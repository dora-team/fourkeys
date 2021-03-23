package scripts

import "testing"

func Test_exec(t *testing.T) {
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
			if got := exec(tt.args.month); got != tt.want {
				t.Errorf("exec() = %v, want %v", got, tt.want)
			}
		})
	}
}
