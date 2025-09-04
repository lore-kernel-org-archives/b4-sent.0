From: Nikita Ofitserov <himikof@gmail.com>
Date: Thu, 04 Sep 2025 08:20:38 +0300
Subject: [PATCH v3 7/7] bcachefs: More accurate progress reporting for
 inner node iteration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250904-better-progress-v3-7-6cc4edf543f4@gmail.com>
References: <20250904-better-progress-v3-0-6cc4edf543f4@gmail.com>
In-Reply-To: <20250904-better-progress-v3-0-6cc4edf543f4@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2388; i=himikof@gmail.com;
 h=from:subject:message-id; bh=0y6FqhvH4YgWJi6ZMAsnk4E4uWmbuAqR+vZzxFZ2CqY=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWTsVPy5ztFi7cevlh9WFnetubhh6r47F81umXGaqF8RP
 X3KU2DB545SFgYxLgZZMUWWD0u+/lmTaf3HUmivIcwcViaQIQxcnAIwkYc8jAxTs16s8Do4sSZz
 t4hx5TLWzYqviuurL0z4uDO7bjOTCyMvI8P+TS6Xut8XXxBImP1ittxT2bYYR/6dOsZbNheUCq6
 VM2UCAA==
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
 fs/bcachefs/backpointers.c |  4 +++-
 fs/bcachefs/btree_gc.c     |  2 +-
 fs/bcachefs/migrate.c      | 13 +++++++++----
 3 files changed, 13 insertions(+), 6 deletions(-)

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
index 2338feb8d8ed4bad85a01a6b9181116d918636b5..c04e88ec5c0ac73c21f01db597b19d1b0c798299 100644
--- a/fs/bcachefs/btree_gc.c
+++ b/fs/bcachefs/btree_gc.c
@@ -780,7 +780,7 @@ static int bch2_gc_btrees(struct bch_fs *c)
 	int ret = 0;
 
 	struct progress_indicator_state progress;
-	bch2_progress_init(&progress, c, ~0ULL);
+	bch2_progress_init_inner(&progress, c, ~0ULL, ~0ULL);
 
 	enum btree_id ids[BTREE_ID_NR];
 	for (unsigned i = 0; i < BTREE_ID_NR; i++)
diff --git a/fs/bcachefs/migrate.c b/fs/bcachefs/migrate.c
index 8a3981e1016edd3357fa45428c7a28bbb1057ad7..e1bca93294ca5f1badb17c8a6aa71c31c3d78443 100644
--- a/fs/bcachefs/migrate.c
+++ b/fs/bcachefs/migrate.c
@@ -273,10 +273,15 @@ int bch2_dev_data_drop(struct bch_fs *c, unsigned dev_idx,
 		       unsigned flags, struct printbuf *err)
 {
 	struct progress_indicator_state progress;
+	int ret;
+
 	bch2_progress_init(&progress, c,
-			   BIT_ULL(BTREE_ID_extents)|
-			   BIT_ULL(BTREE_ID_reflink));
+			   btree_has_data_ptrs_mask & ~BIT_ULL(BTREE_ID_stripes));
+
+	if ((ret = bch2_dev_usrdata_drop(c, &progress, dev_idx, flags, err)))
+		return ret;
+
+	bch2_progress_init_inner(&progress, c, 0, ~0ULL);
 
-	return bch2_dev_usrdata_drop(c, &progress, dev_idx, flags, err) ?:
-		bch2_dev_metadata_drop(c, &progress, dev_idx, flags, err);
+	return bch2_dev_metadata_drop(c, &progress, dev_idx, flags, err);
 }

-- 
2.50.1

