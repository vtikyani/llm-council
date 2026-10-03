#!/usr/bin/env bash
# llm-council.sh — throw an idea, get it stress-tested by a 6-persona adversarial
# council that DELIBERATES, then reports to you (the CEO) without forced consensus.
#
# Three engines, two seats each (Claude/Codex/Grok). Model diversity is the
# point: three different families disagree in ways three personas on one model
# can't. Kimi was dropped 2026-08-31 (subscription lapsed, the binary hangs).
# Generalist seats are deliberately spread across DIFFERENT engines so a
# model-family bias can't line up with a persona-class bias.
#
# Flow:
#   Round 1  — 6 personas give independent takes (2 per engine).
#   Round 2  — each persona sees the whole room, makes its strongest case, attacks
#              the weakest reasoning, and HOLDS or UPDATES its verdict. No pressure
#              to agree — a well-argued dissent beats false consensus.
#   Briefing — the Chair files a CEO briefing: convergence + minority report +
#              verdict movement + the decision you actually face.
#
# Usage:
#   llm-council.sh "my idea here"      (idea via arg or stdin; URLs auto-fetched)
#   echo "my idea" | llm-council.sh
#
# Output: markdown to stdout.

set -uo pipefail

IDEA="${*:-}"
if [ -z "$IDEA" ]; then IDEA="$(cat)"; fi
if [ -z "${IDEA// /}" ]; then echo "No idea provided." >&2; exit 1; fi

CLAUDE_MODEL="${COUNCIL_CLAUDE_MODEL:-opus}"
# Absolute paths: this runs under launchd/router where PATH is minimal.
GROK_BIN="${COUNCIL_GROK_BIN:-$HOME/.grok/bin/grok}"
command -v claude >/dev/null || { echo "llm-council needs the claude CLI (Claude Code) on PATH." >&2; exit 1; }
# Codex and Grok seats fall back to Claude when their CLI is missing, so the council
# still runs with one engine; the labels say which seats were substituted.
HAVE_CODEX="$(command -v codex || true)"
[ -x "$GROK_BIN" ] || GROK_BIN="$(command -v grok || true)"
HAVE_GROK="$GROK_BIN"
[ -z "$HAVE_CODEX" ] && echo "codex CLI not found: seats 3-4 run on Claude." >&2
[ -z "$HAVE_GROK" ] && echo "grok CLI not found: seats 5-6 run on Claude." >&2
WORK="$(mktemp -d /tmp/council.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

# Seats. Index → engine mapping lives in ask(); every loop iterates $SEATS so
# resizing the panel is a one-line change.
SEATS="1 2 3 4 5 6"

# --- URL auto-fetch: enrich the idea with real facts before anyone reasons ---
# The personas are pure reasoners with no web access. If the idea contains URLs,
# fetch each (plain curl by default; set COUNCIL_FETCH_CMD to a command that takes a URL and
# prints page text, e.g. a headless-browser CLI for JS or login pages), summarize to a fact block with haiku, and feed it in as ground truth. Without
# this, a bare URL gets critiqued blind. Capped at 3 URLs; every step is guarded
# so a slow/dead fetch degrades gracefully to "council on the raw idea".
fetch_url() { # $1=url -> page text on stdout
  if [ -n "${COUNCIL_FETCH_CMD:-}" ]; then
    $COUNCIL_FETCH_CMD "$1"
  else
    curl -sL --max-time 25 -A "Mozilla/5.0 llm-council" "$1" \
      | python3 -c 'import sys,re,html; t=sys.stdin.read(); t=re.sub(r"(?is)<(script|style|noscript)[^>]*>.*?</\1>"," ",t); t=re.sub(r"(?s)<[^>]+>"," ",t); print(re.sub(r"\s+"," ",html.unescape(t)).strip())'
  fi
}
FACTS=""
URLS="$(printf '%s' "$IDEA" | grep -oE 'https?://[^ )>"]+' | head -3)"
if [ -n "$URLS" ]; then
  echo "Auto-fetching $(printf '%s\n' "$URLS" | grep -c .) URL(s) for ground truth..." >&2
  while IFS= read -r url; do
    [ -z "$url" ] && continue
    raw="$(fetch_url "$url" 2>/dev/null | head -c 12000)"
    [ -z "$raw" ] && { echo "  fetch failed: $url" >&2; continue; }
    summary="$(printf 'Summarize this page factually for an idea-critique council. Cover: what it is, what it does, key facts/numbers, business model, stated limitations. Concrete, ~150 words, no fluff.\n\nPAGE:\n%s' "$raw" \
      | claude -p --model haiku 2>/dev/null)"
    [ -n "$summary" ] && FACTS+="
