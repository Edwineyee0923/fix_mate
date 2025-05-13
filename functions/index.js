const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.autoCompleteBookings = functions.pubsub.schedule('every 5 minutes').onRun(async (context) => {
  try {
    console.log("🚀 Auto-complete function triggered");

    const now = admin.firestore.Timestamp.now();
    const bookingsRef = admin.firestore().collection('bookings');

    const snapshot = await bookingsRef
      .where('pCompleted', '==', true)
      .where('sCompleted', '==', false)
      .where('status', '!=', 'Completed')
      .where('autoCompleteAt', '<=', now)
      .get();

    const batch = admin.firestore().batch();

    for (const doc of snapshot.docs) {
      const data = doc.data();

      // ✅ Step 1: Update the booking
      batch.update(doc.ref, {
        status: 'Completed',
        sCompleted: true,
        completedAt: now,
        autoCompletedBySystem: true,
      });

      // ✅ Step 2: Add notification
      await admin.firestore().collection('s_notifications').add({
        seekerId: data.serviceSeekerId,
        providerId: data.serviceProviderId,
        bookingId: data.bookingId,
        postId: data.postId || null,
        title: 'Service Auto-Completed\n(#' + data.bookingId + ')',
        message: 'The system auto-completed this service after 7 days without user confirmation.',
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    console.log(`✅ Auto-completed ${snapshot.size} bookings`);
  } catch (error) {
    console.error('❌ Auto-complete failed:', error);
  }
});
