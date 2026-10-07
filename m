From: Daejun Park <daejun7.park@samsung.com>
Subject: [PATCH 0/2] ext4: fix fast commit and extent status after
 unwritten extent zero-out
Date: Wed, 07 Oct 2026 09:41:19 +0900
Message-Id: <20261007-ext4-fc-zeroout-v1-0-b86de6439431@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAC+VxWoC/x3MQQqAIBBA0avIrBuYJJK6SrQIG2s2GmoRhXdPW
 r7F/y8kjsIJRvVC5EuSBF/RNgrsvviNUdZq0KT7lqhHvnOHzuLDMYQzI3d6IDLW6IWgVkdkJ/d
 /nOZSPvlk5G9hAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791333679; l=2396;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=8F9GJMv3WTxZjI1Rk1NLaQRRVl0LopGzPbJ88DUUPZw=;
 b=/YkCKYdsa6j3xDyVIOKw7GHwwaFkrVXKMcE9hsv/SUX2Ug0nWmTQhTjKguF1Joo4Ep8RZVOSC
 b6YxKqDly2eBKTzPXuOIzIhiZl0nCthtHup8zICTQP72ytRpuPUb2aQ
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

2/2 depends on 1/2. With 2/2 alone, the blocks that failed to zero out
are tracked as well, and fast commit replay converts them to written on
disk, so the old contents survive the crash: with the dm-error
reproducer described in 1/2, block 1 reads back as old data after
replay on a kernel with only 2/2, and as zeroes with both patches.

Tested in QEMU on ext4 dev 9091c97be340 plus this series:
 - the reproducer described in 2/2, with -o nodelalloc and with
   -o dioread_lock, also on a PROVE_LOCKING and DEBUG_ATOMIC_SLEEP kernel
   (no report), and the dm-error reproducer described in 1/2;
 - xfstests ext4/044 ext4/045 generic/455 generic/456 generic/482 with
   -O fast_commit, with and without -o nodelalloc: the same results as
   without the series (generic/455 fails on both, at different marks);
 - the ext4 KUnit tests, 72 of 72, including the split cases that zero
   out. They are the only ones to reach the second hunk of 2/2, and they
   run without fast commit, so its tracking is not exercised.

For stable: 2/2 needs ext4_split_extent_zeroout(), which came in 7.0,
hence "# 7.0.x". Before that only its ext4_zeroout_es() part applies.

---
Daejun Park (2):
      ext4: don't cache unzeroed blocks as written after a failed zeroout
      ext4: track zeroed out blocks of unwritten extents for fast commit

 fs/ext4/extents.c | 29 ++++++++++++++++++++++++-----
 1 file changed, 24 insertions(+), 5 deletions(-)
---
base-commit: 9091c97be34083587a75db174aab51551d8e8543
change-id: 20261006-ext4-fc-zeroout-e429007c72a0

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

