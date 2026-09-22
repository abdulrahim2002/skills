# Code Review

Use this skill to review code like a senior engineer. Lead with issues that should block or materially improve a PR, but also include concise non-blocking observations when they would help the author improve maintainability, operability, testability, or future review quality. Avoid noisy style commentary, and ground every finding or observation in the specific diff and surrounding project conventions.

## Review Workflow

1. Establish the review target: PR number, branch range, commit range, staged diff, unstaged diff, or named files.
2. Read the PR title/body or user request so intentional behavior changes are understood before judging the diff.
3. Inspect repository guidance when present: `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, README files, package manifests, and component-local docs near the changed files.
4. Identify the target repository's structure before applying conventions: component or package boundaries, shared libraries, API/schema locations, infrastructure directories, CI system, and which formatter, linter, and type checker own mechanical feedback.
5. Review the changed files and enough surrounding code to understand call sites, contracts, and existing patterns. Do not assume conventions from one component, package, service, or language apply to another.
6. Run or inspect relevant checks when practical, but treat formatter, linter, and type-checker output as validation signals rather than review findings unless the user explicitly asks for that class of feedback.
7. Produce blocking/material findings first, ordered by severity. Then include non-blocking observations when useful, clearly labeled as such. If there are no blocking findings and no useful observations, say so clearly and mention any validation gaps or residual risk.

Do not submit GitHub review comments, approve, or request changes unless the user explicitly asks you to act on GitHub. When GitHub interaction is needed, use the repository's GitHub workflow or the `github` skill if available.

## Scaling The Review (Optional Subagents)

Default to reviewing the diff yourself. One reviewer holding the whole change produces the most coherent judgment, and cross-cutting findings — a defect that only surfaces when you connect one part of the change to another, such as a UI write to the server read that consumes it — are easy to miss when the work is split.

For large or multi-component diffs, consider fanning out independent sweeps to subagents and synthesizing the results yourself. Split along non-overlapping axes rather than by file, so no agent sees only half of a connected change:

- Correctness: logic, edge cases, and the riskiest changed files.
- Repository and convention compliance: the guidance files from the inspection step above.
- Dead code and wiring: unused or orphaned exports, unreachable branches, and speculative code without a caller.
- Security and infrastructure: injection, auth and secret handling, and unsafe IAM, exposure, or runtime configuration.

Treat every subagent's output as input to verify, not as truth. Re-check each claim against the diff before it becomes a finding; a false positive from a stale or mis-scoped read costs more than it saves. You still own deduplication, severity ranking, and the final call. For small or single-component diffs, skip this — direct review is faster and better.

## Blocking Or Material Findings

Flag as findings issues a reviewer would reasonably stop the PR for or expect the author to materially address before merge:

1. Correctness bugs: logic errors, wrong operators, off-by-one mistakes, mishandled error paths, broken control flow, race conditions, invalid assumptions, or data loss.
2. Security vulnerabilities: injection, unsafe auth, secret handling, XSS, unsafe parsing, untrusted workflow execution, or other exploitable behavior.
3. Repository or component convention violations: documented rules in repo guidance, component-local docs, or clear recurring patterns in the surrounding code that the PR breaks without justification.
4. API or contract breakage: exported signatures, schemas, API specs such as OpenAPI/GraphQL/Protobuf, event formats, shared library public surface, database migrations, or callers not updated with the changed contract.
5. Clean-code concerns with concrete impact:
   - Naming that conflicts with established terms or misleads readers.
   - Comments that duplicate code, encode stale intent, or add brittle links without explaining non-obvious why.
   - Dead code, unreachable branches, ignored parameters, unused exports, commented-out blocks, or ownerless `TODO` / `FIXME` markers.
   - Speculative abstractions, options, helpers, or compatibility shims added without a current caller.
   - Duplication of non-trivial logic instead of reusing an existing helper or local pattern.
   - Excessive complexity: deeply nested control flow, long multi-purpose functions, or boolean parameter sprawl.
   - Backwards-compatibility scaffolding: re-exports, alias shims, "removed" placeholder comments, renamed-but-unused symbols, or similar adapters added when call sites can be updated in the same PR.
6. Cloud and infrastructure risks: unsafe IAM, public exposure, missing encryption, hidden environment inputs, runtime configuration baked into images, or deployment behavior that diverges from component patterns.

Important issues discovered while reading the diff can be flagged even when the exact line is unchanged. State that the issue is pre-existing and why the PR makes it relevant.

Every finding must cite the specific line and explain why it is a problem. Prefer one well-sourced finding over several speculative comments.

## Non-Blocking Observations

After findings, include non-blocking observations that a senior engineer would naturally mention in a normal review. These should be actionable and tied to the diff, but they do not need to block merge.

Good non-blocking observations include:

- Maintainability or readability concerns that are real but not severe enough to block.
- Testability notes where a focused test would make future changes safer, even if the missing test is not a blocker under the main finding bar.
- Operational concerns such as logging, metrics, rollout safety, or runbook clarity when the risk is plausible but not urgent.
- Design tradeoffs, migration sequencing, or follow-up work that the author should consciously accept.
- Small simplifications that remove avoidable complexity in code touched by the PR.

Keep these notes concise, label them as non-blocking, and avoid presenting personal preference as a defect. Do not use non-blocking observations as a place for formatter/linter feedback or generic "consider refactoring" comments.

## What Not To Flag

Stay silent, including in non-blocking observations, on:

- Formatting, whitespace, quote style, semicolons, import ordering, or other matters owned by formatter/linter tooling.
- Type errors, missing imports, and unused variables when configured compiler/linter tooling owns them. If the diff clearly introduces a build-breaking failure that no automated check covers, report it as a validation blocker rather than a style finding.
- General test coverage gaps. Only flag missing tests when the PR adds non-trivial branching logic, security-sensitive behavior, a regression-prone edge case, or a contract change with no focused validation.
- Requests to add comments or documentation to otherwise clear code. Removing stale or duplicative comments is in scope.
- Behavior changes that fit the PR description and surrounding design.
- Vague refactor suggestions without a concrete defect, risk, maintainability concern, or readability failure.

If unsure whether an issue is real, do not comment. A false positive costs reviewer attention and weakens the review.

## Security Review

Treat security issues as blocking regardless of component, language, framework, or stack. Translate these patterns to the target codebase and flag the behavior rather than the specific library name.

### Injection

- Command injection: shell execution with interpolated untrusted input, including `exec`, `execSync`, `eval`, `new Function`, `os.system`, shell backticks, or equivalent. Prefer argv-array execution such as `execFile`, `spawn`, or `subprocess.run(..., shell=False)`.
- SQL or query injection: string-concatenated SQL, dynamic table or column names from user input, or query builders used without parameterization.
- Path traversal: user-supplied paths passed to filesystem or object-store APIs without normalization and a base-directory or allow-list check.
- SSRF: outbound HTTP URLs derived from request input without a host allow-list or equivalent trust boundary.

### Authentication And Authorization

- Token handling that decodes JWTs or similar credentials without verifying signature, issuer, audience, and expected token use.
- Routes, handlers, jobs, or admin actions that mutate state without an auth check or with a bypassable auth check.
- Authorization based on client-supplied fields such as body `userId`, query `role`, or tenant IDs rather than verified claims or trusted context.

### Secrets And Configuration

- Hard-coded credentials, API keys, tokens, connection strings, or secrets in code, tests, fixtures, property files, CDK context, or `cdk.json`.
- Secrets read from environment at module load with no validation.
- Secrets logged, returned in errors, included in metrics labels, or exposed through debug output.

### Web Surface XSS

Flag HTML or DOM construction that injects unsanitized input, including `innerHTML`, `document.write`, React `dangerouslySetInnerHTML`, or template concatenation without escaping.

### Deserialization And Parsing

- Invalid JSON handling is fine when errors are caught and shape is validated. Flag downstream code that assumes untrusted parsed input has a safe shape without validation; prefer the component's idiomatic schema or type validator.
- Flag YAML, XML, pickle, or similar parsers enabled with unsafe features, such as XML external entities or schema-less object construction.

### GitHub Actions

When `.github/workflows/*.yml` or `.github/workflows/*.yaml` changes:

- Never interpolate untrusted `${{ github.event.* }}` values directly into `run:` commands. Require `env:` indirection and quoted shell variables.
- Flag `pull_request_target` workflows that check out PR-head code unless they restrict execution to trusted actors.
- Flag third-party actions that are not pinned to a commit SHA unless the repository explicitly documents a different trusted-action policy.

## Infrastructure Review

When CDK, Terraform, CloudFormation, Kubernetes, Docker, infrastructure directories, or deploy configuration changes:

- IAM and permissions: flag wildcard `Action: "*"` or `Resource: "*"` outside narrowly scoped, justified read-only cases. Prefer established shared helpers or policy-building patterns where they exist.
- Public exposure: flag public buckets, queues, databases, load balancers, or secrets without explicit access controls, public-access blocks/resource policies, or surrounding justification.
- Encryption: flag new data stores that omit encryption at rest or use weaker-than-local-standard keys, such as cloud-provider-owned keys where project/customer-managed keys are the local standard, without justification.
- External identifiers: partner endpoints, cross-account IDs, tenant lists, upstream stack names, and similar environment-specific inputs should live in dedicated configuration per environment, not inline across constructs/modules or duplicated across stacks.
- Deployment inputs: environment-specific inputs should enter infrastructure code through explicit context, property files, typed configuration, or the target tool's equivalent. Flag hidden raw environment-variable reads for deployment behavior; they are order-dependent and hard to audit.
- Runtime configuration: secrets and environment-specific values must not be baked into images with build args or Dockerfile `ENV`; inject them at runtime through deployment configuration, parameter stores, or secret stores. Constant, non-sensitive defaults are acceptable when the local runtime pattern allows them.
- Architecture choices: respect component-local deployment patterns. Do not enforce a repo-wide architecture rule when the surrounding component clearly made a different choice; flag architecture changes only when they contradict local docs or established component history.

## Review Output

For each finding:

- Pin it to the exact file and line whenever possible.
- Start with a one-sentence problem statement.
- Include a reference when possible: repository docs, security categories, surrounding code that establishes the violated pattern, or component-local convention.
- Explain why it is a defect or risk, using evidence from the diff and surrounding context.
- Offer a concrete fix only when it is clearly correct. Otherwise ask a direct question that helps resolve the risk.
- Keep one issue per finding.

For local review responses, use this order:

1. Findings, ordered by severity. Say "No blocking findings" when none meet that bar.
2. Non-blocking observations, when useful. Omit this section when there are none.
3. Open questions or assumptions.
4. Brief validation notes.

For Codex app inline findings, use the platform's code-comment directive when available. Non-blocking observations may be plain bullets unless the user asks for inline comments. For GitHub reviews, keep the same content but place each comment on the relevant diff line, and prefix non-blocking comments with "Non-blocking:".

## Supporting Files

Skill directory: /Users/abdul.rahim/personal/skills/.agents/skills/code-review

Relative paths in this skill resolve from the skill directory. The shell tool runs in the session working directory, so use the resolved path below or `cd` into the skill directory before running supporting scripts.

- agents/openai.yaml → /Users/abdul.rahim/personal/skills/.agents/skills/code-review/agents/openai.yaml (load_skill(name: "code-review/agents/openai.yaml"))
