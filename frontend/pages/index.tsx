import React, { useState } from 'react'
import axios from 'axios'
import ApiKeyInputForm from '../components/ApiKeyInputForm'
import TaskSubmissionForm from '../components/TaskSubmissionForm'
import AgentStatusDashboard from '../components/AgentStatusDashboard'
import TaskListPanel from '../components/TaskListPanel'

export default function Home() {
  const [apiKey, setApiKey] = useState<string>('')
  const [isApiKeySet, setIsApiKeySet] = useState<boolean>(false)
  const [currentTaskId, setCurrentTaskId] = useState<string>('')
  const [tasks, setTasks] = useState<string[]>([])

  const handleApiKeySet = (key: string) => {
    setApiKey(key)
    setIsApiKeySet(true)
  }

  const handleTaskSubmitted = (taskId: string) => {
    setCurrentTaskId(taskId)
    setTasks(prev => [...prev, taskId])
  }

  const handleSelectTask = (taskId: string) => {
    setCurrentTaskId(taskId)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
      <div className="container mx-auto p-8">
        <header className="mb-12">
          <h1 className="text-5xl font-bold text-white mb-2">OpenDevAgent</h1>
          <p className="text-xl text-slate-300">
            Kilo-Inspired AI Software Engineer with Plan-Act-Observe-Fix Loop
          </p>
        </header>

        {!isApiKeySet ? (
          <div className="max-w-2xl mx-auto">
            <ApiKeyInputForm onApiKeySet={handleApiKeySet} />
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-2 space-y-8">
              <TaskSubmissionForm
                apiKey={apiKey}
                onTaskSubmitted={handleTaskSubmitted}
              />
              {currentTaskId && (
                <AgentStatusDashboard taskId={currentTaskId} />
              )}
            </div>
            <div>
              <TaskListPanel
                tasks={tasks}
                selectedTask={currentTaskId}
                onSelectTask={handleSelectTask}
              />
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
