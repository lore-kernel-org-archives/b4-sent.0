From: Xiubo Li <xiubo.li@clyso.com>
Date: Wed, 21 Oct 2026 13:52:03 +0200
Subject: [PATCH v2 1/5] ceph: invalidate a revoked cache even while its cap
 is stale
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261021-b4-wip-ceph-lazyio-fix-v2-1-25d28479d6ea@clyso.com>
References: <20261021-b4-wip-ceph-lazyio-fix-v2-0-25d28479d6ea@clyso.com>
In-Reply-To: <20261021-b4-wip-ceph-lazyio-fix-v2-0-25d28479d6ea@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792583534; l=3450;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=8QRSQn0Y4TVaLVXe6qoY9/nZ1m8oLxj3xBc5YKZ5mow=;
 b=nYumE/Qxkwb+5GrS8YtwEusKpRzxaR3c+W2llfIHuR4OpoKl2fHeNPAll9K1NoTByNvMwhEeD
 9WIGcneeVoaCcwiL7BWVDpNL4+B7D186GvJDFVAaI+zUj+ioHYvt4uC
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ceph_check_caps() decides whether to invalidate the page cache from the
caps being revoked as __ceph_caps_issued() reports them, and that skips
a cap whose session's TTL has run out.  When it runs in that window for
a file whose CACHE or LAZYIO is being revoked, it does not invalidate
the cache, the per-cap check then finds the cache still in use and
waits, and nothing calls it again without CHECK_CAPS_NOINVAL: the MDS
waits for the revocation for good, and every other client's request
that needs the lock with it.  A lazyio writer on a slow client (arm64
64K pages under QEMU, whose sessions keep going stale and getting
renewed) hung that way after shared-file writes.

Ask every cap whether it is revoking CACHE or LAZYIO before deciding,
and when a session's caps are renewed, check the caps of every inode
with a revocation pending, so a decision put off while the cap was
stale is made again.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/caps.c       | 12 ++++++++++--
 fs/ceph/mds_client.c | 10 ++++++++++
 2 files changed, 20 insertions(+), 2 deletions(-)

diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index b27bcdc24d29..ae7b62b07462 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -2260,12 +2260,20 @@ void ceph_check_caps(struct ceph_inode_info *ci, int flags)
 	 * have cached pages, but don't want them, then try to invalidate.
 	 * If we fail, it's because pages are locked.... try again later.
 	 */
+	/*
+	 * "revoking" above only covers the caps that are valid right now:
+	 * a cap whose session's TTL ran out is left out of it, though the
+	 * MDS still waits for it to give up CACHE/LAZYIO.  Ask every cap
+	 * here, or the cache of such a cap is never invalidated, the
+	 * per-cap check below finds the cache still in use and the
+	 * revocation is never acked.
+	 */
 	if ((!(flags & CHECK_CAPS_NOINVAL) || mdsc->stopping) &&
 	    S_ISREG(inode->i_mode) &&
 	    !(ci->i_wb_ref || ci->i_wrbuffer_ref) &&   /* no dirty pages... */
 	    inode->i_data.nrpages &&		/* have cached pages */
-	    (revoking & (CEPH_CAP_FILE_CACHE|
-			 CEPH_CAP_FILE_LAZYIO)) && /*  or revoking cache */
+	    __ceph_caps_revoking_other(ci, NULL, CEPH_CAP_FILE_CACHE |
+					     CEPH_CAP_FILE_LAZYIO) &&
 	    !tried_invalidate) {
 		doutc(cl, "trying to invalidate on %p %llx.%llx\n",
 		      inode, ceph_vinop(inode));
diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index d4ef8a355a48..dc8ecd771620 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -2138,13 +2138,23 @@ static int wake_up_session_cb(struct inode *inode, int mds, void *arg)
 		spin_unlock(&ci->i_ceph_lock);
 	} else if (ev == RENEWCAPS) {
 		struct ceph_cap *cap;
+		bool revoking = false;
 
 		spin_lock(&ci->i_ceph_lock);
 		cap = __get_cap_for_mds(ci, mds);
 		/* mds did not re-issue stale cap */
 		if (cap && cap->cap_gen < atomic_read(&cap->session->s_cap_gen))
 			cap->issued = cap->implemented = CEPH_CAP_PIN;
+		/*
+		 * A revocation that ceph_check_caps() put off while the cap
+		 * was stale (its cache was not invalidated then) is not
+		 * looked at again by anything else: check the caps now.
+		 */
+		if (cap && (cap->implemented & ~cap->issued))
+			revoking = true;
 		spin_unlock(&ci->i_ceph_lock);
+		if (revoking)
+			ceph_queue_check_caps(inode);
 	} else if (ev == FORCE_RO) {
 	}
 	wake_up_all(&ci->i_cap_wq);

-- 
2.53.0

