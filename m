From: Xiubo Li <xiubo.li@clyso.com>
Date: Fri, 30 Oct 2026 09:07:34 +0100
Subject: [PATCH v4 2/5] ceph: do not ask for LAZYIO for a lazy reader that
 holds CACHE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-b4-wip-ceph-lazyio-fix-v4-2-f734a26bbaab@clyso.com>
References: <20261030-b4-wip-ceph-lazyio-fix-v4-0-f734a26bbaab@clyso.com>
In-Reply-To: <20261030-b4-wip-ceph-lazyio-fix-v4-0-f734a26bbaab@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793347670; l=3495;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=9pCeVzQYSDJ5vZuuue3pphdfQCNRxqQXpuIHp+vghK8=;
 b=zr/BM/qg8XLf66sB/7lLayThtraymXPuwqOkBd8TDHJqIyVw6zfv9m757Zo2QZXuq6DBo63ML
 8ll547GwmHdDir1P41Hd3XdTLkGLKlFZSMfEIRUR2Uau5NdKA/RxYz2
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A lazy I/O open adds LAZYIO to the caps it wants.  When the inode
already has caps from a lookup or a stat, the open is satisfied locally,
but LAZYIO was never issued (nobody wanted it), so the client sends a
cap update to the MDS and gets a grant back: one extra round trip and
two MDS messages for every open.  io500 mdtest-hard-read, for one,
opens each file once from a client other than the writer's.

A reader whose cache is backed by CACHE gains nothing from LAZYIO.  Want
it only for writing, once CACHE is gone (e.g. the file went mixed: the
cap ack then asks for LAZYIO), or while it is still issued.  A lazy
reader of a file that goes mixed now drops its cache once before
LAZYIO arrives, instead of keeping it.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/caps.c  | 24 +++++++++++++++++++++++-
 fs/ceph/file.c  |  4 ++++
 fs/ceph/super.h |  1 +
 3 files changed, 28 insertions(+), 1 deletion(-)

diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index ae7b62b07462..c063d3cf7d21 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -1125,6 +1125,27 @@ static inline int ceph_adjust_caps_used_for_lazyio(struct ceph_inode_info *ci,
 
 #define FMODE_WAIT_BIAS 1000
 
+/*
+ * Does a lazy I/O open want LAZYIO?  A writer does, to keep buffering
+ * when the file goes mixed.  A reader whose cache is backed by CACHE
+ * gains nothing from it, and asking for it would cost a cap message to
+ * the MDS and a grant back for every open of a file that was looked up
+ * or stat'ed before: want it only once CACHE is gone, or keep it while
+ * it is still issued.
+ *
+ * Caller must hold i_ceph_lock.
+ */
+bool __ceph_lazy_wants_lazyio(struct ceph_inode_info *ci, bool write)
+{
+	int issued;
+
+	if (write)
+		return true;
+	issued = __ceph_caps_issued(ci, NULL);
+	return !(issued & CEPH_CAP_FILE_CACHE) ||
+	       (issued & CEPH_CAP_FILE_LAZYIO);
+}
+
 /*
  * wanted, by virtue of open file modes
  */
@@ -1179,7 +1200,8 @@ int __ceph_caps_file_wanted(struct ceph_inode_info *ci)
 
 		/* check lazyio only when read/write is wanted */
 		if ((bits & (CEPH_FILE_MODE_RDWR << 1)) &&
-		    ci->i_nr_by_mode[LAZY_SHIFT] > 0)
+		    ci->i_nr_by_mode[LAZY_SHIFT] > 0 &&
+		    __ceph_lazy_wants_lazyio(ci, bits & (1 << WR_SHIFT)))
 			bits |= 1 << LAZY_SHIFT;
 
 		return bits ? ceph_caps_for_mode(bits >> 1) : 0;
diff --git a/fs/ceph/file.c b/fs/ceph/file.c
index 856710c63765..fbdccbae0d17 100644
--- a/fs/ceph/file.c
+++ b/fs/ceph/file.c
@@ -462,6 +462,10 @@ int ceph_open(struct inode *inode, struct file *file)
 		int mds_wanted = __ceph_caps_mds_wanted(ci, true);
 		int issued = __ceph_caps_issued(ci, NULL);
 
+		if ((fmode & CEPH_FILE_MODE_LAZY) &&
+		    !__ceph_lazy_wants_lazyio(ci, fmode & CEPH_FILE_MODE_WR))
+			wanted &= ~CEPH_CAP_FILE_LAZYIO;
+
 		boutc(cl, "open %p fmode %d want %s issued %s using existing\n",
 		      inode, fmode, ceph_cap_string(wanted),
 		      ceph_cap_string(issued));
diff --git a/fs/ceph/super.h b/fs/ceph/super.h
index 458fd63dd79f..cdb238d48f72 100644
--- a/fs/ceph/super.h
+++ b/fs/ceph/super.h
@@ -952,6 +952,7 @@ static inline bool __ceph_all_opens_lazy(struct ceph_inode_info *ci)
 }
 
 extern int __ceph_caps_file_wanted(struct ceph_inode_info *ci);
+extern bool __ceph_lazy_wants_lazyio(struct ceph_inode_info *ci, bool write);
 extern int __ceph_caps_wanted(struct ceph_inode_info *ci);
 
 /* what the mds thinks we want */

-- 
2.53.0

