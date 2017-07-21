package core

import (
	"container/heap"
)

var (
	TIMEOUT_SECONDS = 60
)

type address string

type Miner struct {
	Id                 address
	AssignedJobs       []int
	LastAssignmentTime int
	CompletedJobs      int
}

type Job struct {
	Id           int
	CreationTime int
	SolvedTime   int
	priority     int
	index        int
	Data         *[]byte
	Solutions    map[address]*[]byte
}

type JobDispatcher []*Job

func (jd JobDispatcher) Len() int { return len(jd) }

func (jd JobDispatcher) Less(i, j int) bool {
	return jd[i].priority > jd[j].priority
}

func (jd JobDispatcher) Swap(i, j int) {
	jd[i], jd[j] = jd[j], jd[i]
	jd[i].index = i
	jd[j].index = j
}

func (jd *JobDispatcher) Push(x interface{}) {
	len := len(*jd)
	job := x.(*Job)
	job.index = len
	*jd = append(*jd, job)
}

func (jd *JobDispatcher) Pop() interface{} {
	old := *jd
	length := old.Len()
	ret := old[length-1]
	ret.index = -1
	*jd = old[0 : length-1]
	return ret

}

func (jd *JobDispatcher) updatePriority(job *Job, priority int) {
	job.priority = priority
	heap.Fix(jd, job.index)
}
