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
	bqSchemaSource    = "script"
)

func main() {
	ctx := context.Background()

	// setup
	ghClient := gh.NewClient(ctx, githubAccessToken)
	bqClient, err := bq.NewClient(ctx, gcloudProjectID, gcloudKeyFile)
	if err != nil {
		panic(err)
	}

	// init bq event_raw table for extracting DAY
	if err := bqClient.UploadEventsRaw(ctx, []*bq.EventsRawSchema{{
		EventType: "init",
		ID:        "init",
		Metadata:  "init",
		TimeCreated: func() time.Time {
			t, _ := time.Parse("2006-01-02", "2020-01-01")
			return t.Truncate(time.Second)
		}(),
		Signature: "init",
		MsgID:     "init",
		Source:    bqSchemaSource,
	}}); err != nil {
		panic(err)
	}

	repos, err := ghClient.ListAllRepositories(ctx)
	if err != nil {
		panic(err)
	}

	var totalPullsCount int

	for _, repo := range repos {
		page := 1
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

			rowsChanges := make([]*bq.ChangesSchema, 0, pullsCount*4)
			rowsDeployments := make([]*bq.DeploymentsSchema, 0, pullsCount)
			for _, pull := range pulls {
				mergedSHA := pull.MergeCommitSHA
				createdSHA := fmt.Sprintf("%s-created", mergedSHA)

				// changes schema
				rowsChanges = append(rowsChanges, &bq.ChangesSchema{
					Source:      bqSchemaSource,
					ChangeID:    strconv.Itoa(pull.Number),
					TimeCreated: pull.CreatedAt,
					EventType:   "pull_request",
				})
				rowsChanges = append(rowsChanges, &bq.ChangesSchema{
					Source:      bqSchemaSource,
					ChangeID:    createdSHA,
					TimeCreated: pull.CreatedAt,
					EventType:   "push",
				})
				rowsChanges = append(rowsChanges, &bq.ChangesSchema{
					Source:      bqSchemaSource,
					ChangeID:    strconv.Itoa(pull.Number),
					TimeCreated: pull.MergedAt,
					EventType:   "pull_request",
				})
				rowsChanges = append(rowsChanges, &bq.ChangesSchema{
					Source:      bqSchemaSource,
					ChangeID:    mergedSHA,
					TimeCreated: pull.MergedAt,
					EventType:   "push",
				})

				// deployments schema
				rowsDeployments = append(rowsDeployments, &bq.DeploymentsSchema{
					Source:      bqSchemaSource,
					DeployID:    pull.MergeCommitSHA,
					TimeCreated: pull.MergedAt,
					EventType:   []string{createdSHA, mergedSHA},
				})
			}

			if err := bqClient.UploadChanges(ctx, rowsChanges); err != nil {
				log.Println(err)
			}
			if err := bqClient.UploadDeployments(ctx, rowsDeployments); err != nil {
				log.Println(err)
			}

			page++
		}
	}

	fmt.Println(totalPullsCount, "pull requests processed")
}
