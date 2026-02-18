#!/bin/bash
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

# Service evaluation 
if [[ "$ACTIVE_STATE" == "active" ]]; then
	# Print Service is ok. 
	echo "Nginx Service is Healthy."
	exit 0
else
	# Print Service is not ok. 
	echo "Nginx Service is not Healthy (State: $ACTIVE_STATE/$SUB_STATE)."
	
	# Attempt Recovery 
	echo "Attempting Auto-Recovery: Starting Nginx..."
	sudo systemctl restart nginx

	# Post-Restart Validation
	# Wait 2 seconds to let the service initialize. 
	sleep 2

	# Validation Variable
	FINAL_STATE=$(systemctl show nginx -p ActiveState --value)
	
	if [[ "$FINAL_STATE" == "active" ]]; then
		# Print Success Restart
		echo "Nginx Service Successfully Restart."
	else 
		# Print Service Restart Unsuccessful. 
		echo "Nginx Restart Unsuccessful. Critical Failure detected."

		exit 1
	fi 
fi	

