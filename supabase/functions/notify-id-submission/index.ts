// Supabase Edge Function for notifying founder about new ID verification submissions
// Triggered by database webhook on id_verification_submissions INSERT
// Deploy with: supabase functions deploy notify-id-submission

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface VerificationSubmission {
  id: string
  user_id: string
  selfie_url: string
  id_front_url: string
  id_back_url?: string
  status: string
  submitted_at: string
  created_at: string
}

interface WebhookPayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE'
  table: string
  record: VerificationSubmission
  schema: string
  old_record: VerificationSubmission | null
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!RESEND_API_KEY) {
      console.log('Resend API key not configured - skipping email')
      return new Response(
        JSON.stringify({ success: true, message: 'Email skipped - no API key' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const payload = await req.json() as WebhookPayload

    // Only process INSERT events
    if (payload.type !== 'INSERT') {
      return new Response(
        JSON.stringify({ success: true, message: 'Not an INSERT event, skipping' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const submission = payload.record

    // Fetch user info if possible
    let userEmail = 'Unknown'
    let userName = 'Unknown'

    if (SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY) {
      const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

      // Get user email from auth.users
      const { data: userData } = await supabase.auth.admin.getUserById(submission.user_id)
      if (userData?.user) {
        userEmail = userData.user.email || 'No email'
      }

      // Get user name from profiles
      const { data: profileData } = await supabase
        .from('profiles')
        .select('display_name, first_name, last_name')
        .eq('user_id', submission.user_id)
        .single()

      if (profileData) {
        userName = profileData.display_name ||
          `${profileData.first_name || ''} ${profileData.last_name || ''}`.trim() ||
          'No name'
      }
    }

    // Get Supabase project ref from URL
    const projectRef = SUPABASE_URL?.match(/https:\/\/([^.]+)\.supabase\.co/)?.[1] || 'your-project'

    // Build email content
    const emailHtml = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>New ID Verification Submission</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; line-height: 1.6; color: #2D3B35; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="background: linear-gradient(135deg, #5B8A6B 0%, #2d5a5e 100%); padding: 30px; border-radius: 16px 16px 0 0; text-align: center;">
    <h1 style="color: white; margin: 0; font-size: 24px;">New ID Verification</h1>
    <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0 0; font-size: 14px;">Action Required</p>
  </div>

  <div style="background: #ffffff; padding: 30px; border: 1px solid #E5E9E7; border-top: none; border-radius: 0 0 16px 16px;">
    <h2 style="margin-top: 0; color: #5B8A6B;">User Details</h2>

    <div style="background: #F7F9F8; border-radius: 12px; padding: 20px; margin: 20px 0;">
      <p style="margin: 0 0 8px 0;"><strong>Name:</strong> ${userName}</p>
      <p style="margin: 0 0 8px 0;"><strong>Email:</strong> ${userEmail}</p>
      <p style="margin: 0 0 8px 0;"><strong>User ID:</strong> <code style="background: #E5E9E7; padding: 2px 6px; border-radius: 4px; font-size: 12px;">${submission.user_id}</code></p>
      <p style="margin: 0;"><strong>Submitted:</strong> ${new Date(submission.submitted_at || submission.created_at).toLocaleString()}</p>
    </div>

    <h2 style="color: #5B8A6B;">Uploaded Documents</h2>
    <div style="background: #F7F9F8; border-radius: 12px; padding: 20px; margin: 20px 0;">
      <p style="margin: 0 0 8px 0;"><strong>Selfie:</strong> ${submission.selfie_url}</p>
      <p style="margin: 0 0 8px 0;"><strong>ID Front:</strong> ${submission.id_front_url}</p>
      ${submission.id_back_url ? `<p style="margin: 0;"><strong>ID Back:</strong> ${submission.id_back_url}</p>` : '<p style="margin: 0; color: #8B9A94;"><em>No ID back uploaded</em></p>'}
    </div>

    <div style="margin-top: 30px; text-align: center;">
      <a href="https://supabase.com/dashboard/project/${projectRef}/storage/buckets/id-verification" style="display: inline-block; background: #5B8A6B; color: white; padding: 14px 28px; text-decoration: none; border-radius: 8px; font-weight: 600; margin-bottom: 12px;">View Images in Storage</a>
      <br>
      <a href="https://supabase.com/dashboard/project/${projectRef}/editor" style="display: inline-block; background: #2d5a5e; color: white; padding: 14px 28px; text-decoration: none; border-radius: 8px; font-weight: 600;">Open Table Editor</a>
    </div>

    <div style="background: #FFF3CD; border-radius: 12px; padding: 16px; margin-top: 24px; text-align: center;">
      <p style="margin: 0; color: #856404;"><strong>To Approve:</strong> Change status to 'approved' in id_verification_submissions table</p>
      <p style="margin: 8px 0 0 0; color: #856404; font-size: 14px;">The profile will be auto-updated via database trigger</p>
    </div>
  </div>

  <div style="text-align: center; padding: 20px; color: #8B9A94; font-size: 12px;">
    <p style="margin: 0;">Billix ID Verification System</p>
    <p style="margin: 8px 0 0 0;">&copy; ${new Date().getFullYear()} Billix</p>
  </div>
</body>
</html>
`

    // Send email via Resend
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'Billix <noreply@billixapp.com>',
        to: ['info@billixapp.com'],
        subject: `[ID Verification] New submission from ${userName}`,
        html: emailHtml,
      }),
    })

    if (!response.ok) {
      const error = await response.json()
      console.error('Resend error:', error)
      throw new Error(`Failed to send email: ${JSON.stringify(error)}`)
    }

    const result = await response.json()
    console.log('Email sent successfully:', result)

    return new Response(
      JSON.stringify({ success: true, emailId: result.id }),
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
