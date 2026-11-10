From: Daejun Park <daejun7.park@samsung.com>
Date: Tue, 10 Nov 2026 17:03:09 +0900
Subject: [PATCH] ovl: skip stale entries in impure dir iteration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-ovl-impure-stale-v1-1-1a4c2039e89d@samsung.com>
X-B4-Tracking: v=1; b=H4sIALzP8moC/x3MTQqAIBBA4avIrBtwNIq6SrSQmmqgH9GSILp70
 vJbvPdA5CAcoVUPBE4S5dgzqFAwLG6fGWXMBqNNRUQaj7SibP4KjPF0K6ObrC0NOd3UNeTMB57
 k/pdd/74faBG7j2IAAAA=
To: Miklos Szeredi <miklos@szeredi.hu>, Amir Goldstein <amir73il@gmail.com>
Cc: Hungyu Lin <dennylin0707@gmail.com>, linux-unionfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794297788; l=7510;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=2dnXtw2T+i/5B0PuW3RuxH9Poq9RI1r3zJVp+DkMk24=;
 b=NGXtsXteya3Zz5brWtYnnCqOGTGXgSZeMZ7fnIhrN/QbpFWKu6Bb2kZzx5Lfe/C5iU24e7kEh
 ZBxVFkXgefuCGdQl1XEu4CP2rF4xMc6iObyVSzCKakjwdtXDF14nhqF
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ext4 returns the entry that did not fit in the previous getdents buffer
first in the next call, even after it was unlinked. The rebuilt impure
cache no longer has it. ovl_fill_real() then reports its upper inode
number. overlay/077 hits this.

