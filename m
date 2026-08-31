From: Chen Linxuan <me@black-desk.cn>
Date: Mon, 31 Aug 2026 10:59:06 +0800
Subject: [PATCH v2 1/3] fs: Introduce task path helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260831-pidfd-get-paths-v2-1-c59ea6a21b72@black-desk.cn>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=6540; i=me@black-desk.cn;
 s=20260831; h=from:subject:message-id;
 bh=5So2OP5xtxhWElec19b9ZT6vFlwvdbmJSxLeLau4rVo=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBqlO38hlMmWYrfhNP7tNxvYyk/trBioVtyxuO0L
 54fL84jSkCJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCapTt/AAKCRB2HuYUOZmu
 i/oQD/9roMaaNnUmCilRvUZYD8kg+6YObUuwkSY9d99SWki86zWmjnaICnVR+Zb2W8WBtOvGZKB
 6jJRoML7cvLT2hBpblOSeMCQNQK0aC6E3aAWlPdUCDesQdi77+V2pW7TEnve0oy2yGy2VI4Oehd
 h6cf2M5RlpdB2Qk2wd/ASa7xGgcF0UUx0Je/e6Z8kqyWrqaPGGcEr2kJiyDgQ5TnGcyS7etamrO
 wgif/QpDRx+2UYqUbGnAQh1eHfQFMlfKvI36EjtFBqaUCC5y2MC/AadKqtBcDaq6oJQCf7oS0/k
 dY8MXF5nEsqRAGoex3WZV2FMuRg6b8qo4ytELiFKlNsBY/a59YynuRiMzBqI0MsbAsGFYQznNa5
 88UDWMfpUTMB/7fS7xwyV1Sc8rI2fR3Vg7bfoRteDU1zUgrnfalv0MZSa+398Y3IBu0q0JRaVp5
 ECbyOznGF4D8gbD0IiXzV6XnInvJTX7UrfKEdzI4XU2UUWFEOyq/uXoTTZ/IOgDK+AR0tPjMbBr
 0We4F21C4pk/F5ZEhucZ8qdPYzCNRfCNkYt5zk8XXbd7biq9LJoDBPt3zFtDEAmohqdbzTfPeed
 zIt2DrJbd3/iU1BtXbZ1aP04uRnh1E2a+ha+noDPZQ/5tmZQ3OioxmWNeAtrv03A6onDNUibqlZ
 QAHLvTlgoussE/Q==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/20260831 with auth_id=991
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce helpers that acquire a referenced struct path for a task's
executable, root, and working directory. Reuse them for procfs task
links and AppArmor executable-path handling instead of duplicating file
and path reference handling at each call site.

Assisted-by: LLM
Signed-off-by: Chen Linxuan <me@black-desk.cn>
---
 fs/fs_struct.c            | 44 ++++++++++++++++++++++++++++++++++++++++++++
 fs/proc/base.c            | 34 ++--------------------------------
 include/linux/fs_struct.h |  3 +++
 include/linux/mm.h        |  1 +
 kernel/fork.c             | 21 +++++++++++++++++++++
 security/apparmor/task.c  | 12 +++---------
 6 files changed, 74 insertions(+), 41 deletions(-)

diff --git a/fs/fs_struct.c b/fs/fs_struct.c
index 34699f3b6f88..5c772896260a 100644
--- a/fs/fs_struct.c
+++ b/fs/fs_struct.c
@@ -10,6 +10,50 @@
 #include "internal.h"
 #include "mount.h"
 
