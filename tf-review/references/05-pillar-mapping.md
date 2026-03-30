---
page_title: Well-Architected Pillar Mapping
description: Guidance for mapping Terraform review findings to AWS Well-Architected pillars in a consistent, repeatable way.
---

# Well-Architected Pillar Mapping

Standardize how review findings are labeled to AWS Well-Architected pillars so
findings are comparable across modules and reviews.

## Pillars (use exact labels)

- Operational Excellence
- Security
- Reliability
- Performance Efficiency
- Cost Optimization
- Sustainability

## Mapping Rules

- Every finding must map to at least one pillar.
- Use a primary pillar and, if needed, a secondary pillar.
- If a finding clearly fits multiple pillars, pick the primary pillar based on
  the highest risk impact, then note secondary in the detailed finding.

## Common Mapping Examples

- Overly broad IAM permissions -> Security (primary), Reliability (secondary)
- Public network exposure without justification -> Security (primary)
- Missing backups or recovery settings -> Reliability (primary)
- Unbounded autoscaling or expensive defaults -> Cost Optimization (primary)
- Inefficient resource sizing -> Performance Efficiency (primary)
- Missing monitoring or runbooks -> Operational Excellence (primary)
- Excessive log retention without need -> Sustainability (secondary) or Cost
  Optimization (primary) based on impact

## Output Expectations

- Findings Overview table must include a Pillar column.
- Detailed findings should restate the pillar mapping if it is not obvious.
