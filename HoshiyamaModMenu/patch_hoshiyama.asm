[HoshiyamaModMenu_v288]
moduleMatches = 0x659C782E

; ============================================================
; Hoshiyama Mod Menu v0.11 (Splatoon US v288 / オフライン専用)
;
; 操作:
;   Lスティック押し込み : メニューを開く / 閉じる
;   十字キー上下         : カーソル移動
;   十字キー左右         : Fly Speed / Bot Battle のマップを変更
;   L                    : 決定(ON/OFF・シーン移動・Bot Battle 開始・bot 呼び寄せ・bot の武器)
;   右スティックを上に倒す : Fly ON(メニューを開かなくても使える)
;   A と B を同時に押す   : Fly OFF
;
; フック位置・関数アドレスは OneShotted Safe (by Folp, MIT) の
; 解析結果を参考にしている。コードは新しく書いたもの。
; OneShotted / Fly パックと同時に有効にしないこと。
; ============================================================

; --- ゲーム内の関数・戻り先 ---
TextWriter_Init    = 0x028CC3E4
TextWriter_Printf  = 0x028CC450
Scene_Switch       = 0x028C6434
DebugDraw_Continue = 0x0289DD0C
Random_Get         = 0x028FC0DC   ; r3 = 乱数の状態 → r3 = 乱数 32bit
PlayerDie_Continue = 0x02644A58   ; 自分がやられる処理 0x02644A54 の2命令目
PlayerMgr_GetPlayer = 0x026BA4D8   ; r3 = mgr, r4 = 番号 → r3 = プレイヤー

.origin = codecave

; ------------------------------------------------------------
; 状態
; ------------------------------------------------------------
_HS_state:
    .int 0      ; +0x00 メニューが開いているか
    .int 0      ; +0x04 カーソル位置 (0〜11)
    .int 0      ; +0x08 Fly ON/OFF
    .int 2      ; +0x0C Fly Speed の番号 (0〜4)
    .int 0      ; +0x10 シーン移動の予約 (0 = なし)
    .int 0      ; +0x14 前フレームのボタン
    .int 0      ; +0x18 前フレームに飛んでいたか
    .int 0      ; +0x1C Bot Battle のマップ番号 (0〜17、16 射撃場 / 17 チュートリアル)
    .int 0      ; +0x20 マップ名の書き換え予約
    .int 0      ; +0x24 bot 呼び寄せの予約
    .int 1      ; +0x28 bot の武器をランダムにするか
    .int 0      ; +0x2C 使った名前の印(8bit)
    .int 1      ; +0x30 bot をヒトの姿にするか
    .int 1      ; +0x34 Fly のモード (0 = Freeze, 1 = Hover)。最初から Hover(撃てる)

; Fly Speed: 表示用の整数と、計算用の float
_HS_speed_i:
    .int 1
    .int 2
    .int 3
    .int 5
    .int 8
_HS_speed_f:
    .int 0x3F800000     ; 1.0
    .int 0x40000000     ; 2.0
    .int 0x40400000     ; 3.0
    .int 0x40A00000     ; 5.0
    .int 0x41000000     ; 8.0

; シーンID(項目2〜6に対応)
_HS_scene_ids:
    .int 0x1            ; Plaza
    .int 0x2            ; Lobby
    .int 0xB            ; Shooting Range
    .int 0x9            ; Octo Valley
    .int 0x11           ; Battle Dojo

_HS_f_step:
    .int 0x41C00000     ; 24.0(1行の高さ)
_HS_f_rup:
    .int 0x3F4CCCCD     ; 0.8(右スティックをこれより上に倒したら Fly ON)
_HS_f_hover:
    .int 0x3DA72F05     ; 0.0816 = 0.08 / 0.98(空気抵抗と重力のあとでちょうど 0 になる縦の速度)

; bot を並べる位置(自分の向き基準)
; 前方向の距離と、左右のずれ(最大7体ぶん)。近すぎ/遠すぎなら数値を変える
_HS_bring_fwd:
    .int 0x42200000     ; 前に 40
_HS_bring_lat:
    .int 0xC1F00000     ; -30
    .int 0xC1200000     ; -10
    .int 0x41200000     ;  10
    .int 0x41F00000     ;  30
    .int 0xC2480000     ; -50
    .int 0x42480000     ;  50
    .int 0x00000000     ;   0

; bot の名前の候補(UTF-16、1つ32バイト = 最大15文字 + 終端)。8個
_HS_bot_names:
    ;  0: Playboi Carti
    .int 0x0050006C
    .int 0x00610079
    .int 0x0062006F
    .int 0x00690020
    .int 0x00430061
    .int 0x00720074
    .int 0x00690000
    .int 0x00000000
    ;  1: Ken Carson
    .int 0x004B0065
    .int 0x006E0020
    .int 0x00430061
    .int 0x00720073
    .int 0x006F006E
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  2: Destroy Lonely
    .int 0x00440065
    .int 0x00730074
    .int 0x0072006F
    .int 0x00790020
    .int 0x004C006F
    .int 0x006E0065
    .int 0x006C0079
    .int 0x00000000
    ;  3: HXG Beno!
    .int 0x00480058
    .int 0x00470020
    .int 0x00420065
    .int 0x006E006F
    .int 0x00210000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  4: HXG Meechie
    .int 0x00480058
    .int 0x00470020
    .int 0x004D0065
    .int 0x00650063
    .int 0x00680069
    .int 0x00650000
    .int 0x00000000
    .int 0x00000000
    ;  5: ApolloRed1
    .int 0x00410070
    .int 0x006F006C
    .int 0x006C006F
    .int 0x00520065
    .int 0x00640031
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  6: OpiumBaby
    .int 0x004F0070
    .int 0x00690075
    .int 0x006D0042
    .int 0x00610062
    .int 0x00790000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  7: Lukrative
    .int 0x004C0075
    .int 0x006B0072
    .int 0x00610074
    .int 0x00690076
    .int 0x00650000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000

