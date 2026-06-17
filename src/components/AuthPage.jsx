import { useState } from 'react'
import { ForkKnife } from '@phosphor-icons/react'
import { supabase } from '../lib/supabase.js'

export default function AuthPage() {
  const [mode, setMode] = useState('signin')
  const [displayName, setDisplayName] = useState('')
  const [groupName, setGroupName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const [notice, setNotice] = useState(null)

  function switchMode(next) {
    setMode(next)
    setError(null)
    setNotice(null)
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setLoading(true)
    setError(null)
    setNotice(null)

    if (mode === 'signup') {
      if (password !== confirmPassword) {
        setError('Passwords do not match.')
        setLoading(false)
        return
      }
      const { error: err } = await supabase.auth.signUp({
        email,
        password,
        options: { data: { display_name: displayName.trim(), community_group_name: groupName.trim() } },
      })
      if (err) {
        setError(err.message)
      } else {
        setNotice('Account created! Check your email to confirm, then sign in.')
        switchMode('signin')
      }
    } else {
      const { error: err } = await supabase.auth.signInWithPassword({ email, password })
      if (err) setError(err.message)
      // on success, App.jsx's onAuthStateChange fires and shows the main app
    }

    setLoading(false)
  }

  const inputClass =
    'w-full border border-stone-200 rounded-xl px-3.5 py-2.5 text-stone-800 placeholder:text-stone-400 focus:outline-none focus:ring-2 focus:ring-jade focus:border-transparent transition-shadow text-sm'

  return (
    <div
      className="min-h-screen bg-sunrise-50 flex items-center justify-center p-4"
      style={{ paddingTop: 'env(safe-area-inset-top)' }}
    >
      <div className="w-full max-w-sm">
        {/* Logo */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-jade mb-4">
            <ForkKnife size={32} weight="fill" className="text-white" />
          </div>
          <h1 className="text-2xl font-bold text-stone-800">Community Group</h1>
          <p className="text-stone-500 mt-1 text-sm">Sign up for meals and service, chat with your group, and remember birthdays!</p>
        </div>

        {/* Card */}
        <div className="bg-white rounded-2xl shadow-sm border border-stone-100 overflow-hidden">
          {/* Mode toggle */}
          <div className="flex border-b border-stone-100">
            <button
              type="button"
              onClick={() => switchMode('signin')}
              className={`flex-1 py-3.5 text-sm font-semibold transition-colors ${
                mode === 'signin'
                  ? 'text-jade border-b-2 border-jade -mb-px'
                  : 'text-stone-400 hover:text-stone-600'
              }`}
            >
              Sign In
            </button>
            <button
              type="button"
              onClick={() => switchMode('signup')}
              className={`flex-1 py-3.5 text-sm font-semibold transition-colors ${
                mode === 'signup'
                  ? 'text-jade border-b-2 border-jade -mb-px'
                  : 'text-stone-400 hover:text-stone-600'
              }`}
            >
              Create Account
            </button>
          </div>

          <form onSubmit={handleSubmit} className="p-6 space-y-4">
            {mode === 'signup' && (
              <>
                <div>
                  <label className="block text-xs font-semibold text-stone-600 mb-1.5 uppercase tracking-wide">
                    Your Name
                  </label>
                  <input
                    type="text"
                    value={displayName}
                    onChange={e => setDisplayName(e.target.value)}
                    placeholder="e.g. Jane Smith"
                    required
                    autoComplete="name"
                    className={inputClass}
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-stone-600 mb-1.5 uppercase tracking-wide">
                    Community Group Name
                  </label>
                  <input
                    type="text"
                    value={groupName}
                    onChange={e => setGroupName(e.target.value)}
                    placeholder="e.g. Lake Oswego & SE"
                    required
                    autoComplete="organization"
                    className={inputClass}
                  />
                </div>
              </>
            )}

            <div>
              <label className="block text-xs font-semibold text-stone-600 mb-1.5 uppercase tracking-wide">
                Email
              </label>
              <input
                type="email"
                value={email}
                onChange={e => setEmail(e.target.value)}
                placeholder="you@example.com"
                required
                autoComplete="email"
                className={inputClass}
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-stone-600 mb-1.5 uppercase tracking-wide">
                Password
              </label>
              <input
                type="password"
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="••••••••"
                required
                minLength={6}
                autoComplete={mode === 'signup' ? 'new-password' : 'current-password'}
                className={inputClass}
              />
              {mode === 'signup' && (
                <p className="text-xs text-stone-400 mt-1">Minimum 6 characters</p>
              )}
            </div>

            {mode === 'signup' && (
              <div>
                <label className="block text-xs font-semibold text-stone-600 mb-1.5 uppercase tracking-wide">
                  Confirm Password
                </label>
                <input
                  type="password"
                  value={confirmPassword}
                  onChange={e => setConfirmPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                  autoComplete="new-password"
                  className={inputClass}
                />
              </div>
            )}

            {error && (
              <div className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-xl px-4 py-3">
                {error}
              </div>
            )}
            {notice && (
              <div className="text-sm text-jade bg-green-50 border border-green-200 rounded-xl px-4 py-3">
                {notice}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 bg-jade hover:bg-jade-700 active:scale-[0.98] text-white font-semibold rounded-xl transition-all disabled:opacity-50 disabled:cursor-not-allowed text-sm"
            >
              {loading
                ? 'Please wait…'
                : mode === 'signin'
                ? 'Sign In'
                : 'Create Account'}
            </button>
          </form>
        </div>

        {mode === 'signup' && (
          <p className="text-center text-xs text-stone-400 mt-4 px-4">
            Everyone in your group creates their own account using the same Community Group Name.
          </p>
        )}
      </div>
    </div>
  )
}
