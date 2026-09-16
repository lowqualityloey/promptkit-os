import { headers } from 'next/headers'
import { NextResponse } from 'next/server'
import { stripe } from '../../../../lib/stripe'
import prisma from '../../../../lib/prisma'

export async function POST(req: Request) {
  const body = await req.text()
  const signature = headers().get('Stripe-Signature') as string

  let event

  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    )
  } catch (error: any) {
    return new NextResponse(`Webhook Error: ${error.message}`, { status: 400 })
  }

  const session = event.data.object

  if (event.type === 'checkout.session.completed') {
    // Fulfill the purchase...
    console.log(`Payment successful for session: ${session}`)
  }

  return new NextResponse(null, { status: 200 })
}