; Bot Battle のマップ:内部名(読み込ませる名前)と表示名、どちらも1つ32バイト
_HS_map_internal:
    ;  0: Fld_Crank00_Vss
    .int 0x466C645F
    .int 0x4372616E
    .int 0x6B30305F
    .int 0x56737300
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  1: Fld_Warehouse00_Vss
    .int 0x466C645F
    .int 0x57617265
    .int 0x686F7573
    .int 0x6530305F
    .int 0x56737300
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  2: Fld_SeaPlant00_Vss
    .int 0x466C645F
    .int 0x53656150
    .int 0x6C616E74
    .int 0x30305F56
    .int 0x73730000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  3: Fld_UpDown00_Vss
    .int 0x466C645F
    .int 0x5570446F
    .int 0x776E3030
    .int 0x5F567373
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  4: Fld_SkatePark00_Vss
    .int 0x466C645F
    .int 0x536B6174
    .int 0x65506172
    .int 0x6B30305F
    .int 0x56737300
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  5: Fld_Athletic00_Vss
    .int 0x466C645F
    .int 0x4174686C
    .int 0x65746963
    .int 0x30305F56
    .int 0x73730000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  6: Fld_Amida00_Vss
    .int 0x466C645F
    .int 0x416D6964
    .int 0x6130305F
    .int 0x56737300
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  7: Fld_Maze00_Vss
    .int 0x466C645F
    .int 0x4D617A65
    .int 0x30305F56
    .int 0x73730000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  8: Fld_Ruins00_Vss
    .int 0x466C645F
    .int 0x5275696E
    .int 0x7330305F
    .int 0x56737300
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  9: Fld_Tuzura00_Vss
    .int 0x466C645F
    .int 0x54757A75
    .int 0x72613030
    .int 0x5F567373
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ; 10: Fld_Kaisou00_Vss
    .int 0x466C645F
    .int 0x4B616973
    .int 0x6F753030
    .int 0x5F567373
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ; 11: Fld_Jyoheki00_Vss
    .int 0x466C645F
    .int 0x4A796F68
    .int 0x656B6930
    .int 0x305F5673
    .int 0x73000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ; 12: Fld_Pivot00_Vss
    .int 0x466C645F
    .int 0x5069766F
    .int 0x7430305F
    .int 0x56737300
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ; 13: Fld_Hiagari00_Vss
    .int 0x466C645F
    .int 0x48696167
    .int 0x61726930
    .int 0x305F5673
    .int 0x73000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ; 14: Fld_Quarry00_Vss
    .int 0x466C645F
    .int 0x51756172
    .int 0x72793030
    .int 0x5F567373
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ; 15: Fld_Office00_Vss
    .int 0x466C645F
    .int 0x4F666669
    .int 0x63653030
    .int 0x5F567373
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ; 16: Fld_ShootingRange_Shr
    .int 0x466C645F
    .int 0x53686F6F
    .int 0x74696E67
    .int 0x52616E67
    .int 0x655F5368
    .int 0x72000000
    .int 0x00000000
    .int 0x00000000
    ; 17: Fld_Tutorial00_Ttr
    .int 0x466C645F
    .int 0x5475746F
    .int 0x7269616C
    .int 0x30305F54
    .int 0x74720000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
_HS_map_names:
    ;  0: Urchin Underpass
    .int 0x55726368
    .int 0x696E2055
    .int 0x6E646572
    .int 0x70617373
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  1: Walleye Warehouse
    .int 0x57616C6C
    .int 0x65796520
    .int 0x57617265
    .int 0x686F7573
    .int 0x65000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  2: Saltspray Rig
    .int 0x53616C74
    .int 0x73707261
    .int 0x79205269
    .int 0x67000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  3: Arowana Mall
    .int 0x41726F77
    .int 0x616E6120
    .int 0x4D616C6C
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  4: Blackbelly Skatepark
    .int 0x426C6163
    .int 0x6B62656C
    .int 0x6C792053
    .int 0x6B617465
    .int 0x7061726B
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  5: Camp Triggerfish
    .int 0x43616D70
    .int 0x20547269
    .int 0x67676572
    .int 0x66697368
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  6: Port Mackerel
    .int 0x506F7274
    .int 0x204D6163
    .int 0x6B657265
    .int 0x6C000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  7: Kelp Dome
    .int 0x4B656C70
    .int 0x20446F6D
    .int 0x65000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  8: Bluefin Depot
    .int 0x426C7565
    .int 0x66696E20
    .int 0x4465706F
    .int 0x74000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ;  9: Moray Towers
    .int 0x4D6F7261
    .int 0x7920546F
    .int 0x77657273
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ; 10: Hammerhead Bridge
    .int 0x48616D6D
    .int 0x65726865
    .int 0x61642042
    .int 0x72696467
    .int 0x65000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ; 11: Flounder Heights
    .int 0x466C6F75
    .int 0x6E646572
    .int 0x20486569
    .int 0x67687473
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ; 12: Museum d'Alfonsino
    .int 0x4D757365
    .int 0x756D2064
    .int 0x27416C66
    .int 0x6F6E7369
    .int 0x6E6F0000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ; 13: Mahi-Mahi Resort
    .int 0x4D616869
    .int 0x2D4D6168
    .int 0x69205265
    .int 0x736F7274
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ; 14: Piranha Pit
    .int 0x50697261
    .int 0x6E686120
    .int 0x50697400
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ; 15: Ancho-V Games
    .int 0x416E6368
    .int 0x6F2D5620
    .int 0x47616D65
    .int 0x73000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    ; 16: Shooting Range (test)
    .int 0x53686F6F
    .int 0x74696E67
    .int 0x2052616E
    .int 0x67652028
    .int 0x74657374
    .int 0x29000000
    .int 0x00000000
    .int 0x00000000
    ; 17: Tutorial (test)
    .int 0x5475746F
    .int 0x7269616C
    .int 0x20287465
    .int 0x73742900
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000
    .int 0x00000000

