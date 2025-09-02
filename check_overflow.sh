#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==== Football Training App Overflow Checker ====${NC}"
echo -e "${YELLOW}This script will help identify potential overflow issues in your UI${NC}"
echo ""

# Function to check for flutter and dependencies
check_flutter() {
  echo -e "${BLUE}Checking Flutter setup...${NC}"
  
  if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter not found! Please install Flutter first.${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}Flutter is installed.${NC}"
  flutter --version | head -n 1
  
  echo -e "${BLUE}Checking dependencies...${NC}"
  flutter pub get
  
  echo -e "${GREEN}Dependencies updated successfully.${NC}"
}

# Function to run static analysis
run_analysis() {
  echo -e "${BLUE}Running static analysis to find potential UI issues...${NC}"
  
  flutter analyze --no-fatal-infos
  
  echo -e "${BLUE}Looking for RenderFlex overflow warnings in source code...${NC}"
  grep -r "RenderFlex.*overflow" --include="*.dart" lib/
  
  if [ $? -eq 0 ]; then
    echo -e "${YELLOW}Found references to RenderFlex overflow in the code. These might be in comments or actual error handling.${NC}"
  else
    echo -e "${GREEN}No direct references to RenderFlex overflow found in the code.${NC}"
  fi
}

# Function to run app in profile mode to check for overflows
run_profile_check() {
  echo -e "${BLUE}Running app in profile mode to check for overflow issues...${NC}"
  echo -e "${YELLOW}This will start the app - please check the debug console for overflow warnings${NC}"
  echo -e "${YELLOW}Press 'q' to quit the app when done checking.${NC}"
  
  flutter run --profile --dart-define=SHOW_OVERFLOW_INDICATORS=true
}

# Function to run the OverflowUtils check
check_overflow_utils() {
  echo -e "${BLUE}Checking for proper use of OverflowUtils...${NC}"
  
  OVERFLOW_UTILS_IMPORTS=$(grep -r "import .*overflow_utils.dart" --include="*.dart" lib/)
  
  if [ -z "$OVERFLOW_UTILS_IMPORTS" ]; then
    echo -e "${YELLOW}Warning: No imports of overflow_utils.dart found in the codebase.${NC}"
    echo -e "${YELLOW}Consider using OverflowUtils in UI files to prevent overflow issues.${NC}"
  else
    echo -e "${GREEN}Found imports of OverflowUtils in these files:${NC}"
    echo "$OVERFLOW_UTILS_IMPORTS"
  fi
  
  RESPONSIVE_SIZE_USAGE=$(grep -r "responsiveSize" --include="*.dart" lib/)
  
  if [ -z "$RESPONSIVE_SIZE_USAGE" ]; then
    echo -e "${YELLOW}Warning: No usage of responsiveSize found in the codebase.${NC}"
    echo -e "${YELLOW}Consider using responsiveSize for responsive dimensions.${NC}"
  else
    echo -e "${GREEN}Found usage of responsiveSize in various files.${NC}"
  fi
}

# Main menu
main_menu() {
  echo -e "${BLUE}Select an option:${NC}"
  echo "1. Check Flutter setup and dependencies"
  echo "2. Run static analysis for overflow issues"
  echo "3. Check proper use of OverflowUtils"
  echo "4. Run app in profile mode to check for overflows"
  echo "5. Run all checks"
  echo "q. Quit"
  
  read -p "Enter your choice: " choice
  
  case $choice in
    1) check_flutter; main_menu ;;
    2) run_analysis; main_menu ;;
    3) check_overflow_utils; main_menu ;;
    4) run_profile_check; main_menu ;;
    5) 
      check_flutter
      run_analysis
      check_overflow_utils
      run_profile_check
      ;;
    q|Q) exit 0 ;;
    *) echo -e "${RED}Invalid option${NC}"; main_menu ;;
  esac
}

# Start the script
main_menu
