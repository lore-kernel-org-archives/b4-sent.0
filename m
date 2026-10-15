From: Daejun Park <daejun7.park@samsung.com>
Subject: [PATCH v3 0/9] xfs: pNFS block layout fixes
Date: Thu, 15 Oct 2026 13:07:59 +0900
Message-Id: <20261015-xfs-pnfs-batch-v3-0-54fc7b2e467d@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJ9R0GoC/x2MQQqAIBAAvxJ7bkEto/pKdFBbcy8WGiFEf0+6D
 Mxh5oFMiSnD3DyQ6ObMR6zStQ24YOJOyFt1UEINUkiNxWc8Y4U1lws46l5PSgpDZKFGZyLP5R8
 u6/t+zuyVtGAAAAA=
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, "Darrick J. Wong" <djwong@kernel.org>, 
 Dave Chinner <dgc@kernel.org>, Chuck Lever <cel@kernel.org>, 
 Jeff Layton <jlayton@kernel.org>, Dai Ngo <Dai.Ngo@oracle.com>, 
 Sergey Bashirov <sergeybashirov@gmail.com>, 
 Andrey Albershteyn <aalbersh@kernel.org>, linux-nfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792037279; l=9878;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=rasnpN29RY/blQ0oMOQmIC6IJTCeb1WlYVNfnq/w+ks=;
 b=2xzLjGPJ1Akk5hBmPZEkiqj20QVBCmZjX5hRlJfEW6Tat8qfInxrjQKIHPu0AFztevFiMpoBO
 0ln9fjSKKqEDMDgD96qi77zbwp7497Ow6yYKR+3MHmbeToH5w77BLCV
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The XFS side of the pNFS block and SCSI layout fixes, in one series as
Christoph asked [1]. A pNFS client alone can trigger the bugs fixed by
patches 1 and 3 to 6. The race fixed by patch 7 needs a local process
writing to a shared mapping, and patches 8 and 9 change how a
LAYOUTCOMMIT is made stable.

Patch 1 keeps blockgc from freeing the blocks past EOF that a write
layout handed out. Patches 2 to 4 make LAYOUTCOMMIT refuse a range
without blocks instead of allocating blocks for it, and clamp the
committed length before adding it to the offset. Patches 5 and 6 refuse
a write layout whose block reservation would wrap and clamp the layout
range to the maximum file size. Patch 7 takes the invalidate lock while
mapping a layout.

Patches 8 and 9 make a LAYOUTCOMMIT stable the way fdatasync does,
instead of forcing the log for every one. With patch 9, a LAYOUTCOMMIT
that only overwrites written blocks replies before its timestamps, and
the change attribute that nfsd derives from the ctime, are stable. A
crash before the next log write can take the change attribute back to
its value before the overwrite. nfsd persists the timestamps for
FILE_SYNC writes and for COMMIT, so this is a question for the nfsd side
as much as for XFS; the fixes do not depend on patches 8 and 9.

Patches 5 to 7 come from the ->map_blocks series [2]. Patch 1 of that
series is in for-next as e3c682dd1130. Its interface change, and patches
5 and 7 that prepare for and use it, are left for the next cycle [1].

Changes since the separate postings:
- Patch 1 (v2 [3]): unchanged; Christoph said it looks good.
- Patches 2 and 3 (v2 patch 1 [4]): split the new flag from its user in
  the pNFS code [5]. xfs_bmapi_write() now returns -ENOSR instead of
  -EIO when it maps nothing, and xfs_iomap_write_unwritten() then
  commits the transaction instead of cancelling it:
  xfs_iext_count_extend() may have logged the inode, and cancelling a
  dirty transaction shuts the filesystem down, as Sashiko pointed out on
  v2 [5]. Patch 2 asserts that XFS_BMAPI_CONVERT_ONLY comes with
  XFS_BMAPI_CONVERT.
- Patch 4 (v2 patch 2 [4]): code unchanged; the message now says what
  the wrap does on top of patches 2 and 3.
- Patches 5 and 6 (v1 patches 2 and 3 [2]): code unchanged. On patch 5,
  Darrick asked whether capping the count at XFS_MAX_BMBT_EXTLEN would
  do, and the answer is at [6]; one sentence of its message is fixed.
