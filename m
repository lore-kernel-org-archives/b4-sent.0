From: Xiubo Li <xiubo.li@clyso.com>
Subject: [PATCH 0/2] ceph: dirty folios left at umount
Date: Mon, 09 Nov 2026 01:27:17 +0100
Message-Id: <20261109-ceph-shutdown-dirty-folios-v1-0-34600e8dab20@clyso.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMOw7DIAwA0KtEnmMJGNKoV6k6JGAXRxVEmPSjK
 Hcvbce3vB2UipDCuduh0ENUcmqwfQc+TulGKKEZnHGDtWZET2tEjVsN+ZkwSKlv5HyXrMh08uw
 4zM4M0IK1EMvrl1+uf+s2L+Trd4Tj+ACF24EUfgAAAA==
X-Change-ID: 20261108-ceph-shutdown-dirty-folios-fe7cf2fdb206
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>, 
 Christian Brauner <brauner@kernel.org>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794184042; l=1539;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=DkStLvIYCGVjAQ5edL4dBSmnuabmcLt1n1rz2B8iYco=;
 b=7uEsb17jqcBxX+vBu72dHD9qkkoj9z4jHlj5shmzZGDT3qCIOHA2tdqpy/h6L2l8Ghm2QM9yY
 AaGh9GIeIyFBExGA0Q8RA1wKYjw72Q5xyOywJaLTkybKCSxRMIwZuTM
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two fixes for dirty folios that umount waits for until mount_timeout,
and that can leave the inode busy, which BUGs in generic_shutdown_super().

Patch 1 takes a folio out of mdsc->dirty_folios wherever it stops being
dirty: ceph_invalidate_folio() and write_folio_nounlock() only put its
snap context and Fb cap ref, so after e.g. a truncate of dirty data
umount waits for the folio until mount_timeout.

Patch 2 drops the dirty folios of an inode when the mount is shut down
and they can no longer be written back.  When the client was evicted,
the caps went before the forced umount, so nothing invalidated the
folios; they kept their Fb cap ref, and with it the inode:

  ceph: ... umount timed out, 0
  VFS: Busy inodes after unmount of ceph (ceph)
  kernel BUG at fs/super.c:731!

Tested with the qa lazy I/O suite (the evicted writer case hit the BUG
on the first run without the fixes, and passes 5/5 with them) and with
fsstress, on a KASAN + lockdep + kmemleak kernel.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
Xiubo Li (2):
      ceph: count a dirty folio out wherever it stops being dirty
      ceph: drop the dirty folios that a shut down mount cannot write back

 fs/ceph/addr.c  | 43 +++++++++++++++++++++++++++++++++----------
 fs/ceph/super.c |  8 ++++++++
 2 files changed, 41 insertions(+), 10 deletions(-)
---
base-commit: 5dcec86cc31f8144857c0d9bf2a7fa13b6e6f531
change-id: 20261108-ceph-shutdown-dirty-folios-fe7cf2fdb206

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

