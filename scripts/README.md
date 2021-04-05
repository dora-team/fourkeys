# Original scripts

このディレクトリは fork ( https://github.com/GoogleCloudPlatform/fourkeys ) 後に追加したものです。

## What the script does

全てのアクティブレポジトリの過去3ヶ月分のGithubのPull Request情報を取得しBigqueryに抽出します。

過去のデータをグラフに反映させて確認したかったので一時的に作成したものです。運用目的ではないので今後使うことはないですが、コードだけ残してあります。

## Running the script

```shell
GITHUB_ACCESS_TOKEN=xxxxxxxxxxxxxxxxxxxxxxx go run main.go
```