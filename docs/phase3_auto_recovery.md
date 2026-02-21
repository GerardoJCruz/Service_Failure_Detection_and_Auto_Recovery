# Phase 3 - Auto Recovery

## Goal:

Implement a controlled and intelligent restart mechanism that attempts to recover Nginx only when a real failure is detected. 

This phase transforms the script from passive monitoring into active self-healing automation. 

## Implement Controlled Service Restart.

This Script must:

1. Detect the failure. 
2. Attempt a restart. 
3. Log the action. 

The restart must be controlled, meaning: 

- Only restart if systemd reports failure.
- Do not restart if already running.
- Do not blindly call restart every time.

Recovery should only happens when required. 

### Out of scope

This phase doesn’t include:

- Logging configuration.
- Alerting configuration.

These will be added in their corresponding coming phases. 

## Validate Restart Success.

A restart command alone means nothing. After restarting the script must: 

1. Re-Check the service state. 
2. Confirm it is now ‘active (running)’
3. Decide:
    1. Recovery Successful. 
    2. Recovery Failed. 

## Avoid Restart Loops.

Restart loop happens when: 

- Service fails
- Script restart it
- it fails again
- Script restart again and repeat forever.

### Common safe approaches.

- Limit restart attempts per execution.
- Add a cooldown window.
- Exit if restart already attempted.

## Script Logic Structure:

This is just and example of the logic of the script. It’s not the script configuration

```bash
ACTIVE_STATE=systemd_invocation

# Service evaluation 
if [ACTIVE_STATE == healthy]; then
	echo "service is healthy and end the execution of the script"
	# Exit the script 
else 
	echo "Service is considered no healthy. Initialization of restart, logging and alerting"
	# Restart the service
	# Add a coolwindow
	
	# Create a new variable to validate the new state
	FINAL_STATE=systemd_invocation
	if [FINAL_STATE == healty]; then
		echo "Service Successfully Restarted"
	else 
		echo "Nginx Restart Unsuccessful. Critical failure detected."
		# Trigger Logging
		# Trigger Alerting 
		# Exit the script
	fi 	
fi

```

### Key Considerations in Script

- What condition triggers restart? Any state where ACTIVE_STATE is not equal to active.
- How verify restart success? By catching the state into a new variable (FINAL_STATE) after the restart command and checking if it equals ‘active’.
- What happens if restart fails? The script prints a “Critical Failure” Message and exits with a non-zero code (exit 1), preventing further execution.
- Why this design cannot loop infinitely? Because the scrip performs exactly one restart attempt per execution. If the restart fails, the script exits. If cron runs it again 1 minute after later and it’s still failing, it will try again once, but won’t “machine-gun” the system with restarts.

Sometimes Service fail because of a temporary resource spike, a network glitch, or a weird kernel hiccup. 

- If the script stop after 1 try: If that one try happened during the “glitch”, the service stays down for hours until fix.
- If the script keep trying: The first try might fail, but the second try (1 minute later) might succeed. The “Self-healing” actually worked.

## Phase 3 Testing:

The services will go through this stages:

- Running State.
- Stopped State
- Killed State

During this stages the scrip will be run to try to restart the service. 

