package main

import (
	"context"
	"fmt"
	gh "hrbrain/fourkeys/scripts/github"
	"os"
)

var (
	githubAccessToken = os.Getenv("GITHUB_ACCESS_TOKEN")
	gcloudKeyFile     = "/Users/yukichi/Downloads/hrb-fourkeys-9fbc5da5546f.json"
	gcloudProjectID   = "hrb-=fourkeys"
)

func main() {
	ctx := context.Background()

	// setup
	ghClient := gh.NewClient(ctx, githubAccessToken)
	//bqClient, err := bq.NewClient(ctx, gcloudProjectID, gcloudKeyFile)
	//if err != nil {
	//	panic(err)
	//}

	//repos, err := ghClient.ListAllRepositories(ctx)
	//if err != nil {
	//	panic(err)
	//}

	pulls, err := ghClient.ListPullRequests(ctx, "app", 1)
	if err != nil {
		panic(err)
	}

	fmt.Println(len(pulls))
	fmt.Println(pulls[0])

	//const source = "github_past"
	//// bq table row1
	//fmt.Println("source", source)
	//fmt.Println("change_id", *pull.Number)
	//fmt.Println("time_created", *pull.CreatedAt)
	//fmt.Println("event_type", "pull_request")
	//// bq table row2
	//fmt.Println("source", source)
	//fmt.Println("change_id", *pull.Number)
	//fmt.Println("time_created", *pull.MergedAt)
	//fmt.Println("event_type", "pull_request")
	//// bq table row3
	//fmt.Println("source", source)
	//fmt.Println("change_id", *pull.MergeCommitSHA)
	//fmt.Println("time_created", *pull.MergedAt)
	//fmt.Println("event_type", "push")

	//// load to bigquery
	//rows := []*bigquery.Schema{
	//	{Source: "hoge", ChangeID: "fuga", TimeCreated: time.Now().Truncate(time.Second), EventType: "test"},
	//}
	//bqClient.Upload(ctx, "four_keys", "changes", rows)
}
