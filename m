From: Mark Korenberg <socketpair@gmail.com>
Date: Fri, 06 Nov 2026 22:33:10 +0500
Subject: [PATCH v2 2/2] btrfs: raid56: pass REQ_META to per-device bios
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-btrfs-sb-read-req-meta-v2-2-71c1afaf5c67@gmail.com>
References: <20261106-btrfs-sb-read-req-meta-v2-0-71c1afaf5c67@gmail.com>
In-Reply-To: <20261106-btrfs-sb-read-req-meta-v2-0-71c1afaf5c67@gmail.com>
To: David Sterba <dsterba@suse.com>, Chris Mason <mason@kernel.org>
Cc: Qu Wenruo <wqu@suse.com>, linux-btrfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Mark Korenberg <socketpair@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793986388; l=2479;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=03ZVHtjUEaKbOwy9y4lTSzoDh3nzlMUykXCapQogZXk=;
 b=lmkNKMF54ONzD8K3N1HX3MJFukSl6LQyyWTdJUAgRTxEkpZZkvKHFAymIAOODq1p9zMpYKpWB
 faiV3VpR9eHCr+P2H3pNfdOuqPsTYy4f1RgYMZR5ucHFxZPmrLP+JVP
X-Developer-Key: i=socketpair@gmail.com; a=ed25519;
 pk=2iAMjWhs7kA9X8ccetT2YVX8dvniXua2okQogw3Don8=
X-Endpoint-Received: by B4 Relay for socketpair@gmail.com/20260603 with auth_id=806
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

RAID5/6 writes, and reads that need a rebuild, go through an rbio,
which builds new per-device bios from a bare REQ_OP_READ or
REQ_OP_WRITE.  So all tree block writes on RAID5/6 lose REQ_META, while
on the other profiles the per-device bios are clones and keep it.  The
same goes for a tree block read rebuilt from the other stripes, for
example with a missing device.

Pass REQ_META on to all per-device bios of an rbio, data and P/Q alike,
if any bio it serves has it.  Scrub and relocation do not set REQ_META,
so their rbios stay untagged, as do rbios that only serve file data.

Signed-off-by: Mark Korenberg <socketpair@gmail.com>
---
 fs/btrfs/raid56.c | 14 +++++++++++---
 fs/btrfs/raid56.h |  7 +++++++
 2 files changed, 18 insertions(+), 3 deletions(-)

diff --git a/fs/btrfs/raid56.c b/fs/btrfs/raid56.c
index a8a8004bb14c..63b5acbf107e 100644
--- a/fs/btrfs/raid56.c
+++ b/fs/btrfs/raid56.c
@@ -1202,10 +1202,15 @@ static int rbio_add_io_paddrs(struct btrfs_raid_bio *rbio, struct bio_list *bio_
 		}
 	}
 
-	/* put a new bio on the list */
+	/*
+	 * Put a new bio on the list.  Every per-device bio, data and P/Q
+	 * alike, serves the bios in rbio->bio_list, so it is metadata I/O if
+	 * any of them is: a tree block write, or a tree block read rebuilt
+	 * from the other stripes.
+	 */
 	bio = bio_alloc(stripe->dev->bdev,
 			max(rbio->bioc->stripe_len >> PAGE_SHIFT, 1),
-			op, GFP_NOFS);
+			op | rbio->req_meta, GFP_NOFS);
 	bio->bi_iter.bi_sector = disk_start >> SECTOR_SHIFT;
 	bio->bi_private = rbio;
 
@@ -1246,8 +1251,11 @@ static void index_rbio_pages(struct btrfs_raid_bio *rbio)
 	struct bio *bio;
 
 	spin_lock(&rbio->bio_list_lock);
-	bio_list_for_each(bio, &rbio->bio_list)
+	rbio->req_meta = 0;
+	bio_list_for_each(bio, &rbio->bio_list) {
 		index_one_bio(rbio, bio);
+		rbio->req_meta |= bio->bi_opf & REQ_META;
+	}
 
 	spin_unlock(&rbio->bio_list_lock);
 }
diff --git a/fs/btrfs/raid56.h b/fs/btrfs/raid56.h
index 8700910b8dc9..a5a0ff8e4a03 100644
--- a/fs/btrfs/raid56.h
+++ b/fs/btrfs/raid56.h
@@ -139,6 +139,13 @@ struct btrfs_raid_bio {
 	 */
 	enum btrfs_rbio_ops operation;
 
+	/*
+	 * REQ_META if any bio in bio_list has it.  Set under bio_list_lock by
+	 * index_rbio_pages(), which runs before every assembly of per-device
+	 * bios.
+	 */
+	blk_opf_t req_meta;
+
 	/* How many pages there are for the full stripe including P/Q */
 	u16 nr_pages;
 

-- 
2.56.0

