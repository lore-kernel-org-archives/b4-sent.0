From: Mark Korenberg <socketpair@gmail.com>
Date: Fri, 06 Nov 2026 22:33:09 +0500
Subject: [PATCH v2 1/2] btrfs: tag tree block repair writes with REQ_META
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-btrfs-sb-read-req-meta-v2-1-71c1afaf5c67@gmail.com>
References: <20261106-btrfs-sb-read-req-meta-v2-0-71c1afaf5c67@gmail.com>
In-Reply-To: <20261106-btrfs-sb-read-req-meta-v2-0-71c1afaf5c67@gmail.com>
To: David Sterba <dsterba@suse.com>, Chris Mason <mason@kernel.org>
Cc: Qu Wenruo <wqu@suse.com>, linux-btrfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Mark Korenberg <socketpair@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793986388; l=1104;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=YFyzH7lKR5afoL8KflpNwQVQtbrBLsyNhI5jTu4GvOI=;
 b=LRjo3+UMw8+Uy8gjTh53YtHvFCNT6N7/7K8GFHXitnuoTtAc8J97WHxEfKWx/uQ4POZDzrunT
 9u5k2VJl7DlB9efjzve4JIDeZSrmVrWTIPKnyRH5FqZAdDrsaZTQCcG
X-Developer-Key: i=socketpair@gmail.com; a=ed25519;
 pk=2iAMjWhs7kA9X8ccetT2YVX8dvniXua2okQogw3Don8=
X-Endpoint-Received: by B4 Relay for socketpair@gmail.com/20260603 with auth_id=806
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a tree block read finds a bad copy, btrfs_repair_eb_io_failure()
rewrites it from a good one through btrfs_repair_bbio_failure().  That
rewrite is a plain REQ_OP_WRITE | REQ_SYNC, while the read that found
the bad copy and all other tree block writes carry REQ_META.

Tag it with REQ_META when the bbio belongs to the btree inode.

Signed-off-by: Mark Korenberg <socketpair@gmail.com>
---
 fs/btrfs/bio.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/fs/btrfs/bio.c b/fs/btrfs/bio.c
index 2e12a6d7e16f..efbce4d549ff 100644
--- a/fs/btrfs/bio.c
+++ b/fs/btrfs/bio.c
@@ -951,7 +951,8 @@ int btrfs_repair_bbio_failure(struct btrfs_bio *bbio, const struct bvec_iter *or
 	}
 
 	repair_bio = bio_alloc(smap.dev->bdev, max(1, length >> PAGE_SHIFT),
-			       REQ_OP_WRITE | REQ_SYNC, GFP_NOFS);
+			       REQ_OP_WRITE | REQ_SYNC |
+			       (is_data_inode(inode) ? 0 : REQ_META), GFP_NOFS);
 	repair_bio->bi_iter.bi_sector = smap.physical >> SECTOR_SHIFT;
 	while (cur < length) {
 		struct page *page = bio_iter_page(&bbio->bio, iter);

-- 
2.56.0

