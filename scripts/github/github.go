package gh

import (
	"context"
	"time"

	"github.com/google/go-github/v33/github"
	"golang.org/x/oauth2"
)

const githubOrganization = "hrbrain"

var timeAgo = time.Now().AddDate(0, -3, 0)

type client struct {
	*github.Client
}

func NewClient(ctx context.Context, accessToken string) *client {
	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: accessToken},
	)
	tc := oauth2.NewClient(ctx, ts)

	cli := github.NewClient(tc)

	return &client{cli}
}

func (client *client) ListAllRepositories(ctx context.Context) ([]string, error) {
	var list []string
	page := 1

	for {
		repos, _, err := client.Repositories.ListByOrg(ctx, githubOrganization, &github.RepositoryListByOrgOptions{
			ListOptions: github.ListOptions{
				PerPage: 100,
				Page:    page,
			},
		})
		if err != nil {
			return make([]string, 0), err
		}
		if len(repos) == 0 {
			break
		}

		for _, repo := range repos {
			if *repo.Archived {
				continue
			}
			list = append(list, *repo.Name)
		}

		page++
	}

	return list, nil
}

type PullRequest struct {
	Number         int
	MergeCommitSHA string
	CreatedAt      time.Time
	MergedAt       time.Time
}

func (client *client) ListPullRequests(ctx context.Context, repo string, page int) (
	[]*PullRequest, error) {

	const size = 100
	pulls, _, err := client.PullRequests.List(ctx, githubOrganization, repo,
		&github.PullRequestListOptions{
			State: "closed",
			ListOptions: github.ListOptions{
				PerPage: size,
				Page:    page,
			},
		})
	if err != nil {
		return make([]*PullRequest, 0), err
	}

	list := make([]*PullRequest, 0, size)

	for _, pull := range pulls {
		if pull.ClosedAt.Before(timeAgo) {
			continue
		}
		if pull.MergedAt == nil {
			continue
		}

		list = append(list, &PullRequest{
			Number:         *pull.Number,
			MergeCommitSHA: *pull.MergeCommitSHA,
			CreatedAt:      *pull.CreatedAt,
			MergedAt:       *pull.MergedAt,
		})
	}

	return list, nil
}
