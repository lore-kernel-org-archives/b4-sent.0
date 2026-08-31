From: Chen Linxuan <me@black-desk.cn>
Date: Mon, 31 Aug 2026 10:59:07 +0800
Subject: [PATCH v2 2/3] pidfd: Use scoped cleanup for task access
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260831-pidfd-get-paths-v2-2-c59ea6a21b72@black-desk.cn>
References: <20260831-pidfd-get-paths-v2-0-c59ea6a21b72@black-desk.cn>
In-Reply-To: <20260831-pidfd-get-paths-v2-0-c59ea6a21b72@black-desk.cn>
To: Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, Ingo Molnar <mingo@redhat.com>, 
 Peter Zijlstra <peterz@infradead.org>, Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>, 
 K Prateek Nayak <kprateek.nayak@amd.com>, Kees Cook <kees@kernel.org>, 
 John Johansen <john.johansen@canonical.com>, 
 Georgia Garcia <georgia.garcia@canonical.com>, 
 Paul Moore <paul@paul-moore.com>, James Morris <jmorris@namei.org>, 
 "Serge E. Hallyn" <serge@hallyn.com>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, apparmor@lists.ubuntu.com, 
 linux-security-module@vger.kernel.org, linux-api@vger.kernel.org, 
 Chen Linxuan <me@black-desk.cn>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5079; i=me@black-desk.cn;
 s=20260831; h=from:subject:message-id;
 bh=SVmkrkqreGdyu4HBET8Otf2T/l+VOx0ddobGuHRudwA=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBqlO38jtoUK7Zb2KaX9LmA95hJa9Ar2TOqQKP0Y
 mknRd85v6uJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCapTt/AAKCRB2HuYUOZmu
 i5X5EACIqaukJokPjfQSlW5sUrgCjOuBxwqea6WJwCreP8MQShFKmwjR4Qmbul9kBNZMsGgkWgD
 pHbwT8els8YMxEYg+Pf1exMDyQJTlhXjpgpIKZKRbDo154/bfblKtzFjAqQVQdWt7JnLv71ric9
 u6squ8kjcsenN0dhwuO8Y00xsDBdD2HJm0mpw+smScEDAbqoZuFrrU7+3nb6EJGVelkXIIWtIjv
 fZrX57jCQCpNBCBlihI1FoX9RW+JEaoII/mVrXK/RfZmgWBBHKt32vCiW0T4TsXbgxsIKKaS7VV
 nRrGBERlyFyufsbAXVuQIcfpvvnt0Rm96XBpfR9OhLptzD1Wi+mI69M+QOXccIs2HGrK2TwtAzI
 LP34Z4zSZAWMbafTwNO6ZBy3zRnEFaKjAaPHAcc1Dl1UWS2SzT38ANIrlI5bpEDxKqlqZFL2JLa
 lKrhCX4nG7CDqSZ6freKOsne110U/HFPFSs7uyU7pUcPLEHlsbXIibjCMTiBEq53yebl+ka2vxA
 oeWS7CnAxRaAh+FitafaT41X3gyg9Bhhjn0C2PCRg1TqnieM3QG1mBkHxh3B/8Xb2cDZ9hfmH9T
 5dhHrLPxUHWf2X1YLnQMwQarcA7H69XPnF8qpf5KLAGo3HE1EFSNKM5WusZhqK394lWi2VIp6Qg
 RjwpZnuocjYlECA==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/20260831 with auth_id=991
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Split namespace acquisition from namespace fd creation and represent a
privileged target task as a scoped class that owns both the task
reference and exec_update_lock. Use the class for namespace lookups so
ptrace access checks and task state reads remain tied to the same exec
critical section, while open_namespace() stays outside the lock.

Assisted-by: LLM
Signed-off-by: Chen Linxuan <me@black-desk.cn>
---
 fs/pidfs.c | 115 ++++++++++++++++++++++++++++++++++++++-----------------------
 1 file changed, 71 insertions(+), 44 deletions(-)

diff --git a/fs/pidfs.c b/fs/pidfs.c
index a6a643f15d08..49a1ab0c42f9 100644
--- a/fs/pidfs.c
+++ b/fs/pidfs.c
@@ -527,62 +527,67 @@ static bool pidfs_ioctl_valid(unsigned int cmd)
 	return false;
 }
 
