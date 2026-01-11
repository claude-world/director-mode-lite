#!/bin/bash
# Director Mode Lite - Demo Script
# Quick demonstration of Director Mode features

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Demo directory
DEMO_DIR="${1:-$HOME/director-mode-demo}"

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          Director Mode Lite - Interactive Demo             ║${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}║  Use Claude Code like a Director, not a Programmer         ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Create demo project
echo -e "${YELLOW}Step 1: Creating demo project...${NC}"
echo "────────────────────────────────"

if [[ -d "$DEMO_DIR" ]]; then
    echo -e "  ${YELLOW}Demo directory already exists: $DEMO_DIR${NC}"
    read -p "  Remove and recreate? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$DEMO_DIR"
    else
        echo -e "  ${RED}Aborted.${NC}"
        exit 1
    fi
fi

mkdir -p "$DEMO_DIR"
cd "$DEMO_DIR"

# Initialize npm project
cat > package.json << 'EOF'
{
  "name": "director-mode-demo",
  "version": "1.0.0",
  "description": "Demo project for Director Mode Lite",
  "main": "index.js",
  "scripts": {
    "test": "node --test",
    "lint": "echo 'Linting...' && exit 0"
  }
}
EOF

echo -e "  ${GREEN}✓ Created demo project at: $DEMO_DIR${NC}"
echo ""

# Step 2: Install Director Mode Lite
echo -e "${YELLOW}Step 2: Installing Director Mode Lite...${NC}"
echo "────────────────────────────────────────"

# Clone if not exists
LITE_DIR="/tmp/director-mode-lite-$$"
git clone --depth 1 https://github.com/claude-world/director-mode-lite.git "$LITE_DIR" 2>/dev/null

# Run install
"$LITE_DIR/install.sh" "$DEMO_DIR"

# Cleanup
rm -rf "$LITE_DIR"

echo ""

# Step 3: Verify installation
echo -e "${YELLOW}Step 3: Verifying installation...${NC}"
echo "──────────────────────────────────"

echo ""
echo "  Checking installed components:"
echo ""

# Check commands
CMD_COUNT=$(find .claude/commands -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
echo -e "  ${GREEN}✓${NC} Commands: ${CYAN}$CMD_COUNT${NC} installed"

# List command categories
echo "    ├── workflow/     (5 commands)"
echo "    ├── automation/   (1 command - Auto-Loop)"
echo "    ├── diagnostics/  (1 command)"
echo "    ├── setup/        (2 commands)"
echo "    ├── interop/      (2 commands)"
echo "    └── agents.md, skills.md"

# Check agents
AGENT_COUNT=$(find .claude/agents -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
echo -e "  ${GREEN}✓${NC} Agents:   ${CYAN}$AGENT_COUNT${NC} installed"
echo "    ├── code-reviewer"
echo "    ├── debugger"
echo "    └── doc-writer"

# Check skills
SKILL_COUNT=$(ls -d .claude/skills/*/ 2>/dev/null | wc -l | tr -d ' ')
echo -e "  ${GREEN}✓${NC} Skills:   ${CYAN}$SKILL_COUNT${NC} installed"
echo "    ├── code-reviewer"
echo "    ├── debugger"
echo "    ├── doc-writer"
echo "    └── test-runner"

# Check hooks
if [[ -f .claude/hooks.json ]]; then
    echo -e "  ${GREEN}✓${NC} Hooks:    Auto-Loop Stop Hook"
fi

echo ""

# Step 4: Show available commands
echo -e "${YELLOW}Step 4: Available Commands${NC}"
echo "───────────────────────────"
echo ""
echo -e "  ${CYAN}Workflow Commands:${NC}"
echo "    /workflow           Complete 5-step development flow"
echo "    /focus-problem      Problem analysis with Explore agents"
echo "    /test-first         TDD: Red-Green-Refactor cycle"
echo "    /smart-commit       Conventional Commits automation"
echo "    /plan               Task breakdown and planning"
echo ""
echo -e "  ${CYAN}Automation:${NC}"
echo "    /auto-loop          TDD-based autonomous loop (★ Key Feature)"
echo ""
echo -e "  ${CYAN}Diagnostics:${NC}"
echo "    /project-health-check   7-point project audit"
echo ""
echo -e "  ${CYAN}Setup:${NC}"
echo "    /project-init       Quick project setup with CLAUDE.md"
echo "    /check-environment  Verify development environment"
echo ""
echo -e "  ${CYAN}Multi-CLI:${NC}"
echo "    /handoff-codex      Delegate to Codex CLI"
echo "    /handoff-gemini     Delegate to Gemini CLI"
echo ""
echo -e "  ${CYAN}Info:${NC}"
echo "    /agents             List available agents"
echo "    /skills             List available skills"
echo ""

# Step 5: Demo suggestions
echo -e "${YELLOW}Step 5: Try It Out!${NC}"
echo "────────────────────"
echo ""
echo "  Start Claude Code in the demo directory:"
echo ""
echo -e "    ${GREEN}cd $DEMO_DIR${NC}"
echo -e "    ${GREEN}claude${NC}"
echo ""
echo "  Then try these commands:"
echo ""
echo -e "    ${CYAN}1. Basic workflow:${NC}"
echo "       /workflow"
echo ""
echo -e "    ${CYAN}2. Auto-Loop demo (★ Recommended):${NC}"
echo '       /auto-loop "Create a calculator module'
echo ''
echo '       Acceptance Criteria:'
echo '       - [ ] add(a, b) function'
echo '       - [ ] subtract(a, b) function'
echo '       - [ ] Unit tests"'
echo ""
echo -e "    ${CYAN}3. Check project health:${NC}"
echo "       /project-health-check"
echo ""

# Final message
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    Demo Ready!                             ║${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}║  Project: $DEMO_DIR${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}║  Questions? Join https://claude-world.com                  ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
