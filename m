From: Chen Linxuan <me@black-desk.cn>
Date: Thu, 20 Aug 2026 13:45:41 +0800
Subject: [PATCH RFC 3/3] pidfd: Add task path ioctls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260820-pidfd-get-paths-v1-3-ac3eee4003d5@black-desk.cn>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3688; i=me@black-desk.cn;
 h=from:subject:message-id; bh=SyCJ8ZXQnkLR08IG8rcsufXrwQOP/Lvf27zOyLS7qI4=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBqhpSJDhbniXO7VTnsBnYigbwYSqL0ydwoM9Upl
 DHXQvTB+v2JAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCaoaUiQAKCRB2HuYUOZmu
 i4uqD/44j22S8gnOub6Zv/RbvFFh+uGAZv+rI+zrZnRo0odFcT7RMRBXrmCjhgzjHaCfSGEh3go
 mKUGkE2toky5oYmwVGdcLNETa6r8Fkw8ejN2u4djgO+k1WnqZ85vWLv4dw6ztS/tvP3UYr2ZzyW
 oXz7bbJi2+QWDj5dJibicHISv2mJzbin7aoW81vuYpFbXKQDlQ3UfeweBr6KqOC+z2qAh+BzQy9
 fLpiupREES4xfVqGiNsx0ZdUNNuBvyopwM/y+MzSw2y06+yNVoALSW0wbLAb1q8ixeyb1Wm4l20
 Mn65ZwUpyoVIyFZ6eYmiI6QyNFQ0SIjBg0Tjs/1FBWh4+70HRdr6ozRgAd0ebsXnUc1B82Qyb6u
 c8D+jhn1Q74lzZis9aBVXdVk1HG4dx2qeWS4uRGyHEFQSNaymcwQLVZRHu+jDL+2A8yqmQozWgQ
 k3LlT8i6AXHTO9pM5L+8Nqt5DrL1jixakTMoy0+thK3k6hGAt6vLgRQ41W0nP3qABxzeR86v0hX
 daVgR6Jia3Lbl08T0/Y15G3+fYNwOyrt923CwlW+KUEzTUbqaPbdQx7nq+ppTkW71oAyeOBqtOT
 7NVEMgwxydtPT1Xwk5+b/ORdVJmf+emeBIERqfcH2Or+zLQr5iT94ebNJjbUITowzwY/iWNFCpV
 QISSKSU3JhyWBjQ==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/default with auth_id=573
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add PIDFD_GET_EXE, PIDFD_GET_CWD, and PIDFD_GET_ROOT to return
close-on-exec O_PATH file descriptors referencing the target task's
executable, working directory, and root directory.

The new ioctls use the same PTRACE_MODE_READ_FSCREDS permission check
and nonzero-argument rejection as the existing namespace ioctls.  The
target is sampled while holding exec_update_lock so that the access
check and path read cannot race with execve().

This allows userspace to obtain stable path references from a pidfd
without requiring procfs.

Assisted-by: codex:glm-5.3
Signed-off-by: Chen Linxuan <me@black-desk.cn>
---
 fs/pidfs.c                 | 38 ++++++++++++++++++++++++++++++++++++++
 include/uapi/linux/pidfd.h |  7 +++++++
 2 files changed, 45 insertions(+)

diff --git a/fs/pidfs.c b/fs/pidfs.c
index 39e1e7ad9b2b..95b079d0de0d 100644
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
 
@@ -682,9 +686,31 @@ static struct ns_common *pidfd_get_namespace(struct pid *pid,
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
@@ -702,6 +728,18 @@ static long pidfd_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
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
+		return FD_ADD(O_CLOEXEC,
+			      dentry_open(&path, O_PATH, current_cred()));
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
2.53.0

