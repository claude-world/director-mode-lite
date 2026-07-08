# Changelog

All notable changes to Director Mode Lite will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.9.0] - 2026-07-08

Closes issue #13 (v1.9: guided setup wizard) as scoped in its own re-scoping
comment: "a thin interactive layer that drives `/project-init` rather than a
parallel implementation." Also fixes two small leftovers the v1.8.x audits missed.

### Added
- **`install.sh --wizard`** — interactive setup: asks what kind of project
  you're installing into, then lets you choose the Stop-hook automation level
  (none / Auto-Loop / Auto-Loop + Evolving-Loop) and whether to enable the
  changelog + pre-write safety hooks, instead of always wiring the fixed
  defaults. Agents and skills are still installed in full either way — the
  wizard only changes which hooks get merged into `settings.local.json`.
  Requires a TTY; falls back to the historical defaults under `curl | bash`
  or any other non-interactive stdin, so existing install commands and CI
  are unaffected. Documented in README, MIGRATION.md, and `/getting-started`
- **`tests/test-install-wizard.sh`** — 7 tests covering all three automation
  levels, declining observability hooks, blank-answer defaults, and the
  non-interactive fallback path, plus a regression check that plain
  `./install.sh` (no `--wizard`) still merges every hook exactly as before

### Fixed
- **`agents/skill-synthesizer.md`** was missing the `<example>` block the
  v1.8.1 changelog claimed all 14 agent descriptions had — added
- **Top-level `VERSION` file** was stale at 1.7.2 (unread by any script,
  silently out of sync with `.claude-plugin/plugin.json` /
  `marketplace.json` since the v1.7.2 release) — synced to 1.9.0

## [1.8.1] - 2026-07-06

Completion round for v1.8.0: wires the self-evolving-loop scaffolding into the
installer, adds an in-place upgrade path, hardens CI against count drift, and
lifts agent descriptions to the repo's own documented standard.

### Added
- **`install.sh --update`** — in-place upgrade that overwrites distributed files
  (after the usual backup) instead of skipping them; MIGRATION.md now leads with it
- **`.self-evolving-loop/` scaffolding is now actually installed** (hooks +
  templates copied to the target project, opt-in activation documented in
  `/evolving-loop` under "Hook-Driven Continuation") — previously shipped but
  never wired, so the Stop-hook-driven loop mode could not work
- **`scripts/validate-frontmatter.py` + CI job** — deep validation with real YAML
  parsing: enforces explicit `user-invocable` on every skill (the root cause of
  past count drift), verifies the advertised "27 commands / 14 agents / 32 skills"
  in plugin.json/marketplace.json against reality, validates agent `skills:`
  cross-references, memory enums, and warns on unsupported agent fields
- **`<example>` blocks in all 14 agent descriptions** (per the repo's own
  agent-check standard) showing a concrete delegation scenario each
- **interop-router now knows about Claude profiles** — `check_cli_available.sh`
  detects `claude-z-*` wrappers, `score_decision.py` can recommend
  `claude-profile` for parallel/end-to-end delegation (pairs with `/handoff-claude`)
- **Two new install tests** — scaffolding presence and `--update` overwrite behavior

### Changed
- **memory/maxTurns conventions normalized across all 14 agents** (loop agents +
  personas carry `memory: [user]` and turn caps; experts stay stateless) and
  documented in agents-expert
- **hooks-expert self-freshness** — gains WebFetch and a "Keeping Current"
  instruction to verify hook specs against official docs before answering;
  inline knowledge stamped "last verified v2.1.201 (2026-07-06)"
- **skill-synthesizer generates from the shipped templates** (single {{handlebars}}
  vocabulary; inline scaffolds kept only as fallback); templates gained the
  `lifecycle: task-scoped` field its review gate expects
- **auto-loop-stop.sh rewritten around jq** (quoting-safe parsing, atomic
  checkpoint updates) with the old grep/sed path kept as a jq-less fallback
