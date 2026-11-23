From: "Josh Lafleur (Zipline)" <josh.lafleur@outlook.com>
Subject: [PATCH 0/2] sched/rt: Restore the PUSH_IPI fallback for migration
 disabled next_task
Date: Mon, 23 Nov 2026 11:21:42 -0800
Message-Id: <20261123-migrate-on-ipi-v1-0-eacfe7e4b808@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAEaSBGsC/y2NQQqDMBBFryKz7oATayleRbpIdNQpNOokiiDev
 al1+eD993cIrMIBqmwH5VWCjD4B3TJoBut7RmkTg8nNg8gU+JFebWQcPcokWFLu7tS6Z0kW0mh
 S7mQ7g/Xrz2Fxb27ir3IZyvOSnuKlHccX8wKoAocAAAA=
X-Change-ID: 20261123-migrate-on-ipi-510b41db851a
To: Ingo Molnar <mingo@redhat.com>, Peter Zijlstra <peterz@infradead.org>, 
 Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>, 
 K Prateek Nayak <kprateek.nayak@amd.com>, 
 Gauri Patwardhan <gauri.patwardhan@nutanix.com>, 
 Phil Auld <pauld@redhat.com>, Harshit Agarwal <harshit@nutanix.com>, 
 Jon Kohler <jon@nutanix.com>, Seiji Nishikawa <snishika@redhat.com>
Cc: Rahul Chunduru <rahul.chunduru@nutanix.com>, 
 linux-kernel@vger.kernel.org, 
 "Josh Lafleur (Zipline)" <josh.lafleur@outlook.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795461730; l=6430;
 i=josh.lafleur@outlook.com; s=20260930; h=from:subject:message-id;
 bh=Wrsd8e1gb5ciWU+hltY5kz+iDYcS2cMAQldKALBiziU=;
 b=Ce/mxKtmYakO/QuEOjUYJu98SE0du3KHC554k7MbDraIaifHFxaVHcEEM115aG9uixqShTFZ/
 62S/U1ZqEn0DsFcNTbou3PE9vzoT2cyN1i+PDdNu43utyWIneXgNnes
X-Developer-Key: i=josh.lafleur@outlook.com; a=ed25519;
 pk=slf3cskRg11vRnFROP6D9bMBKyvvRNsP2Msvm4/qpmM=
X-Endpoint-Received: by B4 Relay for josh.lafleur@outlook.com/20260930 with auth_id=1090
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A migrate-disabled RT task will remain on the pushable list though fail
migration.

The PUSH_IPI path originally used the non-migrateable condition to
request a stopper push of the running task, allowing the pinned task to
run. The head check added by 690e47d1403e can reject the stopper target
after the source rq lock is dropped; dae5c0292080 then prevented the
PUSH_IPI path from selecting the pinned candidate at all to reduce stopper
handler load, however this is still at the cost of increased rt latency
when there are other available cores which may run both the current and
next tasks of a rq.

Patch 1 allows a queued stopper target through the head recheck while
retaining the ordinary push validation.

Patch 2 selects pinned candidates only for the PUSH_IPI path. Ordinary
pushes continue to skip them and can reach movable tasks behind them.
One caveat with this change which would be good to address is that it
(seems?) feasible for a Task A running on core N with task B queued
behind it and of lower priority to attempt pushing task A onto a cpu
running task C (prioritized in-between the A,B) which would be roughly
a short windowed priority inversion of task C. I have posited a third
change to precheck the push_rt_task() codepath which would ensure the
next_task is of higher priority than the remote rq->curr, however this
is up for discussion. I can see how we would want to avoid cascaded
load-balancing sequences even after the recent improvements to the IPI
balancer, but this problem should technically still exist because the
remote rq can concurrently re-shuffle during the push->handler
sequence.

