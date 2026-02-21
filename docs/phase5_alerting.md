Phase 5 - Alerting
Goal:
Implement a simple and reliable alerting mechanism that triggers every time the script attempts a recovery. The goal is to ensure the administrator knows an incident happened, even if the service is back online.

This phase prevents "silent recoveries" that could hide instability in the server.
The Alerting Matters Because:

If Nginx fails and the script fixes it silently, we don't know the system is unstable.

The alert must confirm:

-   An incident was detected.

-   Automation took action.

-   What was the final result (Success or Failure).

What Should Trigger an Alert?

An alert must be generated every time the recovery logic runs.

-   Alert if restart succeeds.

-   Alert if restart fails.

We alert on the action, not just the failure.
Alert Design and Strategy.

To keep it reliable and native to Linux, we use a separate Alert Log.

This mechanism must be:

-   Append-only: Never delete previous alerts.

-   State-Aware: Use a "Flag File" to avoid spamming alerts if the service stays down, but ensure we log the recovery when it's fixed.

-   Immediate: Triggered right after the validation of the restart.

Example of alert structure:
```bash

ALERT: Nginx Failure Detected | ACTION: Restart Attempt | RESULT: Successful | STATE: active | TIME: 2026-02-15 15:02:11
```

Phase 5 Testing Outputs:
```bash

# Verify Nginx is running
[admin@web-prod-01 ~]$ systemctl show nginx -p ActiveState,MainPID
MainPID=9802
ActiveState=active

# Kill Service to simulate failure
[admin@web-prod-01 ~]$ sudo kill -9 9802

# Verify the Service is in failed state
[admin@web-prod-01 ~]$ systemctl show nginx -p ActiveState,MainPID
MainPID=0
ActiveState=failed

# Run the Script to trigger recovery and alerting
[admin@web-prod-01 ~]$ sudo /usr/local/sbin/monitor_nginx_webprod01.sh 
Nginx Service 0 is not Healthy (State: failed/failed) - Exit Code 9
Attempting Auto-Recovery: Starting Nginx...
Nginx Service Successfully Restart.

# Verify Nginx is active again with new PID
[admin@web-prod-01 ~]$ systemctl show nginx -p ActiveState,MainPID
MainPID=10878
ActiveState=active

# Check the Alert Log for the recovery notification
[admin@web-prod-01 ~]$ sudo cat /var/log/nginx_alerts.log 
RECOVERY: Nginx is back online | TIME: 2026-01-27 13:46:19
```

Key Considerations in Alerting

-   Why use a Flag File? To prevent the script from writing an alert every minute if the service is stuck. It "remembers" it already alerted.

-   Why log a Successful recovery? Because even if it's fixed, the admin needs to investigate why it crashed in the first place.

-   No dependencies: This works without internet or external APIs, making it 100% reliable.
