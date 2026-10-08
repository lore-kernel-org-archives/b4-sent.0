From: Daejun Park <daejun7.park@samsung.com>
Subject: [PATCH v2 0/2] ext4: fix fast commit and extent status after
 unwritten extent zero-out
Date: Thu, 08 Oct 2026 10:25:35 +0900
Message-Id: <20261008-ext4-fc-zeroout-v2-0-55cab1e24fa3@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAA/xxmoC/2WNQQ6CMBBFr0Jm7ZhpaYq48h6GRS0DdAE1LRCU9
 O5WElcu30v++ztEDo4jXIsdAq8uOj9lkKcC7GCmntG1mUGS1IJII2+zws7im4P3y4ysZE1U2Uo
 agrx6Bu7cdhTvTebBxdmH13Gwiq/9taq/1iqQ8HHRLWtV1qoUt2jGuEz92foRmpTSB/rZQsGwA
 AAA
To: Theodore Ts'o <tytso@mit.edu>, linux-ext4@vger.kernel.org
Cc: Jan Kara <jack@suse.cz>, Andreas Dilger <adilger.kernel@dilger.ca>, 
 Baokun Li <libaokun@linux.alibaba.com>, 
 Ojaswin Mujoo <ojaswin@linux.ibm.com>, 
 "Ritesh Harjani (IBM)" <ritesh.list@gmail.com>, 
 Zhang Yi <yi.zhang@huawei.com>, Zhang Yi <yi.zhang@huaweicloud.com>, 
 Harshad Shirwadkar <harshadshirwadkar@gmail.com>, Li Chen <me@linux.beauty>, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791422735; l=3514;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=yeOwUTqDuR+LFpSQg6FwfpWjLvYhNN1K8QqDI9SipC4=;
 b=1B4IoWNTfYaCByl2DEVxmy/yc2PDq1y6JqQY5QZXeouf76hDv2Iw4qMtvlwOLZ65G30StjvQU
 yd5NiqY/ryND8T1EP6Nh9uLH8OgPacJ1HSmOamSzldMJaAQ8Zzxwrx5
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When ext4_ext_convert_to_initialized() converts part of an unwritten
extent, it may zero out the blocks around the range and convert them
too, and ext4_split_extent() does the same with a whole extent when a
split fails. Two things go wrong around that.

1/2: if the zeroout fails, the blocks on that side stay unwritten in the
extent tree, but the extent status tree caches them as written. Reads
return old disk contents, and writes go in place without converting the
extent, so they read back as zeroes once the entry is dropped.

2/2: when the zeroout succeeds, fast commit is told only about the range
that was written. A later in-place overwrite of a zeroed block is not
tracked either, and after a crash the fsynced data reads back as zeroes.

Tested in QEMU on ext4 dev 9091c97be340 plus this series:
 - the reproducer described in 2/2, with -o nodelalloc and with
   -o dioread_lock, also on a PROVE_LOCKING and DEBUG_ATOMIC_SLEEP kernel
   (no report), and the dm-error reproducer described in 1/2;
 - FALLOC_FL_WRITE_ZEROES on scsi_debug (lbpws=1 lbprz=1) over a whole
   unwritten extent, over one block in the middle of one, and over a
   hole, each followed by an in-place write, fsync and
   EXT4_IOC_SHUTDOWN: the written block survives replay, with and
   without the series;
 - xfstests ext4/044 ext4/045 generic/455 generic/456 generic/482 with
   -O fast_commit, with and without -o nodelalloc: the same results as
   without the series. generic/455 fails on both, at different marks.
   generic/482 fails now and then on both (base 3 of 53 runs, with the
   series 2 of 46), with e2fsck reporting i_blocks one block short after
   replay;
 - the ext4 KUnit tests, 72 of 72. They are the only ones to reach the
   zeroout after a failed split, with the zeroout stubbed and without
   fast commit, so the tracking there is covered by review only.

For stable: the fast commit part goes back to 5.10. 2/2 applies as is
from 7.3-rc1 on, and I will send backports for older trees.

---
Changes in v2:
- 2/2: track the range in ext4_issue_zeroout(), once the zeroout has
  succeeded, instead of in ext4_zeroout_es() and
  ext4_split_extent_zeroout() (Jan). ext4_issue_zeroout() and
  ext4_ext_zeroout() take the handle for that.
  ext4_alloc_file_blocks() zeroes out without a handle and passes NULL.
  The ext4_convert_unwritten_extents() call after it tracks the blocks
  it converts through ext4_map_blocks(), blocks that were already
  written keep their mapping, and the FALLOC_FL_WRITE_ZEROES test above
  keeps the block on the base kernel too, so I found no gap there.
- 1/2: add Jan's Reviewed-by.
- 2/2: Cc stable without "# 7.0.x"; the fix is in ext4_issue_zeroout()
  now, which older trees have as well.
- Link to v1: https://lore.kernel.org/r/20261007-ext4-fc-zeroout-v1-0-b86de6439431@samsung.com

---
Daejun Park (2):
      ext4: don't cache unzeroed blocks as written after a failed zeroout
      ext4: track zeroed out blocks of unwritten extents for fast commit

 fs/ext4/ext4.h         |  5 +++--
 fs/ext4/ext4_extents.h |  3 ++-
 fs/ext4/extents-test.c |  8 +++++---
 fs/ext4/extents.c      | 39 ++++++++++++++++++++++++++-------------
 fs/ext4/inode.c        | 25 +++++++++++++++++--------
 5 files changed, 53 insertions(+), 27 deletions(-)
---
base-commit: 9091c97be34083587a75db174aab51551d8e8543
change-id: 20261006-ext4-fc-zeroout-e429007c72a0

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

