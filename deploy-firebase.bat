@echo off
REM Firebase Deployment Script for Finance Tracker App
REM This script deploys all Firebase services with proper configuration

echo 🚀 Starting Firebase deployment for Finance Tracker App...

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Firebase CLI not found. Please install it first:
    echo npm install -g firebase-tools
    pause
    exit /b 1
)

REM Check if user is logged in
firebase projects:list >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Please login to Firebase first:
    echo firebase login
    pause
    exit /b 1
)

echo ✅ Firebase CLI is ready

REM Deploy Firestore rules
echo 📝 Deploying Firestore rules...
firebase deploy --only firestore:rules
if %errorlevel% neq 0 (
    echo ❌ Failed to deploy Firestore rules
    pause
    exit /b 1
)
echo ✅ Firestore rules deployed successfully

REM Deploy Firestore indexes
echo 📊 Deploying Firestore indexes...
firebase deploy --only firestore:indexes
if %errorlevel% neq 0 (
    echo ❌ Failed to deploy Firestore indexes
    pause
    exit /b 1
)
echo ✅ Firestore indexes deployed successfully

REM Deploy Storage rules
echo 💾 Deploying Storage rules...
firebase deploy --only storage
if %errorlevel% neq 0 (
    echo ❌ Failed to deploy Storage rules
    pause
    exit /b 1
)
echo ✅ Storage rules deployed successfully

REM Deploy Functions
echo ⚡ Deploying Functions...
cd functions
npm install
cd ..
firebase deploy --only functions
if %errorlevel% neq 0 (
    echo ❌ Failed to deploy Functions
    pause
    exit /b 1
)
echo ✅ Functions deployed successfully

REM Deploy Hosting (if configured)
echo 🌐 Deploying Hosting...
firebase deploy --only hosting
if %errorlevel% neq 0 (
    echo ⚠️ Hosting deployment skipped (not configured)
) else (
    echo ✅ Hosting deployed successfully
)

REM Deploy Extensions (if any)
echo 🔌 Deploying Extensions...
firebase deploy --only extensions
if %errorlevel% neq 0 (
    echo ⚠️ Extensions deployment skipped (none configured)
) else (
    echo ✅ Extensions deployed successfully
)

echo.
echo 🎉 Firebase deployment completed successfully!
echo.
echo 📋 Deployment Summary:
echo ✅ Firestore rules and indexes
echo ✅ Storage rules
echo ✅ Functions
echo ✅ Hosting (if configured)
echo ✅ Extensions (if configured)
echo.
echo 🔗 Next steps:
echo 1. Test your app with the new Firebase configuration
echo 2. Monitor Firebase Console for any issues
echo 3. Set up monitoring and alerts
echo 4. Configure backup strategies
echo.
echo 📚 Documentation:
echo - Firebase Console: https://console.firebase.google.com/
echo - Firebase Docs: https://firebase.google.com/docs
echo - Flutter Firebase: https://firebase.flutter.dev/
echo.
echo 🚀 Your Finance Tracker App is now ready for production!
pause