; ============================================================
; 入力フック:コントローラーを読んだ直後に毎フレーム呼ばれる
; r31 = 入力バッファ (+0x14 押しているボタン, +0x20/+0x24 左スティック,
;       +0x2C 右スティックY, +0xAD4 サンプル数)
; ============================================================
_HS_Frame:
    stw r3, 0xAD4(r31)          ; フックで上書きした元の命令

    ; --- 押した瞬間のボタン (r10) を求める ---
    lis r11, _HS_state@hi
    ori r11, r11, _HS_state@l
    lwz r12, 0x14(r31)
    lwz r10, 0x14(r11)
    stw r12, 0x14(r11)
    andc r10, r12, r10

    ; --- Fly のショートカット ---
    lwz r8, 0x8(r11)
    cmpwi r8, 0
    bne _HSF_flyKeyOff

    ; OFF のとき:右スティックを上に倒したら ON
    lfs f1, 0x2C(r31)           ; 右スティック Y
    lis r9, _HS_f_rup@hi
    ori r9, r9, _HS_f_rup@l
    lfs f2, 0x0(r9)
    fcmpu cr0, f1, f2
    ble _HSF_noFlyKey
    li r8, 1
    stw r8, 0x8(r11)
    b _HSF_noFlyKey

    ; ON のとき:A (0x8000) と B (0x4000) を同時に押したら OFF
_HSF_flyKeyOff:
    andi. r9, r12, 0xC000       ; 今押しているボタン
    cmplwi r9, 0xC000
    bne _HSF_noFlyKey           ; 両方押していない
    andi. r9, r10, 0xC000       ; どちらかをこのフレームで押した瞬間だけ
    beq _HSF_noFlyKey
    li r8, 0
    stw r8, 0x8(r11)
_HSF_noFlyKey:

    ; --- Lスティック押し込み (0x40000):メニュー開閉 ---
    andis. r9, r10, 0x0004
    beq _HSF_noMenuKey
    lwz r8, 0x0(r11)
    xori r8, r8, 1
    stw r8, 0x0(r11)
_HSF_noMenuKey:

    lwz r8, 0x0(r11)
    cmpwi r8, 0
    beq _HSF_fly                ; メニューが閉じていれば操作処理は飛ばす

    ; --- 十字キー上下でカーソル移動 (12項目でループ) ---
    lwz r7, 0x4(r11)
    andi. r9, r10, 0x200        ; 上
    beq _HSF_noUp
    addi r7, r7, -1
    cmpwi r7, 0
    bge _HSF_noUp
    li r7, 11
_HSF_noUp:
    andi. r9, r10, 0x100        ; 下
    beq _HSF_noDown
    addi r7, r7, 1
    cmpwi r7, 12
    blt _HSF_noDown
    li r7, 0
_HSF_noDown:
    stw r7, 0x4(r11)

    ; --- Fly Speed の上で十字キー左右 ---
    cmpwi r7, 1
    bne _HSF_noSpeed
    lwz r6, 0xC(r11)
    andi. r9, r10, 0x800        ; 左
    beq _HSF_noLeft
    addi r6, r6, -1
    cmpwi r6, 0
    bge _HSF_noLeft
    li r6, 0
_HSF_noLeft:
    andi. r9, r10, 0x400        ; 右
    beq _HSF_noRight
    addi r6, r6, 1
    cmpwi r6, 4
    ble _HSF_noRight
    li r6, 4
_HSF_noRight:
    stw r6, 0xC(r11)
_HSF_noSpeed:

    ; --- Bot Battle の上で十字キー左右:マップ変更 (18個でループ) ---
    cmpwi r7, 7
    bne _HSF_noMap
    lwz r6, 0x1C(r11)
    andi. r9, r10, 0x800        ; 左
    beq _HSF_mapNoLeft
    addi r6, r6, -1
    cmpwi r6, 0
    bge _HSF_mapNoLeft
    li r6, 17
_HSF_mapNoLeft:
    andi. r9, r10, 0x400        ; 右
    beq _HSF_mapNoRight
    addi r6, r6, 1
    cmpwi r6, 18
    blt _HSF_mapNoRight
    li r6, 0
_HSF_mapNoRight:
    stw r6, 0x1C(r11)
_HSF_noMap:

    ; --- L (0x20) で決定 ---
    andi. r9, r10, 0x20
    beq _HSF_eat
    cmpwi r7, 0
    bne _HSF_notFly
    lwz r6, 0x8(r11)            ; 項目0:Fly ON/OFF
    xori r6, r6, 1
    stw r6, 0x8(r11)
    b _HSF_eat
_HSF_notFly:
    cmpwi r7, 10
    bne _HSF_notFlyMode
    lwz r6, 0x34(r11)           ; 項目10:Fly のモード Freeze / Hover 切り替え
    xori r6, r6, 1
    stw r6, 0x34(r11)
    b _HSF_eat
_HSF_notFlyMode:
    cmpwi r7, 11
    bne _HSF_notHuman
    lwz r6, 0x30(r11)           ; 項目11:bot をヒトにする ON / OFF
    xori r6, r6, 1
    stw r6, 0x30(r11)
    b _HSF_eat
_HSF_notHuman:
    cmpwi r7, 9
    bne _HSF_notWeapon
    lwz r6, 0x28(r11)           ; 項目9:bot の武器 Random / Default 切り替え
    xori r6, r6, 1
    stw r6, 0x28(r11)
    b _HSF_eat
_HSF_notWeapon:
    cmpwi r7, 8
    bne _HSF_notBring
    li r6, 1                    ; 項目8:bot 呼び寄せを予約(メニューは開いたまま)
    stw r6, 0x24(r11)
    b _HSF_eat
_HSF_notBring:
    cmpwi r7, 7
    bne _HSF_notBot
    li r6, 1                    ; 項目7:Bot Battle
    stw r6, 0x20(r11)           ; マップ名の書き換えを予約
    li r6, 0
    stw r6, 0x2C(r11)           ; 使った名前の印をリセット
    li r6, 7                    ; シーン7(オフライン対戦)を予約
    stw r6, 0x10(r11)
    li r6, 0
    stw r6, 0x0(r11)            ; メニューを閉じる
    b _HSF_eat
_HSF_notBot:
    cmpwi r7, 2
    blt _HSF_eat                ; 項目1(Speed)はLでは何もしない
    addi r6, r7, -2             ; 項目2〜6:シーン移動を予約
    slwi r6, r6, 2
    lis r5, _HS_scene_ids@hi
    ori r5, r5, _HS_scene_ids@l
    lwzx r6, r5, r6
    stw r6, 0x10(r11)
    li r6, 0
    stw r6, 0x0(r11)            ; 移動するときはメニューを閉じる

    ; --- メニュー操作に使ったボタンをゲームに渡さない ---
