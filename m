From: Xiubo Li <xiubo.li@clyso.com>
Date: Tue, 20 Oct 2026 10:05:50 +0200
Subject: [PATCH 4/5] ceph: ask for LAZYIO only once the MDS turns CACHE or
 BUFFER down
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-b4-wip-ceph-lazyio-fix-v1-4-f4cc62459d37@clyso.com>
References: <20261020-b4-wip-ceph-lazyio-fix-v1-0-f4cc62459d37@clyso.com>
In-Reply-To: <20261020-b4-wip-ceph-lazyio-fix-v1-0-f4cc62459d37@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792483564; l=3543;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=vM1YJ8Qdb6EoK/7Y+Z2XaIpcesKUcnEvtBTos7L2Q+s=;
 b=AKK4OdZXxriM/rdAq2splM2MD6YPQeGEzL3R2a8HqP3mg61t++9RgOSEncKUR/eca80XegfMw
 0+OuT+nwJECArMgic66FZDqCBdPhxLXYxTKF1AaXHRtoXQfSiLMBdzt
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A lazy I/O open asked for LAZYIO with the other caps of its mode.  The
MDS issues LAZYIO in LOCK_SYNC, but not in LOCK_SYNC_EXCL: an open for
writing by the only client of a synced file makes that client the
loner, and the MDS revokes the LAZYIO it has just issued on the way to
LOCK_EXCL.  mdtest's "read" phase opens files O_RDWR (it passes
O_RDONLY, 0, where the backend wants IOR_RDONLY), so with the lazyio
mount option a file read can cost a revoke and its ack.  A reader whose
caps came from a lookup also paid a cap message and a grant for LAZYIO
it had no use for.

LAZYIO only stands in for CACHE (reads) and BUFFER (writes) when the
MDS will not give those out, i.e. when the file goes mixed.  Ask for it
once CACHE, or BUFFER for a writer, is in the wanted set the MDS knows
of but not issued, and keep it while it is issued.  A lazy client of a
file that goes mixed then gets LAZYIO one cap message later than it
did.

Reading 2000 files O_RDWR from a second client cost 930 revokes and
2916 cap messages to the MDS before this change, and costs 0 revokes
and 2000 cap messages with it, the same as without lazyio.  In an io500
run the mdtest-hard-read phase still sees about one revoke per file
with lazyio (2.5-2.7M); those go away only when mdtest opens the files
read-only.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/caps.c | 30 +++++++++++++++++++-----------
 1 file changed, 19 insertions(+), 11 deletions(-)

diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index c063d3cf7d21..49e5c1c36b68 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -1126,24 +1126,32 @@ static inline int ceph_adjust_caps_used_for_lazyio(struct ceph_inode_info *ci,
 #define FMODE_WAIT_BIAS 1000
 
 /*
- * Does a lazy I/O open want LAZYIO?  A writer does, to keep buffering
- * when the file goes mixed.  A reader whose cache is backed by CACHE
- * gains nothing from it, and asking for it would cost a cap message to
- * the MDS and a grant back for every open of a file that was looked up
- * or stat'ed before: want it only once CACHE is gone, or keep it while
- * it is still issued.
+ * Does a lazy I/O open want LAZYIO?  It stands in for CACHE (reads) and
+ * BUFFER (writes) when the MDS will not give those out, i.e. when the
+ * file goes mixed.  Until then it gains nothing, and asking for it costs:
+ * the MDS issues LAZYIO in LOCK_SYNC, but not in LOCK_SYNC_EXCL, so an
+ * open that makes the client the loner of a synced file (any open for
+ * writing by a single client, as mdtest's "read" phase does) gets the
+ * LAZYIO it asked for revoked again on the way to LOCK_EXCL: a revoke and
+ * its ack for every file opened.  A reader whose caps came from a lookup
+ * also paid a cap message and a grant for it.
+ *
+ * So want LAZYIO once the MDS has turned CACHE (BUFFER for a writer)
+ * down, i.e. it is in the wanted set the MDS knows of but not issued,
+ * and keep it while it is issued.
  *
  * Caller must hold i_ceph_lock.
  */
 bool __ceph_lazy_wants_lazyio(struct ceph_inode_info *ci, bool write)
 {
-	int issued;
+	int need = write ? CEPH_CAP_FILE_BUFFER : CEPH_CAP_FILE_CACHE;
+	int issued = __ceph_caps_issued(ci, NULL);
 
-	if (write)
+	if (issued & CEPH_CAP_FILE_LAZYIO)
 		return true;
-	issued = __ceph_caps_issued(ci, NULL);
-	return !(issued & CEPH_CAP_FILE_CACHE) ||
-	       (issued & CEPH_CAP_FILE_LAZYIO);
+	if (issued & need)
+		return false;
+	return __ceph_caps_mds_wanted(ci, true) & need;
 }
 
 /*

-- 
2.53.0

