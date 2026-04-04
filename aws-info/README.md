# aws_report.sh Guide

**Overview**
`aws_report.sh` generates a consolidated AWS report with up to four sections: cost,
IAM security posture, TLS endpoint health, and network inventory. It writes either
Markdown (default) or JSON output and can run sections sequentially or in
parallel. The script is designed to be safe for repeated use and provides warning
summaries when any section only partially succeeds.

**When To Use This Script**
Use this script when you need a quick, consistent snapshot of:
- Cost Explorer deltas month-over-month.
- IAM posture signals (MFA coverage, key age, admin roles, cross-account roles).
- TLS health and certificate expiration for known endpoints.
- Network inventory for resources that share a common tag.

**Quick Start**
Run all sections (defaults to Markdown output, auto-generated filename):
```bash
./aws_report.sh -i ./tls_info/links -k Environment -v prod
```
Run only cost and IAM, write JSON, overwrite existing file:
```bash
./aws_report.sh --only cost,iam --format json --output ./aws_report.json --overwrite
```
Run with config file:
```bash
./aws_report.sh --config ./report_config.json
```

**Dependencies**
Required for all runs:
- `aws` CLI
- `jq`

Required when TLS section is enabled:
- `openssl`
- `timeout` or `gtimeout`

Required when cost section is enabled:
- `python3` or GNU `date` (`gdate`)

Optional but helpful:
- `dig` for DNS lookups in TLS probes (fallback to `python3` resolver)

**Inputs You Must Provide**
Some flags are only required if specific sections are enabled.
- TLS section requires `--tls-input`.
- Network section requires both `--tag-key` and `--tag-value`.

**Output Behavior**
Default output:
- Markdown file in the script directory with a UTC timestamp in the filename.

JSON output:
- A top-level object that merges `metadata`, `warnings`, and each enabled section.

Overwrite behavior:
- Existing output file is not replaced unless `--overwrite` is set.

Exit codes:
- `0` success
- `1` validation or non-auth errors
- `2` AWS auth errors (AccessDenied/AuthFailure/UnrecognizedClientException)
- `3` partial failure (one or more sections failed but report was still written)

**Permissions Required**
The script uses AWS CLI calls under the hood. The IAM principal used by the AWS
CLI profile should allow the following actions. If you only run specific
sections, you can scope permissions to those services.

Cost section:
- `ce:GetCostAndUsage`

IAM section:
- `sts:GetCallerIdentity`
- `iam:GetAccountSummary`
- `iam:ListUsers`
- `iam:ListRoles`
- `iam:GetLoginProfile`
- `iam:ListMFADevices`
- `iam:ListAccessKeys`
- `iam:GetAccessKeyLastUsed`
- `iam:ListAttachedRolePolicies`
- `iam:GetPolicy`
- `iam:GetPolicyVersion`
- `cloudtrail:DescribeTrails`
- `guardduty:ListDetectors`
- `securityhub:GetEnabledStandards`

TLS section:
- No AWS permissions required (local `openssl` probes only).

Network section:
- `ec2:DescribeVpcs`
- `ec2:DescribeSubnets`
- `ec2:DescribeRouteTables`
- `ec2:DescribeNatGateways`
- `ec2:DescribeSecurityGroups`
- `resourcegroupstaggingapi:GetResources`
- `wafv2:GetWebACLForResource`
- `wafv2:GetWebACL`
- `wafv2:GetIPSet`

**Config Precedence**
From highest to lowest:
- CLI flags
- Config file (`--config`)
- Environment (`AWS_PROFILE`, `AWS_REGION`, `AWS_DEFAULT_REGION`)
- Script defaults

Notes:
- `--log-level` defaults to `INFO`. A config `log_level` is only applied when
  the CLI flag is not set.
- `--log-file` from config is only applied if the CLI flag is not set.
- `--overwrite` and `--parallel-sections` from config apply only if the CLI
  flag is not set.

**Config File Schema**
The config is JSON. Any field can be omitted.
```json
{
  "tls_input": "./links.txt",
  "tag_key": "Environment",
  "tag_value": "prod",
  "profile": "cc-prod",
  "region": "us-east-1",
  "output": "./aws_report_cc.md",
  "top_n": 10,
  "include_record_types": "",
  "exclude_record_types": "Credit,Refund,Tax",
  "iam_mode": "full",
  "tls_timeout": 5,
  "tls_parallel": 32,
  "log_level": "DEBUG",
  "log_file": "./aws_report.log",
  "parallel_sections": true,
  "overwrite": true,
  "format": "json",
  "only": "cost,iam",
  "skip": "tls"
}
```