-static long pidfd_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
+static inline void pidfd_put_task_locked(struct task_struct *task)
 {
-	struct task_struct *task __free(put_task) = NULL;
-	struct nsproxy *nsp __free(put_nsproxy) = NULL;
-	struct ns_common *ns_common = NULL;
-	int error;
-
-	if (!pidfs_ioctl_valid(cmd))
-		return -ENOIOCTLCMD;
-
-	if (cmd == FS_IOC_GETVERSION) {
-		if (!arg)
-			return -EINVAL;
-
-		__u32 __user *argp = (__u32 __user *)arg;
-		return put_user(file_inode(file)->i_generation, argp);
+	if (!IS_ERR_OR_NULL(task)) {
+		up_read(&task->signal->exec_update_lock);
+		put_task_struct(task);
 	}
+}
 
-	/* Extensible IOCTL that does not open namespace FDs, take a shortcut */
-	if (_IOC_NR(cmd) == _IOC_NR(PIDFD_GET_INFO))
-		return pidfd_info(file, cmd, arg);
+/*
+ * Return @pid's task with @task's exec_update_lock held. The ptrace check
+ * and the callers' task state lookup must be performed while the lock is held
+ * so that they cannot race with a concurrent execve().
+ */
+static struct task_struct *pidfd_get_task_locked(struct pid *pid,
+						 unsigned long arg)
+{
+	struct task_struct *task __free(put_task) =
+		get_pid_task(pid, PIDTYPE_PID);
+	int error;
 
-	task = get_pid_task(pidfd_pid(file), PIDTYPE_PID);
 	if (!task)
-		return -ESRCH;
+		return ERR_PTR(-ESRCH);
 
 	if (arg)
-		return -EINVAL;
+		return ERR_PTR(-EINVAL);
 
-	/*
-	 * We're trying to open a file descriptor to the namespace so perform a
-	 * filesystem cred ptrace check. Hold @task's exec_update_lock for the
-	 * duration of the ptrace check and the namespace lookup so that the
-	 * credentials used for the access decision match those of @task at the
-	 * time its namespace is read, preventing a concurrent execve() from
-	 * swapping the task's credentials in between the check and the use. We
-	 * mirror nsfs behavior.
-	 */
 	error = down_read_killable(&task->signal->exec_update_lock);
 	if (error)
-		return error;
+		return ERR_PTR(error);
 
 	if (!ptrace_may_access(task, PTRACE_MODE_READ_FSCREDS)) {
-		error = -EACCES;
-		goto out_unlock;
+		up_read(&task->signal->exec_update_lock);
+		return ERR_PTR(-EACCES);
 	}
 
+	return_ptr(task);
+}
+
+DEFINE_CLASS(pidfd_task_locked, struct task_struct *,
+	     pidfd_put_task_locked(_T),
+	     pidfd_get_task_locked(pid, arg),
+	     struct pid *pid, unsigned long arg)
+
+static struct ns_common *pidfd_get_namespace(struct pid *pid,
+					     unsigned int cmd,
+					     unsigned long arg)
+{
+	struct nsproxy *nsp __free(put_nsproxy) = NULL;
+	struct ns_common *ns_common = NULL;
+
+	CLASS(pidfd_task_locked, task)(pid, arg);
+	if (IS_ERR(task))
+		return ERR_CAST(task);
+
 	scoped_guard(task_lock, task) {
 		nsp = task->nsproxy;
 		if (nsp)
 			get_nsproxy(nsp);
 	}
-	if (!nsp) {
-		error = -ESRCH; /* just pretend it didn't exist */
-		goto out_unlock;
-	}
+	if (!nsp)
+		return ERR_PTR(-ESRCH); /* just pretend it didn't exist */
 
 	switch (cmd) {
 	/* Namespaces that hang of nsproxy. */
@@ -664,16 +669,38 @@ static long pidfd_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
 #endif
 		break;
 	default:
-		error = -ENOIOCTLCMD;
+		return ERR_PTR(-ENOIOCTLCMD);
 	}
 
-	if (!error && !ns_common)
-		error = -EOPNOTSUPP;
+	if (!ns_common)
+		return ERR_PTR(-EOPNOTSUPP);
 
-out_unlock:
-	up_read(&task->signal->exec_update_lock);
-	if (error)
-		return error;
+	return ns_common;
+}
+
+static long pidfd_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
+{
+	struct ns_common *ns_common = NULL;
+
+	if (!pidfs_ioctl_valid(cmd))
+		return -ENOIOCTLCMD;
+
+	if (cmd == FS_IOC_GETVERSION) {
+		if (!arg)
+			return -EINVAL;
+
+		__u32 __user *argp = (__u32 __user *)arg;
+
+		return put_user(file_inode(file)->i_generation, argp);
+	}
+
+	/* Extensible IOCTL that does not open namespace FDs, take a shortcut */
+	if (_IOC_NR(cmd) == _IOC_NR(PIDFD_GET_INFO))
+		return pidfd_info(file, cmd, arg);
+
+	ns_common = pidfd_get_namespace(pidfd_pid(file), cmd, arg);
+	if (IS_ERR(ns_common))
+		return PTR_ERR(ns_common);
 
 	/* open_namespace() unconditionally consumes the reference */
 	return open_namespace(ns_common);

-- 
2.53.0

