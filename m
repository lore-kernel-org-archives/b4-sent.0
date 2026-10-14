From: Daejun Park <daejun7.park@samsung.com>
Date: Wed, 14 Oct 2026 13:10:27 +0900
Subject: [PATCH pynfs 2/3] Add tests for LAYOUTCOMMITs of ranges without
 blocks in a block layout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-pynfs-block-commit-v1-2-1723979f495f@samsung.com>
References: <20261014-pynfs-block-commit-v1-0-1723979f495f@samsung.com>
In-Reply-To: <20261014-pynfs-block-commit-v1-0-1723979f495f@samsung.com>
To: Calum Mackay <calum.mackay@oracle.com>
Cc: linux-nfs@vger.kernel.org, Chuck Lever <cel@kernel.org>, 
 Jeff Layton <jlayton@kernel.org>, Christoph Hellwig <hch@lst.de>, 
 Dai Ngo <dai.ngo@oracle.com>, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791951025; l=7745;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=WVFejkVr5yteMDS17OJC7agj1PodBWv4RBiX7EkvTYE=;
 b=U6s7Y89ANtEIKiJ8NEXgIXLCK+D1ntN8ZjwOI4fmGmJ7rh6Nc1UxWrhF4B44a0nfMfrwUElS3
 audiYQHs8/mDKAc7qXtLc1y9K7WvqdmkdiVHH74/WXMR3ALJnsmVjMT
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

BLOCK6 gets an RW layout for the first 64 KiB of a 2 MiB file without
blocks and commits that range. BLOCK7 to BLOCK10 commit ranges that no
layout covered instead: a 64 KiB hole, the laid-out range together with
that hole, a one-block hole, and an extent that starts at the second
block and whose offset + length wraps around 2^64. Per RFC 5663
section 2.3.2, a LAYOUTCOMMIT commits regions that a layout handed out
as PNFS_BLOCK_INVALID_DATA, so the server must refuse those. After
the refused LAYOUTCOMMIT, the tests also check that the server can
still GETATTR the file and that its space used did not grow. The client
writes nothing to the volume.

On Linux, nfsd does not check the committed extents against the layouts
it handed out, and XFS converted whatever range it got. A 64 KiB hole
shut XFS down, a one-block hole got NFS4_OK and a block of whatever the
volume held mapped into the file, and the wrapping extent got
NFS4ERR_IO with a "non-standard errno" warning from nfsd. "xfs: refuse
a pNFS LAYOUTCOMMIT of a range without blocks" and "xfs: clamp a pNFS
LAYOUTCOMMIT extent before computing its end" fix that.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 nfs4.1/server41tests/st_block.py | 136 +++++++++++++++++++++++++++++++++++++++
 1 file changed, 136 insertions(+)

diff --git a/nfs4.1/server41tests/st_block.py b/nfs4.1/server41tests/st_block.py
index 6c30585..36d7652 100644
--- a/nfs4.1/server41tests/st_block.py
+++ b/nfs4.1/server41tests/st_block.py
@@ -303,3 +303,139 @@ def testRWExtentsContiguous(t, env):
        blocks[1][1] != blocks[0][1] + bs or blocks[2][1] != blocks[1][1] + bs:
         t.pass_warn("The three blocks are not contiguous on the volume, "
                     "so there were no extents to merge")
