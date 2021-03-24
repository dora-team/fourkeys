package bq

import (
	"context"
	"time"

	"cloud.google.com/go/bigquery"
	"google.golang.org/api/option"
)

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

type Schema struct {
	Source      string    `bigquery:"source"`
	ChangeID    string    `bigquery:"change_id"`
	TimeCreated time.Time `bigquery:"time_created"`
	EventType   string    `bigquery:"event_type"`
}

func (client *client) Upload(ctx context.Context, datasetID, tableID string, rows []*Schema) error {
	table := client.Dataset(datasetID).Table(tableID)

	u := table.Inserter()

	return u.Put(ctx, rows)
}
