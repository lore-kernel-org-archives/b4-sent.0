From: Nikita Ofitserov <himikof@gmail.com>
Date: Thu, 28 Aug 2025 17:16:03 +0300
Subject: [PATCH v2 01/15] bcachefs: Introduce btree_leaf_has_triggers_mask
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250828-better-progress-v2-1-c088a2003940@gmail.com>
References: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
In-Reply-To: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1519; i=himikof@gmail.com;
 h=from:subject:message-id; bh=TYWLHU8w0/8UTBK1GkJbIUDQjni0TKSNwZ+FHNlfT2A=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWRsSDmYUaZ0VUCe0TZrVsbCrU1fOsKqTZiCPi/t1PMye
 /iufW1hRykLgxgXg6yYIsuHJV//rMm0/mMptNcQZg4rE8gQBi5OAZiI6E2Gf4ZneoOZX9S6T5i3
 zndpYs3shewV7jcfu554bs97hff/jVqGv8KlE7/p2Jy4r/6/pcmoykfoYqv8Mv1dRertsdvr2nd
 NZgEA
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
 fs/bcachefs/btree_gc.c    | 2 +-
 fs/bcachefs/btree_types.h | 3 +++
 2 files changed, 4 insertions(+), 1 deletion(-)

diff --git a/fs/bcachefs/btree_gc.c b/fs/bcachefs/btree_gc.c
index 43f294284d57473fd8868c974c4bdd847fcf2636..2b1b6b7ffdf0af7ec0bf4cbaf68cc9a53a20cfce 100644
--- a/fs/bcachefs/btree_gc.c
+++ b/fs/bcachefs/btree_gc.c
@@ -720,7 +720,7 @@ static int bch2_gc_btree(struct btree_trans *trans,
 			 enum btree_id btree, bool initial)
 {
 	struct bch_fs *c = trans->c;
-	unsigned target_depth = btree_node_type_has_triggers(__btree_node_type(0, btree)) ? 0 : 1;
+	unsigned target_depth = BIT_ULL(btree) & btree_leaf_has_triggers_mask ? 0 : 1;
 	int ret = 0;
 
 	/* We need to make sure every leaf node is readable before going RW */
diff --git a/fs/bcachefs/btree_types.h b/fs/bcachefs/btree_types.h
index e893eb938bb3da441f0ab0096ced3cc3c2a701e2..ad9bd18fe9b6e51987da74d373830dca98df56ec 100644
--- a/fs/bcachefs/btree_types.h
+++ b/fs/bcachefs/btree_types.h
@@ -840,6 +840,9 @@ static inline bool btree_node_type_has_triggers(enum btree_node_type type)
 	return BIT_ULL(type) & BTREE_NODE_TYPE_HAS_TRIGGERS;
 }
 
+/* A mask of btree id bits that have triggers for their leaves */
+static const u64 btree_leaf_has_triggers_mask = BTREE_NODE_TYPE_HAS_TRIGGERS >> 1;
+
 static const u64 btree_is_extents_mask = 0
 #define x(name, nr, flags, ...)	|((!!((flags) & BTREE_IS_extents)) << nr)
 BCH_BTREE_IDS()

-- 
2.50.1

