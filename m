From: Xiubo Li <xiubo.li@clyso.com>
Date: Thu, 23 Jul 2026 14:28:19 +0800
Subject: [PATCH] ceph: do not cache negative dentries for snapped
 directories
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260723-b4-snap-negative-dentry-v1-1-c78178117929@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBG4auQWTsJbdBGr2JctPCD42IknUI0h
 Ltbdfkt3tvIkAVGl2ajjFVMnlrhDg3196gTWIZq8q0/tcF7Th2bxpkVUyyyggdoyW9OaQxdcOf
 ojo5qPWeM8vqdr7e/bUkP9OW7o33/AFn5CKd7AAAA
X-Change-ID: 20260722-b4-snap-negative-dentry-bbf74719a151
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: Dhairya Parmar <dparmar@redhat.com>, ceph-devel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Andras Pataki <apataki@flatironinstitute.org>, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784788106; l=2717;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=IQw0JIRgW0RO39xXG7APolmM9Qi7REzbCEwy1oF6S94=;
 b=m9Tub+llkZehLKdx+aCcduZk/0So1CxY8W2Hh2pvcvjNpsg7qlC6UJfBcoePtsmY9Z7qUP0vo
 d6+eWxdPGJbBkPkf7KXtYmqQx6nb0eI1aZClCJ+mCHSOlXy+oabsX18
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a LOOKUP/LOOKUPSNAP in a snapped directory returns ENOENT
without a trace, ceph_finish_lookup() creates a negative dentry
via d_add(dentry, NULL).  For live directories this is fine — the
dentry naturally expires.  But for snapped directories,
ceph_d_revalidate() unconditionally trusts all cached dentries
(valid = 1), so a negative dentry created by a transient error
persists forever, hiding entries that genuinely exist in the
snapshot.

Only cache negative dentries for live (non-snapshotted) parent
directories.  For snapped parents, skip the negative dentry so
that VFS retries the lookup on the next access.  Since the
conditions that trigger a negative dentry (MDS transient error,
local ENOENT shortcut, or MDS null dentry lease) are all rare in
snapped directories, the performance impact of this change is
negligible.

Reported-by: Andras Pataki <apataki@flatironinstitute.org>
Closes: https://tracker.ceph.com/issues/78529
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/dir.c   | 10 ++++++++--
 fs/ceph/inode.c |  3 ++-
 2 files changed, 10 insertions(+), 3 deletions(-)

diff --git a/fs/ceph/dir.c b/fs/ceph/dir.c
index b4b541a1180c..d5d8f935fb62 100644
--- a/fs/ceph/dir.c
+++ b/fs/ceph/dir.c
@@ -774,8 +774,13 @@ struct dentry *ceph_finish_lookup(struct ceph_mds_request *req,
 				d_drop(dentry);
 				err = -ENOENT;
 			} else {
-				if (d_unhashed(dentry))
-					d_add(dentry, NULL);
+				if (d_unhashed(dentry)) {
+					struct inode *parent =
+						d_inode(dentry->d_parent);
+					if (!parent ||
+					    ceph_snap(parent) == CEPH_NOSNAP)
+						d_add(dentry, NULL);
+				}
 			}
 		}
 	}
@@ -840,6 +845,7 @@ static struct dentry *ceph_lookup(struct inode *dir, struct dentry *dentry,
 			    dentry->d_name.len) &&
 		    !is_root_ceph_dentry(dir, dentry) &&
 		    ceph_test_mount_opt(fsc, DCACHE) &&
+		    ceph_snap(dir) == CEPH_NOSNAP &&
 		    __ceph_dir_is_complete(ci) &&
 		    __ceph_caps_issued_mask_metric(ci, CEPH_CAP_FILE_SHARED, 1)) {
 			__ceph_touch_fmode(ci, mdsc, CEPH_FILE_MODE_RD);
diff --git a/fs/ceph/inode.c b/fs/ceph/inode.c
index 61d7c0b8161f..d52e2b389e0b 100644
--- a/fs/ceph/inode.c
+++ b/fs/ceph/inode.c
@@ -1814,7 +1814,8 @@ int ceph_fill_trace(struct super_block *sb, struct ceph_mds_request *req)
 				ceph_dir_clear_ordered(dir);
 				d_delete(dn);
 			} else if (have_lease) {
-				if (d_unhashed(dn))
+				if (d_unhashed(dn) &&
+				    ceph_snap(dir) == CEPH_NOSNAP)
 					d_add(dn, NULL);
 			}
 

---
base-commit: 602bb4525c8146865b7f6e44c81d54bf97861aed
change-id: 20260722-b4-snap-negative-dentry-bbf74719a151

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

