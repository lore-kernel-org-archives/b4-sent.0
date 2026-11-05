From: Daejun Park <daejun7.park@samsung.com>
Subject: [PATCH 0/2] xfs: skip redundant fsync cache flushes
Date: Thu, 05 Nov 2026 11:49:11 +0900
Message-Id: <20261105-xfs-fsync-flush-seq-v1-0-299bdf5e28c3@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKfu62oC/x3MwQpAQBCA4VfRnE3ZEcmryEFrhiktdiKSd7c5f
 of/f8A4Khu02QORTzVdQ4LLM/DzECZGHZOBCqqdKyq8xFDsDh5lOWxG4x2bcmDyIjVRBancIot
 e/7Xr3/cDdFj4zWUAAAA=
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, Dave Chinner <david@fromorbit.com>, 
 "Darrick J. Wong" <djwong@kernel.org>, Amir Goldstein <amir73il@gmail.com>, 
 linux-kernel@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793846951; l=1069;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=NQTFHpwt987/Z9fZrwgqPjU/uEomGjhiNQuVS35MfSg=;
 b=gClUR6DwC9OlLGCYV3zCtSGOkNahTDwXNMleYmFnweN3OYmHQWaGf9QEv/NkVlg2rlCbwbcLO
 fDjF7tGe8BsDvFiJXGtL6b9+EX9ugIS+xA1V4i85LXlSml7rSrRK0ri
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Concurrent fsyncs often wait for an iclog that another task wrote out,
and then send their own cache flush. Patch 1 numbers the cache flushes
on each buftarg. Patch 2 uses the numbers to skip that flush when a
later flush has completed.

16 fio jobs of 4k append + fsync in a QEMU guest: 809 -> 4185
fsyncs/s. fstests -g quick shows no change, and a dm-log-writes crash
test lost no data (patch 2).

---
Daejun Park (2):
      xfs: number the cache flushes submitted to each buftarg
      xfs: skip the fsync flush when a later flush has completed

 fs/xfs/xfs_buf.c      | 39 +++++++++++++++++++++++++++++++++++++++
 fs/xfs/xfs_buf.h      | 40 ++++++++++++++++++++++++++++++++++++++++
 fs/xfs/xfs_file.c     | 21 +++++++++++++++------
 fs/xfs/xfs_log.c      | 25 +++++++++++++++++++------
 fs/xfs/xfs_log_priv.h |  1 +
 5 files changed, 114 insertions(+), 12 deletions(-)
---
base-commit: 1e17fc56469d62d1c1ac45c137a2456d14456f1d
change-id: 20261105-xfs-fsync-flush-seq-83ae2cff6225

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

