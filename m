From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 26 Nov 2026 12:47:44 +0100
Subject: [PATCH RFC 4/9] sysctl: Add sysctl template registration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-lklm-sysctl-ctx-flatarray-v1-4-d7fc9cc9b03e@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=14316;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=eW097mEkqhuZunAIEgyFJZ7ZyrcCo+Hgb0Cm8AguRSU=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGsIHGPo9anX2QhjuzL/XKOOLG0t59OcZM37n
 m29g8zUZpaJHokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJrCBxjAAoJELqXzVK3
 lkFP4CQL/1hoOazkl4mVp2aNHL31buKhNSXe0uhboIjH+okIdlgQupdsQvENn4hCQhpoMEUxqCQ
 ciSva+/GNjntB6du2m+MwUSjYR3awNe+2ghfMAkklDTscx6e4xUcrDVg1Xr2mHzv/R4GuNkwKoV
 cG9zYKn5vfsCTcn6vDZ0UCU8RCOAOgM+C/jEkAtiQ8/UXCmBqXo2QBB3acNkWGpfAH4piyIqJqj
 zbdv8vGb52XWrX24pbXoJqiZgEKXJ7at/oJrBqkMNxqOmpYJwlPu6/rhC10vHT9gWf/7MAhocGA
 1UQxDX6+fXKTbcZOeP5jSQ15ZitHKnp1qM2q4zVYIxOZ1HfS+3ogVT9L+tjI3VQuo9qcNxmVjyQ
 HVkRFTEYSe3ZZyBsIsnoYpiOMpqyb12tzY4PFtWIHtZnHxbedSfke1G0BrAXz1xLaFyCKeeHQsU
 7LF6yAXCki/ESYwdfUWTD4QPU62jzMk/yZwn1170pL1owrRCLA2gDIDK5bnb6++XhLvqCu2sM86
 lU=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add register_sysctl_tmpl{,_sz}() for sysctl template registrations. A
caller marks the entries that vary with the SYSCTL_OVERLAY_* flags in
the already existing const struct ctl_table. The "new" entry values are
filled and passed along in a copy of the array.

	overlay = kmemdup_array(tbl, ARRAY_SIZE(tbl), sizeof(*tbl), GFP_KERNEL);
	overlay[idx].data = VALUE;
	hdr = register_sysctl_tmpl("kernel", tbl, overlay);
	kfree(overlay);

sysctl_ctx_fill adds the overlay (flagged) entries into the header
context. Check that every flagged overlay carries a value; return an
error if this is not the case.

The new internal function register_header() contains the common logic
between the two ways of doing the sysctl registration (original and
templated)

This is a prep commit, no caller uses this yet. No functional change
intended.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 fs/proc/proc_sysctl.c  | 264 ++++++++++++++++++++++++++++++++++++++++++-------
 include/linux/sysctl.h |  30 ++++++
 2 files changed, 256 insertions(+), 38 deletions(-)

diff --git a/fs/proc/proc_sysctl.c b/fs/proc/proc_sysctl.c
index 5b5db9fcc3c63444e79b76d94891af70ec8ecc0a..aabcb9ef8e8e7832734360cec80796c2ee7547d4 100644
--- a/fs/proc/proc_sysctl.c
+++ b/fs/proc/proc_sysctl.c
@@ -1176,6 +1176,53 @@ static int sysctl_err(const char *path, const struct ctl_table *table, char *fmt
 	return -EINVAL;
 }
 
