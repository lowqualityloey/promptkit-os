import NextAuth from "next-auth"
// Example using GitHub, replace with actual providers you need
import GitHub from "next-auth/providers/github"

export const { handlers: { GET, POST }, auth } = NextAuth({
  providers: [
    GitHub({
      clientId: process.env.GITHUB_ID,
      clientSecret: process.env.GITHUB_SECRET,
    }),
  ],
})