_HSF_eat:
    lwz r7, 0xAD4(r31)          ; サンプル数 (1〜16 に収める)
    cmpwi r7, 1
    bge _HSF_eatMin
    li r7, 1
_HSF_eatMin:
    cmpwi r7, 16
    ble _HSF_eatMax
    li r7, 16
_HSF_eatMax:
    mtctr r7
    addi r6, r31, 0x14
    lis r8, 0x0004              ; Lスティック押し込み
    ori r8, r8, 0x0F20          ; 十字キー全部 + L
_HSF_eatLoop:
    lwz r5, 0x0(r6)
    andc r5, r5, r8
    stw r5, 0x0(r6)
    lwz r5, 0x4(r6)
    andc r5, r5, r8
    stw r5, 0x4(r6)
    addi r6, r6, 0xAC
    bdnz _HSF_eatLoop

    ; --- Fly 本体 ---
_HSF_fly:
    lis r9, 0x101E
    lwz r9, 0x16E8(r9)          ; [0x101E16E8] = プレイヤー
    cmpwi r9, 0
    beq _HSF_end
    lwz r8, 0x8(r11)
    cmpwi r8, 0
    bne _HSF_flyOn

    ; Fly OFF:直前まで飛んでいたらフリーズを解除
    lwz r8, 0x18(r11)
    cmpwi r8, 0
    beq _HSF_end
    li r8, 0
    stw r8, 0x18(r11)
    stw r8, 0x4E4(r9)
    b _HSF_end

_HSF_flyOn:
    lwz r8, 0x34(r11)
    cmpwi r8, 0
    bne _HSF_hover

    ; Freeze モード:計算ごと止める(バリアに入れるが撃てない)
    li r8, 1
    stw r8, 0x18(r11)
    lis r7, 0x0FFF              ; 重力・物理を止める
    ori r7, r7, 0xFFFF
    stw r7, 0x4E4(r9)
    b _HSF_flyMove

    ; Hover モード:止めずに縦の速度だけ打ち消す(撃てるがバリアには弾かれる)
_HSF_hover:
    lwz r8, 0x18(r11)
    cmpwi r8, 0
    beq _HSF_hoverNoUnfreeze
    li r8, 0                    ; Freeze から切り替えたときはフリーズを解除
    stw r8, 0x18(r11)
    stw r8, 0x4E4(r9)
_HSF_hoverNoUnfreeze:
    lis r7, _HS_f_hover@hi
    ori r7, r7, _HS_f_hover@l
    lwz r7, 0x0(r7)
    stw r7, 0x304(r9)           ; 縦の速度
    li r7, 0
    stw r7, 0x31C(r9)           ; もう一つの縦の成分も 0 に
_HSF_flyMove:

    lwz r8, 0x8D0(r9)           ; 向きの情報
    cmpwi r8, 0
    beq _HSF_end
    lfs f1, 0x20(r31)           ; 左スティック X
    lfs f2, 0x24(r31)           ; 左スティック Y
    lfs f3, 0x2C(r31)           ; 右スティック Y
    lfs f4, 0x1B8(r8)
    lfs f5, 0x1C0(r8)
    lwz r7, 0xC(r11)            ; 速さ = _HS_speed_f[番号]
    slwi r7, r7, 2
    lis r6, _HS_speed_f@hi
    ori r6, r6, _HS_speed_f@l
    lfsx f6, r6, r7

    fmuls f7, f2, f4
    fmuls f8, f1, f5
    fsubs f7, f7, f8
    fmuls f7, f7, f6            ; X
    fmuls f8, f1, f4
    fmuls f9, f2, f5
    fadds f8, f8, f9
    fmuls f8, f8, f6            ; Z
    fmuls f9, f3, f6            ; Y

    lfs f0, 0x248(r9)
    fadds f0, f0, f7
    stfs f0, 0x248(r9)
    lfs f0, 0x24C(r9)
    fadds f0, f0, f9
    stfs f0, 0x24C(r9)
    lfs f0, 0x250(r9)
    fadds f0, f0, f8
    stfs f0, 0x250(r9)
_HSF_end:
    blr

; ============================================================
; 描画フック:デバッグ描画関数の入口から呼ばれる
; r3, r4 = 元の関数の引数(r4 の先頭が 3 のときに描く)
; スタック: +0x10 TextWriter, +0x80 今の行のY, +0x90〜 保存したレジスタ
; ============================================================
_HS_Draw:
    stwu r1, -0xB0(r1)
    mflr r0
    stw r0, 0xB4(r1)
    stw r31, 0xAC(r1)
    stw r30, 0xA8(r1)
    stw r29, 0xA4(r1)
    stw r28, 0xA0(r1)
    stw r27, 0x9C(r1)
    stw r26, 0x98(r1)
    stw r25, 0x94(r1)
    stw r24, 0x90(r1)
    mr r27, r3                  ; 元の引数を保存
    mr r30, r4
    mr r31, r1                  ; TextWriter のある場所
    lis r28, _HS_state@hi
    ori r28, r28, _HS_state@l

    lwz r12, 0x0(r30)
    cmpwi r12, 3
    bne _HSD_end

    ; --- Bot Battle:読み込むステージ名を選んだマップに書き換える ---
    lwz r12, 0x20(r28)
    cmpwi r12, 0
    beq _HSD_noMap
    li r12, 0
    stw r12, 0x20(r28)
    lis r10, 0x101E
    lwz r10, -0x2CD0(r10)       ; [0x101DD330] = ステージ情報
    cmpwi r10, 0
    beq _HSD_noMap
    lwz r11, 0x1C(r10)          ; ステージ名のバッファ
    lwz r12, 0x24(r10)          ; バッファの大きさ
    cmpwi r11, 0
    beq _HSD_noMap
    cmpwi r12, 32
    blt _HSD_noMap              ; 32バイト未満なら書かない(はみ出し防止)
    lwz r12, 0x1C(r28)
    slwi r12, r12, 5            ; マップ番号 × 32
    lis r9, _HS_map_internal@hi
    ori r9, r9, _HS_map_internal@l
    add r9, r9, r12
_HSD_mapCopy:
    lbz r7, 0x0(r9)
    stb r7, 0x0(r11)
    addi r9, r9, 1
    addi r11, r11, 1
    cmpwi r7, 0
    bne _HSD_mapCopy
