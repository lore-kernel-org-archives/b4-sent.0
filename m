From: Xiubo Li <xiubo.li@clyso.com>
Date: Tue, 25 Aug 2026 22:23:37 -0700
Subject: [PATCH v2 1/2] ceph: mark the superblock active after mounting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-b4-b4-ceph-dentry-caps-v2-1-41201d7a4868@clyso.com>
References: <20260825-b4-b4-ceph-dentry-caps-v2-0-41201d7a4868@clyso.com>
In-Reply-To: <20260825-b4-b4-ceph-dentry-caps-v2-0-41201d7a4868@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>, Jeff Layton <jlayton@kernel.org>, 
 David Howells <dhowells@redhat.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787721829; l=1739;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=ixCFtWZ2ctnytGgDbGQ+GA3BkQV45N30qXqkNKfViuY=;
 b=1Y+mOAdwJEnFaHrRHZi2y29bZuPufLAC8aI7ZpKx5PDqAFf7WRTQ99zGPcmZlR5kjRdWGHbq+
 o7NUX2P4O4qCcD2GBFWiS/s2GcYZzb+Cd3p0UKrRxUUfPot1AAH0Kw6
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ceph_get_tree() calls sget_fc() directly and so never goes through
vfs_get_super(), which is what sets SB_ACTIVE after fill_super for
filesystems that use it.  Before commit 82995cc6c5ae ("libceph, rbd,
ceph: convert to use the new mount API") the flag used to be set by
get_sb_nodev(), which did this for ceph, but the conversion dropped it.

SB_ACTIVE is required for iput_final() to retain an inode on the
inode LRU instead of evicting it once its last reference goes away.
This has gone unnoticed because ceph sets inode_just_drop() for
->drop_inode, which always asks for eviction, so the retain branch in
iput_final() was never reachable.  The next patch makes ->drop_inode()
able to retain inodes, and that needs the flag to actually work.

Set it once the mount is up, like nfs_get_tree() does.

Fixes: 82995cc6c5ae ("libceph, rbd, ceph: convert to use the new mount API")
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/super.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/fs/ceph/super.c b/fs/ceph/super.c
index 518ee63d55fb..6573285d704a 100644
--- a/fs/ceph/super.c
+++ b/fs/ceph/super.c
@@ -1381,6 +1381,15 @@ static int ceph_get_tree(struct fs_context *fc)
 	doutc(fsc->client, "root %p inode %p ino %llx.%llx\n", res,
 		    d_inode(res), ceph_vinop(d_inode(res)));
 	fc->root = fsc->sb->s_root;
+
+	/*
+	 * The mount is up.  sget_fc() leaves SB_ACTIVE unset, and, unlike
+	 * filesystems that go through vfs_get_super(), nothing else sets
+	 * it here, so iput_final() would always evict an inode whose
+	 * ->drop_inode() asks to retain it.  Set it like nfs_get_tree()
+	 * does.
+	 */
+	sb->s_flags |= SB_ACTIVE;
 	return 0;
 
 out_splat:

-- 
2.53.0