FACTS ABOUT $url:
$summary
"
  done <<< "$URLS"
fi

# IDEA_CTX is what the personas actually reason over: the raw idea plus any
# auto-fetched facts. The display header still shows the raw idea.
IDEA_CTX="$IDEA"
[ -n "$FACTS" ] && IDEA_CTX="$IDEA

--- RESEARCHED CONTEXT (auto-fetched from the URL(s) above; treat as ground truth) ---$FACTS"

# --- Personas --------------------------------------------------------------
# Index → engine: 1-2 Claude, 3-4 Codex, 5-6 Grok (ask() routes by index).
#
# The panel is domain-adaptive: a dispatcher designs 3 EXPERT personas matched to
# THIS idea, paired with 3 fixed GENERALIST seats (First-Principles Skeptic,
# Ruthless Pragmatist, Red-Team Adversary) that catch the obvious-failure modes
# domain experts tunnel past. Every engine gets exactly one expert and one
# generalist, so no model family owns a persona class. If the dispatcher fails,
# we fall back to 6 of the generalist personas below.

# Generalist personas — the fallback panel + the source of the 2 fixed seats.
G1="ROLE: First-Principles Skeptic. Attack the PREMISE. Does this problem actually exist, and is it worth solving? Is the stated need real or assumed? Strip every assumption to bedrock and check if the foundation holds."
G2="ROLE: Red-Team Adversary. Steelman the strongest case for why this DIES. What's the single thing most likely to kill it? Where is it most fragile to competition, abuse, or a smarter incumbent move?"
G3="ROLE: Market Realist. Who exactly uses this, and will they actually adopt/pay/care? Attack distribution, willingness-to-pay, switching cost, and 'so what' factor. Nice-to-have or painkiller?"
G4="ROLE: Staff Engineer. Attack technical feasibility and TRUE cost. What's the hidden complexity, the part that's 10x harder than it looks, the ongoing maintenance tax, the scaling cliff? What breaks at the edges?"
G5="ROLE: Ruthless Pragmatist. Propose the simplest 80/20 alternative that gets most of the value for a fraction of the effort. What should be DELETED from this idea? Is there an off-the-shelf thing that already does this?"
G6="ROLE: Pre-Mortem Coroner. It's 6 months later and this idea SHIPPED and FAILED. Write the autopsy: the top 2-3 root causes of death, in past tense, as if they already happened."
G7="ROLE: Second-Order Effects Analyst. Assume it WORKS. Now attack what success itself breaks: what does it attract (competitors, abuse, scrutiny), what does it obligate forever, what incentive does it quietly create, and what does it make harder to change later? The failure mode you hunt is the win that costs more than the loss."
G8="ROLE: Evidence Auditor. Attack the EVIDENCE, not the conclusion. Where do the numbers come from, and is the sample the biggest one available or just the one at hand? Name the selection, survivorship, and multiple-testing bias. Would this survive a shuffled-label test, and is the headline metric the one that actually pays (EV, not hit rate)? If the claim rests on a pattern someone just noticed, say so."

