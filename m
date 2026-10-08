From: Daejun Park <daejun7.park@samsung.com>
Subject: [PATCH 0/8] xfs, nfsd: map a whole pNFS block layout in one
 ->map_blocks call
Date: Thu, 08 Oct 2026 10:39:29 +0900
Message-Id: <20261008-xfs-nfsd-map-blocks-v1-0-560026cdccb6@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFH0xmoC/x3MTQqAIBBA4avErBtQsR+6SrSwHGuoLByIILp70
 vJbvPeAUGIS6IoHEl0sfMQMXRYwLS7OhOyzwShTa6VavINgDOJxdyeO2zGtglY3vhpr58gayOW
 ZKPD9X/vhfT8mSRkAZQAAAA==
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>, 
 Christoph Hellwig <hch@lst.de>, Carlos Maiolino <cem@kernel.org>, 
 Amir Goldstein <amir73il@gmail.com>
Cc: "Darrick J. Wong" <djwong@kernel.org>, Dave Chinner <dgc@kernel.org>, 
 Sergey Bashirov <sergeybashirov@gmail.com>, 
 Christian Brauner <brauner@kernel.org>, linux-nfs@vger.kernel.org, 
 linux-xfs@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791423569; l=7438;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=kP0JJQRwP0kNOX5s7X+UWUSB0zcc0qher0tSsqFRWKw=;
 b=lrFrEp5QgOiMYXYb/d1JOtyxiu/wqdG0GoRLJODoSCxZGx7HOoaBjy9nT610jBvSfnZ2459rK
 xx6ttYEwjQbBcOHKx8Ureevc8DCXHDLXWei5W7KXHOgjxDExfBquw4K
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nfsd calls ->map_blocks once per extent of a block layout. XFS takes
the iolock, flushes and invalidates the page cache, maps one extent
and, if it allocated blocks for a write layout, updates the inode and
forces the log, all again for each extent, and the mapping of the file
can change between the calls. Christoph asked for ->map_blocks to
return several mappings instead [1], as Darrick had suggested [2].

Patch 1 is "xfs: map pNFS layouts to the end of the extent again" [3],
posted on its own and reviewed by Darrick, but not in a tree yet. It
changes the same function, so it is included here unchanged.

Patches 2 and 3 fix the ranges that xfs_fs_map_blocks() gets from a
client. An RW LAYOUTGET at offset 0 of an empty file for 16 TiB shuts
the filesystem down, because xfs_iomap_write_direct() keeps the block
reservation in an unsigned int; patch 2 refuses a count that does not
fit with -ENOSPC. A LAYOUTGET for NFS4_UINT64_MAX bytes, or at an offset
of 2^63, makes the range check wrap and maps nothing; patch 3 fixes the
check, which the rest of the series relies on. Both are fixes for stable
kernels as well, and leave a range that fits the free space as it was.
Patch 3 needs patch 2 there: alone, it turns the NFS4ERR_IO of an RW
layout to the end of the file into a shutdown.

Patch 4 lets ->map_blocks fill an array of mappings, without a change
in behavior. Patches 5 to 7 make XFS map the whole range one extent
after the other, under the iolock and, as Darrick also pointed out in
[2], the invalidate lock, so that each mapping starts where the one
before it ends, with one flush and at most one log force. Patch 8 makes
nfsd ask for all extents at once and check that they fit together,
instead of trimming them.

