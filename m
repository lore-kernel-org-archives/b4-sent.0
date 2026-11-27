From: Xiubo Li <xiubo.li@clyso.com>
Date: Fri, 27 Nov 2026 05:34:39 +0100
Subject: [PATCH 2/2] ceph: check the caps of a closed file the MDS thinks
 we read sooner
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261127-ceph-drop-stale-wanted-v1-2-763882859c5f@clyso.com>
References: <20261127-ceph-drop-stale-wanted-v1-0-763882859c5f@clyso.com>
In-Reply-To: <20261127-ceph-drop-stale-wanted-v1-0-763882859c5f@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?PATRICK_B=C3=89GOU?= <patrick.begou@univ-grenoble-alpes.fr>, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795754083; l=2555;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=kTwNLo7MYDuLOGtN7iAIiJVkQ9HNzoSGkjITAYSGCyE=;
 b=Ei9rBDZ2zIcVyeH//4kd3096Wpz0OHGUNMBkuWGrHyyESqnWRoPVbTBeamdDlOGGmp9a6BTQ5
 fM8XWqA3AMND6p/TiSmoXRAYhVdpUWh0KahYpQ3/XkFfp1Iso+QwRLG
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A file closed after reading is checked again at caps_wanted_delay_max
only: the earlier check at caps_wanted_delay_min is for files that
hold write caps.  Until then the MDS still has Fr in our 'wanted'
mask, so if another client is writing the file, the filelock stays
in MIX and that writer has no Fb for up to 60 s after a single "tail"
of the file here.

Queue a closed regular file for the check at caps_wanted_delay_min
also when the MDS has Fr or a write cap in the 'wanted' mask of one of
its caps.  The check then sends the one cap message that tells the MDS
we no longer want them; it would send the same message at
caps_wanted_delay_max anyway.  A file opened without asking the MDS
(caps already issued) is not affected.

Same test as in the previous patch:

  +--------------+---------------+----------------------------------+
  |              | before "tail" | after "tail"                     |
  | kernel       | ops/s         | ops/s                            |
  +--------------+---------------+----------------------------------+
  | before       | ~120,000      | ~85, as long as the test ran     |
  | patch 1      | ~120,000      | ~110,000, from 60 s after "tail" |
  | patch 1 + 2  | ~115,000      | ~120,000, from 10 s after "tail" |
  +--------------+---------------+----------------------------------+

Reported-by: PATRICK BÉGOU <patrick.begou@univ-grenoble-alpes.fr>
Link: https://tracker.ceph.com/issues/83627
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/caps.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index add63a8f6212..2a6c21d8b7af 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -5261,9 +5261,15 @@ void ceph_put_fmode(struct ceph_inode_info *ci, int fmode, int count)
 		 * the exclusive caps from us first when another client
 		 * looks at the file, e.g. stats a file we just created.
 		 * Check again after caps_wanted_delay_min instead.
+		 *
+		 * The same goes for a file the MDS still thinks we want to
+		 * read: it keeps the filelock in MIX, and a writer on
+		 * another client has no Fb, until we tell it we don't.
 		 */
 		if (S_ISREG(ci->netfs.inode.i_mode) &&
-		    (__ceph_caps_issued(ci, NULL) & CEPH_CAP_ANY_WR))
+		    ((__ceph_caps_issued(ci, NULL) & CEPH_CAP_ANY_WR) ||
+		     (__ceph_caps_mds_wanted(ci, false) &
+		      (CEPH_CAP_ANY_WR | CEPH_CAP_FILE_RD))))
 			__cap_delay_requeue_idle(mdsc, ci);
 	}
 	spin_unlock(&ci->i_ceph_lock);

-- 
2.53.0

