---
name: postpone-update
description: Cancels or postpones the automated VPS Hermes update.
trigger: When the user asks to "postpone the update", "cancel the update", etc., usually after receiving the 1-minute warning.
---

# Cancelling the Automated Update

A cron script runs daily to automatically update Hermes. It warns the user 60 seconds before executing the update.
If the user asks you to postpone or cancel this update, you MUST execute the following command to create the flag file that tells the script to abort:

```bash
touch /tmp/hermes_update_postponed
```

After executing the command, reply to the user to confirm that the update has been successfully blocked/postponed.