**Section Selection**
Use these flags to control which sections run:
- `--only cost,iam,tls,network` to run a subset.
- `--skip cost,iam,tls,network` to skip one or more.
- `--parallel-sections` to run enabled sections concurrently.

When to use:
- Use `--only` when you want a fast, focused report.
- Use `--skip` when you want most sections but need to omit one.
- Use `--parallel-sections` for faster runs on large accounts; be aware that
  AWS API rate limits may be hit more easily.

**TLS Input File Format**
The TLS input file is a line-based list. The parser accepts:
- URLs like `https://example.com/path`.
- Hostnames like `example.com`.
- Host and port like `example.com:8443`.

Rules:
- Blank lines and lines starting with `#` are ignored.
- If no port is provided or it is invalid, the script defaults to port `443`.
- The scheme, path, query, and fragment are ignored.

**Detailed Flag Guide**
All flags and when to use them.

AWS context:
- `-p, --profile <name>`
Use when you need a non-default AWS CLI profile. If omitted, uses `AWS_PROFILE`
or `default`.

- `-r, --region <region>`
Use when APIs should target a specific region. If omitted, uses `AWS_REGION` or
`AWS_DEFAULT_REGION`. If the final value is `default`, the script behaves as if
region is not set.

Output:
- `-o, --output <file>`
Use to control the report filename and location.

- `--format <markdown|json>`
Use `markdown` for human reading, `json` for machine processing or pipelines.

- `--overwrite`
Use when you want to replace an existing output file.

- `--log-level <ERROR|WARN|INFO|DEBUG>`
Use `DEBUG` to inspect AWS calls and decision points. Use `WARN` or `ERROR` for
quiet runs.

- `--log-file <file>`
Use to persist logs to a file in addition to stderr.

Cost options:
- `-n, --top-n <number>`
Controls how many services appear in top spenders and increase tables. Use a
higher number for wider coverage. Range: 1-100.

- `--include-record-types <list>`
Use to only include specific Cost Explorer record types. This overrides the
exclude list. Example: `Credit,Refund`.

- `--exclude-record-types <list>`
Use to exclude record types from cost calculations. Default excludes
`Credit,Refund,Tax`.

IAM options:
- `--iam-mode <fast|full>`
Use `fast` for quicker runs. Use `full` when you want access key last-used data
and deeper admin-role detection.

TLS options:
- `-i, --tls-input <file>`
Required when TLS section is enabled. Point to a file containing endpoints.

- `--tls-timeout <seconds>`
Use when endpoints are slow or to fail faster. Range: 1-60 seconds.

- `--tls-parallel <number>`
Use to control concurrency for TLS probes. Higher values are faster but can
increase load on your network and on the targets. Range: 1-128.

Network options:
- `-k, --tag-key <key>`
- `-v, --tag-value <value>`
Use to scope inventory to resources matching a specific tag. Required when the
network section is enabled.

Config:
- `--config <file>`
Use to persist common settings across runs. CLI flags still override config.

General:
- `-h, --help` show usage
- `--version` print script version

**Section Details**
What each section includes and when to use it.

Cost section (`cost`):
- Uses Cost Explorer to compare the most recent full month to the month before it.
- Outputs top spenders, largest increases, and a "spending more" list.
- Best for monthly delta reviews, budget checks, and cost anomalies.

IAM section (`iam`):
- Reports root MFA and root access key presence.
- Counts console users with and without MFA.
- Lists access keys with age and last-used date (in `full` mode).
- Identifies admin-equivalent roles and cross-account roles.
- Checks CloudTrail, GuardDuty, and Security Hub status.
- Best for security posture checks and audit preparation.

TLS section (`tls`):
- Probes endpoints to capture TLS version, errors, and certificate expiration.
- Useful for hygiene checks, deprecation planning, and alerting on expirations.

Network section (`network`):
- Inventory of VPCs, subnets, route tables, routes, NAT gateways, security groups.
- WAFv2 Web ACLs and referenced IP sets for tagged resources.
- Best for tagged environment snapshots and infrastructure reviews.

**Common Recipes**
Monthly cost delta report only:
```bash
./aws_report.sh --only cost --format markdown
```

Security posture snapshot:
```bash
./aws_report.sh --only iam --iam-mode full --format markdown
```

TLS health for a service list:
```bash
./aws_report.sh --only tls -i ./tls_info/links --tls-timeout 10 --tls-parallel 64
```

Network inventory for production tag:
```bash
./aws_report.sh --only network -k Environment -v prod
```

Full report with parallel execution:
```bash
./aws_report.sh -i ./tls_info/links -k Environment -v prod --parallel-sections
```
