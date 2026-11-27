From: Xiubo Li <xiubo.li@clyso.com>
Date: Fri, 27 Nov 2026 05:34:38 +0100
Subject: [PATCH 1/2] ceph: tell the MDS when a closed file no longer wants
 Fr or Fw
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261127-ceph-drop-stale-wanted-v1-1-763882859c5f@clyso.com>
References: <20261127-ceph-drop-stale-wanted-v1-0-763882859c5f@clyso.com>
In-Reply-To: <20261127-ceph-drop-stale-wanted-v1-0-763882859c5f@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, 
 =?utf-8?q?PATRICK_B=C3=89GOU?= <patrick.begou@univ-grenoble-alpes.fr>, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795754083; l=3161;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=pffS/mCkZJh6WEF7XHRVXxBboLfbNbLy63vgUyCni1U=;
 b=alo+dUHgRrOS5eTXfRsfrcUDJUXRjDegf4XMdgQuFH4qMkEdtJtj1icVFCYn7qVnxUQUx5TH0
 8TlVKHRe+H2AvjoDyUYLtCTzQ3VpDlJOI5jteQT7eHb+ZUtk0rN4COW
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ceph_check_caps() skips a cap whose issued caps are all ones we retain.
Since commit fdac94fab799 ("ceph: skip updating 'wanted' caps if caps
are already issued") this holds even when the MDS still has a 'wanted'
mask we dropped long ago.  After a file opened for reading is closed,
we may keep the inode with only Fr and shared caps issued, and then
never tell the MDS that we no longer want Fr.

The MDS counts every client wanting Fr or a write cap as a user of the
file.  If another client keeps the file open for writing, no loner is
chosen and the filelock stays in MIX for as long as we keep the inode
cached.  The writer has no Fb, so every write() goes to the OSDs
synchronously.  A single "tail" of a log file from a second mount made
the writer of that file over 1000 times slower until the reader
dropped its caches.

Send the cap message when the MDS still has Fr or a write cap in the
'wanted' mask of a regular file that we no longer want.  Reopening an
inode whose caps are still issued tells the MDS nothing, as before, so
this does not bring back the two messages the commit above avoided.

The closed file is only checked again at caps_wanted_delay_max, so the
writer gets Fb back about 60 s after the "tail".  Two noshare mounts
on one VM, 1 MDS, 3 OSDs, 64 byte writes on mount A, one "tail" of the
file on mount B:

  +--------+---------------+-----------------------------------+
  |        | before "tail" | after "tail"                      |
  | kernel | ops/s         | ops/s                             |
  +--------+---------------+-----------------------------------+
  | before | ~120,000      | ~85, as long as the test ran      |
  | after  | ~120,000      | ~110,000, from 60 s after "tail"  |
  +--------+---------------+-----------------------------------+

Fixes: fdac94fab799 ("ceph: skip updating 'wanted' caps if caps are already issued")
Cc: stable@vger.kernel.org
Reported-by: PATRICK BÉGOU <patrick.begou@univ-grenoble-alpes.fr>
Link: https://tracker.ceph.com/issues/83627
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/caps.c | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index cc8748f7e0bd..add63a8f6212 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -2418,6 +2418,21 @@ void ceph_check_caps(struct ceph_inode_info *ci, int flags)
 				goto ack;
 		}
 
+		/*
+		 * Does the mds still think we want to read or write a
+		 * file that is no longer open here?  It counts every
+		 * client wanting Fr or a write cap as a user of the
+		 * file, so it keeps the filelock in MIX and no other
+		 * client gets Fb or Fc back.  The caps we hold may all
+		 * be ones we retain, so tell it now.  This only fires
+		 * for bits the mds was told about, so reopening an
+		 * inode whose caps are still issued sends no update.
+		 */
+		if (!S_ISDIR(inode->i_mode) &&
+		    (cap->mds_wanted & ~want &
+		     (CEPH_CAP_ANY_WR | CEPH_CAP_FILE_RD)))
+			goto ack;
+
 		/* things we might delay */
 		if ((cap->issued & ~retain) == 0)
 			continue;     /* nope, all good */

-- 
2.53.0