+/**
+ * get_task_root - acquire a reference to the task's root path
+ * @task: The task.
+ * @root: The task's root path.
+ *
+ * Returns 0 if the task has a root path, or -ENOENT if it does not. The
+ * caller must release the path through path_put() on success.
+ */
+int get_task_root(struct task_struct *task, struct path *root)
+{
+	int ret = -ENOENT;
+
+	task_lock(task);
+	if (task->real_fs) {
+		get_fs_root(task->real_fs, root);
+		ret = 0;
+	}
+	task_unlock(task);
+
+	return ret;
+}
+
+/**
+ * get_task_pwd - acquire a reference to the task's working directory
+ * @task: The task.
+ * @pwd: The task's working directory.
+ *
+ * Returns 0 if the task has a working directory, or -ENOENT if it does not.
+ * The caller must release the path through path_put() on success.
+ */
+int get_task_pwd(struct task_struct *task, struct path *pwd)
+{
+	int ret = -ENOENT;
+
+	task_lock(task);
+	if (task->real_fs) {
+		get_fs_pwd(task->real_fs, pwd);
+		ret = 0;
+	}
+	task_unlock(task);
+
+	return ret;
+}
+
 /*
  * Replace the fs->{rootmnt,root} with {mnt,dentry}. Put the old values.
  * It can block.
diff --git a/fs/proc/base.c b/fs/proc/base.c
index 6a39de424f62..7e2c0538323c 100644
--- a/fs/proc/base.c
+++ b/fs/proc/base.c
@@ -206,31 +206,10 @@ static unsigned int __init pid_entry_nlink(const struct pid_entry *entries,
 	return count;
 }
 
-static int get_task_root(struct task_struct *task, struct path *root)
-{
-	int result = -ENOENT;
-
-	task_lock(task);
-	if (task->real_fs) {
-		get_fs_root(task->real_fs, root);
-		result = 0;
-	}
-	task_unlock(task);
-	return result;
-}
-
 static int proc_cwd_link(struct dentry *dentry, struct path *path,
 			 struct task_struct *task)
 {
-	int result = -ENOENT;
-
-	task_lock(task);
-	if (task->real_fs) {
-		get_fs_pwd(task->real_fs, path);
-		result = 0;
-	}
-	task_unlock(task);
-	return result;
+	return get_task_pwd(task, path);
 }
 
 static int proc_root_link(struct dentry *dentry, struct path *path,
@@ -1761,16 +1740,7 @@ static const struct file_operations proc_pid_set_comm_operations = {
 static int proc_exe_link(struct dentry *dentry, struct path *exe_path,
 			 struct task_struct *task)
 {
-	struct file *exe_file;
-
-	exe_file = get_task_exe_file(task);
-	if (exe_file) {
-		*exe_path = exe_file->f_path;
-		path_get(&exe_file->f_path);
-		fput(exe_file);
-		return 0;
-	} else
-		return -ENOENT;
+	return get_task_exe_path(task, exe_path);
 }
 
 static int call_proc_get_link(struct dentry *dentry, struct inode *inode, struct path *path_out)
diff --git a/include/linux/fs_struct.h b/include/linux/fs_struct.h
index 97eef8d3863d..fb725707754d 100644
--- a/include/linux/fs_struct.h
+++ b/include/linux/fs_struct.h
@@ -42,6 +42,9 @@ static inline void get_fs_pwd(struct fs_struct *fs, struct path *pwd)
 	read_sequnlock_excl(&fs->seq);
 }
 
+int get_task_root(struct task_struct *task, struct path *root);
+int get_task_pwd(struct task_struct *task, struct path *pwd);
+
 struct fs_struct *switch_fs_struct(struct fs_struct *new_fs);
 
 extern bool current_chrooted(void);
diff --git a/include/linux/mm.h b/include/linux/mm.h
index dd09c438fa23..a65f24b2e65b 100644
--- a/include/linux/mm.h
+++ b/include/linux/mm.h
@@ -4239,6 +4239,7 @@ extern int set_mm_exe_file(struct mm_struct *mm, struct file *new_exe_file);
 extern int replace_mm_exe_file(struct mm_struct *mm, struct file *new_exe_file);
 extern struct file *get_mm_exe_file(struct mm_struct *mm);
 extern struct file *get_task_exe_file(struct task_struct *task);
+int get_task_exe_path(struct task_struct *task, struct path *exe_path);
 
 extern void vm_stat_account(struct mm_struct *, vm_flags_t, long npages);
 
diff --git a/kernel/fork.c b/kernel/fork.c
index 416758c8a3d4..a493de3ae5c2 100644
--- a/kernel/fork.c
+++ b/kernel/fork.c
@@ -1371,6 +1371,27 @@ struct file *get_task_exe_file(struct task_struct *task)
 	return exe_file;
 }
 
+/**
+ * get_task_exe_path - acquire a reference to the task's executable path
+ * @task: The task.
+ * @exe_path: The task's executable path.
+ *
+ * Returns 0 if the task has an executable path, or -ENOENT if it does not.
+ * The caller must release the path through path_put() on success.
+ */
+int get_task_exe_path(struct task_struct *task, struct path *exe_path)
+{
+	struct file *exe_file = get_task_exe_file(task);
+
+	if (!exe_file)
+		return -ENOENT;
+
+	*exe_path = exe_file->f_path;
+	path_get(exe_path);
+	fput(exe_file);
+	return 0;
+}
+
 /**
  * get_task_mm - acquire a reference to the task's mm
  * @task: The task.
diff --git a/security/apparmor/task.c b/security/apparmor/task.c
index e16ff4130bc2..05cba261dd34 100644
--- a/security/apparmor/task.c
+++ b/security/apparmor/task.c
@@ -13,6 +13,7 @@
  */
 
 #include <linux/gfp.h>
+#include <linux/mm.h>
 #include <linux/ptrace.h>
 #include <linux/task_work.h>
 
@@ -330,22 +331,15 @@ int aa_may_ptrace(const struct cred *tracer_cred, struct aa_label *tracer,
 
 static const char *get_current_exe_path(char *buffer, int buffer_size)
 {
-	struct file *exe_file;
-	struct path p;
+	struct path p __free(path_put) = {};
 	const char *path_str;
 
-	exe_file = get_task_exe_file(current);
-	if (!exe_file)
+	if (get_task_exe_path(current, &p))
 		return ERR_PTR(-ENOENT);
-	p = exe_file->f_path;
-	path_get(&p);
 
 	if (aa_path_name(&p, FLAG_VIEW_SUBNS, buffer, &path_str, NULL, NULL))
 		path_str = ERR_PTR(-ENOMEM);
 
-	fput(exe_file);
-	path_put(&p);
-
 	return path_str;
 }
 

-- 
2.53.0