+/* Move the flagged members into the header sysctl context. */
+static int sysctl_ctx_fill(const char *path, struct ctl_table_header *head,
+			   const struct ctl_table *overlay)
+{
+	struct sysctl_context *ctx = &head->ctx;
+	const struct ctl_table *tmpl;
+
+	list_for_each_table_entry(tmpl, head) {
+		size_t idx = tmpl - head->ctl_table;
+		const struct ctl_table *ovl = &overlay[idx];
+		u8 flags = tmpl->flags;
+
+		/* An unflagged member must match the template. */
+		if (ovl->procname != tmpl->procname ||
+		    ovl->maxlen != tmpl->maxlen ||
+		    ovl->proc_handler != tmpl->proc_handler ||
+		    ovl->poll != tmpl->poll ||
+		    ovl->flags != flags ||
+		    (!(flags & SYSCTL_OVERLAY_DATA) && ovl->data != tmpl->data) ||
+		    (!(flags & SYSCTL_OVERLAY_EXTRA1) && ovl->extra1 != tmpl->extra1) ||
+		    (!(flags & SYSCTL_OVERLAY_EXTRA2) && ovl->extra2 != tmpl->extra2) ||
+		    (!(flags & SYSCTL_OVERLAY_MODE) && ovl->mode != tmpl->mode))
+			goto err;
+
+		/* A flagged one must be set: an empty slot means "not overlaid". */
+		if (((flags & SYSCTL_OVERLAY_DATA) && !ovl->data) ||
+		    ((flags & SYSCTL_OVERLAY_EXTRA1) && !ovl->extra1) ||
+		    ((flags & SYSCTL_OVERLAY_EXTRA2) && !ovl->extra2) ||
+		    ((flags & SYSCTL_OVERLAY_MODE) && !ovl->mode))
+			goto err;
+
+		if (flags & SYSCTL_OVERLAY_DATA)
+			ctx->data[idx] = ovl->data;
+		if (flags & SYSCTL_OVERLAY_EXTRA1)
+			ctx->extra1[idx] = ovl->extra1;
+		if (flags & SYSCTL_OVERLAY_EXTRA2)
+			ctx->extra2[idx] = ovl->extra2;
+		if (flags & SYSCTL_OVERLAY_MODE)
+			ctx->mode[idx] = ovl->mode;
+	}
+
+	return 0;
+
+err:
+	return sysctl_err(path, tmpl, "error while filling the sysctl context");
+}
+
 static int sysctl_check_table_array(const char *path, const struct ctl_table *table)
 {
 	unsigned int extra;
@@ -1213,6 +1260,30 @@ static int sysctl_check_table_array(const char *path, const struct ctl_table *ta
 	return err;
 }
 
+/* A flagged member must be different between the underlying entry and the overlay */
+static int sysctl_check_overlay(const char *path,
+				struct ctl_table_header *head,
+				const struct ctl_table *entry)
+{
+	const struct sysctl_context *ctx = &head->ctx;
+	size_t idx = entry - head->ctl_table;
+	u8 flags = entry->flags;
+	int err = 0;
+
+	if (flags & ~SYSCTL_OVERLAY_MASK)
+		err |= sysctl_err(path, entry, "bogus .flags 0x%x", flags);
+	if ((flags & SYSCTL_OVERLAY_DATA) && (!ctx->data || !ctx->data[idx]))
+		err |= sysctl_err(path, entry, "no data to overlay");
+	if ((flags & SYSCTL_OVERLAY_EXTRA1) && (!ctx->extra1 || !ctx->extra1[idx]))
+		err |= sysctl_err(path, entry, "no extra1 to overlay");
+	if ((flags & SYSCTL_OVERLAY_EXTRA2) && (!ctx->extra2 || !ctx->extra2[idx]))
+		err |= sysctl_err(path, entry, "no extra2 to overlay");
+	if ((flags & SYSCTL_OVERLAY_MODE) && (!ctx->mode || !ctx->mode[idx]))
+		err |= sysctl_err(path, entry, "no mode to overlay");
+
+	return err;
+}
+
 static int sysctl_check_table(const char *path, struct ctl_table_header *header)
 {
 	const struct ctl_table *entry;
@@ -1247,6 +1318,9 @@ static int sysctl_check_table(const char *path, struct ctl_table_header *header)
 		    (entry->mode & (S_IRUGO|S_IWUGO)) != entry->mode)
 			err |= sysctl_err(path, entry, "bogus .mode 0%o",
 				entry->mode);
+
+		if (entry->flags)
+			err |= sysctl_check_overlay(path, header, entry);
 	}
 	return err;
 }
