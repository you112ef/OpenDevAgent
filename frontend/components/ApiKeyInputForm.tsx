import React, { useState } from 'react'
import axios from 'axios'

interface Props {
  onApiKeySet: (key: string) => void
}

export default function ApiKeyInputForm({ onApiKeySet }: Props) {
  const [apiKey, setApiKey] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:8000'
      const response = await axios.get(`${backendUrl}/health`)
      
      if (response.status === 200) {
        onApiKeySet(apiKey)
      }
    } catch (err) {
      setError('Failed to connect to backend. Please ensure the backend is running.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="bg-slate-800 rounded-lg border border-slate-700 p-8 shadow-lg">
      <h2 className="text-2xl font-bold text-white mb-6">Configure OpenRouter API</h2>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="apiKey" className="block text-sm font-medium text-slate-300 mb-2">
            OpenRouter API Key
          </label>
          <input
            type="password"
            id="apiKey"
            value={apiKey}
            onChange={(e) => setApiKey(e.target.value)}
            placeholder="sk-or-v1-..."
            className="w-full px-4 py-3 bg-slate-900 border border-slate-600 rounded-lg text-white placeholder-slate-500 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
            required
          />
          <p className="mt-2 text-xs text-slate-400">
            Your API key is used securely on the backend and never stored. 
            Get your key from <a href="https://openrouter.ai" target="_blank" rel="noopener noreferrer" className="text-blue-400 hover:text-blue-300">openrouter.ai</a>
          </p>
        </div>

        {error && (
          <div className="bg-red-900 border border-red-700 text-red-200 px-4 py-3 rounded">
            {error}
          </div>
        )}

        <button
          type="submit"
          disabled={loading || !apiKey.trim()}
          className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-slate-700 text-white font-bold py-3 px-4 rounded-lg transition-colors"
        >
          {loading ? 'Verifying...' : 'Configure & Continue'}
        </button>
      </form>
    </div>
  )
}
