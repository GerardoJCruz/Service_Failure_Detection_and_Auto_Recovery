#!/bin/bash
#

# Add this at the top of /usr/local/sbin/monitor_nginx_webprod01.sh
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run with root privileges (use sudo)."
   exit 1
fi

  #
  # =============================================================================================================================
  # Script: monitor_nginx_webprod01.sh
  # Description: Monitoring Nginx service and trigger auto-restart when detect a failure. 
  # Strategy: Evaluate the service health based on systemd status. 
  # =============================================================================================================================
  #
  # Capture specific values info variables. 
  ACTIVE_STATE=$(systemctl show nginx -p ActiveState --value)
  SUB_STATE=$(systemctl show nginx -p SubState --value)
  LOG_FILE="/var/log/web-prod-01-nginx-monitor.log"
  EXIT_CODE=$(systemctl show nginx -p ExecMainStatus --value)
  SERVICE_PID=$(systemctl show nginx -p MainPID --value)
  FAILURE_MSG="FAILURE Detected: Nginx Services with PID: $SERVICE_PID - State: ($ACTIVE_STATE/$SUB_STATE) - Exit Code: $EXIT_CODE"
  ATTEMPT_MSG="ACTION: Restart Attempted for Nginx SERVICE with PID: $SERVICE_PID"
  ALERT_LOG="/var/log/nginx_alerts.log"
  
  # STATUS_MSG=$(systemctl show nginx -p StatusText --value)
  
# Verify Loggin File Exists. 
  log_file_verification(){
          # Ensure the log file exists and is writable
          if [ ! -f "$LOG_FILE" ]; then
                  # Try to create it if doesn't exist.
                  sudo touch "$LOG_FILE"
                  # Ensure the current user can write to it if it was created by sudo.
                  sudo chmod 664 "$LOG_FILE"
          fi
  
          # Final Safety check
          if [ ! -w "$LOG_FILE" ]; then
                  echo "Error: Cannot write to $LOG_FILE. check permissions."
                  exit 1
          fi
  }


  # Define the Logging Function
  log_event(){
          # Access the first argument ($1)
          local MESSAGE=$1
 	  sudo echo "[$(date '+%Y-%m-%d %H:%M:%S')] $MESSAGE" >> "$LOG_FILE"
  }
 
  # Aler FLag Detection (Designe to avoid auto-spamming alerts)
  # Define the Alert Function
  alert_event(){
  	# Access the first argument ($1)
	local STATE=$1
	local RESULT=$2

	# Alert message variable
	
	local ALERT_MSG="ALERT: Nginx Failure Detected | ACTION: Restart Attempt | RESULT: $RESULT | STATE: $STATE | TIME: $(date '+%Y-%m-%d %H:%M:%S')"

	# flag_file
	local FLAG_FILE="/tmp/nginx_alerts.flag"

	# Alerting Logic
	# If service is still down and we haven't alerted yet:
	if [[ "$STATE" != "active" && ! -f "$FLAG_FILE" ]]; then
		# Send Alert Message
		echo "$ALERT_MSG" >> "$ALERT_LOG"
		# Create Flag 
		touch "$FLAG_FILE" # Create the "Alert already exists" flag
	
	#If service is fixed and the flag exists (meaning it was broken before):
	elif [[ "$STATE" == "active" ]]; then
		echo "RECOVERY: Nginx is back online | TIME: $(date '+%Y-%m-%d %H:%M:%S')" >> "$ALERT_LOG"
		
		if [ -f "$FLAG_FILE" ]; then
		rm "$FLAG_FILE" # Clear the memory so we can alert agin next time it breaks
		fi 
	fi
} 

  

# Service evaluation 
  if [[ "$ACTIVE_STATE" == "active" ]]; then
          # Print Service is ok. 
          echo "Nginx Service $SERVICE_PID is Healthy."
          exit 0
  else

	# Run the function to verify Log File. 
          log_file_verification

	  # Log Failure Message 
          log_event "$FAILURE_MSG"
  
          # Print Service is not ok. 
          echo "Nginx Service $SERVICE_PID is not Healthy (State: $ACTIVE_STATE/$SUB_STATE) - Exit Code $EXIT_CODE"
  
          # Attempt Recovery
          echo "Attempting Auto-Recovery: Starting Nginx..."
          sudo systemctl restart nginx
          #Log Restart Attempt 
          log_event "$ATTEMPT_MSG"

  
          # Post-Restart Validation
          # Wait 2 seconds to let the service initialize. 
          sleep 2
  
          # Validation Variable
          FINAL_STATE=$(systemctl show nginx -p ActiveState --value)
          FINAL_CODE=$(systemctl show nginx -p ExecMainStatus --value)
          FINAL_PID=$(systemctl show nginx -p MainPID --value)
          FAIL_RESTART_MSG="RESULT: Restart Unsuccessful. Nginx Service with PID: $FINAL_PID - State: $FINAL_STATE - Exit Code: $FINAL_CODE"
          SUCCESS_RESTART_MSG="RESULT: Restart Successful. Nginx Service with PID: $FINAL_PID - State: $FINAL_STATE - Exit Code: $FINAL_CODE"
  
          if [[ "$FINAL_STATE" == "active" ]]; then
                  # Print Success Restart
                  echo "Nginx Service Successfully Restart."
                  # Log Successful Restart
                  log_event "$SUCCESS_RESTART_MSG"
 		  # Alert Event 
		  alert_event "$FINAL_STATE" "Successful" 
          else
                  # Print Service Restart Unsuccessful. 
                  echo "Nginx Restart Unsuccessful. Critical Failure detected."
                  log_event "$FAIL_RESTART_MSG"
		    
 		  # Alert Event 
		  alert_event "$FINAL_STATE" "Failed" 
                  exit 1
          fi
  fi
  

