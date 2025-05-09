From: Chen Linxuan <chenlinxuan@uniontech.com>
Date: Fri, 09 May 2025 14:33:54 +0800
Subject: [PATCH v3 2/3] fs: fuse: add backing_files control file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250509-fusectl-backing-files-v3-2-393761f9b683@uniontech.com>
References: <20250509-fusectl-backing-files-v3-0-393761f9b683@uniontech.com>
In-Reply-To: <20250509-fusectl-backing-files-v3-0-393761f9b683@uniontech.com>
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: Amir Goldstein <amir73il@gmail.com>, linux-fsdevel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Chen Linxuan <chenlinxuan@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=7805;
 i=chenlinxuan@uniontech.com; h=from:subject:message-id;
 bh=+MhiJZwoWBEljdQr/g8U8P1eFwU3TeweBp7OoYHMYik=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBoHaHjlZztZa9asbobQfJ6ybAhCz/sgZvkKgJ0V
 LhCrh2UbzGJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCaB2h4wAKCRB2HuYUOZmu
 i0hxEACJUzDyG8zVO4zljqlbg7Snng6KjRromE1dhqx++/N+gYmwoalV7kk1YevRdst4mhkRDA8
 Qf9TXajVoW99WUY3HyJm0cB+9rzfl2ACHzlnF9pnhl72Dfu6Bw4LbqxVjiylPpq/f9rui2bR8al
 J+Mln5v9SR2BUfEHmhF3y6U6nBkZQu0G3rkXyx9xV23RiaDOvP9bgdQK8reqFv0UmrTS+shciup
 3U+LS94CRFKPfolxA/+g2pC3k71f8LPFlUKepcYiwr68q++ADog7KpKwivq/GICo/Tsck63PfOd
 kyZQTL5pdZ53e5cS0B/z4fhxG/38E0jpAEmAE10Mm/7gXxg4PZA0SPMt/kGJSJwLE3X/PuA1wr3
 wIHYOATMG8IGKN1SdX9zGoS1oE6rdUq+v6lnTlACTBpxowh817/TXbRgoulNaoOuNPfJf3vV0wF
 1ah04gXfGeTlo6WmxK/nA/Ngp+gB7lqoTEI9g+q1nkcx/aniX7fPTKfUGMjBFsxEIzZGN6lnvuw
 WbQGUGNh6XWn8neGwnwhMma8OMKS/6JQuVWVNvRbzgb5HfXeZe5hOLVxuhfxd6UVtRKrg+S7cbQ
 Ata9mF5xEY1/PHMnxSddUQb6sW7gw5ty5+lK4coRPnDBg0Hno9RSPgjSm2cyMwrW19GOuduoDDs
 YkFs8dyM/meXe7A==
X-Developer-Key: i=chenlinxuan@uniontech.com; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for chenlinxuan@uniontech.com/default with auth_id=380
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a new FUSE control file "/sys/fs/fuse/connections/*/backing_files"
that exposes the paths of all backing files currently being used in
FUSE mount points. This is particularly valuable for tracking and
debugging files used in FUSE passthrough mode.

This approach is similar to how fixed files in io_uring expose their
status through fdinfo, providing administrators with visibility into
backing file usage. By making backing files visible through the FUSE
control filesystem, administrators can monitor which files are being
used for passthrough operations and can force-close them if needed by
aborting the connection.

This exposure of backing files information is an important step towards
potentially relaxing CAP_SYS_ADMIN requirements for certain passthrough
operations in the future, allowing for better security analysis of
passthrough usage patterns.

The control file is implemented using the seq_file interface for
efficient handling of potentially large numbers of backing files.
Access permissions are set to read-only (0400) as this is an
informational interface.

FUSE_CTL_NUM_DENTRIES has been increased from 5 to 6 to accommodate the
additional control file.

Some related discussions can be found at links below.

Link: https://lore.kernel.org/all/4b64a41c-6167-4c02-8bae-3021270ca519@fastmail.fm/T/#mc73e04df56b8830b1d7b06b5d9f22e594fba423e
Link: https://lore.kernel.org/linux-fsdevel/CAOQ4uxhAY1m7ubJ3p-A3rSufw_53WuDRMT1Zqe_OC0bP_Fb3Zw@mail.gmail.com/
Cc: Amir Goldstein <amir73il@gmail.com>
Signed-off-by: Chen Linxuan <chenlinxuan@uniontech.com>
---
 fs/fuse/control.c | 155 +++++++++++++++++++++++++++++++++++++++++++++++++-----
 fs/fuse/fuse_i.h  |   2 +-
 2 files changed, 144 insertions(+), 13 deletions(-)

