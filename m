From: Daejun Park <daejun7.park@samsung.com>
Subject: [PATCH v2 0/2] xfs: make pNFS LAYOUTCOMMIT stable the way
 fdatasync does
Date: Wed, 14 Oct 2026 12:43:09 +0900
Message-Id: <20261014-xfs-pnfs-commit-datasync-v2-0-c11341a189b5@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAE36zmoC/42NTQ6CQAyFr0K6toZWI+KKexgWk6FAFwxkigRCu
 LsjJ3Dzku/l/exgElUMXtkOURY1HUMCvmTgexc6QW0SA+f8oJxuuLaGU0jix2HQGRs3O9uCx9w
 XfOeiIHEMqT5FaXU9p9914l5tHuN2Pi30c/8YXQgJ2RFL+yzFN2VlbrBP6K4pCfVxHF+cqERMw
 gAAAA==
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, "Darrick J. Wong" <djwong@kernel.org>, 
 Dave Chinner <dgc@kernel.org>, Chuck Lever <cel@kernel.org>, 
 Jeff Layton <jlayton@kernel.org>, Dai Ngo <Dai.Ngo@oracle.com>, 
 Sergey Bashirov <sergeybashirov@gmail.com>, linux-nfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791949389; l=8008;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=7jaEf+DSc3ZErWV7GdzaWAdh1OASwLxdqWsXrm+gVDE=;
 b=er4d8e0QmqyM1euukGiZzo2JIqFIpYmRUmmQb/OUAyL5f0Iu86Bwf25A0OlKJQcVzFWEdbG20
 4qIpSgCtZuCCbh936jya1oHFEWueDYvLYUv+LFmp3ZMJHhRAQVHxVE0
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Patch 2 stops forcing the log for a LAYOUTCOMMIT that converts nothing
and keeps the size, and flushes the data device cache instead, the way
fdatasync does. Patch 1 moves the log force helper of fsync next to
xfs_log_force_inode() so that xfs_pnfs.c can use it.

Changes in v2:
- New patch 1: move xfs_fsync_flush_log() next to
  xfs_log_force_inode() in xfs_inode.c as __xfs_log_force_inode(),
  and make xfs_log_force_inode() a wrapper around it (Christoph). It
  stays in xfs_inode.c rather than xfs_log.c because
  xfs_log_force_inode() is already there and xfs_log.c does not deal
  with inode log items.
- Patch 2 calls __xfs_log_force_inode() instead of exporting
  xfs_fsync_flush_log() from xfs_file.c, and is otherwise unchanged.
- Do not factor the end of xfs_file_fsync() into a shared helper, as
  offered in v1 (Christoph: overkill for two function calls).
- Link to v1: https://lore.kernel.org/r/20261013-xfs-pnfs-commit-datasync-v1-1-2a12ef89ecd9@samsung.com

