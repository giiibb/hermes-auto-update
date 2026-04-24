#!/bin/bash

echo "🚀 Installing Hermes Auto-Update..."

# 1. Create scripts directory
mkdir -p ~/.hermes/scripts

# 2. Copy the update script
cp auto_update.sh ~/.hermes/scripts/auto_update.sh
chmod +x ~/.hermes/scripts/auto_update.sh

# 3. Setup Cronjob (Every day at 4 AM)
crontab -l > /tmp/current_cron 2>/dev/null || true
if ! grep -q "auto_update.sh" /tmp/current_cron; then
    echo "0 4 * * * /bin/bash $HOME/.hermes/scripts/auto_update.sh >> /tmp/hermes_auto_update.log 2>&1" >> /tmp/current_cron
    crontab /tmp/current_cron
    echo "✅ Cron job added: Checks for updates will run every day at 4:00 AM."
else
    echo "✅ Cron job already exists. (Note: check 'crontab -e' to ensure it is daily '0 4 * * *')"
fi
rm -f /tmp/current_cron

echo "🎉 Installation complete!"
echo "Check README.md on how to teach Hermes to postpone updates on command."