The series is on top of nfsd-testing 214e388464bf ("nfsd: do not return
overlapping extents in a block layout"). Patches 4 and 8 depend on that
commit, which added the comment that patch 4 changes and the trim that
patch 8 replaces. Darrick's comment on that commit [5] came after it was
applied: patch 4 documents that a mapping may end past the range, and
patch 8 removes the comment he asked to fix. exportfs_block.h is
maintained with nfsd, so I would suggest the nfsd tree, with acks from
XFS for patches 1 to 3 and 5 to 7. Patches 1 to 3 could also go through
XFS first; they apply to XFS for-next 197f678cccba as they are, and
patches 5 to 7 do not apply without them.

Tests. QEMU VMs, the server exports a 32 GiB XFS on an NVMe/TCP
namespace, pynfs or the Linux client, KASAN and lockdep unless noted.
"before" is the base with patch 1, "after" the whole series.

LAYOUTGETs for the first 256 KiB of a file in which 32 blocks of 4 KiB
written with O_DIRECT are each followed by a 4 KiB hole, 64 extents,
20 LAYOUTGETs each, KASAN and lockdep off, time from a kprobe on
nfsd4_block_proc_layoutget():

                                            before      after
  READ: ->map_blocks calls                  64          1
        median time                         26 us       9 us
  RW, 32 holes allocated:
        ->map_blocks calls                  64          1
        log forces                          32          1
        median time                         166 ms      2.2 ms

RW LAYOUTGETs for large ranges, minimum length 4 KiB unless noted,
each on its own boot:

                            before       patches 2, 3   after
  empty file, 16 TiB        shutdown     NOSPC          NOSPC
  empty file, to the end    IO, WARN     NOSPC          NOSPC
  64 KiB allocated, then
  a hole, to the end        IO, WARN     NOSPC          NOSPC
  empty file, 100 GiB       NOSPC        NOSPC          NOSPC
  empty file, 16 GiB,
  minimum length 16 GiB     16 GiB       16 GiB         16 GiB

NOSPC is answered before anything is allocated. WARN is nfsd's warning
about the non-standard errno -63.

pynfs, with BLOCK5 from [6] and the empty lou_body of BLOCK3 passed as
bytes (as shipped, BLOCK3 fails with a TypeError in pynfs before
anything is sent): BLOCK1, BLOCK2, BLOCK4 and BLOCK5 pass before and
after, five and three runs, and BLOCK3 fails in both with
NFS4ERR_BADXDR, as a zero-length lou_body has no extent count.
GETLAYOUT1, a READ LAYOUTGET for NFS4_UINT64_MAX bytes, gets NFS4ERR_IO
before, NFS4ERR_INVAL with patches 2 and 3, and a layout to 2^63 after,
also with XFS_DEBUG. LAYOUTRET1 and LAYOUTRET3 then run and fail as they
would on any kernel (a TypeError in pynfs, and no current filehandle),
as do CSID7 and GETDLIST1 before and after. On a test kernel whose XFS
does not trim a mapping to the offset asked for, BLOCK5 gets
NFS4ERR_LAYOUTUNAVAILABLE and nfsd warns, instead of handing out
overlapping extents. With a process on the server that writes a shared
mapping of another file in a loop, the pynfs run gives no lockdep
report.

fstests generic/075, 091 and 263 over the block and the SCSI layout
give the same results before and after (075 fails with an fsx size
error in both), and the client's bl_alloc_lseg() returns no error.
With XFS_DEBUG, of generic/013, 075, 091, 112, 127 and 263 only 075,
112 and 127 fail, which also fail without this series on nfsd-testing,
and XFS logs no assertion.

Clients writing new files through their layouts, four cases, read back
on the server: no block is lost before or after. This test runs on top
of the nfsd layout recall series [4] as revised for a v2 that is not
posted yet; this series applies to it without conflicts. Without it,
nfsd-testing loses blocks when a layout recall fails.

Not in this series: Darrick's third point in [2], that the reflink and
realtime checks are made before the locks are taken, and the window
between ->map_blocks and nfsd4_insert_layout() that Christoph mentioned
in the same thread, which this series narrows but does not close.

[1] https://lore.kernel.org/r/20261007131133.GB30647@lst.de
[2] https://lore.kernel.org/r/20260519145949.GH9555@frogsfrogsfrogs
[3] https://lore.kernel.org/r/20261006003425epcms2p586728e55ff5f9bbabc506b672fc4a421@epcms2p5
[4] https://lore.kernel.org/r/20261006-nfsd-layout-recall-v1-0-b59b31caf342@samsung.com
[5] https://lore.kernel.org/r/20261007165101.GD2705364@frogsfrogsfrogs
[6] https://lore.kernel.org/r/20261006002622epcms2p38e492aef17fdf79e48b05c9aada2918d@epcms2p3

---
Daejun Park (8):
      xfs: map pNFS layouts to the end of the extent again
      xfs: refuse a direct allocation whose block reservation would wrap
      xfs: clamp the pNFS layout range to the maximum file size
      exportfs: let ->map_blocks return more than one mapping
      xfs: factor the mapping of one pNFS extent out of xfs_fs_map_blocks()
      xfs: take the invalidate lock while mapping a pNFS layout
      xfs: map the whole range of a pNFS layout in one ->map_blocks call
      nfsd: get all extents of a block layout in one ->map_blocks call

 fs/nfsd/blocklayout.c          | 134 +++++++++++++++++++++-------------------
 fs/xfs/xfs_iomap.c             |   7 +++
 fs/xfs/xfs_pnfs.c              | 136 +++++++++++++++++++++++++++++------------
 include/linux/exportfs_block.h |  14 +++--
 4 files changed, 185 insertions(+), 106 deletions(-)
---
base-commit: 214e388464bf850fcdc5d656fd39909f0a1ee83d
change-id: 20261008-xfs-nfsd-map-blocks-417d5b6aae42

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

