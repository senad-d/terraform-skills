---
page_title: Terraform Review Overview
description: Overview of the Terraform module review lifecycle, principles, and checklists.
---

# Terraform Review Overview

This guide is the entry point for the Terraform review documentation set. It
explains how to navigate the guides, outlines the review lifecycle, and calls
out which documents are authoritative for each topic.

## Core Principles

- Review findings must be evidence-based and tied to concrete file locations or
  tool output.
- Prioritize security, reliability, and correctness before style or refactors.
- Treat secure defaults as the baseline; exceptions require explicit
  justification.
- Focus on least-privilege IAM, network minimization, and encryption by
  default.
- Favor consistent patterns already used in this repository.
- Document assumptions, risks, and verification steps for every finding.
- Challenge the code by testing claims against evidence and behavior, not
  intent.

## Review Checklist

- Module scope and non-goals are explicit and match the README.
- Terraform and provider versions are pinned to supported constraints.
- Inputs are typed, validated, and have safe defaults.
- IAM, networking, and encryption follow least-privilege and secure defaults.
- Resource naming and tagging meet repository conventions.
- Logging, monitoring, and retention are configured where relevant.
- Cost exposure is understood and mitigated (limits, scaling, retention).
- Confirm module intent, boundaries, and invariants before reviewing code.
- Capture evidence for every issue (file + line, plan output, or tool output).
- Assign severity based on impact and exploitability.
- Provide a concrete remediation and verification step per finding.
- Run a challenge pass to eliminate already-satisfied requirements.

## Definition of Done

- Review plan is completed and scoped to the correct module(s).
- Findings include evidence, impact, severity, and remediation guidance.
- High and critical issues include explicit verification gates.
- Recommendations are validated against authoritative references.
- Review output is published with links to sources.

## Sources of Truth

The review methodology and remediation guides are authoritative for their
topics. This overview should point to them instead of duplicating details.
