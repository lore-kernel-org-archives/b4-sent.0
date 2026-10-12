From: Daejun Park <daejun7.park@samsung.com>
Date: Mon, 12 Oct 2026 13:40:37 +0900
Subject: [PATCH] nfsd: do not allocate blocks for an RW layout with a
 minlength of zero
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261012-nfsd-block-minlength0-v1-1-4b8a9445619e@samsung.com>
X-B4-Tracking: v=1; b=H4sIAMRkzGoC/x3MQQqEMAxA0atI1hNIq6jjVQYXtUYNOlFaEUG8u
 8XlW/x/QeQgHKHJLgh8SJRVE8wnAz85HRmlTwZLtjREX9Qh9tgtq5/xL7qwjvtESLkpXFVb37k
 cUrsFHuR8v7/2vh9tiqlJZwAAAA==
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>, 
 Christoph Hellwig <hch@lst.de>
Cc: "Darrick J. Wong" <djwong@kernel.org>, Carlos Maiolino <cem@kernel.org>, 
 Sergey Bashirov <sergeybashirov@gmail.com>, linux-nfs@vger.kernel.org, 
 linux-xfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791780036; l=4421;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=AxJFt7SCKtciklmWlX18k37cLIKLzkvlN3bezyFY75M=;
 b=JPvVt57XgPOQF7oJ2fkeDOaSRtqoO15Q8YjjiWrqKL5ZEoNK/XStSskkOGFy1g0xfiGaWYs4C
 EzmQz8n+vN0AQ66FZKqlWtOlv0hJm56DBQWZ21g+FgkwIa6OdDxiXAi
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

RFC 5663 section 2.3.1 says that for a LAYOUTGET with a loga_minlength
of zero, a writable layout is readily available only if its extents can
be returned in the READ_WRITE_DATA state. nfsd4_block_map_extent()
follows it by refusing an RW layout with a minlength of zero on an
unwritten extent, with NFS4ERR_LAYOUTUNAVAILABLE.

But it asks ->map_blocks for a write mapping before it looks at the
minlength. For a hole, XFS allocates blocks, updates the inode and forces
the log, and the mapping it returns is unwritten, so the layout is
refused. The client gets no layout, and the blocks stay allocated: XFS
marks the inode XFS_DIFLAG_PREALLOC for them, so xfs_free_eofblocks()
does not free them past EOF either. This is possible since commit
8c3ad9cb7343 ("nfsd/blocklayout: accept any minlength"), which removed
the check that refused a minlength below the block size before
->map_blocks was called.

Ask for a write mapping only when the minlength is not zero, and refuse
a hole in an RW layout with a minlength of zero, as an unwritten extent
is refused. The client gets the same answer, and nothing is allocated.
Written extents are still granted as READ_WRITE_DATA.

With pynfs as the client, an RW LAYOUTGET for 0+1 MiB with a minlength
of zero got NFS4ERR_LAYOUTUNAVAILABLE and left 1 MiB allocated on an
empty file, and 960 KiB allocated past the first 64 KiB on a file whose
first 64 KiB were written. With this patch both get the same error and
nothing is allocated. An RW LAYOUTGET with a minlength of zero for the
64 KiB that were written, and one with a minlength of 4 KiB on an empty
file, are granted as before.

The Linux client does not send an RW LAYOUTGET with a minlength of zero
(pnfs_alloc_init_layoutget_args()), so it is not affected.

Fixes: 8c3ad9cb7343 ("nfsd/blocklayout: accept any minlength")
Suggested-by: Chuck Lever <cel@kernel.org>
Link: https://lore.kernel.org/r/235ae19b-fd63-4d01-9fe0-d047a33b55ed@slotpi15m67
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Tested on nfsd-testing (d918c664efd5) with KASAN and lockdep, XFS on an
NVMe/TCP namespace shared by the server and the client:

- pynfs block and blockextent tests, and the LAYOUTGETs above (a local
  test, not posted), 1 run without and 2 with this patch: the same
  results apart from the allocations above. BLOCK3 fails with
  NFS4ERR_BADXDR for its empty layoutupdate with and without this patch.
  The same on the earlier heads f27ad2d54411 and 3af417ce0f30, which
  differ only in fs/nfsd/nfsctl.c and net/sunrpc/svcsock.c.
- fstests generic/075, 091 and 263 with the Linux client over the block
  layout, on 3af417ce0f30: only 075 fails, as without this patch.

This is meant to go in before the ->map_blocks series, which will take
the same change into nfsd4_block_proc_layoutget():
https://lore.kernel.org/r/235ae19b-fd63-4d01-9fe0-d047a33b55ed@slotpi15m67
---
 fs/nfsd/blocklayout.c | 12 +++++++++++-
 1 file changed, 11 insertions(+), 1 deletion(-)

diff --git a/fs/nfsd/blocklayout.c b/fs/nfsd/blocklayout.c
index 6fefcb2072..b3bb2831cf 100644
--- a/fs/nfsd/blocklayout.c
+++ b/fs/nfsd/blocklayout.c
@@ -31,10 +31,17 @@ nfsd4_block_map_extent(struct inode *inode, const struct svc_fh *fhp,
 	struct super_block *sb = inode->i_sb;
 	struct iomap iomap;
 	u32 device_generation = 0;
+	bool write;
 	int error;
 
+	/*
+	 * An RW layout with a minlength of zero only gets extents that can
+	 * be returned as READ_WRITE_DATA (RFC 5663, section 2.3.1), so do
+	 * not have the filesystem allocate blocks that would be refused.
+	 */
+	write = iomode != IOMODE_READ && minlength != 0;
 	error = sb->s_export_op->block_ops->map_blocks(inode, offset, length,
-			&iomap, iomode != IOMODE_READ, &device_generation);
+			&iomap, write, &device_generation);
 	if (error) {
 		if (error == -ENXIO)
 			return nfserr_layoutunavailable;
@@ -76,6 +83,9 @@ nfsd4_block_map_extent(struct inode *inode, const struct svc_fh *fhp,
 			bex->es = PNFS_BLOCK_NONE_DATA;
 			break;
 		}
+		/* Not allocated for a minlength of zero, see above. */
+		if (minlength == 0)
+			return nfserr_layoutunavailable;
 		fallthrough;
 	case IOMAP_DELALLOC:
 	default:

---
base-commit: d918c664efd5ec6a7309e98f567fb018bcde0e11
change-id: 20261009-nfsd-block-minlength0-0314a782cba3

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

