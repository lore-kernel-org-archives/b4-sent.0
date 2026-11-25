From: Binoy Ravindran <binoy@vt.edu>
Subject: [PATCH v3 0/3] livepatch: Do not lose exiting tasks during a
 transition
Date: Wed, 25 Nov 2026 18:11:45 -0500
Message-Id: <20261125-klp-series-v3-v3-0-b1e0f79af331@vt.edu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADFrB2sC/3WN0QqCMBhGXyX+6xbbP6euq94jutBt5ipUNh2F+
 O5tChFBlwe+c74ZvHHWeDjuZnAmWG/7LgLf70C1VXc1xOrIgBRzxpCT+2Mgm0MCJ1pgIXNFhaQ
 NRGdwprHPtXe+bOyn+mbUmCJp0Vo/9u61HgaWdv/agRFKMiyUFCVjWtanMB6MniCFA36r2a+KU
 RVUIy1RVpwXH3VZljeaGyBj9AAAAA==
X-Change-ID: 20261123-klp-series-v3-d52796c0590f
To: "Paul E. McKenney" <paulmck@kernel.org>, 
 Frederic Weisbecker <frederic@kernel.org>, 
 Neeraj Upadhyay <neeraj.upadhyay@kernel.org>, 
 Joel Fernandes <joelagnelf@nvidia.com>, 
 Josh Triplett <josh@joshtriplett.org>, Boqun Feng <boqun@kernel.org>, 
 Uladzislau Rezki <urezki@gmail.com>, Steven Rostedt <rostedt@goodmis.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Lai Jiangshan <jiangshanlai@gmail.com>, Zqiang <qiang.zhang@linux.dev>, 
 Josh Poimboeuf <jpoimboe@kernel.org>, Miroslav Benes <mbenes@suse.cz>, 
 Petr Mladek <pmladek@suse.com>, Joe Lawrence <joe.lawrence@redhat.com>, 
 Song Liu <song@kernel.org>, Ingo Molnar <mingo@kernel.org>, 
 Jiri Kosina <jikos@kernel.org>
Cc: rcu@vger.kernel.org, linux-kernel@vger.kernel.org, 
 live-patching@vger.kernel.org, Yafang Shao <laoar.shao@gmail.com>, 
 Jaidev Shastri <jaidevshastri@vt.edu>, Binoy Ravindran <binoy@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795648326; l=5443;
 i=binoy@vt.edu; s=20261123; h=from:subject:message-id;
 bh=oeulflrpaOtQWHSfhsh+UIlfdExERenQnmbTmiZ3tNo=;
 b=lwnaW0EwcTZ9LN4bkX3r57sXyi/w/nY9K3ax+AWLdjGPp6Tbg+iUpFS482LiYSX9dqWOFt2NK
 tG2NjOltWmUAOi/O3gMdhyjwcicOMslD5u0BihtC+2OcaO8WTA0RoMf
X-Developer-Key: i=binoy@vt.edu; a=ed25519;
 pk=4cNdKPHP0InmhK/9bb7Tm2ZMUXUvLGfw1pmVt5b98fA=
X-Endpoint-Received: by B4 Relay for binoy@vt.edu/20261123 with auth_id=1622
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After exit_notify(), a self-reaping task is unhashed from the task list
but keeps running the rest of do_exit(). The livepatch transition walks
the task list, so it can complete while such a task still runs code from
a patch module that atomic replace is about to free. Yafang Shao and
Petr Mladek discussed this race in [1], and Josh Poimboeuf suggested a
similar approach in [2]. The race is hard to hit, but any livepatch that
replaces a function on the exit path can reach it, for example a fix to
do_exit() itself.

Every exiting task is on an RCU-tasks exit list from
exit_tasks_rcu_start(), before exit_notify(), until
exit_tasks_rcu_finish(). Patch 1 adds helpers to visit the tasks on
these lists. Patch 2 makes every transition step, including reverse and
force, visit them too. After exit_tasks_rcu_finish(), do_exit() runs
with preemption disabled until the task's final switch. Patch 2 waits
that stretch out with synchronize_rcu() before func->transition is set
and before the transition completes. The exit
path itself is unchanged. Patch 3, suggested by Yafang, makes LIVEPATCH
select TASKS_RCU, which every livepatch kernel already builds, so that
the exit lists are always there.

