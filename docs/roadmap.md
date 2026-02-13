# Service Failure Detection + Auto-Recovery - Roadmap.

# Phase 1- Baseline Validation
- Confirm Nginx is running normally.
- Understand how systemd reports service state. 
- Identify failure signals. 

# Phase 2 - Detection Logic
- Define what "failure" means.
- Build logic to detect stopped or failed service.
- Ensure script runs safely multiple times.

# Phase 3 - Auto-Recovery
- Implement controlled service restart.
- Validate restart success. 
- Avoid restart loops. 

# Phase 4 - Logging
- Log: 
	- Timesatmp
	- Detected failure
	- Recovery action
	- Result
- Ensure logs are append-only. 

# Phase 5 - Alerting
- Trigger alert when: 
	- Recovery action occurs
- Keep alert simple and reliable. 

# Phase 6 - Automation
- Schedule script execution. 
- Ensure correct permissions. 
- Verify cron execution. 

# Phase 7 - Failure Testing
- Stop Nginx manually.
- Observe detection.
- Confirm restart.
- Confirm log entry.
- Confirm alert.
- Reboot system and retest


