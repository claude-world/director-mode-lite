# [Project name] — working guide

Keep this file concise and specific to facts every session needs. Director Mode
suggestions live in `.director-mode/GUIDANCE.md`; task procedures belong in
skills so they load only when relevant.

## Project

- Purpose: [what this project does]
- Stack: [languages, frameworks, runtime]
- Key paths: [entry points and important directories]

## Useful commands

```bash
[install command]
[targeted test command]
[full verification command]
[development or build command]
```

## Local conventions

- [A concrete convention the repository cannot reveal on its own]
- [Where new code or tests normally belong]
- [A compatibility or product constraint that commonly matters]

## Completion evidence

Choose checks that match the change. Common evidence includes targeted tests,
the full build or typecheck, an inspected diff, and a short note about checks
that could not run.

## Cross-CLI continuity

Claude Code, Codex CLI, and Grok Build can share repository guidance, skills,
and adapted agents. Their native session histories and controls remain separate.
Use the `session-relay` skill when another CLI should continue the work.

<!-- director-mode-lite:start -->
## Director Mode Lite (guidance)

For substantial work, read `.director-mode/GUIDANCE.md`. It offers a concise
brief, verification checklist, and portable Claude/Codex/Grok handoff format.
It never adds a permission gate, denial rule, or forced workflow. Use this
CLI's native permission mode and approvals according to the user's choice.
<!-- director-mode-lite:end -->
