From: Daejun Park <daejun7.park@samsung.com>
Subject: [PATCH v2 0/2] xfs: refuse pNFS LAYOUTCOMMITs of ranges without
 blocks
Date: Wed, 14 Oct 2026 12:42:57 +0900
Message-Id: <20261014-xfs-pnfs-commit-hole-v2-0-d3a02a79ab6c@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEH6zmoC/22NQQ6CQAxFr0K6tmZajIgr72FYjDBAE5khUyQYw
 t0dSdy5afJ+/n9dQV0Up3DNVohuFpXgE/Ahg7q3vnMoTWJgw2cyxLi0iqNPpw7DIBP24emwzo1
 1peVL0eaQpmN0rSy79l4l7kWnEN/7l5m+6U+Y/xfOhITFyZTEzaMkwze1g758d0wtqLZt+wCbc
 jrRugAAAA==
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, "Darrick J. Wong" <djwong@kernel.org>, 
 Dave Chinner <dgc@kernel.org>, Chuck Lever <cel@kernel.org>, 
 Jeff Layton <jlayton@kernel.org>, Dai Ngo <Dai.Ngo@oracle.com>, 
 Sergey Bashirov <sergeybashirov@gmail.com>, linux-nfs@vger.kernel.org, 
 Andrey Albershteyn <aalbersh@kernel.org>, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791949377; l=5569;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=LHzFOmq/a+lyPtSBjNoJEO3MjrbmhrHhyDkpiPxXg7g=;
 b=XoR+j2rGgjPTJF4tYYjhWR9C16Nr/Wxic59Lt1AhbYan1sa81jBgNUtwC6ySyHQbR0bfFFpZ1
 w/vkPNtccwDAIeFP6FGKaMkzHq4C+NRDPGiJ+zWXQS4QKe5ZQHEL7pn
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xfs_fs_commit_blocks() converts whatever range a pNFS client commits.
For a range without blocks, the conversion allocates blocks that the
transaction did not reserve and shuts XFS down, or maps blocks that
nobody wrote into the file. Patch 1 refuses such a commit with a new
XFS_BMAPI_CONVERT_ONLY flag for xfs_bmapi_write(). Patch 2 clamps the
committed length before adding it to the offset, as the sum can wrap.

Changes in v2:
- Refuse the hole in xfs_bmapi_write() with a new
  XFS_BMAPI_CONVERT_ONLY flag, as Christoph suggested, instead of
  checking all the ranges first. A range before the hole is now
  converted before the commit fails; v1 converted nothing.
- Drop the blockgc case from the message: with "xfs: mark the inode
  preallocated for pNFS write layouts past EOF" [1], blockgc keeps
  those blocks.
- Split the length clamp into patch 2. It fixes a separate bug.
- Link to v1: https://lore.kernel.org/r/20261013-xfs-pnfs-commit-hole-v1-1-740912db9102@samsung.com

