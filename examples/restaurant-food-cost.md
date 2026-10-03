# 🏛️ Council Briefing — for the CEO

**Idea:** A subscription app that reads a restaurant's supplier invoices with an LLM and emails the owner a weekly food-cost report with the 3 items that moved most. $49 a month per location, sold to independent restaurants.

**Panel** (domain experts — Restaurant back-office SaaS: AI invoice OCR/extraction and food-cost analytics for independent restaurants (vertical SaaS, SMB)):
- 🍝 Independent restaurant owner-operator (20-year chef-owner) (Claude)
- 🧱 First-Principles Skeptic (Claude)
- 📊 Restaurant tech competitive strategist (ex-MarginEdge/Restaurant365/meez/Craftable product lead) (Codex)
- ✂️ Ruthless Pragmatist (Codex)
- 🧾 Applied ML engineer in document-AI/AP automation (invoice extraction at production scale) (Grok)
- ⚔️ Red-Team Adversary (Grok)

---

## ⚖️ Chair's Briefing

**Convergence**

All six members agree the product as pitched is dead. Owners already know what moved: the rep texts them and they see the price at the dock. Ranking items by percentage change misleads, so any alert has to rank by dollar impact. Invoices show what was bought, not food cost. Getting the invoices in, especially wet paper and texted photos, is the hardest part of the business. Agreement got stronger after debate. In Round 1, members proposed three different fixes. By Round 2, every REWORK vote had settled on one pivot: find supplier billing errors and recover the money.

**Minority report**

The KILL side argues that the pivot is a different company. The ML engineer's case is the strongest. Every rework, including recovery audits, needs exact line items: extended price, unit of measure, pack size and credits. An LLM can invent a unit price that still adds up to the invoice total, so the check passes and the error looks verified. One wrong dollar figure shown to an owner ends the account. The Skeptic adds that when every fix replaces the product, calling it REWORK is just being polite. The REWORK side's answer is fair: neither claim came with benchmarks. But no one disproved them either.

**Verdict movement**

Round 1: REWORK 4, KILL 2. Round 2: REWORK 3, KILL 3. The Skeptic (Claude) moved from REWORK to KILL because every proposed fix replaces the product. In Round 1 the split fell exactly along engine lines, with both Grok members voting KILL. In Round 2 the Codex members still both vote REWORK and the Grok members still both vote KILL. Read the 3-3 as partly a model artifact. The Skeptic's move is the one real signal.

**The decision**

You are not choosing between building and killing the weekly email. Kill it. The real choice is between walking away and running a cheap test of recovering billing errors. I recommend the test: 30 days, one supplier's emailed PDFs, about ten restaurants, people checking every flagged line. Kill it unless confirmed credits per location exceed $49 plus the cost of review time.

One thing would flip this to a full kill, and the room never examined it: whether independents have contract prices at all. Many pay market price without a contract, so "billed above contract" may not exist for them. Check that before spending anything.

---

## 🗣️ The Debate (Round 2 — final positions after deliberation)

### 🍝 Independent restaurant owner-operator (20-year chef-owner) (Claude)
**Defend:** Every member agrees on the same failure. The owner already knows what moved, and an email that changes nothing gets ignored by week three. The one thing I will act on is money owed back to me. After 20 years, I know where the leak is. It isn't market price swings. It's being billed above my contract price, credits for short-shipped cases that never show up, and the same invoice charged twice. A tool that says "Sysco owes you $212, here's the line, call your rep" gets opened every single time.

**Attack:** The Red-Team claims Toast or Sysco will flip on this feature for free. Distributors have no reason to build a tool that flags their own overcharges, and xtraCHEF is a paid add-on, not a free tile. Their incumbent argument kills the weekly digest. It doesn't kill an audit of what the supplier billed me.

**Decide:** I hold REWORK, and I'm dropping my own plate-costing fix. The ML engineer showed that plate costing at $49 is MarginEdge with no human checking the numbers.

POSITION: HOLD REWORK — Sell recovered overcharges, not price movement reports.

### 🧱 First-Principles Skeptic (Claude)
The room agreed with my premise attack, and the chef confirmed it from experience. Owners already know what moved: the rep texts them and they see it at the dock on Tuesday. The idea is built on an information gap that isn't there. Look at what each REWORK in Round 1 actually proposed: plate costing, billing-error recoveries, dollar-ranked alerts. Each one throws out the weekly movers email and builds a different product. When every fix replaces the product, the product is dead. Calling that REWORK is just being polite.