Tested on v7.4-rc2, x86-64, under QEMU/KVM, with two klp-build
livepatches that each replace do_exit() and replace each other ten
times per run, and a debug-only 2 s sleep after exit_notify(). Without
the series, 9 of 12 runs crashed; with it, all 12 completed their 120
replace cycles. With lockdep, PROVE_RCU and DEBUG_ATOMIC_SLEEP
enabled, the series ran 180 replace cycles, 120 of them with the sleep,
with no reports. Without the sleep, 20,000 replace cycles with the
series, in both the default and preempt=full modes, completed without a
fault. Compared with v7.4-rc2 alone (about 30,000 transitions per
mode), the median transition time rose from 8 to 12 ms in the default
mode and from 8 ms to 0.8 s with preempt=full, while the 90th and 99th
percentiles stayed at about 1.6 s and 1.8 s. v2, which waited with
klp_synchronize_transition(), kept the median at 7 to 8 ms in both
modes. The wait is the only functional change from v2, so we attribute
the increase to the synchronize_rcu() calls. Each commit
builds without new warnings with and without CONFIG_LIVEPATCH. A
reproducer and the logs are available on request.

checkpatch.pl in v7.4-rc2 reports the Assisted-by: trailer as
non-standard. The trailer follows
Documentation/process/coding-assistants.rst.

[1] https://lore.kernel.org/all/20250127063526.76687-1-laoar.shao@gmail.com/
[2] https://lore.kernel.org/live-patching/20250124010848.pdcxokfsk2ngrowl@jpoimboe/

---
Changes in v3:
- Wait out the do_exit() tail with synchronize_rcu() instead of
  klp_synchronize_transition(), as rcu_tasks_postgp() does
  (Yafang Shao). With preempt=full this raises the median transition
  time in our test from 8 ms to 0.8 s; the 90th and 99th
  percentiles stay about the same. See the test notes above.
- Replace the callback-based snapshot walk, which had a single user,
  with klp_try_switch_exiting_tasks() (Yafang Shao).
- Link to v2: https://patch.msgid.link/20261124-klp-series-v3-v2-0-50d20829a337@vt.edu

Changes in v2:
- Walk the exit lists under tasklist_lock and skip tasks that are
  still hashed, so that each task is visited exactly once (Sashiko).
- Call klp_synchronize_transition() after initializing the transition,
  before func->transition is set, and before completing it, to wait
  out tasks past exit_tasks_rcu_finish() (Sashiko).
- Document rtp_exit_cursor in the kernel-doc comment (Sashiko).
- Add patch 3, which makes LIVEPATCH select TASKS_RCU (Yafang Shao).
- Test on v7.4-rc2 instead of v6.12.1, including lockdep and
  natural-timing runs.
- Link to v1: https://patch.msgid.link/20261123-klp-series-v3-v1-0-427c95811d9b@vt.edu

To: "Paul E. McKenney" <paulmck@kernel.org>
To: Frederic Weisbecker <frederic@kernel.org>
To: Neeraj Upadhyay <neeraj.upadhyay@kernel.org>
To: Joel Fernandes <joelagnelf@nvidia.com>
To: Josh Triplett <josh@joshtriplett.org>
To: Boqun Feng <boqun@kernel.org>
To: Uladzislau Rezki <urezki@gmail.com>
To: Steven Rostedt <rostedt@goodmis.org>
To: Mathieu Desnoyers <mathieu.desnoyers@efficios.com>
To: Lai Jiangshan <jiangshanlai@gmail.com>
To: Zqiang <qiang.zhang@linux.dev>
To: Josh Poimboeuf <jpoimboe@kernel.org>
To: Miroslav Benes <mbenes@suse.cz>
To: Petr Mladek <pmladek@suse.com>
To: Joe Lawrence <joe.lawrence@redhat.com>
To: Song Liu <song@kernel.org>
To: Ingo Molnar <mingo@kernel.org>
To: Jiri Kosina <jikos@kernel.org>
Cc: rcu@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: live-patching@vger.kernel.org
Cc: Yafang Shao <laoar.shao@gmail.com>
Cc: Jaidev Shastri <jaidevshastri@vt.edu>

---
Binoy Ravindran (3):
      rcu-tasks: Add helpers to visit tasks on the exit lists
      livepatch: Include exiting tasks in the transition
      livepatch: Select TASKS_RCU

 include/linux/rcupdate.h      |  9 ++++
 kernel/livepatch/Kconfig      |  1 +
 kernel/livepatch/transition.c | 99 +++++++++++++++++++++++++++++++++++++++++++
 kernel/rcu/tasks.h            | 69 +++++++++++++++++++++++++++---
 4 files changed, 172 insertions(+), 6 deletions(-)
---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261123-klp-series-v3-d52796c0590f

Best regards,
--  
Binoy Ravindran <binoy@vt.edu>

