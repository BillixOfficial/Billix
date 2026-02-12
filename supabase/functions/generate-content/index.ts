// Supabase Edge Function for AI-powered content generation
// Deploy with: supabase functions deploy generate-content

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface AIContext {
  zipCode?: string
  city?: string
  state?: string
  temperature?: number
  weatherCondition?: string
  billTypes?: string[]
  billType?: string
  upcomingBillName?: string
  upcomingBillDays?: number
  currentMonth?: string
  region?: string
  weatherForecast?: string
}

interface AIContentRequest {
  type: string
  context: AIContext
}

interface LocalDeal {
  title: string
  description: string
  savings_amount: string | null
  deadline: string | null
  icon: string
  category: string
  url: string | null
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')

    if (!OPENAI_API_KEY) {
      throw new Error('OpenAI API key not configured')
    }

    const body = await req.json() as AIContentRequest
    const { type, context } = body

    let response: Record<string, unknown> = { success: true }

    switch (type) {
      case 'local_deals':
        response.deals = await generateLocalDeals(OPENAI_API_KEY, context)
        break

      case 'weather_tip':
        response.content = await generateWeatherTip(OPENAI_API_KEY, context)
        break

      case 'daily_brief':
        response.content = await generateDailyBrief(OPENAI_API_KEY, context)
        break

      case 'national_averages':
        response.data = { averages: await getNationalAverages(OPENAI_API_KEY, context) }
        break

      case 'upcoming_estimates':
        response.estimates = await generateUpcomingEstimates(OPENAI_API_KEY, context)
        break

      default:
        throw new Error(`Unknown content type: ${type}`)
    }

    return new Response(
      JSON.stringify(response),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      }
    )
  }
})

// Generate local deals and savings programs based on location
async function generateLocalDeals(apiKey: string, context: AIContext): Promise<LocalDeal[]> {
  const { zipCode, city, state } = context

  const prompt = `Generate 4-6 local utility deals and savings programs for ${city}, ${state} (ZIP: ${zipCode}).

Include a mix of:
1. Utility company rebate programs (appliances, smart thermostats, weatherization)
2. Community solar programs if available in the state
3. Low-income assistance programs (LIHEAP, utility hardship funds)
4. Budget billing options from local utilities
5. EV charging or heat pump incentives (state/federal)
6. Time-of-use rate programs

For each deal, provide realistic and helpful information. Use actual program names when possible.

Return a JSON array with objects containing:
- title: Program name (string)
- description: Brief description, 1-2 sentences (string)
- savings_amount: Estimated savings like "Up to $500" or "Save 10-15%" or null if variable (string or null)
- deadline: When it expires like "Ends Dec 31" or "Always available" or "Limited spots" (string or null)
- icon: SF Symbol name (use: tag.fill, bolt.fill, flame.fill, drop.fill, leaf.fill, sun.max.fill, building.2.fill, dollarsign.circle.fill) (string)
- category: One of: rebate, solar, assistance, billing, ev, efficiency (string)
- url: null (we'll add real URLs later) (null)

Return ONLY the JSON array, no markdown or explanation.`

  const response = await callOpenAI(apiKey, prompt, 0.7)

  try {
    const deals = JSON.parse(response) as LocalDeal[]
    return deals.slice(0, 6) // Max 6 deals
  } catch {
    console.error('Failed to parse deals response:', response)
    throw new Error('Failed to generate deals')
  }
}

// Generate weather-based bill-saving tip
async function generateWeatherTip(apiKey: string, context: AIContext): Promise<string> {
  const { temperature, weatherCondition, city, billTypes } = context

  const prompt = `Generate a short, actionable bill-saving tip based on current weather.

Location: ${city || 'your area'}
Temperature: ${temperature}°F
Conditions: ${weatherCondition}
User's bills: ${billTypes?.join(', ') || 'utilities'}

Provide ONE concise tip (1-2 sentences) that's specific to these conditions.
Be practical and friendly. Don't use emojis.`

  return await callOpenAI(apiKey, prompt, 0.8)
}

