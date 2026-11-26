From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 26 Nov 2026 12:47:43 +0100
Subject: [PATCH RFC 3/9] sysctl: Add overlay mechanism for flagged
 ctl_table members
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-lklm-sysctl-ctx-flatarray-v1-3-d7fc9cc9b03e@kernel.org>
References: <20261126-lklm-sysctl-ctx-flatarray-v1-0-d7fc9cc9b03e@kernel.org>
In-Reply-To: <20261126-lklm-sysctl-ctx-flatarray-v1-0-d7fc9cc9b03e@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexey Gladkov <legion@kernel.org>, 
 David Laight <david.laight.linux@gmail.com>, Wen Yang <wen.yang@linux.dev>
Cc: Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Linus Torvalds <torvalds@linux-foundation.org>, 
 linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 netdev@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=10324;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=/2jXP0DSebY4r4D2CXXAcZ0qCaU6qHmNmZdMqC68rx4=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGsIHGPLhxDr/YZ0VsYRHDpgspou65fc/eNVD
 C7/uJsKOJOzWIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJrCBxjAAoJELqXzVK3
 lkFPaZgL/28DA6s82BQd8duw/P3fYoYrtH+81jk0xnz86GsSnZAyjHrDjsAO8FU8RRgNVfuT/3u
 SosT46cBVaixjQ0Kj2/PniBGwEfIZ23ceueQd+3L0JNLDwif6+iYs35g3pFVpDp3DEfGqQ6a8Fw
 ZhYXCBY/18maTa7AyPxCdPXuvuy7ptiaw6Yie9ukVBCEuBxhgCaX9j61HCMm9zqPljGEQqwQ7IT
 rc3DxbQ9mdb1K0rBFABYvKS1+SIKDBx0skzfU1S+FIE6mDrtq2BWCfBIf9NhGl3RHGujA8j0UGr
 ghR3hVkqsLORerWjVkcmDmgUO+SghCleChySM1FBeDpSvusB6RObe8uRKSwHDJ6TBQpwarLCwFq
 SZq2rkRo0hZbXoCnI8mCt7g78Lu0TWXztodWQkXZdFhM9PJAL/Js1iuJ+dG1VP3ONM3PVXLEpQu
 TGeNdabADgG0n2m6xy3VJNSoiH3LH7QJJWywKynMc0WhX3CxLQt/srkhoeNOCIquvEDvf9LWRg5
 nY=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the ctl_table overlay mechanism and use it whenever the overlay
flags signal the existence of an alternate value. The new
sysctl_context structure holds four arrays of overlay values each
indexed by an entry's position in its ctl_table array.

sysctl_overlay() builds the entry the core acts on. An un-flagged entry
passes through untouched. For a flagged entry it copies the entry to a
stack buffer and overlays each flagged member with data from
sysctl_context. sysctl_overlay() runs in proc_sys_call_handler(),
proc_sys_permission() and proc_sys_make_inode().

The arrays are written once at registration, before the header becomes
visible, and read under the header's use count, so they need no locking.
An error is returned when a flagged value is not found in the
sysctl_context.

This is a prep commit, there is no context registration yet, so there is
no change in functionality.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 fs/proc/proc_sysctl.c  | 97 ++++++++++++++++++++++++++++++++++++++++++++------
 include/linux/sysctl.h | 18 ++++++++++
 2 files changed, 104 insertions(+), 11 deletions(-)

