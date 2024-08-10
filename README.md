これは標準的な API と静的フロントエンドによって構成される web アプリケーション(SPA)の構成サンプルです。
まずは以下のチュートリアルで一連の使い方を体験しましょう

# チュートリアル

まずはチュートリアルをやりましょう。これによってローカル環境のセットアップから、AWS へのデプロイまでを体験できます。
まずこのテンプレートリポジトリから新たに練習用リポジトリを作成しましょう。
(CI の設定などがあるので、このリポジトリのままではチュートリアルできません。CI を実行する手前まではこのリポジトリのままでもできます)
また、AWS のサンドボックス環境のユーザを事前に用意しておきましょう。サンドボックスユーザで実行することを前提にしています。

`TUTORIAL:` でリポジトリ内を全文検索するとステップごとの案内が各所に書かれています、番号順に進めてください。
番号は `1(ローカル環境構築)-1` のように章立てされています。

# ローカル環境

以下のツールが必要です

- docker compose: `docker-compose` ではなく `docker compose` を使いましょう
- https://taskfile.dev/ : タスクランナー。 `go install` かシングルバイナリなのでダウンロードしてくるか、後述のように npm からも入れられます。
- nodejs: [.node-version](./.node-version)のバージョンを使用します。https://asdf-vm.com/ や https://github.com/nodenv/nodenv を使用すると便利です
- pnpm
- https://www.terraform.io/ : これも https://asdf-vm.com/ で導入するのが便利です。

### おすすめ install 方法

どんな方法でも導入できれば OK ですが、おすすめは以下です

- docker は普通に install する https://docs.docker.com/engine/install/
- [asdf](https://asdf-vm.com/) を入れ、 `asdf plugin-add nodejs` で nodejs プラグインを入れる
- `asdf install nodejs latest` で nodejs を入れる(バージョンはよしなに latest から変更します)
- `asdf plugin add terraform` で terraform プラグインを入れる(以下同様)
- `npm install -g @go-task/cli` で task を入れる(go の環境が整ってる人は `go install` のほうが楽です)
- `npm install -g pnpm` で pnpm を入れる

> TIPS:
> WSL 環境では asdf で nodejs を入れてから npm 経由で task と pnpm を入れるのが早いらしいです
> `npm install -g @go-task/cli` > `npm install -g pnpm`

TUTORIAL:1(ローカル環境構築)-1 まず、必要なツールをインストールしましょう
↑ のツールをインストールし、`docker compose` 及び `task`, `pnpm`, `terraform` コマンドが使えるようにしましょう

# 使用方法

### 環境全体について

ディレクトリ構成は以下のようになっています

- [.github](./.github/): github actions による CI 設定が入っています
- [api](./api): API サーバです。python(fastAPI)で実装されていますが、Dockerfile で動くようにしておけば他の言語に書き換えても OK です。
- [frontend](./frontend): 静的フロントエンドです。React(NextJS) で実装されています。静的 html にビルドできればそれ以外フレームワーク等に任意に書き換えても OK です。
- [terraform](./terraform): AWS へのデプロイに関する設定が入っています。terraform で記述されています。
- [.env](./.env): docker compose で使用する環境変数のデフォルト値が入っています。このファイルを編集することで、API やフロントのポートを変更できます。
- [taskfile.yml](./taskfile.yml): タスクランナーです。 `task` コマンドで実行できます。利便性のため入れていますが、必須ではないです。Makefile などに書き換えても OK です。
- [docker-compose.yml](./docker-compose.yml): docker compose の設定ファイルです。このファイルを編集することで、docker compose の動作を変更できます。

TUTORIAL:1(ローカル環境構築)-2 これらの構成を眺めておきましょう。特に `.env` ファイルを変更して、API サーバやフロントのポートを変更できることを覚えておきましょう
(このファイルを書き換えるのではなく、環境変数を定義しても同じ効果が得られます)
(チュートリアルを進める中で、ローカル環境によってはポート競合などから変更が必要になる場合があります)

### ローカルで API を起動する

開発用に API をローカル環境で起動することができます。

```sh
docker compose up
```

ローカルで API を起動します。同時に mysql も起動します。
API_PORT 等の環境変数によって設定を変更できます。
これらの値は .env にデフォルト値が設定されています(docker compose は自動的に.env を読みます)
上書きする場合、一時的な作業であれば.env を編集すればよいですが、誤ってコミットしないように注意してください。
永続的に変更したい場合、https://github.com/direnv/direnv などを使用してください。

TUTORIAL:1(ローカル環境構築)-3 ↑ のコマンドを実行し、 `curl localhost:8080` などで API を叩けること確認しましょう

### ローカルでフロントエンドを起動する

同様にフロントエンドもローカルで起動できます。NextJS 標準のホットリロードがついてます。

初回のみ以下を実行して、依存関係をセットアップします。

```sh
pnpm i
```

以下のコマンドでフロントエンド開発サーバを起動します。
このフロントエンドはローカルに立てた API を呼び出せるようになっています。

```sh
task dev-frontend
```

[.node-version](./.node-version)で使用する nodejs のバージョンを制御します

TUTORIAL:1(ローカル環境構築)-4 API が起動した状態で、↑ のコマンドを実行してフロントエンド開発サーバをブラウザで表示しましょう
左上のボタンをクリックするとコンソールに API レスポンスが表示されます