// Generate personalized daily financial brief
async function generateDailyBrief(apiKey: string, context: AIContext): Promise<string> {
  const { city, state, temperature, weatherCondition, billTypes, upcomingBillName, upcomingBillDays } = context

  let briefContext = `Location: ${city}, ${state}`
  if (temperature) briefContext += `\nWeather: ${temperature}°F, ${weatherCondition}`
  if (billTypes?.length) briefContext += `\nBill types: ${billTypes.join(', ')}`
  if (upcomingBillName && upcomingBillDays) {
    briefContext += `\nUpcoming: ${upcomingBillName} due in ${upcomingBillDays} days`
  }

  const prompt = `Generate a personalized daily financial brief (2-3 sentences).

${briefContext}

Be conversational, helpful, and specific. Mention upcoming bills if relevant.
No emojis. Focus on actionable insights.`

  return await callOpenAI(apiKey, prompt, 0.7)
}

// Get national average bill costs
async function getNationalAverages(apiKey: string, context: AIContext): Promise<unknown[]> {
  const { zipCode } = context

  const prompt = `Provide realistic national average monthly bill costs for a typical household.

ZIP code context: ${zipCode}

Return a JSON array with objects containing:
- bill_type: Category name (Electric, Gas, Water, Internet, Phone)
- average: National average monthly cost in dollars (number)
- low: Low end of typical range (number)
- high: High end of typical range (number)

Use realistic 2024 data. Return ONLY the JSON array.`

  const response = await callOpenAI(apiKey, prompt, 0.3)

  try {
    return JSON.parse(response)
  } catch {
    // Fallback averages
    return [
      { bill_type: "Electric", average: 142, low: 90, high: 200 },
      { bill_type: "Gas", average: 78, low: 40, high: 150 },
      { bill_type: "Water", average: 65, low: 35, high: 100 },
      { bill_type: "Internet", average: 65, low: 45, high: 100 },
      { bill_type: "Phone", average: 85, low: 50, high: 120 }
    ]
  }
}

// Generate location-based utility predictions
async function generateUpcomingEstimates(apiKey: string, context: AIContext): Promise<unknown[]> {
  const { city, state, region, currentMonth, temperature, weatherForecast, billTypes } = context

  const prompt = `Generate 3-4 utility predictions for the next 30 days.

Location: ${city}, ${state} (${region})
Current month: ${currentMonth}
Current temperature: ${temperature}°F
Weather forecast: ${weatherForecast || 'typical seasonal patterns'}
User's bill categories: ${billTypes?.join(', ') || 'utilities'}

Focus on:
- Seasonal patterns for this region
- Weather impact on energy usage
- General trends (no specific dollar amounts)

Return a JSON array with objects containing:
- icon: SF Symbol name (thermometer.snowflake, sun.max.fill, leaf.fill, wifi, drop.fill, flame.fill, bolt.fill)
- title: Brief prediction headline (string)
- subtitle: One sentence explanation (string)

Return ONLY the JSON array.`

  const response = await callOpenAI(apiKey, prompt, 0.7)

  try {
    return JSON.parse(response)
  } catch {
    // Fallback estimates
    return [
      { icon: "leaf.fill", title: "Seasonal energy patterns", subtitle: "Usage typically stabilizes this time of year" },
      { icon: "wifi", title: "Fixed costs remain stable", subtitle: "Internet and phone unaffected by weather" },
      { icon: "drop.fill", title: "Water usage consistent", subtitle: "Minimal seasonal variation expected" }
    ]
  }
}

// Call OpenAI API
async function callOpenAI(apiKey: string, prompt: string, temperature: number = 0.7): Promise<string> {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: 'You are a helpful assistant that provides practical financial advice about utility bills and savings programs. Be concise and accurate.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      temperature,
      max_tokens: 1000,
    }),
  })

  if (!response.ok) {
    const error = await response.json()
    console.error('OpenAI error:', error)
    throw new Error('Failed to generate content')
  }

  const result = await response.json()
  return result.choices[0].message.content.trim()
}
