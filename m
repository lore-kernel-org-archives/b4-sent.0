From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 06:04:58 +0000
Subject: [PATCH v2 5.10.y] pid_namespace: prevent TIF_NOTIFY_SIGNAL from
 interrupting the reaper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-pid-510-v2-1-f528abaf9d3c@certik.com>
X-B4-Tracking: v=1; b=H4sIAAnMB2sC/y2MywrCMBAAf6Xs2dQkkCD+injIY2NXJCnZVpTSf
 zdRjzMMswFjJWQ4DxtUfBJTyQ30YYAwuXxDQbExaKmtUtqKmaIwSgqJyToMKRh3glbPFRO9vqc
 LmFHJ8Q3Xn+fV3zEsfdNL7xiFry6HqSvGHJdSHqL7438P+/4BHb50JpsAAAA=
X-Change-ID: 20261126-pid-510-0ef6aecfc5a8
To: stable@vger.kernel.org
Cc: Christian Brauner <brauner@kernel.org>, Oleg Nesterov <oleg@redhat.com>, 
 linux-kernel@vger.kernel.org, Sasha Levin <sashal@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795673098; l=3176;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=3NDn9fE75xOZ9wPgLWG/nqyjoyHoMyS/t4NUADphw4s=;
 b=ZuwHO1MkeOvSWFTeov5kOKS7DzuukPs21HVsYnEKy1mke2c8g94OYkC+0c6qsi5EZDIhFn+A1
 ykh8ydyoHNaA/1YIJBLHt85lRc+OPfJOP7DfbwCS9iishvlnEUij49Z
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Christian Brauner <brauner@kernel.org>

commit 5c0985dd3c32fc2bbd0e8beaf13cf52cd97376a2 upstream.

Since commit 7fea700e04bd ("zap_pid_ns_processes: clear
TIF_NOTIFY_SIGNAL along with TIF_SIGPENDING") zap_pid_ns_processes()
clears TIF_NOTIFY_SIGNAL before every kernel_wait4() call. Otherwise
kernel_wait4() doesn't sleep and returns -ERESTARTSYS if
signal_pending() is true and the reaper busy-waits.

But clearing TIF_NOTIFY_SIGNAL doesn't fix it. It can get raised again.
For example, klp_send_signals() sets it raw against any task that hasn't
transitioned yet. And it keeps sending it until the livepatch finishes.

The sleep loop waiting for pid_allocated to drop has the same problem
and it doesn't even clear anything. So a schedule() in
TASK_INTERRUPTIBLE returns immediately.

Use a no_notify_signal guard. signal_pending() will ignore
TIF_NOTIFY_SIGNAL and the pid namespace reaper sleeps until a child
exits or free_pid() wakes it.

Link: https://patch.msgid.link/20260824-work-tif_notify_signal-v2-5-6609e42b3157@kernel.org
Fixes: 7fea700e04bd ("zap_pid_ns_processes: clear TIF_NOTIFY_SIGNAL along with TIF_SIGPENDING")
Reviewed-by: Oleg Nesterov <oleg@redhat.com>
Cc: stable@vger.kernel.org
Suggested-by: Oleg Nesterov <oleg@redhat.com>
Signed-off-by: Christian Brauner (Amutable) <brauner@kernel.org>
[ adapted to 5.10: explicit save/restore instead of guard() to avoid a declaration-after-statement warning ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
 kernel/pid_namespace.c |    5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

Changes in v2
v2: resent through a whitespace-safe path; v1 <CAFaZ9ep64RtaNeyK42OVLSCwD_g-E5RqjP4qbK0=45unkG=Zag@mail.gmail.com> was damaged by my mail client and does not apply.
v2: dropped the signal helper patch, Sasha already posted it as <20261028224958.2405498-1-sashal@kernel.org>; this patch depends on it.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

diff --git a/kernel/pid_namespace.c b/kernel/pid_namespace.c
index e032b1ce7964..2c525208b6ad 100644
--- a/kernel/pid_namespace.c
+++ b/kernel/pid_namespace.c
@@ -174,6 +174,7 @@ void zap_pid_ns_processes(struct pid_namespace *pid_ns)
 {
 	int nr;
 	int rc;
+	unsigned int no_notify_flags;
 	struct task_struct *task, *me = current;
 	int init_pids = thread_group_leader(me) ? 1 : 2;
 	struct pid *pid;
@@ -219,9 +220,10 @@ void zap_pid_ns_processes(struct pid_namespace *pid_ns)
 	 * kernel_wait4() will also block until our children traced from the
 	 * parent namespace are detached and become EXIT_DEAD.
 	 */
+	/* Task work must not busy-loop the reaper, see signal_pending(). */
+	no_notify_flags = no_notify_signal_save();
 	do {
 		clear_thread_flag(TIF_SIGPENDING);
-		clear_thread_flag(TIF_NOTIFY_SIGNAL);
 		rc = kernel_wait4(-1, NULL, __WALL, NULL);
 	} while (rc != -ECHILD);
 
@@ -277,6 +279,7 @@ void zap_pid_ns_processes(struct pid_namespace *pid_ns)
 		current->signal->group_exit_code = pid_ns->reboot;
 
 	acct_exit_ns(pid_ns);
+	no_notify_signal_restore(no_notify_flags);
 	return;
 }
 

