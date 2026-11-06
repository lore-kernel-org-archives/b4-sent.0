From: Chen Linxuan <me@black-desk.cn>
Date: Fri, 06 Nov 2026 15:12:23 +0800
Subject: [PATCH v5 3/3] pidfd: Add task path ioctls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-pidfd-get-paths-v5-3-3147ce6571cb@black-desk.cn>
References: <20261106-pidfd-get-paths-v5-0-3147ce6571cb@black-desk.cn>
In-Reply-To: <20261106-pidfd-get-paths-v5-0-3147ce6571cb@black-desk.cn>
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
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=6126; i=me@black-desk.cn;
 s=20260831; h=from:subject:message-id;
 bh=8/4Y51OBEYzNS6FVvsAEjYBKd/ZHA5peUeskEw5337k=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBq7X3u1WnSUNq0WXH8R+Y9EmYhPf33sjCeRtisV
 ZlXZZtijM2JAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCau197gAKCRB2HuYUOZmu
 iz1lEADXkuPv6sF03vbyj+DqwSykq+Gnjlo3ud5LlHRMKcxnAF2WTi5WvaI2KDN1wUfYpCsi/Hg
 SDIin/97wXLOxvrnJK3u/D+IapIgPJIMttsypIrxAY7JSRLSx+X5EpGBKrHTou+RZ3nOzSwsnm9
 O9QLYyX00rJQE/N7OLfRAVR5v9VEkAYex8hsBWptEDIvgUmmLA6U2T7IxJeDYnYDQ/57AnZ+9eD
 0Pl5WoUELb5TIZ3YxZXIWyx/iEzD9yUyKtczWPpul8mVL92aL1mQHrqLC3dk6kwijoWLCl3Nf3R
 1PENdoUmUrvHgaO6XhR6DVuFtqcvA4vD2EsIKyhOrScbNyPNDi/aPE6xWd2Fsqv0dr1EvLTvMtE
 06q8vS1mjdcwG6KvjTqswTX0sNB8w3JmLl4i3jPKTYo4yDHQT2mpveI68i3teVcluNe37X0Awsp
 KDVFc4KLHIfZU2b/d3sIrdf8J2h8aKvlSPZ9kW0yd2VgOcpeUUtDjn6ggliSWaapCHtgs58li4W
 XI2zWuQFUZJQehRQsWJplR4Ns/jsNt+4pX5Se9GSIREUt/qJX27Qz97+ULE8NXnACnh2WNqLp4a
 015O8Q2+6Ras2yQMm7HA53VOQgB/B0Lo91DyWOv4BRb0xdr5Da5YVbjiNbEIVofjHBOBBdR6xgQ
 fhQUoDo6IsEkfSQ==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/20260831 with auth_id=991
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add PIDFD_GET_EXE, PIDFD_GET_CWD, and PIDFD_GET_ROOT so callers holding
a pidfd can obtain close-on-exec O_PATH file descriptors for the
target's executable, working directory, and root without requiring
procfs.

Use the task acquisition helper shared with the namespace ioctls to
check PID namespace visibility and ptrace access. Hold exec_update_lock
across the access check and path acquisition to prevent a concurrent
execve() from changing the target's credentials between them.

Add task_path_open() to perform weak revalidation before opening the
selected path. This gives the filesystem the opportunity to reject a
path handed out directly by a task, as it can when following a procfs
magic link. Pass flags zero because no pathname lookup is performed,
propagate negative errors, and return ESTALE for a zero result.

Release exec_update_lock before calling task_path_open() so filesystem
revalidation runs outside the target's exec critical section.

Suggested-by: Christian Brauner <brauner@kernel.org>
Link: https://lore.kernel.org/all/20261105-gefolge-rosten-neueinstellung-6223a18aae90@brauner/
Signed-off-by: Chen Linxuan <me@black-desk.cn>
---
 fs/internal.h              |  1 +
 fs/open.c                  | 30 ++++++++++++++++++++++++++++++
 fs/pidfs.c                 | 37 +++++++++++++++++++++++++++++++++++++
 include/uapi/linux/pidfd.h |  7 +++++++
 4 files changed, 75 insertions(+)

