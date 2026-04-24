# Hermes Auto-Update Script

An automated weekly update script for your [Hermes Agent](https://github.com/giiibb/hermes-agent) running on a VPS. It notifies you via Telegram 1 minute before updating and gives you a chance to postpone the update if you are actively using the agent.

## Features
- 🔄 **Daily Update Checks:** Runs every day at 4:00 AM. Exits silently if no update is needed.
- 📱 **Telegram Notifications:** Tells you when it's about to update, when it's done, and if it was postponed.
- 🛑 **Postpone Mechanism:** Cancel the update cleanly via a simple Telegram message to Hermes.
- 🛡️ **Failsafe:** Re-installs `python-dotenv` explicitly to prevent gateway restart bugs.

## Installation

1. Clone this repository on your VPS:
   ```bash
   git clone https://github.com/giiibb/hermes-auto-update.git
   cd hermes-auto-update
   ```
2. Run the install script:
   ```bash
   ./install.sh
   ```

## Teaching Hermes to Postpone Updates

The script looks for a flag file (`/tmp/hermes_update_postponed`) to abort the update. You need to teach your Hermes agent to create this file when you ask it to postpone.

Copy the `SKILL.md` provided in this repository and ask Hermes to add it to its skills, or tell Hermes directly:

> *"Hermes, create a skill: When I say 'Postpone update', execute `touch /tmp/hermes_update_postponed` in the terminal and confirm the update is cancelled."*

## How it works

1. At 4:00 AM every day, the script triggers and silently checks for updates.
2. It sends a message to your `TELEGRAM_HOME_CHANNEL`.
3. It waits for 60 seconds.
4. If you tell Hermes to postpone (which creates the flag file), the script sees the file, sends an abort message, and stops.
5. If you do nothing, the script stops the gateway, runs `hermes update`, restarts the gateway, and notifies you of success.