XFS_BMAPI_CONVERT_ONLY takes bit 12 of the bmapi flags, which "xfs: add
XFS_BMAPI_UNWRITTEN to unmap unwritten extents in __xfs_bunmapi()" in
the fs-verity series [2] also uses. Whichever goes in second needs to
move to bit 13. The name was used before, by a flag that commit
26b91c728b2d ("xfs: make COW fork unwritten extent conversions more
robust") removed. That flag only skipped the allocation and went on to
map the hole; this one stops before it.

This series and v2 of "xfs: make pNFS LAYOUTCOMMIT stable the way
fdatasync does", sent at the same time, both change
xfs_fs_commit_blocks(). They apply in either order.

Tested on nfsd-testing d918c664efd5 with the same two patches on top,
in QEMU guests with KASAN and lockdep. The block layout was on an
NVMe/TCP namespace exported by nvmet. The client was pynfs, except for
fstests, which ran on the Linux NFSv4.2 client. XFS for-next also has
commit e3c682dd1130 ("xfs: map pNFS layouts to the end of the extent
again"), which nfsd-testing does not have. xfs_bmapi_write(),
xfs_iomap_write_unwritten(), xfs_fs_commit_blocks() and
xfs_dio_write_end_io() are the same in both trees, and so is the
changed line in xfs_end_ioend_write().

 - A LAYOUTCOMMIT of a 64 KiB hole: NFS4ERR_IO and shutdown without the
   series. With it, NFS4ERR_IO, no shutdown and nothing allocated, in 5
   runs.
 - A LAYOUTCOMMIT of a 4 KiB hole: NFS4_OK and a written block in the
   file without the series. With it, NFS4ERR_IO and nothing allocated.
 - The laid-out range and the 64 KiB hole in one LAYOUTCOMMIT: shutdown
   without the series. With it, NFS4ERR_IO, and fiemap on the server
   shows the laid-out range written and nothing allocated in the hole.
 - An extent at 4 KiB with a length of 2^64 - 4 KiB: NFS4ERR_IO and
   "nfsd: non-standard errno: -63" without the series, and with
   XFS_DEBUG "Assertion failed: bma.nallocs >= *nmap" in
   xfs_bmapi_write(). With patch 1 alone, the same nfsd warning. With
   both, NFS4ERR_IO and no warning, also with XFS_DEBUG.
 - Blocks past EOF freed by blockgc under a layout, without [1]: the
   LAYOUTCOMMIT after the client's write shut XFS down without the
   series and got NFS4ERR_IO with it.
 - pynfs block and blockextent, also with XFS_DEBUG: same as without
   the series (BLOCK3 fails either way, on a bug in the test).
 - fstests generic/075, 091 and 263 over the block layout: 075 fails
   with an fsx size error with and without the series, and XFS refused
   none of the 10384 LAYOUTCOMMITs with it.
 - O_DIRECT and buffered writes into preallocated space on the
   server's own XFS, the other callers of xfs_iomap_write_unwritten():
   converted as before, on the XFS_DEBUG kernel.
 - fstests -g quick on a local XFS (mkfs.xfs defaults from xfsprogs
   6.6.0, 10 GiB TEST and SCRATCH devices, KASAN and lockdep off),
   with and without the series: 1017 tests ran, and the same 5 failed
   either way (generic/453, 454, 563, 794 and xfs/261). Also the same
   with both series applied.
 - W=1 builds of the changed files after each patch, on XFS for-next
   0be6da616ab5 and on nfsd-testing: no warnings.

No test reaches the delalloc case of the new flag. It takes the same
branch as a hole.

For stable, patch 2 applies to every LTS tree, but should not go in
without patch 1: on its own, the clamped extent reaches the hole and
shuts XFS down, as a LAYOUTCOMMIT of a hole already does there. Patch 1
needs a backport for 7.2 and older, which do not have
fs/xfs/xfs_ioend.c.

xfs_pnfs_validate_isize() reads the extents under XFS_ILOCK_SHARED,
which xfs_iread_extents() does not allow when they are not loaded yet.
That needs a separate fix.

[1] https://lore.kernel.org/r/20261012-xfs-pnfs-eof-prealloc-v1-1-e4864d917a00@samsung.com
[2] https://lore.kernel.org/r/20261002223705.2175542-14-aalbersh@kernel.org

---
Daejun Park (2):
      xfs: refuse a pNFS LAYOUTCOMMIT of a range without blocks
      xfs: clamp a pNFS LAYOUTCOMMIT extent before computing its end

 fs/xfs/libxfs/xfs_bmap.c | 14 ++++++++++++++
 fs/xfs/libxfs/xfs_bmap.h | 10 +++++++++-
 fs/xfs/xfs_file.c        |  2 +-
 fs/xfs/xfs_ioend.c       |  2 +-
 fs/xfs/xfs_iomap.c       |  7 ++++---
 fs/xfs/xfs_iomap.h       |  3 ++-
 fs/xfs/xfs_pnfs.c        | 13 +++++++++----
 7 files changed, 40 insertions(+), 11 deletions(-)
---
base-commit: 0be6da616ab5031ea6419dc4fe0bf0e378fb6757
change-id: 20261012-xfs-pnfs-commit-hole-c30ae9a287f3

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

