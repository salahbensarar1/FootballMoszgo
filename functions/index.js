const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * MIGRATION: Add is_active field to all users
 */
exports.addIsActiveToAllUsers = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  try {
    console.log('🚀 Starting is_active migration...');
    let totalUpdated = 0;

    const orgsSnapshot = await admin.firestore().collection('organizations').get();
    console.log(`Found ${orgsSnapshot.size} organizations`);

    for (const orgDoc of orgsSnapshot.docs) {
      const orgId = orgDoc.id;
      console.log(`Processing org: ${orgId}`);

      const usersSnapshot = await admin.firestore()
        .collection('organizations')
        .doc(orgId)
        .collection('users')
        .get();

      const userDocs = usersSnapshot.docs;
      
      for (let i = 0; i < userDocs.length; i += 500) {
        const batch = admin.firestore().batch();
        const batchDocs = userDocs.slice(i, i + 500);
        let batchUpdates = 0;

        for (const userDoc of batchDocs) {
          const userData = userDoc.data();

          if (!userData.hasOwnProperty('is_active')) {
            batch.update(userDoc.ref, {
              is_active: true,
              updated_at: admin.firestore.FieldValue.serverTimestamp()
            });
            batchUpdates++;
            totalUpdated++;
          }
        }

        if (batchUpdates > 0) {
          await batch.commit();
          console.log(`Committed ${batchUpdates} updates`);
        }
      }
    }

    console.log(`Migration completed! Updated ${totalUpdated} users`);
    return { success: true, totalUpdated };

  } catch (error) {
    console.error('Migration failed:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// HTTP version
exports.addIsActiveHttp = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  
  try {
    let totalUpdated = 0;
    
    const orgsSnapshot = await admin.firestore().collection('organizations').get();
    
    for (const orgDoc of orgsSnapshot.docs) {
      const usersSnapshot = await admin.firestore()
        .collection('organizations')
        .doc(orgDoc.id)
        .collection('users')
        .get();

      const userDocs = usersSnapshot.docs;
      
      for (let i = 0; i < userDocs.length; i += 500) {
        const batch = admin.firestore().batch();
        let batchUpdates = 0;

        for (const userDoc of userDocs.slice(i, i + 500)) {
          const userData = userDoc.data();
          if (!userData.hasOwnProperty('is_active')) {
            batch.update(userDoc.ref, {
              is_active: true,
              updated_at: admin.firestore.FieldValue.serverTimestamp()
            });
            batchUpdates++;
            totalUpdated++;
          }
        }

        if (batchUpdates > 0) {
          await batch.commit();
        }
      }
    }

    res.json({ success: true, totalUpdated });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});