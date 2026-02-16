# Phase 1- Baseline Validation.

## Goal:

The purpose of this phase is to generate an evaluation previous to the automation of failure detection or service recovery, collecting structured signals that automation can late read. 

The most important tool for this is systemd 

## Steps:

## 1. Confirm Nginx is running normally.

Before automating detection and recovery, is important prove that service starts cleanly, it stays in healthy state, and systemd considers it “good”. To confirm Nginx runs “normally”, we must check:

- Service state: active (running)
- Main PID exits.
- No restart loops.
- No recent failures recorded.

## 2. Understand how systemd reports service state.

Key systemd services states and what they mean.  

- active (running): Service is healthy
- inactive (dead): Service is stopped cleanly.
- failed: Service crashed or exited improperly.
- activating: Starting up.
- deactivating: Shutting down.

For Nginx, failed is a big red flag. 

## 3. Identify failure signals.

Define what counts as a failure in this environment. 

Failure signals: A  failure is any of the following:

1. Nginx service state is:
    - inactive
    - failed
2. systemd reports:
    - non-zero exit code.
    - Result=failed
3. Service is not listening on expected ports. 
    
    (Second validation, not primary)
    

Key points to consider:

- A service can be running but broken.
- systemd failure = automation trigger.

## System Evaluation:

### Confirm the Normal state:

- Command used: systemctl status nginx

```bash
# Command run
[admin@web-prod-01 ~]$ systemctl status nginx

# Output
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: disabled)
     Active: active (running) since Sun 2026-01-25 23:11:24 CST; 14h ago
 Invocation: 81...f0d
   Main PID: 936 (nginx)
      Tasks: 2 (limit: 4241)
     Memory: 8.5M (peak: 9.8M)
        CPU: 210ms
     CGroup: /system.slice/nginx.service
             ├─936 "nginx: master process /usr/sbin/nginx"
             └─937 "nginx: worker process"

Jan 25 23:11:24 web-prod-01.local systemd[1]: Starting nginx.service - The nginx HTTP and reverse proxy server...
Jan 25 23:11:24 web-prod-01.local nginx[917]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jan 25 23:11:24 web-prod-01.local nginx[917]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jan 25 23:11:24 web-prod-01.local systemd[1]: Started nginx.service - The nginx HTTP and reverse proxy server.
```

- What to look for: The ‘Active: active (running)’ line and the Main PID.

Services is healthy. 

### 2 Identify the failure signals.

Exit Codes:

- Run systemctl is-active nginx.
    - If it returns active, the exit code is 0..
    - If it returns inactive or failed, the exit code is non-zero.
- The script will use this logic: “If exit code is not 0, then start recovery.”

```bash
[admin@web-prod-01 ~]$ systemctl is-active nginx
active
```

### Failure Records (Exit Codes & Results)

Systemd keeps records of why a unit transitioned to a failed state. 

- Command: systemctl show nginx -p ActiveState,SubState,Result,Restart
- What it tell:
    - ActiveState=failed: The service is not running.
    - Result=exit-code: It crashed with an error.
    - Result=signal: Someone (or a kernel OOM killer) killed the process.
    - Restart=always: Nginx is configured to try and restart itself.

```bash
# Command Run:
[admin@web-prod-01 ~]$ systemctl show nginx -p ActiveState,SubState,Result,MainPID,Restart,RestartCount

# Output: 
Restart=no
MainPID=936
Result=success
ActiveState=active
SubState=running
[admin@web-prod-01 ~]$ 
```

### Systemd journal (journald)

Journald is the global database for all system events. It tracks everything from boot to current time. 

Command: journalctl

```bash
# Command Run:
[admin@web-prod-01 ~]$ journalctl -u nginx

# Output:
Jan 25 23:11:24 web-prod-01.local systemd[1]: Starting nginx.service - The nginx HTTP and reverse proxy server...
Jan 25 23:11:24 web-prod-01.local nginx[917]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jan 25 23:11:24 web-prod-01.local nginx[917]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jan 25 23:11:24 web-prod-01.local systemd[1]: Started nginx.service - The nginx HTTP and reverse proxy server.
```

## Phase 1 success criteria:

- Nginx start cleanly on web-prod-01.
- Identify which systemd states mean “healthy”.
- Clearly describe what a “failure” looks like.
- Recognize which signal the script will need to detect.

## Phase Conclusion:
Phase 1 successfully establish a healthy baseline for Nginx on web-prod-01 verifying an 'active (running)' state with zero previous restart failures. We have identified systemctl is-active exit codes and journald unit logs as the primary telemetry signals for our upcoming automation logic. 
