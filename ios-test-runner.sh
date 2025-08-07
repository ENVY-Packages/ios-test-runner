#!/bin/bash
set -e

# ------------------------------
# Color Variables
# ------------------------------

GREEN=$(tput setaf 2)
BLUE=$(tput setaf 6)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
RESET=$(tput sgr0)

# ------------------------------
# Dependency Check
# ------------------------------

REQUIRED_TOOLS=("xcodebuild" "xcrun" "xcresultparser")

for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v "$tool" &>/dev/null; then
    echo "${RED}❌ Error: '$tool' is not installed or not available in PATH.${RESET}"
    echo "${YELLOW}➡️  Please install it before running this script.${RESET}"
    exit 1
  fi
done

# ------------------------------
# Default Values
# ------------------------------

SCHEME="BillManagement"
OUTPUT_DIR="reporter/reports"
RESULT_BUNDLE="TestResults.xcresult"
DEVICE="iPhone 16 Pro Max"

# ------------------------------
# Help Function
# ------------------------------

function print_help() {
  echo ""
  echo "${BLUE}🧪 iOS Test Runner${RESET}"
  echo ""
  echo "Usage: $0 [-s scheme] [-d device] [-o output_dir]"
  echo ""
  echo "Options:"
  echo "  -s    Scheme name (default: $SCHEME)"
  echo "  -d    Simulator device name (default: $DEVICE)"
  echo "  -o    Output directory for reports (default: $OUTPUT_DIR)"
  echo "  -h    Show help"
}

# ------------------------------
# Parse Arguments
# ------------------------------

while getopts "s:d:o:h" opt; do
  case $opt in
    s) SCHEME="$OPTARG" ;;
    d) DEVICE="$OPTARG" ;;
    o) OUTPUT_DIR="$OPTARG" ;;
    h) print_help; exit 0 ;;
    *) print_help; exit 1 ;;
  esac
done

# ------------------------------
# Derived Variables
# ------------------------------

JUNIT_REPORT="$OUTPUT_DIR/junit.xml"
HTML_REPORT="$OUTPUT_DIR/report.html"

# ------------------------------
# Create Output Directory
# ------------------------------

rm -rf "$OUTPUT_DIR"
rm -rf "$RESULT_BUNDLE"
mkdir -p "$OUTPUT_DIR"

echo "${BLUE}🔧 Running tests on '${YELLOW}$DEVICE${BLUE}' for scheme '${YELLOW}$SCHEME${BLUE}'...${RESET}"
echo "${BLUE}📁 Reports will be saved in '${YELLOW}$OUTPUT_DIR${BLUE}'${RESET}"

# ------------------------------
# Reset and Boot Simulator
# ------------------------------

echo "${BLUE}🌀 Resetting and booting simulator: $DEVICE${RESET}"
killall Simulator &>/dev/null || true
xcrun simctl shutdown all || true
xcrun simctl erase all || true
open -a Simulator

# ------------------------------
# Run Tests
# ------------------------------

echo "${BLUE}🚀 Starting test execution...${RESET}"
xcodebuild test \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,name=$DEVICE,OS=latest" \
  -enableCodeCoverage YES \
  -resultBundlePath "$RESULT_BUNDLE" || true

# ------------------------------
# Generate Reports
# ------------------------------

echo "${BLUE}📄 Generating test reports...${RESET}"
xcresultparser -o txt "$RESULT_BUNDLE" > "$OUTPUT_DIR/output.txt"
xcresultparser -o junit "$RESULT_BUNDLE" > "$JUNIT_REPORT"
xcresultparser -o html "$RESULT_BUNDLE" > "$HTML_REPORT"

# ------------------------------
# Done
# ------------------------------

echo "${GREEN}✅ Test execution completed successfully!${RESET}"
echo "${GREEN}📁 Output Directory: ${YELLOW}$OUTPUT_DIR${RESET}"
echo "${GREEN}📄 HTML Report: ${YELLOW}$HTML_REPORT${RESET}"
echo "${GREEN}📄 JUnit Report: ${YELLOW}$JUNIT_REPORT${RESET}"
