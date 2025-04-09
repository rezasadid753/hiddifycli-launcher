#!/bin/bash

# ------------------------------------- ⚠ WARNING ⚠ -------------------------------------
# This script installs HiddifyCli, adds configurations, and provides an uninstall option.
# ----------------------------------------------------------------------------------------

# Directories
BASE_DIR="$HOME/HiddifyCli"
CONFIGS_DIR="$BASE_DIR/configs"
SCRIPTS_DIR="$BASE_DIR/scripts"
ICONS_DIR="$BASE_DIR/icons"
HIDDIFY_CLI_PATH="/opt"
DESKTOP_APPS_PATH="$HOME/.local/share/applications"

# Assign an automatic number to file name
FILE_NUM=$(( $(ls -1 $CONFIGS_DIR/config_*.json 2>/dev/null | wc -l) + 1 ))
CONFIG_NAME="config_$FILE_NUM"
SCRIPT_NAME="script_$FILE_NUM"

# Assign an icon number (incrementing)
ICON_ON="$ICONS_DIR/on_${FILE_NUM}.svg"
ICON_OFF="$ICONS_DIR/off_${FILE_NUM}.svg"

sudo echo '⨂ ATTENTION: In case you see an error, uninstall using "./HiddifyCli_AutoInstaller.sh --uninstall" and try installing again'

# Uninstall: Full
if [[ "$1" == "--uninstall" ]]; then    
    echo "● Checking for running HiddifyCli tunnels"
    PIDS=$(pgrep -f "/opt/HiddifyCli run --config")
    
    if [ -n "$PIDS" ]; then
        echo "● Found an active tunnel, Stopping it"
        for PID in $PIDS; do
            PGID=$(ps -o pgid= "$PID" | grep -o '[0-9]*')
            sudo kill -TERM -- -"$PGID" 2>/dev/null
        done
        sudo rm -f /tmp/HiddifyCli_*.pid /tmp/HiddifyCli_active
    fi

    echo "● Removing $BASE_DIR"
    sudo rm -rf $BASE_DIR
    echo "● Removing $DESKTOP_APPS_PATH/HiddifyCli_*.desktop"
    sudo rm -rf $DESKTOP_APPS_PATH/HiddifyCli_*.desktop
    echo "● Removing $HIDDIFY_CLI_PATH/HiddifyCli"
    sudo rm -rf $HIDDIFY_CLI_PATH/HiddifyCli
    echo "● Removing /tmp/HiddifyCli_*.log"
    sudo rm -rf /tmp/HiddifyCli_*.log
    echo "● HiddifyCli and all configurations have been removed"
    echo "● Exiting"
    exit 0
fi

# Uninstall: Configs Only
if [[ "$1" == "--uninstall-configs" ]]; then    
    echo "● Checking for running HiddifyCli tunnels"
    PIDS=$(pgrep -f "/opt/HiddifyCli run --config")
    
    if [ -n "$PIDS" ]; then
        echo "● Found an active tunnel, Stopping it"
        for PID in $PIDS; do
            PGID=$(ps -o pgid= "$PID" | grep -o '[0-9]*')
            sudo kill -TERM -- -"$PGID" 2>/dev/null
        done
        sudo rm -f /tmp/HiddifyCli_*.pid /tmp/HiddifyCli_active
    fi

    echo "● Removing $BASE_DIR/scripts/script_*.sh"
    sudo rm -rf $BASE_DIR/scripts/script_*.sh
    echo "● Removing $BASE_DIR/configs/config_*.json"
    sudo rm -rf $BASE_DIR/configs/config_*.json
    echo "● Removing $DESKTOP_APPS_PATH/HiddifyCli_*.desktop"
    sudo rm -rf $DESKTOP_APPS_PATH/HiddifyCli_*.desktop
    echo "● Removing /tmp/HiddifyCli_*.log"
    sudo rm -rf /tmp/HiddifyCli_*.log
    echo "● All HiddifyCli configs have been removed"
    echo "● Exiting"
    exit 0
fi

