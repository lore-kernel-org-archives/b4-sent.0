From: Daejun Park <daejun7.park@samsung.com>
Subject: [PATCH v2 0/2] xfs: skip redundant fsync cache flushes
Date: Wed, 11 Nov 2026 12:17:10 +0900
Message-Id: <20261111-xfs-fsync-flush-seq-v2-0-b5c00c25d276@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADbe82oC/32NQQ6CQAxFr0K6toYpgYAr72FY4NDCJDLIVAiEc
 HdHDuDyveS/v4NycKxwS3YIvDh1o49AlwRs3/iO0bWRgVIqjElzXEVRdPMW5TVrj8oTllnDZEU
 Kohzi8h1Y3HpWH3Xk3ulnDNt5spif/d9bDKZIVfVsJWcqbXbXZtDZd1c7DlAfx/EFdgYRZrgAA
 AA=
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, Dave Chinner <david@fromorbit.com>, 
 "Darrick J. Wong" <djwong@kernel.org>, Amir Goldstein <amir73il@gmail.com>, 
 Brian Foster <bfoster@redhat.com>, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794367030; l=1829;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=c4BWBwBKwkn74Ov6XMf6CjVsk1F8tqFkdQIPCAjSv4w=;
 b=ZLCHVLmcQn7q5tXwuxyvwaz6vsXPLFdxDMUFZLVPgOA7X+r9TAs/5MTtqOZ4/XN+AL1GolO2b
 V40e8hp1lqTDZ/cX3Bc/KdIZbERy3JFUYZtJZ7Htirh+5kKz8PyDJ0Y
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Concurrent fsyncs often wait for an iclog that another task wrote out,
and then send their own cache flush. Patch 1 numbers the cache flushes
on each buftarg. Patch 2 uses the numbers to skip that flush when a
later flush has completed.

16 fio jobs of 4k append + fsync in a QEMU guest: 1111 -> 4498
fsyncs/s. fstests -g quick shows no change, and a dm-log-writes crash
test on an internal log lost no data (patch 2).

---
Changes in v2:
- Zero ic_flush_seq after the bio setup and take the flush number
  where REQ_PREFLUSH is set
- Move the fio result into the commit log of patch 2, measured again
  for both kernels on the new base, and add the single job result
- Rename the argument of xfs_buftarg_flushed_since() and the fsync
  local to submit_seq, and describe the submit and completion ordering
  in the comments
- Keep the fsync comment on why the flush is needed
- In patch 2, shorten the DAX text in the comment and the commit log,
  and drop the commit log sentence on numbering the fsync's own flush
- Say below --- of patch 2 what changes for a failed flush on
  bio-based dm
- Rebase onto the current for-next (v7.4-rc2)

---
Daejun Park (2):
      xfs: number the cache flushes submitted to each buftarg
      xfs: skip the fsync flush when a later flush has completed

 fs/xfs/xfs_buf.c      | 40 ++++++++++++++++++++++++++++++++++++++++
 fs/xfs/xfs_buf.h      | 43 +++++++++++++++++++++++++++++++++++++++++++
 fs/xfs/xfs_file.c     | 18 +++++++++++++++---
 fs/xfs/xfs_log.c      | 28 +++++++++++++++++++++-------
 fs/xfs/xfs_log_priv.h |  1 +
 5 files changed, 120 insertions(+), 10 deletions(-)
---
base-commit: 48326a2382d80715475d10ce98734ac65d2d2150
change-id: 20261105-xfs-fsync-flush-seq-83ae2cff6225

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