With patch 2, the timestamps of a LAYOUTCOMMIT that converts nothing
and keeps the size, and the change attribute that nfsd derives from
i_version and the ctime, are not made stable before the reply goes
out. After a server crash, a
client that cached the file before the LAYOUTCOMMIT could see the old
change attribute again and keep its stale cache until the file changes.
A WRITE with DATA_SYNC4 already leaves the timestamps that way ("persist
data only" in nfsd_vfs_write(), nfsd4_iocb_flags() in nfsd-testing),
although there the client asks for it, and the comment above
nfsd4_change_attribute() assumes a stable change attribute only for
directories.

On a sync export, nfsd makes most metadata operations stable before it
replies: commit_metadata() after SETATTR, ALLOCATE, DEALLOCATE, create,
link, rename and unlink, and a full fsync for CLONE and, as RFC 8881
section 18.3.4 asks, for COMMIT. With this patch, a LAYOUTCOMMIT on a
sync export replies before its timestamps are stable, unlike those.
LAYOUTCOMMIT is not that COMMIT: section 12.5.4 says "The data should be
written and committed to the appropriate storage devices before the
LAYOUTCOMMIT occurs", and of durability it says only that for block
layouts LAYOUTCOMMIT may require committing the block list to stable
storage, which this patch keeps. If nfsd wants LAYOUTCOMMIT to follow
the sync export option anyway, ->commit_blocks can take a datasync
argument as ->fsync does, but sync is the default, so the gain would
then be limited to async exports.

Tested on nfsd-testing d918c664efd5 with the same changes, in QEMU
guests: nfsd on XFS (mkfs.xfs defaults, internal log, sync export), the
block layout on an NVMe/TCP namespace exported by nvmet from another
guest, and the Linux NFSv4.2 client. The series applies to XFS for-next
0be6da616ab5 as is. The measurements below were taken with v1; v2 only
moves the log force helper, and the v2 runs listed after them show the
same behaviour.

nfsd-testing does not have commit e3c682dd1130 ("xfs: map pNFS layouts
to the end of the extent again"), which only changes LAYOUTGET, nor the
for-next changes to the log cache flushes (xlog_flush_data_caches() and
XLOG_ICL_NEED_FLUSH_LOG), which only matter with an external log or an
rt device.

 - Overwrites of written files, each write followed by fsync, KASAN
   and lockdep off. The namespace was backed by a partition of a
   Samsung 990 PRO (volatile write cache), given to the nvmet guest as
   virtio-blk with cache=none. virtio-blk has no FUA, so REQ_FUA became
   a write plus a cache flush there. Medians of 5 runs, with the
   kernels without and with the patch alternating; "ms each" is the
   time in xfs_fs_commit_blocks() per LAYOUTCOMMIT:

     threads  file    write   without    with  commits  ms each
     1        16 MiB  64 KiB   800 ms  473 ms   256   2.4 -> 1.1
     4        16 MiB  64 KiB  1083 ms 1011 ms  1024   2.6 -> 2.5
     1         4 MiB   4 KiB  3101 ms 1841 ms  1024   2.6 -> 1.5

   With the patch no LAYOUTCOMMIT forced the log, and the log was
   written at most once per run. With 4 writers the gain is smaller:
   without the patch their log forces are partly shared, and with it
   their cache flushes queue up. Overwrites of 64 MiB files in 4 MiB
   writes by 4 threads took 1150 ms instead of 1328 ms, medians of 3
   runs that overlap (1114 to 1214 ms against 1181 to 1424 ms) and did
   not alternate.
 - New files, 4 threads writing 64 MiB each in 4 MiB writes, each
   write followed by fsync: every LAYOUTCOMMIT still forced the log, as
   before.
 - A crash right after a LAYOUTCOMMIT of an extent that the server had
   just converted with a direct write, before that conversion was
   written to the log: the server preallocated 4 MiB and wrote it with
   O_DIRECT, the client overwrote it through the layout and called
   fsync, and the server VM was killed. After mount, the extent was
   written and held the client's data, with and without the patch (2
   runs each). A prototype that only flushed the cache when the range
   was written in memory and the size did not change lost the data in
   both runs: the extent came back unwritten.
 - The same crash after the client wrote a new 4 MiB file through the
   layout and called fsync (allocation, conversion and a new size):
   size, extent and data were all there, with and without the patch
   (2 runs each).
 - With a KASAN and lockdep kernel, and no warnings from either: pynfs
   block and blockextent, same as without the patch (BLOCK3 fails
   either way, on a bug in the test); fstests generic/075, 091 and 263
   over the block layout, where 075 fails with an fsx size error as it
   does without the patch, and none of the 10337 LAYOUTCOMMITs failed.
   The pynfs tests also passed the same way on an XFS_DEBUG kernel with
   XFS_ASSERT_FATAL.
 - v2, both patches: the overwrite of a 16 MiB file in 64 KiB writes,
   each followed by fsync, made 256 LAYOUTCOMMITs with no log write
   and one cache flush each, as with v1 (2 runs each, host file
   backing). The two crash cases gave the same results as above (2
   runs each). pynfs block and blockextent gave the same results on
   KASAN and lockdep, XFS_DEBUG, and patch 1 alone, with no warnings.
   In fstests generic/075, 091 and 263 over the block layout on the
   KASAN and lockdep kernel, 075 failed with an fsx size error as
   before, none of the 10373 LAYOUTCOMMITs failed, and there were no
   warnings.
 - v2, fsync and fdatasync on the server's own XFS, counted from
   /proc/fs/xfs/stat over 5 calls each: an overwrite followed by
   fdatasync forced the log 0 times, an overwrite followed by fsync 5
   times, and an extending write followed by fdatasync 5 times. That
   is the same as with v1, and the same with patch 1 alone.
 - fstests -g quick on a local XFS (mkfs.xfs defaults from xfsprogs
   6.6.0, 10 GiB TEST and SCRATCH devices, KASAN and lockdep off),
   with and without the series: 1017 tests ran, and the same 5 failed
   either way (generic/453, 454, 563, 794 and xfs/261). Also the same
   with v2 of "xfs: refuse pNFS LAYOUTCOMMITs of ranges without
   blocks", sent at the same time, applied as well.
 - W=1 builds of the changed files after each patch, on XFS for-next
   0be6da616ab5 and on nfsd-testing: no warnings.

---
Daejun Park (2):
      xfs: move xfs_fsync_flush_log() next to xfs_log_force_inode()
      xfs: make pNFS LAYOUTCOMMIT stable the way fdatasync does

 fs/xfs/xfs_file.c  | 44 +-------------------------------------------
 fs/xfs/xfs_inode.c | 42 +++++++++++++++++++++++++++++++++++++-----
 fs/xfs/xfs_inode.h |  2 ++
 fs/xfs/xfs_pnfs.c  | 21 +++++++++++++++------
 4 files changed, 55 insertions(+), 54 deletions(-)
---
base-commit: 0be6da616ab5031ea6419dc4fe0bf0e378fb6757
change-id: 20261013-xfs-pnfs-commit-datasync-0c7242771ea2

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

