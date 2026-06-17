import { useState, useEffect } from 'react'
import { supabase } from '../lib/supabase.js'
import ConversationList from './ConversationList.jsx'
import ChatView from './ChatView.jsx'

export default function ChatTab({ session, displayName, groupId, onRead }) {
  const [activeConv, setActiveConv] = useState(null)
  const [members, setMembers] = useState([])

  useEffect(() => {
    if (!groupId) return
    supabase
      .from('profiles')
      .select('user_id, display_name')
      .eq('community_group_id', groupId)
      .then(({ data }) => setMembers(data ?? []))
  }, [groupId])

  if (activeConv) {
    return (
      <ChatView
        conversation={activeConv}
        session={session}
        displayName={displayName}
        groupId={groupId}
        members={members}
        onBack={() => setActiveConv(null)}
        onRead={onRead}
      />
    )
  }

  return (
    <ConversationList
      session={session}
      groupId={groupId}
      members={members}
      onSelect={setActiveConv}
      onRead={onRead}
    />
  )
}
