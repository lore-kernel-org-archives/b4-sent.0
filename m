From: Chen Linxuan <me@black-desk.cn>
Date: Tue, 27 Oct 2026 16:22:15 +0800
Subject: [PATCH] pidfd: restrict task access ioctls to the caller's pid
 namespace
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-pidfd-task-access-v1-1-d46cf0fa4ca1@black-desk.cn>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrB2IoRjsVcRFMhl1FKxkbCkE7
 95Ul2/xfwblJKzwrDIk/ojKayto6gpo9tvEKLEYrLFtY6zDXeIY8fC6oidiVQyuc0zBtsY/oHR
 74lG+17Mfbus7LEzHfwTn+QP6aJ3EdQAAAA==
X-Change-ID: 20261027-pidfd-task-access-b797ecb260a4
To: Christian Brauner <brauner@kernel.org>, Jann Horn <jannh@google.com>
Cc: Alexander Viro <viro@zeniv.linux.org.uk>, Jan Kara <jack@suse.cz>, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-api@vger.kernel.org, Chen Linxuan <me@black-desk.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2904; i=me@black-desk.cn;
 s=20260831; h=from:subject:message-id;
 bh=NJGDJ4tAiDZhLhTR/ki/QbOLj26AyQQxFTXud2F+Uxo=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBq4F9CKxRS8zvMiS4Y5tBkX2gAQZ6Z9+krgSBb7
 LCi8zk6uRGJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCauBfQgAKCRB2HuYUOZmu
 i0UeD/0TIMg45/Wr71eH7wN89I0/aoj2TDmRpMs9bVru+UZ4bdPCFngLgH/SlvX5qXbTKMcoWTu
 7rCblQ287n/0JHBRCJb8XogWmNO0yBE+REFNUcvLNgkbknTlNpAvLs17N8h16nAL3xUqjw93GcO
 vUXYDFbUu5rY3iU8q5IQ9rpDBq5mYM7vTkSIIY0KXR90L19CF0rqpm2P3Nq/1xWhpcRAfyc42Ii
 SGBgp53CyL0n/D90VZ7ZcHZjBiduN6cwZFma5LO39Gh12eu8qhqd6IzGDDv/LbCVg6S1vlv8c/E
 WqlTcgNTk+bDOqATlOtcvfjiVi0IxrSqlRWYphFs11fJ3Am0EPW6b8+7/nC5Qfyay4Syy9Ou8dF
 opuGz9/JrGnZGtDbfLg1kU0tLx/NsgltEqhriT3L2nZLfSWAYV3zC4A7LFw1A2PIYEBzuYwGEs1
 26ufm52NX6NrJTfmjRV27LvRm6uhO+sxDt1I6F0VbAKUUF+qA00EKr/fesJL1YNVvTdj6qJoHOi
 umDQZEUpr3IRYUQt5RhUPa7F5QF8x99WlGOW/i5m1laCXa5sMtJOM2pCVXDR31tGaIdD8/O7Agf
 +gvCZrBOevdtWPuoFcS+7ETCWiR6b6Xp+hKzs5hIDAvRyvJI41rknc86fSuvV47zqs3k9adALLE
 JjLzh7sObruOqVA==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/20260831 with auth_id=991
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pidfds can cross pid namespace boundaries: a task may obtain one for a
process outside of its own pid namespace hierarchy through SO_PASSPIDFD
or SO_PEERPIDFD, via SCM_RIGHTS, or through file descriptor inheritance.

The namespace ioctls gate access with a ptrace check against the
target's credentials only. That check does not account for the pid
namespace relationship between the caller and the target, so a task
inside a pid namespace can use a pidfd obtained across that boundary to
acquire namespace file descriptors of a task outside of its hierarchy.

procfs exposes the equivalent information only for tasks visible in the
reader's pid namespace, and PIDFD_GET_INFO already answers with -EREMOTE
for targets outside the caller's hierarchy. Extend that policy to the
namespace ioctls: fail with -EREMOTE unless the target is visible in the
caller's active pid namespace. Callers in ancestor pid namespaces are
unaffected.

Unlike PIDFD_GET_INFO, the visibility check is performed after the task
lookup here, so reaped targets outside of the caller's pid namespace
hierarchy answer -ESRCH instead of -EREMOTE.

Link: https://lore.kernel.org/all/CAG48ez1T5-tUHVK_iHsgUtWa-inVdrZxA3E-ZCW0iENJvasKfg@mail.gmail.com
Link: https://lore.kernel.org/all/20260925-gewischt-auftrag-tierzucht-c153cb3f9f74@brauner
Suggested-by: Jann Horn <jannh@google.com>
Suggested-by: Christian Brauner <brauner@kernel.org>
Signed-off-by: Chen Linxuan <me@black-desk.cn>
---
This patch was previously submitted as patch 1/4 of the task path ioctl
series v3. It is now submitted independently because it changes access
to existing namespace ioctls and does not depend on the new path ioctls.

The code and commit message are unchanged from v3 1/4. The patch has
been rebased onto current mainline. A revised task path ioctl series
will follow separately and depend on this patch.

Previous submission:
https://lore.kernel.org/all/20261010-pidfd-get-paths-v3-1-f245440b2b30@black-desk.cn/
---
 fs/pidfs.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/fs/pidfs.c b/fs/pidfs.c
index 7f8c323ce6cb..cfb93c4ccf23 100644
--- a/fs/pidfs.c
+++ b/fs/pidfs.c
@@ -556,6 +556,14 @@ static long pidfd_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
 	if (arg)
 		return -EINVAL;
 
+	/*
+	 * Require the target to be visible in the caller's pid namespace
+	 * for operations that grant access to its resources, mirroring
+	 * procfs and PIDFD_GET_INFO.
+	 */
+	if (!pid_in_current_pidns(pidfd_pid(file)))
+		return -EREMOTE;
+
 	/*
 	 * We're trying to open a file descriptor to the namespace so perform a
 	 * filesystem cred ptrace check. Hold @task's exec_update_lock for the

---
base-commit: d135ab453a7400a34930bdda1ef4bdc8acfac80e
change-id: 20261027-pidfd-task-access-b797ecb260a4

Best regards,
--  
Chen Linxuan <me@black-desk.cn>

