From: Binoy Ravindran <binoy@vt.edu>
Subject: [PATCH 0/2] livepatch: Do not lose exiting tasks during a
 transition
Date: Mon, 23 Nov 2026 15:52:14 -0500
Message-Id: <20261123-klp-series-v3-v1-0-427c95811d9b@vt.edu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAH6nBGsC/yXMQQ5AMBBA0avIrE3SVhCuIhbUlEFKWkQi7q5Yv
 sX/F3hyTB7K6AJHB3tebICMI9BDY3tC7oJBCZVJqRKc5hX/Bo8Eu1TlRaZFWggDoVkdGT6/X1X
 /9ns7kt7eCdz3AyO0XZhxAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795467163; l=2301;
 i=binoy@vt.edu; s=20261123; h=from:subject:message-id;
 bh=8jw45Z4MONwXpwW16fWs+bguoDA4AMUrsssB1NGSAis=;
 b=KwX1UeAQbQ2O0SqnnT4zaR8qX7zMX5woDh7B1B/Zs6y+x/yTVWOb5SHeWmsDlEquYZcvv+U1a
 AEJtznQ9PwBDyw4N/k3DQBV02yzIU27PJYtO8lumV7kE5bxG6CU15w/
X-Developer-Key: i=binoy@vt.edu; a=ed25519;
 pk=4cNdKPHP0InmhK/9bb7Tm2ZMUXUvLGfw1pmVt5b98fA=
X-Endpoint-Received: by B4 Relay for binoy@vt.edu/20261123 with auth_id=1622
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After exit_notify(), a self-reaping task is unhashed from the task list
but keeps running the rest of do_exit(). The livepatch transition walks
the task list, so it can complete while such a task still runs code from
a patch module that atomic replace is about to free. Yafang Shao and
Petr Mladek discussed this race in [1]. It is hard to hit, but it is
reachable by any livepatch that replaces a function on the exit path,
for example a fix to do_exit() itself.

Every exiting task is already on an RCU-tasks exit list from
exit_tasks_rcu_start(), before exit_notify(), until
exit_tasks_rcu_finish(). After that, do_exit() runs with preemption
disabled until the final switch, so the task cannot sleep or be
preempted. Patch 1 adds helpers to visit the tasks on these lists.
Patch 2 makes every transition step, including reverse and force,
visit them too. The exit path itself is unchanged. Kernels without
CONFIG_TASKS_RCU have no exit lists and are not covered.

We reproduced the crash with two atomic-replace livepatches of the
CVE-2025-38424 fix, which replaces do_exit(). With a debug-only sleep
after exit_notify(), 11 of 12 runs crash without the series and none
with it. With it, there were also no crashes in 1,200 cycles of a /proc
stress test or in 400 cycles with preempt=full. The measurements were
taken on v6.12.1. This series is the forward port to v7.4-rc2. On
mainline it has been build-tested only: it builds without new warnings
with livepatch on, with livepatch on and preemption off, and with
TASKS_RCU off. It has not yet been run on mainline. A reproducer and the
logs are available on request.

[1] https://lore.kernel.org/all/20250127063526.76687-1-laoar.shao@gmail.com/

---
Binoy Ravindran (2):
      rcu-tasks: Add helpers to visit tasks on the exit lists
      livepatch: Include exiting tasks in the transition

 include/linux/rcupdate.h      |  9 ++++++
 kernel/livepatch/transition.c | 72 +++++++++++++++++++++++++++++++++++++++++++
 kernel/rcu/tasks.h            | 67 ++++++++++++++++++++++++++++++++++++----
 3 files changed, 142 insertions(+), 6 deletions(-)
---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261123-klp-series-v3-d52796c0590f

Best regards,
--  
Binoy Ravindran <binoy@vt.edu>

