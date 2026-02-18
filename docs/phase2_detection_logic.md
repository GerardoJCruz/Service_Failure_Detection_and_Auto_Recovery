# Phase 2 - Detection Logic

## Goal:

Design and implement reliable logic that can accurately detect when the Nginx Service is in a failure state, using systemd to determinate this evaluation. 

Test the script to verify it can run repeatedly without causing instability or false positives. 

## Build Logic to Detect Stopped or Failed Service.

Services states:

- The services is consider healthy when the state is ‘active (running)’
- The service is consider a failure when the states is different, like ‘failed’ or ‘inactive’.

In summary, if systemd does not consider the service active, that’s the trigger for the script. 

## Script initial evaluation logic:

Key features: 

- A variable which will storage the initial state of the service.
- A if condition which will determinate if the service is healthy:
    - Print a message indicating the services is ok and exiting the script.
    - An ‘else’ where the restart, logging and alerting configuration will be place.

### Evaluation logic.

This is just and example of the logic of the script. It’s not the script configuration.  

```bash
VARAIBLE=SERVICe_STATE

if (VARIABLE == healthy); then
	echo "service is healthy and end the execution of the script"
else 
	echo "Service is considered no healthy. Initialization of restart, logging and alerting"
fi
```

## Ensure Script Runs Safely Multiple Times.

Detection script must be:

- Idempotent.
- Stateless.
- Safe to run every minute.

That means: 

- It must not modify system state
- It must not depend on previous runs.
- It must not create duplicate logs uncontrollably.
- It must not crash if the service is already stopped.

## Phase 2 Testing:

The services will go through this stages: 

1. First verification: Services must be ‘active (running)’. 
    - Services will be stop
    - Verify state changed
2. Stop Service
    - Run Script
    - Verify  output indicating the service has fail.
3. Kill Service
    - Run Script
    - Verify output indicating the service has fail.
4. Restart Service
    - Run Script last time to verify the state is active

```bash
# Give the file execution properties. 
[admin@web-prod-01 ~]$ sudo chmod +x /usr/local/sbin/monitor_nginx_webprod01.sh 
[admin@web-prod-01 ~]$ sudo ls -l /usr/local/sbin/monitor_nginx_webprod01.sh
-rwxr-xr-x. 1 root root 923 Jan 26 19:23 /usr/local/sbin/monitor_nginx_webprod01.sh

# First Verification 
[admin@web-prod-01 ~]$ monitor_nginx_webprod01.sh 
Nginx Service is Healthy.

# Stop Service and Run Script to verify output
[admin@web-prod-01 ~]$ sudo systemctl stop nginx 
[admin@web-prod-01 ~]$ monitor_nginx_webprod01.sh 
Nginx Service is not Healthy.

# Restart Service
[admin@web-prod-01 ~]$ sudo systemctl start nginx 
[admin@web-prod-01 ~]$ monitor_nginx_webprod01.sh 
Nginx Service is Healthy.

# Kill Service and Run Script to verify output
[admin@web-prod-01 ~]$ sudo kill -9 $(pgrep nginx | head -1)
[admin@web-prod-01 ~]$ monitor_nginx_webprod01.sh 
Nginx Service is not Healthy.

# Restart Nginx Service and Run Script Las Time 
[admin@web-prod-01 ~]$ sudo systemctl start nginx 
[admin@web-prod-01 ~]$ monitor_nginx_webprod01.sh 
Nginx Service is Healthy.
[admin@web-prod-01 ~]$ 
```
