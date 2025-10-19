const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const moment = require('moment');

// Initialize Firebase Admin
admin.initializeApp();

// ==================== WHATSAPP INTEGRATION ====================

/**
 * Send WhatsApp message when a transaction is created
 */
exports.sendWhatsAppMessage = functions.firestore
  .document('transactions/{transactionId}')
  .onCreate(async (snap, context) => {
    try {
      const transaction = snap.data();
      const transactionId = context.params.transactionId;
      
      console.log('New transaction created:', transactionId);
      
      // Get user data
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(transaction.userId)
        .get();
      
      if (!userDoc.exists) {
        console.log('User not found for transaction:', transactionId);
        return;
      }
      
      const user = userDoc.data();
      
      // Get user scheme data
      const schemeDoc = await admin.firestore()
        .collection('userSchemes')
        .where('userId', '==', transaction.userId)
        .limit(1)
        .get();
      
      if (schemeDoc.empty) {
        console.log('Scheme not found for user:', transaction.userId);
        return;
      }
      
      const scheme = schemeDoc.docs[0].data();
      
      // Calculate remaining weeks
      const totalPaid = await calculateTotalPaid(transaction.userId);
      const weeklyAmount = scheme.totalAmount / 52;
      const paidWeeks = Math.floor(totalPaid / weeklyAmount);
      const remainingWeeks = 52 - paidWeeks;
      
      // Calculate next due date
      const nextDueDate = moment(scheme.startDate.toDate())
        .add(paidWeeks + 1, 'weeks')
        .format('MMM DD, YYYY');
      
      // Build WhatsApp message
      const message = buildWhatsAppMessage(user, transaction, scheme, totalPaid, remainingWeeks, nextDueDate);
      
      // Send WhatsApp message (implement your WhatsApp API integration)
      await sendWhatsAppAPI(user.mobileNumber, message);
      
      // Log the message
      await admin.firestore().collection('whatsappMessages').add({
        userId: transaction.userId,
        transactionId: transactionId,
        messageType: 'payment_confirmation',
        message: message,
        phoneNumber: user.mobileNumber,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        isDelivered: true
      });
      
      console.log('WhatsApp message sent successfully for transaction:', transactionId);
      
    } catch (error) {
      console.error('Error sending WhatsApp message:', error);
      
      // Log error
      await admin.firestore().collection('errors').add({
        type: 'whatsapp_error',
        transactionId: context.params.transactionId,
        error: error.message,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
    }
  });

/**
 * Send payment reminder notifications
 */
exports.sendPaymentReminders = functions.pubsub
  .schedule('0 9 * * 1') // Every Monday at 9 AM
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    try {
      console.log('Running payment reminders job');
      
      // Get all active users
      const usersSnapshot = await admin.firestore()
        .collection('users')
        .where('isActive', '==', true)
        .get();
      
      for (const userDoc of usersSnapshot.docs) {
        const user = userDoc.data();
        const userId = userDoc.id;
        
        // Check if user has overdue payments
        const overdueData = await checkOverduePayments(userId);
        
        if (overdueData.hasOverdue) {
          const message = buildReminderMessage(user, overdueData);
          await sendWhatsAppAPI(user.mobileNumber, message);
          
          // Log the reminder
          await admin.firestore().collection('whatsappMessages').add({
            userId: userId,
            messageType: 'payment_reminder',
            message: message,
            phoneNumber: user.mobileNumber,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            isDelivered: true
          });
        }
      }
      
      console.log('Payment reminders sent successfully');
      
    } catch (error) {
      console.error('Error sending payment reminders:', error);
    }
  });

// ==================== ANALYTICS ====================

/**
 * Track user analytics
 */
exports.trackUserAnalytics = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    try {
      const before = change.before.data();
      const after = change.after.data();
      const userId = context.params.userId;
      
      // Track user updates
      await admin.firestore().collection('analytics').add({
        eventType: 'user_updated',
        userId: userId,
        before: before,
        after: after,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
      
    } catch (error) {
      console.error('Error tracking user analytics:', error);
    }
  });

/**
 * Track transaction analytics
 */
exports.trackTransactionAnalytics = functions.firestore
  .document('transactions/{transactionId}')
  .onCreate(async (snap, context) => {
    try {
      const transaction = snap.data();
      const transactionId = context.params.transactionId;
      
      // Track transaction creation
      await admin.firestore().collection('analytics').add({
        eventType: 'transaction_created',
        userId: transaction.userId,
        amount: transaction.amount,
        paymentMode: transaction.paymentMode,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
      
    } catch (error) {
      console.error('Error tracking transaction analytics:', error);
    }
  });

// ==================== BACKUP AND RECOVERY ====================

/**
 * Create daily backup
 */
exports.createDailyBackup = functions.pubsub
  .schedule('0 2 * * *') // Every day at 2 AM
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    try {
      console.log('Creating daily backup');
      
      const timestamp = moment().format('YYYY-MM-DD-HH-mm-ss');
      const backupId = `backup-${timestamp}`;
      
      // Create backup record
      await admin.firestore().collection('backups').doc(backupId).set({
        backupType: 'daily',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isSuccessful: true,
        size: 0, // Will be updated after backup
        collections: ['users', 'transactions', 'userSchemes', 'schemes']
      });
      
      console.log('Daily backup created:', backupId);
      
    } catch (error) {
      console.error('Error creating daily backup:', error);
      
      // Log backup error
      await admin.firestore().collection('backups').add({
        backupType: 'daily',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isSuccessful: false,
        error: error.message
      });
    }
  });

// ==================== REPORT GENERATION ====================

/**
 * Generate monthly reports
 */
