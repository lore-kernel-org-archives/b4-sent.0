From: Nikita Ofitserov <himikof@gmail.com>
Date: Wed, 27 Aug 2025 01:49:13 +0300
Subject: [PATCH 07/12] bcachefs: More accurate progress reporting for inner
 node iteration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250827-better-progress-v1-7-74c24de7988a@gmail.com>
References: <20250827-better-progress-v1-0-74c24de7988a@gmail.com>
In-Reply-To: <20250827-better-progress-v1-0-74c24de7988a@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3496; i=himikof@gmail.com;
 h=from:subject:message-id; bh=+yss3zKdgUo3M11y90XdgozWvwalA2Ur+GHO8RDFz14=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWSss5J5cuXmrKkLp5oKb7i//pfdkes9J8JrRJZGX92yx
 36C1wIdtY5SFgYxLgZZMUWWD0u+/lmTaf3HUmivIcwcViaQIQxcnAIwkYlfGf6neZs82bUqPNq6
 TTRm0bmihGe2odd3TlIQ8VGI0WJrfbKNkWH/r9a8Nj5pyXuHLt78Uv3ol9v0yW3fpNLmXHf//If
 h3iZmAA==
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
 fs/bcachefs/backpointers.c |  4 +++-
 fs/bcachefs/btree_gc.c     | 13 +++++--------
 fs/bcachefs/migrate.c      | 13 +++++++++----
 3 files changed, 17 insertions(+), 13 deletions(-)

diff --git a/fs/bcachefs/backpointers.c b/fs/bcachefs/backpointers.c
index 0d585e5662be3f02580558e9a590075ea73193d5..42370aebb7a442ee368df323eb1f4970f2e5f949 100644
--- a/fs/bcachefs/backpointers.c
+++ b/fs/bcachefs/backpointers.c
@@ -804,7 +804,9 @@ static int bch2_check_extents_to_backpointers_pass(struct btree_trans *trans,
 	struct progress_indicator_state progress;
 	int ret = 0;
 
-	bch2_progress_init(&progress, trans->c, BIT_ULL(BTREE_ID_extents)|BIT_ULL(BTREE_ID_reflink));
+	bch2_progress_init_inner(&progress, trans->c,
+		btree_has_data_ptrs_mask,
+		~0ULL);
 
 	for (enum btree_id btree_id = 0;
 	     btree_id < btree_id_nr_alive(c);
diff --git a/fs/bcachefs/btree_gc.c b/fs/bcachefs/btree_gc.c
index 006bdd5c90bc805219d4e38923135986425ccf17..b89e12a3112868f175d028ce9745c8b4944ca747 100644
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
@@ -784,7 +780,7 @@ static int bch2_gc_btrees(struct bch_fs *c)
 	int ret = 0;
 
 	struct progress_indicator_state progress;
-	bch2_progress_init(&progress, c, ~0ULL);
+	bch2_progress_init_inner(&progress, c, ~0ULL, ~0ULL);
 
 	enum btree_id ids[BTREE_ID_NR];
 	for (unsigned i = 0; i < BTREE_ID_NR; i++)
@@ -797,7 +793,8 @@ static int bch2_gc_btrees(struct bch_fs *c)
 		if (IS_ERR_OR_NULL(bch2_btree_id_root(c, btree)->b))
 			continue;
 
-		ret = bch2_gc_btree(trans, &progress, btree, true);
+		/* We need to make sure every leaf node is readable before going RW */
+		ret = bch2_gc_btree(trans, &progress, btree, 0, true);
 	}
 
 	bch_err_fn(c, ret);
diff --git a/fs/bcachefs/migrate.c b/fs/bcachefs/migrate.c
index 41657deb0e3807f4968272491faea09d05ec2299..0ef576ec45c7310423cf7cdf902cad30dba257db 100644
--- a/fs/bcachefs/migrate.c
+++ b/fs/bcachefs/migrate.c
@@ -265,10 +265,15 @@ int bch2_dev_data_drop_by_backpointers(struct bch_fs *c, unsigned dev_idx, unsig
 int bch2_dev_data_drop(struct bch_fs *c, unsigned dev_idx, unsigned flags)
 {
 	struct progress_indicator_state progress;
+	int ret;
+
 	bch2_progress_init(&progress, c,
-			   BIT_ULL(BTREE_ID_extents)|
-			   BIT_ULL(BTREE_ID_reflink));
+			   btree_has_data_ptrs_mask & ~BIT_ULL(BTREE_ID_stripes));
+
+	if ((ret = bch2_dev_usrdata_drop(c, &progress, dev_idx, flags)))
+		return ret;
+
+	bch2_progress_init_inner(&progress, c, 0, ~0ULL);
 
-	return bch2_dev_usrdata_drop(c, &progress, dev_idx, flags) ?:
-		bch2_dev_metadata_drop(c, &progress, dev_idx, flags);
+	return bch2_dev_metadata_drop(c, &progress, dev_idx, flags);
 }

-- 
2.50.1

