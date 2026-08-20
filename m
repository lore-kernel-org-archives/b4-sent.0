From: Chen Linxuan <me@black-desk.cn>
Date: Thu, 20 Aug 2026 13:45:40 +0800
Subject: [PATCH RFC 2/3] pidfd: Use scoped cleanup for task access
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260820-pidfd-get-paths-v1-2-ac3eee4003d5@black-desk.cn>
References: <20260820-pidfd-get-paths-v1-0-ac3eee4003d5@black-desk.cn>
In-Reply-To: <20260820-pidfd-get-paths-v1-0-ac3eee4003d5@black-desk.cn>
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
 linux-security-module@vger.kernel.org, Chen Linxuan <me@black-desk.cn>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5184; i=me@black-desk.cn;
 h=from:subject:message-id; bh=KBo9FLg9vQy1MB4oOYDcDc0kQebzYNbPiSNI8fLNAR0=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBqhpSIhKwGZauH3fC6nxip9ANmNISsp+MKbUnCe
 /TrubcJkUmJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCaoaUiAAKCRB2HuYUOZmu
 ixmID/41QbF14zMynFNvfg9xr0TvYsQnr5aSI0j2biffLrXEfTAP6BRpHjSCrg/K/mp9z703xWm
 EdtYRqlXwDUSPzZ8NSsaryeHXNlsADwpA2/9lzhbUfHlunyJ1OiboJCDp6AMophJj2WjqYKxwSl
 7WSKaF1HJS0fttFvQK9Bn6tVW80AvAHRbwOQZyLXGpW1dO59yI1Zcsuo9gXYqZlMI/6JGaV/b1b
 1hIm9lRiuEBgbJKLZf04LdGEzbS343+JOOqyfTK5BPxqDxNzTUhVPbT+hz2jOcG4KkHFAC9ij0G
 WBJC5NVICg5EAvvuO60Tl0V7AHNoopxdlgO5z/7IK6eHG1e152EmwKHVsouyJWSOepeD0A7Uz2o
 q48TzL3h3HmOJ9GBTignvke9t6TBPDriI6GxUlctkca3hh1hRPQglvXItNlt+DZRlffizuumBlr
 5vkMGB+9ZCnPh/9LTa4l3jrXlLHw5+ZGLQzsUJ8tRb8THJx3Fnvha4+Eq3GkvuA/w4eGQqRJw+c
 AFG0KKBtIZvGZCkokmw8vnMxiPah60Qg7VKrwqQ1kNiDsgrFr3YLZZFKxc/bgqkj3Kw9LirC7Si
 mYvrooo55v/G9MB5TyyLeW3g9JaO6LBMR4pzS5PMLnhe8LyEEkx9cIlMX9HEojUK3DInni74x8k
 Ze3Wt7ddjFy833A==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/default with auth_id=573
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Split namespace acquisition from namespace fd creation and represent a
privileged target task as a scoped class that owns both the task
reference and exec_update_lock. Use the class for namespace lookups so
ptrace access checks and task state reads remain tied to the same exec
critical section, while open_namespace() stays outside the lock.

Assisted-by: codex:glm-5.3
Signed-off-by: Chen Linxuan <me@black-desk.cn>
---
 fs/pidfs.c | 123 ++++++++++++++++++++++++++++++++++++++-----------------------
 1 file changed, 77 insertions(+), 46 deletions(-)

diff --git a/fs/pidfs.c b/fs/pidfs.c
index a6a643f15d08..39e1e7ad9b2b 100644
--- a/fs/pidfs.c
+++ b/fs/pidfs.c
@@ -527,62 +527,71 @@ static bool pidfs_ioctl_valid(unsigned int cmd)
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
+	struct task_struct *task = get_pid_task(pid, PIDTYPE_PID);
+	int error;
 
-	task = get_pid_task(pidfd_pid(file), PIDTYPE_PID);
 	if (!task)
-		return -ESRCH;
+		return ERR_PTR(-ESRCH);
 
-	if (arg)
-		return -EINVAL;
+	if (arg) {
+		put_task_struct(task);
+		return ERR_PTR(-EINVAL);
+	}
 
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
-	if (error)
-		return error;
+	if (error) {
+		put_task_struct(task);
+		return ERR_PTR(error);
+	}
 
 	if (!ptrace_may_access(task, PTRACE_MODE_READ_FSCREDS)) {
-		error = -EACCES;
-		goto out_unlock;
+		up_read(&task->signal->exec_update_lock);
+		put_task_struct(task);
+		return ERR_PTR(-EACCES);
 	}
 
+	return task;
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
@@ -664,16 +673,38 @@ static long pidfd_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
 #endif
 		break;
 	default:
-		error = -ENOIOCTLCMD;
+		return ERR_PTR(-ENOIOCTLCMD);
+	}
+
+	if (!ns_common)
+		return ERR_PTR(-EOPNOTSUPP);
+
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
 	}
 
-	if (!error && !ns_common)
-		error = -EOPNOTSUPP;
+	/* Extensible IOCTL that does not open namespace FDs, take a shortcut */
+	if (_IOC_NR(cmd) == _IOC_NR(PIDFD_GET_INFO))
+		return pidfd_info(file, cmd, arg);
 
-out_unlock:
-	up_read(&task->signal->exec_update_lock);
-	if (error)
-		return error;
+	ns_common = pidfd_get_namespace(pidfd_pid(file), cmd, arg);
+	if (IS_ERR(ns_common))
+		return PTR_ERR(ns_common);
 
 	/* open_namespace() unconditionally consumes the reference */
 	return open_namespace(ns_common);

-- 
2.53.0

