From: Xiubo Li <xiubo.li@clyso.com>
Date: Tue, 20 Oct 2026 10:05:51 +0200
Subject: [PATCH 5/5] ceph: keep LAZYIO with the read caps of a closed file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-b4-wip-ceph-lazyio-fix-v1-5-f4cc62459d37@clyso.com>
References: <20261020-b4-wip-ceph-lazyio-fix-v1-0-f4cc62459d37@clyso.com>
In-Reply-To: <20261020-b4-wip-ceph-lazyio-fix-v1-0-f4cc62459d37@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792483564; l=1563;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=vCRKa1jTwTRmyvIPqElXVacQQHdBR1gNvKu9DI1jLQE=;
 b=Z/Hs4K4lnERsSrvgustj02cukELiGN4Y+hBDpPlHF02CYvdciuRLbk+RUlhqGv0YUZ9UbMxQK
 uE+l9Vl6d98BXkY8M0bnd+BV78Pjd+GNp9uJSwzQbQo/FFbOI6K6k2s
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A lazy I/O open of a file in LOCK_SYNC gets LAZYIO issued along with
the read caps.  Once the file is closed and its wanted caps lapse,
ceph_check_caps() keeps the shared and read caps of a file that was
not opened for writing, but not LAZYIO, so it sends the MDS a cap
update for every closed file only to give LAZYIO back.  With the
lazyio mount option, io500 mdtest-hard-read sends about one such
message per file read, from about 60 seconds after the reads start,
and the MDS serves the reads more slowly while they arrive.

Keep LAZYIO under the same condition as the read caps.  The MDS still
revokes it together with CACHE when another client needs the file.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/caps.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index 49e5c1c36b68..aca09351a094 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -2266,10 +2266,13 @@ void ceph_check_caps(struct ceph_inode_info *ci, int flags)
 			/*
 			 * keep RD only if we didn't have the file open RW,
 			 * because then the mds would revoke it anyway to
-			 * journal max_size=0.
+			 * journal max_size=0.  Keep LAZYIO with it: a lazy
+			 * I/O open gets it issued in LOCK_SYNC, and giving
+			 * it back costs a cap message per closed file, while
+			 * the MDS revokes it along with CACHE when it must.
 			 */
 			if (ci->i_max_size == 0)
-				retain |= CEPH_CAP_ANY_RD;
+				retain |= CEPH_CAP_ANY_RD | CEPH_CAP_FILE_LAZYIO;
 		}
 	}
 

-- 
2.53.0

