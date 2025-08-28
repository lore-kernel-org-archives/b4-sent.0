From: Nikita Ofitserov <himikof@gmail.com>
Date: Thu, 28 Aug 2025 17:16:04 +0300
Subject: [PATCH v2 02/15] bcachefs: Refactor bch2_gc_btree/bch2_gc_btrees
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250828-better-progress-v2-2-c088a2003940@gmail.com>
References: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
In-Reply-To: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1558; i=himikof@gmail.com;
 h=from:subject:message-id; bh=oDcgd9+Tw5O6XEbdGPb3cpQkJo1A036cADXhKke/lEI=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWRsSDm4VmzdHM77gr8iLXhaFmpHTPYpkHcrEPxkGdwTz
 cktpP+no5SFQYyLQVZMkeXDkq9/1mRa/7EU2msIM4eVCWQIAxenAEwkOoSR4c9iy6wXLKfi0z55
 +h64Wnr+dsbZ7Sy9p8TvPNxsEK6/N4SRoW3tC88YvqSrKqt5Gqe9mHmdZ+v/Q7+6U01jnKWiBKJ
 rmQA=
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Concentrate iteration policy inside the caller so that accurate
progress reporting would be possible.

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
 fs/bcachefs/btree_gc.c | 11 ++++-------
 1 file changed, 4 insertions(+), 7 deletions(-)

diff --git a/fs/bcachefs/btree_gc.c b/fs/bcachefs/btree_gc.c
index 2b1b6b7ffdf0af7ec0bf4cbaf68cc9a53a20cfce..2a369aebdbe216ed665115e27388ab4821696bf8 100644
--- a/fs/bcachefs/btree_gc.c
+++ b/fs/bcachefs/btree_gc.c
@@ -717,16 +717,12 @@ static int bch2_gc_mark_key(struct btree_trans *trans, enum btree_id btree_id,
 
 static int bch2_gc_btree(struct btree_trans *trans,
 			 struct progress_indicator_state *progress,
-			 enum btree_id btree, bool initial)
+			 enum btree_id btree, unsigned target_depth,
+			 bool initial)
 {
 	struct bch_fs *c = trans->c;
-	unsigned target_depth = BIT_ULL(btree) & btree_leaf_has_triggers_mask ? 0 : 1;
 	int ret = 0;
 
-	/* We need to make sure every leaf node is readable before going RW */
-	if (initial)
-		target_depth = 0;
-
 	for (unsigned level = target_depth; level < BTREE_MAX_DEPTH; level++) {
 		struct btree *prev = NULL;
 		struct btree_iter iter;
@@ -797,7 +793,8 @@ static int bch2_gc_btrees(struct bch_fs *c)
 		if (IS_ERR_OR_NULL(bch2_btree_id_root(c, btree)->b))
 			continue;
 
-		ret = bch2_gc_btree(trans, &progress, btree, true);
+		/* We need to make sure every leaf node is readable before going RW */
+		ret = bch2_gc_btree(trans, &progress, btree, 0, true);
 	}
 
 	bch_err_fn(c, ret);

-- 
2.50.1

