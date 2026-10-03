# llm-council

Stress-test an idea before you spend time building it. Six AI reviewers, two each on Claude, Codex, and Grok, attack the idea from different angles, argue with each other in a second round, and a chair writes a short briefing with the vote, the strongest dissent, and the one decision you actually face.

```bash
./council.sh "A subscription app that reads a restaurant's supplier invoices with an LLM and emails the owner a weekly food-cost report. \$49 a month per location."
```

Full output from that run: [`examples/restaurant-food-cost.md`](examples/restaurant-food-cost.md). The vote went from 4 REWORK and 2 KILL in round 1 to a 3 and 3 split after debate, and the chair found the one unexamined assumption that would kill the pivot outright.

## How it works

1. **Dispatcher.** One model call reads the idea, names its real domain, and designs three expert reviewers for it (for the example: a 20-year restaurant owner, an ex-MarginEdge product lead, and an invoice-extraction ML engineer).
2. **Panel.** Each engine gets one domain expert and one fixed generalist (First-Principles Skeptic, Ruthless Pragmatist, Red-Team Adversary). No model family owns a type of reviewer, so a bias in one model can't pass for reviewers agreeing.
3. **Round 1.** All six answer independently and in parallel, each ending with `VERDICT: KILL | REWORK | SHIP`.
4. **Round 2.** Each reviewer reads the whole room, defends its strongest point, attacks the weakest argument it sees, and holds or changes its verdict. Consensus is not required.
5. **Chair.** Writes the briefing: what the room agrees on, the strongest dissent still standing, how the votes moved, and the decision with the one thing that would flip it. It flags any split that falls along engine lines as a model artifact, not a signal.

URLs in the idea are fetched and summarized first, so the panel reasons over the page's facts instead of a bare link.

## Setup

Requires `bash`, `python3`, `curl`, and the [Claude Code CLI](https://docs.claude.com/en/docs/claude-code) logged in. The [Codex CLI](https://github.com/openai/codex) and the Grok CLI are optional: when either is missing, its two seats run on Claude and the labels say so.

```bash
./council.sh "your idea"            # or: echo "your idea" | ./council.sh
```

Output is markdown on stdout; progress goes to stderr.

| Variable | Default | Purpose |
| --- | --- | --- |
| `COUNCIL_CLAUDE_MODEL` | `opus` | Claude reviewers and the chair. `haiku` for a cheap smoke test. |
| `COUNCIL_GROK_BIN` | `~/.grok/bin/grok`, then `grok` on PATH | Grok CLI path. |
| `COUNCIL_FETCH_CMD` | `curl` plus tag stripping | A command that takes a URL and prints page text, for JS-heavy or login pages. |

Codex uses the model set in your `~/.codex/config.toml`.

## License

MIT
