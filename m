From: Nikita Ofitserov <himikof@gmail.com>
Date: Thu, 28 Aug 2025 17:16:05 +0300
Subject: [PATCH v2 03/15] bcachefs: Improve check_allocations pass speed
 when not in fsck
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250828-better-progress-v2-3-c088a2003940@gmail.com>
References: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
In-Reply-To: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1395; i=himikof@gmail.com;
 h=from:subject:message-id; bh=LsH3HjIJ0C6BLAOki5osq6Lc4dYBqwtI+Ym2pal9WXY=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWRsSDn4PGbb/ECF3AdPCmf5cSr//Bf39f7mx0EP4qZue
 H3Y9E7qpo5SFgYxLgZZMUWWD0u+/lmTaf3HUmivIcwcViaQIQxcnAIwkbRdDH+lJvy1XLB9QeXa
 Neuln7/17/dSfqPgpSO4xm2ivL2EZr8+w//6GQ9X1Fn9eVC0ilVPQn92/v2S8zLrFbYnv+6rPXF
 F9RcrAA==
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Skip reading unnecessary leaf btree nodes unless running fsck.
For example, this should speed up version upgrade/downgrade when
rebuilding accounting information.

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
 fs/bcachefs/btree_gc.c | 17 +++++++++++++++--
 1 file changed, 15 insertions(+), 2 deletions(-)

diff --git a/fs/bcachefs/btree_gc.c b/fs/bcachefs/btree_gc.c
index 2a369aebdbe216ed665115e27388ab4821696bf8..b95a3610900de2eecf978c62f3809453455f7a5c 100644
--- a/fs/bcachefs/btree_gc.c
+++ b/fs/bcachefs/btree_gc.c
@@ -793,8 +793,21 @@ static int bch2_gc_btrees(struct bch_fs *c)
 		if (IS_ERR_OR_NULL(bch2_btree_id_root(c, btree)->b))
 			continue;
 
-		/* We need to make sure every leaf node is readable before going RW */
-		ret = bch2_gc_btree(trans, &progress, btree, 0, true);
+
+		unsigned target_depth = BIT_ULL(btree) & btree_leaf_has_triggers_mask ? 0 : 1;
+
+		/*
+		 * In fsck, we need to make sure every leaf node is readable
+		 * before going RW, otherwise we can no longer rewind inside
+		 * btree_lost_data to repair during the current fsck run.
+		 *
+		 * Otherwise, we can delay the repair to the next
+		 * mount or offline fsck.
+		 */
+		if (test_bit(BCH_FS_in_fsck, &c->flags))
+			target_depth = 0;
+
+		ret = bch2_gc_btree(trans, &progress, btree, target_depth, true);
 	}
 
 	bch_err_fn(c, ret);

-- 
2.50.1

