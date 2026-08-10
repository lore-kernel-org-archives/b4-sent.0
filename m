From: Chris Ayoub <cayoub@openai.com>
Date: Mon, 10 Aug 2026 00:19:34 -0400
Subject: [PATCH v2] rebuild: prevent quadratic snapshot merges on wide
 directories
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-rebuild-wide-directory-index-v2-1-3a977092b7ea@openai.com>
X-B4-Tracking: v=1; b=H4sIAFVReWoC/42NTQ6CMBBGr2Jm7Rh+DIIr72FYtJ1BxmhLWkEM4
 e62eAGXL3nf+xYI7IUDnHcLeJ4kiLMRiv0OTK/sjVEoMhRZUWV11qBnPcqD8C3ESOLZvJz/oFj
 iGU1nykaXR1XVDDExeO5k3vLX9sdh1Pe4Sc1k9BLSfvuf8uT9eTXlmKMytT5pwyUTXdzAVsnBu
 Ce067p+AYHm9OfbAAAA
X-Change-ID: 20260809-rebuild-wide-directory-index-cfc39b34a68e
To: linux-erofs@lists.ozlabs.org
Cc: Gao Xiang <xiang@kernel.org>, Chris Ayoub <cayoub@openai.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786335581; l=8711;
 i=cayoub@openai.com; s=20260809; h=from:subject:message-id;
 bh=9VXj7OUFa5XFtJt3jzoTSA0n4h2icwNe252RWgLnB30=;
 b=hmxdLSxp/escyHDTwzWQRnAJFlp7okKqa9QE2HC64VWkFEkt9LV3Q7KB5eKwyP6QtNbuBWwc+
 YyoyxxK1TJODvP644Vp4scrfWt6qqMaQ74ojo+IxoC+Ykl1f+zMskGr
X-Developer-Key: i=cayoub@openai.com; a=ed25519;
 pk=3iLiZIUNdg97frhaiHfDNEIq1uD5UxhezQvebdhCZUo=
X-Endpoint-Received: by B4 Relay for cayoub@openai.com/20260809 with auth_id=931
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Directory entry merging currently performs a linear search of the
destination directory for each source entry. Repeating this operation
for wide directories makes snapshot rebuilding quadratic.

Add a temporary fixed-bucket index keyed by the parent inode and entry
name. Hash keys with the existing xxHash helper and resolve collisions
with list_head chains. Use 1,048,576 buckets to keep chains short for
million-entry rebuilds.

Use fixed list_head buckets instead of the generic hashmap implementation
while preserving the existing merge and replacement behavior. Release the
index when rebuilding finishes.

In the original reproducer, merging 129 layers containing approximately
2.4 million entries did not finish after 1195 seconds. With the index,
the same merge completed in 1.40 seconds. The widest directories
contained 65,212 and 83,318 entries.

Suggested-by: Gao Xiang <xiang@kernel.org>
Assisted-by: Codex:gpt-5
Signed-off-by: Chris Ayoub <cayoub@openai.com>
---
Snapshot rebuild currently performs a linear directory search for every
entry being merged.  This becomes prohibitively expensive for container
images with very wide directories.

The patch adds a temporary rebuild-only index keyed by parent inode and
entry name.  It uses the existing xxHash helper and fixed list_head buckets
instead of the generic hashmap implementation, preserving merge and
replacement behavior.

The original workload merged 129 layers containing approximately 2.4
million entries.  The unmodified rebuild did not finish after 1195 seconds;
the indexed version completed in 1.40 seconds.  The widest directories had
65,212 and 83,318 entries.

A shape-matched 129-layer replay with 2.4 million total entries and 800,000
unique live dentries completed in a 2.48-second median with list buckets,
versus 2.23 seconds with the v1 hashmap.  Their output images were
byte-identical, and fsck.erofs accepted the list-bucket image.

Validation against current dev (v1.9.3) on arm64 Ubuntu 24.04:

- Full builds with LZ4, LZMA, FUSE, and Zstd enabled, plus make check
- Byte-identical base, v1, and v2 output for file replacement, whiteout and
  opaque-directory handling, and an 8,000-entry directory
