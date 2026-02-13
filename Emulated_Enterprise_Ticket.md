Incident / Serice Request
Ticket ID: OPS-2025-0213
Priority: High
Affected System: web-prod-01
Service: Nginx (HTTP/HTTPS)

Issue Summary: Intemittent outages have been reported on the production web service. Initial investigation suggest the Nginx service occasionally stops unexpectedly. 

Business Impact: 
Service downtime impacts external users and reduces confidence in platform reliability. 

Request: 
- "Implement automated detection of service failure"
- "Automatically restore service availability"
- "Log incidents for auditing and troubleshooting"
- "Notify adminstrators when recovery actions occur"

Constraints:
- "No additional monitoring platforms approved"
- "Solution must use native Linux tools"
- "Must be simple, auditable, and maintainable"
