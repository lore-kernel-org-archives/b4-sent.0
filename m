From: Daejun Park <daejun7.park@samsung.com>
Subject: [PATCH v5 0/9] xfs: pNFS block layout fixes
Date: Thu, 29 Oct 2026 11:22:57 +0900
Message-Id: <20261029-xfs-pnfs-batch-v5-0-ef8d2eafb7fa@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAGu4moC/3XMQQ6CMBCF4auQrq0pQwviynsYF6VMoQsK6WCDI
 dzdwkpj3EzyT/K+lREGh8Su2coCRkdu9CnUKWOm175D7trUDASUucgVXyzxyafT6Nn0/KKkqiE
 XGrFhaTQFtG45wPsjde9oHsPr8GOxf/9SseCCK2lN1QDKsmpvpAd6+u5sxoHtWJQfAIgfQCagh
 kJYDUZLLb+BbdvenCpY+e8AAAA=
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, "Darrick J. Wong" <djwong@kernel.org>, 
 Dave Chinner <dgc@kernel.org>, Pankaj Raghav <p.raghav@samsung.com>, 
 Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Sergey Bashirov <sergeybashirov@gmail.com>, 
 Andrey Albershteyn <aalbersh@kernel.org>, linux-nfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793240577; l=3097;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=c/1TEndM7InozfzPWoIRGtybrwNWX1Xg1TAnNYOp1+w=;
 b=+Hhyw83TxI8HBGZoFKKAYZ5ZKpcWypWiqrKh4t6W7wio3bJbyDws59vEZFOTU1tWLU0qPm//I
 qF6I4tSSzeeBalOMkb+d7qFEdRypvTghDUpMls7MXTVTL0HZ8NHuXOt
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The XFS side of the pNFS block and SCSI layout fixes. A pNFS client
alone can trigger the bugs fixed by patches 1 and 3 to 6. Patch 7
closes a race with a local process writing to a shared mapping.
Patches 8 and 9 make a LAYOUTCOMMIT stable the way fdatasync does.

Patch 3 needs patch 2. Patch 4 should not go without patches 2 and 3,
and patch 6 not without patch 5. Patches 1 to 6 are marked for stable.
XFS_BMAPI_CONVERT_ONLY takes bit 12 of the bmapi flags, which the
fs-verity series [1] also uses.

Tested on nfsd-testing plus this series in QEMU guests. nfsd exported
XFS on an nvmet-tcp namespace to pynfs ([2] and local tests for patches
5 and 6) and the Linux client, with KASAN and lockdep and also with
XFS_DEBUG. fstests -g quick ran on a local XFS. Each patch builds with
W=1 on for-next.

[1] https://lore.kernel.org/r/20261002223705.2175542-14-aalbersh@kernel.org
[2] https://lore.kernel.org/r/20261014-pynfs-block-commit-v1-0-1723979f495f@samsung.com

---
Changes in v5:
- Cap the block count in xfs_iomap_write_direct() instead of
  xfs_fs_map_blocks().
- Clamp the layout length with min_t(), as min() rejects u64 against
  loff_t.
- Assert that XFS_BMAPI_CONVERT_ONLY allocated nothing.
- Shorter commit messages, with test results below the --- line.

Changes in v4:
- Limit a pNFS allocation to XFS_MAX_BMBT_EXTLEN blocks instead of
  refusing a count whose reservation would wrap.

Changes in v3:
- Post the XFS pNFS patches as one series.
- Split XFS_BMAPI_CONVERT_ONLY from its pNFS user.
- Return -ENOSR when nothing is mapped, and commit the transaction
  instead of cancelling it.
- Add the datasync arguments to xfs_log_force_inode() itself.

---
Daejun Park (9):
      xfs: mark the inode preallocated for pNFS write layouts past EOF
      xfs: add a flag to convert unwritten extents without allocating blocks
      xfs: refuse a pNFS LAYOUTCOMMIT of a range without blocks
      xfs: clamp a pNFS LAYOUTCOMMIT extent before computing its end
      xfs: cap the block count of xfs_iomap_write_direct() at one extent
      xfs: clamp the pNFS layout range to the maximum file size
      xfs: take the invalidate lock while mapping a pNFS layout
      xfs: add datasync and log_flushed arguments to xfs_log_force_inode()
      xfs: make pNFS LAYOUTCOMMIT stable the way fdatasync does

 fs/xfs/libxfs/xfs_bmap.c | 14 +++++++--
 fs/xfs/libxfs/xfs_bmap.h | 10 +++++-
 fs/xfs/xfs_export.c      |  2 +-
 fs/xfs/xfs_file.c        | 52 +++---------------------------
 fs/xfs/xfs_inode.c       | 36 ++++++++++++++++++---
 fs/xfs/xfs_inode.h       |  3 +-
 fs/xfs/xfs_ioend.c       |  2 +-
 fs/xfs/xfs_iomap.c       | 28 +++++++++++++++--
 fs/xfs/xfs_iomap.h       |  3 +-
 fs/xfs/xfs_pnfs.c        | 82 +++++++++++++++++++++++++++++++++---------------
 fs/xfs/xfs_zone_gc.c     |  2 +-
 11 files changed, 147 insertions(+), 87 deletions(-)
---
base-commit: ec8f62cc109a3f596b3c65dc0f1011c209239051
change-id: 20261015-xfs-pnfs-batch-85459210aeeb

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

