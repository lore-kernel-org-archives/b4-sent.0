From: Daejun Park <daejun7.park@samsung.com>
Date: Wed, 14 Oct 2026 13:10:26 +0900
Subject: [PATCH pynfs 1/3] Add a test for contiguous writable extents in a
 block layout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-pynfs-block-commit-v1-1-1723979f495f@samsung.com>
References: <20261014-pynfs-block-commit-v1-0-1723979f495f@samsung.com>
In-Reply-To: <20261014-pynfs-block-commit-v1-0-1723979f495f@samsung.com>
To: Calum Mackay <calum.mackay@oracle.com>
Cc: linux-nfs@vger.kernel.org, Chuck Lever <cel@kernel.org>, 
 Jeff Layton <jlayton@kernel.org>, Christoph Hellwig <hch@lst.de>, 
 Dai Ngo <dai.ngo@oracle.com>, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791951025; l=7175;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=O0mTH+U+0HDOqsC8sbaXehAPEfoyBixGIdtM/QO1Pxw=;
 b=EBX9otnUsDhLs3LLuNTWhQtm3es7YxQNueiu6A56ZkduQBtj7EVPVhLHrXZRMM4hepX6OnPar
 0CHaYmTTOPCAdmXKE1WdfKn3ArBlVolFOur4w29ImiIzvY1kWEL+F4B
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

BLOCK5: a LAYOUTIOMODE4_RW LAYOUTGET over a hole between two allocated
blocks, where the server allocates the hole, gets extents that follow
three of the rules in RFC 5663 section 2.3.1: the extents are ordered by
offset, the writable extents (all but PNFS_BLOCK_READ_DATA) are
logically contiguous, and the first extent contains the requested offset
(so the extent list is not empty).  A server that maps each extent in
full can return the extent that the allocation merges with the ones
before it, overlapping them.

The test allocates three blocks of the layout block size
(FATTR4_LAYOUT_BLKSIZE) and deallocates the middle one, so that the
block the server allocates for the hole is likely to be that one and to
merge with both neighbours.  It warns if the layout does not cover the
three blocks or they are not contiguous on the volume, as then no merge
could be seen.  On Linux nfsd over XFS the freed block can be reused at
once on a sync export, where DEALLOCATE commits.  The minimum length is
one block, so that a server that returns one extent per LAYOUTGET does
not have to refuse the request.  Every layout in the reply is checked.
The test uses ALLOCATE and DEALLOCATE, so it needs NFSv4.2, and a server
without them does not support the test.

Linux nfsd over XFS fails BLOCK5 in five runs out of five on a test
kernel that maps with XFS_BMAPI_ENTIRE in xfs_fs_map_blocks() and does
not trim, which kernel commit 36ca6f11424a ("xfs: fix overlapping
extents returned for pNFS LAYOUTGET") stopped in 7.1.  nfsd-testing on
top of 7.3-rc4 passes it in five runs out of five, with and without
"xfs: map pNFS layouts to the end of the extent again".

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 nfs4.1/server41tests/st_block.py | 94 ++++++++++++++++++++++++++++++++++++++--
 1 file changed, 91 insertions(+), 3 deletions(-)

diff --git a/nfs4.1/server41tests/st_block.py b/nfs4.1/server41tests/st_block.py
index 3cfc1c6..6c30585 100644
--- a/nfs4.1/server41tests/st_block.py
+++ b/nfs4.1/server41tests/st_block.py
@@ -2,10 +2,11 @@ from xdrdef.nfs4_const import *
 from xdrdef.nfs4_type import *
 import nfs_ops
 op = nfs_ops.NFS4ops()
-from .environment import check, fail, create_file
+from .environment import check, fail, create_file, use_obj, \
+    get_blocksize
 from block import Packer as BlockPacker, Unpacker as BlockUnpacker, \
-    PNFS_BLOCK_READWRITE_DATA, pnfs_block_layoutupdate4, \
-    pnfs_block_extent4
+    PNFS_BLOCK_READWRITE_DATA, PNFS_BLOCK_READ_DATA, \
+    pnfs_block_layoutupdate4, pnfs_block_extent4
 from nfs4lib import FancyNFS4Packer, get_nfstime
 
 
@@ -215,3 +216,90 @@ def testSplitCommit(t, env):
                            layoutupdate4(LAYOUT4_BLOCK_VOLUME, p.get_buffer()))]
     res = sess.compound(ops)
     check(res)
