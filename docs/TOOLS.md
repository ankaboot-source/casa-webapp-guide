# Security Hardening tools
We have implemented a multi-layered approach to enhance the security of both our infrastructure and application. These measures are designed to safeguard against unauthorized access, cyber threats, and potential vulnerabilities.

## Infrastructure
Infrastructure security focuses on protecting our servers, instances, and admin dashboards from unauthorized access and known attacks such as SYN flood DDoS attacks, brute force attempts, and more. To achieve this, we have employed a combination of robust tools and strategies, including:

- **Firewalls** to filter and control incoming and outgoing traffic.
- **Cloudflare** for DDoS protection, traffic routing, and enhanced security.
- **Fail2Ban** integrated with Cloudflare to detect and block malicious login attempts in real-time.
- **Caddy Security** to automate HTTPS encryption and secure admin dashboards with Single Sign-On (SSO) authentication to specific users.

#### 1. Firewalls
To protect our running services and instances from unauthorized access, we have implemented custom firewall rules on DigitalOcean


#### 2. Cloudflare
We use Cloudflare to protect our servers by routing traffic through their secure proxies, shielding them from known attacks.

#### 3. Fail2ban + Cloudflare
Fail2ban is an Intrusion Detection/Prevention System, we use it to detect in real-time any DDOS attack on application side, protect from SSH Bruteforce, and enhance our mail server security by monitoring Postfix and dovecot logs from any suspecious activities.

Combined with Cloudflare, Fail2ban will ban malicious IPs on server level and on Cloudflare by creating WAF rules blocking the Specific IP.


#### 4. Caddy Security
In addition to serving as a reverse proxy, forward auth, web server and wide utilities, we use Caddy's security module to protect our databases and monitoring admin dashboards by implementing GitHub Single Sign-On, allowing access exclusively for specific users.


#### 5. At rest Encryption
We use Ecryptfs tool to encrypt our databases filesystem at rest, luks is another option if you prefer to encrypt the whole disk.


## OS
We integrated some recommendations to harden the infrastructure security including auto system update, disabling root SSH access, disabling SSH forwarding, enable TCP-SYNcookie protection, create firewall rules to allow only necessary inbounds and outbounds, install some known system audit tools, such us Lynis, Clamav, Rkhunter, Dbsums...
most of the mentioned configurations can be done by running this [script](https://github.com/ankaboot-source/casa-webapp-guide/tree/main/security-hardening.sh):
> sudo bash security-hardening.sh

## Application

Application Security focuses on the continuous detection of vulnerabilities, such as missing security headers and other weaknesses. We perform weekly DAST (Dynamic Application Security Testing) scans using OWASP's recommended tool, ZAP Proxy, which is automated through our CI/CD pipeline.

This tool helps us identify new vulnerabilities and automatically report them by creating GitHub issues for tracking and remediation.