_HSD_noMap:

    ; --- 予約されたシーン移動を実行 ---
    lwz r3, 0x10(r28)
    cmpwi r3, 0
    beq _HSD_noScene
    li r12, 0
    stw r12, 0x10(r28)
    bl Scene_Switch
_HSD_noScene:

    ; --- bot 呼び寄せ:敵チームの bot を、自分の正面に並べる ---
    ; PlayerMgr = [[0x101E2814] + 0x268]
    ; [mgr + 0x2B8 + 番号*4] が -1 のプレイヤーが bot、+0x2C がチーム
    lwz r12, 0x24(r28)
    cmpwi r12, 0
    beq _HSD_noBring
    li r12, 0
    stw r12, 0x24(r28)
    lis r24, 0x101E
    lwz r24, 0x16E8(r24)        ; r24 = 自分
    cmpwi r24, 0
    beq _HSD_noBring
    lis r12, 0x101E
    lwz r12, 0x2814(r12)        ; ゲーム全体のルート
    cmpwi r12, 0
    beq _HSD_noBring
    lwz r26, 0x268(r12)         ; r26 = PlayerMgr
    cmpwi r26, 0
    beq _HSD_noBring
    li r25, 0                   ; r25 = プレイヤー番号
    li r29, 0                   ; r29 = 並べた bot の数
_HSD_bringLoop:
    lwz r12, 0x320(r26)         ; 人数
    cmpw r25, r12
    bge _HSD_noBring
    cmpwi r25, 8
    bge _HSD_noBring
    slwi r12, r25, 2
    add r12, r12, r26
    lwz r12, 0x2B8(r12)         ; コントローラ番号
    cmpwi r12, -1
    bne _HSD_bringNext          ; 人が操作しているなら飛ばす
    mr r3, r26
    mr r4, r25
    bl PlayerMgr_GetPlayer
    cmpwi r3, 0
    beq _HSD_bringNext
    cmpw r3, r24
    beq _HSD_bringNext          ; 念のため自分は動かさない
    lwz r12, 0x2C(r3)           ; bot のチーム
    lwz r11, 0x2C(r24)          ; 自分のチーム
    cmpw r12, r11
    beq _HSD_bringNext          ; 味方は呼ばない
    cmpwi r29, 7
    bge _HSD_bringNext
    lwz r8, 0x8D0(r24)          ; 自分の向き(Fly と同じ)
    cmpwi r8, 0
    beq _HSD_noBring
    lfs f4, 0x1B8(r8)           ; c
    lfs f5, 0x1C0(r8)           ; s
    lis r11, _HS_bring_fwd@hi
    ori r11, r11, _HS_bring_fwd@l
    lfs f2, 0x0(r11)            ; 前への距離
    slwi r12, r29, 2
    lis r11, _HS_bring_lat@hi
    ori r11, r11, _HS_bring_lat@l
    lfsx f3, r11, r12           ; 左右のずれ
    ; 前ベクトル (c, s)、右ベクトル (-s, c) として
    ; dX = 前*c - 左右*s、dZ = 前*s + 左右*c
    fmuls f6, f2, f4
    fmuls f7, f3, f5
    fsubs f6, f6, f7            ; dX
    fmuls f7, f2, f5
    fmuls f8, f3, f4
    fadds f7, f7, f8            ; dZ
    lfs f0, 0x248(r24)
    fadds f0, f0, f6
    stfs f0, 0x248(r3)          ; X
    lfs f0, 0x24C(r24)
    stfs f0, 0x24C(r3)          ; Y = 自分と同じ高さ
    lfs f0, 0x250(r24)
    fadds f0, f0, f7
    stfs f0, 0x250(r3)          ; Z
    lwz r12, 0x30(r28)          ; Bots Stand Up が ON なら、
    cmpwi r12, 0
    beq _HSD_bringNoStand
    li r12, 5
    stw r12, 0x7B4(r3)          ; 大きな状態 = 5(ふつうに動ける状態)
    li r12, 0
    stb r12, 0x7B9(r3)          ; 登場/ワープ演出のフラグを消す
    stb r12, 0x584(r3)          ; イカになりたいフラグを消す
_HSD_bringNoStand:
    addi r29, r29, 1
_HSD_bringNext:
    addi r25, r25, 1
    b _HSD_bringLoop
_HSD_noBring:

    ; --- メニューもFlyもOFFなら何も描かない ---
    lwz r12, 0x0(r28)
    lwz r11, 0x8(r28)
    or. r12, r12, r11
    beq _HSD_end

    addi r3, r1, 0x10
    mr r4, r30
    bl TextWriter_Init
    lis r12, 0x3F80
    stw r12, 0x3C(r1)           ; 不透明度 1.0

    lwz r12, 0x0(r28)
    cmpwi r12, 0
    bne _HSD_menu

    ; --- メニューが閉じていてFlyがONなら、左上に表示 ---
    lis r12, 0xC416             ; X = -600
    stw r12, 0x20(r1)
    lis r12, 0x43A5             ; Y = 330
    stw r12, 0x24(r1)
    li r12, 0
    stw r12, 0x30(r1)           ; 緑
    stw r12, 0x38(r1)
    lis r12, 0x3F80
    stw r12, 0x34(r1)
    addi r3, r1, 0x10
    lis r4, _HS_txt_flyon@hi
    ori r4, r4, _HS_txt_flyon@l
    crxor 6, 6, 6
    bl TextWriter_Printf
    b _HSD_end

_HSD_menu:
    lis r12, 0x43A5             ; 最初の行のY = 330(各行で24ずつ下げる)
    stw r12, 0x80(r1)

    ; タイトル
    li r29, -1
    lis r4, _HS_txt_title@hi
    ori r4, r4, _HS_txt_title@l
    bl _HS_Line

    ; 項目0:Fly
    li r29, 0
    lis r6, _HS_txt_off@hi
    ori r6, r6, _HS_txt_off@l
    lwz r12, 0x8(r28)
    cmpwi r12, 0
    beq _HSD_flyText
    lis r6, _HS_txt_on@hi
    ori r6, r6, _HS_txt_on@l
