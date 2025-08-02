#!/bin/bash

# Fix iOS Xcode Configuration Script
# This script fixes the common issue where Xcode configurations reset to "None"

echo "🔧 Fixing iOS Xcode Configuration..."

# Navigate to iOS directory
cd "$(dirname "$0")"

# Create Profile.xcconfig if it doesn't exist
if [ ! -f "Flutter/Profile.xcconfig" ]; then
    echo "📝 Creating Profile.xcconfig..."
    cat > Flutter/Profile.xcconfig << EOF
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.profile.xcconfig"
#include "Generated.xcconfig"
EOF
fi

# Run flutter clean and rebuild
echo "🧹 Cleaning Flutter project..."
cd ..
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "🍎 Installing iOS dependencies..."
cd ios
pod install

echo "✅ Configuration fixed! Your Xcode project should now properly reference:"
echo "  • Debug → Debug.xcconfig"  
echo "  • Release → Release.xcconfig"
echo "  • Profile → Profile.xcconfig"
echo ""
echo "💡 If the issue persists, try opening Runner.xcworkspace in Xcode and verify"
echo "   the configuration settings under Project → Runner → Info → Configurations"