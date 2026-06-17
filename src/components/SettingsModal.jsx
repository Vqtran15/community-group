import { GearSix, ListBullets, PencilSimple, SignOut } from '@phosphor-icons/react'
import { useModalClose } from '../hooks/useModalClose.js'
import { supabase } from '../lib/supabase.js'

export default function SettingsModal({ editLabel, groupName, displayName, onEditPage, onManagePages, onClose }) {
  const [closing, close] = useModalClose(onClose)

  return (
    <div
      className={`fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center z-50 p-4 ${closing ? 'animate-overlay-out' : 'animate-overlay-in'}`}
      onClick={close}
    >
      <div
        className={`bg-white rounded-2xl shadow-xl w-full max-w-sm ${closing ? 'animate-modal-out' : 'animate-modal-in'}`}
        onClick={e => e.stopPropagation()}
      >
        <div className="flex items-center justify-between p-5 pb-4">
          <div className="flex items-center gap-2">
            <GearSix size={20} weight="fill" className="text-jade" />
            <h2 className="text-lg font-bold text-stone-800">Settings</h2>
          </div>
          <button
            onClick={close}
            className="text-stone-400 hover:text-stone-600 text-2xl leading-none w-8 h-8 flex items-center justify-center rounded-full hover:bg-stone-100"
          >
            &times;
          </button>
        </div>

        <div className="px-5 pb-6 space-y-2">
          <p className="text-xs font-semibold text-stone-400 uppercase tracking-wide pb-1">
            Pages
          </p>
          {onEditPage && (
            <button
              onClick={onEditPage}
              className="w-full flex items-center justify-between px-4 py-3.5 rounded-xl border-2 border-stone-200 bg-white hover:border-coral hover:bg-coral-light transition-all"
            >
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-full bg-coral-100 flex items-center justify-center">
                  <PencilSimple size={16} weight="bold" className="text-coral-700" />
                </div>
                <div className="text-left">
                  <div className="text-sm font-semibold text-stone-800">{editLabel}</div>
                  <div className="text-xs text-stone-400 mt-0.5">Edit title, date, and ingredients</div>
                </div>
              </div>
            </button>
          )}
          <button
            onClick={onManagePages}
            className="w-full flex items-center justify-between px-4 py-3.5 rounded-xl border-2 border-stone-200 bg-white hover:border-jade hover:bg-lagoon-50 transition-all"
          >
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-full bg-lagoon-50 flex items-center justify-center">
                <ListBullets size={16} weight="bold" className="text-lagoon-700" />
              </div>
              <div className="text-left">
                <div className="text-sm font-semibold text-stone-800">Manage pages</div>
                <div className="text-xs text-stone-400 mt-0.5">Add, view, and reorder pages</div>
              </div>
            </div>
          </button>

          <div className="pt-2 border-t border-stone-100">
            <p className="text-xs font-semibold text-stone-400 uppercase tracking-wide pb-2">
              Account
            </p>
            <div className="flex items-center justify-between px-1">
              <div className="min-w-0 mr-3">
                {displayName && <p className="text-sm font-medium text-stone-700 truncate">{displayName}</p>}
                {groupName && <p className="text-xs text-stone-400 truncate">{groupName}</p>}
              </div>
              <button
                onClick={() => supabase.auth.signOut()}
                className="flex items-center gap-1.5 text-sm text-stone-400 hover:text-red-500 transition-colors shrink-0"
              >
                <SignOut size={15} weight="bold" />
                Sign out
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
