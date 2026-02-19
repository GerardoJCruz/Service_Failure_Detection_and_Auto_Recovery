# Phase 4 - Logging

## Goal:

Implement structured, append-only logging that records every detection and recovery even with enough detail to support auditing, troubleshooting, and post-incident analysis - without overwriting or corrupting previous logs. 

## The Logging Matters Because:

If the restart Nginx silently, it creates invisible automation - and invisible automation is dangerous. 

The log must answer:

- When was the failure detected?
- What was the service state?
- Did script attempt recovery?
- Did recovery succeed or fail?

## What Must Be Logged?

Each execution that detects a failure must log: 

- Timestamp (precise and consistent format).
- Failure detected.
- Action taken (restart attempted).
- Result (success or failure).

Example: 

```bash
[2026-02-15 14:22:01] FAILURE detected: nginx inactive
[2026-02-15 14:22:01] ACTION: restart attempted
[2026-02-15 14:22:02] RESULT: restart successful
```

Clarity > Cleverness. 

## Append-Only Requirements.

This is critical

Logging must:

- Never overwrite previous entries.
- Never truncate the file.
- Never erase history.

That means: 

- Always append new logs.
- Never redirect with overwrite.
- Never recreate the log file blindly.

If the script runs 100 times, the log grows 100 entries. 

## Design Considerations

Logging must be:

- Deterministic (same format every time).
- Atomic (each entry complete).
- Safe to run from cron.
- Not dependent on previous runs.

## Phase 4 Testing Outputs:

```bash
# Verify log file doesn't exist yet using ls
[admin@web-prod-01 ~]$ sudo ls /var/log/
anaconda  chrony	 dnf.librepo.log  exim		hawkey.log	     maillog	       messages-20260125  samba		   spooler	     wtmp
audit	  cron		 dnf.log	  fail2ban.log	hawkey.log-20260125  maillog-20260125  nginx		  secure	   spooler-20260125
btmp	  cron-20260125  dnf.rpm.log	  firewalld	lastlog		     messages	       private		  secure-20260125  sssd

# Get Nginx ActiveState and MainPID
[admin@web-prod-01 ~]$ sudo systemctl show nginx -p ActiveState,MainPID 
MainPID=9602
ActiveState=active

# Kill Service using the PID
[admin@web-prod-01 ~]$ sudo kill -9 9602

# Verify the Service Failed
[admin@web-prod-01 ~]$ sudo systemctl show nginx -p ActiveState,MainPID 
MainPID=0
ActiveState=failed

# Run Script
[admin@web-prod-01 ~]$ sudo /usr/local/sbin/monitor_nginx_webprod01.sh 
Nginx Service 0 is not Healthy (State: failed/failed) - Exit Code 9
Attempting Auto-Recovery: Starting Nginx...
Nginx Service Successfully Restart.

# Verify Nginx Service Recover and has a new PID
[admin@web-prod-01 ~]$ sudo systemctl show nginx -p ActiveState,MainPID 
MainPID=9802
ActiveState=active

# Verify Log File was created
[admin@web-prod-01 ~]$ sudo ls /var/log/
anaconda  chrony	 dnf.librepo.log  exim		hawkey.log	     maillog	       messages-20260125  samba		   spooler	     web-prod-01-nginx-monitor.log
audit	  cron		 dnf.log	  fail2ban.log	hawkey.log-20260125  maillog-20260125  nginx		  secure	   spooler-20260125  wtmp
btmp	  cron-20260125  dnf.rpm.log	  firewalld	lastlog		     messages	       private		  secure-20260125  sssd

# Analize the logs store in the Log File. 
[admin@web-prod-01 ~]$ sudo cat /var/log/web-prod-01-nginx-monitor.log 
[2026-01-27 07:34:18] FAILURE Detected: Nginx Services PID 0 State (failed/failed) - Exit Code 9
[2026-01-27 07:34:18] ACTION: Restart Attempted for Nginx SERVICE PID 0
[2026-01-27 07:34:20] RESULT: Restart Successful. Service PID 9802 State active - Exit Code 0
[admin@web-prod-01 ~]$ 
```

.
