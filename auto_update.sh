#!/bin/bash

# Configuration
ENV_FILE="$HOME/.hermes/.env"
FLAG_FILE="/tmp/hermes_update_postponed"
HERMES_DIR="$HOME/.hermes/hermes-agent"

# Load environment variables
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

TOKEN="${TELEGRAM_BOT_TOKEN:-}"
CHAT_ID="${TELEGRAM_HOME_CHANNEL:-}"

send_tg_message() {
    local message="$1"
    if [ -n "$TOKEN" ] && [ -n "$CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
            -d "chat_id=${CHAT_ID}" \
            -d "text=${message}" \
            -d "parse_mode=Markdown" > /dev/null
    else
        echo "$message"
    fi
}

# 1. Check current and target versions
if [ -d "$HERMES_DIR" ]; then
    cd "$HERMES_DIR" || exit 1
    # Get current version (hash or tag)
    CURRENT_VERSION=$(git describe --tags --always 2>/dev/null || git log -1 --format="%h")
    
    # Fetch latest from remote to know what we are updating to
    git fetch origin main --quiet 2>/dev/null
    TARGET_VERSION=$(git log -1 --format="%h" origin/main 2>/dev/null)
    
    # Check if we are already up to date
    if [ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]; then
        # send_tg_message "ℹ️ *Hermes Auto-Update*\nHermes is already up-to-date at version \`$CURRENT_VERSION\`."
        # Uncomment above to receive weekly "already up to date" messages, otherwise it exits silently.
        exit 0
    fi
else
    CURRENT_VERSION="Unknown"
    TARGET_VERSION="Latest"
fi

# 2. Clean previous flag
rm -f "$FLAG_FILE"

# 3. Notify user
send_tg_message "⚠️ *Hermes Automatic Update*
A system update will start in 1 minute.
*Current version:* \`$CURRENT_VERSION\`
*Target version:* \`$TARGET_VERSION\`

If you are currently using Hermes, simply reply: *« Postpone update »* or create the file \`/tmp/hermes_update_postponed\` to abort."

# 4. Wait 60 seconds
sleep 60

# 5. Check if postponed
if [ -f "$FLAG_FILE" ]; then
    send_tg_message "🛑 *Update postponed.* Procedure aborted. Staying on \`$CURRENT_VERSION\`."
    rm -f "$FLAG_FILE"
    exit 0
fi

# 6. Proceed with update
send_tg_message "🔄 *Starting update...* (Gateway shutting down)"

# Make sure hermes is in PATH
export PATH="$HOME/.hermes/hermes-agent/venv/bin:$HOME/.local/bin:$PATH"

# Execute update
hermes gateway stop
yes | hermes update

# Safety mechanism to ensure python-dotenv is present (prevents gateway restart failures)
$HOME/.hermes/hermes-agent/venv/bin/pip install python-dotenv

# 7. Gather changes and restart
if [ -d "$HERMES_DIR" ]; then
    cd "$HERMES_DIR" || exit 1
    NEW_VERSION=$(git describe --tags --always 2>/dev/null || git log -1 --format="%h")
    # Get the last 5 commits that were pulled
    CHANGELOG=$(git log ${CURRENT_VERSION}..HEAD --oneline -n 5 | sed 's/^/- /')
    
    if [ -z "$CHANGELOG" ]; then
        CHANGELOG="- (No specific commit messages found or force-update)"
    fi
else
    NEW_VERSION="Unknown"
    CHANGELOG="- Unknown changes"
fi

hermes gateway start

send_tg_message "✅ *Hermes update completed and gateway restarted!*

*Updated to:* \`$NEW_VERSION\`

*Recent changes:*
$CHANGELOG"