+
+def testRWExtentsContiguous(t, env):
+    """RW layout over a hole between allocated blocks has contiguous extents
+
+    The server allocates the hole for the layout.  Check three of the
+    rules in RFC 5663 section 2.3.1: the extents are ordered by offset,
+    the writable extents (all but PNFS_BLOCK_READ_DATA) are logically
+    contiguous, and the first extent contains the requested offset.  A
+    server that maps each extent in full can return the extent that the
+    allocation merges with the ones before it, overlapping them.  The
+    minimum length is one block, so that a server that returns one
+    extent per LAYOUTGET does not have to refuse the request.  Warn if
+    the layout does not cover the three blocks or they are not contiguous
+    on the volume, as then no merge could be seen.
+
+    FLAGS: block
+    CODE: BLOCK5
+    VERS: 2-
+    """
+    sess = env.c1.new_pnfs_client_session(env.testname(t))
+    bs = get_blocksize(sess, use_obj(env.opts.path))
+    res = create_file(sess, env.testname(t))
+    check(res)
+    fh = res.resarray[-1].object
+    open_stateid = res.resarray[-2].stateid
+    # Allocate three blocks, then deallocate the middle one: the block
+    # the server allocates for the hole is likely to be that one, and to
+    # merge with both neighbours.  (On Linux nfsd over XFS the freed block
+    # can be reused at once on a sync export, where DEALLOCATE commits.)
+    res = sess.compound([op.putfh(fh), op.allocate(open_stateid, 0, 3*bs)])
+    if res.status == NFS4ERR_NOTSUPP:
+        t.fail_support("ALLOCATE is not supported")
+    check(res)
+    res = sess.compound([op.putfh(fh), op.deallocate(open_stateid, bs, bs)])
+    if res.status == NFS4ERR_NOTSUPP:
+        t.fail_support("DEALLOCATE is not supported")
+    check(res)
+    ops = [op.putfh(fh),
+           op.layoutget(False, LAYOUT4_BLOCK_VOLUME, LAYOUTIOMODE4_RW,
+                        0, 3*bs, bs, open_stateid, 0xffff)]
+    res = sess.compound(ops)
+    check(res)
+    found = False
+    blocks = {}
+    for layout in res.resarray[-1].logr_layout:
+        p = BlockUnpacker(layout.loc_body)
+        opaque = p.unpack_pnfs_block_layout4()
+        p.done()
+        ext = [(e.bex_file_offset, e.bex_length, e.bex_state)
+               for e in opaque.blo_extents]
+        print(layout.lo_offset, layout.lo_length, ext,
+              [e.bex_storage_offset for e in opaque.blo_extents])
+        if not ext:
+            fail("No extents in layout %d+%d" %
+                 (layout.lo_offset, layout.lo_length))
+        for a, b in zip(ext, ext[1:]):
+            if b[0] < a[0] or (b[0] == a[0] and
+                               a[2] != PNFS_BLOCK_READ_DATA and
+                               b[2] == PNFS_BLOCK_READ_DATA):
+                fail("Extents %s and %s are not in order" % (a, b))
+        writable = [e for e in ext if e[2] != PNFS_BLOCK_READ_DATA]
+        for a, b in zip(writable, writable[1:]):
+            if b[0] != a[0] + a[1]:
+                fail("Writable extents %s and %s are not logically "
+                     "contiguous" % (a, b))
+        if layout.lo_offset <= 0 < layout.lo_offset + layout.lo_length:
+            found = True
+            if not ext[0][0] <= 0 < ext[0][0] + ext[0][1]:
+                fail("First extent %s does not contain offset 0" %
+                     (ext[0],))
+        for e in opaque.blo_extents:
+            if e.bex_state == PNFS_BLOCK_READ_DATA:
+                continue
+            off = e.bex_file_offset
+            for i in range(3):
+                if off <= i*bs < off + e.bex_length:
+                    blocks[i] = (e.bex_vol_id,
+                                 e.bex_storage_offset + i*bs - off)
+    if not found:
+        fail("No layout contains offset 0")
+    if len(blocks) < 3:
+        t.pass_warn("The layout does not cover all three blocks, so a "
+                    "merge could not be seen")
+    if blocks[0][0] != blocks[1][0] or blocks[1][0] != blocks[2][0] or \
+       blocks[1][1] != blocks[0][1] + bs or blocks[2][1] != blocks[1][1] + bs:
+        t.pass_warn("The three blocks are not contiguous on the volume, "
+                    "so there were no extents to merge")

-- 
2.43.0

