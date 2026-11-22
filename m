From: Hang Zhengyang <hang.zhengyang1010@gmail.com>
Subject: [PATCH sched_ext/for-7.4-fixes 0/2] sched_ext: Fix two gaps in
 dl_server protection against RT starvation
Date: Mon, 23 Nov 2026 02:04:53 +0800
Message-Id: <20261123-scx-dlsrv-v1-0-87c342d8246e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMUQrCMBAFr1L229UmxFa8ipQiyUu7IK3sSgmU3
 t2gn8MMs5NBBUb3ZifFJibrUsGdGorzc5nAkiqTb33nnHdssXB6mW7cpxCQw/XmW1Dt34os5fd
 6kMUZaUT5XPKq3J8D/91wHF/iIpeIdAAAAA==
X-Change-ID: 20261121-scx-dlsrv-7d44ef45820e
To: Tejun Heo <tj@kernel.org>, David Vernet <void@manifault.com>, 
 Andrea Righi <arighi@nvidia.com>, Changwoo Min <changwoo@igalia.com>, 
 Ingo Molnar <mingo@redhat.com>, Peter Zijlstra <peterz@infradead.org>, 
 Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>, 
 K Prateek Nayak <kprateek.nayak@amd.com>
Cc: Joel Fernandes <joelagnelf@nvidia.com>, sched-ext@lists.linux.dev, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Hang Zhengyang <hang.zhengyang1010@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795370696; l=2617;
 i=hang.zhengyang1010@gmail.com; s=20261008; h=from:subject:message-id;
 bh=aSZAQoVClVkjxIB0EoJguj0WIv5tGQ97jdqS31tG35g=;
 b=iUyXsA1PyOnncV3w4VClrZYRB3zpFeScduXVAaZZYivIZA9bs7L0zuYlp3J+jZbID2ExlGqcV
 5LsITTAMHt5BAs5BS9UGBOM2rTwcQZSHpE0hiqglBTYuUjpqAOGu5pe
X-Developer-Key: i=hang.zhengyang1010@gmail.com; a=ed25519;
 pk=5drRny3PqRPLhKVB0YIQXN5YyD8miKCpXWhnEPvafAI=
X-Endpoint-Received: by B4 Relay for hang.zhengyang1010@gmail.com/20261008 with auth_id=1133
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These patches fix two cases where a dl_server should protect tasks from
an RT task but isn't running. The starved tasks then hold up the
scheduler disable. It doesn't finish until the RT task stops.

Patch 1: in full mode, the disable attaches fair_server only at the end.
Tasks move back to fair long before that.

Patch 2: a CPU's ext_server restarts only when the first sched_ext task
is enqueued there. If it stops while tasks are still queued, nothing
restarts it.

Both came out of one stress test (scx_simple, CPU hotplug, stress-ng,
SCHED_FIFO spinners). The patches don't depend on each other.

Tested on sched_ext/for-7.4-fixes (8e156b9218f9) in an 8 vCPU KVM guest
with PREEMPT, PREEMPT_RCU and NO_HZ_FULL:

                         no patches    patch 1        patch 2   both
  patch 1 repro          37/300 stuck  0/300          -         0/300
  same, KASAN+lockdep    3/100 stuck   0/100          -         0/100
  stress, KASAN+lockdep  hung, 4 min   hung, 2-5 min  1/3 hung  6/7 ok [*]
  stress, no debug       -             2/2 ok         -         3/3 ok
  selftests              -             38 ok, 2 skip  -         38 ok, 2 skip
  messaging [**]         1.849 s       -              -         1.821 s

  Each stress run is 15 minutes.
  [*]  The 7th run stopped at 2.5 min. A fork stalled for 75 s with the
       scheduler enabled, then went on. Not the disable hang. Cause not
       found.
  [**] perf bench sched messaging -g 8 -l 1000 under scx_simple, mean of
       15 runs

With patch 2 alone, the one stress hang was the problem patch 1 fixes.

Patch 2's cost: during a scheduler reload, ext_server restarted and
stopped 238 times in 41 ms on one CPU. I also ran an RT spinner with
sched_ext tasks on the same CPU, under scx_simple and scx_central.
There, patch 2 changed neither the restart count nor the time the RT
task lost.

I didn't test on bare metal, or with other schedulers outside that cost
test. I didn't write selftests, because both hangs depend on timing.

I used Claude Code to find the issues, write the patches and run the
tests. I reran the reproducer and reviewed the patches.

---
Hang Zhengyang (2):
      sched_ext: Attach fair_server before tasks fall back to fair on disable
      sched_ext: Start ext_server on every enqueue

 kernel/sched/ext/ext.c | 27 ++++++++++++++++++++++-----
 1 file changed, 22 insertions(+), 5 deletions(-)
---
base-commit: 8e156b9218f9f1f8b866d8e253145afdb01cf289
change-id: 20261121-scx-dlsrv-7d44ef45820e

Best regards,
-- 
Hang Zhengyang <hang.zhengyang1010@gmail.com>

