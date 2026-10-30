From: Zhuangzhuang Wang <3050681779@qq.com>
Date: Fri, 30 Oct 2026 07:07:27 +0000
Subject: [PATCH] lockdep: Fix inverted "on"/"last" CPU label in
 lockdep_print_held_locks()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-lockdep-fix-cpu-label-v1-1-96875c74b15b@qq.com>
X-B4-Tracking: v=1; b=H4sIAC5C5GoC/yXM0QqCQBCF4VeRuW5Ah0rsVaILdzzp6KLLrkYgv
 ntbXX5wzr9TQjQkuhU7Rbws2TJnVKeCdGjnHmxdNkkp16qUhv2iU4fAT3uzho196+C5UbhLLYD
 UZ8rfEJEHv+798Xfa3AhdvzE6jg+pTO7WeQAAAA==
X-Change-ID: 20261029-lockdep-fix-cpu-label-9ceb572ee274
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Will Deacon <will@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Waiman Long <longman@redhat.com>
Cc: linux-kernel@vger.kernel.org, Zhuangzhuang Wang <3050681779@qq.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793344047; l=1377;
 i=3050681779@qq.com; s=20261029; h=from:subject:message-id;
 bh=6Z2toOrr1MZMaiNJqhLdHt3xNCky5kA9I29By0W/ZlE=;
 b=CAy+zFL/ckUOr2YxzunyS7eycpsvoOZAMBZCb084iD2TVJxDWfxmE4fNoMkCnl0KPBRMMVG8G
 EiFFr+8dc2RCkhFgV4rL9H08ZzxBSYjgRoCWm4rsugs8BD4hKg5xkGE
X-Developer-Key: i=3050681779@qq.com; a=ed25519;
 pk=oGgMbb1S6zGzNgE2ItK2PWjTk3iITWtu91CA5G5Czuw=
X-Endpoint-Received: by B4 Relay for 3050681779@qq.com/20261029 with auth_id=1350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 051f5d223dfc ("lockdep: Enable the printing of held locks of
remote running tasks and print task CPU") added the task's CPU to the
"locks held by" line. As the comment above the printk() describes, a
running task should be reported as "on CPU#N" and a task that is not
running as "last CPU#N". The ternary has the two strings swapped, so
the labels are inverted.

Swap the strings so the output matches the comment.

Fixes: 051f5d223dfc ("lockdep: Enable the printing of held locks of remote running tasks and print task CPU")
Signed-off-by: Zhuangzhuang Wang <3050681779@qq.com>
---
 kernel/locking/lockdep.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/kernel/locking/lockdep.c b/kernel/locking/lockdep.c
index c3dc84a7c..fdae495bf 100644
--- a/kernel/locking/lockdep.c
+++ b/kernel/locking/lockdep.c
@@ -811,7 +811,7 @@ static void lockdep_print_held_locks(struct task_struct *p)
 	 */
 	printk("locks held by %s/%d: %d, %s CPU#%d%s\n",
 		p->comm, task_pid_nr(p), depth,
-		task_is_running(p) ? "last" : "on", task_cpu(p),
+		task_is_running(p) ? "on" : "last", task_cpu(p),
 		depth > 0 ? ":" : "");
 
 	for (i = 0; i < depth; i++) {

---
base-commit: d135ab453a7400a34930bdda1ef4bdc8acfac80e
change-id: 20261029-lockdep-fix-cpu-label-9ceb572ee274

Best regards,
--  
Zhuangzhuang Wang <3050681779@qq.com>