diff --git a/fs/fuse/control.c b/fs/fuse/control.c
index f0874403b1f7c91571f38e4ae9f8cebe259f7dd1..6333fffec85bd562dc9e86ba7cbf88b8bc2d68ce 100644
--- a/fs/fuse/control.c
+++ b/fs/fuse/control.c
@@ -11,6 +11,7 @@
 #include <linux/init.h>
 #include <linux/module.h>
 #include <linux/fs_context.h>
+#include <linux/seq_file.h>
 
 #define FUSE_CTL_SUPER_MAGIC 0x65735543
 
@@ -180,6 +181,135 @@ static ssize_t fuse_conn_congestion_threshold_write(struct file *file,
 	return ret;
 }
 
+struct fuse_backing_files_seq_state {
+	struct fuse_conn *fc;
+	int backing_id;
+};
+
+static void fuse_backing_files_seq_state_free(struct fuse_backing_files_seq_state *state)
+{
+	fuse_conn_put(state->fc);
+	kvfree(state);
+}
+
+static void *fuse_backing_files_seq_start(struct seq_file *seq, loff_t *pos)
+{
+	struct fuse_backing *fb;
+	struct fuse_backing_files_seq_state *state;
+	struct fuse_conn *fc;
+	int backing_id;
+	void *ret;
+
+	fc = fuse_ctl_file_conn_get(seq->file);
+	if (!fc)
+		return ERR_PTR(-ENOTCONN);
+
+	backing_id = *pos;
+
+	rcu_read_lock();
+
+	fb = idr_get_next(&fc->backing_files_map, &backing_id);
+
+	rcu_read_unlock();
+
+	if (!fb) {
+		ret = NULL;
+		goto err;
+	}
+
+	state = kmalloc(sizeof(*state), GFP_KERNEL);
+	if (!state) {
+		ret = ERR_PTR(-ENOMEM);
+		goto err;
+	}
+
+	state->fc = fc;
+	state->backing_id = backing_id;
+	*pos = backing_id;
+
+	ret = state;
+	return ret;
+
+err:
+	fuse_conn_put(fc);
+	return ret;
+}
+
+static void *fuse_backing_files_seq_next(struct seq_file *seq, void *v,
+					 loff_t *pos)
+{
+	struct fuse_backing_files_seq_state *state = v;
+	struct fuse_backing *fb;
+
+	state->backing_id++;
+
+	rcu_read_lock();
+
+	fb = idr_get_next(&state->fc->backing_files_map, &state->backing_id);
+
+	rcu_read_unlock();
+
+	if (!fb) {
+		fuse_backing_files_seq_state_free(state);
+		return NULL;
+	}
+
+	*pos = state->backing_id;
+
+	return state;
+}
+
+static int fuse_backing_files_seq_show(struct seq_file *seq, void *v)
+{
+	struct fuse_backing_files_seq_state *state = v;
+	struct fuse_conn *fc = state->fc;
+	struct fuse_backing *fb;
+
+	rcu_read_lock();
+
+	fb = idr_find(&fc->backing_files_map, state->backing_id);
+	fb = fuse_backing_get(fb);
+
+	rcu_read_unlock();
+
+	if (!fb)
+		return 0;
+
+	if (fb->file) {
+		seq_printf(seq, "%5u: ", state->backing_id);
+		seq_file_path(seq, fb->file, " \t\n\\");
+		seq_puts(seq, "\n");
+	}
+
+	fuse_backing_put(fb);
+	return 0;
+}
+
+static void fuse_backing_files_seq_stop(struct seq_file *seq, void *v)
+{
+	if (v)
+		fuse_backing_files_seq_state_free(v);
+}
+
+static const struct seq_operations fuse_backing_files_seq_ops = {
+	.start = fuse_backing_files_seq_start,
+	.next = fuse_backing_files_seq_next,
+	.stop = fuse_backing_files_seq_stop,
+	.show = fuse_backing_files_seq_show,
+};
+
+static int fuse_backing_files_seq_open(struct inode *inode, struct file *file)
+{
+	return seq_open(file, &fuse_backing_files_seq_ops);
+}
+
+static const struct file_operations fuse_conn_backing_files_ops = {
+	.open = fuse_backing_files_seq_open,
+	.read = seq_read,
+	.llseek = seq_lseek,
+	.release = seq_release,
+};
+
 static const struct file_operations fuse_ctl_abort_ops = {
 	.open = nonseekable_open,
 	.write = fuse_conn_abort_write,
@@ -204,8 +334,7 @@ static const struct file_operations fuse_conn_congestion_threshold_ops = {
 
 static struct dentry *fuse_ctl_add_dentry(struct dentry *parent,
 					  struct fuse_conn *fc,
-					  const char *name,
-					  int mode, int nlink,
+					  const char *name, int mode, int nlink,
 					  const struct inode_operations *iop,
 					  const struct file_operations *fop)
 {
@@ -262,20 +391,22 @@ int fuse_ctl_add_conn(struct fuse_conn *fc)
 	if (!parent)
 		goto err;
 
-	if (!fuse_ctl_add_dentry(parent, fc, "waiting", S_IFREG | 0400, 1,
-				 NULL, &fuse_ctl_waiting_ops) ||
-	    !fuse_ctl_add_dentry(parent, fc, "abort", S_IFREG | 0200, 1,
-				 NULL, &fuse_ctl_abort_ops) ||
+	if (!fuse_ctl_add_dentry(parent, fc, "waiting", S_IFREG | 0400, 1, NULL,
+				 &fuse_ctl_waiting_ops) ||
+	    !fuse_ctl_add_dentry(parent, fc, "abort", S_IFREG | 0200, 1, NULL,
+				 &fuse_ctl_abort_ops) ||
 	    !fuse_ctl_add_dentry(parent, fc, "max_background", S_IFREG | 0600,
 				 1, NULL, &fuse_conn_max_background_ops) ||
 	    !fuse_ctl_add_dentry(parent, fc, "congestion_threshold",
 				 S_IFREG | 0600, 1, NULL,
-				 &fuse_conn_congestion_threshold_ops))
+				 &fuse_conn_congestion_threshold_ops) ||
+	    !fuse_ctl_add_dentry(parent, fc, "backing_files", S_IFREG | 0400, 1,
+				 NULL, &fuse_conn_backing_files_ops))
 		goto err;
 
 	return 0;
 
- err:
+err:
 	fuse_ctl_remove_conn(fc);
 	return -ENOMEM;
 }
@@ -335,7 +466,7 @@ static int fuse_ctl_get_tree(struct fs_context *fsc)
 }
 
 static const struct fs_context_operations fuse_ctl_context_ops = {
-	.get_tree	= fuse_ctl_get_tree,
+	.get_tree = fuse_ctl_get_tree,
 };
 
 static int fuse_ctl_init_fs_context(struct fs_context *fsc)