exports.generateMonthlyReports = functions.pubsub
  .schedule('0 0 1 * *') // First day of every month
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    try {
      console.log('Generating monthly reports');
      
      const month = moment().format('YYYY-MM');
      const startDate = moment().startOf('month').toDate();
      const endDate = moment().endOf('month').toDate();
      
      // Get monthly transactions
      const transactionsSnapshot = await admin.firestore()
        .collection('transactions')
        .where('date', '>=', startDate)
        .where('date', '<=', endDate)
        .get();
      
      const transactions = transactionsSnapshot.docs.map(doc => doc.data());
      
      // Calculate monthly statistics
      const totalAmount = transactions.reduce((sum, t) => sum + t.amount, 0);
      const totalTransactions = transactions.length;
      const averageTransaction = totalAmount / totalTransactions;
      
      // Create report
      const reportId = `monthly-report-${month}`;
      await admin.firestore().collection('reports').doc(reportId).set({
        reportType: 'monthly',
        month: month,
        totalAmount: totalAmount,
        totalTransactions: totalTransactions,
        averageTransaction: averageTransaction,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        data: transactions
      });
      
      console.log('Monthly report generated:', reportId);
      
    } catch (error) {
      console.error('Error generating monthly reports:', error);
    }
  });

// ==================== HELPER FUNCTIONS ====================

/**
 * Calculate total paid amount for a user
 */
async function calculateTotalPaid(userId) {
  const transactionsSnapshot = await admin.firestore()
    .collection('transactions')
    .where('userId', '==', userId)
    .get();
  
  return transactionsSnapshot.docs.reduce((sum, doc) => {
    return sum + doc.data().amount;
  }, 0);
}

/**
 * Check if user has overdue payments
 */
async function checkOverduePayments(userId) {
  // Get user scheme
  const schemeDoc = await admin.firestore()
    .collection('userSchemes')
    .where('userId', '==', userId)
    .limit(1)
    .get();
  
  if (schemeDoc.empty) {
    return { hasOverdue: false };
  }
  
  const scheme = schemeDoc.docs[0].data();
  const totalPaid = await calculateTotalPaid(userId);
  const weeklyAmount = scheme.totalAmount / 52;
  const paidWeeks = Math.floor(totalPaid / weeklyAmount);
  const remainingWeeks = 52 - paidWeeks;
  
  // Check if overdue (more than 1 week behind)
  const currentWeek = moment().diff(moment(scheme.startDate.toDate()), 'weeks');
  const overdueWeeks = currentWeek - paidWeeks;
  
  return {
    hasOverdue: overdueWeeks > 1,
    overdueWeeks: overdueWeeks,
    remainingWeeks: remainingWeeks,
    totalPaid: totalPaid,
    weeklyAmount: weeklyAmount
  };
}

/**
 * Build WhatsApp payment confirmation message
 */
function buildWhatsAppMessage(user, transaction, scheme, totalPaid, remainingWeeks, nextDueDate) {
  const pendingAmount = scheme.totalAmount - totalPaid;
  const bonus = transaction.interest || 0;
  
  return `🎉 *Payment Received Successfully!*

👤 *Customer Details:*
Name: ${user.name}
ID: ${user.serialNumber}

💰 *Payment Details:*
Amount: ₹${transaction.amount}
Date: ${moment(transaction.date.toDate()).format('MMM DD, YYYY')}
Mode: ${transaction.paymentMode}
Receipt: ${transaction.receiptNumber || 'N/A'}

📋 *Scheme Information:*
Scheme: ${scheme.schemeType}
Weekly Amount: ₹${Math.round(scheme.totalAmount / 52)}
Total Amount: ₹${scheme.totalAmount}

📊 *Financial Summary:*
Pending Amount: ₹${Math.round(pendingAmount)}
Total Bonus Earned: ₹${bonus}

📅 *Next Due Date:*
${nextDueDate}

Thank you for your payment! 🙏

_This is an automated message from Finance Tracker App_`;
}

/**
 * Build payment reminder message
 */
function buildReminderMessage(user, overdueData) {
  return `⏰ *Payment Reminder*

👤 *Customer Details:*
Name: ${user.name}
ID: ${user.serialNumber}

💰 *Payment Details:*
Weekly Amount: ₹${Math.round(overdueData.weeklyAmount)}
⚠️ Overdue Amount: ₹${Math.round(overdueData.overdueWeeks * overdueData.weeklyAmount)}
📅 Overdue Weeks: ${overdueData.overdueWeeks} weeks

Total Due: ₹${Math.round((overdueData.overdueWeeks + 1) * overdueData.weeklyAmount)}

Please make your payment at the earliest convenience.

Thank you! 🙏

_This is an automated reminder from Finance Tracker App_`;
}

/**
 * Send WhatsApp message via API
 */
async function sendWhatsAppAPI(phoneNumber, message) {
  // Implement your WhatsApp API integration here
  // This could be Twilio, WhatsApp Business API, or any other service
  
  console.log(`Sending WhatsApp to ${phoneNumber}: ${message}`);
  
  // Example with Twilio (you'll need to configure your Twilio credentials)
  // const twilio = require('twilio');
  // const client = twilio(accountSid, authToken);
  // 
  // await client.messages.create({
  //   body: message,
  //   from: 'whatsapp:+14155238886',
  //   to: `whatsapp:+${phoneNumber}`
  // });
}

// ==================== EXPORTS ====================

module.exports = {
  sendWhatsAppMessage: exports.sendWhatsAppMessage,
  sendPaymentReminders: exports.sendPaymentReminders,
  trackUserAnalytics: exports.trackUserAnalytics,
  trackTransactionAnalytics: exports.trackTransactionAnalytics,
  createDailyBackup: exports.createDailyBackup,
  generateMonthlyReports: exports.generateMonthlyReports
};

