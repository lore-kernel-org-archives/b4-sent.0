From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 24 Sep 2026 16:34:09 +0200
Subject: [PATCH RFC 1/4] sysctl: add a registration context to
 ctl_table_header
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-lklm-sysctl-headerctx-template-v1-1-b25e51c66ba7@kernel.org>
References: <20260924-lklm-sysctl-headerctx-template-v1-0-b25e51c66ba7@kernel.org>
In-Reply-To: <20260924-lklm-sysctl-headerctx-template-v1-0-b25e51c66ba7@kernel.org>
To: Kees Cook <kees@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 =?utf-8?q?Ondrej_Mosn=C3=A1=C4=8Dek?= <omosnacek@gmail.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Ryan Roberts <ryan.roberts@arm.com>, Serge Hallyn <serge@hallyn.com>, 
 "Eric W . Biederman" <ebiederm@xmission.com>, 
 Alexey Gladkov <legion@kernel.org>, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=8723;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=mnIQb1Yug/ZKrL0ezOFkoOsvh5aZpqvlnrOmEwE7vMc=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGq1NORtLkytfrO8kdQmGphH+AeiVJ9pb10K0
 ZQZxK0Hura+fokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqtTTkAAoJELqXzVK3
 lkFP0TYL/jDhyu7JScUlj8eRfIz1Fb7pZXIKigFdfWXdIsC/g+G99++mhoy4kWLiyGF5h9aBjdz
 gnK3fWpq1u5M9cvk3SoZ2l0ooIEpel8IOwSDh+6V/06OmGgCRG23+9dFjGGziBg+ehofIe8urRB
 OqrMAZjl4RJQWtsrfSSadnXZxGhdA0q1mxkMKh5+LjgtDSo1lK8Y61XqtRAoY0xnCuKI5jdaOHu
 bI5LCEFHbn5MDtF9gM/oiu5JD2/VN+HloYk95ZpvDSGY1SkxpRKOakUHibfYQwSN3PoZtmNStZd
 moWdCLuojvtxEHRd0L/mPi8wal9jmTeOFPKnSr+B7vjLDg55GdRzITnw8TE7Q0yIxT6GRy/L6Zv
 qRrdTgMGfR4SsxD4dyM2n9DJs87JsMfN8GCJR9+O9VkkZ6qtVxg8e9oXGO26yCquLrMwIANL8Sk
 SROpD0gw5Js0EkvVkyfuTP6j+Dnuto2nm5IeltUI3ncE8tGecqv8B1IEQT3w9uE1LdiLqb3OAo7
 yY=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The sysctl context holds a pointer where the actual data (per-namespace
or per-device) is located. When an entry is marked CTL_TABLE_F_CTX_DATA
it is replaced just before calling proc_handler. Add flags to
each ctl_table entry to pass along CTL_TABLE_F_CTX_DATA.

SYSCTL_CTX() builds the context and fails the build unless the instance
and the template point at the same type.

This is a prep commit, no functional changes intended.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 fs/proc/proc_sysctl.c  | 29 ++++++++++++++++++++++----
 include/linux/sysctl.h | 55 ++++++++++++++++++++++++++++++++++++++++++++++++--
 2 files changed, 78 insertions(+), 6 deletions(-)