- Patch 7 (v1 patch 6 [2]): taken without the patches before it in that
  series, and without the sentence about the patch after it.
- Patch 8 (v2 patch 1 [7]): add the datasync and log_flushed arguments
  to xfs_log_force_inode() itself rather than wrapping a new
  __xfs_log_force_inode(), as Christoph suggested [8].
- Patch 9 (v2 patch 2 [7]): calls xfs_log_force_inode() with them.
- Rebased onto XFS for-next ec8f62cc109a.

Patches 1 to 6 are marked for stable. Patch 2 needs a backport for 6.9
and older, where xfs_bmapi_write() has no -ENOSR return, and a context
fix in xfs_bmap.h for 6.12; patch 3 needs one for 7.2 and older, which
do not have fs/xfs/xfs_ioend.c. Patch 4 should not go without patches 2
and 3, and patch 6 not without patch 5: on their own, the clamped range
reaches code that shuts XFS down.

XFS_BMAPI_CONVERT_ONLY takes bit 12 of the bmapi flags, which
"xfs: add XFS_BMAPI_UNWRITTEN to unmap unwritten extents in
__xfs_bunmapi()" in the fs-verity series [9] also uses. Whichever goes
in second needs to move to bit 13. The name was used before, by a flag
that commit 26b91c728b2d ("xfs: make COW fork unwritten extent
conversions more robust") removed. That flag only skipped the
allocation and went on to map the hole; this one stops before it.

Dave's rolling transaction series [10] rewrites
xfs_iomap_write_direct(), xfs_iomap_write_unwritten() and
xfs_fs_map_blocks(). In its 37/38 the inode update moves into the
allocation transaction and the path that allocates nothing returns
early; the case added by patch 1 would still need its own transaction
there. Whichever series goes in second needs to carry these changes
over.

The pynfs tests for patches 2 to 4, with a README on running pynfs
against a block layout export, were posted as [11].

Tested on nfsd-testing 78c334bc5ae6 with commit e3c682dd1130 and this
series on top, in QEMU guests with KASAN and lockdep, and XFS_DEBUG
where noted: an nvmet-tcp target, the server (nfsd, XFS on the nvmet
namespace, pnfs export) and one client. The client was pynfs, with the
tests of [11], except for fstests, which ran on the Linux NFSv4.2
client. "Without the series" is nfsd-testing with e3c682dd1130. The test
branch has the same changes as this series, apart from the context of
one line in xfs_file.c.

 - LAYOUTCOMMITs of a hole, and of a laid-out range followed by a hole
   (BLOCK7, BLOCK8): without the series XFS shut down ("Corruption of
   in-memory data (0x8) detected at xfs_trans_mod_sb"). With it,
   NFS4ERR_IO, nothing allocated and no warning; BLOCK6 to BLOCK10
   passed in 5 runs, and once with XFS_DEBUG. In both, BLOCK3 fails on a
   bug in the test.
 - The wrapped length (BLOCK10): without the series, NFS4ERR_IO with
   "nfsd: non-standard errno: -63" and a WARNING. With patches 1 to 3
   only, NFS4ERR_IO and the laid-out range stays unwritten, also with
   XFS_DEBUG, without a warning or an assertion. With the series, the
   laid-out range from 4 KiB on is converted and the commit fails at the
   hole.
 - Sashiko's case: with a test-only change that has
   xfs_iext_count_extend() log the inode in every transaction, and v2's
   handling of the refusal (cancel), a LAYOUTCOMMIT of a hole shut XFS
   down ("Corruption of in-memory data (0x8) detected at
   xfs_trans_cancel", from xfs_iomap_write_unwritten() in
   xfs_fs_commit_blocks()). With this series on the same change, BLOCK6,
   BLOCK7 and BLOCK10 passed and XFS kept running.
 - RW LAYOUTGETs (patches 5 and 6): for 16 TiB at offset 0 of an empty
   file, XFS shut down without the series. With it, NFS4ERR_NOSPC and
   nothing allocated, as for NFS4_UINT64_MAX bytes and for 100 GiB, and
   one for 16 GiB with a loga_minlength of 16 GiB is granted in three
   extents. A READ LAYOUTGET at offset 0 for NFS4_UINT64_MAX got
   NFS4ERR_IO with "Access to block zero" without the series, and
   NFS4ERR_INVAL without a warning with it, as patch 6 says.
 - Blocks past EOF under a write layout held for 360 s, with small files
   written on the server (patch 1): kept, no warning.
 - fstests generic/075, 091 and 263 over the block layout: 075 fails
   with an fsx size error with and without the series, and all 10349
   LAYOUTCOMMITs returned 0.
 - The server's own XFS, the other callers of
   xfs_iomap_write_unwritten(): O_DIRECT and buffered writes into
   preallocated space were converted as before, also with XFS_DEBUG.
   fdatasync after an overwrite forced the log 0 times in 5 runs, fsync
   5 times, and fdatasync after an extending write 5 times.
 - fstests -g quick on a local XFS (mkfs.xfs defaults from xfsprogs
   6.6.0, 32 GiB TEST and 8 GiB SCRATCH devices, KASAN and lockdep off),
   with and without the series: 1017 tests ran, and the same 5 failed
   either way (generic/453, 454, 563, 794 and xfs/261).
 - W=1 builds of fs/xfs after each patch on XFS for-next ec8f62cc109a:
   no warnings.

Patch 9 was measured in its v2 posting [7] and is unchanged apart from
the call. No test reaches the race of patch 7 or the delalloc case of
XFS_BMAPI_CONVERT_ONLY.

[1] https://lore.kernel.org/r/20261014130557.GA15773@lst.de
[2] https://lore.kernel.org/r/20261008-xfs-nfsd-map-blocks-v1-0-560026cdccb6@samsung.com
[3] https://lore.kernel.org/r/20261014-xfs-pnfs-eof-prealloc-v2-1-f303fd5e9dfb@samsung.com
[4] https://lore.kernel.org/r/20261014-xfs-pnfs-commit-hole-v2-0-d3a02a79ab6c@samsung.com
[5] https://lore.kernel.org/r/20261014130834.GB15773@lst.de
[6] https://lore.kernel.org/r/20261012024745epcms2p18c4fad2aa953cd80338e2e614198a6ea@epcms2p1
[7] https://lore.kernel.org/r/20261014-xfs-pnfs-commit-datasync-v2-0-c11341a189b5@samsung.com
[8] https://lore.kernel.org/r/20261014130124.GA15407@lst.de
[9] https://lore.kernel.org/r/20261002223705.2175542-14-aalbersh@kernel.org
[10] https://lore.kernel.org/r/20260819001442.1451892-1-dgc@kernel.org
[11] https://lore.kernel.org/r/20261014-pynfs-block-commit-v1-0-1723979f495f@samsung.com

---
Daejun Park (9):
      xfs: mark the inode preallocated for pNFS write layouts past EOF
      xfs: add a flag to convert unwritten extents without allocating blocks
      xfs: refuse a pNFS LAYOUTCOMMIT of a range without blocks
      xfs: clamp a pNFS LAYOUTCOMMIT extent before computing its end
      xfs: refuse a direct allocation whose block reservation would wrap
      xfs: clamp the pNFS layout range to the maximum file size
      xfs: take the invalidate lock while mapping a pNFS layout
      xfs: add datasync and log_flushed arguments to xfs_log_force_inode()
      xfs: make pNFS LAYOUTCOMMIT stable the way fdatasync does

 fs/xfs/libxfs/xfs_bmap.c | 14 +++++++--
 fs/xfs/libxfs/xfs_bmap.h | 10 +++++-
 fs/xfs/xfs_export.c      |  2 +-
 fs/xfs/xfs_file.c        | 52 +++----------------------------
 fs/xfs/xfs_inode.c       | 36 ++++++++++++++++++---
 fs/xfs/xfs_inode.h       |  3 +-
 fs/xfs/xfs_ioend.c       |  2 +-
 fs/xfs/xfs_iomap.c       | 27 ++++++++++++++--
 fs/xfs/xfs_iomap.h       |  3 +-
 fs/xfs/xfs_pnfs.c        | 81 ++++++++++++++++++++++++++++++++++--------------
 fs/xfs/xfs_zone_gc.c     |  2 +-
 11 files changed, 146 insertions(+), 86 deletions(-)
---
base-commit: ec8f62cc109a3f596b3c65dc0f1011c209239051
change-id: 20261015-xfs-pnfs-batch-85459210aeeb

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

