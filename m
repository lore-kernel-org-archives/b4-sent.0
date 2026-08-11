From: Changyu Li <ihaveihaveihavea@gmail.com>
Date: Tue, 11 Aug 2026 04:12:20 -0400
Subject: [PATCH] ipc: fix hung task in copy_ipcs()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-work-v1-1-df28655110a0@gmail.com>
X-B4-Tracking: v=1; b=H4sIAGPZemoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDC0ND3fL8omxdU2MjC8tUC8OkFOM0JaDSgqLUtMwKsDHRsRB+cWlSVmp
 yCUivUm0tANC+r1VoAAAA
X-Change-ID: 20260811-work-53289e81bd3f
To: linux-kernel@vger.kernel.org
Cc: syzbot+97a62389c5611b0477f3@syzkaller.appspotmail.com, 
 Changyu Li <ihaveihaveihavea@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2847;
 i=ihaveihaveihavea@gmail.com; h=from:subject:message-id;
 bh=mmV3V1+8ai5Y8M4gkr3IAIu4s2zOEMfEy4G4kkpygHI=;
 b=owGbwMvMwCW2u2xN/2eLjV8ZT6slMWRV3Szrf1DxYO4cl5J23q3rpq1rm7w0Iev2oem3zor0H
 ShwXRJe3lHCwiDGxSArpsiiZ80sta9xivPea9/2w8xhZQIZwsDFKQAT2dXP8L1iyrb1hy5v4ito
 iPKzkn7SeCTao5L7s2H2QeG+XcJV6xn+hyXn7f+czxx3dO7bApPY54kJ97pfyYRX2kobsghzVex
 gBAA=
X-Developer-Key: i=ihaveihaveihavea@gmail.com; a=openpgp;
 fpr=2E3B031ABE819443BDD6F6BFBB76AC8FF338B1F5
X-Endpoint-Received: by B4 Relay for ihaveihaveihavea@gmail.com/default with auth_id=936
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the user_ns's UCOUNT_IPC_NAMESPACES limit is reached,
copy_ipcs eventually calls flush_work(&free_ipc_work) to wait for
in-flight work to reduce the number of ipc_namespaces so it can proceed.
Unfortunately flush_work() enters uninterruptible sleep and if there
are enough pending items to be freed by free_ipc_work then this would
trip hung task watchdog.

INFO: task blocked for more than 143 seconds.
      Not tainted syzkaller #0
task:syz-executor845 state:D stack:27496 pid:5856
Call Trace:
 <TASK>
 __flush_work+0x9c2/0xd70 kernel/workqueue.c:4431
 create_ipc_ns ipc/namespace.c:55 [inline]
 copy_ipcs+0x19b/0x6c0 ipc/namespace.c:116
 create_new_namespaces+0x210/0x6b0 kernel/nsproxy.c:112
 unshare_nsproxy_namespaces+0x149/0x190 kernel/nsproxy.c:234
 ksys_unshare+0x5a7/0x950 kernel/fork.c:3291
 </TASK>

Replace the uninterruptible flush_work() with a polling loop that
checks if there's an in-flight free_ipc_work. If there is then wait
interruptibly a short interval for forward progress in free_ipc_work
and retry.

If free_ipc_work is not in-flight nothing will free up quota so bail
with -ENOSPC as before. Otherwise wait interruptibly to not trip hung
task watchdog.

Reported-by: syzbot+97a62389c5611b0477f3@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=97a62389c5611b0477f3
Signed-off-by: Changyu Li <ihaveihaveihavea@gmail.com>
---
 ipc/namespace.c | 19 ++++++++++++++-----
 1 file changed, 14 insertions(+), 5 deletions(-)

diff --git a/ipc/namespace.c b/ipc/namespace.c
index 1e71353bdb..e8ea422d79 100644
--- a/ipc/namespace.c
+++ b/ipc/namespace.c
@@ -26,6 +26,8 @@
 static void free_ipc(struct work_struct *unused);
 static DECLARE_WORK(free_ipc_work, free_ipc);
 
+#define FREE_IPC_WAIT_JIFFIES 5
+
 static struct ucounts *inc_ipc_namespaces(struct user_namespace *ns)
 {
 	return inc_ucount(ns, current_euid(), UCOUNT_IPC_NAMESPACES);
@@ -49,12 +51,19 @@ static struct ipc_namespace *create_ipc_ns(struct user_namespace *user_ns,
 	if (!ucounts) {
 		/*
 		 * IPC namespaces are freed asynchronously, by free_ipc_work.
-		 * If frees were pending, flush_work will wait, and
-		 * return true. Fail the allocation if no frees are pending.
+		 * If there is in flight free_ipc_work, we'll wait for it to
+		 * make progress otherwise fail immediately.
 		 */
-		if (flush_work(&free_ipc_work))
-			goto again;
-		goto fail;
+		if (!work_busy(&free_ipc_work))
+			goto fail;
+
+		schedule_timeout_interruptible(FREE_IPC_WAIT_JIFFIES);
+		if (signal_pending(current)) {
+			err = -ERESTARTSYS;
+			goto fail;
+		}
+
+		goto again;
 	}
 
 	err = -ENOMEM;

---
base-commit: 3d08ff75a47a3e7e2ab45a3bcab6723b4d906422
change-id: 20260811-work-53289e81bd3f

Best regards,
--  
Changyu Li <ihaveihaveihavea@gmail.com>

