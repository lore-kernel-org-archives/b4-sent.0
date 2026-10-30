From: Daejun Park <daejun7.park@samsung.com>
Date: Fri, 30 Oct 2026 13:06:19 +0900
Subject: [PATCH pynfs] BLOCK3: send an empty extent list in the second
 LAYOUTCOMMIT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-pynfs-block-empty-commit-v1-1-a1dcc3473ac1@samsung.com>
X-B4-Tracking: v=1; b=H4sIALoX5GoC/x3MSQqEMBBA0atIrbtASxyv0rjQWGrRnYFExCDe3
 eDyL96/ILAXDtBnF3g+JIg1KYpPBmobzcooc2qgnOoipw5dNEvA6W/VD1m7PaKyWsuOzdy0JU3
 VSFRB4s7zIue7/sKrYLjvB9yJxclxAAAA
To: Calum Mackay <calum.mackay@oracle.com>
Cc: linux-nfs@vger.kernel.org, Chuck Lever <cel@kernel.org>, 
 Jeff Layton <jlayton@kernel.org>, Christoph Hellwig <hch@lst.de>, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793333178; l=1862;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=HzkblooUr65z9Ok3LlhdDkT+TzEVEd2JnZC43XXWaos=;
 b=7alkc8rE+OY9hqxCuyFtqq8z9HIYa6If7Vedb3OK1vsdfY2wGAq1ET5Id+Hk68fpgyYTGKm0J
 lzPsfxhOQgHBiodrADuN9I7lTnmgpQpnBODZhYND/df3NgIpijrC/Xt
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Under Python 3, BLOCK3 fails on every server with a TypeError: its
second LAYOUTCOMMIT passes the str "" as the layout body. Send an
empty pnfs_block_layoutupdate4 (RFC 5663, section 2.3.2) instead.
It holds an extent count of zero.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
With b"" (the zero-length body BLOCK3 was written to send), nfsd
answers NFS4ERR_BADXDR. With this patch, BLOCK3 passes on Linux
nfsd over XFS (mainline 65ba8f34ec88).
---
 nfs4.1/server41tests/st_block.py | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/nfs4.1/server41tests/st_block.py b/nfs4.1/server41tests/st_block.py
index 3cfc1c6..d43b7d5 100644
--- a/nfs4.1/server41tests/st_block.py
+++ b/nfs4.1/server41tests/st_block.py
@@ -158,7 +158,9 @@ def testEmptyCommit(t, env):
                            layoutupdate4(LAYOUT4_BLOCK_VOLUME, p.get_buffer()))]
     res = sess.compound(ops)
     check(res)
-    # Send another LAYOUTCOMMIT, with an empty opaque
+    # Send another LAYOUTCOMMIT, with an empty extent list
+    p = BlockPacker()
+    p.pack_pnfs_block_layoutupdate4(pnfs_block_layoutupdate4([]))
     time = newtime4(True, get_nfstime())
     ops = [op.putfh(fh),
            op.layoutcommit(extent.bex_file_offset,
@@ -166,7 +168,7 @@ def testEmptyCommit(t, env):
                            False, lo_stateid2,
                            newoffset4(True, 2 * 8192 - 1),
                            time,
-                           layoutupdate4(LAYOUT4_BLOCK_VOLUME, ""))]
+                           layoutupdate4(LAYOUT4_BLOCK_VOLUME, p.get_buffer()))]
     res = sess.compound(ops)
     check(res)
 

---
base-commit: cd4701827a8261fedbfb4c6e39029fb9671321a6
change-id: 20261029-pynfs-block-empty-commit-7d7832b5a225

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

