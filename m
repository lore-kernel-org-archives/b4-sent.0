From: Chen Linxuan <me@black-desk.cn>
Date: Sat, 10 Oct 2026 18:20:53 +0800
Subject: [PATCH v3 4/4] pidfd: Add task path ioctls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-pidfd-get-paths-v3-4-f245440b2b30@black-desk.cn>
References: <20261010-pidfd-get-paths-v3-0-f245440b2b30@black-desk.cn>
In-Reply-To: <20261010-pidfd-get-paths-v3-0-f245440b2b30@black-desk.cn>
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
 "Serge E. Hallyn" <serge@hallyn.com>, Jann Horn <jannh@google.com>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, apparmor@lists.ubuntu.com, 
 linux-security-module@vger.kernel.org, linux-api@vger.kernel.org, 
 Chen Linxuan <me@black-desk.cn>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3684; i=me@black-desk.cn;
 s=20260831; h=from:subject:message-id;
 bh=+1T/PPCKeQZBRhmKsitYw/Ec11LSxu55a/COLMCLNMo=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBqyhGeHSAru4tTGfalbmhoJcNYCzEfByYH/LxTw
 ceuZnHmKJqJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCasoRngAKCRB2HuYUOZmu
 i5twEADKSVdmpTk/nlZ00M+zdAAWq5/SBTf3ZXGeIyz2tgTjNQ2eIUOYGbg+Sy1YQmPJN4KfCEi
 EBLl26OkJC+9e21ly5xdiJF2opwxIM6FprQCfbAvvR0tYFo3M6YaBcXyhNJRJrMKFxZRtUCH3g8
 cFqLBHG0tDO0fwV6aad/1Y7Fl41Xm2eQX1DsBPwgBk3VqVHFiX+v8XO1Ml0p7YdBIXkJRr69gzQ
 xDOXqz5g9mlj+uFKJVORHK0/LN86AwA00XSrkxPWAGKkJ70eHJhScBwPlFHQHQaWKysfR95hYBx
 1dHy2E7U0N9Y0/pucsHV1ADMNBuFGnorz8bSVQ3blRYwYpCLM68esUqA4vbxv/xNfgcOb30dkWq
 M71eXmfaKuFDmb8CYrE0obRhgU99t4i8C+uJmAlNUe8roFQ1llVN3HlT6ywworrKBiY9rnKXJaF
 7cesgSX3fAg1oHxwk5iCbhu8WD8TAVyQcf3mcxOwmIcfgxWkSfulqzWQpS7ZMzhVTHoUEvEmOnM
 5WC2NJs2rzbhaR7fDzElKWOvmHIpKPiUC+osQx18XlH+lcQ0fd6ib7mmBZzpVNsKoSNwIGLMCym
 hShy2bj27Y6swxJQZUarquzHkgabidlDe/III2wz2oyUriSdk01Q7Iwz6WOhaooZi0Z+I6okj2m
 OGvuJ09FgJHBJJg==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/20260831 with auth_id=991
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add PIDFD_GET_EXE, PIDFD_GET_CWD, and PIDFD_GET_ROOT to return
close-on-exec O_PATH file descriptors referencing the target task's
executable, working directory, and root directory.

The ioctls acquire the target through the shared task acquisition
helper and are thus subject to the same checks as the namespace
ioctls. The target is sampled while holding exec_update_lock so that
the access check and the path read cannot race with execve().

This allows userspace to obtain stable path references from a pidfd
without requiring procfs.

Assisted-by: LLM
Signed-off-by: Chen Linxuan <me@black-desk.cn>
---
 fs/pidfs.c                 | 38 ++++++++++++++++++++++++++++++++++++++
 include/uapi/linux/pidfd.h |  7 +++++++
 2 files changed, 45 insertions(+)

diff --git a/fs/pidfs.c b/fs/pidfs.c
index 82ab4dee55e5..e945c77bdc0e 100644
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
@@ -707,6 +733,18 @@ static long pidfd_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
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
2.55.0