diff --git a/fs/proc/proc_sysctl.c b/fs/proc/proc_sysctl.c
index 04a382178c657b5af201a838fa15703d9eea9c7b..fe32337892f9badc897a29e9176e66790003fb05 100644
--- a/fs/proc/proc_sysctl.c
+++ b/fs/proc/proc_sysctl.c
@@ -1143,10 +1143,18 @@ static int sysctl_check_table_array(const char *path, const struct ctl_table *ta
 static int sysctl_check_table(const char *path, struct ctl_table_header *header)
 {
 	const struct ctl_table *entry;
+	u8 flagged = 0;
 	int err = 0;
 	list_for_each_table_entry(entry, header) {
 		if (!entry->procname)
 			err |= sysctl_err(path, entry, "procname is null");
+		if (entry->flags & CTL_TABLE_F_CTX_DATA) {
+			if (!entry->data)
+				err |= sysctl_err(path, entry, "No data to resolve");
+			if (!header->ctx.inst || !header->ctx.tmpl)
+				err |= sysctl_err(path, entry, "No context to resolve against");
+		}
+		flagged |= entry->flags & CTL_TABLE_F_CTX;
 		if ((entry->proc_handler == proc_dostring) ||
 		    (entry->proc_handler == proc_dobool) ||
 		    (entry->proc_handler == proc_dointvec) ||
@@ -1173,6 +1181,12 @@ static int sysctl_check_table(const char *path, struct ctl_table_header *header)
 			err |= sysctl_err(path, entry, "bogus .mode 0%o",
 				entry->mode);
 	}
+	/* A context nobody resolves against is a forgotten flag. */
+	if (!flagged && (header->ctx.inst || header->ctx.tmpl)) {
+		pr_err("sysctl table check failed: %s context given but no entry is flagged\n",
+		       path);
+		err = -EINVAL;
+	}
 	return err;
 }
 
@@ -1324,7 +1338,7 @@ static struct ctl_dir *sysctl_mkdir_p(struct ctl_dir *dir, const char *path)
 }
 
 /**
- * __register_sysctl_table - register a leaf sysctl table
+ * __register_sysctl_table_ctx - register a leaf sysctl table
  * @set: Sysctl tree to register on
  * @path: The path to the directory the sysctl table is in.
  *
@@ -1333,6 +1347,9 @@ static struct ctl_dir *sysctl_mkdir_p(struct ctl_dir *dir, const char *path)
  *         be a global or dynamically allocated by the caller and free'd later
  *         after sysctl unregistration.
  * @table_size : The number of elements in table
+ * @ctx: instances that entries flagged CTL_TABLE_F_CTX_* resolve against, see
+ *       struct sysctl_context.  Copied, so it may be on stack.  %NULL when no
+ *       entry is flagged.
  *
  * Register a sysctl table hierarchy. @table should be a filled in ctl_table
  * array.
@@ -1343,6 +1360,7 @@ static struct ctl_dir *sysctl_mkdir_p(struct ctl_dir *dir, const char *path)
  * data     - a pointer to data for use by proc_handler
  * maxlen   - the maximum size in bytes of the data
  * mode     - the file permissions for the /proc/sys file
+ * flags    - CTL_TABLE_F_* bits naming members to resolve against @ctx
  * type     - Defines the target type (described in struct definition)
  * proc_handler - the text handler routine (described below)
  *
@@ -1366,9 +1384,10 @@ static struct ctl_dir *sysctl_mkdir_p(struct ctl_dir *dir, const char *path)
  * This routine returns %NULL on a failure to register, and a pointer
  * to the table header on success.
  */
-struct ctl_table_header *__register_sysctl_table(
+struct ctl_table_header *__register_sysctl_table_ctx(
 	struct ctl_table_set *set,
-	const char *path, const struct ctl_table *table, size_t table_size)
+	const char *path, const struct ctl_table *table, size_t table_size,
+	const struct sysctl_context *ctx)
 {
 	struct ctl_table_root *root = set->dir.header.root;
 	struct ctl_table_header *header;
@@ -1382,6 +1401,8 @@ struct ctl_table_header *__register_sysctl_table(
 
 	node = (struct ctl_node *)(header + 1);
 	init_header(header, root, set, node, table, table_size);
+	if (ctx)
+		header->ctx = *ctx;
 	if (sysctl_check_table(path, header))
 		goto fail;
 
@@ -1427,7 +1448,7 @@ struct ctl_table_header *__register_sysctl_table(
  * Register a sysctl table. @table should be a filled in ctl_table
  * array. A completely 0 filled entry terminates the table.
  *
- * See __register_sysctl_table for more details.
+ * See __register_sysctl_table_ctx for more details.
  */
 struct ctl_table_header *register_sysctl_sz(const char *path, const struct ctl_table *table,
 					    size_t table_size)
diff --git a/include/linux/sysctl.h b/include/linux/sysctl.h
index e5d7226ab6f5af34a33829883ad5d1b405e19c86..b2c57c530bdc9b3542375b761fec3e02ab38bc7f 100644
--- a/include/linux/sysctl.h
+++ b/include/linux/sysctl.h
@@ -22,6 +22,8 @@
 #ifndef _LINUX_SYSCTL_H
 #define _LINUX_SYSCTL_H
 
+#include <linux/bits.h>
+#include <linux/build_bug.h>
 #include <linux/list.h>
 #include <linux/rcupdate.h>
 #include <linux/wait.h>
@@ -224,12 +226,50 @@ struct ctl_table {
 	void *data;
 	int maxlen;
 	umode_t mode;
+	u8 flags;			/* CTL_TABLE_F_* */
 	proc_handler *proc_handler;	/* Callback for text formatting */
 	struct ctl_table_poll *poll;
 	void *extra1;
 	void *extra2;
 } __randomize_layout;
 
+/*
+ * ctl_table::flags.  Resolve the corresponding member against the
+ * registration context instead of using it as it stands.
+ */
+#define CTL_TABLE_F_CTX_DATA	BIT(0)
+#define CTL_TABLE_F_CTX		CTL_TABLE_F_CTX_DATA
+
+/**
+ * struct sysctl_context - ctl_table specific context
+ * @inst: entry location
+ * @tmpl: struct template (used to calculate offset into @inst)
+ *
+ * @inst/@tmpl pair is used to overlay the ctl_table entry before calling
+ * proc_handler. This is relevant when struct members (like ->data) are
+ * somewhere different than the const static ctl_table array (think
+ * namespaces).  Build it with SYSCTL_CTX() so the compiler checks that
+ * both point at the same type.
+ */
+struct sysctl_context {
+	void *inst;
+	const void *tmpl;
+};
+
+/**
+ * SYSCTL_CTX - build a struct sysctl_context
+ * @_inst: the instance this registration describes
+ * @_tmpl: the instance the table's data members name
+ *
+ * Fails to build unless @_inst and @_tmpl point at the same type.
+ */
+#define SYSCTL_CTX(_inst, _tmpl)					\
+	((struct sysctl_context){					\
+		.inst = (_inst) +					\
+			BUILD_BUG_ON_ZERO(!__same_type(*(_inst), *(_tmpl))), \
+		.tmpl = (_tmpl),					\
+	})
+
 struct ctl_node {
 	struct rb_node node;
 	struct ctl_table_header *header;
@@ -244,6 +284,7 @@ struct ctl_node {
  *         something is removed from inodes
  * @nreg: When nreg drops to 0 the ctl_table_header will be unregistered.
  * @rcu: Delays the freeing of the inode. Introduced with "unfuck proc_sysctl ->d_compare()"
+ * @ctx: instances given to __register_sysctl_table_ctx(), see struct sysctl_context
  *
  * @type: Enumeration to differentiate between ctl target types:
  * type.SYSCTL_TABLE_TYPE_DEFAULT: ctl target with no special considerations
@@ -268,6 +309,7 @@ struct ctl_table_header {
 	struct ctl_dir *parent;
 	struct ctl_node *node;
 	struct hlist_head inodes; /* head for proc_inode->sysctl_inodes */
+	struct sysctl_context ctx;
 	enum {
 		SYSCTL_TABLE_TYPE_DEFAULT,
 		SYSCTL_TABLE_TYPE_PERMANENTLY_EMPTY,
@@ -305,9 +347,18 @@ extern void setup_sysctl_set(struct ctl_table_set *p,
 	int (*is_seen)(struct ctl_table_set *));
 extern void retire_sysctl_set(struct ctl_table_set *set);
 
-struct ctl_table_header *__register_sysctl_table(
+struct ctl_table_header *__register_sysctl_table_ctx(
 	struct ctl_table_set *set,
-	const char *path, const struct ctl_table *table, size_t table_size);
+	const char *path, const struct ctl_table *table, size_t table_size,
+	const struct sysctl_context *ctx);
+
+static inline struct ctl_table_header *__register_sysctl_table(
+	struct ctl_table_set *set,
+	const char *path, const struct ctl_table *table, size_t table_size)
+{
+	return __register_sysctl_table_ctx(set, path, table, table_size, NULL);
+}
+
 struct ctl_table_header *register_sysctl_sz(const char *path, const struct ctl_table *table,
 					    size_t table_size);
 void unregister_sysctl_table(struct ctl_table_header * table);

-- 
2.50.1

