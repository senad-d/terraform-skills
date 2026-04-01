---
page_title: Well-Architected Pillar Mapping
description: Guidance for mapping Terraform planning steps to AWS Well-Architected pillars in a consistent, repeatable way.
---

# Well-Architected Pillar Mapping

Standardize how review steps are labeled to AWS Well-Architected pillars so steps are comparable across modules and reviews.

## Pillars (use exact labels)

- Operational Excellence
- Security
- Reliability
- Performance Efficiency
- Cost Optimization
- Sustainability

## Mapping Rules

- Every step must map to at least one pillar.
- Use a primary pillar and, if needed, a secondary pillar.
- If a step clearly fits multiple pillars, pick the primary pillar based on the highest risk impact, then note secondary in the detailed step.

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

- Detailed steps should restate the pillar mapping if it is not obvious.
