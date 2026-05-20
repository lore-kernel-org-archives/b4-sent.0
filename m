From: Xiao Feng <xiaofeng5@xiaomi.com>
Date: Wed, 20 May 2026 21:07:49 +0800
Subject: [PATCH] sched/fork: Fix timer_slack_ns inheritance for RT tasks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260520-sched-fork-fix-timer-slack-v1-1-d4fc937245b2@xiaomi.com>
X-B4-Tracking: v=1; b=H4sIACSyDWoC/yXMwQ6CMAyA4VchPdtkbsrBVzEeRtdBRcG0QEgI7
 +6U45f8+TcwVmGDW7WB8iIm41BwPlVAXRxaRknF4J2v3dU7NOo4YR61xywrTvJmRXtF6rFOOVL
 jQkiXAGXwUS7Jf35/HLa5eTJNvyPs+xdtksyYfgAAAA==
X-Change-ID: 20260520-sched-fork-fix-timer-slack-6dfacb033d43
To: Ingo Molnar <mingo@redhat.com>, Peter Zijlstra <peterz@infradead.org>, 
 Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>, 
 K Prateek Nayak <kprateek.nayak@amd.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, Kees Cook <kees@kernel.org>, 
 Felix Moessbauer <felix.moessbauer@siemens.com>, 
 Thomas Gleixner <tglx@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-mm@kvack.org, 
 Xiao Feng <xiaofeng5@xiaomi.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779282468; l=3123;
 i=xiaofeng5@xiaomi.com; s=20260520; h=from:subject:message-id;
 bh=Z8IuJn4aKUWAvDe5Kpak3owHY216za5bjiydkqmvna8=;
 b=Rtvgm49E2Sy9Gr8Xg2UYbouCShW1ZRLMLsLo7cdfQPp9S/JROW01+FZDMIBGw4YacqB4FdSVv
 elHmfiaTdouC2q7Rc3IOCOqsLqa98SPu0n1ej4v8jUXeYQw2zY+URpm
X-Developer-Key: i=xiaofeng5@xiaomi.com; a=ed25519;
 pk=RGje+zXrBTS+7klps4Lhq/+str3IGTgzLwYEkGwZfs0=
X-Endpoint-Received: by B4 Relay for xiaofeng5@xiaomi.com/20260520 with auth_id=784
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit ed4fb6d7ef68 ("hrtimer: Use and report correct timerslack
values for realtime tasks"), RT tasks have their timer_slack_ns set to 0
in __setscheduler_params(). This introduces two related problems when RT
tasks fork children that end up running as CFS:

Problem 1: sched_reset_on_fork

When a RT task with sched_reset_on_fork set forks a child:

1. dup_task_struct() copies timer_slack_ns (0) from the RT parent.
2. copy_process() sets:
     p->default_timer_slack_ns = current->timer_slack_ns (= 0)
3. sched_fork() demotes the child to SCHED_NORMAL but does not
   restore timer_slack_ns.

Result: CFS child has timer_slack_ns = 0 and default_timer_slack_ns = 0
permanently.

Problem 2: RT fork followed by later policy change

When a RT task forks a child (without reset_on_fork), the child inherits
RT policy with timer_slack_ns = 0. copy_process() sets
default_timer_slack_ns = current->timer_slack_ns (= 0). If the child is
later demoted to CFS via sched_setscheduler(), __setscheduler_params()
tries to restore timer_slack_ns from default_timer_slack_ns, but it is 0.

Result: same as above.

Both problems prevent timer coalescing for these CFS tasks, causing
unnecessary wakeups and increased power consumption. Writing 0 to
/proc/pid/timerslack_ns also cannot restore a proper default.

Fix both issues:

1. In copy_process(), inherit default_timer_slack_ns from the parent's
   default_timer_slack_ns (which is preserved across RT transitions)
   instead of timer_slack_ns (which is 0 for RT tasks).

2. In sched_fork(), when sched_reset_on_fork demotes RT/DL to CFS,
   explicitly restore timer_slack_ns from the parent's
   default_timer_slack_ns, falling back to 50us if it is also 0.

Fixes: ed4fb6d7ef68 ("hrtimer: Use and report correct timerslack values for realtime tasks")
Signed-off-by: Xiao Feng <xiaofeng5@xiaomi.com>
---
 kernel/fork.c       | 2 +-
 kernel/sched/core.c | 2 ++
 2 files changed, 3 insertions(+), 1 deletion(-)

diff --git a/kernel/fork.c b/kernel/fork.c
index 5f3fdfdb14c7..c3ef5ebb3037 100644
--- a/kernel/fork.c
+++ b/kernel/fork.c
@@ -2174,7 +2174,7 @@ __latent_entropy struct task_struct *copy_process(
 	retval = -EAGAIN;
 #endif
 
-	p->default_timer_slack_ns = current->timer_slack_ns;
+	p->default_timer_slack_ns = current->default_timer_slack_ns;
 
 #ifdef CONFIG_PSI
 	p->psi_flags = 0;
diff --git a/kernel/sched/core.c b/kernel/sched/core.c
index b8871449d3c6..9b63560a45de 100644
--- a/kernel/sched/core.c
+++ b/kernel/sched/core.c
@@ -4710,6 +4710,8 @@ int sched_fork(u64 clone_flags, struct task_struct *p)
 			p->policy = SCHED_NORMAL;
 			p->static_prio = NICE_TO_PRIO(0);
 			p->rt_priority = 0;
+			p->timer_slack_ns = current->default_timer_slack_ns ?: 50000;
+			p->default_timer_slack_ns = p->timer_slack_ns;
 		} else if (PRIO_TO_NICE(p->static_prio) < 0)
 			p->static_prio = NICE_TO_PRIO(0);
 

---
base-commit: 27fa82620cbaa89a7fc11ac3057701d598813e87
change-id: 20260520-sched-fork-fix-timer-slack-6dfacb033d43

Best regards,
--  
Xiao Feng <xiaofeng5@xiaomi.com>

