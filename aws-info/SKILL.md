---
name: aws-info
description: Generate a consolidated AWS report.
---

# AWS Info

Run the [aws_report](./scripts/aws_report.sh) to get information about AWS `cost`, `iam`, `tls`, and `network`.

## When To Use This Script
Use this script when you need a quick, consistent snapshot of:
- Cost Explorer deltas month-over-month.
- IAM posture signals (MFA coverage, key age, admin roles, cross-account roles).
- TLS health and certificate expiration for known endpoints.
- Network inventory for resources that share a common tag.

### Config File Schema (`scan_config.json`)

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

### Examples:

Run with config file:
```bash
./aws_report.sh --config ./scan_config.json
```

### AWS Profile

If you see AWS connection errors (for example: "Unable to locate credentials", "AccessDenied", or "could not connect to the endpoint"), show the [connection_template](./templates/CONNECTION_TEMPLATE.md) to the user to help them fix the issue.

## Templates

- Basic questions: [question_template](./templates/QUESTION_TEMPLATE.md)  used as the first question.
- TLS question: [tls_template](./templates/TLS_QUESTION_TEMPLATE.md) used if TLS scan is requested.
- Network question: [network_template](./templates/NETWORK_QUESTION_TEMPLATE.md) used if Network scan is requested.
- Missing profile: [connection_template](./templates/CONNECTION_TEMPLATE.md) used if AWS credentials are not working.
- Response output: [response_template](./templates/OUTPUT_TEMPLATE.md) used for the final output.

## Workflow

1. Confirm the user inputs are sufficient to run the script. (hard gate)
   
   - Ask the user to clarify inputs using [question_template](./templates/QUESTION_TEMPLATE.md). 
   - When the user chooses to scan TLS, utilize the [tls_template](./templates/TLS_QUESTION_TEMPLATE.md) to obtain the necessary information. (replace X with the number)
   - When the user chooses to scan network, utilize the [network_template](./templates/NETWORK_QUESTION_TEMPLATE.md) to obtain the necessary information. (replace X with the number)
   - If the user chooses to scan for TLS, create a file using [list_file_template](./templates/template_files/url_list.txt) template that lists the user-provided URLs and point `tls_input` at that file.
   - After all the questions are answerd create `scan_config.json` using [config_template](./templates/template_files/scan_config.json) template.
   - Stop-gate: do not proceed until a usable `scan_config.json` exists for the user request. 

2. Tell the user you are starting the script. (hard gate)
   - Note: 
   ```markdown
   We are starting the script. Depending on your selections and the number of resources in the account, the process may take some time.
   Reply “run” and I’ll execute it.
   ```
   - Stop-gate: do not begin the script until you have displayed the note.

3. Run the [script](./scripts/aws_report.sh) once `scan_config.json` (and any TLS links file) exists.
   
   - Execute:
     ```bash
     ./aws_report.sh --config ./tmp/s-<DDMMHM>/scan_config.json
     ```

4. After the script completes, read the report output file and respond using [output_template](./templates/OUTPUT_TEMPLATE.md).

   - Determine the output path from `scan_config.json` (`output`).
   - Read the output file and use it as the source content for the template.
   - Populate the template with the report content and return it as the final response.

---

## Helpful Notes

- Use a per-session timestamp identifier in the format `DDMMHM` (day, month, hour, minute) to create a directory under `./tmp` (for example: `./tmp/s-<DDMMHM>/`). Store all session files there (such as `scan_config.json`, any TLS URL list, logs, and the report output), and set `tls_input`, `log_file`, and `output` paths in `scan_config.json` to point into that directory.
- If `scan_config.json` contains region filters or tag filters, confirm they match the user request before execution.
- If the script exits early, re-check file paths in `scan_config.json` (especially `output` and any TLS `tls_input` file).

## Do Not Do

- DO NOT perform any write actions in AWS.
- DO NOT run the script without required inputs.
- DO NOT print or expose credentials or secrets.
- YOU DO NOT NEED to read `scripts/*.sh` scripts.
