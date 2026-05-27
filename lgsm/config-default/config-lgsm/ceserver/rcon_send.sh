#!/bin/bash
# LinuxGSM Conan Exiles RCON utility
# Send commands to Conan Exiles server via RCON
# Usage: ./rcon_send.sh "command text"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the server config if available
if [ -f "${SCRIPT_DIR}/ceserver.cfg" ]; then
	source "${SCRIPT_DIR}/ceserver.cfg"
elif [ -f "${SCRIPT_DIR}/../ceserver.cfg" ]; then
	source "${SCRIPT_DIR}/../ceserver.cfg"
else
	echo "Error: Could not find ceserver.cfg"
	exit 1
fi

# Verify RCON settings
if [ -z "${rconpassword}" ] || [ "${rconpassword}" == "NOT SET" ]; then
	echo "Error: RCON password not configured. Set rconpassword in ceserver.cfg"
	exit 1
fi

if [ -z "${rconport}" ]; then
	rconport="25575"
fi

if [ -z "${1}" ]; then
	echo "Usage: $0 \"command\""
	echo "Example: $0 \"Server will restart in 5 minutes\""
	exit 1
fi

COMMAND="${1}"

# Send RCON command via netcat
if command -v nc &> /dev/null; then
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sending RCON command: ${COMMAND}"
	echo -e "RCON\x00${rconpassword}\x00broadcast ${COMMAND}" | nc -w 2 localhost "${rconport}"
	if [ $? -eq 0 ]; then
		echo "RCON command sent successfully"
		exit 0
	else
		echo "Error: Failed to send RCON command"
		exit 1
	fi
else
	echo "Error: netcat (nc) is not installed. Install it with: apt-get install netcat-openbsd"
	exit 1
fi