# Generate SVG icons dynamically
generate_svg_icon() {
    local FILENAME="$1"
    local COLOR="$2"
    local STATE="$3"
    echo "● Creating $FILENAME"
    sudo touch $FILENAME
    sudo tee "$FILENAME" > /dev/null <<EOL
<svg width="500" height="500" viewBox="0 0 500 500" xmlns="http://www.w3.org/2000/svg">
<path d="M0 130C0 58.203 58.203 0 130 0H370C441.797 0 500 58.203 500 130V289H0V130Z" fill="$COLOR"/>
<path d="M104 158V222" stroke="white" stroke-width="40" stroke-linecap="round"/>
<path d="M105.363 186.353L182.637 165.647" stroke="white" stroke-width="20" stroke-linecap="round"/>
<path d="M184 118V222" stroke="white" stroke-width="40" stroke-linecap="round"/>
<path d="M254 136L255 222" stroke="white" stroke-width="40" stroke-linecap="round"/>
<path d="M255 68L255 68.0001" stroke="white" stroke-width="40" stroke-linecap="round"/>
<path fill-rule="evenodd" clip-rule="evenodd" d="M500 209V130C500 111.897 496.3 94.6591 489.615 79H350C333.431 79 320 92.4315 320 109V179C320 195.569 333.431 209 350 209H500Z" fill="white"/>
<text x="360" y="176" style="font-size:90px; font-weight: bold; font-family: Nimbus Sans" fill="$COLOR">${FILE_NUM}</text>
<path d="M0 289H500V370C500 441.797 441.797 500 370 500H130C58.203 500 0 441.797 0 370V289Z" fill="#383838"/>
$STATE
</svg>
EOL
}

# Ask if HiddifyCli is already installed (default: No)
read -p "○ Do you want to install HiddifyCli? If you haven't installed it already via the script! (Y/n): " INSTALLED
INSTALLED=${INSTALLED:-n} # Default to 'n' if empty

