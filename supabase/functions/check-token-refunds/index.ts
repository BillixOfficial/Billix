// Supabase Edge Function for automatic token refunds
// This function checks for swaps with < 5 messages after 24 hours and refunds the token
// Deploy with: supabase functions deploy check-token-refunds
// Schedule with: pg_cron or call from external scheduler

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get Supabase client with service role (for scheduled jobs)
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Find swaps that:
    // 1. Have chat_unlocked = true
    // 2. Were unlocked more than 24 hours ago
    // 3. Haven't been refunded yet (token_refunded = false)
    const cutoffTime = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()

    const { data: eligibleSwaps, error: swapsError } = await supabase
      .from('swaps')
      .select('id, user_a_id, user_b_id, conversation_id, chat_unlocked_at')
      .eq('chat_unlocked', true)
      .eq('token_refunded', false)
      .lt('chat_unlocked_at', cutoffTime)

    if (swapsError) {
      throw new Error(`Failed to fetch swaps: ${swapsError.message}`)
    }

    if (!eligibleSwaps || eligibleSwaps.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'No swaps eligible for refund',
          processed: 0
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    let refundedCount = 0
    const errors: string[] = []

    for (const swap of eligibleSwaps) {
      try {
        // Count messages in the conversation
        let messageCount = 0

        if (swap.conversation_id) {
          const { count, error: countError } = await supabase
            .from('messages')
            .select('*', { count: 'exact', head: true })
            .eq('conversation_id', swap.conversation_id)

          if (countError) {
            console.error(`Failed to count messages for swap ${swap.id}:`, countError)
            continue
          }

          messageCount = count || 0
        }

        // If less than 5 messages, refund the token
        if (messageCount < 5) {
          // Refund token to user_a (the one who initiated the unlock)
          // In the new model, only one user needs to use a token to unlock
          const userId = swap.user_a_id

          // Get current token balance
          const { data: tokenRecord, error: tokenError } = await supabase
            .from('connect_tokens')
            .select('balance')
            .eq('user_id', userId)
            .single()

          if (tokenError) {
            console.error(`Failed to get token record for user ${userId}:`, tokenError)
            errors.push(`Swap ${swap.id}: Failed to get token record`)
            continue
          }

          // Add token back
          const newBalance = (tokenRecord?.balance || 0) + 1

          const { error: updateTokenError } = await supabase
            .from('connect_tokens')
            .update({
              balance: newBalance,
              updated_at: new Date().toISOString()
            })
            .eq('user_id', userId)

          if (updateTokenError) {
            console.error(`Failed to update token balance for user ${userId}:`, updateTokenError)
            errors.push(`Swap ${swap.id}: Failed to update token balance`)
            continue
          }

          // Log the refund transaction
          const { error: transactionError } = await supabase
            .from('token_transactions')
            .insert({
              user_id: userId,
              amount: 1,
              type: 'refund',
              reference_id: swap.id
            })

          if (transactionError) {
            console.error(`Failed to log transaction for swap ${swap.id}:`, transactionError)
            // Continue anyway - token was refunded
          }

          // Mark swap as refunded
          const { error: swapUpdateError } = await supabase
            .from('swaps')
            .update({ token_refunded: true })
            .eq('id', swap.id)

          if (swapUpdateError) {
            console.error(`Failed to mark swap ${swap.id} as refunded:`, swapUpdateError)
            errors.push(`Swap ${swap.id}: Failed to mark as refunded`)
            continue
          }

          refundedCount++
          console.log(`Refunded token for swap ${swap.id} (${messageCount} messages)`)
        } else {
          // More than 5 messages - mark as not eligible for refund
          await supabase
            .from('swaps')
            .update({ token_refunded: true })  // Mark as processed (no refund needed)
            .eq('id', swap.id)
        }

      } catch (error) {
        console.error(`Error processing swap ${swap.id}:`, error)
        errors.push(`Swap ${swap.id}: ${error.message}`)
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Processed ${eligibleSwaps.length} swaps, refunded ${refundedCount}`,
        processed: eligibleSwaps.length,
        refunded: refundedCount,
        errors: errors.length > 0 ? errors : undefined
      }),
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
        status: 500
      }
    )
  }
})
