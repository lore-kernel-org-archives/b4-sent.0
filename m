From: Daejun Park <daejun7.park@samsung.com>
Subject: [PATCH v2 0/2] exportfs, xfs, nfsd: map a whole pNFS block layout
 in one ->map_blocks call
Date: Thu, 26 Nov 2026 10:52:24 +0900
Message-Id: <20261126-xfs-nfsd-map-blocks-v2-0-6d85b1388739@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANiQB2sC/32NTQ6CMBSEr0Le2mfaBqpx5T0Ii/4BjbYlfUowp
 He3cgCX32Tmmx3IZe8Ibs0O2a2efIoVxKkBM6s4OfS2MggmJGfsittIGEeyGNSC+pnMg7DlF9t
 pqZRrBdTlkt3ot8PaD5VnT6+UP8fJyn/pf9/KkWEnWe0Ya4yWd1KB3nE6mxRgKKV8AbAM9Le4A
 AAA
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>, 
 Christoph Hellwig <hch@lst.de>, Carlos Maiolino <cem@kernel.org>, 
 Amir Goldstein <amir73il@gmail.com>
Cc: "Darrick J. Wong" <djwong@kernel.org>, Dave Chinner <dgc@kernel.org>, 
 Sergey Bashirov <sergeybashirov@gmail.com>, 
 Christian Brauner <brauner@kernel.org>, linux-nfs@vger.kernel.org, 
 linux-xfs@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795657944; l=1642;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=CHe9NdNoNWMN3OZLg6eYv1P0qljzfmwefVyC+JLRYlU=;
 b=Z1FcxTUa6ywlKOAf0WRvfAHZbKqu+vWqFtZRcueStNEhUsXV3vakq9dGoNWDBwzG/KlU8r7Q7
 seKi7tbjqBQCux9qLbNB9S3rpkBy3JzalZsPbA2BSFwjjDr8yGL9zQL
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nfsd gets a pNFS block layout from XFS with one ->map_blocks call per
extent. Patch 2 lets one call return all of them, as Christoph and
Darrick suggested, and patch 1 prepares XFS for it. fstests and pynfs
give the same results with and without the series.

The series needs four fixes. The first two are posted separately, and
the other two are in nfsd-testing:

- nfsd: stop a block layout at the maximum file size
- xfs: punch delalloc blocks past EOF before mapping a pNFS layout
- nfsd: do not return overlapping extents in a block layout
- nfsd: do not allocate blocks for an RW layout with a minlength of zero

Once they are in mainline, I will rebase the series for the VFS tree,
as Chuck suggested.

Changes in v2:
- Drop v1 patches 1-3 and 6, now in mainline (2 in another form).
- Fold the interface, the XFS loop and the nfsd caller into one patch.
- Allocate the mapping array with kvmalloc (Chuck).
- Keep nfsd's trim of a mapping that starts below the offset, instead
  of refusing it.

---
Daejun Park (2):
      xfs: factor the mapping of one pNFS extent out of xfs_fs_map_blocks()
      exportfs, xfs, nfsd: map a whole pNFS block layout in one ->map_blocks call

 fs/nfsd/blocklayout.c          | 137 ++++++++++++++++++----------------
 fs/xfs/xfs_pnfs.c              | 163 +++++++++++++++++++++++++----------------
 include/linux/exportfs_block.h |  17 +++--
 3 files changed, 187 insertions(+), 130 deletions(-)
---
base-commit: 25527067098f9d95562244fd64749ebaae3077f9
change-id: 20261008-xfs-nfsd-map-blocks-417d5b6aae42

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

