# Commandments for Skill Creation

1. **Single Responsibility Only**
   A skill must solve one clear problem end-to-end.

2. **Deterministic Execution**
   Same input must always produce the same result.

3. **Validate Everything First**
   Never execute without input, dependency, and environment validation.

4. **Fail Fast and Clearly**
   Errors must be immediate, explicit, and actionable.

5. **Automate Fully**
   Eliminate manual steps wherever possible.

6. **Be Idempotent** *(AWS best practice)*
   Re-running the skill must not create unintended side effects.

7. **Keep It Composable**
   Design skills to be chained into larger workflows.

8. **Minimize User Input**
   Require only essential parameters; infer the rest.

9. **Provide Observability**
   Log all key steps, decisions, and outputs.

10. **Include Safe Guards**
    Require confirmation for destructive actions (e.g., deletes).

11. **Version and Document**
    Every skill must be versioned and clearly documented (`SKILL.md`).

12. **Test Before Trust**
    Validate locally and in CI before reuse.