The Ruthless Pragmatist has the weakest reasoning. Their fix, "You paid $85 more for chicken, ask your supplier why," is still information, and it's still homework. The owner already knew about the chicken. Running ten restaurants by hand can show whether people open an email. It can't show they needed one.

The Applied ML engineer's extraction point backs this up but isn't my reason. Even perfect parsing would deliver news the owner already has.

POSITION: UPDATE REWORK->KILL — every rework replaces the product; premise is false

### 📊 Restaurant tech competitive strategist (ex-MarginEdge/Restaurant365/meez/Craftable product lead) (Codex)
DEFEND: The owner sharpens my objection: attention is the scarce resource, so cheaper reporting does not create a competitive wedge. Menu-margin recommendations also expand onboarding into recipes, yields, and POS mapping, importing incumbent complexity at $49. The stronger rework is identifying a billing discrepancy, supplying evidence for a credit request, and tracking whether the credit arrives. That gives owners a reason to renew and a measurable ceiling for acquisition and support costs.

ATTACK: Applied ML engineer has the weakest reasoning: “you will not get that map without distributor EDI” and “frontier vision eats the margin” are asserted without benchmarks. Those claims support narrowing suppliers, measuring review costs, and rejecting uncertain lines, not killing every possible implementation.

DECIDE: HOLD REWORK. Test one supplier and one restaurant segment, measuring confirmed credits, review minutes, and paid renewals. If recoveries cannot cover the fee and support, kill it.

POSITION: HOLD REWORK — Verified recoveries earn renewals; price reports invite cancellation.

### ✂️ Ruthless Pragmatist (Codex)
The owner’s objection strengthens my position: the scarce resource is attention, so delete anything that adds work before proving savings. Start with one supplier’s emailed invoices, a spreadsheet, and human checks on flagged changes. Send only a dollar-impact alert with a specific action. Skip paper capture, dashboards, menu costing, and supplier switching. If a restaurant needs those broader workflows, point it toward the existing products the room identified. The pilot must prove owners act, save money, and renew at $49. Count review time against revenue.

The Applied ML engineer has the weakest reasoning: messy invoices justify narrowing the inputs, not declaring extraction impossible without EDI. “You cannot afford human review” needs measured review time and invoice volume; it cannot serve as its own evidence.

I hold REWORK. The owner out-argued the original email, but nobody established that a tightly scoped service cannot earn its price.

POSITION: HOLD REWORK — Owners must act and renew before software investment

### 🧾 Applied ML engineer in document-AI/AP automation (invoice extraction at production scale) (Grok)
Every fix the room offered still needs a true line item. Dollar rank, an ask-the-supplier alert, and plate margin all need extended price, unit, and pack. Catch-weight says 1 CS and bills pounds. A 6/10 is quantity, pack, or price depending on the read. Credits in pen reverse last week. The model invents a unit price that still foots the total, so your checksum passes and the mover is fake. Rank by dollars and a $4.70 versus $47 slip is the headline. The owner matches one line to the spike and cancels.

The chef-owner's rework is the worst. Plate cost stacks recipes and yields on lines that are already wrong and then states a margin. Louder fiction.

A manual pilot or a recovery audit is a different, pricier AP product. It does not make this $49 email true.

POSITION: HOLD KILL — line-item errors poison every smarter report

### ⚔️ Red-Team Adversary (Grok)
Every rework still dies on capture. Plate cost, dollar ranks, and billing recoveries need correct packs, credits, and stable item names. The operator's invoices are wet dock paper and a texted photo. The ML engineer showed a model can invent a unit price that still nearly matches the total, so the lie looks checked. MarginEdge already ships price movers, and Toast or Sysco can show the same three lines on a screen the owner already opens. $39 of gross profit cannot fund those disputes.

The owner-operator's prescription fights their own evidence. They name MarginEdge and xtraCHEF as plate-cost tools owners already churn off, then ask this email to become plate cost. That is the suite they cancel, and it still needs the 11pm photos they will not take.

Plate costing and recovery audits need distributor feeds and a POS. That is a different company. I hold KILL.
POSITION: HOLD KILL — incumbents own the invoice pipe