diff --git a/fs/internal.h b/fs/internal.h
index e833c7e6e14f..799495ce3d98 100644
--- a/fs/internal.h
+++ b/fs/internal.h
@@ -207,6 +207,7 @@ int do_fchownat(int dfd, const char __user *filename, uid_t user, gid_t group,
 int chown_common(const struct path *path, uid_t user, gid_t group);
 extern int vfs_open(const struct path *, struct file *);
 int vfs_open_consume(struct path *, struct file *);
+struct file *task_path_open(const struct path *path);
 
 /*
  * inode.c
diff --git a/fs/open.c b/fs/open.c
index e43f02ff64ac..55441ff0525c 100644
--- a/fs/open.c
+++ b/fs/open.c
@@ -1156,6 +1156,36 @@ struct file *dentry_open(const struct path *path, int flags,
 }
 EXPORT_SYMBOL(dentry_open);
 
+/**
+ * task_path_open - open a path handed out by a task
+ * @path: the task's path
+ *
+ * Open a task's exe, cwd or root for the caller. The path wasn't found by
+ * a lookup, it's handed out directly, the same way a /proc/<pid>/{exe,cwd,root}
+ * jump lands on it. So give the filesystem the chance to refuse it that
+ * complete_walk() gives it for a jumped dentry.
+ *
+ * Only O_PATH opens are supported. Anything else would need the permission
+ * checks a lookup performs before the open.
+ *
+ * Return: An O_PATH file on success, an error pointer on failure.
+ */
+struct file *task_path_open(const struct path *path)
+{
+	struct dentry *dentry = path->dentry;
+
+	if (unlikely(dentry->d_flags & DCACHE_OP_WEAK_REVALIDATE)) {
+		int status = dentry->d_op->d_weak_revalidate(dentry, 0);
+
+		if (status < 0)
+			return ERR_PTR(status);
+		if (!status)
+			return ERR_PTR(-ESTALE);
+	}
+
+	return dentry_open(path, O_PATH, current_cred());
+}
+
 struct file *dentry_open_nonotify(const struct path *path, int flags,
 				  const struct cred *cred)
 {
diff --git a/fs/pidfs.c b/fs/pidfs.c
index b70ec50f64da..6eeaad3135de 100644
--- a/fs/pidfs.c
+++ b/fs/pidfs.c
@@ -4,6 +4,7 @@
 #include <linux/exportfs.h>
 #include <linux/file.h>
 #include <linux/fs.h>
+#include <linux/fs_struct.h>
 #include <linux/cgroup.h>
 #include <linux/magic.h>
 #include <linux/mount.h>
@@ -510,6 +511,9 @@ static bool pidfs_ioctl_valid(unsigned int cmd)
 	case PIDFD_GET_UTS_NAMESPACE:
 	case PIDFD_GET_USER_NAMESPACE:
 	case PIDFD_GET_PID_NAMESPACE:
+	case PIDFD_GET_EXE:
+	case PIDFD_GET_CWD:
+	case PIDFD_GET_ROOT:
 		return true;
 	}
 
@@ -687,9 +691,31 @@ static struct ns_common *pidfd_get_namespace(struct pid *pid,
 	return ns_common;
 }
 
+static int pidfd_get_task_path(struct pid *pid, unsigned int cmd,
+			       unsigned long arg, struct path *path)
+{
+	CLASS(pidfd_task_locked, task)(pid, arg);
+
+	if (IS_ERR(task))
+		return PTR_ERR(task);
+
+	switch (cmd) {
+	case PIDFD_GET_EXE:
+		return get_task_exe_path(task, path);
+	case PIDFD_GET_CWD:
+		return get_task_pwd(task, path);
+	case PIDFD_GET_ROOT:
+		return get_task_root(task, path);
+	}
+
+	return -EINVAL;
+}
+
 static long pidfd_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
 {
 	struct ns_common *ns_common = NULL;
+	struct path path __free(path_put) = {};
+	int error;
 
 	if (!pidfs_ioctl_valid(cmd))
 		return -ENOIOCTLCMD;
@@ -707,6 +733,17 @@ static long pidfd_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
 	if (_IOC_NR(cmd) == _IOC_NR(PIDFD_GET_INFO))
 		return pidfd_info(file, cmd, arg);
 
+	switch (cmd) {
+	case PIDFD_GET_EXE:
+	case PIDFD_GET_CWD:
+	case PIDFD_GET_ROOT:
+		error = pidfd_get_task_path(pidfd_pid(file), cmd, arg, &path);
+		if (error)
+			return error;
+
+		return FD_ADD(O_CLOEXEC, task_path_open(&path));
+	}
+
 	ns_common = pidfd_get_namespace(pidfd_pid(file), cmd, arg);
 	if (IS_ERR(ns_common))
 		return PTR_ERR(ns_common);
diff --git a/include/uapi/linux/pidfd.h b/include/uapi/linux/pidfd.h
index 0919246a1611..95ce1819f423 100644
--- a/include/uapi/linux/pidfd.h
+++ b/include/uapi/linux/pidfd.h
@@ -121,4 +121,11 @@ struct pidfd_info {
 #define PIDFD_GET_UTS_NAMESPACE               _IO(PIDFS_IOCTL_MAGIC, 10)
 #define PIDFD_GET_INFO                        _IOWR(PIDFS_IOCTL_MAGIC, 11, struct pidfd_info)
 
+/* Return an O_PATH file descriptor for the target task's executable. */
+#define PIDFD_GET_EXE                         _IO(PIDFS_IOCTL_MAGIC, 12)
+/* Return an O_PATH file descriptor for the target task's working directory. */
+#define PIDFD_GET_CWD                         _IO(PIDFS_IOCTL_MAGIC, 13)
+/* Return an O_PATH file descriptor for the target task's root directory. */
+#define PIDFD_GET_ROOT                        _IO(PIDFS_IOCTL_MAGIC, 14)
+
 #endif /* _UAPI_LINUX_PIDFD_H */

-- 
2.56.0

