package etl

import (
	"hrbrain/fourkeys/scripts/bigquery"
	"testing"
)

func Test_ExtractFromGithub(t *testing.T) {
	t.SkipNow()
	type args struct {
		month int
	}
	tests := []struct {
		name string
		args args
		want bool
	}{
		{
			name: "test1",
			args: args{month: 3},
			want: true,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := bigquery.ExtractFromGithub(tt.args.month); got != tt.want {
				t.Errorf("ExtractFromGithub() = %v, want %v", got, tt.want)
			}
		})
	}
}

func Test_LoadToBigquery(t *testing.T) {
	tests := []struct {
		name    string
		wantErr bool
	}{
		{
			name:    "test1",
			wantErr: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if err := bigquery.LoadToBigquery(); (err != nil) != tt.wantErr {
				t.Errorf("LoadToBigquery() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
