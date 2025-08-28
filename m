From: Nikita Ofitserov <himikof@gmail.com>
Date: Thu, 28 Aug 2025 17:16:17 +0300
Subject: [PATCH v2 15/15] bcachefs: More accurate progress reporting for
 inner node iteration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250828-better-progress-v2-15-c088a2003940@gmail.com>
References: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
In-Reply-To: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2418; i=himikof@gmail.com;
 h=from:subject:message-id; bh=2Gi9QvTlP0kPo5mlJKbmm3EH65uDXG8So4G6gHv9ydM=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWRsSDmUeLl6j+bDX7lqgc9W/A1oTlmk+IvpQb0r54ZFJ
 /gNlW+ldZSyMIhxMciKKbJ8WPL1z5pM6z+WQnsNYeawMoEMYeDiFICJOC5i+KeS3lPjLxyeE3G/
 98+03y9zTlXeNm/dwx7zrNnI+EjL+n+MDF8FORrjsv4/OPN8T5r5kjsr3p/1c6mIvz3No8wn7sK
 CaQwA
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
index 4aa7dd483cab5a400974b5824bfaf0c0af2e9331..d67ca56d3f431980b104ea5528cce79be88f93fb 100644
--- a/fs/bcachefs/migrate.c
+++ b/fs/bcachefs/migrate.c
@@ -266,10 +266,15 @@ int bch2_dev_data_drop_by_backpointers(struct bch_fs *c, unsigned dev_idx, unsig
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