+
+def _commit_setup(t, env):
+    """Make a 2 MiB file without blocks and get an RW layout for its
+    first 64 KiB, which makes the server allocate those blocks.
+
+    Returns the session, the file handle, the layout stateid, the block
+    size and the first extent of the layout.
+    """
+    sess = env.c1.new_pnfs_client_session(env.testname(t))
+    bs = get_blocksize(sess, use_obj(env.opts.path))
+    if 65536 % bs:
+        t.fail_support("Block size %d does not divide 64 KiB" % bs)
+    res = create_file(sess, env.testname(t), access=OPEN4_SHARE_ACCESS_BOTH)
+    check(res)
+    fh = res.resarray[-1].object
+    open_stateid = res.resarray[-2].stateid
+    res = sess.compound([op.putfh(fh),
+                         op.setattr(open_stateid, {FATTR4_SIZE: 2 << 20})])
+    check(res, msg="SETATTR of the size to 2 MiB")
+    res = sess.compound([op.putfh(fh),
+                         op.layoutget(False, LAYOUT4_BLOCK_VOLUME,
+                                      LAYOUTIOMODE4_RW, 0, 65536, bs,
+                                      open_stateid, 0xffff)])
+    check(res, msg="RW LAYOUTGET of the first 64 KiB")
+    layout_stateid = res.resarray[-1].logr_stateid
+    extents = []
+    for layout in res.resarray[-1].logr_layout:
+        p = BlockUnpacker(layout.loc_body)
+        extents += p.unpack_pnfs_block_layout4().blo_extents
+        p.done()
+    if not extents:
+        fail("No extents in the layout")
+    return sess, fh, layout_stateid, bs, extents[0]
+
+def _commit(sess, fh, layout_stateid, vol_id, extents):
+    """LAYOUTCOMMIT the extents, a list of (file offset, length, volume
+    offset), as written"""
+    p = BlockPacker()
+    p.pack_pnfs_block_layoutupdate4(pnfs_block_layoutupdate4(
+        [pnfs_block_extent4(vol_id, foff, length, soff,
+                            PNFS_BLOCK_READWRITE_DATA)
+         for foff, length, soff in extents]))
+    return sess.compound([op.putfh(fh),
+                          op.layoutcommit(0, 2 << 20, False, layout_stateid,
+                                          newoffset4(False),
+                                          newtime4(True, get_nfstime()),
+                                          layoutupdate4(LAYOUT4_BLOCK_VOLUME,
+                                                        p.get_buffer()))])
+
+def _space_used(sess, fh):
+    res = sess.compound([op.putfh(fh), op.getattr(1 << FATTR4_SPACE_USED)])
+    check(res, msg="GETATTR after the LAYOUTCOMMIT")
+    return res.resarray[-1].obj_attributes[FATTR4_SPACE_USED]
+
+def _commit_refused(sess, fh, lo_stateid, vol_id, extents, what):
+    """The LAYOUTCOMMIT must fail, and the server must still be able to
+    GETATTR the file and must not have allocated anything for it"""
+    before = _space_used(sess, fh)
+    res = _commit(sess, fh, lo_stateid, vol_id, extents)
+    if res.status == NFS4_OK:
+        fail("LAYOUTCOMMIT of %s succeeded" % what)
+    after = _space_used(sess, fh)
+    if after > before:
+        fail("Space used grew from %d to %d after the refused LAYOUTCOMMIT "
+             "of %s" % (before, after, what))
+
+def testCommitLaidOut(t, env):
+    """LAYOUTCOMMIT of the range of an RW layout
+
+    FLAGS: block
+    CODE: BLOCK6
+    """
+    sess, fh, lo_stateid, bs, e = _commit_setup(t, env)
+    res = _commit(sess, fh, lo_stateid, e.bex_vol_id,
+                  [(0, 65536, e.bex_storage_offset)])
+    check(res, msg="LAYOUTCOMMIT of the range of the layout")
+
+def testCommitHole(t, env):
+    """LAYOUTCOMMIT of a hole that no layout covered must fail
+
+    Per RFC 5663 section 2.3.2, a LAYOUTCOMMIT commits extents that a
+    layout handed out as PNFS_BLOCK_INVALID_DATA, so there is nothing
+    the client could have written to a hole that it never got a layout
+    for. The client writes nothing to the volume here. After the
+    LAYOUTCOMMIT fails, the server must still be able to GETATTR the
+    file, and its space used must not have grown.
+
+    FLAGS: block
+    CODE: BLOCK7
+    DEPEND: BLOCK6
+    """
+    sess, fh, lo_stateid, bs, e = _commit_setup(t, env)
+    _commit_refused(sess, fh, lo_stateid, e.bex_vol_id,
+                    [(1 << 20, 65536, e.bex_storage_offset)],
+                    "a 64 KiB hole that no layout covered")
+
+def testCommitLaidOutAndHole(t, env):
+    """LAYOUTCOMMIT of the range of an RW layout and a hole must fail
+
+    FLAGS: block
+    CODE: BLOCK8
+    DEPEND: BLOCK6
+    """
+    sess, fh, lo_stateid, bs, e = _commit_setup(t, env)
+    _commit_refused(sess, fh, lo_stateid, e.bex_vol_id,
+                    [(0, 65536, e.bex_storage_offset),
+                     (1 << 20, 65536, e.bex_storage_offset + 65536)],
+                    "the laid out range and a hole that no layout covered")
+
+def testCommitBlockHole(t, env):
+    """LAYOUTCOMMIT of a one-block hole that no layout covered must fail
+
+    FLAGS: block
+    CODE: BLOCK9
+    DEPEND: BLOCK6
+    """
+    sess, fh, lo_stateid, bs, e = _commit_setup(t, env)
+    _commit_refused(sess, fh, lo_stateid, e.bex_vol_id,
+                    [(1 << 20, bs, e.bex_storage_offset)],
+                    "a one-block hole that no layout covered")
+
+def testCommitWrap(t, env):
+    """LAYOUTCOMMIT of an extent whose offset + length wraps must fail
+
+    The extent starts at the second block of the layout and runs past
+    2^64. The server must not treat the length as if it ended below the
+    offset, and the extent covers the hole after the layout.
+
+    FLAGS: block
+    CODE: BLOCK10
+    DEPEND: BLOCK6
+    """
+    sess, fh, lo_stateid, bs, e = _commit_setup(t, env)
+    _commit_refused(sess, fh, lo_stateid, e.bex_vol_id,
+                    [(bs, 2**64 - bs, e.bex_storage_offset)],
+                    "an extent that wraps around 2^64")

-- 
2.43.0