# --- Dispatcher: design a domain-expert panel for THIS specific idea --------
DISPATCH_MODEL="${COUNCIL_DISPATCH_MODEL:-sonnet}"
DISPATCH_SCHEMA='{"type":"object","properties":{"domain":{"type":"string"},"experts":{"type":"array","minItems":3,"maxItems":3,"items":{"type":"object","properties":{"emoji":{"type":"string"},"title":{"type":"string"},"role":{"type":"string"}},"required":["emoji","title","role"]}}},"required":["domain","experts"]}'
DISPATCH_PROMPT="You are assembling an expert review panel to stress-test the idea below. Identify its real domain, then design THREE distinct expert personas who are the most qualified specialists to expose THIS idea's actual flaws — the reviewers its author would most fear. Requirements:
- Specific, not generic: e.g. 'Quant researcher who has run live stat-arb books and knows multiple-testing bias cold', NOT 'finance expert'. Naming a real archetype/practitioner style is good.
- Diverse vantage points: three genuinely different angles, not three flavors of the same expert. If two would say the same thing, replace one.
- Each 'role' is a 1-2 sentence instruction to that persona about exactly what to scrutinize from their expertise.
- Pick a fitting emoji per expert.
Return JSON only.

IDEA:
$IDEA_CTX"

echo "Dispatcher: matching a domain-expert panel to the idea..." >&2
printf '%s' "$DISPATCH_PROMPT" \
  | claude -p --model "$DISPATCH_MODEL" --output-format json --json-schema "$DISPATCH_SCHEMA" \
  > "$WORK/dispatch.json" 2>/dev/null

# Pull the schema-conforming object out of the CLI envelope (.structured_output).
EXPERTS_TSV="$(python3 - "$WORK/dispatch.json" <<'PY' 2>/dev/null
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    so = d.get("structured_output") or {}
    for e in (so.get("experts") or [])[:3]:
        em = (str(e.get("emoji", "")).strip() or "🎓")
        ti = str(e.get("title", "Domain Expert")).replace("\t", " ").replace("\n", " ").strip()
        ro = str(e.get("role", "")).replace("\t", " ").replace("\n", " ").strip()
        if ti:
            print(f"{em}\t{ti}\t{ro}")
except Exception:
    pass
PY
)"
DOMAIN="$(python3 - "$WORK/dispatch.json" <<'PY' 2>/dev/null
import json, sys
try:
    print((json.load(open(sys.argv[1])).get("structured_output") or {}).get("domain", "").strip())
except Exception:
    pass
PY
)"

# Load experts into parallel arrays (bash 3.2-safe — no mapfile).
EXP_EMOJI=(); EXP_TITLE=(); EXP_ROLE=()
while IFS=$'\t' read -r em ti ro; do
  [ -z "${ti:-}" ] && continue
  EXP_EMOJI+=("$em"); EXP_TITLE+=("$ti"); EXP_ROLE+=("$ro")
done <<< "$EXPERTS_TSV"

expert_persona() { # $1 = 0-based index into EXP_* → emits a ROLE prompt
  printf 'ROLE: %s. %s Judge the idea with the standards, rigor, and known failure modes of your field — surface the domain-specific flaws a generalist would miss. Concrete and brutally honest.' \
    "${EXP_TITLE[$1]}" "${EXP_ROLE[$1]}"
}

if [ "${#EXP_TITLE[@]}" -ge 3 ]; then
  PANEL_MODE="domain experts${DOMAIN:+ — $DOMAIN}"
  LABELS=( "" \
    "${EXP_EMOJI[0]} ${EXP_TITLE[0]} (Claude)" \
    "🧱 First-Principles Skeptic (Claude)" \
    "${EXP_EMOJI[1]} ${EXP_TITLE[1]} (Codex)" \
    "✂️ Ruthless Pragmatist (Codex)" \
    "${EXP_EMOJI[2]} ${EXP_TITLE[2]} (Grok)" \
    "⚔️ Red-Team Adversary (Grok)" )
  PERSONAS=( "" \
    "$(expert_persona 0)" \
    "$G1" \
    "$(expert_persona 1)" \
    "$G5" \
    "$(expert_persona 2)" \
    "$G2" )
