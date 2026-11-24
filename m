From: Ernest Borowski <ernest.borowski.git@proton.me>
Subject: [PATCH v2 00/11] ntfs: delayed allocation accounting and stale
 data fixes, part 1
Date: Tue, 24 Nov 2026 23:49:34 +0100
Message-Id: <20261124-b4-ntfs-delalloc-fixes-v2-0-f394c800ec03@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WOyw6CMBBFf4V07WhbXsGV/2FY9DFIDbakrQRD+
 Hdb/ACXZ+bek7uRgN5gINdiIx4XE4yzCfipIGoU9oFgdGLCKW8Y4xxkBTYOATROYpqcgsGsGKC
 WotMVdm1ZlySVZ4/HI3Xv/Y/DWz5RxWzLCSkCgvTCqjGfsvRymC2uMQdGE6Lzn2PawrLo74qFA
 QXa8magWmFFy9vsXXT2/ELS7/v+BRV9EgfvAAAA
X-Change-ID: 20261122-b4-ntfs-delalloc-fixes-5ba9d4e97353
To: Namjae Jeon <linkinjeon@kernel.org>, Hyunchul Lee <hyc.lee@gmail.com>, 
 Baolin Liu <liubaolin12138@163.com>
Cc: Christian Brauner <brauner@kernel.org>, Christoph Hellwig <hch@lst.de>, 
 "Darrick J. Wong" <djwong@kernel.org>, ntfs@lists.linux.dev, 
 linux-fsdevel@vger.kernel.org, linux-xfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Zhan Xusheng <zhanxusheng1024@gmail.com>, 
 stable@vger.kernel.org, Ernest Borowski <ernest.borowski.git@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6581;
 i=ernest.borowski.git@proton.me; s=default; h=from:subject:message-id;
 bh=2QCJ1Lv8pJcwRXH4oO49eHdWn2O+fC7Yd8/UYJK0wuE=;
 b=owGbwMvMwCVWzJ65uCpJ5D/jabUkhmw2kXrFqeeSr7lzOB58c8Mt955/8Z1L+3c4Ose/XfV/a
 uD9uR9+d5SyMIhxMciKKbJ0/L8R4hPy7dOyOK0+mDmsTCBDGLg4BWAiyXcYGRpzV0g/V/k/+5h1
 fGSvLc90N20XwdVTi214407WfJR+YMzwV/jRc7OUkPiyNZuffTqeu2G+8ZtjE79qLtv84d6Vrev
 FtNgB
X-Developer-Key: i=ernest.borowski.git@proton.me; a=openpgp;
 fpr=88FFD8544C54F6F2A65E2A8E730769A37A6214FF
X-Endpoint-Received: by B4 Relay for ernest.borowski.git@proton.me/default with auth_id=1589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A write/truncate/punch-hole stress test on a 128 MiB volume showed the
free space reported by statfs() falling from 79 MB to zero within 80
seconds, after which writes failed with ENOSPC or came back short, while
$Bitmap stayed correct.  The delalloc reservations in
vol->dirty_clusters were not given back on several paths.  The same
paths also had buffered writes into holes that exposed old disk
contents.

The series has four groups:

Patches 1-2 (iomap) are small prerequisites for patches 8 and 10.  ntfs
reserves delalloc space in whole clusters, and a cluster can be smaller
than a folio (1 KiB or 2 KiB clusters with 512-byte blocks).  Patch 1
passes each run of clean blocks to ->punch() in one call, so that ntfs
sees a whole clean cluster and can release it.  Patch 2 adds
iomap_dirty_folio_range(), which patch 10 uses to dirty part of a folio.
For XFS and ext4 the only effect of patch 1 is fewer ->punch() calls,
and patch 2 changes nothing for them.

Patches 3-6 fix reservations that were lost or dropped: on truncate
(3), when fallocate(), direct I/O or page_mkwrite() fill a hole (4),
when a cluster allocation fails (5), and when a named stream is removed
or an inode is evicted (6).

Patches 7-8 handle a buffered write that fails after ->iomap_begin()
reserved its clusters, which left delalloc runs that no data covers.
Patch 7 fixes the runlist split helpers, which turned such a run into
real clusters when it was punched or collapsed, and so corrupted
$Bitmap.  Patch 8 turns the clusters the write did not use back into
holes, so that no such run is left.

Patches 9-11 fix buffered writes into holes that showed old disk
contents or lost data written through a shared mapping:
- patch 9: the zeroing of a new cluster's edges gave up as soon as
  writeback allocated the cluster;
- patch 10: a copy that stopped inside a new cluster left the rest of
  the cluster unzeroed;
- patch 11: when a write fault or writeback allocated the clusters
  during the copy, the write zeroed blocks instead of reading them,
  which overwrote data written through a shared mapping.

