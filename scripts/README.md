# Original scripts

このディレクトリは fork ( https://github.com/GoogleCloudPlatform/fourkeys ) 後に追加したものです。

## What the script does

全てのアクティブレポジトリの過去3ヶ月分のGithubのPull Request情報を取得しBigqueryに抽出します。

## Running the script

```shell
GITHUB_ACCESS_TOKEN=xxxxxxxxxxxxxxxxxxxxxxx go run main.go
```