@@ -358,10 +489,10 @@ static void fuse_ctl_kill_sb(struct super_block *sb)
 }
 
 static struct file_system_type fuse_ctl_fs_type = {
-	.owner		= THIS_MODULE,
-	.name		= "fusectl",
+	.owner = THIS_MODULE,
+	.name = "fusectl",
 	.init_fs_context = fuse_ctl_init_fs_context,
-	.kill_sb	= fuse_ctl_kill_sb,
+	.kill_sb = fuse_ctl_kill_sb,
 };
 MODULE_ALIAS_FS("fusectl");
 
diff --git a/fs/fuse/fuse_i.h b/fs/fuse/fuse_i.h
index d56d4fd956db99ecd93052a9655428664882cb72..2830b05bb0928e9b30f9905d70fc3ec1ef11c2a5 100644
--- a/fs/fuse/fuse_i.h
+++ b/fs/fuse/fuse_i.h
@@ -46,7 +46,7 @@
 #define FUSE_NAME_MAX (PATH_MAX - 1)
 
 /** Number of dentries for each connection in the control filesystem */
-#define FUSE_CTL_NUM_DENTRIES 5
+#define FUSE_CTL_NUM_DENTRIES 6
 
 /* Frequency (in seconds) of request timeout checks, if opted into */
 #define FUSE_TIMEOUT_TIMER_FREQ 15

-- 
2.43.0

