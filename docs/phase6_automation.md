Phase 5 - Automation

## Goal:

Configure automatic, scheduled execution of your monitoring and recovery script, ensuring it runs with the correct permissions and executes reliably without manual intervention. 

## 1. Schedule Script Execution.

The scheduling decision should answer: 

- How often should detection run?
- What’s the acceptable recovery delay?
- Is the interval reasonable for production?

In production, every second of downtime is lost revenue or a bad user experience, so a 1-minute interval is the professional choice for a critical web server. 

The scheduler must call the script directly and consistently. 

No interactive dependencies. 

No environment assumptions. 

## 2. Ensure Correct Permissions.

The script must:

- Be executable.
- Be owned appropriately.
- Have correct permissions.
- Be readable/executable by the scheduler user.

Many scripts “work manually” and fail under cron because:

- PATH  is missing.
- Permissions are wrong.
- Relative

Production rule: If cron runs it, it must work with minimal environment context. 

### Permissions & Ownership.

Since the script manages a system service (Nginx) and writes to /var/log, it must run as root.

1. Set Ownership: sudo chown root:root /usr/local/sbin/monitor_nginx_webprod01.sh
2. Set Permissions: sudo chmod 700 /usr/local/sbin/monitor_nginx_webprod01.sh

## Commands PATH Variable

Adding shortcut which allows the script where to look for any command use in the script. 

Why the shortcut is useful?

- Readability:  The code stays clean and easy to read (e.g., systemctl isntead of /usr/bin/systemctl).
- Portability: If the script is moved to a different Linux version where a command lives in /bin/ instead of /usr/bin/, the PATH variable handles it automatically.
- Safety: It ensures that every command in the script - not just the ones changed - is found by cron.

How to add the PATH Variable?

```bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

## Scheduling With Cron:

Use the Root Crontab so the script has the authority to restart Nginx and write to protected logs. 

1. Open the crontab: sudo crontab -e
2. Add the following line (to run every minute):

```bash
* * * * * /usr/local/sbin/monitori_nginx_webprod01.sh > /dev/null 2>&1
```

Note; the output is sent to /dev/null because the script already handles its own logging in /var/log/web-prod-01-nginx-monitor.log and /var/log/nginx_alerts.log

Verify Cron Execution. 

- The cron job is registered correctly.
- It executes at the expected interval.
- It produces logs.
- It performs recovery if failure occurs.
- I does not silently fail.

First Terminal: Trigger the logging. 

```bash
# Set and verify the right permissions. 
[admin@web-prod-01 ~]$ sudo chmod 700 /usr/local/sbin/monitor_nginx_webprod01.sh
[admin@web-prod-01 ~]$ sudo ls -l /usr/local/sbin/monitor_nginx_webprod01.sh
-rwx------. 1 root root 5201 Jan 27 14:08 /usr/local/sbin/monitor_nginx_webprod01.sh

# Edit crontab to generate evaluation every minute
[admin@web-prod-01 ~]$ sudo crontab -e
no crontab for root - using an empty one
crontab: installing new crontab
[admin@web-prod-01 ~]$ sudo crontab -e
[sudo] password for admin:
crontab: installing new crontab
Backup of root's previous crontab saved to /root/.cache/crontab/crontab.bak

# Stop the Nginx service
[admin@web-prod-01 ~]$ sudo systemctl stop nginx
[admin@web-prod-01 ~]$ sudo systemctl show nginx -p ActiveState,MainPID
MainPID=11342
ActiveState=active

# Kill the Nginx service. 
[admin@web-prod-01 ~]$ sudo kill -9 11342
[admin@web-prod-01 ~]$
```

Second terminal: Logging monitoring. 

This terminal is mainly to monitor and guarantee the logs creation. 

```bash
# It repors the logging in real time. 
[admin@web-prod-01 ~]$ tail -f /var/log/nginx_alerts.log
RECOVERY: Nginx is back online | TIME: 2026-01-27 13:46:19
RECOVERY: Nginx is back online | TIME: 2026-01-27 14:37:03
RECOVERY: Nginx is back online | TIME: 2026-01-27 14:39:04

# Check whi s the crond is logging the incidents. 
[admin@web-prod-01 ~]$ sudo grep crond /var/log/cron | tail -n 20
[sudo] password for admin:
Jan 27 14:35:01 web-pro
```

.
