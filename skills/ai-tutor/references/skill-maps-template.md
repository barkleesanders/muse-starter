# Skill-maps registry — template

Copy this file to `state/skill-maps.md` in the ai-tutor skill's
directory and keep it updated in place. This registry is what makes
the tutoring loop recursive across sessions: levels earned last month
are re-tested, not trusted forever.

Rules (from SKILL.md):

- One block per tutored skill, updated in place — never a second block
  for the same skill.
- A map whose last full assessment is 60+ days old is reported
  UNVERIFIED, whatever it says, until a spaced-review re-test lands.
- A failed spaced-review re-test lowers the recorded level on the
  spot; the registry never shows a level the latest probe contradicts.

Block format:

```
## <skill-name>
Last tutored: YYYY-MM-DD · Last full assessment: YYYY-MM-DD · Target: 4 (5 if safety-adjacent)
Skill: <name>                             overall: ######.... 58%
-----------------------------------------------------------------
trigger precision     [########..]  4/5  * independent
failure handling      [######....]  3/5  <- current focus
boundary discipline   [##........]  1/5
-----------------------------------------------------------------
Notes: <what the last run changed, which probes are owed, NOT LIVE-PROVEN items>
```

The bar is 10 cells, 2 per level. `* independent` marks a
sub-capability verified by an unprompted probe; `<- current focus`
marks the weakest sub-capability the loop is working.

---

<!-- Tutored skills begin below this line. -->
