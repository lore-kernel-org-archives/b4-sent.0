From: Daejun Park <daejun7.park@samsung.com>
Subject: [PATCH v2 0/3] erofs: bound file-backed mount nesting and use a
 bio_set for requests
Date: Tue, 03 Nov 2026 15:29:30 +0900
Message-Id: <20261103-erofs-fileio-bioset-v2-0-5b91af423f72@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEp/6WoC/12OOw7CMBBErxK5ZpEdA06ouAei8GcNKyBG3hCBU
 O6OidKE8o00b+YjGDMhi331ERkHYkpdgXpVCX+x3RmBQmFRy3qnZN0C5hQZIt2QEjhKjD0Ypbd
 GuqYNTStK85Ex0muyHk+FL8R9yu9pZFC/dPZpOfu4t/6KAfDVZwuhHPHIMChQoNtoQjTWS+UOb
 O/87M5rn+6/oT/L8tXU9jZujA3OaasX7dM4jl/k/vQf/gAAAA==
To: Gao Xiang <xiang@kernel.org>, Chao Yu <chao@kernel.org>
Cc: Yue Hu <zbestahu@gmail.com>, Jingbo Xu <jefflexu@163.com>, 
 Sandeep Dhavale <dhavale@google.com>, Hongbo Li <hongbohbli@tencent.com>, 
 Chunhai Guo <guochunhai@vivo.com>, linux-erofs@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>, 
 Sashiko <sashiko-bot@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793687370; l=1630;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=xHyr8ZsDIYNONpUNcHNkNV4xyWK3+xLjfOqRcIe3HUY=;
 b=EcuOXlce50tx7+rrDgy6bnPyjh0auWDBQQywZeMsU4+Zsaz/XR9OPcPta1/E4yn9dDE6/wJ+6
 4S0oShmqC1AADDfl+6vEGJ4j5NYB936pbVYiBfBzfy/YSGtfPlGB3eh
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

File-backed EROFS mounts cap each request at 16 bvecs. A larger
readahead window then takes several backing reads. This series
allocates file-backed requests from a bio_set to hold up to
BIO_MAX_VECS bvecs per request.

All file-backed mounts share that bio_set mempool. Patches 1 and 2
first close two ways for file-backed mounts to nest past the stacked
fs check: extra devices, and files shared by inode_share. Patch 3 then
switches request allocation to the bio_set. Without the mm readahead
alignment patch, larger backing reads slow some buffered reads.

Tested in a QEMU guest with KASAN:
- Images and device= blobs shared by inode_share are rejected. So is
  an image after a remount clears inode_share.
- Unshared files still mount.

---
Changes in v2:
- New patch 2 for inode_share, reported by Sashiko. It checks the
  file, not the option, which a remount can clear.
- Patch 3 no longer says "does not fail", nor that a backing read
  cannot reach the pool again in the same task.

---
Daejun Park (3):
      erofs: apply the stacked fs check to extra file-backed devices
      erofs: treat files shared by inode_share as stacked
      erofs: allocate file-backed mount requests from a bio_set

 fs/erofs/fileio.c   | 47 +++++++++++++++++++++++++++++++++++------------
 fs/erofs/internal.h |  4 ++++
 fs/erofs/super.c    | 30 +++++++++++++++++++++++++++---
 3 files changed, 66 insertions(+), 15 deletions(-)
---
base-commit: 209108a5456171ab430e25b54b2dfe083455bfb6
change-id: 20261029-erofs-fileio-bioset-713570b89d89

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

