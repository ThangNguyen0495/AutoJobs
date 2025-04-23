#!/bin/bash

set -e

# Args
SIM_NAME="${1:-iPhone 15}"
IOS_VERSION="${2:-17.5}"
NODE_VERSION="${3:-21}"
JAVA_VERSION="${4:-22}"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo "[1/10] Install Homebrew"
if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew already installed"
fi

echo "[2/10] Install Nodejs"
# Function to compare versions
# Returns 0 (true) if $1 >= $2
function version_ge() {
  [ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" ]
}

# Check if Node.js is installed
if ! command -v node >/dev/null 2>&1; then
  echo "Node.js is not installed. Installing..."
  brew install node
else
  CURRENT_VERSION=$(node -v | sed 's/v//')
  echo "Node.js is already installed. Version: $CURRENT_VERSION"

  if version_ge "$CURRENT_VERSION" "$NODE_VERSION"; then
    echo "Node.js version is >= $NODE_VERSION. No need to reinstall."
  else
    echo "Node.js version is less than $NODE_VERSION. Upgrading..."
    brew upgrade node
  fi
fi


echo "[3/10] Install Java"
# Function to set JAVA_HOME using installed JDK path
set_java_home() {
  JAVA_PATH=$(/usr/libexec/java_home)
  echo "Setting JAVA_HOME to $JAVA_PATH"
  export JAVA_HOME="$JAVA_PATH"

  # Ensure ~/.zshrc exists
  if [ ! -f ~/.zshrc ]; then
    # shellcheck disable=SC2088
    echo "~/.zshrc not found. Creating it..."
    touch ~/.zshrc
  fi

  # Add JAVA_HOME and PATH to ~/.zshrc
  # shellcheck disable=SC2129
  # shellcheck disable=SC2016
  echo 'export JAVA_HOME=$(/usr/libexec/java_home)' >> ~/.zshrc
  # shellcheck disable=SC2016
  echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.zshrc
  echo 'export CPPFLAGS="-I/opt/homebrew/opt/openjdk/include"' >> ~/.zshrc
  # shellcheck disable=SC1090
  source ~/.zshrc
}

# Check if Java is installed
if ! command -v java >/dev/null 2>&1; then
  echo "📦 Java is not installed. Installing OpenJDK..."
  brew install openjdk
  sudo ln -sfn /opt/homebrew/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
  # shellcheck disable=SC2016
  echo 'export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"' >> ~/.zshrc
  # shellcheck disable=SC1090
  source ~/.zshrc
  set_java_home
else
  CURRENT_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
  echo "🔍 Java is already installed. Version: $CURRENT_VERSION"

  if version_ge "$CURRENT_VERSION" "$JAVA_VERSION"; then
    echo "✅ Java version is >= $JAVA_VERSION. No need to update."
  else
    echo "⚠️ Java version is less than $JAVA_VERSION. Upgrading..."
    brew upgrade openjdk
    set_java_home
  fi
fi


#echo "Installing Appium..."
#npm install -g appium
#
#echo "Installing Appium XCUI Test Driver..."
#appium driver install xcuitest
#
#echo "Installing Carthage..."
#brew install carthage
#
#echo -e "${GREEN}Carthage installed${NC}"
#
#echo "Starting Appium server in background..."
#nohup nohup appium -a 0.0.0.0 -p 4723 -pa /wd/hub --relaxed-security> appium_log.txt 2>&1 &
#sleep 5
#
#echo -e "${GREEN}Appium started${NC}"
#
#echo "Find simulator for '$SIM_NAME' with iOS $IOS_VERSION..."
#UDID=$(xcrun simctl list devices | sed -n "/^-- iOS $IOS_VERSION --/,/^$/p" | grep -i "$SIM_NAME (" | grep -oE '[A-Fa-f0-9-]{36}' | head -n 1)
#echo -e "${GREEN}UDID: $UDID${NC}"
#
#echo "Booting simulator $SIM_NAME..."
#xcrun simctl boot "$UDID" || echo "(Simulator may already be booted)"
#
#echo "Installing WebDriverAgent on simulator..."
#cd ~/.appium/node_modules/appium-xcuitest-driver/node_modules/appium-webdriveragent
#
#LOG_FILE="wda_build.log"
#rm -f "$LOG_FILE"
#
#xcodebuild -project WebDriverAgent.xcodeproj \
#  -scheme WebDriverAgentRunner \
#  -destination "platform=iOS Simulator,id=$UDID" \
#  DEVELOPMENT_TEAM="" \
#  CODE_SIGN_IDENTITY="" \
#  CODE_SIGNING_REQUIRED=NO \
#  CODE_SIGNING_ALLOWED=NO \
#  test > "$LOG_FILE" 2>&1 &
#
#echo "Waiting for WebDriverAgent build to finish..."
#
#while ! grep -q "ServerURLHere->http://" "$LOG_FILE"; do
#  sleep 10
#  echo "Waiting for WebDriverAgent build to finish..."
#done
#
#echo "${GREEN} Build appears to be finished${NC}"
#tail -n 20 "$LOG_FILE"
