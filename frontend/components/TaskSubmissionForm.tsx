import React, { useState } from 'react'
import axios from 'axios'

interface Props {
  apiKey: string
  onTaskSubmitted: (taskId: string) => void
}

export default function TaskSubmissionForm({ apiKey, onTaskSubmitted }: Props) {
  const [taskDescription, setTaskDescription] = useState('')
  const [targetLanguage, setTargetLanguage] = useState('python')
  const [targetFramework, setTargetFramework] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:8000'
      const response = await axios.post(`${backendUrl}/api/submit_task`, {
        task_description: taskDescription,
        target_language: targetLanguage,
        target_framework: targetFramework || null,
        openrouter_api_key: apiKey,
      })

      if (response.data.task_id) {
        onTaskSubmitted(response.data.task_id)
        setTaskDescription('')
        setTargetFramework('')
      }
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Failed to submit task')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="bg-slate-800 rounded-lg border border-slate-700 p-8 shadow-lg">
      <h2 className="text-2xl font-bold text-white mb-6">Submit Development Task</h2>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="description" className="block text-sm font-medium text-slate-300 mb-2">
            Feature Description
          </label>
          <textarea
            id="description"
            value={taskDescription}
            onChange={(e) => setTaskDescription(e.target.value)}
            placeholder="Describe the software feature or component you want the AI agent to build..."
            rows={6}
            className="w-full px-4 py-3 bg-slate-900 border border-slate-600 rounded-lg text-white placeholder-slate-500 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
            required
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label htmlFor="language" className="block text-sm font-medium text-slate-300 mb-2">
              Target Language
            </label>
            <select
              id="language"
              value={targetLanguage}
              onChange={(e) => setTargetLanguage(e.target.value)}
              className="w-full px-4 py-3 bg-slate-900 border border-slate-600 rounded-lg text-white focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
            >
              <option value="python">Python</option>
              <option value="javascript">JavaScript</option>
              <option value="typescript">TypeScript</option>
              <option value="java">Java</option>
              <option value="csharp">C#</option>
            </select>
          </div>

          <div>
            <label htmlFor="framework" className="block text-sm font-medium text-slate-300 mb-2">
              Framework (Optional)
            </label>
            <input
              type="text"
              id="framework"
              value={targetFramework}
              onChange={(e) => setTargetFramework(e.target.value)}
              placeholder="e.g., Django, React, FastAPI"
              className="w-full px-4 py-3 bg-slate-900 border border-slate-600 rounded-lg text-white placeholder-slate-500 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
            />
          </div>
        </div>

        {error && (
          <div className="bg-red-900 border border-red-700 text-red-200 px-4 py-3 rounded">
            {error}
          </div>
        )}

        <button
          type="submit"
          disabled={loading || !taskDescription.trim()}
          className="w-full bg-green-600 hover:bg-green-700 disabled:bg-slate-700 text-white font-bold py-3 px-4 rounded-lg transition-colors"
        >
          {loading ? 'Submitting Task...' : 'Submit Task'}
        </button>
      </form>
    </div>
  )
}
