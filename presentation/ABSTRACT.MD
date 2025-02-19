## Abstract

Google requested that our web application get approved for Cloud Application Security Assessment after we asked for access to their IMAP server. 
We initially thought we were secure by design, thanks to our firewall rules, Fail2ban for DDoS prevention, regular pentesting, and following security best practices in our base code. Of course, protecting our user's data is our top priority! However, we were far from knowing that a CASA assessment involves complying with over 60 (yes, 60!) different rules.  Some of them were a real challenge. 
In this talk, we’ll share the story of how we nailed it in just a few weeks, along with some tips and tricks to help you succeed with your own CASA certification.

## Steps of the talk
1. Secure by Design? Think Again.
   - The moment Google dropped the CASA Tier 2 requirement: Why IMAP access triggered a deeper audit.

2. The CASA Wake-Up Call
   - A breakdown of the 3 categories that shocked us most:
         - Wait, that’s a requirement?
         - We thought this was covered!
         - How do we even test this?

3. Sprinting Through the verification process
   - Triage Mode: How we prioritized rules into "Easy Wins," "Team Sprints," and "Mission-Critical" challenges.

4. Lessons Beyond Compliance
   - Surprising wins: How CASA uncovered hidden risks

5.  Strategies for CASA Certification   

## Github repo
A collection of guides and resources to help teams navigate the CASA assessment process.
[CASA Web App Guide](https://github.com/ankaboot-source/casa-webapp-guide)
