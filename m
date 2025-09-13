From: Demi Marie Obenour <demiobenour@gmail.com>
Date: Sat, 13 Sep 2025 18:28:49 -0400
Subject: [PATCH] kernel: Prevent prctl(PR_SET_PDEATHSIG) from racing with
 parent process exit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250913-fix-prctl-pdeathsig-race-v1-1-44e2eb426fe9@gmail.com>
X-B4-Tracking: v=1; b=H4sIACDwxWgC/x2MWwqAIBAArxL73YIPhOoq0YfoVgthskYE4d2TP
 gdm5oVCwlRg6l4QurnwmRrovoOw+7QRcmwMRhmnRm1x5QezhOvAHMlfe+ENxQfClaKzwXg3OA0
 tz0LN/dfzUusHfP+BRmoAAAA=
X-Change-ID: 20250913-fix-prctl-pdeathsig-race-fed53c2a5851
To: linux-kernel@vger.kernel.org
Cc: Demi Marie Obenour <demiobenour@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757802531; l=4260;
 i=demiobenour@gmail.com; s=20250731; h=from:subject:message-id;
 bh=p8I08OCbW2U/ck1jmNRahTKGCgOB/aX3lWg1CCaFPzE=;
 b=A1dzZzRdsvNHlTbvcgzqE0Xo63/KNrfxknlr9qE7rdR1d82wxgDwQOK51C8dpw7klX8LtuATM
 Ut3iX4SaWc5AwR4NxpWPjPBqS5LwSbLA6kxXU8RZJ24sIifbbqDO30x
X-Developer-Key: i=demiobenour@gmail.com; a=ed25519;
 pk=4iGY+ynEKxIfs+fIUK9EzsvZ44yGE0GvXLeLTPKKPhI=
X-Endpoint-Received: by B4 Relay for demiobenour@gmail.com/20250731 with auth_id=473
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If a process calls prctl(PR_SET_PDEATHSIG) at the same time that the
parent process exits, the child will write to me->pdeath_sig at the same
time the parent is reading it.  Since there is no synchronization, this
is a data race.

Worse, it is possible that a subsequent call to getppid() can continue
to return the previous parent process ID without the parent death signal
being delivered.  This happens in the following scenario:

parent                                                 child

forget_original_parent()                               prctl(PR_SET_PDEATHSIG, SIGKILL)
                                                         sys_prctl()
                                                           me->pdeath_sig = SIGKILL;
                                                       getppid();
  RCU_INIT_POINTER(t->real_parent, reaper);
  if (t->pdeath_signal) /* reads stale me->pdeath_sig */
           group_send_sig_info(t->pdeath_signal, ...);

And in the following:

parent                                                 child

forget_original_parent()
    RCU_INIT_POINTER(t->real_parent, reaper);
    /* also no barrier */
     if (t->pdeath_signal) /* reads stale me->pdeath_sig */
             group_send_sig_info(t->pdeath_signal, ...);

                                                       prctl(PR_SET_PDEATHSIG, SIGKILL)
                                                         sys_prctl()
                                                           me->pdeath_sig = SIGKILL;
                                                       getppid(); /* reads old ppid() */

As a result, the following pattern is racy:

	pid_t parent_pid = getpid();
	pid_t child_pid = fork();
	if (child_pid == -1) {
		/* handle error... */
		return;
	}
	if (child_pid == 0) {
		if (prctl(PR_SET_PDEATHSIG, SIGKILL) != 0) {
			/* handle error */
			_exit(126);
		}
		if (getppid() != parent_pid) {
			/* parent died already */
			raise(SIGKILL);
		}
		/* keep going in child */
	}
	/* keep going in parent */

If the parent is killed at exactly the wrong time, the child process can
(wrongly) stay running.

I didn't manage to reproduce this in my testing, but I'm pretty sure the
race is real.  KCSAN is probably the best way to spot the race.

Fix the bug by holding tasklist_lock for reading whenever pdeath_signal
is being written to.  This prevents races on me->pdeath_sig, and the
locking and unlocking of the rwlock provide the needed memory barriers.
If prctl(PR_SET_PDEATHSIG) happens before the parent exits, the signal
will be sent.  If it happens afterwards, a subsequent getppid() will
return the new value.

Signed-off-by: Demi Marie Obenour <demiobenour@gmail.com>
---
I believe this is not the only code missing locking, but I'm
not familiar enough with the rest of the kernel to know if
read_lock(&tasklist_lock) is safe in the other places (AppArmor,
execve(), SELinux, commit_creds()) that change it.

checkpatch complains about overly long lines in the commit message.  I
don't see a way to wrap them without making the description of the race
harder to read.

Only compile-tested, but this looks obvious.
---
 kernel/sys.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/kernel/sys.c b/kernel/sys.c
index 1e28b40053ce206d7d0ed27e8a4fce8b616c3565..5e0e0bdca386492dace6341e3ce8083d7aa732cb 100644
--- a/kernel/sys.c
+++ b/kernel/sys.c
@@ -2470,7 +2470,17 @@ SYSCALL_DEFINE5(prctl, int, option, unsigned long, arg2, unsigned long, arg3,
 			error = -EINVAL;
 			break;
 		}
+		/*
+		 * Ensure that either:
+		 *
+		 * 1. Subsequent getppid() calls reflect the parent process having died.
+		 * 2. forget_original_parent() will send the new me->pdeath_signal.
+		 *
+		 * Also prevent the read of me->pdeath_signal from being a data race.
+		 */
+		read_lock(&tasklist_lock);
 		me->pdeath_signal = arg2;
+		read_unlock(&tasklist_lock);
 		break;
 	case PR_GET_PDEATHSIG:
 		error = put_user(me->pdeath_signal, (int __user *)arg2);

---
base-commit: 5cd64d4f92683afa691a6b83dcad5adfb2165ed0
change-id: 20250913-fix-prctl-pdeathsig-race-fed53c2a5851

Best regards,
-- 
Demi Marie Obenour <demiobenour@gmail.com>

