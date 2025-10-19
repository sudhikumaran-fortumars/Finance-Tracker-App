@echo off
echo 🚀 Finance Tracker App Reset Tool
echo ================================
echo.

echo ⚠️  WARNING: This will delete ALL data from Firebase!
echo.
set /p confirm="Are you sure you want to continue? (y/N): "

if /i "%confirm%"=="y" (
    echo.
    echo 🧹 Resetting app data...
    dart reset_app.dart
    echo.
    echo ✅ Reset complete! App is ready for client delivery.
) else (
    echo.
    echo ❌ Reset cancelled.
)

echo.
pause
