From: Mark Korenberg <socketpair@gmail.com>
Subject: [PATCH v2 0/2] btrfs: tag tree block repair and RAID5/6 metadata
 I/O with REQ_META
Date: Fri, 06 Nov 2026 22:33:08 +0500
Message-Id: <20261106-btrfs-sb-read-req-meta-v2-0-71c1afaf5c67@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQqDMBREryJ/3V8SUdN01XsUF4n56oeqbRJCi
 +TuTb1AZzHwBmZmh0CeKcC12sFT4sDbWqA+VTDMZp0I2RWGWtSdlKJBG/0YMFj0ZFyxFy4UDSp
 LrVamqJVQyk9PI7+P4XtfeOYQN/85fpL8pX8nk0SJJDrbONHqi1a3aTH8OA/bAn3O+QurhqA+v
 AAAAA==
X-Change-ID: 20261104-btrfs-sb-read-req-meta-7be597aaaa51
To: David Sterba <dsterba@suse.com>, Chris Mason <mason@kernel.org>
Cc: Qu Wenruo <wqu@suse.com>, linux-btrfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Mark Korenberg <socketpair@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793986388; l=3228;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=uBfa/e6IVMCRQRcbDLHJW71sGV+QFJ4/tF2ZMfAJ+3U=;
 b=Wvz2sjsut2f/096cp7dJR3YN6ju8KnNGm7KaiqihHvS8+rxhKMw8TNh9H436cde/U8tb5Ysjq
 j4eCiJ+aQ4/CgLC3ZtWUgOQXTQTe1NonWyhhxjUfDpRJ6SuXkGi+S7g
X-Developer-Key: i=socketpair@gmail.com; a=ed25519;
 pk=2iAMjWhs7kA9X8ccetT2YVX8dvniXua2okQogw3Don8=
X-Endpoint-Received: by B4 Relay for socketpair@gmail.com/20260603 with auth_id=806
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Tree block reads and writes carry REQ_META, so the layers below see
them as metadata I/O: blk-cgroup issues them as root to avoid priority
inversion, wbt does not throttle them, blktrace shows them as such, and
ublk passes the flag to its server as UBLK_IO_F_META.  Two paths of
normal operation lose the flag:

- Patch 1: when a tree block read finds a bad copy, the rewrite from a
  good copy goes out as a plain write.
- Patch 2: on RAID5/6 the rbio builds new per-device bios and drops the
  flag, so all tree block writes, and tree block reads rebuilt from the
  other stripes (for example with a missing device), go out as data
  I/O.  On the other profiles the per-device bios are clones and keep
  it.  Now the flag follows the bios the rbio serves, P/Q included, so
  mixed block groups need no special case.

Thanks to Qu for the review of v1.  I agree that background work
should not get the priority of metadata I/O, so v2 drops the scrub,
dev-replace and relocation parts: they stay untagged even when they
handle metadata, and so do the rebuilds and parity checks that scrub
does on RAID5/6.

RAID5/6 stays, as its own patch, because what it tags is regular
operation, not background work.  The writes are the normal tree block
writeback, which carries REQ_META on every other profile.  A rebuild
read serves a tree block read, the same read that carries REQ_META when
no rebuild is needed.

Zoned devices see no change: they support neither RAID5/6 nor in-place
repair, btrfs_repair_one_zone() relocates the block group instead.

Testing: virtme-ng VM, memory backed null_blk, tracefs
block:block_bio_queue, every bio classified by the chunk type of its
dev extent:
- RAID5 metadata and data, copy /usr/include: all metadata bios, P/Q
  and RMW reads included, carry REQ_META (before: none).  Scrub and the
  copy of a dev-replace carry none.
- RAID5 with one device missing, mounted degraded, all files read: all
  696 metadata bios carry REQ_META (before: the 344 rebuild reads did
  not).
- DUP metadata with one copy of a leaf corrupted, read back: the repair
  write carries REQ_META.
No bio to a data chunk carries the flag, no new warnings, W=1 build
clean.

Changes in v2:
- Leave scrub, dev-replace and remap relocation untagged, including the
  super block reads of scrub: background work (Qu).
- RAID5/6: take REQ_META from the bios the rbio serves instead of the
  chunk type, which also covers rebuild reads and mixed block groups,
  and move it to its own patch (Qu).
- Link to v1: https://lore.kernel.org/r/20261104-btrfs-sb-read-req-meta-v1-1-e06b4d059897@gmail.com

The audit, the patches and the tests were drafted with the help of an
AI assistant (Claude Opus 5.5).

---
Mark Korenberg (2):
      btrfs: tag tree block repair writes with REQ_META
      btrfs: raid56: pass REQ_META to per-device bios

 fs/btrfs/bio.c    |  3 ++-
 fs/btrfs/raid56.c | 14 +++++++++++---
 fs/btrfs/raid56.h |  7 +++++++
 3 files changed, 20 insertions(+), 4 deletions(-)
---
base-commit: df5b88a7914e18488908ddf13e14e31ab39f954c
change-id: 20261104-btrfs-sb-read-req-meta-7be597aaaa51

Best regards,
-- 
Mark Korenberg <socketpair@gmail.com>

