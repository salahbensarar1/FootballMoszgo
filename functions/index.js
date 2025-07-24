const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { Resend } = require('resend');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

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

/**
 * AUTOMATIC: Delete Firebase Auth when coach user document is deleted
 * This triggers automatically when CoachManagementService.deleteCoachCompletely() runs
 */
exports.autoDeleteCoachAuth = functions.firestore
  .document('users/{userId}')
  .onDelete(async (snap, context) => {
    const userId = context.params.userId;
    const userData = snap.data();
    
    try {
      // Only auto-delete auth for coaches (safety measure)
      if (userData.role === 'coach') {
        await admin.auth().deleteUser(userId);
        console.log(`✅ Automatically deleted Firebase Auth for coach: ${userData.email}`);
      }
    } catch (error) {
      if (error.code !== 'auth/user-not-found') {
        console.error('❌ Error auto-deleting Firebase Auth:', error);
      }
    }
  });

/**
 * MANUAL: Explicit Cloud Function to delete coach authentication
 * Can be called from Flutter if you need manual control
 */
exports.deleteCoachAuth = functions.https.onCall(async (data, context) => {
  // Verify caller is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  // Verify caller has admin/receptionist privileges
  const callerUid = context.auth.uid;
  const callerDoc = await admin.firestore().collection('users').doc(callerUid).get();
  
  if (!callerDoc.exists) {
    throw new functions.https.HttpsError('permission-denied', 'User document not found');
  }

  const callerRole = callerDoc.data().role;
  if (!['admin', 'receptionist'].includes(callerRole)) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins and receptionists can delete coaches');
  }

  const { coachId } = data;
  if (!coachId) {
    throw new functions.https.HttpsError('invalid-argument', 'coachId is required');
  }

  try {
    // Verify the user is actually a coach
    const coachDoc = await admin.firestore().collection('users').doc(coachId).get();
    
    if (!coachDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Coach not found');
    }

    const coachData = coachDoc.data();
    if (coachData.role !== 'coach') {
      throw new functions.https.HttpsError('invalid-argument', 'User is not a coach');
    }

    // Delete from Firebase Authentication
    await admin.auth().deleteUser(coachId);

    return {
      success: true,
      message: 'Coach authentication deleted successfully',
      coachEmail: coachData.email
    };

  } catch (error) {
    console.error('Error deleting coach auth:', error);
    
    if (error.code === 'auth/user-not-found') {
      return { success: true, message: 'Coach authentication was already deleted' };
    }

    throw new functions.https.HttpsError('internal', `Failed to delete coach auth: ${error.message}`);
  }
});