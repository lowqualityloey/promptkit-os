import LoginButton from '../components/auth/LoginButton'

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-between p-24">
      <div className="z-10 max-w-5xl w-full items-center justify-between font-mono text-sm lg:flex">
        <h1 className="text-4xl font-bold">Awesome SaaS Boilerplate</h1>
        <div className="mt-8 flex gap-4">
          <LoginButton />
        </div>
      </div>
      
      <div className="mt-16 text-center">
        <h2 className="text-3xl font-semibold mb-4">Pricing</h2>
        <div className="border p-8 rounded-lg shadow-md">
          <h3 className="text-2xl font-bold">Pro Plan</h3>
          <p className="text-xl my-4">$29 / month</p>
          <button className="bg-blue-600 text-white px-4 py-2 rounded-md font-semibold">Subscribe Now</button>
        </div>
      </div>
    </main>
  )
}
