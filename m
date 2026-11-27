From: Xiubo Li <xiubo.li@clyso.com>
Subject: [PATCH 0/2] ceph: tell the MDS when a closed file no longer wants
 Fr or Fw
Date: Fri, 27 Nov 2026 05:34:37 +0100
Message-Id: <20261127-ceph-drop-stale-wanted-v1-0-763882859c5f@clyso.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCMBBG4auUWTvQxGKLVxEXafJrRyQNmaiF0
 rs36vJbvLeSIguUzs1KGW9RmWOFOTTkJxfvYAnVZFt7Msb27JEmDnlOrMU9wR8XCwJ3nRt9i+H
 Y24FqnDJusvzGl+vf+hof8OV7o23bAS7Z8N16AAAA
X-Change-ID: 20261127-ceph-drop-stale-wanted-44abc0e83728
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, 
 =?utf-8?q?PATRICK_B=C3=89GOU?= <patrick.begou@univ-grenoble-alpes.fr>, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795754083; l=1836;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=VHzb9ucE/pcleIt29IQpj4E990WPVnr2Hv/I0H5tNQU=;
 b=Skdr36wzJ2bP/RlBqANnT9or3k4xlUlkhf93YKc8H8PXvkXpIxi7jxxEV06ykgdruOcr/5QDv
 mZ5zhkANx9YDwAm2pD5MNyoZpkCFZBY3G/aGJiYZfoLItckPYhEdCQk
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A single "tail" of a log file from one client can make the writer of
that file on another client over 1000 times slower, for as long as the
reader keeps the inode cached.  This was reported on ceph-users: a
simulation that runs in 38 s took about 15 minutes after one "tail" of
its log from the cluster front end.

After a file opened for reading is closed, we often keep the inode with
only Fr and shared caps issued.  These are all caps we retain, and since
commit fdac94fab799 ("ceph: skip updating 'wanted' caps if caps are
already issued") nothing tells the MDS that we no longer want Fr.  The
MDS counts us as a user of the file, chooses no loner, and keeps the
filelock in MIX; the writer has no Fb and every write() goes to the
OSDs synchronously.  Nothing in MIX revokes our Fr, so it never ends
until the inode is dropped.

Patch 1 sends the cap message when the MDS still has Fr or a write cap
in the 'wanted' mask of a regular file we no longer want.  Patch 2
checks such a closed file at caps_wanted_delay_min, like a closed file
holding write caps, instead of at caps_wanted_delay_max.  The writer
is back to full speed 60 s after the "tail" with patch 1, and about
10 s after it with both.

The same bug is in libcephfs; its fix and a qa test that fails on both
clients without the fixes are in a ceph pull request.

Link: https://tracker.ceph.com/issues/83627
---
Xiubo Li (2):
      ceph: tell the MDS when a closed file no longer wants Fr or Fw
      ceph: check the caps of a closed file the MDS thinks we read sooner

 fs/ceph/caps.c | 23 ++++++++++++++++++++++-
 1 file changed, 22 insertions(+), 1 deletion(-)
---
base-commit: 3f90412e989cb381d4bf96260468f5c7b2d08655
change-id: 20261127-ceph-drop-stale-wanted-44abc0e83728

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

