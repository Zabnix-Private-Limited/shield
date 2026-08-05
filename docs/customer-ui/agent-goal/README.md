# SHIELD Customer UI Completion Goal Package

This package is designed to be handed to a new Codex/engineering-agent goal for completing the entire SHIELD customer-facing Flutter interface inside the existing repository.

## Repository and reference paths

- Repository: `E:\K4NN4N\shield`
- Approved visual references: `E:\K4NN4N\shield\Design reference`
- Active customer route family: `/portal/customer/:section`

## How to use

### Preferred multi-file method

1. Copy this complete folder into the repository, for example:
   `E:\K4NN4N\shield\docs\customer-ui\agent-goal`
2. Set `01_GOAL_OBJECTIVE.md` as the goal objective.
3. Tell the agent to read every Markdown and CSV file in this package before editing.
4. Keep `03_CUSTOMER_SCREEN_COMPLETION_MATRIX.csv` as the live completion tracker.

### Single-prompt method

Use `FULL_SINGLE_PROMPT.md` as the goal objective when the tool accepts only one large prompt.

## Authority warning

The old AI-generated design ZIPs, contact sheets, posters and synthetic screen packs are obsolete as visual authorities. The only approved visual references are the images in `E:\K4NN4N\shield\Design reference`. The repository and current database/API implementation remain the functional authority.

## Included files

- `00_READ_FIRST.md` — mandatory preamble and source-of-truth rules
- `01_GOAL_OBJECTIVE.md` — primary detailed goal
- `02_CURRENT_STATE_HANDOFF.md` — known implementation state and recent changes
- `03_CUSTOMER_SCREEN_COMPLETION_MATRIX.md` — complete human-readable screen inventory
- `03_CUSTOMER_SCREEN_COMPLETION_MATRIX.csv` — agent-editable tracking matrix
- `04_ROUTE_DATA_AND_SECURITY_GUIDE.md` — route, API, persistence and authorization rules
- `05_DESIGN_SYSTEM_AND_VISUAL_RULES.md` — approved visual language and carousel exception
- `06_COMPONENT_ARCHITECTURE.md` — reusable Flutter component requirements
- `07_TESTING_VISUAL_QA_AND_ACCEPTANCE.md` — test and screenshot-verification contract
- `08_EXECUTION_PHASES_AND_REPORTING.md` — phased work plan, checkpoints and reporting
- `09_OPEN_BUSINESS_RULES.md` — rules the agent must not invent
- `10_FINAL_DEFINITION_OF_DONE.md` — final completion gates
- `FULL_SINGLE_PROMPT.md` — all instructions consolidated into one prompt
