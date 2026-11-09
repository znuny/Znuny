# Znuny Vulnerability Disclosure Policy

We take the security of our systems seriously, and we value the security community.
The disclosure of security vulnerabilities helps us ensure the security and privacy of our users.

## How to report a security vulnerability?

Please do not report security vulnerabilities through public GitHub issues,
pull requests or discussions.

If you believe you've found a security vulnerability in one of our
products or platforms please send it to us by emailing
security@znuny.com. Please include the following details with your report:

- Description of the location and potential impact of the vulnerability;
- A detailed description of the steps required to reproduce the
vulnerability (PoC scripts, screenshots, and compressed screen captures
are all helpful to us); and
- Your name/pseudonym for recognition of your contribution. If you prefer
to remain anonymous, we encourage you to submit under a pseudonym.

## Guidelines

We require that all researchers:

- Respect the rules. Operate within the rules set, or speak up if you strongly
disagree with the rules.
- Respect privacy. Make a good faith effort not to access or destroy
another user's data. Avoid degradation of user experience, disruption to
production systems, and destruction of data.
- Be patient. Make a good faith effort to help us clarify any questions
that arise. Keep information about any vulnerabilities you've
discovered confidential between yourself and Znuny until we have
resolved the issue with a public Znuny Security Advisory (see
[Disclosure timeline](#disclosure-timeline)).
- Do no harm. Act for the common good through the prompt reporting of
all found vulnerabilities. Never willfully exploit others without their
permission.
- Use the communication channel above to report vulnerability
information to us. Do not use personal emails, social media accounts, or
other private connections to contact a member of our security team in
regards to vulnerabilities or any program related issues, unless you
have been instructed to do so.

The following activities are not permitted:

- Denial of service (DoS/DDoS) attacks or load testing;
- Social engineering or phishing of Znuny employees, customers or partners;
- Physical attacks against Znuny offices, data centers or equipment;
- Sending spam or unsolicited messages;
- Automated vulnerability scanning of managed Znuny instances.

If you follow these guidelines when reporting an issue to us, we commit to:
- Not pursue or support any legal action related to your research;
- Work with you to understand and resolve the issue quickly;
- Recognize your contribution, if you are the first to report the issue
and we make a code or configuration change based on the issue.

Where applicable, we request a CVE ID and credit the reporter in the advisory.
Published security advisories are available at https://www.znuny.org/advisories.

Znuny does not offer a paid bug bounty program.

### Disclosure timeline

- We confirm the receipt of your report within 1 week of submission.
- We keep you informed about the progress of our analysis and the fix.
- We aim to release a fix and publish a Znuny Security Advisory within
60 days of your report.
- If a fix requires more time, we will contact you before the deadline and
agree on an extended timeline with you.
- We notify you when the fix is released and the advisory is published.

## Scope

- Znuny and features created or forked by Znuny
- Managed Znuny instances and any tools created or operated by Znuny

### Out of scope

Any services hosted by 3rd party providers and services are excluded
from scope. These services include instances hosted by external
parties and forks of Znuny or the ((OTRS)) Community Edition.

Add-ons (packages) that were not developed by Znuny are also out of scope.
Please report vulnerabilities in such add-ons directly to their respective
vendor or maintainer.

## Supported Versions

The following list shows Znuny versions with their support status for security updates.
Please see the [Roadmap](https://www.znuny.org/en/roadmap) for an EOL overview.

| Version | Supported          |
| ------- | ------------------ |
| 6.0     | :x:                |
| 6.1     | :x:                |
| 6.2     | :x:                |
| 6.3     | :x:                |
| 6.4     | :x:                |
| LTS 6.5 | :heavy_check_mark: |
| 7.0     | :x:                |
| 7.1     | :x:                |
| 7.2     | :x:                |
| 7.3     | :heavy_check_mark: |

Unsupported versions do not receive security fixes and contain known vulnerabilities.
Please upgrade to a supported version.
