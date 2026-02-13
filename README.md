# Service Failure Detection + Auto-Recovery (Nginx)

## Project Goals:
- Detect Nginx service failure on web-prod-01.
- Automatically restore the service.
- Log the incident in a dedicated log file. 
- Trigger an administrator alert. 
- Validate behavior through controlled failure testing. 

## Project Justification:
In real-world environments:
- Services will fail
- Manual restarts don't scale
- Teams want: 
	- Fast Recovery
	- Visibility
	- Proof it happened. 

## Scope & Context
In Scope:
- web-prod-01
- Nginx service
- Systemd
- Bash scripting
- Cron Jobs
- Logging and alerts.

Out of scope:
- Enternal monitoring tools.
- Containers. 
- Load balancers. 

## Naming Convenctions
Scripts:
- Location: 
	/usr/local/sbin/
- Scrip name:
	monitor_nginx_webprod01.sh

Logs:
- Log file:
	/var/log/web_prod_01_nginx_monitor.log

Alerts:
- Method:
	- Local log entry and/or
	- Email notification (simple MTA).

Cron: 
- Cron File:
	/etc/cron.d/webprod01_nginx_monitor

## Project Resume:
Implement an automated monitoring solution for a production web server. Ths system detects when Nginx stops, restarts it automatically, logs the incident for auditing, and sends an alert so administrators can be alerted.

![Project_Diagram](/images_and_diagrams/service_failure_detection.png)
