# Conan Exiles Enhanced Server - Shutdown Countdown Configuration

## Overview

The Conan Exiles Enhanced Server configuration includes a custom shutdown countdown system that sends in-game warning messages to players before the server stops or restarts. Messages are sent via RCON (Remote Console) at configurable intervals.

## Features

- **Configurable Countdown Intervals**: Define when messages are sent (e.g., 30m, 15m, 5m, 1m)
- **Custom Message Format**: Customize the warning message text
- **RCON Integration**: Uses Conan Exiles native RCON to send in-game broadcasts
- **Easy Enable/Disable**: Toggle countdown on or off
- **Manual RCON Utility**: Send custom messages anytime with `rcon_send.sh`

## Setup Instructions

### 1. Enable RCON

Edit your `ceserver.cfg` (instance config file) and set:

```bash
# Enable RCON
rconenable="on"

# Set a secure RCON password (change this!)
rconpassword="your_secure_password_here"

# RCON port (default is 25575)
rconport="25575"
```

### 2. Configure Shutdown Countdown

In the same `ceserver.cfg`, set:

```bash
# Enable shutdown countdown messages
shutdowncountdown="on"

# Specify intervals in minutes (space-separated)
# Messages sent at: 30 minutes, 15 minutes, 5 minutes, 1 minute before shutdown
shutdowncountdownmessages="30 15 5 1"

# Customize the message (use {MINUTES} placeholder for countdown value)
shutdowncountdownmessageformat="Server shutting down in {MINUTES} minute(s). Please save your progress."
```

### 3. Configure Server Settings

Update your game server configuration at:
```
ConanSandbox/Saved/Config/LinuxServer/Engine.ini
```

Add RCON settings:
```ini
[RconPlugin]
RconPort=25575
RconPassword=your_secure_password_here
```

## Configuration Examples

### Example 1: Standard Countdown (30, 15, 5, 1 minutes)
```bash
shutdowncountdown="on"
shutdowncountdownmessages="30 15 5 1"
shutdowncountdownmessageformat="[SERVER] Shutdown in {MINUTES} minute(s)"
```

### Example 2: Quick Shutdown (10, 5, 1 minutes)
```bash
shutdowncountdown="on"
shutdowncountdownmessages="10 5 1"
shutdowncountdownmessageformat="Server restarting in {MINUTES} minute(s)!"
```

### Example 3: Long Maintenance (60, 30, 15, 5, 1 minutes)
```bash
shutdowncountdown="on"
shutdowncountdownmessages="60 30 15 5 1"
shutdowncountdownmessageformat="Scheduled maintenance: Server down in {MINUTES} minute(s)"
```

### Example 4: Disable Countdown
```bash
shutdowncountdown="off"
```

## Using the RCON Utility

Send manual messages to players anytime:

### Using `rcon_send.sh`:

```bash
# Navigate to your server directory
cd /home/gameserver/ceserver

# Send a simple message
./rcon_send.sh "Welcome to our server!"

# Send a warning message
./rcon_send.sh "PvP raids are enabled after 6 PM UTC"

# Send an announcement
./rcon_send.sh "New player event starting in 1 hour - join us!"
```

### Script Output:
```
[2026-05-27 15:25:30] Sending RCON command: Welcome to our server!
RCON command sent successfully
```

## Troubleshooting

### Messages Not Sending?

1. **Check RCON is enabled:**
   ```bash
   grep rconenable ceserver.cfg
   ```
   Should show: `rconenable="on"`

2. **Verify RCON password is set:**
   ```bash
   grep rconpassword ceserver.cfg
   ```
   Should NOT show: `NOT SET`

3. **Verify netcat is installed:**
   ```bash
   apt-get install netcat-openbsd
   ```

4. **Check server is running and accessible:**
   ```bash
   ss -tulpn | grep 25575  # Check if RCON port is listening
   ```

5. **Test RCON connection manually:**
   ```bash
   echo "test" | nc -w 1 localhost 25575
   ```

### Server Crashes on Shutdown?

- The countdown system is graceful and doesn't interfere with normal shutdown
- If server crashes, it's likely unrelated to the countdown system
- Check server logs: `tail -f log/console/ceserver-console.log`

### Messages Not Appearing In-Game?

1. Verify password matches in both `ceserver.cfg` and `Engine.ini`
2. Check RCON port (default 25575) matches config
3. Ensure server logs show RCON messages being sent
4. Verify admin or player has permission to see broadcasts

## Network Configuration

### Firewall Rules

RCON uses **TCP port 25575** (or custom port if changed):

```bash
# Linux firewall (UFW)
sudo ufw allow 25575/tcp

# Check if port is open
sudo ss -tulpn | grep 25575
```

### Port Forwarding (if server is behind router)

Forward TCP port 25575 to your server's internal IP (only if accessing RCON remotely).

## Security Notes

⚠️ **IMPORTANT:**
- Use a **strong, unique RCON password**
- Don't use simple passwords like "password" or "12345"
- Don't share RCON password publicly
- RCON commands from any IP can shutdown the server
- Consider restricting network access to RCON port

## Logs

Check these locations for countdown activity:

```bash
# Server console logs
log/console/ceserver-console.log

# LinuxGSM script logs
log/script/ceserver-script.log
```

Search for RCON messages:
```bash
grep -i "RCON\|countdown" log/script/ceserver-script.log
```

## Advanced: Custom Stop Script Hook

The countdown is implemented via `fix_stop.sh` which is automatically called before server stop. To customize behavior:

1. Edit: `lgsm/config-default/config-lgsm/ceserver/fix_stop.sh`
2. Modify the `fn_stop_graceful_ce_countdown()` function
3. Restart the LGSM service for changes to take effect

## References

- **Conan Exiles Official Docs**: https://www.conanexiles.com/dedicated-servers/
- **LinuxGSM Documentation**: https://docs.linuxgsm.com/
- **RCON Protocol**: Standard game server RCON via TCP

## Support

For issues or improvements:
1. Check the troubleshooting section above
2. Review server logs
3. Verify RCON settings match across all config files
4. Test RCON manually with `rcon_send.sh`
