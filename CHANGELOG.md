# Changelog

All notable changes to Director Mode Lite will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
| 1.4.0 | 2026-01-16 | Claude Code 2.1.9+ Support, Session Tracking, PreToolUse Validator |
| 1.3.0 | 2026-01-16 | Skills Directory Migration, Context Isolation, Phase Dependency Validation |
| 1.2.0 | 2025-01-13 | Observability Changelog System, Session Conflict Prevention |
| 1.0.0 | 2025-01-11 | Initial release with 13 commands, 3 agents, 4 skills |

---

## Links

- [GitHub Releases](https://github.com/claude-world/director-mode-lite/releases)
- [Report Issues](https://github.com/claude-world/director-mode-lite/issues)
- [Website](https://claude-world.com)