diff --git a/fs/proc/proc_sysctl.c b/fs/proc/proc_sysctl.c
index 1c5ccb29707d83bacad06198c0dcab39c8b7b347..5b5db9fcc3c63444e79b76d94891af70ec8ecc0a 100644
--- a/fs/proc/proc_sysctl.c
+++ b/fs/proc/proc_sysctl.c
@@ -205,6 +205,7 @@ static void init_header(struct ctl_table_header *head,
 	head->parent = NULL;
 	head->node = node;
 	INIT_HLIST_HEAD(&head->inodes);
+	memset(&head->ctx, 0, sizeof(head->ctx));
 	if (node) {
 		const struct ctl_table *entry __maybe_unused;
 
@@ -446,13 +447,64 @@ static int sysctl_perm(struct ctl_table_header *head, const struct ctl_table *ta
 	return test_perm(mode, op);
 }
 
+/*
+ * Replace .data, .extra{1,2} or .mode when flagged. An unflagged entry is
+ * returned as it is.
+ */
+static const struct ctl_table *sysctl_overlay(struct ctl_table_header *head,
+					      const struct ctl_table *entry,
+					      struct ctl_table *buf)
+{
+	const struct sysctl_context *ctx = &head->ctx;
+	size_t idx;
+
+	if (!(entry->flags & SYSCTL_OVERLAY_MASK))
+		return entry;
+
+	/* The entry and the header arrive as a pair; anything else is a bug. */
+	idx = entry - head->ctl_table;
+	if (WARN_ON_ONCE(idx >= (size_t)head->ctl_table_size))
+		return ERR_PTR(-EINVAL);
+	*buf = *entry;
+
+	if (entry->flags & SYSCTL_OVERLAY_DATA) {
+		if (!ctx->data || !ctx->data[idx])
+			return ERR_PTR(-EINVAL);
+		buf->data = ctx->data[idx];
+	}
+	if (entry->flags & SYSCTL_OVERLAY_EXTRA1) {
+		if (!ctx->extra1 || !ctx->extra1[idx])
+			return ERR_PTR(-EINVAL);
+		buf->extra1 = ctx->extra1[idx];
+	}
+	if (entry->flags & SYSCTL_OVERLAY_EXTRA2) {
+		if (!ctx->extra2 || !ctx->extra2[idx])
+			return ERR_PTR(-EINVAL);
+		buf->extra2 = ctx->extra2[idx];
+	}
+	if (entry->flags & SYSCTL_OVERLAY_MODE) {
+		if (!ctx->mode || !ctx->mode[idx])
+			return ERR_PTR(-EINVAL);
+		buf->mode = ctx->mode[idx];
+	}
+
+	return buf;
+}
+
 static struct inode *proc_sys_make_inode(struct super_block *sb,
 		struct ctl_table_header *head, const struct ctl_table *table)
 {
 	struct ctl_table_root *root = head->root;
+	const struct ctl_table *view;
+	struct ctl_table overlaid;
 	struct inode *inode;
 	struct proc_inode *ei;
 
+	/* The mode comes from the overlaid entry; sysctl_entry keeps @table. */
+	view = sysctl_overlay(head, table, &overlaid);
+	if (IS_ERR(view))
+		return ERR_CAST(view);
+
 	inode = new_inode(sb);
 	if (!inode)
 		return ERR_PTR(-ENOMEM);
@@ -474,8 +526,8 @@ static struct inode *proc_sys_make_inode(struct super_block *sb,
 	spin_unlock(&sysctl_lock);
 
 	simple_inode_init_ts(inode);
-	inode->i_mode = table->mode;
-	if (!S_ISDIR(table->mode)) {
+	inode->i_mode = view->mode;
+	if (!S_ISDIR(view->mode)) {
 		inode->i_mode |= S_IFREG;
 		inode->i_op = &proc_sys_inode_operations;
 		inode->i_fop = &proc_sys_file_operations;
@@ -556,6 +608,7 @@ static ssize_t proc_sys_call_handler(struct kiocb *iocb, struct iov_iter *iter,
 	struct inode *inode = file_inode(iocb->ki_filp);
 	struct ctl_table_header *head = grab_header(inode);
 	const struct ctl_table *table = PROC_I(inode)->sysctl_entry;
+	struct ctl_table overlaid;
 	size_t count = iov_iter_count(iter);
 	char *kbuf;
 	ssize_t error;
@@ -567,6 +620,12 @@ static ssize_t proc_sys_call_handler(struct kiocb *iocb, struct iov_iter *iter,
 	 * At this point we know that the sysctl was not unregistered
 	 * and won't be until we finish.
 	 */
+	table = sysctl_overlay(head, table, &overlaid);
+	if (IS_ERR(table)) {
+		error = PTR_ERR(table);
+		goto out;
+	}
+
 	error = -EPERM;
 	if (sysctl_perm(head, table, write ? MAY_WRITE : MAY_READ))
 		goto out;
@@ -797,6 +856,7 @@ static int proc_sys_permission(const struct mnt_idmap *idmap,
 	 */
 	struct ctl_table_header *head;
 	const struct ctl_table *table;
+	struct ctl_table overlaid;
 	int error;
 
 	/* Executable files are not allowed under /proc/sys/ */
@@ -810,8 +870,14 @@ static int proc_sys_permission(const struct mnt_idmap *idmap,
 	table = PROC_I(inode)->sysctl_entry;
 	if (!table) /* global root - r-xr-xr-x */
 		error = mask & MAY_WRITE ? -EACCES : 0;
-	else /* Use the permissions on the sysctl table entry */
-		error = sysctl_perm(head, table, mask & ~MAY_NOT_BLOCK);
+	else {
+		/* ->permissions may inspect the entry, so overlay it first. */
+		table = sysctl_overlay(head, table, &overlaid);
+		if (IS_ERR(table))
+			error = PTR_ERR(table);
+		else
+			error = sysctl_perm(head, table, mask & ~MAY_NOT_BLOCK);
+	}
 
 	sysctl_head_finish(head);
 	return error;
@@ -841,16 +907,23 @@ static int proc_sys_getattr(const struct mnt_idmap *idmap,
 	struct inode *inode = d_inode(path->dentry);
 	struct ctl_table_header *head = grab_header(inode);
 	const struct ctl_table *table = PROC_I(inode)->sysctl_entry;
+	struct ctl_table overlaid;
+	int error = 0;
 
 	if (IS_ERR(head))
 		return PTR_ERR(head);
 
 	generic_fillattr(&nop_mnt_idmap, request_mask, inode, stat);
-	if (table)
-		stat->mode = (stat->mode & S_IFMT) | table->mode;
+	if (table) {
+		table = sysctl_overlay(head, table, &overlaid);
+		if (IS_ERR(table))
+			error = PTR_ERR(table);
+		else
+			stat->mode = (stat->mode & S_IFMT) | table->mode;
+	}
 
 	sysctl_head_finish(head);
-	return 0;
+	return error;
 }
 
 static const struct file_operations proc_sys_file_operations = {
@@ -1118,13 +1191,13 @@ static int sysctl_check_table_array(const char *path, const struct ctl_table *ta
 		if (table->maxlen != sizeof(u8))
 			err |= sysctl_err(path, table, "array not allowed");
 
-		if (table->extra1) {
+		if (table->extra1 && !(table->flags & SYSCTL_OVERLAY_EXTRA1)) {
 			extra = *(unsigned int *) table->extra1;
 			if (extra > 255U)
 				err |= sysctl_err(path, table,
 						"range value too large for proc_dou8vec_minmax");
 		}
-		if (table->extra2) {
+		if (table->extra2 && !(table->flags & SYSCTL_OVERLAY_EXTRA2)) {
 			extra = *(unsigned int *) table->extra2;
 			if (extra > 255U)
 				err |= sysctl_err(path, table,
@@ -1159,7 +1232,8 @@ static int sysctl_check_table(const char *path, struct ctl_table_header *header)
 		    (entry->proc_handler == proc_dointvec_ms_jiffies) ||
 		    (entry->proc_handler == proc_doulongvec_minmax) ||
 		    (entry->proc_handler == proc_doulongvec_ms_jiffies_minmax)) {
-			if (!entry->data)
+			/* Can be NULL when overlaid */
+			if (!entry->data && !(entry->flags & SYSCTL_OVERLAY_DATA))
 				err |= sysctl_err(path, entry, "No data");
 			if (!entry->maxlen)
 				err |= sysctl_err(path, entry, "No maxlen");
@@ -1169,7 +1243,8 @@ static int sysctl_check_table(const char *path, struct ctl_table_header *header)
 		if (!entry->proc_handler)
 			err |= sysctl_err(path, entry, "No proc_handler");
 
-		if ((entry->mode & (S_IRUGO|S_IWUGO)) != entry->mode)
+		if (!(entry->flags & SYSCTL_OVERLAY_MODE) &&
+		    (entry->mode & (S_IRUGO|S_IWUGO)) != entry->mode)
 			err |= sysctl_err(path, entry, "bogus .mode 0%o",
 				entry->mode);
 	}
diff --git a/include/linux/sysctl.h b/include/linux/sysctl.h
index 3654fd31e3cc4f9217ae61b0bb4d6f4c677ea237..11ee0cdeef0ffe8daa4cc8756a820bf2b002c9ad 100644
--- a/include/linux/sysctl.h
+++ b/include/linux/sysctl.h
@@ -225,6 +225,8 @@ static inline void *proc_sys_poll_event(struct ctl_table_poll *poll)
 #define SYSCTL_OVERLAY_EXTRA1	BIT(1)
 #define SYSCTL_OVERLAY_EXTRA2	BIT(2)
 #define SYSCTL_OVERLAY_MODE	BIT(3)
+#define SYSCTL_OVERLAY_MASK	(SYSCTL_OVERLAY_DATA | SYSCTL_OVERLAY_EXTRA1 | \
+				 SYSCTL_OVERLAY_EXTRA2 | SYSCTL_OVERLAY_MODE)
 
 /* A sysctl table is an array of struct ctl_table: */
 struct ctl_table {
@@ -253,6 +255,20 @@ struct ctl_node {
 	struct ctl_table_header *header;
 };
 
+/**
+ * struct sysctl_context - per-registration values for template entries
+ * @data: replaces ctl_table.data of entries flagged SYSCTL_OVERLAY_DATA
+ * @extra1: replaces ctl_table.extra1 of entries flagged SYSCTL_OVERLAY_EXTRA1
+ * @extra2: replaces ctl_table.extra2 of entries flagged SYSCTL_OVERLAY_EXTRA2
+ * @mode: replaces ctl_table.mode of entries flagged SYSCTL_OVERLAY_MODE
+ */
+struct sysctl_context {
+	void **data;
+	void **extra1;
+	void **extra2;
+	umode_t *mode;
+};
+
 /**
  * struct ctl_table_header - maintains dynamic lists of struct ctl_table trees
  * @ctl_table: pointer to the first element in ctl_table array
@@ -262,6 +278,7 @@ struct ctl_node {
  *         something is removed from inodes
  * @nreg: When nreg drops to 0 the ctl_table_header will be unregistered.
  * @rcu: Delays the freeing of the inode. Introduced with "unfuck proc_sysctl ->d_compare()"
+ * @ctx: per-registration values for flagged entries, see struct sysctl_context
  *
  * @type: Enumeration to differentiate between ctl target types:
  * type.SYSCTL_TABLE_TYPE_DEFAULT: ctl target with no special considerations
@@ -286,6 +303,7 @@ struct ctl_table_header {
 	struct ctl_dir *parent;
 	struct ctl_node *node;
 	struct hlist_head inodes; /* head for proc_inode->sysctl_inodes */
+	struct sysctl_context ctx;
 	enum {
 		SYSCTL_TABLE_TYPE_DEFAULT,
 		SYSCTL_TABLE_TYPE_PERMANENTLY_EMPTY,

-- 
2.50.1