_HSD_flyText:
    lis r4, _HS_fmt_fly@hi
    ori r4, r4, _HS_fmt_fly@l
    bl _HS_Line

    ; 項目1:Fly Speed
    li r29, 1
    lwz r12, 0xC(r28)
    slwi r12, r12, 2
    lis r11, _HS_speed_i@hi
    ori r11, r11, _HS_speed_i@l
    lwzx r6, r11, r12
    lis r4, _HS_fmt_speed@hi
    ori r4, r4, _HS_fmt_speed@l
    bl _HS_Line

    ; 項目2〜6:シーン移動
    li r29, 2
    lis r6, _HS_txt_plaza@hi
    ori r6, r6, _HS_txt_plaza@l
    lis r4, _HS_fmt_go@hi
    ori r4, r4, _HS_fmt_go@l
    bl _HS_Line

    li r29, 3
    lis r6, _HS_txt_lobby@hi
    ori r6, r6, _HS_txt_lobby@l
    lis r4, _HS_fmt_go@hi
    ori r4, r4, _HS_fmt_go@l
    bl _HS_Line

    li r29, 4
    lis r6, _HS_txt_range@hi
    ori r6, r6, _HS_txt_range@l
    lis r4, _HS_fmt_go@hi
    ori r4, r4, _HS_fmt_go@l
    bl _HS_Line

    li r29, 5
    lis r6, _HS_txt_valley@hi
    ori r6, r6, _HS_txt_valley@l
    lis r4, _HS_fmt_go@hi
    ori r4, r4, _HS_fmt_go@l
    bl _HS_Line

    li r29, 6
    lis r6, _HS_txt_dojo@hi
    ori r6, r6, _HS_txt_dojo@l
    lis r4, _HS_fmt_go@hi
    ori r4, r4, _HS_fmt_go@l
    bl _HS_Line

    ; 項目7:Bot Battle
    li r29, 7
    lwz r12, 0x1C(r28)
    slwi r12, r12, 5
    lis r6, _HS_map_names@hi
    ori r6, r6, _HS_map_names@l
    add r6, r6, r12
    lis r4, _HS_fmt_bot@hi
    ori r4, r4, _HS_fmt_bot@l
    bl _HS_Line

    ; 項目8:bot 呼び寄せ
    li r29, 8
    lis r4, _HS_txt_bring@hi
    ori r4, r4, _HS_txt_bring@l
    bl _HS_Line

    ; 項目9:bot の武器
    li r29, 9
    lis r6, _HS_txt_default@hi
    ori r6, r6, _HS_txt_default@l
    lwz r12, 0x28(r28)
    cmpwi r12, 0
    beq _HSD_weaponText
    lis r6, _HS_txt_random@hi
    ori r6, r6, _HS_txt_random@l
_HSD_weaponText:
    lis r4, _HS_fmt_weapon@hi
    ori r4, r4, _HS_fmt_weapon@l
    bl _HS_Line

    ; 項目10:Fly のモード
    li r29, 10
    lis r6, _HS_txt_freeze@hi
    ori r6, r6, _HS_txt_freeze@l
    lwz r12, 0x34(r28)
    cmpwi r12, 0
    beq _HSD_flyModeText
    lis r6, _HS_txt_hover@hi
    ori r6, r6, _HS_txt_hover@l
_HSD_flyModeText:
    lis r4, _HS_fmt_flymode@hi
    ori r4, r4, _HS_fmt_flymode@l
    bl _HS_Line

    ; 項目11:bot をヒトにする
    li r29, 11
    lis r6, _HS_txt_off@hi
    ori r6, r6, _HS_txt_off@l
    lwz r12, 0x30(r28)
    cmpwi r12, 0
    beq _HSD_humanText
    lis r6, _HS_txt_on@hi
    ori r6, r6, _HS_txt_on@l
_HSD_humanText:
    lis r4, _HS_fmt_human@hi
    ori r4, r4, _HS_fmt_human@l
    bl _HS_Line

    ; デバッグ:最初の bot の状態を1行出す(イカのままの原因探し用)
    lis r12, 0x101E
    lwz r12, 0x2814(r12)
    cmpwi r12, 0
    beq _HSD_dbgEnd
    lwz r26, 0x268(r12)         ; PlayerMgr
    cmpwi r26, 0
    beq _HSD_dbgEnd
    li r25, 0
_HSD_dbgLoop:
    lwz r12, 0x320(r26)
    cmpw r25, r12
    bge _HSD_dbgEnd
    cmpwi r25, 8
    bge _HSD_dbgEnd
    slwi r12, r25, 2
    add r12, r12, r26
    lwz r12, 0x2B8(r12)
    cmpwi r12, -1
    bne _HSD_dbgNext            ; bot だけ
    mr r3, r26
    mr r4, r25
    bl PlayerMgr_GetPlayer
    cmpwi r3, 0
    beq _HSD_dbgNext
    lwz r6, 0x7B4(r3)           ; 大きな状態(5 = ふつう)
    lbz r7, 0x7B9(r3)           ; 登場/ワープ演出
    lwz r8, 0x6F4(r3)           ; スーパージャンプの状態
    lwz r9, 0x76C(r3)           ; アニメ管理
    cmpwi r9, 0
    beq _HSD_dbgNoAnim
    lwz r9, 0x24(r9)            ; 今のアニメ番号
    b _HSD_dbgPrint
_HSD_dbgNoAnim:
    li r9, -1
_HSD_dbgPrint:
    li r29, -1                  ; 選択できない行
    lis r4, _HS_fmt_dbg@hi
    ori r4, r4, _HS_fmt_dbg@l
    bl _HS_Line
    b _HSD_dbgEnd
_HSD_dbgNext:
    addi r25, r25, 1
    b _HSD_dbgLoop
_HSD_dbgEnd:

_HSD_end:
    mr r3, r27                  ; 元の引数に戻す
    mr r4, r30
    lwz r24, 0x90(r1)
    lwz r25, 0x94(r1)
    lwz r26, 0x98(r1)
    lwz r27, 0x9C(r1)
    lwz r28, 0xA0(r1)
    lwz r29, 0xA4(r1)
    lwz r30, 0xA8(r1)
    lwz r31, 0xAC(r1)
    lwz r0, 0xB4(r1)
    mtlr r0
    addi r1, r1, 0xB0
    stwu r1, -0x108(r1)         ; フックで上書きした元の命令
    b DebugDraw_Continue