- Byte-identical v1 and v2 output for a 50,000-entry directory
- Extracted-tree checks for replacement, whiteout, and opaque semantics
- 50,000-entry local rebuild: 0.11 seconds for v1, 0.12 seconds for v2
- fsck.erofs validation and ASan coverage, including early-error cleanup
---
Changes in v2:
- Replace the generic hashmap implementation with fixed list_head buckets,
  as suggested by Gao Xiang.
- Hash parent/name keys with the existing xxHash helper.
- Revalidate output equivalence, wide-directory performance, fsck, and
  early-error cleanup against current dev.
- Link to v1: https://patch.msgid.link/20260809-rebuild-wide-directory-index-v1-1-ac8b7bce3edd@openai.com
---
 lib/liberofs_rebuild.h |  3 ++
 lib/rebuild.c          | 91 ++++++++++++++++++++++++++++++++++++++++++++++++++
 mkfs/main.c            |  4 +++
 3 files changed, 98 insertions(+)

diff --git a/lib/liberofs_rebuild.h b/lib/liberofs_rebuild.h
index 6459dbd..2ab6414 100644
--- a/lib/liberofs_rebuild.h
+++ b/lib/liberofs_rebuild.h
@@ -13,6 +13,9 @@ enum erofs_rebuild_datamode {
 struct erofs_dentry *erofs_rebuild_get_dentry(struct erofs_inode *pwd,
 		char *path, bool aufs, bool *whout, bool *opq, bool to_head);
 
+void erofs_rebuild_dentry_index_init(void);
+void erofs_rebuild_dentry_index_exit(void);
+
 int erofs_rebuild_load_tree(struct erofs_inode *root, struct erofs_sb_info *sbi,
 			    enum erofs_rebuild_datamode mode);
 
diff --git a/lib/rebuild.c b/lib/rebuild.c
index a5308dc..89a7600 100644
--- a/lib/rebuild.c
+++ b/lib/rebuild.c
@@ -17,6 +17,7 @@
 #include "erofs/io.h"
 #include "liberofs_rebuild.h"
 #include "liberofs_uuid.h"
+#include "liberofs_xxhash.h"
 
 #ifdef HAVE_LINUX_AUFS_TYPE_H
 #include <linux/aufs_type.h>
@@ -26,6 +27,79 @@
 #define AUFS_WH_DIROPQ		AUFS_WH_PFX AUFS_DIROPQ_NAME
 #endif
 
+struct erofs_rebuild_dentry_index_entry {
+	struct list_head list;
+	struct erofs_inode *parent;
+	struct erofs_dentry *dentry;
+};
+
+/*
+ * Keep chains short for million-entry rebuilds.  The bucket heads occupy
+ * 16 MiB on 64-bit systems and are initialized only when rebuilding.
+ */
+#define EROFS_REBUILD_DENTRY_HASHSIZE	1048576
+static struct list_head
+	erofs_rebuild_dentry_index_storage[EROFS_REBUILD_DENTRY_HASHSIZE];
+static struct list_head *erofs_rebuild_dentry_index;
+
+static unsigned int erofs_rebuild_dentry_hash(struct erofs_inode *parent,
+					      const char *name)
+{
+	u64 parent_addr = (uintptr_t)parent;
+	u32 parent_seed = parent_addr ^ (parent_addr >> 32);
+
+	/* Distinguish identical names belonging to different directories. */
+	return xxh32(name, strlen(name), parent_seed);
+}
+
+void erofs_rebuild_dentry_index_init(void)
+{
+	unsigned int i;
+
+	for (i = 0; i < ARRAY_SIZE(erofs_rebuild_dentry_index_storage); ++i)
+		init_list_head(&erofs_rebuild_dentry_index_storage[i]);
+	erofs_rebuild_dentry_index = erofs_rebuild_dentry_index_storage;
+}
+
+void erofs_rebuild_dentry_index_exit(void)
+{
+	struct erofs_rebuild_dentry_index_entry *indexed, *n;
+	unsigned int i;
+
+	if (!erofs_rebuild_dentry_index)
+		return;
+
+	for (i = 0; i < ARRAY_SIZE(erofs_rebuild_dentry_index_storage); ++i) {
+		list_for_each_entry_safe(indexed, n,
+					 &erofs_rebuild_dentry_index[i], list) {
+			list_del(&indexed->list);
+			free(indexed);
+		}
+	}
+	erofs_rebuild_dentry_index = NULL;
+}
+
+static int erofs_rebuild_dentry_index_add(struct erofs_inode *parent,
+					 struct erofs_dentry *dentry)
+{
+	struct erofs_rebuild_dentry_index_entry *indexed;
+
+	if (!erofs_rebuild_dentry_index)
+		return 0;
+
+	indexed = malloc(sizeof(*indexed));
+	if (!indexed)
+		return -ENOMEM;
+
+	indexed->parent = parent;
+	indexed->dentry = dentry;
+	list_add_tail(&indexed->list,
+		      &erofs_rebuild_dentry_index[
+			      erofs_rebuild_dentry_hash(parent, dentry->name) &
+			      (ARRAY_SIZE(erofs_rebuild_dentry_index_storage) - 1)]);
+	return 0;
+}
+
 /*
  * These non-existent parent directories are created with the same permissions
  * as their parent directories.  It is expected that a call to create these
@@ -76,6 +150,19 @@ struct erofs_dentry *erofs_d_lookup(struct erofs_inode *dir, const char *name)
 {
 	struct erofs_dentry *d;
 
+	if (erofs_rebuild_dentry_index) {
+		struct erofs_rebuild_dentry_index_entry *indexed;
+		unsigned int hash = erofs_rebuild_dentry_hash(dir, name);
+		struct list_head *head = &erofs_rebuild_dentry_index[
+			hash & (ARRAY_SIZE(erofs_rebuild_dentry_index_storage) - 1)];
+
+		list_for_each_entry(indexed, head, list)
+			if (indexed->parent == dir &&
+			    !strcmp(indexed->dentry->name, name))
+				return indexed->dentry;
+		return NULL;
+	}
+
 	list_for_each_entry(d, &dir->i_subdirs, d_child)
 		if (!strcmp(d->name, name))
 			return d;
@@ -134,12 +221,16 @@ struct erofs_dentry *erofs_rebuild_get_dentry(struct erofs_inode *pwd,
 				d = erofs_rebuild_mkdir(pwd, s);
 				if (IS_ERR(d))
 					return d;
+				if (erofs_rebuild_dentry_index_add(pwd, d))
+					return ERR_PTR(-ENOMEM);
 			} else {
 				d = erofs_d_alloc(pwd, s);
 				if (IS_ERR(d))
 					return d;
 				d->type = EROFS_FT_UNKNOWN;
 				d->inode = pwd;
+				if (erofs_rebuild_dentry_index_add(pwd, d))
+					return ERR_PTR(-ENOMEM);
 			}
 			pwd = d->inode;
 		}
diff --git a/mkfs/main.c b/mkfs/main.c
index 929ce7c..7158853 100644
--- a/mkfs/main.c
+++ b/mkfs/main.c
@@ -1680,21 +1680,25 @@ static int erofs_mkfs_rebuild_load_trees(struct erofs_inode *root)
 		return -EINVAL;
 	}
 
+	erofs_rebuild_dentry_index_init();
 	list_for_each_entry(src, &rebuild_src_list, list) {
 		src->xamgr = g_sbi.xamgr;
 		ret = erofs_rebuild_load_tree(root, src, datamode);
 		src->xamgr = NULL;
 		if (ret) {
 			erofs_err("failed to load %s", src->devname);
+			erofs_rebuild_dentry_index_exit();
 			return ret;
 		}
 		if (src->extra_devices > 1) {
 			erofs_err("%s: unsupported number %u of extra devices",
 				  src->devname, src->extra_devices);
+			erofs_rebuild_dentry_index_exit();
 			return -EOPNOTSUPP;
 		}
 		extra_devices += src->extra_devices;
 	}
+	erofs_rebuild_dentry_index_exit();
 
 	if (datamode == EROFS_REBUILD_DATA_RESVSP)
 		return 0;

---
base-commit: 7db78788b000999e2de88decd2ba90654f26171c
change-id: 20260809-rebuild-wide-directory-index-cfc39b34a68e

Best regards,
--  
Chris Ayoub <cayoub@openai.com>

