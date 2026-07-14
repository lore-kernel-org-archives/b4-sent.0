From: Xiubo Li <xiubo.li@clyso.com>
Date: Tue, 14 Jul 2026 14:20:37 +0800
Subject: [PATCH] ceph: fix use-after-dereference of NULL ci in
 __ceph_remove_cap()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260714-ceph-fix-remove-cap-v1-1-27b5bc6ee2f6@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMUQqDMBCE4avIPrugQZrSq5Q+rOtYt1ANiYog3
 t3YPn4w8++UEA2JHsVOEaslm8aMuixIBxnfYOuyyVXuVvm6YUUYuLeNI77TClYJrL3v7uLFNU4
 oP0NEXvyqz9ffaWk/0PlK0XGcpd+6AHcAAAA=
X-Change-ID: 20260714-ceph-fix-remove-cap-cf7d8a7a242a
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784010045; l=1741;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=ooSqkK6IVYP8K/OVskBxW937t4pyDtOQPUpfeEISEHY=;
 b=4//FPhq6KgagTG7f41be8cBiCVClaxaFVnSh67AOzk1hzSy6SbXQvnVf2R60XFFiAHUbODHSR
 gtMFoGu8RKWBfFyD7Ojs+kZstipgGwStwiWiMciXlZWJ7Tpgy1a/kAr
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The NULL check for "ci" in __ceph_remove_cap() was dead code because
ci was dereferenced via &ci->netfs.inode before the check, and
cap->session was dereferenced via session->s_mdsc->fsc->client even
earlier.  On a double-remove, both cap->ci and cap->session are set
to NULL by the first call, so the second call would crash before
ever reaching the guard.

Move ci, session, cl, and inode initializations after the NULL check
so that the early-return actually works.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/caps.c | 17 ++++++++++-------
 1 file changed, 10 insertions(+), 7 deletions(-)

diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index f8d898ad091e..8568edf494b5 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -1154,18 +1154,21 @@ int ceph_is_any_caps(struct inode *inode)
  */
 void __ceph_remove_cap(struct ceph_cap *cap, bool queue_release)
 {
-	struct ceph_mds_session *session = cap->session;
-	struct ceph_client *cl = session->s_mdsc->fsc->client;
-	struct ceph_inode_info *ci = cap->ci;
-	struct inode *inode = &ci->netfs.inode;
+	struct ceph_mds_session *session;
+	struct ceph_client *cl;
+	struct ceph_inode_info *ci;
+	struct inode *inode;
 	struct ceph_mds_client *mdsc;
 	int removed = 0;
 
 	/* 'ci' being NULL means the remove have already occurred */
-	if (!ci) {
-		doutc(cl, "inode is NULL\n");
+	ci = cap->ci;
+	if (!ci)
 		return;
-	}
+
+	session = cap->session;
+	cl = session->s_mdsc->fsc->client;
+	inode = &ci->netfs.inode;
 
 	lockdep_assert_held(&ci->i_ceph_lock);
 

---
base-commit: fc67edb66b3c9924c4e0bb366a92b32ea13c526a
change-id: 20260714-ceph-fix-remove-cap-cf7d8a7a242a

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

