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
	gcloudProjectID   = "hrb-fourkeys"
)

func main() {
	ctx := context.Background()

	// setup
	ghClient := gh.NewClient(ctx, githubAccessToken)
	bqClient, err := bq.NewClient(ctx, gcloudProjectID, gcloudKeyFile)
	if err != nil {
		panic(err)
	}

	repos, err := ghClient.ListAllRepositories(ctx)
	if err != nil {
		panic(err)
	}
	//repos = []string{"client"}

	page := 1
	const bqSchemaSource = "github"
	var totalPullsCount int

	for _, repo := range repos {
		fmt.Println("processing", repo)
		for {
			pulls, err := ghClient.ListPullRequests(ctx, repo, page)
			if err != nil {
				log.Println(err)
				break
			}
			pullsCount := len(pulls)
			fmt.Println("page:", page, "filtered pulls size:", pullsCount)
			if pullsCount == 0 {
				break
			}

			totalPullsCount += pullsCount

			rows := make([]*bq.Schema, 0, pullsCount*3)
			for _, pull := range pulls {
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

			err = bqClient.Upload(ctx, "four_keys", "changes", rows)
			if err != nil {
				log.Println(err)
			}

			page++
		}
		page = 1
	}

	fmt.Println(totalPullsCount, "pull requests processed")
}