Remember the entry that did not fit and look it up before the next
call. Skip it if it is gone, as commit 9011c2791e63 ("ovl: skip stale
entries in merge dir cache iteration") does for merge dirs.

Fixes: 4edb83bb1041 ("ovl: constant d_ino for non-merge dirs")
Reported-by: Hungyu Lin <dennylin0707@gmail.com>
Closes: https://lore.kernel.org/linux-unionfs/CAGEkeHcg06kHshHQ=9U6Yrs_wm8W9H28o9bcC2Qh3fw3tANbWA@mail.gmail.com/
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
With the fstests change "overlay/077: check a stale entry in an impure
dir on any hash seed", overlay/077 fails on 3 of 3 random ext4 hash
seeds before and passes after, also with index=on,nfs_export=on. The
test checks both a removed and a recreated next entry. overlay/quick on
xfs passes.

Not covered: names on the same hash collision chain as the entry that
did not fit also come from the cached tree. A removed entry with origin
there is still listed with its upper inode number, as before this patch.
---
 fs/overlayfs/readdir.c | 120 +++++++++++++++++++++++++++++++++++++++++++++++--
 1 file changed, 117 insertions(+), 3 deletions(-)

diff --git a/fs/overlayfs/readdir.c b/fs/overlayfs/readdir.c
index 4cd4af097e5c..0ebc4fe477b7 100644
--- a/fs/overlayfs/readdir.c
+++ b/fs/overlayfs/readdir.c
@@ -58,10 +58,25 @@ struct ovl_readdir_data {
 	bool in_xwhiteouts_dir;
 };
 
+/*
+ * An impure dir entry with origin that the caller of the previous getdents
+ * did not take. The real dir may return it first in the next call, even
+ * after it was removed or replaced.
+ */
+struct ovl_dir_next {
+	u64 version;		/* dir version when it was refused */
+	u64 real_ino;
+	u64 ino;		/* d_ino to report */
+	bool gone;		/* removed since, skip it */
+	int len;
+	char name[];
+};
+
 struct ovl_dir_file {
 	bool is_real;
 	bool is_upper;
 	struct ovl_dir_cache *cache;
+	struct ovl_dir_next *next;
 	struct list_head *cursor;
 	struct file *realfile;
 	struct file *upperfile;
@@ -413,6 +428,8 @@ static void ovl_dir_reset(struct file *file)
 		od->cache = NULL;
 		od->cursor = NULL;
 	}
+	kfree(od->next);
+	od->next = NULL;
 	is_real = ovl_dir_is_real(inode);
 	if (od->is_real != is_real) {
 		/* is_real can only become false when dir is copied up */
@@ -767,6 +784,10 @@ static struct ovl_dir_cache *ovl_cache_get_impure(struct file *file)
 struct ovl_readdir_translate {
 	struct dir_context *orig_ctx;
 	struct ovl_dir_cache *cache;
+	struct ovl_dir_next *next;		/* refused before */
+	struct ovl_cache_entry *refused;	/* refused in this call */
+	u64 refused_ino;			/* its d_ino from the real dir */
+	bool next_refused;
 	struct dir_context ctx;
 	u64 parent_ino;
 	int fsid;
@@ -781,13 +802,24 @@ static bool ovl_fill_real(struct dir_context *ctx, const char *name,
 	struct ovl_readdir_translate *rdt =
 		container_of(ctx, struct ovl_readdir_translate, ctx);
 	struct dir_context *orig_ctx = rdt->orig_ctx;
+	struct ovl_dir_next *next = rdt->next;
+	struct ovl_cache_entry *p = NULL;
+	u64 real_ino = ino;
+	bool is_next = false;
 	bool res;
 
-	if (rdt->parent_ino && name_is_dotdot(name, namelen)) {
+	if (next && next->real_ino == ino && next->len == namelen &&
+	    !memcmp(next->name, name, namelen)) {
+		/* Looked up before this call if the dir changed */
+		if (next->gone) {
+			rdt->next = NULL;
+			return true;
+		}
+		ino = next->ino;
+		is_next = true;
+	} else if (rdt->parent_ino && name_is_dotdot(name, namelen)) {
 		ino = rdt->parent_ino;
 	} else if (rdt->cache) {
-		struct ovl_cache_entry *p;
-
 		p = ovl_cache_entry_find(&rdt->cache->root, name, namelen);
 		if (p)
 			ino = p->ino;
@@ -798,10 +830,63 @@ static bool ovl_fill_real(struct dir_context *ctx, const char *name,
 
 	res = orig_ctx->actor(orig_ctx, name, namelen, offset, ino, d_type);
 	ctx->count = orig_ctx->count;
+	if (!res) {
+		if (is_next) {
+			rdt->next_refused = true;
+		} else {
+			rdt->refused = p;
+			rdt->refused_ino = real_ino;
+		}
+	}
 
 	return res;
 }
 
+/*
+ * The dir changed since the previous call refused this entry. Look the name
+ * up as ovl_cache_update() does, and report what stat() would return now.
+ */
+static int ovl_dir_next_update(const struct path *path,
+			       struct ovl_dir_next *next)
+{
+	struct path statpath = *path;
+	struct dentry *this;
+	struct kstat stat;
+	int err = 0;
+
+	this = lookup_one(mnt_idmap(path->mnt), &QSTR_LEN(next->name, next->len),
+			  path->dentry);
+	if (IS_ERR(this))
+		return PTR_ERR(this);
+	if (!this->d_inode) {
+		next->gone = true;
+	} else {
+		statpath.dentry = this;
+		err = vfs_getattr(&statpath, &stat, STATX_INO, 0);
+		if (!err)
+			next->ino = stat.ino;
+	}
+	dput(this);
+	return err;
+}
+
+static struct ovl_dir_next *ovl_dir_next_new(struct ovl_cache_entry *p,
+					     u64 real_ino, u64 version)
+{
+	struct ovl_dir_next *next;
+
+	next = kmalloc_flex(*next, name, p->len);
+	if (!next)
+		return NULL;
+	next->version = version;
+	next->real_ino = real_ino;
+	next->ino = p->ino;
+	next->gone = false;
+	next->len = p->len;
+	memcpy(next->name, p->name, p->len);
+	return next;
+}
+
 static bool ovl_is_impure_dir(struct file *file)
 {
 	struct ovl_dir_file *od = file->private_data;
@@ -863,9 +948,32 @@ static int ovl_iterate_real(struct file *file, struct dir_context *ctx)
 			return PTR_ERR(rdt.cache);
 	}
 
+	/* Even if no longer impure: od->next was its last origin entry */
+	if (od->next) {
+		u64 version = ovl_inode_version_get(d_inode(dir));
+
+		if (od->next->version != version) {
+			err = ovl_dir_next_update(&file->f_path, od->next);
+			if (err)
+				return err;
+			od->next->version = version;
+		}
+		rdt.next = od->next;
+	}
+
 	err = iterate_dir(od->realfile, &rdt.ctx);
 	ctx->pos = rdt.ctx.pos;
 
+	if (!rdt.next_refused) {
+		u64 version = ovl_inode_version_get(d_inode(dir));
+
+		kfree(od->next);
+		od->next = NULL;
+		if (rdt.refused)
+			od->next = ovl_dir_next_new(rdt.refused,
+						    rdt.refused_ino, version);
+	}
+
 	return err;
 }
 
@@ -908,6 +1016,7 @@ static int ovl_iterate_merged(struct file *file, struct dir_context *ctx)
 
 static bool ovl_need_adjust_d_ino(struct file *file)
 {
+	struct ovl_dir_file *od = file->private_data;
 	struct dentry *dentry = file->f_path.dentry;
 	struct ovl_fs *ofs = OVL_FS(dentry->d_sb);
 	struct dentry *parent;
@@ -925,6 +1034,10 @@ static bool ovl_need_adjust_d_ino(struct file *file)
 	if (ovl_is_impure_dir(file))
 		return true;
 
+	/* An entry the previous call refused may still need adjusting */
+	if (od->next)
+		return true;
+
 	/* If parent is merge, then need to adjust d_ino for '..' */
 	parent = dget_parent(dentry);
 	type = ovl_path_type(parent);
@@ -1073,6 +1186,7 @@ static int ovl_dir_release(struct inode *inode, struct file *file)
 		ovl_cache_put(od, inode);
 		inode_unlock(inode);
 	}
+	kfree(od->next);
 	fput(od->realfile);
 	if (od->upperfile)
 		fput(od->upperfile);

---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261110-ovl-impure-stale-af33421a0977

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

