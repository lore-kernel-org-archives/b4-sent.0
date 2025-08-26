From: Nikita Ofitserov <himikof@gmail.com>
Date: Wed, 27 Aug 2025 01:49:16 +0300
Subject: [PATCH 10/12] bcachefs: Improve check_allocations pass speed not
 in fsck
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250827-better-progress-v1-10-74c24de7988a@gmail.com>
References: <20250827-better-progress-v1-0-74c24de7988a@gmail.com>
In-Reply-To: <20250827-better-progress-v1-0-74c24de7988a@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1395; i=himikof@gmail.com;
 h=from:subject:message-id; bh=WSNOd5gV6NmNyQNbSGutydt83aC8FZuQ9bqlIo3aZ8o=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWSss5Jdv4/5fMBGrp9TPzHrftzxw6zcu0KK1+hw2DOLu
 tLGzUdXd5SyMIhxMciKKbJ8WPL1z5pM6z+WQnsNYeawMoEMYeDiFICJfGFmZJjOcui6nX/j3eCb
 ziKHeJVMqrr8GGUNtqu+tP79dP+tNeKMDK+uy/LxXRGTWB3/OlPaeleq26MobWMewUsdh4r1zR6
 /YwUA
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
index b89e12a3112868f175d028ce9745c8b4944ca747..c04e88ec5c0ac73c21f01db597b19d1b0c798299 100644
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