; ------------------------------------------------------------
; 1行描くサブルーチン
; 入力: r4 = 書式, r6 = 引数, r29 = 行番号, r31 = TextWriter の場所
; 選択中の行は黄色で ">> " を付ける
; ------------------------------------------------------------
_HS_Line:
    stwu r1, -0x20(r1)
    mflr r0
    stw r0, 0x24(r1)

    lfs f0, 0x80(r31)           ; Y を1行ぶん下げる
    lis r12, _HS_f_step@hi
    ori r12, r12, _HS_f_step@l
    lfs f1, 0x0(r12)
    fsubs f0, f0, f1
    stfs f0, 0x80(r31)
    stfs f0, 0x24(r31)
    lis r12, 0xC416             ; X = -600
    stw r12, 0x20(r31)

    lis r12, 0x3F80             ; 白
    stw r12, 0x30(r31)
    stw r12, 0x34(r31)
    stw r12, 0x38(r31)
    lis r5, _HS_txt_nosel@hi
    ori r5, r5, _HS_txt_nosel@l
    lwz r12, 0x4(r28)           ; カーソル位置
    cmpw r12, r29
    bne _HSL_print
    li r12, 0
    stw r12, 0x38(r31)          ; 青を0にして黄色
    lis r5, _HS_txt_sel@hi
    ori r5, r5, _HS_txt_sel@l
_HSL_print:
    addi r3, r31, 0x10
    crxor 6, 6, 6
    bl TextWriter_Printf

    lwz r0, 0x24(r1)
    mtlr r0
    addi r1, r1, 0x20
    blr

; ------------------------------------------------------------
; bot の名前と武器を決める
; 0x021A740C(元の命令 `or r3, r31, r31`)から bl で呼ばれる。
; bot の枠を作る関数 0x021A728C の途中で、名前("Player%d")を書いた後・武器を選ぶ前。
; このとき r29 = プレイヤー情報、r4 = 武器セットの番号(普段は 0 = ボールドマーカー)、
;          r0 = 武器セットの個数、r31 = 武器セットのテーブル
; このあとゲームが使うのは r3 / r4 / r29 / r31 だけ
; ------------------------------------------------------------
_HS_RandWeapon:
    stwu r1, -0x20(r1)
    mflr r12
    stw r12, 0x24(r1)
    stw r0, 0x8(r1)             ; 個数(乱数の関数で壊れるので保存)
    stw r4, 0xC(r1)             ; 元の武器セット番号

    ; ---- 名前:候補からまだ使っていない名前を選んで info+0x06 に書く ----
    lhz r12, 0x6(r29)           ; 名前が "Pl..."(= "Player%d")のときだけ
    cmpwi r12, 0x50
    bne _HSR_weapon
    lhz r12, 0x8(r29)
    cmpwi r12, 0x6C
    bne _HSR_weapon
    lis r3, 0x101E
    lwz r3, 0x6B18(r3)          ; 乱数の状態
    cmpwi r3, 0
    beq _HSR_weapon
    bl Random_Get
    li r12, 8
    mulhwu r10, r3, r12         ; r10 = 0〜7
    lis r11, _HS_state@hi
    ori r11, r11, _HS_state@l
    lwz r9, 0x2C(r11)           ; 使った名前の印
    cmplwi r9, 0xFF
    blt _HSN_probe
    li r9, 0                    ; 8個全部使ったらリセット
_HSN_probe:
    li r8, 1
    slw r8, r8, r10
    and. r7, r9, r8
    beq _HSN_got                ; まだ使っていない名前
    addi r10, r10, 1            ; 使っていたら次の名前へ
    andi. r10, r10, 7
    b _HSN_probe
_HSN_got:
    or r9, r9, r8
    stw r9, 0x2C(r11)
    slwi r10, r10, 5            ; 番号 × 32
    lis r12, _HS_bot_names@hi
    ori r12, r12, _HS_bot_names@l
    add r12, r12, r10
    addi r11, r29, 0x6          ; info+0x06 = 名前
    li r10, 16                  ; 16文字ぶん(終端を含む)コピー
    mtctr r10
_HSN_copy:
    lhz r9, 0x0(r12)
    sth r9, 0x0(r11)
    addi r12, r12, 2
    addi r11, r11, 2
    bdnz _HSN_copy

    ; ---- 武器:Random なら番号を乱数で選び直す ----
_HSR_weapon:
    lwz r4, 0xC(r1)             ; まずは元の番号
    lis r12, _HS_state@hi
    ori r12, r12, _HS_state@l
    lwz r12, 0x28(r12)
    cmpwi r12, 0
    beq _HSR_end                ; Default なら何もしない
    lis r3, 0x101E
    lwz r3, 0x6B18(r3)
    cmpwi r3, 0
    beq _HSR_end
    bl Random_Get
    lwz r4, 0xC(r1)
    lwz r0, 0x8(r1)
    cmpwi r0, 0
    beq _HSR_end
    mulhwu r4, r3, r0           ; r4 = 乱数 × 個数 の上位32bit = 0〜個数-1
_HSR_end:
    lwz r0, 0x8(r1)
    lwz r12, 0x24(r1)
    mtlr r12
    addi r1, r1, 0x20
    or r3, r31, r31             ; 上書きした元の命令
    blr

; ------------------------------------------------------------
; bot をヒトの姿にする
; 0x02641D44(元の命令 `or r3, r30, r30`)から bl で呼ばれる。
; プレイヤーの毎フレームの更新(0x02641C1C)の中で、入力処理の直後・本体の更新の前。
; r30 = プレイヤー。r12 と cr0 以外は触らない
; +0x50 が 0 以外 = 人が操作していない(bot)なら、イカになりたいフラグ +0x584 を 0 にする
; ------------------------------------------------------------
_HS_BotHuman:
    lis r12, _HS_state@hi
    ori r12, r12, _HS_state@l
    lwz r12, 0x30(r12)
    cmpwi r12, 0
    beq _HSH_end
    lwz r12, 0x50(r30)          ; 操作の種類(0 = コントローラ)
    cmpwi r12, 0
    beq _HSH_end
    li r12, 0
    stb r12, 0x584(r30)         ; ヒトになりたい
