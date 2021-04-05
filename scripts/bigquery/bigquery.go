package bq

import (
	"context"
	"time"

	"cloud.google.com/go/bigquery"
	"google.golang.org/api/option"
)

const datasetID = "four_keys"

type client struct {
	*bigquery.Client
}

func NewClient(ctx context.Context, projectID, keyFile string) (*client, error) {
	cli, err := bigquery.NewClient(ctx, projectID, option.WithCredentialsFile(keyFile))
	if err != nil {
		return nil, err
	}

	return &client{cli}, nil
}

type EventsRawSchema struct {
	EventType   string    `bigquery:"event_type"`
	ID          string    `bigquery:"id"`
	Metadata    string    `bigquery:"metadata"`
	TimeCreated time.Time `bigquery:"time_created"`
	Signature   string    `bigquery:"signature"`
	MsgID       string    `bigquery:"msg_id"`
	Source      string    `bigquery:"source"`
}

func (client *client) UploadEventsRaw(ctx context.Context, rows []*EventsRawSchema) error {
	table := client.Dataset(datasetID).Table("events_raw")
	u := table.Inserter()
	return u.Put(ctx, rows)
}

type ChangesSchema struct {
	Source      string    `bigquery:"source"`
	ChangeID    string    `bigquery:"change_id"`
	TimeCreated time.Time `bigquery:"time_created"`
	EventType   string    `bigquery:"event_type"`
}

func (client *client) UploadChanges(ctx context.Context, rows []*ChangesSchema) error {
	table := client.Dataset(datasetID).Table("changes")
	u := table.Inserter()
	return u.Put(ctx, rows)
}

type DeploymentsSchema struct {
	Source      string    `bigquery:"source"`
	DeployID    string    `bigquery:"deploy_id"`
	TimeCreated time.Time `bigquery:"time_created"`
	EventType   []string  `bigquery:"changes"`
}

func (client *client) UploadDeployments(ctx context.Context, rows []*DeploymentsSchema) error {
	table := client.Dataset(datasetID).Table("deployments")
	u := table.Inserter()
	return u.Put(ctx, rows)
}
