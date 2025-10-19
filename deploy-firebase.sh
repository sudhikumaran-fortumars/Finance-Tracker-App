#!/bin/bash

# Firebase Deployment Script for Finance Tracker App
# This script deploys all Firebase services with proper configuration

echo "🚀 Starting Firebase deployment for Finance Tracker App..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "❌ Please login to Firebase first:"
    echo "firebase login"
    exit 1
fi

echo "✅ Firebase CLI is ready"

# Deploy Firestore rules
echo "📝 Deploying Firestore rules..."
firebase deploy --only firestore:rules
if [ $? -eq 0 ]; then
    echo "✅ Firestore rules deployed successfully"
else
    echo "❌ Failed to deploy Firestore rules"
    exit 1
fi

# Deploy Firestore indexes
echo "📊 Deploying Firestore indexes..."
firebase deploy --only firestore:indexes
if [ $? -eq 0 ]; then
    echo "✅ Firestore indexes deployed successfully"
else
    echo "❌ Failed to deploy Firestore indexes"
    exit 1
fi

# Deploy Storage rules
echo "💾 Deploying Storage rules..."
firebase deploy --only storage
if [ $? -eq 0 ]; then
    echo "✅ Storage rules deployed successfully"
else
    echo "❌ Failed to deploy Storage rules"
    exit 1
fi

# Deploy Functions
echo "⚡ Deploying Functions..."
cd functions
npm install
cd ..
firebase deploy --only functions
if [ $? -eq 0 ]; then
    echo "✅ Functions deployed successfully"
else
    echo "❌ Failed to deploy Functions"
    exit 1
fi

# Deploy Hosting (if configured)
echo "🌐 Deploying Hosting..."
firebase deploy --only hosting
if [ $? -eq 0 ]; then
    echo "✅ Hosting deployed successfully"
else
    echo "⚠️ Hosting deployment skipped (not configured)"
fi

# Deploy Extensions (if any)
echo "🔌 Deploying Extensions..."
firebase deploy --only extensions
if [ $? -eq 0 ]; then
    echo "✅ Extensions deployed successfully"
else
    echo "⚠️ Extensions deployment skipped (none configured)"
fi

echo ""
echo "🎉 Firebase deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "✅ Firestore rules and indexes"
echo "✅ Storage rules"
echo "✅ Functions"
echo "✅ Hosting (if configured)"
echo "✅ Extensions (if configured)"
echo ""
echo "🔗 Next steps:"
echo "1. Test your app with the new Firebase configuration"
echo "2. Monitor Firebase Console for any issues"
echo "3. Set up monitoring and alerts"
echo "4. Configure backup strategies"
echo ""
echo "📚 Documentation:"
echo "- Firebase Console: https://console.firebase.google.com/"
echo "- Firebase Docs: https://firebase.google.com/docs"
echo "- Flutter Firebase: https://firebase.flutter.dev/"
echo ""
echo "🚀 Your Finance Tracker App is now ready for production!"

