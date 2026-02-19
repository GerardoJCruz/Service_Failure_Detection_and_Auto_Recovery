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
  
          else
                  # Print Service Restart Unsuccessful. 
                  echo "Nginx Restart Unsuccessful. Critical Failure detected."
                  log_event "$FAIL_RESTART_MSG"
  
                  exit 1
          fi
  fi
  


