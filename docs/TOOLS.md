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

<details>
<summary><strong>Integrating Fail2ban with Cloudflare</strong></summary>


To extend Fail2ban’s protection to Cloudflare, follow these steps to automatically ban malicious IPs on Cloudlfare WAF:

**I. Set Up Cloudflare API Token**

1. Go to **Cloudflare Dashboard** → **Profile** → **API Tokens**.  
2. Create a token with the following permissions:  

   > **Account.Account WAF** – Edit    
3. Set the token to only apply to the domain you want to protect.  
4. Copy the generated **API Token**.  


**II. Configure Fail2ban**

Fail2ban includes a default **Cloudflare** action that allows it to send API requests to Cloudflare when an IP is banned.

To set it up:

1. Open the Cloudflare action configuration file:

   ```bash
   sudo nano /etc/fail2ban/action.d/cloudflare.conf
   ```
   Add your Cloudflare API Token and Cloudflare Email by updating the following fields:

   > cftoken = <YOUR_CLOUDFLARE_API_TOKEN>
     cfuser  = <YOUR_CLOUDFLARE_EMAIL>

2. Configure your Fail2ban Filter:
  
   We use the following filter to match 404 errors from our logs.

    Logs format can be different, make sure to update the filter regex accordingly!

   ```bash
   sudo nano /etc/fail2ban/filter.d/404-filter.conf
   ```
   Add the following lines:
   
   ```bash
   [Definition]
   failregex = ^<HOST> - .* "(GET|POST).*HTTP.*" 404 .*$
   ## you can add an ignore regex to ignore lines from specific IP, e.g.
   ignoreregex = ^(111\.111\.111\.111) - .* "(GET|POST).*HTTP.*" 404 .*$
   ```
4. Configure your Fail2ban Jail:

   ```bash
   sudo nano /etc/fail2ban/jail.d/404-Jail.conf
   ```
   Add the following lines, update it based on your needs:
   
   ```bash
   [404]
   enabled  = true
   port     = https, http
   filter   = 404-filter
   logpath  = /var/log/caddy/access.log
   bantime = 1440m
   findtime = 250
   maxretry = 5
   action = cloudflare
   ```

5. Restart Fail2ban:

   ```bash
   sudo systemctl restart fail2ban
   ```

**III. Useful Fail2ban Commands**

   - Test your filter regex
     
   ```bash
   sudo fail2ban-regex <log_path> /etc/fail2ban/filter.d/<filter_name>
   ```

   - Check status of specific Jail
     
   ```bash
   sudo fail2ban-client status <jail_name>
   ```

   - Unban an IP address
     
   ```bash
   sudo fail2ban-client set <jail_name> unbanip <IP_ADDRESS>
   ```

</details>

#### 4. Caddy Security
In addition to serving as a reverse proxy, forward auth, web server and wide utilities, we use Caddy's security module to protect our databases and monitoring admin dashboards by implementing GitHub Single Sign-On, allowing access exclusively for specific users.
you can use this [script](https://github.com/ankaboot-source/caddy-security.sh) (reverse proxy self-hosted supabase instance with SSO enabled only on Supabase studio) or update it based on your needs. 

#### 5. At rest Encryption
We use Ecryptfs tool to encrypt our databases filesystem at rest, luks is another option if you prefer to encrypt the whole disk.


## OS
We integrated some recommendations to harden the infrastructure security including auto system update, disabling root SSH access, disabling SSH forwarding, enable TCP-SYNcookie protection, create firewall rules to allow only necessary inbounds and outbounds, install some known system audit tools, such us Lynis, Clamav, Rkhunter, Dbsums...
most of the mentioned configurations can be done by running this [script](https://github.com/ankaboot-source/casa-webapp-guide/tree/main/security-hardening.sh):
> sudo bash security-hardening.sh

## Application

Application Security focuses on the continuous detection of vulnerabilities, such as missing security headers and other weaknesses. We perform weekly DAST (Dynamic Application Security Testing) scans using OWASP's recommended tool, ZAP Proxy, which is automated through our CI/CD pipeline.

This tool helps us identify new vulnerabilities and automatically report them by creating GitHub issues for tracking and remediation.