else
  PANEL_MODE="generalist (dispatcher fallback)"
  LABELS=( "" \
    "🧱 First-Principles Skeptic (Claude)" \
    "⚔️ Red-Team Adversary (Claude)" \
    "📊 Market Realist (Codex)" \
    "🔧 Staff Engineer (Codex)" \
    "✂️ Ruthless Pragmatist (Grok)" \
    "⚰️ Pre-Mortem Coroner (Grok)" )
  PERSONAS=( "" "$G1" "$G2" "$G3" "$G8" "$G5" "$G6" )
fi
for i in 3 4; do [ -z "$HAVE_CODEX" ] && LABELS[$i]="${LABELS[$i]/(Codex)/(Claude, sub for Codex)}"; done
for i in 5 6; do [ -z "$HAVE_GROK" ] && LABELS[$i]="${LABELS[$i]/(Grok)/(Claude, sub for Grok)}"; done
echo "Panel: $PANEL_MODE" >&2

# --- Engine runners (generic: take an outfile + a full prompt) --------------
ask_claude() { # $1=outfile  $2=prompt
  printf '%s' "$2" | claude -p --model "$CLAUDE_MODEL" > "$1" 2>"$1.err" \
    || echo "[claude error] $(tail -1 "$1.err" 2>/dev/null)" > "$1"
}
ask_codex() {  # $1=outfile  $2=prompt
  codex exec --skip-git-repo-check --ephemeral -s read-only -o "$1" "$2" \
    < /dev/null > "$1.log" 2>&1 \
    || echo "[codex error] see $1.log" > "$1"
}
ask_grok() {   # $1=outfile  $2=prompt
  # --cwd "$WORK" pins grok to the scratch dir: it can't read a project's
  # AGENTS.md (which would overwrite the persona with the project's agent) and has nothing
  # to damage. Council members reason; they don't need tools, the web, or agents.
  "$GROK_BIN" -p "$2" --cwd "$WORK" --disable-web-search --no-subagents \
    --no-plan --max-turns 6 > "$1" 2>"$1.err" \
    || echo "[grok error] $(tail -1 "$1.err" 2>/dev/null)" > "$1"
}
ask() { # $1=index  $2=outfile  $3=prompt   — routes by index to the right engine
  case "$1" in
    1|2) ask_claude "$2" "$3" ;;
    3|4) if [ -n "$HAVE_CODEX" ]; then ask_codex "$2" "$3"; else ask_claude "$2" "$3"; fi ;;
    *)   if [ -n "$HAVE_GROK" ]; then ask_grok "$2" "$3"; else ask_claude "$2" "$3"; fi ;;
  esac
}

# ============================================================================
# ROUND 1 — independent takes
# ============================================================================
FRAME1="You are one member of an adversarial LLM council whose JOB is to STRESS-TEST an idea before its author (the CEO) wastes resources on it. Be brutally honest, specific, and concrete. No hedging, no participation-trophy praise. If it genuinely survives YOUR lens, say so briefly and why; otherwise attack with concrete failure modes, not vibes. Plain prose: short words, active voice, no em-dashes, no stock phrases. Max ~180 words. End with one line: VERDICT: KILL | REWORK | SHIP and a 6-word reason."

echo "Convening the council (Round 1: independent takes)..." >&2
for i in $SEATS; do
  prompt="$(printf '%s\n\n%s\n\nIDEA TO STRESS-TEST:\n%s\n' "$FRAME1" "${PERSONAS[$i]}" "$IDEA_CTX")"
  ask "$i" "$WORK/r1.$i" "$prompt" &
done
wait

# Assemble the full Round-1 transcript (every persona sees this in Round 2).
R1=""
for i in $SEATS; do
  R1+="### ${LABELS[$i]}
