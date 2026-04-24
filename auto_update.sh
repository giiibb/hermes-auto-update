#!/bin/bash

# Configuration
ENV_FILE="$HOME/.hermes/.env"
FLAG_FILE="/tmp/hermes_update_postponed"

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

# 1. Clean previous flag
rm -f "$FLAG_FILE"

# 2. Notify user
send_tg_message "⚠️ *Hermes Automatic Update*
A system update will start in 1 minute.
If you are currently using Hermes, simply reply: *« Postpone update »* or create the file \`/tmp/hermes_update_postponed\` to abort."

# 3. Wait 60 seconds
sleep 60

# 4. Check if postponed
if [ -f "$FLAG_FILE" ]; then
    send_tg_message "🛑 *Update postponed.* Procedure aborted."
    rm -f "$FLAG_FILE"
    exit 0
fi

# 5. Proceed with update
send_tg_message "🔄 *Starting update...* (Gateway shutting down)"

# Make sure hermes is in PATH
export PATH="$HOME/.hermes/hermes-agent/venv/bin:$HOME/.local/bin:$PATH"

# Execute update
hermes gateway stop
yes | hermes update

# Safety mechanism to ensure python-dotenv is present (prevents gateway restart failures)
$HOME/.hermes/hermes-agent/venv/bin/pip install python-dotenv

hermes gateway start

send_tg_message "✅ *Hermes update completed and gateway restarted!*"