@@ -1398,6 +1472,110 @@ static struct ctl_dir *sysctl_mkdir_p(struct ctl_dir *dir, const char *path)
 	return dir;
 }
 
+/* OR of every entry's flags, so the context gets an array per kind in use. */
+static u8 sysctl_table_flags(const struct ctl_table *table, size_t table_size)
+{
+	u8 flags = 0;
+	size_t i;
+
+	for (i = 0; i < table_size; i++)
+		flags |= table[i].flags;
+
+	return flags & SYSCTL_OVERLAY_MASK;
+}
+
+static size_t sysctl_header_size(const struct ctl_table *table, size_t table_size)
+{
+	u8 flags = sysctl_table_flags(table, table_size);
+	size_t size = sizeof(struct ctl_table_header) +
+		      sizeof(struct ctl_node) * table_size;
+
+	if (flags & SYSCTL_OVERLAY_DATA)
+		size += table_size * sizeof(void *);
+	if (flags & SYSCTL_OVERLAY_EXTRA1)
+		size += table_size * sizeof(void *);
+	if (flags & SYSCTL_OVERLAY_EXTRA2)
+		size += table_size * sizeof(void *);
+	if (flags & SYSCTL_OVERLAY_MODE)
+		size += table_size * sizeof(umode_t);
+
+	return size;
+}
+
+/* Init only the pointers that will be used */
+static void sysctl_ctx_init(struct ctl_table_header *head)
+{
+	size_t table_size = head->ctl_table_size;
+	u8 flags = sysctl_table_flags(head->ctl_table, table_size);
+	void **slots = (void **)(head->node + table_size);
+
+	if (flags & SYSCTL_OVERLAY_DATA) {
+		head->ctx.data = slots;
+		slots += table_size;
+	}
+	if (flags & SYSCTL_OVERLAY_EXTRA1) {
+		head->ctx.extra1 = slots;
+		slots += table_size;
+	}
+	if (flags & SYSCTL_OVERLAY_EXTRA2) {
+		head->ctx.extra2 = slots;
+		slots += table_size;
+	}
+	if (flags & SYSCTL_OVERLAY_MODE)
+		head->ctx.mode = (umode_t *)slots;
+}
+
+static struct ctl_table_header *register_header(struct ctl_table_set *set,
+	const char *path, const struct ctl_table *table,
+	const struct ctl_table *overlay, size_t table_size)
+{
+	struct ctl_table_root *root = set->dir.header.root;
+	struct ctl_table_header *header;
+	struct ctl_dir *dir;
+	struct ctl_node *node;
+	size_t size;
+
+	size = sysctl_header_size(table, table_size);
+	header = kzalloc(size, GFP_KERNEL_ACCOUNT);
+	if (!header)
+		return NULL;
+
+	node = (struct ctl_node *)(header + 1);
+	init_header(header, root, set, node, table, table_size);
+	if (overlay) {
+		sysctl_ctx_init(header);
+		if (sysctl_ctx_fill(path, header, overlay))
+			goto fail;
+	}
+	if (sysctl_check_table(path, header))
+		goto fail;
+
+	spin_lock(&sysctl_lock);
+	dir = &set->dir;
+	/* Reference moved down the directory tree get_subdir */
+	dir->header.nreg++;
+	spin_unlock(&sysctl_lock);
+
+	dir = sysctl_mkdir_p(dir, path);
+	if (IS_ERR(dir))
+		goto fail;
+	spin_lock(&sysctl_lock);
+	if (insert_header(dir, header))
+		goto fail_put_dir_locked;
+
+	drop_sysctl_table(&dir->header);
+	spin_unlock(&sysctl_lock);
+
+	return header;
+
+fail_put_dir_locked:
+	drop_sysctl_table(&dir->header);
+	spin_unlock(&sysctl_lock);
+fail:
+	kfree(header);
+	return NULL;
+}
+
 /**
  * __register_sysctl_table - register a leaf sysctl table
  * @set: Sysctl tree to register on
@@ -1446,45 +1624,31 @@ struct ctl_table_header *__register_sysctl_table(
 	struct ctl_table_set *set,
 	const char *path, const struct ctl_table *table, size_t table_size)
 {
-	struct ctl_table_root *root = set->dir.header.root;
-	struct ctl_table_header *header;
-	struct ctl_dir *dir;
-	struct ctl_node *node;
+	return register_header(set, path, table, NULL, table_size);
+}
 
-	header = kzalloc(sizeof(struct ctl_table_header) +
-			 sizeof(struct ctl_node)*table_size, GFP_KERNEL_ACCOUNT);
-	if (!header)
-		return NULL;
-
-	node = (struct ctl_node *)(header + 1);
-	init_header(header, root, set, node, table, table_size);
-	if (sysctl_check_table(path, header))
-		goto fail;
-
-	spin_lock(&sysctl_lock);
-	dir = &set->dir;
-	/* Reference moved down the directory tree get_subdir */
-	dir->header.nreg++;
-	spin_unlock(&sysctl_lock);
-
-	dir = sysctl_mkdir_p(dir, path);
-	if (IS_ERR(dir))
-		goto fail;
-	spin_lock(&sysctl_lock);
-	if (insert_header(dir, header))
-		goto fail_put_dir_locked;
-
-	drop_sysctl_table(&dir->header);
-	spin_unlock(&sysctl_lock);
-
-	return header;
-
-fail_put_dir_locked:
-	drop_sysctl_table(&dir->header);
-	spin_unlock(&sysctl_lock);
-fail:
-	kfree(header);
-	return NULL;
+/**
+ * __register_sysctl_table_tmpl - register a table from a template/overlay
+ * @set: Sysctl tree to register on
+ * @path: The path to the directory the sysctl table is in.
+ * @tmpl: the template, passed through CTL_TABLE_TMPL. Must be available
+ *	until unregistered. Should be const global.
+ * @overlay: caller's copy of @tmpl in which every flagged member has its
+ *	own value. The callers should free it after the registration call
+ * @table_size: The number of elements in @tmpl and @overlay.
+ *
+ * The flagged members of @overlay are stored in the header's context and
+ * overlaid on the template entry each time it is accessed.
+ *
+ * This routine returns %NULL on a failure to register, and a pointer
+ * to the table header on success.
+ */
+struct ctl_table_header *__register_sysctl_table_tmpl(
+	struct ctl_table_set *set, const char *path,
+	const struct ctl_table_tmpl *tmpl, const struct ctl_table *overlay,
+	size_t table_size)
+{
+	return register_header(set, path, &tmpl->t, overlay, table_size);
 }
 
 /**
@@ -1513,6 +1677,30 @@ struct ctl_table_header *register_sysctl_sz(const char *path, const struct ctl_t
 }
 EXPORT_SYMBOL(register_sysctl_sz);
 
+/**
+ * register_sysctl_tmpl_sz - register a sysctl table from a template
+ * @path: The path to the directory the sysctl table is in. If the path
+ *	doesn't exist we will create it for you.
+ * @tmpl: the template, see __register_sysctl_table_tmpl()
+ * @overlay: the filled-in copy of @tmpl, see __register_sysctl_table_tmpl()
+ * @table_size: The number of elements in @tmpl and @overlay.
+ *
+ * Register a sysctl table whose entries flagged SYSCTL_OVERLAY_* take their
+ * values from @overlay while @tmpl stays shared and unmodified. The
+ * register_sysctl_tmpl() macro supplies the cast and the size for an array.
+ *
+ * See __register_sysctl_table_tmpl() for more details.
+ */
+struct ctl_table_header *register_sysctl_tmpl_sz(const char *path,
+						 const struct ctl_table_tmpl *tmpl,
+						 const struct ctl_table *overlay,
+						 size_t table_size)
+{
+	return __register_sysctl_table_tmpl(&sysctl_table_root.default_set,
+					    path, tmpl, overlay, table_size);
+}
+EXPORT_SYMBOL(register_sysctl_tmpl_sz);
+
 /**
  * __register_sysctl_init() - register sysctl table to path
  * @path: path name for sysctl base. If that path doesn't exist we will create
diff --git a/include/linux/sysctl.h b/include/linux/sysctl.h
index 11ee0cdeef0ffe8daa4cc8756a820bf2b002c9ad..1eefcbb9f02a612118bf3810f137e713dc9389cd 100644
--- a/include/linux/sysctl.h
+++ b/include/linux/sysctl.h
@@ -22,6 +22,7 @@
 #ifndef _LINUX_SYSCTL_H
 #define _LINUX_SYSCTL_H
 
+#include <linux/array_size.h>
 #include <linux/bits.h>
 #include <linux/build_bug.h>
 #include <linux/list.h>
@@ -250,6 +251,16 @@ static_assert(sizeof(struct ctl_table_tmpl) == sizeof(struct ctl_table));
 static_assert(__alignof__(struct ctl_table_tmpl) == __alignof__(struct ctl_table));
 static_assert(offsetof(struct ctl_table_tmpl, t) == 0);
 
+/**
+ * CTL_TABLE_TMPL - cast a struct ctl_table * as a ctl template
+ * @arr: array of struct ctl_table
+ *
+ * This macro is the only way to get a ctl_table_tmpl to register as a template
+ */
+#define CTL_TABLE_TMPL(arr)						\
+	((const struct ctl_table_tmpl *)(arr) + __must_be_array(arr) +	\
+	 BUILD_BUG_ON_ZERO(!__same_type((arr)[0], struct ctl_table)))
+
 struct ctl_node {
 	struct rb_node node;
 	struct ctl_table_header *header;
@@ -331,6 +342,9 @@ struct ctl_table_root {
 
 #define register_sysctl(path, table)	\
 	register_sysctl_sz(path, table, ARRAY_SIZE(table))
+#define register_sysctl_tmpl(path, tmpl, overlay)			\
+	register_sysctl_tmpl_sz(path, CTL_TABLE_TMPL(tmpl), overlay,		\
+				ARRAY_SIZE(tmpl))
 
 #ifdef CONFIG_SYSCTL
 
@@ -346,6 +360,14 @@ struct ctl_table_header *__register_sysctl_table(
 	const char *path, const struct ctl_table *table, size_t table_size);
 struct ctl_table_header *register_sysctl_sz(const char *path, const struct ctl_table *table,
 					    size_t table_size);
+struct ctl_table_header *__register_sysctl_table_tmpl(
+	struct ctl_table_set *set, const char *path,
+	const struct ctl_table_tmpl *tmpl, const struct ctl_table *overlay,
+	size_t table_size);
+struct ctl_table_header *register_sysctl_tmpl_sz(const char *path,
+						 const struct ctl_table_tmpl *tmpl,
+						 const struct ctl_table *overlay,
+						 size_t table_size);
 void unregister_sysctl_table(struct ctl_table_header * table);
 
 extern int sysctl_init_bases(void);
@@ -379,6 +401,14 @@ static inline struct ctl_table_header *register_sysctl_sz(const char *path,
 	return NULL;
 }
 
+static inline struct ctl_table_header *register_sysctl_tmpl_sz(const char *path,
+							       const struct ctl_table_tmpl *tmpl,
+							       const struct ctl_table *overlay,
+							       size_t table_size)
+{
+	return NULL;
+}
+
 static inline void unregister_sysctl_table(struct ctl_table_header * table)
 {
 }

-- 
2.50.1

