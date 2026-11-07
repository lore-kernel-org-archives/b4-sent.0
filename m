From: Xiubo Li <xiubo.li@clyso.com>
Date: Sat, 07 Nov 2026 03:51:28 +0100
Subject: [PATCH 2/2] ceph: do not hold a LAZYIO revoke for pages that CACHE
 covers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-ceph-lazyio-noread-v1-2-d04369c70ab7@clyso.com>
References: <20261107-ceph-lazyio-noread-v1-0-d04369c70ab7@clyso.com>
In-Reply-To: <20261107-ceph-lazyio-noread-v1-0-d04369c70ab7@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794019887; l=3142;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=Sl0LxPrKAtHetqfgc/TKI9v6Rg/tbvwlkGhYdSOWqMI=;
 b=bw9rbPPEQieegybJkeMG7glGLYFOC+04SaXe7t3wbwxt9taaR+MY8dEqxARA5+e3xgsoHNoCr
 XkOaBfSOTd+Dlrc3HslhIvrqneusNN5OM38S0kGQIG0didjCNYKc2YV
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ceph_adjust_caps_used_for_lazyio() reports LAZYIO as used in place of
CACHE or BUFFER when that cap is not issued.  It does so even when the
used set does not contain the cap at all: with BUFFER not issued, a
file that only has clean pages cached (CACHE used and still issued)
is reported as using LAZYIO too.

When the MDS then revokes LAZYIO and leaves CACHE issued, e.g. from a
writer that has closed the file, (revoking & used) stays non-zero.
handle_cap_grant() checks the caps with CHECK_CAPS_NOINVAL and there
are no dirty pages to write back, so nothing acks the revoke until the
delayed cap check runs, up to caps_wanted_delay_max (60 s) later.  The
MDS request that needed the revoke, such as a getattr from another
client, waits that long.

Only move a use to LAZYIO when it is in the used set and its cap is
not issued.

Reproducer, 5 lazyio mounts: 4 create ~174k files of 3901 bytes in
one directory, a 5th lstats them all, then a 4th mount opens and
writes 5000 files of the 1st one.  Mean of 4 runs (open+write: 2):

+--------------------------------+---------+---------+
| metric                         |    base |   patch |
+--------------------------------+---------+---------+
| unacked revokes after lstat    |    7355 |      10 |
| lstat walk time (s)            |   27.69 |   25.19 |
| open+write p50 (ms)            |    2.70 |    2.89 |
| open+write p99 (ms)            |    3.26 |    3.53 |
| open+write max (ms)            |  5325.8 |    51.9 |
| open+write calls > 1 s         |       1 |       0 |
+--------------------------------+---------+---------+

In a parallel walk that stats every file with 4 clients and 3 active
MDS ranks, right after other lazy I/O clients wrote the files, the walk
no longer stalls on such revokes: its worst time over the runs went
from 90.2 s to 42.4 s, and its mean from 51.7 s to 41.5 s.

Fixes: 488ffbdd99d8 ("ceph: add 'lazyio' mount option to kclient")
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/caps.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index aca09351a094..5669e458f287 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -1112,11 +1112,18 @@ static inline int ceph_adjust_caps_used_for_lazyio(struct ceph_inode_info *ci,
 	 */
 	if ((issued & CEPH_CAP_FILE_LAZYIO) && !__ceph_all_opens_lazy(ci))
 		return used;
-	if (!(issued & CEPH_CAP_FILE_CACHE)) {
+	/*
+	 * Only a use that the issued caps no longer cover moves to LAZYIO.
+	 * Clean pages under an issued CACHE are not using LAZYIO, so a
+	 * revoke of LAZYIO that leaves CACHE issued must not count them;
+	 * otherwise it is never acked from handle_cap_grant() and waits
+	 * for the delayed cap check.
+	 */
+	if ((used & CEPH_CAP_FILE_CACHE) && !(issued & CEPH_CAP_FILE_CACHE)) {
 		used &= ~CEPH_CAP_FILE_CACHE;
 		used |= CEPH_CAP_FILE_LAZYIO;
 	}
-	if (!(issued & CEPH_CAP_FILE_BUFFER)) {
+	if ((used & CEPH_CAP_FILE_BUFFER) && !(issued & CEPH_CAP_FILE_BUFFER)) {
 		used &= ~CEPH_CAP_FILE_BUFFER;
 		used |= CEPH_CAP_FILE_LAZYIO;
 	}

-- 
2.53.0

