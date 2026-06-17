import { useState, useEffect, useRef } from 'react'
import { Routes, Route, Navigate, useNavigate, useLocation } from 'react-router-dom'
import { ForkKnife, HandHeart, Confetti } from '@phosphor-icons/react'
import { formatDate } from './utils/dates.js'
import { getUpcomingBirthdays } from './utils/birthdays.js'
import { supabase } from './lib/supabase.js'
import RotationTab from './RotationTab.jsx'
import BirthdayTab from './components/BirthdayTab.jsx'
import BirthdayBanner from './components/BirthdayBanner.jsx'

const TABS = [
  {
    path: '/meals',
    shortLabel: 'Meals',
    Icon: ForkKnife,
    config: {
      label: 'Meal Sign-up',
      Icon: ForkKnife,
      editLabel: 'Edit Meal',
      noun: 'Ingredient',
      itemNoun: 'Ingredient',
      tables: { pages: 'meal_pages', signups: 'signups' },
      autoFill: true,
      defaultTitle: dateStr => `Meal — ${formatDate(dateStr)}`,
    },
  },
  {
    path: '/services',
    shortLabel: 'Service',
    Icon: HandHeart,
    config: {
      label: 'Service Night',
      Icon: HandHeart,
      editLabel: 'Edit Items',
      noun: 'Item',
      itemNoun: 'Item',
      tables: { pages: 'serving_pages', signups: 'serving_signups' },
      defaultTitle: dateStr => `Service Night — ${formatDate(dateStr)}`,
    },
  },
  {
    path: '/birthdays',
    shortLabel: 'Birthdays',
    Icon: Confetti,
  },
]

const PATHS = TABS.map(t => t.path)

export default function App() {
  const navigate = useNavigate()
  const location = useLocation()
  const prevIndexRef = useRef(PATHS.indexOf(location.pathname))
  const [enterFrom, setEnterFrom] = useState('right')
  const [birthdays, setBirthdays] = useState([])

  useEffect(() => {
    supabase.from('birthdays').select('*').then(({ data }) => setBirthdays(data ?? []))

    const channel = supabase
      .channel('birthdays-global')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'birthdays' },
        ({ eventType, new: next, old: prev }) => {
          if (eventType === 'INSERT') {
            setBirthdays(b => b.some(r => r.id === next.id) ? b : [...b, next])
          } else if (eventType === 'UPDATE') {
            setBirthdays(b => b.map(r => r.id === next.id ? next : r))
          } else if (eventType === 'DELETE') {
            setBirthdays(b => b.filter(r => r.id !== prev.id))
          }
        },
      )
      .subscribe()

    return () => supabase.removeChannel(channel)
  }, [])

  const upcoming = getUpcomingBirthdays(birthdays)

  function handleTabChange(path) {
    const newIndex = PATHS.indexOf(path)
    setEnterFrom(newIndex > prevIndexRef.current ? 'right' : 'left')
    prevIndexRef.current = newIndex
    navigate(path)
  }

  return (
    <div className="min-h-screen bg-sunrise-50 overflow-x-hidden" style={{ paddingTop: 'env(safe-area-inset-top)' }}>
      <BirthdayBanner upcoming={upcoming} />

      <div
        key={location.pathname}
        className={`pb-24 ${enterFrom === 'right' ? 'animate-slide-in-right' : 'animate-slide-in-left'}`}
      >
        <Routes>
          <Route path="/" element={<Navigate to="/meals" replace />} />
          <Route path="/meals" element={<RotationTab config={TABS[0].config} revealKey="/meals" />} />
          <Route path="/services" element={<RotationTab config={TABS[1].config} revealKey="/services" />} />
          <Route path="/birthdays" element={<BirthdayTab birthdays={birthdays} onBirthdaysChange={setBirthdays} revealKey="/birthdays" />} />
        </Routes>
      </div>

      <nav
        className="fixed bottom-0 inset-x-0 bg-white border-t border-stone-200 z-40 flex"
        style={{ paddingBottom: 'env(safe-area-inset-bottom)' }}
      >
        {TABS.map(t => {
          const active = location.pathname === t.path
          return (
            <button
              key={t.path}
              onClick={() => handleTabChange(t.path)}
              className={`flex-1 flex flex-col items-center gap-0.5 py-2 px-1 transition-colors ${active ? '' : 'text-stone-400 hover:text-stone-600'}`}
            >
              <span className={`relative px-3 py-1 rounded-2xl transition-colors ${active ? 'bg-jade text-white' : ''}`}>
                <t.Icon size={26} weight={active ? 'fill' : 'regular'} />
                {t.path === '/birthdays' && upcoming.length > 0 && (
                  <span className="absolute top-0 right-0 w-2.5 h-2.5 bg-lagoon rounded-full border-2 border-white" />
                )}
              </span>
              <span className={`text-[10px] font-medium tracking-wide ${active ? 'text-jade' : ''}`}>{t.shortLabel}</span>
            </button>
          )
        })}
      </nav>
    </div>
  )
}
