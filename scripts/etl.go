package scripts

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/google/go-github/v33/github"
	"golang.org/x/oauth2"
)

const (
	githubOrganization = "hrbrain"
)

var (
	githubAccessToken = os.Getenv("GITHUB_ACCESS_TOKEN")
)

func exec(month int) bool {
	timeAgo := time.Now().AddDate(0, -month, 0)

	ctx := context.Background()
	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: githubAccessToken},
	)
	tc := oauth2.NewClient(ctx, ts)

	client := github.NewClient(tc)

	// list repositories
	//repos, _, err := client.Repositories.ListByOrg(ctx, githubOrganization, &github.RepositoryListByOrgOptions{
	//	ListOptions: github.ListOptions{
	//		PerPage: 10,
	//		Page:    1,
	//	},
	//})
	//if err != nil {
	//	return false
	//}
	//for _, repo := range repos {
	//	if *repo.Archived {
	//		continue
	//	}
	//	fmt.Println(*repo.Name)
	//}

	// list pull requests
	var (
		page = 1
		fin  bool
	)
	for !fin {
		pulls, _, err := client.PullRequests.List(ctx, githubOrganization, "app", &github.PullRequestListOptions{
			State: "closed",
			ListOptions: github.ListOptions{
				PerPage: 10,
				Page:    page,
			},
		})
		if err != nil {
			return false
		}
		if len(pulls) == 0 {
			break
		}
		for _, pull := range pulls {
			if pull.ClosedAt.Before(timeAgo) {
				fin = true
				break
			}
			if pull.MergedAt == nil {
				fmt.Println("closed", *pull.Number)
				continue
			}
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
			fmt.Println(*pull.Number)
		}
		page++
	}

	return true
}