# Install HiddifyCli if not installed
if [[ "$INSTALLED" == "Y" ]]; then
    echo "● Creating $BASE_DIR directory"
    sudo mkdir -p "$BASE_DIR"

    echo "● Creating $CONFIGS_DIR directory"
    sudo mkdir -p "$CONFIGS_DIR"

    echo "● Creating $SCRIPTS_DIR directory"
    sudo mkdir -p "$SCRIPTS_DIR"

    echo "● Creating $ICONS_DIR directory"
    sudo mkdir -p "$ICONS_DIR"

    # Prompt user about GitHub API authentication
    read -p "○ Use GitHub authentication for higher rate limits? (Y/n): " USE_AUTH
    USE_AUTH=${USE_AUTH:-n}

    if [[ "$USE_AUTH" == "Y" ]]; then
        echo "● To generate a token: Navigate to GitHub → Settings → Developer settings → Personal access tokens → Generate new token (classic)"
        read -p "○ Enter your GitHub Personal Access Token: " GITHUB_TOKEN
        AUTH_HEADER="Authorization: token $GITHUB_TOKEN"
    else
        AUTH_HEADER=""
    fi

    # Fetch all HiddifyCli download links
    echo "● Fetching available HiddifyCli versions"
    RELEASES=$(curl --noproxy github.com -s -H "$AUTH_HEADER" https://api.github.com/repos/hiddify/hiddify-core/releases/latest | grep "browser_download_url" | cut -d '"' -f 4 | grep -E "hiddify-cli-linux-.*.tar.gz")

    if [[ -z "$RELEASES" ]]; then
        echo "ERROR: Could not fetch release list, API rate limit may be exceeded or token invalid!"
        echo '● Uninstall using "./HiddifyCli_AutoInstaller.sh --uninstall" and try installing again'
        echo '● Exiting'
        exit 1
    fi

    # Convert to array
    readarray -t RELEASE_ARRAY <<< "$RELEASES"

    echo ""
    echo "------ Available HiddifyCli versions ------"
    for i in "${!RELEASE_ARRAY[@]}"; do
        echo "[$i] ${RELEASE_ARRAY[$i]}"
    done
    echo "-------------------------------------------"
    echo ""
    
    # Ask user to choose one
    read -p "○ Enter the number of the version you want to download: " VERSION_INDEX
    DOWNLOAD_URL="${RELEASE_ARRAY[$VERSION_INDEX]}"

    if [[ -z "$DOWNLOAD_URL" ]]; then
        echo "ERROR: Invalid selection"
        echo '● Uninstall using "./HiddifyCli_AutoInstaller.sh --uninstall" and try installing again'
        echo "● Exiting"
        exit 1
    fi

    echo "● Downloading $DOWNLOAD_URL"
    if ! wget -q --progress=dot:giga --no-check-certificate "$DOWNLOAD_URL" -O /tmp/HiddifyCli.tar.gz; then
        echo "ERROR: Download failed! Please check your connection"
        echo '● Uninstall using "./HiddifyCli_AutoInstaller.sh --uninstall" and try installing again'
        echo "● Exiting"
        exit 1
    fi

    # Extract and move files
    echo "● Creating /tmp/HiddifyCliExtracted directory"
    mkdir -p /tmp/HiddifyCliExtracted
    
    echo "● Extracting HiddifyCli"
    if ! tar -xzf /tmp/HiddifyCli.tar.gz -C /tmp/HiddifyCliExtracted; then
        echo "ERROR: Extraction failed! The archive may be corrupted"
        echo '● Uninstall using "./HiddifyCli_AutoInstaller.sh --uninstall" and try installing again'
        echo "● Exiting"
        exit 1
    fi
    
    if ! sudo mv /tmp/HiddifyCliExtracted/webui "$BASE_DIR"; then
        echo 'ERROR: Move operation failed! "webui" folder were not found'
        echo '● Uninstall using "./HiddifyCli_AutoInstaller.sh --uninstall" and try installing again'
        echo "● Exiting"
        exit 1
    fi

    if ! sudo mv /tmp/HiddifyCliExtracted/HiddifyCli "$HIDDIFY_CLI_PATH"; then
        echo 'ERROR: Move operation failed! "HiddifyCli" appimage were not found'
        echo '● Uninstall using "./HiddifyCli_AutoInstaller.sh --uninstall" and try installing again'
        echo "● Exiting"
        exit 1
    fi

    echo "● Removing /tmp/HiddifyCli.tar.gz file"
    rm /tmp/HiddifyCli.tar.gz
    
    echo "● Removing /tmp/HiddifyCliExtracted directory"
    rm -rf /tmp/HiddifyCliExtracted
else
    sudo echo "● Skipping HiddifyCli installation process"
    sudo echo "⨂ ATTENTION: Always make sure to end current tunnel and then start another tunnel"
fi

# Create icons
generate_svg_icon "$ICON_OFF" "#BB0707" '<path d="M214.555 392.166V396.95C214.555 404.623 213.515 411.511 211.435 417.612C209.354 423.714 206.419 428.914 202.629 433.213C198.839 437.465 194.309 440.724 189.039 442.989C183.816 445.254 178.015 446.387 171.636 446.387C165.303 446.387 159.502 445.254 154.232 442.989C149.009 440.724 144.479 437.465 140.643 433.213C136.806 428.914 133.825 423.714 131.698 417.612C129.618 411.511 128.578 404.623 128.578 396.95V392.166C128.578 384.447 129.618 377.559 131.698 371.504C133.778 365.402 136.714 360.202 140.504 355.903C144.34 351.604 148.87 348.323 154.094 346.058C159.363 343.793 165.164 342.66 171.497 342.66C177.876 342.66 183.677 343.793 188.9 346.058C194.17 348.323 198.7 351.604 202.49 355.903C206.327 360.202 209.285 365.402 211.365 371.504C213.492 377.559 214.555 384.447 214.555 392.166ZM193.546 396.95V392.027C193.546 386.665 193.061 381.951 192.09 377.883C191.119 373.815 189.686 370.395 187.791 367.621C185.896 364.848 183.585 362.768 180.857 361.381C178.13 359.948 175.01 359.231 171.497 359.231C167.984 359.231 164.864 359.948 162.137 361.381C159.456 362.768 157.168 364.848 155.272 367.621C153.424 370.395 152.014 373.815 151.043 377.883C150.072 381.951 149.587 386.665 149.587 392.027V396.95C149.587 402.266 150.072 406.981 151.043 411.095C152.014 415.162 153.447 418.606 155.342 421.426C157.237 424.199 159.548 426.302 162.275 427.735C165.003 429.168 168.123 429.885 171.636 429.885C175.149 429.885 178.269 429.168 180.996 427.735C183.723 426.302 186.011 424.199 187.86 421.426C189.709 418.606 191.119 415.162 192.09 411.095C193.061 406.981 193.546 402.266 193.546 396.95ZM250.332 344.047V445H229.531V344.047H250.332ZM290.547 387.174V403.398H244.646V387.174H290.547ZM295.4 344.047V360.341H244.646V344.047H295.4ZM328.266 344.047V445H307.465V344.047H328.266ZM368.48 387.174V403.398H322.58V387.174H368.48ZM373.334 344.047V360.341H322.58V344.047H373.334Z" fill="white"/>'
generate_svg_icon "$ICON_ON" "#007D51" '<path d="M242.358 392.166V396.95C242.358 404.623 241.318 411.511 239.238 417.612C237.158 423.714 234.223 428.914 230.433 433.213C226.642 437.465 222.112 440.724 216.843 442.989C211.619 445.254 205.818 446.387 199.439 446.387C193.107 446.387 187.306 445.254 182.036 442.989C176.813 440.724 172.283 437.465 168.446 433.213C164.61 428.914 161.628 423.714 159.502 417.612C157.422 411.511 156.382 404.623 156.382 396.95V392.166C156.382 384.447 157.422 377.559 159.502 371.504C161.582 365.402 164.517 360.202 168.308 355.903C172.144 351.604 176.674 348.323 181.897 346.058C187.167 343.793 192.968 342.66 199.301 342.66C205.68 342.66 211.481 343.793 216.704 346.058C221.974 348.323 226.504 351.604 230.294 355.903C234.131 360.202 237.089 365.402 239.169 371.504C241.295 377.559 242.358 384.447 242.358 392.166ZM221.35 396.95V392.027C221.35 386.665 220.864 381.951 219.894 377.883C218.923 373.815 217.49 370.395 215.595 367.621C213.7 364.848 211.388 362.768 208.661 361.381C205.934 359.948 202.814 359.231 199.301 359.231C195.788 359.231 192.668 359.948 189.94 361.381C187.259 362.768 184.971 364.848 183.076 367.621C181.227 370.395 179.817 373.815 178.847 377.883C177.876 381.951 177.391 386.665 177.391 392.027V396.95C177.391 402.266 177.876 406.981 178.847 411.095C179.817 415.162 181.25 418.606 183.146 421.426C185.041 424.199 187.352 426.302 190.079 427.735C192.806 429.168 195.926 429.885 199.439 429.885C202.952 429.885 206.073 429.168 208.8 427.735C211.527 426.302 213.815 424.199 215.664 421.426C217.513 418.606 218.923 415.162 219.894 411.095C220.864 406.981 221.35 402.266 221.35 396.95ZM339.498 344.047V445H318.697L278.136 377.328V445H257.335V344.047H278.136L318.767 411.788V344.047H339.498Z" fill="white"/>'

echo "⨂ ATTENTION: Make sure none of your current configs are active before proceeding"

# Ask user for subscription link
read -p "○ Enter your subscription link (Press Enter for an empty config file): " SUBSCRIPTION_LINK
CONFIG_PATH="$CONFIGS_DIR/${CONFIG_NAME}.json"

# Create the config file
echo "● Creating $CONFIG_PATH"

# Check if the user didn't provide a link (empty input)
if [ -z "$SUBSCRIPTION_LINK" ]; then
    echo "● No subscription link provided. Creating an empty JSON file at $CONFIG_PATH"
    sudo touch $CONFIG_PATH
    echo "⨂ ATTENTION: You can later add your JSON config to this file"
else
    echo "● Establishing first connection to grab the config and create the JSON configuration"
    sudo /opt/HiddifyCli run --config "$SUBSCRIPTION_LINK" --tun --directory "$BASE_DIR" > /tmp/HiddifyCli_current.log 2>&1 &
    HIDDIFY_PID=$!

    # Wait until the log contains the target line
    while ! grep -q "INFO CORE STARTED:" /tmp/HiddifyCli_current.log; do sleep 0.5; done
    sudo rm -rf /tmp/HiddifyCli_current.log

    # Send Ctrl+C to stop the background process
    kill -INT $HIDDIFY_PID
    echo "● Saving config to $CONFIG_PATH"
    sudo cp "$BASE_DIR/current-config.json" "$CONFIG_PATH"
fi

# Create the shell script
SCRIPT_FILE="$SCRIPTS_DIR/${SCRIPT_NAME}.sh"
echo "● Creating $SCRIPT_FILE"
sudo touch $SCRIPT_FILE

echo "● Creating $ACTIVE_VPN_FILE"
ACTIVE_VPN_FILE="/tmp/HiddifyCli_active"
sudo touch $ACTIVE_VPN_FILE

sudo tee "$SCRIPT_FILE" > /dev/null <<EOL
#!/bin/bash

BASE_DIR="$BASE_DIR"
CONFIG_NAME="$CONFIG_NAME"
CONFIG_PATH="$CONFIG_PATH"
PID_FILE="/tmp/HiddifyCli_$CONFIG_NAME.pid"
LOG_FILE="/tmp/HiddifyCli_$CONFIG_NAME.log"
ACTIVE_VPN_FILE="/tmp/HiddifyCli_active"
ICON_ON="$ICON_ON"
ICON_OFF="$ICON_OFF"
DESKTOP_FILE="$DESKTOP_APPS_PATH/HiddifyCli_${FILE_NUM}.desktop"

stop_existing_vpn() {
    if [ -f "\$ACTIVE_VPN_FILE" ]; then
        PREV_VPN=\$(cat "\$ACTIVE_VPN_FILE")
        PREV_PID_FILE="/tmp/HiddifyCli_\${PREV_VPN}.pid"
        PREV_FILE_NUM="\${PREV_VPN##*_}"
        PREV_DESKTOP_FILE="$DESKTOP_APPS_PATH/HiddifyCli_\${PREV_FILE_NUM}.desktop"
        PREV_ICON_ON="$ICONS_DIR/on_\${PREV_FILE_NUM}.svg"
        PREV_ICON_OFF="$ICONS_DIR/off_\${PREV_FILE_NUM}.svg"

        if [ -f "\$PREV_PID_FILE" ]; then
            PREV_PID=\$(cat "\$PREV_PID_FILE")
            echo "Stopping previous VPN (\$PREV_VPN)"
            sudo kill "\$PREV_PID" 2>/dev/null
            sudo rm "\$PREV_PID_FILE"
            sudo rm -f "\$ACTIVE_VPN_FILE"
            
            sed -i "s|Icon=\$PREV_ICON_ON|Icon=\$PREV_ICON_OFF|" "\$PREV_DESKTOP_FILE"
        fi
    fi
}

start_vpn() {
    stop_existing_vpn

    echo "Starting Hiddify VPN"
    sudo nohup $HIDDIFY_CLI_PATH/HiddifyCli run --config "\$CONFIG_PATH" --tun --directory "\$BASE_DIR" >> "\$LOG_FILE" 2>&1 &
    echo \$! > "\$PID_FILE"
    disown  

    echo "\$CONFIG_NAME" > "\$ACTIVE_VPN_FILE"

    sed -i "s|Icon=\$ICON_OFF|Icon=\$ICON_ON|" "\$DESKTOP_FILE"
}

stop_vpn() {
    if [ -f "\$PID_FILE" ]; then
        PID=\$(cat "\$PID_FILE")
        echo "Stopping Hiddify VPN"
        sudo kill "\$PID" 2>/dev/null
        sudo rm "\$PID_FILE"
        sudo rm -f "\$ACTIVE_VPN_FILE"

        sed -i "s|Icon=\$ICON_ON|Icon=\$ICON_OFF|" "\$DESKTOP_FILE"
    fi
}

if [ -f "\$PID_FILE" ]; then
    stop_vpn
else
    start_vpn
fi
EOL

sudo chmod +x "$SCRIPT_FILE"

# Create the log file
sudo touch /tmp/HiddifyCli_${CONFIG_NAME}.log
sudo chmod 666 /tmp/HiddifyCli_${CONFIG_NAME}.log

# Create desktop entry
DESKTOP_FILE="$DESKTOP_APPS_PATH/HiddifyCli_${FILE_NUM}.desktop"
echo "● Creating $DESKTOP_FILE"
sudo touch $DESKTOP_FILE

sudo tee "$DESKTOP_FILE" > /dev/null <<EOL
[Desktop Entry]
Name=HiddifyCli $FILE_NUM
Comment=Toggle HiddifyCli tunnel on and off
Exec=pkexec $SCRIPT_FILE
Icon=$ICON_OFF
Terminal=false
Type=Application
EOL

echo "● Installation completed"
echo "⨂ ATTENTION: You can now run HiddifyCli $FILE_NUM using the application menu"