I was able to reproduce the failing migration with a set of 4 tasks
which are runnable on 3 cores in addition to 1 per-cpu high frequency
periodic. The periodic runs at multiple kHz to stress a higher->lower
priority transition to kick off cross core IPI balancing. The A, B,
high priority, and busy worker are all ~wake aligned operating at 50Hz
(arbitrary number for this test case). The A and B tasks content on an
rt mutex in a non-migrateable section for 10% of its runtime whereas
the other 90% is spent running busy work. The A, B, and Busy tasks
have 5ms of work to complete whereas the high priority task has 1ms.
The periodic runs at 4kHz and does ~25us of work.

The intended sequence is that the A, B, and High priority tasks start
~algined on cpu such that one of the victim tasks goes non-preemptible
and blocks on the acquired mutex. This then allows the busy worker to
step on cpu for its 5ms runtime. In ~1% of runtimes, we would see the
worst case completion time of the victim be over 10ms with high IPI
interrupt rates due to failed migration. After this changeset, we
reduced rt completion latency by ~40% due it no longer being stuck in
the runqueue, in addition to the reduced IPI rates.

Note: Codex assisted in the creation of a test module and for
post-processing ftrace/test application data.

The original testing was conducted on a PREEMPT_RT LTS without
dae5c0292080. The fixed scheduler saw a reduction of 10/1200 missed
deadlines to 0/1200 missed deadlines. It also saw a reduction in the
max IPI per period going from 190->64. Following this testing, we
applied dae5c0292080 and saw roughly the same deadline misses (15
total), though roughly comparable improvements to IPI hard irq rates.
Max completion times for A, B were still over 10ms with just the
dae5c0292080 patch applied. This is expected as that change didn't
intend to resolve the balancing storms, only mitigate the failed
handler load.

Completion Time Analysis

 Worker           Unfixed mean ± SD     Fixed mean ± SD    Maximum, unfixed → fixed
━━━━━━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━━━━━━━
 A                 5.088 ± 0.264 ms    5.937 ± 0.303 ms           10.546 → 6.065 ms
───────────────  ───────────────────  ──────────────────  ──────────────────────────
 B                 5.982 ± 0.485 ms    5.096 ± 0.179 ms           10.549 → 6.069 ms
───────────────  ───────────────────  ──────────────────  ──────────────────────────
 High priority     1.037 ± 0.021 ms    1.036 ± 0.002 ms            1.541 → 1.064 ms
───────────────  ───────────────────  ──────────────────  ──────────────────────────
 Busy              5.133 ± 0.293 ms    5.130 ± 0.289 ms            6.057 → 6.056 ms

I did note that per test run, results seem quasi dependent on the way tasks
tend to land on cpus in the first scheduler run which is why I believe
the A and B workers are non-deterministically the victim though we can
see the worst case completion time significantly improve across the tests.

I believe this is also similar to discussions in [1,2] (among many others
when going through the lore) though I believe it addresses the root cause
of the failed migration storms leading to increased RT latency.

Note: The seperate items relating to the DL scheduler in related issues
and the original changes is out of scope of this change-set.

[1] https://lore.kernel.org/all/20261113160655.2909479-1-mgorman@techsingularity.net/
[2] https://lore.kernel.org/all/178833372384.3717435.9283330313829938009.tip-bot2@tip-bot2/

Signed-off-by: Josh Lafleur (Zipline) <josh.lafleur@outlook.com>
---
Josh Lafleur (Zipline) (2):
      sched/rt: Allow queued stopper targets past the pushable-head check
      sched/rt: Restore pinned candidates for PUSH_IPI balancing

 kernel/sched/rt.c | 22 +++++++++++++++-------
 1 file changed, 15 insertions(+), 7 deletions(-)
---
base-commit: 666539eecdf4db623f5e3c3e55cf9f2dfad24aa4
change-id: 20261123-migrate-on-ipi-510b41db851a

Best regards,
--  
Josh Lafleur (Zipline) <josh.lafleur@outlook.com>

