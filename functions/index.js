const functions = require('firebase-functions');
const { Resend } = require('resend');

// Initialize Resend with your API key
const resend = new Resend('re_QQUf69Ve_89uwd9qCqYVTGqR4jnpACQsj'); // Replace with your real API key

exports.sendPaymentReminder = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
  }

  const { playerName, playerEmail, unpaidMonths, clubName } = data;

  // Validate input
  if (!playerName || !playerEmail || !unpaidMonths) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }

  console.log(`Sending payment reminder to ${playerEmail} for ${playerName}`);

  try {
    const { data: emailData, error } = await resend.emails.send({
      from: 'Football Club <onboarding@resend.dev>', // Use Resend's test domain for now
      to: [playerEmail],
      subject: `Payment Reminder for ${playerName}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #F27121;">Payment Reminder</h2>
          <p>Dear Parent/Guardian,</p>
          <p>This is a reminder that the following months are unpaid for <strong>${playerName}</strong>:</p>
          <ul style="background-color: #f9f9f9; padding: 15px; border-radius: 5px;">
            ${unpaidMonths.map(month => `<li style="margin: 5px 0;">${month}</li>`).join('')}
          </ul>
          <p>Please make the payment at your earliest convenience.</p>
          <p>If you have any questions, please don't hesitate to contact us.</p>
          <br>
          <p>Thank you,<br><strong>${clubName || 'Football Club Management'}</strong></p>
          <hr style="margin-top: 30px; border: none; border-top: 1px solid #eee;">
          <p style="font-size: 12px; color: #666;">This is an automated reminder from your football club management system.</p>
        </div>
      `,
    });

    if (error) {
      console.error('Resend error:', error);
      throw new Error(error.message);
    }

    console.log('Email sent successfully:', emailData.id);
    return { success: true, messageId: emailData.id };
  } catch (error) {
    console.error('Email sending error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send email: ' + error.message);
  }
});