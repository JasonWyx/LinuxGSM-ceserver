#!/bin/bash
# LinuxGSM fix_stop.sh module for Conan Exiles
# Provides graceful shutdown with countdown warning messages via RCON
# Usage: Automatically called before server stop if enabled
# Description: Sends configurable countdown warnings to players before shutdown

moduleselfname="$(basename "$(readlink -f "${BASH_SOURCE[0]}")")"

# Function to send RCON command to Conan Exiles server
fn_send_rcon_command() {
	local message="${1}"
	
	if [ -z "${rconpassword}" ] || [ "${rconpassword}" == "NOT SET" ]; then
		fn_print_warn "RCON: Password not set, skipping countdown message"
		fn_script_log_warn "RCON: Password not set, skipping countdown message"
		return 1
	fi
	
	if [ "${rconenable}" != "on" ]; then
		fn_print_info_nl "RCON: Disabled - enable in config to send countdown messages"
		return 1
	fi
	
	# Use nc (netcat) to send RCON command to the server
	# Conan Exiles RCON format: RCON command via TCP
	if command -v nc &> /dev/null; then
		echo -e "RCON\x00${rconpassword}\x00broadcast ${message}" | nc -w 1 localhost "${rconport}" > /dev/null 2>&1
		fn_print_dots "RCON: Sent countdown message"
		fn_script_log_info "RCON: Countdown message: ${message}"
		return 0
	else
		fn_print_warn "RCON: netcat not installed, countdown messages disabled"
		fn_script_log_warn "RCON: netcat not installed, countdown messages disabled"
		return 1
	fi
}

# Function to handle graceful shutdown with countdown warnings
fn_stop_graceful_ce_countdown() {
	# Check if countdown is enabled
	if [ "${shutdowncountdown}" != "on" ]; then
		return 0
	fi
	
	fn_print_heading "Conan Exiles Graceful Shutdown with Countdown"
	fn_script_log_info "Starting graceful shutdown countdown"
	
	# Parse shutdown countdown messages (space-separated minutes)
	if [ -z "${shutdowncountdownmessages}" ]; then
		fn_print_warn "Shutdown countdown: No intervals configured"
		return 0
	fi
	
	# Convert messages to array
	read -ra countdown_array <<< "${shutdowncountdownmessages}"
	
	if [ ${#countdown_array[@]} -eq 0 ]; then
		fn_print_warn "Shutdown countdown: Invalid message format"
		return 0
	fi
	
	# Calculate total wait time in seconds (largest interval)
	total_seconds=0
	for minutes in "${countdown_array[@]}"; do
		if [[ "$minutes" =~ ^[0-9]+$ ]]; then
			total_seconds=$((minutes * 60))
			break
		fi
	done
	
	if [ $total_seconds -eq 0 ]; then
		fn_print_warn "Shutdown countdown: No valid intervals"
		return 0
	fi
	
	fn_print_info_nl "Countdown enabled: sending messages at intervals"
	fn_print_info_nl "Total countdown time: $((total_seconds / 60)) minutes"
	
	# Track elapsed time and send messages
	local elapsed=0
	local last_message_time=0
	
	while [ $elapsed -lt $total_seconds ]; do
		# Check each countdown interval
		for minutes in "${countdown_array[@]}"; do
			if [[ ! "$minutes" =~ ^[0-9]+$ ]]; then
				continue
			fi
			
			local seconds_until=$((minutes * 60))
			local remaining_seconds=$((total_seconds - elapsed))
			
			# If we've reached this interval, send message
			if [ $remaining_seconds -le $seconds_until ] && [ $remaining_seconds -gt $((seconds_until - 60)) ]; then
				if [ $remaining_seconds -ne $last_message_time ]; then
					local message="${shutdowncountdownmessageformat//\{MINUTES\}/$minutes}"
					fn_print_info_nl "Countdown: Sending message for $minutes minute(s)"
					fn_send_rcon_command "${message}"
					last_message_time=$remaining_seconds
				fi
			fi
		done
		
		# Sleep for 10 seconds before checking again
		sleep 10
		elapsed=$((elapsed + 10))
	done
	
	fn_print_ok "Graceful shutdown countdown completed"
	fn_script_log_pass "Graceful shutdown countdown completed"
}

# Export functions so they can be called from main stop module
export -f fn_send_rcon_command
export -f fn_stop_graceful_ce_countdown
