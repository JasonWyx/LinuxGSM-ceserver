# Conan Exiles Enhanced Server - Shutdown Countdown Implementation

## Summary

A complete custom shutdown countdown system has been created for the Conan Exiles Enhanced Server. Players receive configurable in-game warning messages before the server stops or restarts.

## Files Created

### 1. `_default.cfg` (Updated)
Core configuration file with new countdown settings:
```bash
shutdowncountdown="off"                    # Enable/disable countdown
shutdowncountdownmessages="30 15 5 1"     # Intervals in minutes
shutdowncountdownmessageformat="..."      # Message template with {MINUTES} placeholder
rconenable="off"                           # Enable/disable RCON
rconpassword="NOT SET"                     # RCON authentication
rconport="25575"                           # RCON TCP port
```

### 2. `fix_stop.sh` 
Custom graceful stop script with countdown logic:
- Reads countdown configuration from ceserver.cfg
- Sends RCON broadcast messages at specified intervals
- Integrates with LinuxGSM's graceful shutdown system
- Supports custom message formatting

**Key Functions:**
- `fn_send_rcon_command()` - Sends RCON commands via netcat
- `fn_stop_graceful_ce_countdown()` - Main countdown logic

### 3. `rcon_send.sh`
Standalone utility for manual RCON messages:
- Send messages anytime (not just at shutdown)
- Simple command-line interface
- Useful for announcements, events, warnings
- Can be called from cron jobs or scripts

### 4. `SHUTDOWN_COUNTDOWN_GUIDE.md`
Complete user documentation:
- Setup instructions
- Configuration examples
- Troubleshooting guide
- Security recommendations
- RCON protocol details

## How It Works

### Countdown Flow

```
TIME: -30m → RCON sends: "Server restarting in 30 minute(s)"
TIME: -15m → RCON sends: "Server restarting in 15 minute(s)"
TIME: -5m  → RCON sends: "Server restarting in 5 minute(s)"
TIME: -1m  → RCON sends: "Server restarting in 1 minute(s)"
TIME: 0    → Server performs graceful shutdown
```

### Technical Flow

1. User runs: `./ceserver stop`
2. LinuxGSM calls `fix_stop.sh` before shutdown
3. Script checks if `shutdowncountdown="on"`
4. Reads `shutdowncountdownmessages` intervals (e.g., "30 15 5 1")
5. Calculates wait time from first interval (30 minutes)
6. Loops through remaining time, checking each interval
7. When interval matches remaining time, sends RCON message
8. Uses netcat to send message to RCON port 25575
9. After countdown completes, server shuts down gracefully

## Configuration

### Minimal Setup (in ceserver.cfg)

```bash
# Enable RCON
rconenable="on"
rconpassword="YourSecurePassword"

# Enable countdown with default intervals
shutdowncountdown="on"
```

### Full Configuration (in ceserver.cfg)

```bash
# RCON Settings
rconenable="on"
rconpassword="MySecurePassword123"
rconport="25575"

# Shutdown Countdown
shutdowncountdown="on"
shutdowncountdownmessages="30 15 5 1"
shutdowncountdownmessageformat="[ALERT] Server restarting in {MINUTES} minute(s)!"
```

## Usage Examples

### Example 1: Enable Default Countdown
```bash
shutdowncountdown="on"
shutdowncountdownmessages="30 15 5 1"
```
→ Messages at 30m, 15m, 5m, 1m

### Example 2: Quick Maintenance Window
```bash
shutdowncountdown="on"
shutdowncountdownmessages="5 1"
shutdowncountdownmessageformat="Server down for maintenance in {MINUTES} minute(s)"
```
→ Messages at 5m, 1m only

### Example 3: Long Scheduled Shutdown
```bash
shutdowncountdown="on"
shutdowncountdownmessages="60 30 15 5"
shutdowncountdownmessageformat="Planned shutdown in {MINUTES} minute(s)"
```
→ Messages at 60m, 30m, 15m, 5m

### Example 4: Disable Countdown
```bash
shutdowncountdown="off"
```
→ No countdown messages, normal shutdown

## Manual RCON Commands

Send messages anytime with `rcon_send.sh`:

```bash
# Navigate to server directory
cd /home/gameserver/ceserver

# Send announcement
./rcon_send.sh "Welcome to our Conan Exiles server!"

# Event notification
./rcon_send.sh "PvP event starting at 20:00 UTC"

# Urgent warning
./rcon_send.sh "Server restart in 15 minutes - please save!"

# Server info
./rcon_send.sh "Visit our Discord: discord.gg/yourserver"
```

## Requirements

### Software
- bash shell
- netcat (netcat-openbsd): `apt-get install netcat-openbsd`
- nc command available in PATH

### Server Configuration
- RCON enabled in Conan Exiles Engine.ini
- RCON password configured and matching
- RCON port (25575/tcp) accessible locally

### Network
- TCP port 25575 must be open on server (RCON port)
- No firewall blocking localhost:25575

## Troubleshooting

### Messages Not Sending
1. Verify `rconenable="on"` in config
2. Verify `rconpassword` is NOT "NOT SET"
3. Check netcat installed: `which nc`
4. Test RCON: `echo test | nc -w 1 localhost 25575`
5. Check server logs: `tail log/script/ceserver-script.log`

### Netcat Not Installed
```bash
sudo apt-get update
sudo apt-get install netcat-openbsd
```

### Countdown Doesn't Start
1. Verify server is running: `./ceserver status`
2. Check config file: `cat ceserver.cfg | grep shutdown`
3. Ensure `shutdowncountdown="on"`
4. Check message format has `{MINUTES}` placeholder

### Server Won't Stop
- The countdown doesn't interfere with shutdown
- Use `./ceserver stop --force` if needed
- Check server logs for errors

## Security Notes

⚠️ **Important Security Considerations:**

1. **RCON Password**: Use strong, random password
   ```bash
   # Generate secure password
   openssl rand -base64 16
   ```

2. **Access Control**: Keep RCON port local only
   - Don't expose RCON to internet
   - Only configure if needed

3. **Log Sensitive Data**: RCON commands appear in logs
   - Review logs regularly
   - Don't log passwords

4. **Script Permissions**: Secure the scripts
   ```bash
   chmod 700 fix_stop.sh rcon_send.sh
   ```

## Integration with LinuxGSM

The countdown system integrates seamlessly:

- Runs before standard graceful shutdown
- Respects existing stop modes
- Compatible with auto-restart features
- Works with monitoring/alerts
- Logs to standard LinuxGSM locations

## Performance Impact

- Negligible CPU usage (checking intervals every 10 seconds)
- No network overhead outside of RCON messages
- No impact on server performance
- Shutdown wait time = largest countdown interval

**Example Wait Time:**
- With `"30 15 5 1"` → waits ~30 minutes before shutdown
- With `"5 1"` → waits ~5 minutes before shutdown

## Advanced: Custom Message Variables

Currently supported:
- `{MINUTES}` - Countdown value in minutes

Future possible additions:
- `{SECONDS}` - Time in seconds
- `{SERVERNAME}` - Server name
- `{DATETIME}` - Current date/time
- `{REASON}` - Shutdown reason

## References

- **Conan Exiles Docs**: https://www.conanexiles.com/dedicated-servers/
- **RCON Protocol**: Standard TCP-based game server remote console
- **LinuxGSM**: https://docs.linuxgsm.com/

## Support & Customization

To customize further:

1. Edit `fix_stop.sh` for different countdown logic
2. Modify `rcon_send.sh` for different RCON format
3. Update message format with custom text
4. Extend with additional variables

All files are in: `lgsm/config-default/config-lgsm/ceserver/`
