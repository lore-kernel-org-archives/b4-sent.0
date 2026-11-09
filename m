From: Xiubo Li <xiubo.li@clyso.com>
Date: Mon, 09 Nov 2026 01:28:15 +0100
Subject: [PATCH] ceph: write back a cap snap's dirty pages as soon as it is
 finished
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-ceph-capsnap-writeback-v1-1-d2130bce504b@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQrCMBBA4auUWTuQBCLVqxQXk+nYjkIMmfoDp
 Xc31uW3eG8Fk6picO5WqPJS00du8IcOeKY8CerYDMGFo/euR5YyI1OxTAXfVRdJxHeMXig4N8Y
 UT9DiUuWqn308XP62Z7oJL78bbNsXODSi5noAAAA=
X-Change-ID: 20261108-ceph-capsnap-writeback-51ea200d5b59
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>, 
 Milind Changire <mchangir@redhat.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794184095; l=2794;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=R6XqZSxdVxydzDKnNp2ga3kcSz7zsahaBCcIEPSGDXQ=;
 b=VF1dnMWpYunG/+eQ1Ei5JrkO5cng3HsIWMoEYlJ8MoweHver5KuMGGStsKwC2YX1zckKdL61+
 5ZP1XxWV6/fDr8m5KSHLjNPTTmdCnNImUiOj0YpGiEZ371XwNwfcX1V
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a snapshot is taken while an inode has dirty pages, the pages
move to a cap snap, which can only be flushed to the MDS once they have
been written back.  __ceph_finish_cap_snap() starts writeback at once
when the cap snap has no dirty pages of its own but the inode still has
some, but when the cap snap has some it starts nothing: its pages wait
for periodic writeback, up to dirty_expire_centisecs, or for the next
write to one of them.  ceph-fuse flushes the buffered data at once in
both cases.

With lazy I/O that loses data from the snapshot.  Several clients
buffer writes to one file then, and when another one writes to the
same object with the new snap context first, the OSD clones the object
for the snapshot on that write; what this client writes with the old
snap context after it goes to the head only.  With two lazy writers
that each dirty a page, take a snapshot and write again, the snapshot
had zeros instead of the first client's data whenever the second
client's new write reached the OSD first, as the OSD op history shows:

  client.4157.0:4 [write 4096~2000] snapc 2=[2]
  client.4156.0:3 [write 0~2000] snapc 1=[]

Start writeback of the cap snap's pages at once, too, as ceph-fuse does.
This also gets the cap snap to the MDS sooner without lazy I/O.

Fixes: 2d12ad950b0c ("ceph: trigger to flush the buffer when making snapshot")
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
When a snapshot is taken while an inode has dirty pages, the kernel
client leaves the cap snap's pages for periodic writeback, while
ceph-fuse flushes them at once.  With lazy I/O another client may write
to the same objects with the new snap context first, and what this
client writes with the old one afterwards misses the snapshot.
---
 fs/ceph/snap.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/fs/ceph/snap.c b/fs/ceph/snap.c
index f59b83a97d52..e44378b07fd3 100644
--- a/fs/ceph/snap.c
+++ b/fs/ceph/snap.c
@@ -683,6 +683,15 @@ int __ceph_finish_cap_snap(struct ceph_inode_info *ci,
 		      capsnap->context->seq,
 		      ceph_cap_string(capsnap->dirty),
 		      capsnap->size, capsnap->dirty_pages);
+		/*
+		 * Write them back now, not when writeback or the next
+		 * write to them gets to it: they belong to the snapshot,
+		 * and with lazy I/O another client may already write to
+		 * the same objects with the new snap context.  Its first
+		 * write clones the objects for the snapshot, and what we
+		 * write with the old one after that misses the snapshot.
+		 */
+		ceph_queue_writeback(inode);
 		return 0;
 	}
 

---
base-commit: 5dcec86cc31f8144857c0d9bf2a7fa13b6e6f531
change-id: 20261108-ceph-capsnap-writeback-51ea200d5b59

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

