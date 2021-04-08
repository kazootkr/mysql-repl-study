# mysql-repl-study

## 用途

- 実験用にレプリケーション構成のMySQLサーバーがほしい時
- レプリケーション構成の開発環境を用意したい時

## 使い方

dockerをインストールしたうえで下記のコマンドを実行すると起動します。

```shell
make
```

`SHOW SLAVE SATUS` を確認したい場合は下記が便利です。

```shell
make stats
```

MySQL公式からサンプルデータを取得してインポートします。

```shell
make import
```

プライマリのボリュームをコピーしてレプリカを作成することもできます。

```shell
# レプリカが存在しない状態から
make create-replica-from-primary
docker compose up -d
# レプリカに対して設定を行い、レプリケーション開始する
make prepare-repl.sh
```