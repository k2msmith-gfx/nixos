---
name: ray-poc-collaboration
description: "How the user wants to collaborate on the ray POC work: stage-by-stage, honest assessments, working code first."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 431dfea2-1a06-416f-bfd1-10c0d0145383
---

Stage-by-stage confirmation before proceeding. Do not start the next stage until the user explicitly moves forward.

**Why:** User said "lets do in stages, starting with 1) and we can run the demo scene and compare" — they want to validate each stage before committing to the next one.
**How to apply:** After completing a stage, summarize what's done and what Stage N+1 would look like. Wait for explicit "go" rather than jumping ahead.

---

User actively wants honest technical opinions, including concerns and hesitations — not just "here's what works."

**Why:** User asked explicitly twice: "what are your conclusions after completing ray-ecl-poc? Are there any concerns/hesitations?" and then the same for ray-steel-poc. They are evaluating which language to commit to for Stage 3+ and need real tradeoffs, not a sales pitch.
**How to apply:** When a POC stage is complete, proactively offer a balanced assessment: what worked well, what the real risks are, what would change for the next stage. Do not soften concerns.

---

User prefers working code over planning docs. When a proposal is discussed and agreed, implement it directly.

**Why:** User's response to the TCP eval server proposal was simply "yes" — no back-and-forth on design. They trust the implementation will happen cleanly.
**How to apply:** When user gives a one-word approval ("yes", "perfect"), proceed with full implementation. Don't re-summarize the plan or ask for clarification on details that can be decided sensibly.
