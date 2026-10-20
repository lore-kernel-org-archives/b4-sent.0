From: Daejun Park <daejun7.park@samsung.com>
Date: Tue, 20 Oct 2026 12:08:48 +0900
Subject: [PATCH v4 5/9] xfs: limit the count of a pNFS write allocation to
 one extent
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-xfs-pnfs-batch-v4-5-9230fa2ca4a4@samsung.com>
References: <20261020-xfs-pnfs-batch-v4-0-9230fa2ca4a4@samsung.com>
In-Reply-To: <20261020-xfs-pnfs-batch-v4-0-9230fa2ca4a4@samsung.com>
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, "Darrick J. Wong" <djwong@kernel.org>, 
 Dave Chinner <dgc@kernel.org>, Chuck Lever <cel@kernel.org>, 
 Jeff Layton <jlayton@kernel.org>, Dai Ngo <Dai.Ngo@oracle.com>, 
 Sergey Bashirov <sergeybashirov@gmail.com>, 
 Andrey Albershteyn <aalbersh@kernel.org>, linux-nfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792465723; l=3759;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=bIokulr9YmNCvihfXF2HXvVG1KbQ9zOS6h+CiqM7w0k=;
 b=s78AkhLG828fo4VOvL4QMljwxBhouOcu4IvrIPAXWM8XOXbyFNICpXUArUQ5R66nAJBzVK4d7
 MrBZqyH+1opBWW70VuqFGwmUwmbPQ0/r+OulyNAhKXyH2UddRBqRaOd
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xfs_fs_map_blocks() asks xfs_iomap_write_direct() to allocate from the
start of a hole to the end of the range of a LAYOUTGET, which a client
chooses, or to the end of the hole if the range ends before EOF.
xfs_iomap_write_direct() reserves blocks for that whole count, in an
unsigned int, but xfs_bmapi_write() maps at most XFS_MAX_BMBT_EXTLEN
blocks in one mapping. A count of about 2^32 blocks or more wraps the
reservation. If it wraps to a few blocks, the allocation uses more
blocks than the transaction reserved, and xfs_trans_mod_sb() shuts the
filesystem down. With 4 KiB blocks, an RW LAYOUTGET at offset 0 of an
empty file for 16 TiB does it.

Direct I/O, DAX and buffered writes with an extent size hint never ask
for that much, as xfs_direct_write_iomap_begin() limits them to 1024
pages to keep the count below 32 bits. Limit a pNFS allocation to
XFS_MAX_BMBT_EXTLEN blocks, as xfs_alloc_file_space() limits each of
its reservations for the same reason. This shrinks the reservation; the
mapping that xfs_bmapi_write() returns stays the same. nfsd asks again
for the rest of the range since commit cc6c40e09d7b ("NFSD/blocklayout:
Support multiple extents per LAYOUTGET"), while the reply has room for
another extent; before that, the layout ends with the extent and the
client asks again.

An RW LAYOUTGET for more than the free space used to fail with
NFS4ERR_NOSPC before anything was allocated, as the first call that
allocates tried to reserve blocks for all of it. Where nfsd maps one
extent per LAYOUTGET, it now gets the first extent. Where nfsd asks
again, it allocates one extent after the other: if the reply fills up
first (at most 92 extents with 4 KiB pages), the client gets those
extents, and if fewer than XFS_MAX_BMBT_EXTLEN blocks are free first,
nfsd fails the LAYOUTGET. The blocks it allocated stay past EOF, as
the inode is marked preallocated; xfs_alloc_file_space() likewise
keeps what it allocated when it runs out of space.

With pynfs as the client and a 32 GiB XFS, an RW LAYOUTGET at offset 0
of an empty file for 16 TiB shut the filesystem down: "Corruption of
in-memory data (0x8) detected at xfs_trans_mod_sb". With this patch it
gets NFS4ERR_NOSPC, also with XFS_DEBUG, XFS keeps running, and less
than 8 GiB of the filesystem, one extent's worth, is left free. One
for 100 GiB ends the same way, where it got NFS4ERR_NOSPC with nothing
allocated before. One for 16 GiB, which fits, is granted the same
three extents as before.

Suggested-by: Darrick J. Wong <djwong@kernel.org>
Link: https://lore.kernel.org/r/20261008154017.GO2705364@frogsfrogsfrogs
Suggested-by: Christoph Hellwig <hch@lst.de>
Link: https://lore.kernel.org/r/20261015060932.GD14035@lst.de
Fixes: 527851124d10 ("xfs: implement pNFS export operations")
Cc: stable@vger.kernel.org
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/xfs/xfs_pnfs.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/fs/xfs/xfs_pnfs.c b/fs/xfs/xfs_pnfs.c
index 19eb18e129..401a790299 100644
--- a/fs/xfs/xfs_pnfs.c
+++ b/fs/xfs/xfs_pnfs.c
@@ -224,6 +224,14 @@ xfs_fs_map_blocks(
 		else if (nimaps && imap.br_startblock == HOLESTARTBLOCK)
 			end_fsb = min(end_fsb, imap.br_startoff +
 					       imap.br_blockcount);
+		/*
+		 * xfs_bmapi_write() maps at most XFS_MAX_BMBT_EXTLEN blocks
+		 * in one mapping, so don't reserve blocks for more. The
+		 * range comes from a client, and its block count may not
+		 * even fit the 32-bit reservation. The rest of the range
+		 * is mapped by a later call.
+		 */
+		end_fsb = min(end_fsb, offset_fsb + XFS_MAX_BMBT_EXTLEN);
 		xfs_iunlock(ip, lock_flags);
 
 		error = xfs_iomap_write_direct(ip, offset_fsb,

-- 
2.43.0

