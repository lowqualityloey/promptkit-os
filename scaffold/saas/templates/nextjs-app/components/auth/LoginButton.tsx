'use client'

import { signIn, signOut } from "next-auth/react"

export default function LoginButton() {
  return (
    <div className="flex gap-4">
      <button 
        onClick={() => signIn()}
        className="px-4 py-2 bg-black text-white rounded-md font-semibold"
      >
        Sign In
      </button>
      <button 
        onClick={() => signOut()}
        className="px-4 py-2 border border-black rounded-md font-semibold"
      >
        Sign Out
      </button>
    </div>
  )
}
