# Resumable research through Muse

Use when this research skill runs in Muse, is handed to Muse from another client, or continues after a dropped UI/transport observation. Keep the existing research method, source standards, account boundaries and output requirements. This is a recovery protocol, not a new monitor, agent or network repair.

## Before work or handoff

- Keep one existing owner and one existing issue in your task tracker as the task of record. Record the exact research question, sub-questions, requested output, allowed sources/actions and explicit stop conditions there. A research permission does not authorize contact, publication, paid runs or new access.
- Assign one correlation label for the research artifacts, preferably based on the existing issue. Distinguish that local label from an official Muse task/run ID: save only IDs actually returned by the current runtime. Keep the exact existing conversation URL and any real process session, browser task, research agent or scheduled-run handle. Never invent a status/get/resume API or imply the dispatch-only MCP exposes one.
- Choose a private, persistent workspace artifact directory on the executing host. Keep existing auth on its owning host. Ordinary search uses the installed local engine; a second machine's remote shell is not a prerequisite. Preserve working browser sessions; do not move cookies or tokens to recover a slow route.
- The handoff brief names the existing issue/correlation label, scope, output directory and return contract: retain runtime handles; save source artifacts and checkpoints; return actual terminal status, coverage and output path. Do not ask Muse to create a second task/agent/watchdog merely to watch the first.
- Treat an accepted message or dispatch acknowledgment as submission only. If submission is uncertain, inspect the existing message/task before sending anything again. The bridge's temporary duplicate guard is not a durable task ledger. Never identify an unrelated latest chat bubble as this research's result.

## Bounded research and artifact checkpoints

Divide work by sub-question into bounded batches that can finish within the current runtime's documented tool limits. Preserve the existing provider router/failover; do not add another all-provider health sweep, unbounded parallel fan-out or restart loop. Use one active writer per research artifact directory. Before a long call, persist its intended query and any returned runtime handle. An observation timeout is not a command's terminal outcome.

After each completed batch, atomically replace a private `resume.json` and append or update source artifacts. Use a same-directory private temporary file, flush it, and replace the checkpoint only after validation. Keep the prior checkpoint if parsing or validation fails. Checkpoint fields:

- schema version, correlation label and owning tracker issue;
- exact scope and output contract, plus its version/hash so a changed request cannot silently reuse old conclusions;
- actual conversation URL and runtime handles (or explicit unavailable values);
- completed query/batch identifiers with provider and execution/retrieval times;
- source inventory: actual URL, retrieved time, saved artifact path/hash, full versus partial text, and access/coverage limitations;
- claim evidence/classification and unfinished source-verification gaps;
- one concrete next read or synthesis step, plus any blocked dependency;
- current report/draft artifact path, size/hash and whether synthesis/verification is incomplete.

This JSON is research continuity data, not a second task tracker or a behavioral-memory store. Keep task ownership/status in the tracker. Generate timestamps from system UTC at write time. Exclude credentials, cookies, OTPs and unrelated personal files. Do not convert a partly written report into a completed deliverable because the filename exists.

## Reconnect or resume the same work

1. Read the owning issue and last valid checkpoint before restarting searches. Inspect the current runtime's documented state once for the exact saved handle. Keep running, waiting-for-approval, interrupted, failed, completed, unknown and delivery-unverified distinct.
2. If a process is still live, poll/read its buffered output by the original session handle. If a browser task is waiting, continue its same task ID with only the missing detail. If an agent is interrupted, use resume only when the current tool contract permits that owner/type and state. A terminal agent is not resumed as though interrupted. No observed state means unknown, not dead.
3. For native `browser.deep_research`, the returned agent ID/folder is an acknowledgment. Follow its current runtime handoff contract; do not read its research folder before the terminal handoff. Keep the parent checkpoint outside any worker-owned folder that is not yet readable. Do not call subagent resume on browser-task owners when their contract requires browser continuation.
4. If execution ended, validate saved batch artifacts and continue from the checkpoint's first unfinished gap in the same issue. Reuse verified source reads within their actual freshness/scope limits; re-fetch only changed, stale, partial or failed inputs. Do not repeat the whole assignment just because the UI disconnected. Missing or corrupt checkpoints require evidence reconstruction from supported history/artifacts; never silently reset to an empty successful run.
5. If a paid or mutating operation may have been accepted, inspect its original run/effects before retry. Ordinary read retries are bounded and justified by the specific failed batch, not permission to resubmit the entire task. Existing provider failover owns quota handling. Preserve pagination and source-coverage limits.
6. When retrieval itself is unsupported, report delivery-unverified with the exact task/conversation pointer and missing evidence. Keep independent verified work, rather than claiming failure, completion or a new result from a generic acknowledgment.

## Completion and progress

A terminal runtime status establishes execution state, not research quality. Completion additionally needs the actual saved report/result, readable expected content, citations, coverage/negative-result controls, resolved or explicitly labeled evidence gaps and the requested return contract. Return a compact progress message with the existing issue/handle, last verified batch, current blocker, next action and artifact path. Do not paste a long unfinished report into chat as the only copy.

Recovered work is not a new research task. No duplicate agents, schedules, recurring polls, extra logins or speculative network changes are authorized by a disconnect. A completed result with a lost chat notification should be retrieved and verified, not researched again. A healthy bounded example proves recovery only for its exercised scope; do not claim gateway stability or reboot recovery from it.