$(cat "$WORK/r1.$i" 2>/dev/null)

"
done

# ============================================================================
# ROUND 2 — deliberation / debate (each persona sees the whole room)
# ============================================================================
FRAME2="You are the council member below. Round 1 is done — every member's independent take is in the transcript. This is ROUND 2: deliberation, not repetition. Do these three things, tightly:
1. DEFEND — make your single STRONGEST argument for your position, sharpened by what the room said.
2. ATTACK — name the member with the weakest or most wrong reasoning and dismantle it in 1-2 sentences.
3. DECIDE — HOLD your verdict or UPDATE it. Change your mind if someone genuinely out-argued you; intellectual honesty over ego. There is NO requirement to reach consensus — a well-argued dissent is more valuable than false agreement.
Be concise (~150 words), plain prose, no em-dashes. End with EXACTLY one line:
POSITION: HOLD <KILL|REWORK|SHIP> — <8-word reason>
or
POSITION: UPDATE <OLD>->-<NEW> — <8-word reason>"

echo "Round 2: deliberation..." >&2
for i in $SEATS; do
  prompt="$(printf '%s\n\nYOU ARE: %s\nYour own Round-1 take is the one labeled "%s" below.\n\nIDEA UNDER REVIEW:\n%s\n\n--- FULL ROUND-1 TRANSCRIPT ---\n%s' \
    "$FRAME2" "${PERSONAS[$i]}" "${LABELS[$i]}" "$IDEA_CTX" "$R1")"
  ask "$i" "$WORK/r2.$i" "$prompt" &
done
wait

# Assemble Round-2 final positions.
R2=""
for i in $SEATS; do
  R2+="### ${LABELS[$i]}
$(cat "$WORK/r2.$i" 2>/dev/null)

"
done

# ============================================================================
# CHAIR — CEO briefing (surfaces dissent; does NOT force consensus)
# ============================================================================
CHAIR_PROMPT="You are the Chair of an adversarial council reporting to the CEO after a two-round deliberation. Your job is NOT to manufacture consensus — it is to give the CEO the sharpest possible picture INCLUDING genuine disagreement, so the CEO can decide. Read both rounds, then write the briefing:

1. CONVERGENCE — what the room agrees on AFTER debate. Note whether agreement strengthened or cracked vs Round 1.
2. MINORITY REPORT — the strongest dissent still standing after the debate, named and argued in its best form. If the room is truly unanimous, say so explicitly and judge whether that's genuine robustness or a shared blind spot.
3. VERDICT MOVEMENT — Round-1 tally vs Round-2 tally; name who moved and why.
4. THE DECISION — the actual fork the CEO faces, your single recommendation, and the one thing that would flip it. The CEO decides; do not rubber-stamp.

Terse and direct, ~320 words, plain prose, no em-dashes. No preamble. Six members voted: give exact tallies, and if a split falls along engine lines (Claude/Codex/Grok), say so, because that is a model artifact and not a signal.

IDEA:
$IDEA_CTX

--- ROUND 1 (independent) ---
$R1
--- ROUND 2 (after debate) ---
$R2"

echo "Chair: drafting the CEO briefing..." >&2
CHAIR="$(printf '%s' "$CHAIR_PROMPT" | claude -p --model "$CLAUDE_MODEL" 2>/dev/null)"

# Panel roster for the header.
PANEL_DESC=""
for i in $SEATS; do PANEL_DESC+="- ${LABELS[$i]}
"; done

# --- Final output ----------------------------------------------------------
cat <<EOF
# 🏛️ Council Briefing — for the CEO

**Idea:** $IDEA

**Panel** (${PANEL_MODE}):
$PANEL_DESC
---

## ⚖️ Chair's Briefing

$CHAIR

---

## 🗣️ The Debate (Round 2 — final positions after deliberation)

$R2
EOF
