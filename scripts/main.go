package main

import (
	"context"
	"fmt"
	bq "hrbrain/fourkeys/scripts/bigquery"
	gh "hrbrain/fourkeys/scripts/github"
	"log"
	"os"
	"strconv"
	"time"
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

	repos, err := ghClient.ListAllRepositories(ctx)
	if err != nil {
		panic(err)
	}

	page := 1
	const bqSchemaSource = "test"

	for _, repo := range repos {
		fmt.Println("processing", repo)
		for {
			pulls, err := ghClient.ListPullRequests(ctx, repo, page)
			if err != nil {
				log.Println(err)
				break
			}
			fmt.Println("pulls size", len(pulls))
			if len(pulls) == 0 {
				break
			}

			rows := make([]*bq.Schema, 0, len(pulls)*3)
			for _, pull := range pulls {
				fmt.Println("pull number", pull.Number)
				// row1
				rows = append(rows, &bq.Schema{
					Source:      bqSchemaSource,
					ChangeID:    strconv.Itoa(pull.Number),
					TimeCreated: pull.CreatedAt.Truncate(time.Second),
					EventType:   "pull_request",
				})
				// row2
				rows = append(rows, &bq.Schema{
					Source:      bqSchemaSource,
					ChangeID:    strconv.Itoa(pull.Number),
					TimeCreated: pull.MergedAt.Truncate(time.Second),
					EventType:   "pull_request",
				})
				// row3
				rows = append(rows, &bq.Schema{
					Source:      bqSchemaSource,
					ChangeID:    pull.MergeCommitSHA,
					TimeCreated: pull.MergedAt.Truncate(time.Second),
					EventType:   "push",
				})
			}
			//bqClient.Upload(ctx, "four_keys", "changes", rows)

			page++
		}
	}

}
