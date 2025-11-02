import React, { useState, useEffect } from 'react'
import axios from 'axios'

interface Props {
  taskId: string
}

interface TaskStatus {
  task_id: string
  status: string
  phase: string
  progress: number
  logs: string[]
  result?: any
  error?: string
}

const PHASE_NAMES = {
  planning: 'Planning',
  coding: 'Coding',
  testing: 'Testing',
  debugging: 'Debugging',
  complete: 'Complete'
}

const PHASE_COLORS = {
  planning: 'bg-blue-500',
  coding: 'bg-purple-500',
  testing: 'bg-orange-500',
  debugging: 'bg-red-500',
  complete: 'bg-green-500'
}

export default function AgentStatusDashboard({ taskId }: Props) {
  const [taskStatus, setTaskStatus] = useState<TaskStatus | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    const fetchStatus = async () => {
      try {
        const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:8000'
        const response = await axios.get(`${backendUrl}/api/task_status/${taskId}`)
        setTaskStatus(response.data)
        setError('')
      } catch (err: any) {
        setError('Failed to fetch task status')
      } finally {
        setLoading(false)
      }
    }

    fetchStatus()
    const interval = setInterval(fetchStatus, 2000)
    return () => clearInterval(interval)
  }, [taskId])

  if (loading) {
    return (
      <div className="bg-slate-800 rounded-lg border border-slate-700 p-8 shadow-lg">
        <div className="animate-pulse">
          <div className="h-8 bg-slate-700 rounded w-1/3 mb-4"></div>
          <div className="h-4 bg-slate-700 rounded w-full mb-2"></div>
          <div className="h-4 bg-slate-700 rounded w-full mb-2"></div>
        </div>
      </div>
    )
  }

  if (!taskStatus) {
    return (
      <div className="bg-slate-800 rounded-lg border border-slate-700 p-8 shadow-lg text-red-400">
        Task not found
      </div>
    )
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending':
        return 'bg-gray-500'
      case 'running':
        return 'bg-blue-500'
      case 'completed':
        return 'bg-green-500'
      case 'failed':
        return 'bg-red-500'
      default:
        return 'bg-gray-500'
    }
  }

  const phases = ['planning', 'coding', 'testing', 'debugging', 'complete']
  const currentPhaseIndex = phases.indexOf(taskStatus.phase as any)

  return (
    <div className="space-y-8">
      <div className="bg-slate-800 rounded-lg border border-slate-700 p-8 shadow-lg">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-white">Agent Status</h2>
          <span className={`px-4 py-2 rounded-full text-white font-bold ${getStatusColor(taskStatus.status)}`}>
            {taskStatus.status.toUpperCase()}
          </span>
        </div>

        <div className="mb-6">
          <div className="text-sm text-slate-400 mb-2">Task ID: {taskId}</div>
          <div className="text-sm text-slate-400 mb-4">Progress: {taskStatus.progress}%</div>
          <div className="w-full bg-slate-900 rounded-full h-2 border border-slate-700">
            <div
              className="bg-gradient-to-r from-blue-500 to-purple-500 h-2 rounded-full transition-all duration-300"
              style={{ width: `${taskStatus.progress}%` }}
            ></div>
          </div>
        </div>

        <div className="mb-6">
          <h3 className="text-lg font-semibold text-slate-300 mb-4">Execution Phases</h3>
          <div className="space-y-2">
            {phases.map((phase, idx) => (
              <div key={phase} className="flex items-center">
                <div
                  className={`w-8 h-8 rounded-full flex items-center justify-center font-bold mr-3 ${
                    idx <= currentPhaseIndex
                      ? PHASE_COLORS[phase as keyof typeof PHASE_COLORS]
                      : 'bg-slate-700'
                  }`}
                >
                  {idx < currentPhaseIndex ? '✓' : idx === currentPhaseIndex ? '◉' : idx + 1}
                </div>
                <span className={idx <= currentPhaseIndex ? 'text-white' : 'text-slate-400'}>
                  {PHASE_NAMES[phase as keyof typeof PHASE_NAMES]}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="bg-slate-800 rounded-lg border border-slate-700 p-8 shadow-lg">
        <h3 className="text-lg font-semibold text-white mb-4">Execution Logs</h3>
        <div className="bg-slate-900 rounded p-4 max-h-96 overflow-y-auto border border-slate-700">
          <div className="font-mono text-sm text-slate-300 space-y-1">
            {taskStatus.logs.map((log, idx) => (
              <div key={idx} className="text-slate-400">
                {log}
              </div>
            ))}
          </div>
        </div>
      </div>

      {taskStatus.error && (
        <div className="bg-red-900 border border-red-700 rounded-lg p-8">
          <h3 className="text-lg font-semibold text-red-200 mb-4">Error</h3>
          <p className="text-red-300">{taskStatus.error}</p>
        </div>
      )}

      {taskStatus.result && (
        <div className="bg-green-900 border border-green-700 rounded-lg p-8">
          <h3 className="text-lg font-semibold text-green-200 mb-4">Result</h3>
          <pre className="bg-slate-900 p-4 rounded overflow-x-auto text-sm text-green-300">
            {JSON.stringify(taskStatus.result, null, 2)}
          </pre>
        </div>
      )}
    </div>
  )
}