```bash
# Initial Status Verification
[admin@web-prod-01 ~]$ sudo systemctl status nginx
[sudo] password for admin: 
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: disabled)
     Active: active (running) since Mon 2026-01-26 19:34:09 CST; 2h 55min ago
 Invocation: 592f338574064df2868ff28915a34029
    Process: 7375 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 7377 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 7379 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 7380 (nginx)
      Tasks: 2 (limit: 4241)
     Memory: 2.3M (peak: 3M)
        CPU: 38ms
     CGroup: /system.slice/nginx.service
             ├─7380 "nginx: master process /usr/sbin/nginx"
             └─7381 "nginx: worker process"

Jan 26 19:34:09 web-prod-01.local systemd[1]: Starting nginx.service - The nginx HTTP and reverse proxy server...
Jan 26 19:34:09 web-prod-01.local nginx[7377]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jan 26 19:34:09 web-prod-01.local nginx[7377]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jan 26 19:34:09 web-prod-01.local systemd[1]: Started nginx.service - The nginx HTTP and reverse proxy server.

# Stop Nginx Service 
[admin@web-prod-01 ~]$ sudo systemctl stop nginx

# Verify the service was sttoped
[admin@web-prod-01 ~]$ sudo systemctl status nginx
○ nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: disabled)
     Active: inactive (dead) since Mon 2026-01-26 22:29:55 CST; 11s ago
   Duration: 2h 55min 46.210s
 Invocation: 592f338574064df2868ff28915a34029
    Process: 7375 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 7377 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 7379 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 7380 (code=exited, status=0/SUCCESS)
   Mem peak: 3M
        CPU: 39ms

Jan 26 19:34:09 web-prod-01.local systemd[1]: Starting nginx.service - The nginx HTTP and reverse proxy server...
Jan 26 19:34:09 web-prod-01.local nginx[7377]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jan 26 19:34:09 web-prod-01.local nginx[7377]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jan 26 19:34:09 web-prod-01.local systemd[1]: Started nginx.service - The nginx HTTP and reverse proxy server.
Jan 26 22:29:55 web-prod-01.local systemd[1]: Stopping nginx.service - The nginx HTTP and reverse proxy server...
Jan 26 22:29:55 web-prod-01.local systemd[1]: nginx.service: Deactivated successfully.
Jan 26 22:29:55 web-prod-01.local systemd[1]: Stopped nginx.service - The nginx HTTP and reverse proxy server.

# Run Script to restart the service
[admin@web-prod-01 ~]$ monitor_nginx_webprod01.sh 
Nginx Service is not Healthy (State: inactive/dead).
Attempting Auto-Recovery: Starting Nginx...
Nginx Service Successfully Restart.

# Verfy the service was successfully restart.
[admin@web-prod-01 ~]$ sudo systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: disabled)
     Active: active (running) since Mon 2026-01-26 22:31:46 CST; 1min 16s ago
 Invocation: 51f3885c95574f1e9358546585427df0
    Process: 7923 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 7925 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 7928 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 7929 (nginx)
      Tasks: 2 (limit: 4241)
     Memory: 2.3M (peak: 3M)
        CPU: 37ms
     CGroup: /system.slice/nginx.service
             ├─7929 "nginx: master process /usr/sbin/nginx"
             └─7930 "nginx: worker process"

Jan 26 22:31:46 web-prod-01.local systemd[1]: Starting nginx.service - The nginx HTTP and reverse proxy server...
Jan 26 22:31:46 web-prod-01.local nginx[7925]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jan 26 22:31:46 web-prod-01.local nginx[7925]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jan 26 22:31:46 web-prod-01.local systemd[1]: Started nginx.service - The nginx HTTP and reverse proxy server.

# Kill the Services
[admin@web-prod-01 ~]$ sudo kill -9 $(pgrep nginx | head -1)
[sudo] password for admin: 

# Verify the Service was Killed
[admin@web-prod-01 ~]$ sudo systemctl status nginx
× nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: disabled)
     Active: failed (Result: signal) since Mon 2026-01-26 22:39:45 CST; 11s ago
   Duration: 7min 58.835s
 Invocation: 51f3885c95574f1e9358546585427df0
    Process: 7923 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 7925 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 7928 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 7929 (code=killed, signal=KILL)
   Mem peak: 3M
        CPU: 37ms

Jan 26 22:31:46 web-prod-01.local systemd[1]: Starting nginx.service - The nginx HTTP and reverse proxy server...
Jan 26 22:31:46 web-prod-01.local nginx[7925]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jan 26 22:31:46 web-prod-01.local nginx[7925]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jan 26 22:31:46 web-prod-01.local systemd[1]: Started nginx.service - The nginx HTTP and reverse proxy server.
Jan 26 22:39:45 web-prod-01.local systemd[1]: nginx.service: Main process exited, code=killed, status=9/KILL
Jan 26 22:39:45 web-prod-01.local systemd[1]: nginx.service: Killing process 7930 (nginx) with signal SIGKILL.
Jan 26 22:39:45 web-prod-01.local systemd[1]: nginx.service: Failed with result 'signal'.

# Run the Script to Restart the Service
[admin@web-prod-01 ~]$ monitor_nginx_webprod01.sh 
Nginx Service is not Healthy (State: failed/failed).
Attempting Auto-Recovery: Starting Nginx...
Nginx Service Successfully Restart.

# Verify the services was successfully restarted.
[admin@web-prod-01 ~]$ sudo systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: disabled)
     Active: active (running) since Mon 2026-01-26 22:40:02 CST; 5s ago
 Invocation: 6b3852f49e214e6dad8a3d0dddc57293
    Process: 7975 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 7977 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 7979 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 7980 (nginx)
      Tasks: 2 (limit: 4241)
     Memory: 2.3M (peak: 3M)
        CPU: 36ms
     CGroup: /system.slice/nginx.service
             ├─7980 "nginx: master process /usr/sbin/nginx"
             └─7981 "nginx: worker process"

Jan 26 22:40:02 web-prod-01.local systemd[1]: Starting nginx.service - The nginx HTTP and reverse proxy server...
Jan 26 22:40:02 web-prod-01.local nginx[7977]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jan 26 22:40:02 web-prod-01.local nginx[7977]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jan 26 22:40:02 web-prod-01.local systemd[1]: Started nginx.service - The nginx HTTP and reverse proxy server.
```