- **demo.sh counts computed from frontmatter** instead of hardcoded
- **Architecture links in evolving-loop/evolving-status now absolute GitHub URLs**
  (the relative `docs/` links broke after install, since docs/ isn't copied)

### Fixed
- Templates' `description: [Auto-generated] ...` was invalid strict YAML
  (unquoted leading bracket) — quoted in the 3 templates and the synthesizer scaffolds
- uninstall.sh now also removes `.self-evolving-loop/`

## [1.8.0] - 2026-07-06

Full-catalog optimization of all commands, agents, and skills, driven by a five-track audit
(official-spec verification against Claude Code v2.1.201 + per-file review of all 31 skills,
14 agents, hooks, and cross-file consistency). Net −800 lines while adding one new skill.

### Added
- **`/handoff-claude` skill** — Delegate tasks to other authorized Claude Code instances
  (e.g. `claude-z-1`, `claude-z-2` profiles) via headless `claude -p`. Documents the full
  multi-account setup: one `CLAUDE_CONFIG_DIR` per profile (official isolation mechanism for
  settings/sessions/auth), wrapper commands, one-time `claude auth login` per profile, and
  conflict-free parallel fan-out with git worktrees. Also added to interop-router routing
  targets, getting-started, README, and FAQ
- **`## Execution` steps in `/smart-commit`** — was a style reference with no actionable steps;
  now inspects the diff, groups changes, runs quality gates, stages, commits, verifies
- **Return Contract sections in all 6 self-evolving agents** — final message ≤ 3 lines,
  details to files (closes the context-leak hole on the Stop-hook continuation path)
- **FAQ**: plugin-only installs don't activate hooks (and how to); `/handoff-claude` entry
- **CI link checker now scans README + docs/ + skills/** (code-block aware), previously README only

### Changed
- **Spec alignment to Claude Code v2.1.201 (July 2026)**
  - Hook events: "12 types" → **30 official event types** across hook-template, hooks-check,
    hooks-expert, HOOKS-GUIDE, README; added `http`/`mcp_tool`/`agent` hook types, `if`/`statusMessage` fields
  - Subagent tool naming: `Task(...)` → `Agent(...)` (renamed in v2.1.63) in all skill/agent examples
  - Model lineup: Claude 5 family (Fable 5 / Opus 4.8 / Sonnet 5 / Haiku 4.5); model lists gain
    `fable` + `default`, drop `opusplan` from frontmatter validators (session-only alias)
  - Skill `arguments` field corrected to space-separated names (was documented as structured array)
  - Agent validators/templates: dropped non-official `forkContext`; warn on `hooks`/`mcpServers`/
    `permissionMode` (unsupported in filesystem/plugin agents); added `effort`, `background`,
    `isolation`, `disallowedTools`; `color`/`model` relabeled "Director Mode convention (CI), optional per spec"
  - `allowed-tools` accepts both CSV and YAML list (both official; YAML list = house style)
- **Every description rewritten with trigger conditions (WHAT + WHEN)** — all 32 skills and
  14 agents; delegation routing reads only the description, and triggers previously lived in
  body-only Activation sections
- **Persona pairs consolidated to a single source of truth** — code-reviewer / debugger /
  doc-writer skills now hold the canonical checklists (union of drifted copies); the same-named
  agents keep role/process/output and load the skill via `skills:` frontmatter
- **`evolving-orchestrator` slimmed 23 KB → 9 KB** — inline pseudo-Python and five embedded
  multi-page scripts converted to concise bash/jq steps and decision rules (it coordinates the
  loop that is supposed to minimize context consumption)
- **completion-judge decision boundary unified at score ≥ 80** (was SHIP ≥ 90 vs validator
  pass = 80, forcing a wasted iteration for scores 80-89)
- **Internal skills made explicit**: `user-invocable: false` added to code-reviewer, debugger,
  doc-writer, test-runner (joining interop-router) — the "27 commands + 5 internal = 32 skills"
  arithmetic is now enforced by frontmatter, not defaults
- **test-runner reshaped from agent-voice to skill-voice**; kept framework detection + run commands
- **`/changelog` skill trimmed 345 → 194 lines**; documents both rotation thresholds (100-line
  session-start archive vs 500-line auto-rotation)
- **README refresh**: Claude 5-era compatibility section, 27/14/32 counts, handoff-claude,
  Skills panel now explains the command/internal split

### Fixed
- **auto-loop checkpoint injection bug** — `"request": "$ARGUMENTS"` heredoc produced invalid
  JSON for multiline/quoted requests (the documented usage!); now written safely with `jq -n --arg`
- **uninstall.sh data loss** — deleted the user's entire `.claude/settings.local.json`; now
  surgically removes only the hooks/settings that install.sh injected
- **`.self-evolving-loop/hooks/continue-loop.sh` emitted a non-schema Stop output**
  (`{"continue":true,"prompt":...}`) that cannot continue a loop; now uses the official
  `{"decision":"block","reason":...}`; its settings-hooks.json paths now use `$CLAUDE_PROJECT_DIR`
- **`/changelog` filter examples matched nothing** — docs said `file_created`/`file_modified`
  but the hook emits `file_write`/`file_edit`; docs aligned to reality (+ documented `test_run`)
- **handoff-codex taught the interactive TUI form** — all examples now `codex exec` (non-interactive)
- **handoff-gemini used a non-existent `-f` flag** — now `gemini -p "..." @path` / stdin
- **interop-router script paths broke after install** — `$CLAUDE_PROJECT_DIR/skills/...` resolved
  nowhere; now `${CLAUDE_PLUGIN_ROOT:-$CLAUDE_PROJECT_DIR/.claude}/skills/...` (plugin + local installs)
- **mcp-check validated the wrong file** — project MCP servers live in `.mcp.json`
  (via `claude mcp add --scope project`), not `.claude/settings.json`
- **hooks-expert factual errors** — `PrePromptSubmit` → `UserPromptSubmit`, input field
  `hook_type` → `hook_event_name`, Stop continuation key `prompt` → `reason`, PreToolUse
  decisions via `hookSpecificOutput.permissionDecision`
- **mcp-expert pointed at a non-existent package and API** — `@anthropic/context7-mcp` →
  `@upstash/context7-mcp`; removed the fictional `api.anthropic.com/mcp-registry` endpoint
- **skill-synthesizer and skill-evolver lacked Bash** — their MANDATORY security-check /
  evidence-gate / symlink-registration steps could not execute; requirement-analyzer gained
  Write (+ sonnet for the analytical phase), completion-judge gained Write
- **experience-extractor read the wrong event log** — now primary `.self-evolving-loop/history/events.jsonl`
- **`/agents` listed 8 of 14 agents; `/skills` listed 23 of 31** — both complete now
- **3 broken `../../../docs/` links** (evolving-loop ×2, evolving-status) and
  EVOLVING-LOOP-ARCHITECTURE's `../.claude/skills/` path; changelog skill's `hooks/hooks.json` reference
- **Stale versions/counts** — 1.7.1 leftovers in MIGRATION/DEVELOPMENT-PATTERNS/ROADMAP/HOOKS-GUIDE
  (contradicting v1.7.2's "all files updated" claim), demo.sh "25 commands/4 internal",
  demo.sh "claude" expert → "claude-md", docs referencing non-existent `security-checker` agent →
  `code-reviewer`, check-environment example CLI version 2.1.76 → 2.1.201

## [1.7.2] - 2026-03-25

### Added
- **`/getting-started` skill** — Guided 5-minute onboarding with command priority tiers (Beginner/Intermediate/Advanced/Customization/Validation)
- **`docs/MIGRATION.md`** — Version upgrade guide with re-install instructions for each major version
- **Example CLAUDE.md files** for examples 03 (CLI Tool) and 04 (TypeScript Library)
- **Dependency checks in `install.sh`** — Warns about missing `python3` and `jq` at install time
- **FAQ additions** — Hooks troubleshooting, evolving-loop vs auto-loop decision guide, evolving-loop recovery, verify-install reference
- **README "Start Here" section** — 3 essential commands above the fold for new users

### Changed
- **Official Spec Alignment (v2.1.76)**
  - Agent validator: description limit removed (was 100 chars, now 10-5000), tools field now optional
  - Hook template/guide: expanded from 4 to 12 hook types, added `type: "prompt"` support, `once`/`timeout` fields
  - Skill validator: fixed hooks format to official `PreToolUse`/`PostToolUse` structure
- **`project-init` skill** — Expanded from thin outline to full 6-phase guide with multi-language detection, error handling, concrete examples
- **`check-environment` skill** — Added python3/jq checks, multi-language project detection, Director Mode installation verification
- **CI `validate.yml`** — Removed obsolete `validate-commands` job, replaced with enhanced `validate-agents` (checks name, description, color, model, tools format)
- **README restructure** — Compatibility moved to collapsible details, consolidated badges, added HOOKS-GUIDE and DEVELOPMENT-PATTERNS to docs table
- **ROADMAP.md** — Updated current state to v1.7.2, added delivered v1.5-1.7 sections

### Fixed
- Version consistency: all files now reference v1.7.2
- Skills count: corrected from 29 to 31 across all files (interop-router + getting-started)
- Commands count: corrected from 25 to 26 across all files
- `handoff-gemini`: fixed incorrect prerequisite (`@anthropic/gemini-cli` → `@google/gemini-cli`)
- 3 broken internal links (DEVELOPMENT-PATTERNS, EVOLVING-LOOP-ARCHITECTURE, examples/02-rest-api)
- `project-init`: fixed buggy `find` command missing parentheses
- `CONTRIBUTING.md`: added missing `name` field to skill template
- CHANGELOG: added missing v1.7.0 to version history table
- FAQ: updated feature comparison counts

## [1.7.1] - 2026-03-14

### Security
- Removed `.auto-explore/` directory containing leaked absolute filesystem paths, added to `.gitignore`

### Added
- Install verification script (`scripts/verify-install.sh`) — validates installation and reports component status (closes #6)

### Changed
- Added release, stars, and license badges to README for better visibility (closes #5)

## [1.7.0] - 2026-02-10

### Changed
- **Agent Frontmatter: Restored & Expanded Fields** (aligned to official `~/.claude/templates/AGENT-TEMPLATE.md`)
  - **Restored `memory`** field (YAML array: `user`, `project`, `local`) — was incorrectly removed in v1.5.1
  - **Restored `maxTurns`** field (positive integer) — was incorrectly removed in v1.5.1
  - Added `forkContext` field (string `"true"`/`"false"`, not boolean)
  - Added `mcpServers` field (string ref or inline config with 8 transport types)
  - Expanded `model` options: `inherit`, `haiku`, `sonnet`, `opus`, `best`, `sonnet[1m]`, `opus[1m]`, `opusplan`
  - Updated `hooks` to nested format: `matcher` + `hooks` array + `type: command`
  - Expanded `permissionMode` values: `default`, `acceptEdits`, `bypassPermissions`, `plan`, `delegate`, `dontAsk`
- **Skill Frontmatter: New Fields** (aligned to official `~/.claude/templates/SKILL-TEMPLATE.md`)
  - Added `when_to_use` field (underscore, NOT hyphen) for auto-trigger descriptions
  - Added `arguments` field (structured array: `name`/`description`/`required`)
  - Expanded `model` options (same as agents)
  - Updated `hooks` to nested format (same as agents)
- **Agent Validator (`agent-check`)** — Now validates `forkContext`, `maxTurns`, `memory`, `mcpServers`; expanded model list
- **Skill Validator (`skill-check`)** — Now validates `when_to_use`, `arguments`; expanded model list
- **Agent Template (`agent-template`)** — Frontmatter Reference updated with all new fields
- **Skill Template (`skill-template`)** — Frontmatter Reference updated with all new fields
- **Agents Expert (`agents-expert`)** — Inline docs updated: expanded model selection, YAML list examples, new field documentation
- **6 Source Agents Updated** — `code-reviewer`, `debugger`, `completion-judge`, `experience-extractor`, `skill-evolver`, `evolving-orchestrator` restored `memory`/`maxTurns`

### Fixed
- v1.5.1 incorrectly removed `memory` and `maxTurns` from agents — both ARE official fields

## [1.6.0] - 2026-02-10

### Added
- **Interop Router Skill** (`interop-router`) - Auto-trigger skill for external CLI routing
  - Automatically evaluates tasks and delegates to Codex or Gemini when more efficient
  - `user-invocable: false` - no manual invocation needed, Claude decides automatically
  - Decision scoring system: Benefit (0.0-0.6) + Cost (-0.3-0.0) + Risk (-0.3-0.0)
  - Score >= 0.15 with auto-interop enabled -> auto-execute delegation
  - 3 utility scripts included:
    - `check_cli_available.sh` - Detect installed CLIs and authentication status
    - `score_decision.py` - Calculate routing decision score
    - `wrap_context.py` - Wrap files for external CLI with automatic secret filtering
  - Safety: read-only default, automatic secret redaction, result review before landing
  - Configuration via `.claude/flags/auto-interop.json`
  - Works alongside existing `/handoff-codex` and `/handoff-gemini` (manual still available)

## [1.5.1] - 2026-02-10

### Changed
- **Agent Frontmatter Aligned to Official Spec** (Claude Code v2.1.38)
  - `color` and `model` are now **required** fields (were "recommended")
  - `model` supports `inherit` option (use parent's model)
  - `skills` changed from string to **YAML array** format
  - Added `hooks` field for agent-scoped lifecycle hooks (v2.1.0+)
  - Added `permissionMode` field for permission handling (v2.0.43+)
  - Added `disallowedTools` field for explicit tool blocking (v2.0.30+)
  - ~~Removed `memory` field~~ (**reverted in v1.7.0** — field IS official)
  - ~~Removed `maxTurns` field~~ (**reverted in v1.7.0** — field IS official)
- **Skill Frontmatter Aligned to Official Spec**
  - Added `version` field for semantic versioning
  - Added `model` field for model override (haiku/sonnet/opus)
  - Added `disable-model-invocation` field to prevent programmatic invocation
- **All 14 Agents Updated** - Removed non-standard fields, fixed `skills` to array format
- **All Templates & Validators Updated** - agent-check, skill-check, agent-template, skill-template
- **README Accuracy Fixes**
  - Claude Code badge: v2.1.6+ → v2.1.9+ (minimum required version)
  - Plugin install path: v1.4.0 → v1.5.0
  - "Absolute Path Hooks" → "Portable Path Hooks" (`$CLAUDE_PROJECT_DIR`)
  - Added missing `evolving-orchestrator` to Self-Evolving Agents table (6 agents, not 5)
  - Added missing `/changelog` to Utilities section
  - Removed broken one-line curl install option
  - Removed hardcoded Discord member count
  - Updated all version references across docs/examples to v2.1.9+

## [1.5.0] - 2026-02-10

### Changed
- **Agent Frontmatter Format Upgrade** - All 14 agents updated to new format
  - `tools` field: Migrated from bracket array (`[Read, Write]`) to YAML list format
  - Added `color` field for UI display (yellow, red, cyan, magenta per role)
  - Added `model` field specifying recommended model (haiku/sonnet/opus)
  - Added `skills` field linking agents to their corresponding skill
- **Agent Template** - Updated to include all new frontmatter fields
  - Added Orchestrator template type (haiku model, Task tool)
  - Frontmatter Reference section with all available fields
- **Skill Template** - Updated to include new skill frontmatter fields
  - Added Agent-backed template type
  - New fields: `allowed-tools`, `context`, `agent`, `argument-hint`, `hooks`
  - Frontmatter Reference section with all available fields
- **Agent Validator** (`/agent-check`) - Updated validation rules
  - Validates YAML list tools format (not bracket array)
  - Checks `color`, `model` fields
  - Validates `skills` optional fields
  - Auto-fix: Convert bracket array to YAML list, add missing defaults
- **Skill Validator** (`/skill-check`) - Updated validation rules
  - Validates new optional fields: `allowed-tools`, `context`, `agent`, `argument-hint`, `hooks`
  - Validates YAML list format for `allowed-tools`

### Fixed
- **CI Validation** (`validate.yml`)
  - Fixed skill frontmatter extraction to only parse first YAML block (not example blocks)
  - Removed deprecated commands directory check from install test
  - Updated uninstall verification to check skills instead of commands
- **CI Stats Collection** (`collect-stats.yml`)
  - Added proper permissions block
  - Traffic API graceful fallback when token lacks repo scope
  - Support for separate `REPO_STATS_TOKEN` secret

## [1.4.1] - 2026-01-17

### Changed
- **Hooks Structure Cleanup**
  - Renamed `changelog-logger.sh` → `_lib-changelog.sh` (underscore prefix indicates shared library)
  - Updated all hook scripts to reference new library name
  - `install.sh` now properly handles library rename and removes deprecated files
- **Portable Hook Paths** - Per official Claude Code documentation
  - Changed from absolute paths to `$CLAUDE_PROJECT_DIR` environment variable
  - Hooks now use `"$CLAUDE_PROJECT_DIR"/.claude/hooks/...` format
  - Simplified `install.sh` - no longer needs path conversion logic
  - Better portability: projects can be moved without breaking hooks

### Fixed
- **Hooks Guide Compliance** - All hooks now comply with official Claude Code Hooks Guide
  - PreToolUse: `exit 0` (no output) to allow, `exit 2` + stderr to block
  - PreToolUse with context: `{"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": "..."}}`
  - PostToolUse: `exit 0` (no output) - no JSON required
  - Stop hook: `{"decision": "block", "reason": "..."}` to prevent stopping
  - Fixed `tool_output` field name (was incorrectly `tool_response`)
- **Documentation Updates**
  - `changelog/SKILL.md` updated to reflect current hook structure
  - Removed references to deprecated `log-test-result.sh` and `log-commit.sh`
  - Updated architecture diagram with correct hook names
- **Test Updates**
  - Tests updated for new `_lib-changelog.sh` naming
  - Removed outdated `commands/` directory checks
  - Fixed PreToolUse output assertion

### Removed
- **Deprecated Hooks** - `install.sh` now removes during upgrade:
  - `log-commit.sh` (merged into `log-bash-event.sh` in v1.1.0)
  - `log-test-result.sh` (merged into `log-bash-event.sh` in v1.1.0)
  - `changelog-logger.sh` (renamed to `_lib-changelog.sh`)

## [1.4.0] - 2026-01-16

### Added
- **Claude Code 2.1.9+ Support** - Leveraging latest features
  - `${CLAUDE_SESSION_ID}` for session-scoped tracking in all hooks
  - `plansDirectory` setting for centralized plan storage
  - PreToolUse hooks with `additionalContext` for protected file guidance
- **PreToolUse File Validator Hook** (`pre-tool-validator.sh`)
  - Returns guidance context for sensitive files (.env, settings, lockfiles)
  - No blocking, just adds context to help Claude make better decisions
  - Patterns: environment files, credentials, migrations, CI/CD configs
- **Session-Scoped Changelog** - All events now include `session_id`
  - Enables filtering events by session
  - Better multi-session observability

### Changed
- Minimum Claude Code version updated to **2.1.6+** (was 2.1.4+)
- `install.sh` now configures `plansDirectory` setting automatically
- All inline hook fallbacks include session_id for consistency

## [1.3.0] - 2026-01-16

### Added
- **Skills Directory Migration** - Commands migrated to `.claude/skills/` structure
  - All 25 commands now have corresponding `SKILL.md` files
  - Added `user-invocable: true` flag for user-callable skills
  - Simplified SKILL.md files with detailed docs in separate files
  - Skills directory structure: `.claude/skills/[name]/SKILL.md`
  - Backward compatible: `.claude/commands/` still works
- **Context Isolation Pattern** for Self-Evolving agents
  - All 5 Self-Evolving agents now have explicit return format constraints
  - Agents return <100 char summaries, details go to output files
  - Reduces context bloat and prevents compaction
- **First-Run Error Handling** for `/evolving-loop`
  - Safe directory creation with `mkdir -p`
  - Fallback defaults for missing memory files
  - First-run detection with helpful messages
- **Phase Dependency Validation**
  - `validate_phase_prerequisites()` function added
  - Automatic fallback to missing prerequisite phases
  - `validate_checkpoint()` for resume safety
- **VERSION file** for centralized version management
- **DEVELOPMENT-PATTERNS.md** documenting learned best practices
  - Context Isolation Pattern
  - First-Run Error Handling
  - Phase Dependency Validation
  - Memory Persistence Pattern
  - Version Update Checklist
  - Agent Return Format standards

### Fixed
- **Hook path resolution** - install.sh now converts relative hook paths to absolute paths
  - Fixes "No such file or directory" errors when hooks execute
  - Prevents session start/stop failures from unresolved .claude/hooks/* paths
  - Simplified Python configuration script for reliability

## [1.2.0] - 2025-01-13

### Added
- **Observability Changelog System** (Experimental) - Runtime changelog for tracking all development session events
  - **Automatic logging via PostToolUse Hooks** - no manual logging required (hook interface may change)
  - New `/changelog` command for querying session activity
  - New `changelog` skill with JSONL-based event logging
  - Subagent context injection - agents now read recent changelog for context
  - Event types: file_write, file_edit, test_pass, test_fail, test_run, commit
  - Automatic rotation when exceeding 500 lines
  - Archive management (`--archive`, `--list-archives`)
  - Support for filtering, export, and summary statistics
  - Merged bash hooks (log-bash-event.sh) to avoid stdin conflicts
- **Session Conflict Prevention** - Detects interrupted sessions and prompts user
  - `--resume` flag to continue interrupted session
  - `--force` flag to clear old state and start fresh
  - No more stale lock file issues
- Professional README with responsive SVG banner
- Light/dark mode support for banner images
- Comparison table (Traditional vs Director Mode)
- GitHub stars badge
- Examples directory with calculator tutorial
- Comprehensive FAQ documentation
- Documentation section in README

### Fixed
- **stdin conflict** - Merged log-test-result.sh and log-commit.sh into single log-bash-event.sh
  - PostToolUse hooks for same tool share stdin, only one can read it
- **JSON escape** - Added \r, \b, \f character escaping in changelog-logger.sh
- **Python injection** - Fixed auto-loop-stop.sh to use stdin instead of embedding JSON in code
- **Path injection** - Fixed install.sh to use environment variables instead of string interpolation
- **Event type semantics** - Changed file_created → file_write, file_modified → file_edit
  - Write tool can overwrite existing files, so "created" was misleading

### Changed
- `/auto-loop` now logs all TDD phases to changelog for observability
- `code-reviewer` agent now checks changelog for context before review
- `debugger` agent now checks changelog for recent errors and file changes
- Restructured README with HTML tables for better visual hierarchy
- Improved Quick Start section with collapsible details
- Added navigation links to Examples and Documentation

## [1.0.0] - 2025-01-11

### Added

#### Commands (13)
- `/workflow` - Complete 5-step development flow
- `/focus-problem` - Problem analysis with Explore agents
- `/test-first` - TDD: Red-Green-Refactor cycle
- `/smart-commit` - Conventional Commits automation
- `/plan` - Task breakdown and planning
- `/auto-loop` - TDD-based autonomous development loop (Key Feature)
- `/project-init` - Quick project setup with CLAUDE.md
- `/check-environment` - Verify development environment
- `/project-health-check` - 7-point project audit
- `/handoff-codex` - Delegate to Codex CLI
- `/handoff-gemini` - Delegate to Gemini CLI
- `/agents` - List available agents
- `/skills` - List available skills

#### Agents (3)
- `code-reviewer` - Code quality, security, best practices
- `debugger` - Error analysis and fix recommendations
- `doc-writer` - README, API docs, code comments

#### Skills (4)
- `code-reviewer` - Code quality checklist, security review
- `test-runner` - Test automation, TDD support
- `debugger` - 5-step debugging methodology
- `doc-writer` - Documentation templates

#### Infrastructure
- Plugin installation support (`/plugin install`)
- One-liner install script
- Interactive demo script
- CLAUDE.md template
- Automatic backup during installation
- Hooks for Auto-Loop stop detection
- Uninstall script

### Documentation
- README with feature overview
- CLAUDE-TEMPLATE.md for project configuration
- DIRECTOR-MODE-CONCEPTS.md explaining the methodology
- CONTRIBUTING.md for contributors
- CODE_OF_CONDUCT.md
- SECURITY.md for vulnerability reporting
- Issue templates (bug report, feature request, question)
- Pull request template

---

## Version History

| Version | Date | Highlights |
|---------|------|------------|
| 1.8.1 | 2026-07-06 | install --update, evolving scaffolding wired + opt-in hook mode, deep CI frontmatter validation, agent example blocks, interop claude-profile routing |
| 1.8.0 | 2026-07-06 | Full-catalog optimization: spec alignment (v2.1.201, 30 hook events, Claude 5), trigger-rich descriptions, persona consolidation, /handoff-claude multi-account skill, correctness fixes (auto-loop JSON, uninstall data loss, CLI syntax) |
| 1.7.2 | 2026-03-25 | Onboarding skill, spec alignment, CI overhaul, migration guide, expanded FAQ |
| 1.7.1 | 2026-03-14 | Security fix (path leak), install verification script, README badges |
| 1.7.0 | 2026-02-10 | Agent/Skill frontmatter restored & expanded fields, official spec alignment |
| 1.6.0 | 2026-02-10 | Interop Router auto-trigger skill for external CLI routing |
| 1.5.1 | 2026-02-10 | Official Spec Alignment, README Fixes, New Agent/Skill Fields |
| 1.5.0 | 2026-02-10 | Agent Frontmatter Format Upgrade, YAML List Tools |
| 1.4.1 | 2026-01-17 | Hooks Cleanup, Portable Paths ($CLAUDE_PROJECT_DIR), Guide Compliance |
| 1.4.0 | 2026-01-16 | Claude Code 2.1.9+ Support, Session Tracking, PreToolUse Validator |
| 1.3.0 | 2026-01-16 | Skills Directory Migration, Context Isolation, Phase Dependency Validation |
| 1.2.0 | 2025-01-13 | Observability Changelog System, Session Conflict Prevention |
| 1.0.0 | 2025-01-11 | Initial release with 13 commands, 3 agents, 4 skills |

---

## Links

- [GitHub Releases](https://github.com/claude-world/director-mode-lite/releases)
- [Report Issues](https://github.com/claude-world/director-mode-lite/issues)
- [Website](https://claude-world.com)
