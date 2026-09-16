import { redirect } from "next/navigation"
import { auth } from "../api/auth/[...nextauth]/route"

export default async function DashboardPage() {
  const session = await auth()

  if (!session) {
    redirect("/")
  }

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold">Dashboard</h1>
      <p>Welcome, {session.user?.name || "User"}!</p>
    </div>
  )
}
