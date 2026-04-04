---
name: aws-info
description: Generate a consolidated AWS report.
---

# AWS Info

Use this skill to collect cost, IAM, TLS, and network inventory data with [aws_report](./scripts/aws_report.sh) bash script.

## When To Use This Script
Use this script when you need a quick, consistent snapshot of:
- Cost Explorer deltas month-over-month.
- IAM posture signals (MFA coverage, key age, admin roles, cross-account roles).
- TLS health and certificate expiration for known endpoints.
- Network inventory for resources that share a common tag.

## Script

- Run the [aws_report](./scripts/aws_report.sh) to get information about AWS `cost`, `iam`, `tls`, and `network`.

### Examples:

Run with config file:
```bash
./aws_report.sh --config ./config.json
```

### Config File Schema (`config.json`)

```json
{
  "profile": "<aws_profile>",
  "region": "<aws_region>",
  "tag_key": "<env>",
  "tag_value": "<dev>",
  "top_n": 10,
  "include_record_types": "<include_cost_types>",
  "exclude_record_types": "<exclude_cost_types>",
  "iam_mode": "<fast|full>",
  "tls_input": "<links_file_path>",
  "tls_timeout": 5,
  "tls_parallel": 32,
  "log_level": "INFO",
  "log_file": "<log_file_path>",
  "format": "<markdown|json>",
  "only": "<cost|iam|tls|network>",
  "skip": "<cost|iam|tls|network>",
  "parallel_sections": <true|false>,
  "overwrite": <true|false>,
  "output": "<output_file_path>"
}
```

## AWS Profile

If you see AWS connection errors (for example: "Unable to locate credentials", "AccessDenied", or "could not connect to the endpoint"), show the [connection_template](./templates/CONNECTION_TEMPLATE.md) to the user to help them fix the issue.

## Templates

- Basic questions: [question_template](./templates/QUESTION_TEMPLATE.md)  used as the first question.
- TLS question: [tls_template](./templates/TLS_QUESTION_TEMPLATE.md) used if TLS scan is requested.
- Network question: [network_template](./templates/NETWORK_QUESTION_TEMPLATE.md) used if Network scan is requested.
- Missing profile: [connection_template](./templates/CONNECTION_TEMPLATE.md) used if AWS credentials are not working.
- Response output: [response_template](./templates/OUTPUT_TEMPLATE.md) used for the final output.

## Workflow

1. Confirm the user inputs are sufficient to run the script. (hard gate)
   
   - If they are not, ask the user to clarify inputs using [question_template](./templates/QUESTION_TEMPLATE.md). 
   - When the user chooses to scan using TLS, utilize the [tls_template](./templates/TLS_QUESTION_TEMPLATE.md) to obtain the necessary information.
   - When the user chooses to scan network, utilize the [network_template](./templates/NETWORK_QUESTION_TEMPLATE.md) to obtain the necessary information.
   - If the user chooses to scan for TLS, create a file using [list_file_template](./templates/template_files/url_list.txt) that lists the user-provided URLs and point `tls_input` at that file.
   - After all the questions are answerd create `config.json` using [config_template](./templates/template_files/scan_config.json). 
   - Stop-gate: do not proceed until a usable `config.json` exists for the user request. 

2. Run the [script](./scripts/aws_report.sh) once `config.json` (and any TLS links file) exists.
   
   - Tell the user you are starting the script and that, depending on their selections and the number of resources in the account, the process can take some time.
   - Execute:
     ```bash
     ./aws_report.sh --config ./config.json
     ```

3. After the script completes, read the report output file and respond using [output_template](./templates/OUTPUT_TEMPLATE.md).

   - Determine the output path from `config.json` (`output`).
   - Read the output file (json) and use it as the source content for the template.
   - Populate the template with the report content and return it as the final response.

---

## Helpful Notes

- If `config.json` contains region filters or tag filters, confirm they match the user request before execution.
- If the script exits early, re-check file paths in `config.json` (especially `output` and any TLS `tls_input` file).

## Do Not Do

- Do not perform any write actions in AWS.
- Do not run the script without required inputs.
- Do not print or expose credentials or secrets.