_HSH_end:
    or r3, r30, r30             ; 上書きした元の命令
    blr

; ------------------------------------------------------------
; Fly 中の無敵:自分がやられる処理 0x02644A54 の入口(元の命令 `mflr r0`)から b で来る
; r3 = プレイヤー。まだスタックを作っていないので、そのまま blr で戻れる
; ------------------------------------------------------------
_HS_NoDie:
    lis r12, _HS_state@hi
    ori r12, r12, _HS_state@l
    lwz r12, 0x8(r12)           ; Fly が ON のときだけ
    cmpwi r12, 0
    beq _HSND_die
    lis r12, 0x101E
    lwz r12, 0x16E8(r12)        ; 自分のプレイヤー
    cmpw r3, r12
    bne _HSND_die
    blr                         ; やられずに戻る
_HSND_die:
    mflr r0                     ; 上書きした元の命令
    b PlayerDie_Continue

; ------------------------------------------------------------
; Fly 中のすり抜け:物理の更新(0x0264FF04)の中の3つの比較を置き換える
; r30 = プレイヤー。自分で Fly 中なら比べる値を 1 にして、
; 地形の当たり判定 / [+0x764] の押し出し / [+0x760] の押し出し を飛ばす
; 使うのは r12 と cr0 だけ。最後に元の cmpwi をして、cr0 を作ってから戻る
; ------------------------------------------------------------
_HS_NoClip6:
    lis r12, _HS_state@hi
    ori r12, r12, _HS_state@l
    lwz r12, 0x8(r12)           ; Fly が ON のときだけ
    cmpwi r12, 0
    beq _HSNC6_end
    lis r12, 0x101E
    lwz r12, 0x16E8(r12)        ; 自分のプレイヤー
    cmpw r30, r12
    bne _HSNC6_end
    li r6, 1                    ; 「止める理由がある」扱いにして処理を飛ばす
_HSNC6_end:
    cmpwi r6, 0x0               ; 上書きした元の命令(cr0 は blr で変わらない)
    blr

_HS_NoClip0:
    lis r12, _HS_state@hi
    ori r12, r12, _HS_state@l
    lwz r12, 0x8(r12)           ; Fly が ON のときだけ
    cmpwi r12, 0
    beq _HSNC0_end
    lis r12, 0x101E
    lwz r12, 0x16E8(r12)        ; 自分のプレイヤー
    cmpw r30, r12
    bne _HSNC0_end
    li r0, 1                    ; 「止める理由がある」扱いにして処理を飛ばす
_HSNC0_end:
    cmpwi r0, 0x0               ; 上書きした元の命令(cr0 は blr で変わらない)
    blr

_HS_NoClip4:
    lis r12, _HS_state@hi
    ori r12, r12, _HS_state@l
    lwz r12, 0x8(r12)           ; Fly が ON のときだけ
    cmpwi r12, 0
    beq _HSNC4_end
    lis r12, 0x101E
    lwz r12, 0x16E8(r12)        ; 自分のプレイヤー
    cmpw r30, r12
    bne _HSNC4_end
    li r4, 1                    ; 「止める理由がある」扱いにして処理を飛ばす
_HSNC4_end:
    cmpwi r4, 0x0               ; 上書きした元の命令(cr0 は blr で変わらない)
    blr

; ------------------------------------------------------------
; 文字列(コードの後ろに置く)
; ------------------------------------------------------------
_HS_txt_title:
    .string "Hoshiyama Mod Menu v0.11"
_HS_fmt_fly:
    .string "%sFly: %s"
_HS_fmt_speed:
    .string "%sFly Speed: < %d >"
_HS_fmt_go:
    .string "%sGo to %s"
_HS_fmt_bot:
    .string "%sBot Battle: < %s >"
_HS_txt_bring:
    .string "%sBring Enemy Bots Here"
_HS_fmt_weapon:
    .string "%sBot Weapon: %s"
_HS_txt_random:
    .string "Random"
_HS_txt_default:
    .string "Default"
_HS_fmt_flymode:
    .string "%sFly Mode: %s"
_HS_txt_freeze:
    .string "Freeze"
_HS_txt_hover:
    .string "Hover (can shoot)"
_HS_fmt_human:
    .string "%sBots Stand Up: %s"
_HS_fmt_dbg:
    .string "%s[bot] state=%d warp=%d sj=%d anim=%X"
_HS_txt_on:
    .string "ON"
_HS_txt_off:
    .string "OFF"
_HS_txt_sel:
    .string ">> "
_HS_txt_nosel:
    .string "   "
_HS_txt_flyon:
    .string "FLY ON  (A+B: OFF)"
_HS_txt_plaza:
    .string "Plaza"
_HS_txt_lobby:
    .string "Lobby"
_HS_txt_range:
    .string "Shooting Range"
_HS_txt_valley:
    .string "Octo Valley"
_HS_txt_dojo:
    .string "Battle Dojo"
.align 4

; ============================================================
; フック
; ============================================================
0x028D0F34 = bl _HS_Frame       ; 入力を読んだ直後
0x0289DD08 = b _HS_Draw         ; デバッグ描画関数の入口
0x021A7D84 = li r31, 8          ; 対戦の人数を8人にする(7人ぶんがbotになる)
0x021A740C = bl _HS_RandWeapon  ; bot の名前を書いた後・武器セットを選ぶところ
0x02641D44 = bl _HS_BotHuman    ; プレイヤーの更新の中、入力処理の直後
0x02644A54 = b _HS_NoDie        ; 自分がやられる処理の入口(Fly 中は無敵)
0x026508CC = bl _HS_NoClip6     ; 地形の当たり判定を呼ぶかの比較(Fly 中はすり抜け)
0x02650128 = bl _HS_NoClip0     ; [+0x764] の押し出しの比較
0x0265036C = bl _HS_NoClip4     ; [+0x760] の押し出しの比較
; ※ v0.5 まであった 0x021A743C のパッチ(チーム分けのつもりだったもの)は、
;   実はスペシャル ID(+0x4C)を書き換えていただけだったので外した。
;   チームはゲームが +0x30 に番号の偶奇で入れている
