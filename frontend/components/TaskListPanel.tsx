import React, { useState, useEffect } from 'react'
import axios from 'axios'

interface Props {
  tasks: string[]
  selectedTask: string
  onSelectTask: (taskId: string) => void
}

interface TaskInfo {
  task_id: string
  status: string
  progress: number
}

export default function TaskListPanel({ tasks, selectedTask, onSelectTask }: Props) {
  const [taskDetails, setTaskDetails] = useState<{ [key: string]: TaskInfo }>({})

  useEffect(() => {
    const fetchTaskDetails = async () => {
      const details: { [key: string]: TaskInfo } = {}
      for (const taskId of tasks) {
        try {
          const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:8000'
          const response = await axios.get(`${backendUrl}/api/task_status/${taskId}`)
          details[taskId] = {
            task_id: taskId,
            status: response.data.status,
            progress: response.data.progress,
          }
        } catch (err) {
          details[taskId] = {
            task_id: taskId,
            status: 'unknown',
            progress: 0,
          }
        }
      }
      setTaskDetails(details)
    }

    if (tasks.length > 0) {
      fetchTaskDetails()
      const interval = setInterval(fetchTaskDetails, 3000)
      return () => clearInterval(interval)
    }
  }, [tasks])

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending':
        return 'text-gray-400'
      case 'running':
        return 'text-blue-400'
      case 'completed':
        return 'text-green-400'
      case 'failed':
        return 'text-red-400'
      default:
        return 'text-slate-400'
    }
  }

  return (
    <div className="bg-slate-800 rounded-lg border border-slate-700 p-8 shadow-lg h-fit sticky top-8">
      <h3 className="text-xl font-bold text-white mb-4">Task Queue ({tasks.length})</h3>
      {tasks.length === 0 ? (
        <p className="text-slate-400">No tasks yet. Submit one to get started!</p>
      ) : (
        <div className="space-y-2 max-h-96 overflow-y-auto">
          {tasks.map((taskId) => {
            const taskInfo = taskDetails[taskId]
            return (
              <button
                key={taskId}
                onClick={() => onSelectTask(taskId)}
                className={`w-full text-left p-3 rounded-lg border transition-colors ${
                  selectedTask === taskId
                    ? 'border-blue-500 bg-blue-900 bg-opacity-30'
                    : 'border-slate-600 bg-slate-900 bg-opacity-50 hover:bg-opacity-100'
                }`}
              >
                <div className="flex items-center justify-between">
                  <div className="flex-1 truncate">
                    <div className="text-sm font-mono text-slate-300 truncate">
                      {taskId.slice(0, 8)}...
                    </div>
                    <div className={`text-xs ${getStatusColor(taskInfo?.status || 'unknown')}`}>
                      {taskInfo?.status || 'unknown'}
                    </div>
                  </div>
                  <div className="text-right ml-2">
                    <div className="text-xs text-slate-400">
                      {taskInfo?.progress || 0}%
                    </div>
                  </div>
                </div>
              </button>
            )
          })}
        </div>
      )}
    </div>
  )
}
