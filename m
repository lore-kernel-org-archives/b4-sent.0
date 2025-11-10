From: Xin Wang <xwang@ddn.com>
Date: Mon, 10 Nov 2025 08:31:02 +0000
Subject: [PATCH] fuse: Umask handling problem if FUSE_CAP_DONT_MASK is
 disabled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251110-fuse_acl_umask-v1-1-cf1d431cae06@ddn.com>
X-B4-Tracking: v=1; b=H4sIAMWiEWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDQ0MD3bTS4tT4xOSc+NLcxOJs3cQ08yQTkxQjYzNTCyWgpoKi1LTMCrC
 B0bG1tQDNpDN+YAAAAA==
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: linux-fsdevel@vger.kernel.org, bschubert@ddn.com, gwu@ddn.com, 
 Xin Wang <xwang@ddn.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762763481; l=3412;
 i=xwang@ddn.com; s=20251110; h=from:subject:message-id;
 bh=Gy+2d2kF9z2hAE/298jrIqc0SMibW2BMrzDNvDUnckQ=;
 b=+417Hkhu3M6dN87YbsEfWVcZkOiooZmV3ZhyYKQoM6kunPcwS3jmKn786NUOHGw9tryaItxAz
 U8kxgK3C1JeAL4OzZUFLuy2tAWGV8VNgO+/Qdgbzpp9GENc0DhSZmpE
X-Developer-Key: i=xwang@ddn.com; a=ed25519;
 pk=2NZ7S3gXVdveRFk4yNU1Q6JCNiAedXyGWBm7ipgv5kE=
X-Endpoint-Received: by B4 Relay for xwang@ddn.com/20251110 with auth_id=563
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

According to umask manpage, it should be ignored if the parent has a
default ACL.  But currently, if FUSE_CAP_DONT_MASK is disabled, fuse
always applies umask no matter if the parent has a default ACL or not.
This behaviior is not consistent with the behavior described in the
manpage.

Fix the problem by checking if the parent has a default ACL before
applying umask if FUSE_CAP_DONT_MASK is disabled.

---
We found that there may be a problem about umask handling in fuse code.
According to umask manpage, it should be ignored if the parent has a
default ACL. But currently, if FUSE_CAP_DONT_MASK is disabled, fuse always
applies umask no matter if the parent has a default ACL or not. So, we
think this may be a problem because it is not consistent with the behavior
described in the manpage.

umask manpage:
       Alternatively, if the parent directory has a default ACL
       (see acl(5)), the umask is ignored, the default ACL is inherited,
       the permission bits are set based on the inherited ACL, …

Signed-off-by: Xin Wang <xwang@ddn.com>
---
 fs/fuse/dir.c | 42 ++++++++++++++++++++++++++++++++++++------
 1 file changed, 36 insertions(+), 6 deletions(-)

diff --git a/fs/fuse/dir.c b/fs/fuse/dir.c
index ecaec0fea3a1..f8ab6d76ae35 100644
--- a/fs/fuse/dir.c
+++ b/fs/fuse/dir.c
@@ -645,8 +645,18 @@ static int fuse_create_open(struct mnt_idmap *idmap, struct inode *dir,
 	if (!ff)
 		goto out_put_forget_req;
 
-	if (!fm->fc->dont_mask)
-		mode &= ~current_umask();
+	if (!fm->fc->dont_mask) {
+		/*
+		 * If the parent has a default ACL, the umask is
+		 * ignored, the default ACL is inherited, the
+		 * permission bits are set based on the inherited
+		 * default ACL
+		 */
+		struct posix_acl *p =
+			get_inode_acl(dir, ACL_TYPE_DEFAULT);
+		if (!p || p == ERR_PTR(-EOPNOTSUPP))
+			mode &= ~current_umask();
+	}
 
 	flags &= ~O_NOCTTY;
 	memset(&inarg, 0, sizeof(inarg));
@@ -872,8 +882,18 @@ static int fuse_mknod(struct mnt_idmap *idmap, struct inode *dir,
 	struct fuse_mount *fm = get_fuse_mount(dir);
 	FUSE_ARGS(args);
 
-	if (!fm->fc->dont_mask)
-		mode &= ~current_umask();
+	if (!fm->fc->dont_mask) {
+		/*
+		 * If the parent has a default ACL, the umask is
+		 * ignored, the default ACL is inherited, the
+		 * permission bits are set based on the inherited
+		 * default ACL
+		 */
+		struct posix_acl *p =
+			get_inode_acl(dir, ACL_TYPE_DEFAULT);
+		if (!p || p == ERR_PTR(-EOPNOTSUPP))
+			mode &= ~current_umask();
+	}
 
 	memset(&inarg, 0, sizeof(inarg));
 	inarg.mode = mode;
@@ -919,8 +939,18 @@ static struct dentry *fuse_mkdir(struct mnt_idmap *idmap, struct inode *dir,
 	struct fuse_mount *fm = get_fuse_mount(dir);
 	FUSE_ARGS(args);
 
-	if (!fm->fc->dont_mask)
-		mode &= ~current_umask();
+	if (!fm->fc->dont_mask) {
+		/*
+		 * If the parent has a default ACL, the umask is
+		 * ignored, the default ACL is inherited, the
+		 * permission bits are set based on the inherited
+		 * default ACL
+		 */
+		struct posix_acl *p =
+			get_inode_acl(dir, ACL_TYPE_DEFAULT);
+		if (!p || p == ERR_PTR(-EOPNOTSUPP))
+			mode &= ~current_umask();
+	}
 
 	memset(&inarg, 0, sizeof(inarg));
 	inarg.mode = mode;

---
base-commit: 4a0c9b3391999818e2c5b93719699b255be1f682
change-id: 20251110-fuse_acl_umask-af7b44d23658

Best regards,
-- 
Xin Wang <xwang@ddn.com>

