From: Nikita Ofitserov <himikof@gmail.com>
Date: Wed, 27 Aug 2025 01:49:12 +0300
Subject: [PATCH 06/12] bcachefs: Refactor/rename btree_type_has_ptrs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250827-better-progress-v1-6-74c24de7988a@gmail.com>
References: <20250827-better-progress-v1-0-74c24de7988a@gmail.com>
In-Reply-To: <20250827-better-progress-v1-0-74c24de7988a@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3458; i=himikof@gmail.com;
 h=from:subject:message-id; bh=FQPiPFfaFbnjVux/gGFuoIpp03FQldNcu72MZxMYc9k=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWSss5KRi5u9hss/eum6ddtMEmvkS2+c37hNwTBPcvs87
 mV9BeebOkpZGMS4GGTFFFk+LPn6Z02m9R9Lob2GMHNYmUCGMHBxCsBEvBkZGS4WFzH/brnPfmmV
 y4aU3TGTFTL95rQqTZXiPbuQi/Hrcl9Ghq3n5B5uPiIgcubgtrmJ2zkXlpvo+0Vl32xRq5u+N/V
 hDCcA
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The new name (btree_type_has_data_ptrs) better reflects the meaning.
Also introduce the explicit mask constant.

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
 fs/bcachefs/backpointers.c | 2 +-
 fs/bcachefs/btree_gc.c     | 2 +-
 fs/bcachefs/btree_types.h  | 8 ++++----
 fs/bcachefs/migrate.c      | 2 +-
 fs/bcachefs/move.c         | 2 +-
 5 files changed, 8 insertions(+), 8 deletions(-)

diff --git a/fs/bcachefs/backpointers.c b/fs/bcachefs/backpointers.c
index cb25cddb759b84bed48c653605ba195218f2140c..0d585e5662be3f02580558e9a590075ea73193d5 100644
--- a/fs/bcachefs/backpointers.c
+++ b/fs/bcachefs/backpointers.c
@@ -809,7 +809,7 @@ static int bch2_check_extents_to_backpointers_pass(struct btree_trans *trans,
 	for (enum btree_id btree_id = 0;
 	     btree_id < btree_id_nr_alive(c);
 	     btree_id++) {
-		int level, depth = btree_type_has_ptrs(btree_id) ? 0 : 1;
+		int level, depth = btree_type_has_data_ptrs(btree_id) ? 0 : 1;
 
 		ret = commit_do(trans, NULL, NULL,
 				BCH_TRANS_COMMIT_no_enospc,
diff --git a/fs/bcachefs/btree_gc.c b/fs/bcachefs/btree_gc.c
index 2b1b6b7ffdf0af7ec0bf4cbaf68cc9a53a20cfce..006bdd5c90bc805219d4e38923135986425ccf17 100644
--- a/fs/bcachefs/btree_gc.c
+++ b/fs/bcachefs/btree_gc.c
@@ -1228,7 +1228,7 @@ int bch2_gc_gens(struct bch_fs *c)
 	}
 
 	for (unsigned i = 0; i < BTREE_ID_NR; i++)
-		if (btree_type_has_ptrs(i)) {
+		if (btree_type_has_data_ptrs(i)) {
 			c->gc_gens_btree = i;
 			c->gc_gens_pos = POS_MIN;
 
diff --git a/fs/bcachefs/btree_types.h b/fs/bcachefs/btree_types.h
index ad9bd18fe9b6e51987da74d373830dca98df56ec..d06991c16d5c24c586e9449efa9553e2b8593bd4 100644
--- a/fs/bcachefs/btree_types.h
+++ b/fs/bcachefs/btree_types.h
@@ -886,15 +886,15 @@ static inline bool btree_type_has_snapshot_field(enum btree_id btree)
 	return BIT_ULL(btree) & mask;
 }
 
-static inline bool btree_type_has_ptrs(enum btree_id btree)
-{
-	const u64 mask = 0
+static const u64 btree_has_data_ptrs_mask = 0
 #define x(name, nr, flags, ...)	|((!!((flags) & BTREE_IS_data)) << nr)
 	BCH_BTREE_IDS()
 #undef x
 	;
 
-	return BIT_ULL(btree) & mask;
+static inline bool btree_type_has_data_ptrs(enum btree_id btree)
+{
+	return BIT_ULL(btree) & btree_has_data_ptrs_mask;
 }
 
 static inline bool btree_type_uses_write_buffer(enum btree_id btree)
diff --git a/fs/bcachefs/migrate.c b/fs/bcachefs/migrate.c
index 892990b4a6a6b16785e5030e5dc7cf15b05c0fc5..41657deb0e3807f4968272491faea09d05ec2299 100644
--- a/fs/bcachefs/migrate.c
+++ b/fs/bcachefs/migrate.c
@@ -122,7 +122,7 @@ static int bch2_dev_usrdata_drop(struct bch_fs *c,
 	CLASS(btree_trans, trans)(c);
 
 	for (unsigned id = 0; id < BTREE_ID_NR; id++) {
-		if (!btree_type_has_ptrs(id))
+		if (!btree_type_has_data_ptrs(id))
 			continue;
 
 		/* Stripe keys have pointers, but are handled separately */
diff --git a/fs/bcachefs/move.c b/fs/bcachefs/move.c
index 62aeb54ef11b33814f2d06e5ec2787b656a67c30..c30e74a3f89450b08b3a8b89a863752611482c69 100644
--- a/fs/bcachefs/move.c
+++ b/fs/bcachefs/move.c
@@ -671,7 +671,7 @@ static int bch2_move_data(struct bch_fs *c,
 		unsigned min_depth_this_btree = min_depth;
 
 		/* Stripe keys have pointers, but are handled separately */
-		if (!btree_type_has_ptrs(id) ||
+		if (!btree_type_has_data_ptrs(id) ||
 		    id == BTREE_ID_stripes)
 			min_depth_this_btree = max(min_depth_this_btree, 1);
 

-- 
2.50.1

