set -e

# Arguments
SIM_NAME="${1:-iPhone 15}"       # Default simulator name
IOS_VERSION="${2:-17.5}"         # Default iOS version
JAVA_VERSION="${3:-22}"          # Default Java version

# Colors for output
RED_BOLD='\033[1;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED_BOLD}[1/10] Checking Homebrew installation...${NC}"
if ! command -v brew &> /dev/null; then
  echo -e "${GREEN}Installing Homebrew...${NC}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo -e "${GREEN}Homebrew is already installed${NC}"
fi

echo -e "${RED_BOLD}[2/10] Reinstalling Node.js...${NC}"
brew reinstall node

echo -e "${RED_BOLD}[3/10] Installing Java via SDKMAN...${NC}"
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java "$JAVA_VERSION"-open
sdk use java "$JAVA_VERSION"-open
echo -e "${GREEN}Java $JAVA_VERSION installed via SDKMAN${NC}"

echo -e "${RED_BOLD}[4/10] Installing Appium globally...${NC}"
npm install -g appium
echo -e "${GREEN}Appium installed${NC}"

echo -e "${RED_BOLD}[5/10] Installing Appium XCUITest driver...${NC}"
appium driver install xcuitest
echo -e "${GREEN}XCUITest driver installed${NC}"

echo -e "${RED_BOLD}[6/10] Installing Carthage...${NC}"
brew reinstall carthage
echo -e "${GREEN}Carthage installed${NC}"

echo -e "${RED_BOLD}[7/10] Starting Appium server in background...${NC}"
nohup appium -a 0.0.0.0 -p 4723 -pa /wd/hub --relaxed-security > appium_log.txt 2>&1 &
sleep 5
echo -e "${GREEN}Appium server started${NC}"

echo -e "${RED_BOLD}[8/10] Searching for simulator '$SIM_NAME' on iOS $IOS_VERSION...${NC}"
UDID=$(xcrun simctl list devices | sed -n "/^-- iOS $IOS_VERSION --/,/^$/p" | grep -i "$SIM_NAME (" | grep -oE '[A-Fa-f0-9-]{36}' | head -n 1)
echo -e "${GREEN}Found UDID: $UDID${NC}"

echo -e "${RED_BOLD}[9/10] Booting simulator $SIM_NAME...${NC}"
xcrun simctl boot "$UDID" || echo "(Simulator might already be booted)"
echo -e "${GREEN}Simulator booted${NC}"

echo -e "${RED_BOLD}[10/10] Building WebDriverAgent on simulator...${NC}"
cd ~/.appium/node_modules/appium-xcuitest-driver/node_modules/appium-webdriveragent

LOG_FILE="wda_build.log"
rm -f "$LOG_FILE"

xcodebuild -project WebDriverAgent.xcodeproj \
  -scheme WebDriverAgentRunner \
  -destination "platform=iOS Simulator,id=$UDID" \
  DEVELOPMENT_TEAM="" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  test > "$LOG_FILE" 2>&1 &

echo -e "${GREEN}⏳ Waiting for WebDriverAgent to finish building...${NC}"

while ! grep -q "ServerURLHere->http://" "$LOG_FILE"; do
  sleep 10
  echo -e "${GREEN}⏳ Still building WebDriverAgent...${NC}"
done

echo -e "${GREEN}WebDriverAgent build completed${NC}"
tail -n 20 "$LOG_FILE"