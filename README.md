# Hoshiyama Mod Menu

Wii U版『スプラトゥーン』(US版 v288)を Cemu で遊ぶための、**オフライン専用**の MOD メニューです(Cemu のグラフィックパック)。

An **offline-only** in-game mod menu for Splatoon (Wii U, US v288) on Cemu, made as a Cemu graphic pack.

> [!WARNING]
> **オフライン専用です。オンライン(Pretendo Network など)に接続するときは、必ずこのパックを無効にしてください。**
> 無敵やすり抜けをオンラインで使うと、ほかのプレイヤーの迷惑になります。
>
> **Offline only.** Disable this pack before connecting online (e.g. Pretendo Network).
> Using god mode or noclip online ruins the game for other players.

## 必要なもの / Requirements

- Cemu
- 自分で正規に入手した Splatoon US版(`0005000010176900`)と、更新データ v288
  - ほかのリージョン・バージョンでは読み込まれません
- このリポジトリには、ゲームのファイルは一切含まれていません

## 機能 / Features

- **Fly**:自由に飛べる。速さは 1 / 2 / 3 / 5 / 8
  - **Hover(デフォルト)**:飛びながら撃てる
  - **Freeze**:計算ごと止めて飛ぶ(撃てない)
  - Fly 中は**無敵**で、**壁や敵陣のバリアをすり抜け**られる(自分だけ)
- **シーン移動**:広場 / ロビー / 射撃場 / タコツボバレー / バトルドージョー
- **Bot Battle**:好きなマップで 4対4 のオフライン対戦(相手は bot)。対戦16マップ + 射撃場 + チュートリアル
- **Bring Enemy Bots Here**:敵チームの bot を、自分の正面に並べる
- **Bots Stand Up**:呼び寄せた bot をヒトの姿で立たせる
- **Bot Weapon: Random**:bot の武器をランダムにする
- bot の名前を、用意した8人の名前からランダムに選ぶ

※ bot は動きません(AI はありません)。動く的にするのは今後の課題です。

## インストール / Install

1. `HoshiyamaModMenu` フォルダを丸ごと、Cemu の `graphicPacks` フォルダにコピーする
   - ポータブル版:`<Cemu のフォルダ>\graphicPacks`
   - 通常インストール版:`%APPDATA%\Cemu\graphicPacks`
2. Cemu で「オプション」>「グラフィックパック」>「Splatoon」>「Mods」>「Hoshiyama Mod Menu」を有効にする
3. ゲームを起動する

アンインストールは、パックを無効にするだけです。ゲームや Cemu 本体のファイルは変更しません。

**OneShotted など、同じ場所を書き換えるほかの MOD メニューとは同時に有効にしないでください。**

## 操作 / Controls

| 操作 | 動き |
|---|---|
| Lスティック押し込み | メニューを開く / 閉じる |
| 十字キー上下 | カーソル移動 |
| 十字キー左右 | 値の変更(Fly Speed、Bot Battle のマップ) |
| L | 決定 |
| 右スティックを上に倒す | Fly ON(メニューなしで使える) |
| A と B を同時押し | Fly OFF |

## 仕組み / How it works

Cemu のグラフィックパックの機能で、ゲームの実行ファイルのいくつかの命令を自分の関数への `bl` / `b` に置き換えています。
書き換えている場所と目的は、`patch_hoshiyama.asm` の最後にまとめてあります。

解析の過程は、Qiita の記事にまとめています。
(https://qiita.com/jaki/items/a6bbaf6616f0949fe832)

## クレジット / Credits

- [OneShotted Safe](https://gamebanana.com/mods/727374) by Folp(MIT License)
  - プレイヤーの座標・入力・描画・シーン切り替えのアドレスは、この MOD の解析を出発点にしています(コードは新しく書いたものです)
- [GhidraRPXLoader](https://github.com/Maschell/GhidraRPXLoader) by Maschell(解析に使用)
- アセンブリの作成と解析には、Claude / Claude Code を使っています

## 免責 / Disclaimer

- ファンによる非公式の制作物です。任天堂、そのほかの企業とは一切関係ありません。Splatoon は任天堂の商標です
- このパックの使用によって生じた、オンラインサービスでの BAN・データの消失などについて、作者は責任を負いません。自己責任で使ってください

## ライセンス / License

このリポジトリのコード(`rules.txt`、`patch_hoshiyama.asm`)は MIT License です。[LICENSE](LICENSE) を見てください。
任天堂のコンテンツには適用されません。
