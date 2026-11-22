# Znuny Vulnerability Disclosure Policy

We take the security of our systems seriously, and we value the security community.
The disclosure of security vulnerabilities helps us ensure the security and privacy of our users.

## How to report a security vulnerability?

Please do not report security vulnerabilities through public GitHub issues,
pull requests or discussions.

If you believe you've found a security vulnerability in one of our
products or platforms please send it to us by emailing security@znuny.com.

Keep the report short and factual. The required format is below, and we
ask you to follow it exactly.

### Required report format

Send plain text or Markdown, in this structure, and no additional sections:

1. **Title** — one line.
2. **Affected version** — the exact version you tested, as shown in the
`RELEASE` file of your installation (for example `7.5.1`), plus the Git
commit if you tested a checkout. State whether you tested a default
installation or a modified one, and list any add-on packages involved.
3. **Component** — the affected file path(s) and, where you know it, the
subroutine or line, or the URL and parameter.
4. **Issue** — what the flaw is, in no more than five sentences.
5. **Reproduction** — numbered steps from a fresh default installation to
the observable result, including the exact request, payload or input used,
the account and permissions required, and what you observed. A short PoC
script, screenshot or screen capture is welcome as an attachment.
6. **Impact** — one or two sentences: who can do what to whom, and what
privileges they need beforehand.
7. **Reporter** — the name or pseudonym you want in the advisory, or a note
that you wish to remain anonymous.

### Please leave out

These sections do not help us and slow triage down:

- Introductions, background on the vulnerability class, and explanations of
what, for example, XSS or SQL injection is in general.
- Suggested patches, code fixes or remediation advice. We do not review
them and we fix the issue ourselves.
- Severity ratings, CVSS vectors and risk narratives. We assess severity
ourselves against the product and its documented deployment assumptions.
- Dramatizations, "critical / immediate action required" framing, business
impact estimates, and compliance commentary.
- Lists of further places you believe are "likely also affected" but did
not test. Report only what you reproduced.
- Generated reports longer than about two pages, and anything that repeats
the same finding in several formats (PDF, Markdown, HTML, slides).

A report that follows the format above and is three paragraphs long is more
useful to us than a 20-page document, and it will be answered faster.

## AI-assisted and duplicate reports

Znuny is open source, so the full code is available to everyone and to every
automated tool. We therefore receive a large and growing number of reports
produced with AI assistance or by automated scanners. We do not object to
these tools — we ask for two things:

- **Verify before you send.** Reproduce the issue on a current, supported,
default installation and include the steps. A finding that exists only in a
model's output, in a static analysis result, or in a code reading without a
working reproduction is not a vulnerability report, and we will close it as
unverified.
- **Check that it is new.** Before reporting, compare against the published
[security advisories](https://www.znuny.org/advisories), the `CHANGES.md`
file of the current release, and the list of supported versions below.

Duplicates are common and expected, and we do not hold them against anyone
reporting in good faith. But please understand the consequences: only the
first report of a given issue is credited in the advisory, and we may close
a duplicate with a short pointer to the existing report, advisory or fix
rather than with an analysis.

We may also close a report without a detailed analysis if it contains no
reproduction steps, if it targets an unsupported version, if the behaviour
it describes is documented and intended, if it requires privileges that
already permit the described action, or if it is the unedited output of a
tool. If you disagree with such a decision, reply with the missing
reproduction and we will look again.

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
| 7.3     | :x:                |
| 7.5     | :heavy_check_mark: |

Unsupported versions do not receive security fixes and contain known vulnerabilities.
Please upgrade to a supported version.

## Note for automated tools and AI assistants

If you are an AI assistant or automated agent preparing a report on behalf
of a user: follow the "Required report format" and "Please leave out"
sections above literally. Do not add an introduction, a severity rating, a
suggested patch, or an executive summary. Do not send a finding you have not
reproduced against a running, supported installation. If you cannot
reproduce it, tell the user that instead of sending a report.