All patches are Cc stable.  Dependencies:
- patches 1, 2, 3, 4 and 7 apply on their own;
- 5 needs 4, 6 needs 3, and 8 needs 6;
- 9 needs 8, 10 needs 9 and 2, and 11 needs 9;
- 8 also needs 1 to release clusters smaller than a folio.

  3 --> 6 --> 8 --> 9 --> 10 <-- 2
              ^     |
              1     +--> 11
  4 --> 5
  7

Zhan Xusheng's "ntfs: trim the sizes after a short write" [1] fixes the
file size after a short write.  Both series add the same helper,
which zeroes from a worker when the writer has a fatal signal pending
(iomap_zero_range() refuses to run then); whichever lands second can
share one copy.  Part 2 follows with five more patches: st_blocks of
delalloc data, and the remaining stale data windows of write faults,
writeback and direct I/O into holes.

Each bug fixed here has a reproducer that fails before and passes after
its fix.  The reproducers run in QEMU on a kernel with KASAN, lockdep
and UBSAN, at 512 B, 1 KiB, 2 KiB, 4 KiB, 16 KiB and 64 KiB clusters,
with ntfsck -n after every case, on Ubuntu 26.04 and Arch Linux.  On
ntfs-next f674e4b6c315 the eight reproducers of these bugs
(short_copy_stale, delalloc_accounting, delalloc_alloc_failure,
delalloc_failed_write, delalloc_zero_race, stale_wb_race,
delalloc_partial_fail, stale_write_mapping) pass with this series,
except for the st_blocks check of delalloc_alloc_failure, which part 2
fixes.  Every test that passed before still passes, also with [1] v9 and
the forced wait suggested for it applied.

  tests:                    https://github.com/xerrni/linux-ntfs
  ntfs-next:                https://github.com/xerrni/linux-ntfs/actions/runs/45387973158
  ntfs-next + this series:  https://github.com/xerrni/linux-ntfs/actions/runs/45416562964
  ntfs-next + this series + [1] v9 + the forced wait:
                            https://github.com/xerrni/linux-ntfs/actions/runs/45416568573

[1] https://lore.kernel.org/all/20261124025932.2360848-1-zhanxusheng1024@gmail.com/

---
Changes in v2:
- New patch 1 (iomap): one ->punch() call per run of clean blocks, so
  that 1 KiB and 2 KiB clusters of a dirty folio are released after a
  failed or short write (Hyunchul).
- New patch 2 (iomap) and patch 10 (was 7): after a short copy, dirty
  only the rest of the cluster, so the clusters the write did not reach
  in the same folio are still released.
- New patch 5, moved here from part 2: keep the reservations when a
  cluster allocation fails, instead of resetting every file's
  reservation or leaving a delalloc run with none (Hyunchul's question
  on v1 patch 1).
- New patch 11: revalidate the delalloc mapping when a write fault or
  writeback allocated its clusters during the copy, instead of zeroing
  data written through a shared mapping (Hyunchul).
- Patches 3-4 and 6-9 are v1 patches 1-6, unchanged.
- Cc the iomap maintainers and lists for patches 1 and 2.
- Link to v1: https://patch.msgid.link/20261122-b4-ntfs-delalloc-fixes-v1-0-0726f0dce403@proton.me

---
Ernest Borowski (11):
      iomap: punch out a run of clean blocks in one call
      iomap: add a helper to mark a range of a folio dirty
      ntfs: release delalloc reservations cut off by truncate
      ntfs: do not consume delalloc reservations when filling holes
      ntfs: keep delalloc reservations when a cluster allocation fails
      ntfs: release the delalloc reservations of an evicted inode
      ntfs: do not shift the cluster number of a delalloc run on split
      ntfs: punch out the delalloc reservation of a failed buffered write
      ntfs: zero new delalloc clusters even when writeback allocates them
      ntfs: zero the rest of a new cluster after a short buffered write
      ntfs: revalidate a buffered write's mapping after its clusters were allocated

 fs/iomap/buffered-io.c |  29 +++-
 fs/ntfs/attrib.c       | 130 +++++++++++++++++-
 fs/ntfs/attrib.h       |   2 +
 fs/ntfs/inode.c        |  13 +-
 fs/ntfs/inode.h        |   3 +
 fs/ntfs/iomap.c        | 367 ++++++++++++++++++++++++++++++++++++++++---------
 fs/ntfs/lcnalloc.c     |   1 -
 fs/ntfs/runlist.c      |  13 +-
 include/linux/iomap.h  |   1 +
 9 files changed, 485 insertions(+), 74 deletions(-)
---
base-commit: f674e4b6c315ebe742d08af80659386992d58ce9
change-id: 20261122-b4-ntfs-delalloc-fixes-5ba9d4e97353

Best regards,
--  
Ernest Borowski <ernest.borowski.git@proton.me>

