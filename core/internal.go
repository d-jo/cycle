package core

import (
	"container/heap"
)

var (
	TIMEOUT_SECONDS = 60
)

type Miner struct {
	Id                 int
	AssignedJobs       []int
	LastAssignmentTime int
	CompletedJobs      int
}

type Job struct {
	Id           int
	CreationTime int
	SolvedTime   int
	Priority     int
	index        int
	Data         *[]byte
	Solutions    map[int][]byte
}

type JobDispatcher []*Job

func (jd *JobDispatcher) Push(x interface{}) {
	len := len(*jd)
	job := x.(*Job)
	job.index = len
	*jd = append(*jd, job)
}

func (jd *JobDispatcher) Pop() interface{} {
	old := *jd
	length := len(old)
	ret := old[len-1]
	ret.index = -1
	*jd = old[0 : len-1]
	return ret
}
