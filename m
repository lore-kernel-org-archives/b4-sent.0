From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 31 Jul 2026 21:32:04 -0500
Subject: [PATCH 2/2] dm btree: reject a node whose value size is not the
 reading level's
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-b4-disp-1fdddbbb-v1-2-4879ae1012a2@proton.me>
References: <20260731-b4-disp-1fdddbbb-v1-0-4879ae1012a2@proton.me>
In-Reply-To: <20260731-b4-disp-1fdddbbb-v1-0-4879ae1012a2@proton.me>
To: Mike Snitzer <snitzer@kernel.org>, 
 Mikulas Patocka <mpatocka@redhat.com>
Cc: Joe Thornber <ejt@redhat.com>, Ming-Hung Tsai <mtsai@redhat.com>, 
 Heinz Mauelshagen <heinzm@redhat.com>, Alasdair Kergon <agk@redhat.com>, 
 dm-devel@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Benjamin Marzinski <bmarzins@redhat.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785551523; l=9192;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=nPH9k1cM6UEOPHSiszBBTRgFy6NWqXca3CfwP+ScfsA=;
 b=EQa0PMaDo1tlSXV0HLqVcQFMOqDFl49SHQbH7NZgWIgF8AXfuhk9t+DhDJB7BkJ9lkBKkAqah
 d9wzeMVyJM3B9zg2wEumak1QdnvFlGjJXyHhSvmrQF60GXuuKrEX0A1
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

value_ptr() takes an entry's address from the value_size on disk while
the caller supplies the length it copies; a validator cannot compare the
two, since it sees the block and never the caller. A leaf can pass every
check the previous patch adds and still be laid out for a narrower
value, leaving insert_at() and btree_split_beneath() striding with the
caller's size over a base placed by the node's -- writes that land
kilobytes past the block.

Compare the sizes wherever both are in hand. Everything that modifies a
node reaches it through bn_shadow(), so one check there covers insert,
the splits, remove and the space map's refcount overflow leaf; the
readers and the two paths that bypass the spine take it where the
expected size is known. A node is only ever read through the level that
wrote it, so conforming metadata is unaffected.

Fixes: 3241b1d3e0aa ("dm: add persistent data library")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/md/persistent-data/dm-btree-internal.h |  6 +-
 drivers/md/persistent-data/dm-btree-remove.c   | 24 ++++++--
 drivers/md/persistent-data/dm-btree-spine.c    | 13 ++++-
 drivers/md/persistent-data/dm-btree.c          | 79 +++++++++++++++++++++++---
 4 files changed, 108 insertions(+), 14 deletions(-)

diff --git a/drivers/md/persistent-data/dm-btree-internal.h b/drivers/md/persistent-data/dm-btree-internal.h
index 404739149d02..7d5741572b16 100644
--- a/drivers/md/persistent-data/dm-btree-internal.h
+++ b/drivers/md/persistent-data/dm-btree-internal.h
@@ -51,8 +51,10 @@ uint32_t calc_max_entries(size_t value_size, size_t block_size);
 int bn_read_lock(struct dm_btree_info *info, dm_block_t b,
 		 struct dm_block **result);
 
-void inc_children(struct dm_transaction_manager *tm, struct btree_node *n,
-		  struct dm_btree_value_type *vt);
+int check_value_size(struct btree_node *n, size_t expected);
+
+int inc_children(struct dm_transaction_manager *tm, struct btree_node *n,
+		 struct dm_btree_value_type *vt);
 
 int new_block(struct dm_btree_info *info, struct dm_block **result);
 void unlock_block(struct dm_btree_info *info, struct dm_block *b);
diff --git a/drivers/md/persistent-data/dm-btree-remove.c b/drivers/md/persistent-data/dm-btree-remove.c
index aeec5b9a1dd5..64f3313f5a1c 100644
--- a/drivers/md/persistent-data/dm-btree-remove.c
+++ b/drivers/md/persistent-data/dm-btree-remove.c
@@ -175,8 +175,14 @@ static int init_child(struct dm_btree_info *info, struct dm_btree_value_type *vt
 
 	result->n = dm_block_data(result->block);
 
-	if (inc)
-		inc_children(info->tm, result->n, vt);
+	r = check_value_size(result->n, vt->size);
+	if (!r && inc)
+		r = inc_children(info->tm, result->n, vt);
+
+	if (r) {
+		dm_tm_unlock(info->tm, result->block);
+		return r;
+	}
 
 	*((__le64 *) value_ptr(parent, index)) =
 		cpu_to_le64(dm_block_location(result->block));
@@ -501,8 +507,18 @@ static int rebalance_children(struct shadow_spine *s,
 		if (r)
 			return r;
 
-		if (is_shared)
-			inc_children(info->tm, dm_block_data(child), vt);
+		/*
+		 * The child is copied over the node the spine already
+		 * checked, so it has to answer for itself first.
+		 */
+		r = check_value_size(dm_block_data(child), vt->size);
+		if (!r && is_shared)
+			r = inc_children(info->tm, dm_block_data(child), vt);
+
+		if (r) {
+			dm_tm_unlock(info->tm, child);
+			return r;
+		}
 
 		memcpy(n, dm_block_data(child),
 		       dm_bm_block_size(dm_tm_get_bm(info->tm)));
diff --git a/drivers/md/persistent-data/dm-btree-spine.c b/drivers/md/persistent-data/dm-btree-spine.c
index 076f836912c8..2527af9460fe 100644
--- a/drivers/md/persistent-data/dm-btree-spine.c
+++ b/drivers/md/persistent-data/dm-btree-spine.c
@@ -121,8 +121,19 @@ static int bn_shadow(struct dm_btree_info *info, dm_block_t orig,
 
 	r = dm_tm_shadow_block(info->tm, orig, &btree_node_validator,
 			       result, &inc);
+	if (r)
+		return r;
+
+	/*
+	 * Everything that modifies a node reaches it through here, so this is
+	 * where a leaf laid out for a different value size is caught.
+	 */
+	r = check_value_size(dm_block_data(*result), vt->size);
 	if (!r && inc)
-		inc_children(info->tm, dm_block_data(*result), vt);
+		r = inc_children(info->tm, dm_block_data(*result), vt);
+
+	if (r)
+		unlock_block(info, *result);
 
 	return r;
 }
diff --git a/drivers/md/persistent-data/dm-btree.c b/drivers/md/persistent-data/dm-btree.c
index 5ed3b3e9abb9..b74c41fe6213 100644
--- a/drivers/md/persistent-data/dm-btree.c
+++ b/drivers/md/persistent-data/dm-btree.c
@@ -71,16 +71,47 @@ static int upper_bound(struct btree_node *n, uint64_t key)
 	return bsearch(n, key, 1);
 }
 
-void inc_children(struct dm_transaction_manager *tm, struct btree_node *n,
-		  struct dm_btree_value_type *vt)
+/*
+ * value_ptr() takes an entry's address from the value_size stored on disk,
+ * but the caller supplies the length it copies.  node_check() sees the block
+ * and never the caller, so the two are compared here, wherever both are in
+ * hand.  Internal nodes are exempt: node_check() already holds them to
+ * sizeof(__le64), which is what value64() assumes.
+ */
+int check_value_size(struct btree_node *n, size_t expected)
+{
+	uint32_t value_size = le32_to_cpu(n->header.value_size);
+
+	if (le32_to_cpu(n->header.flags) & INTERNAL_NODE)
+		return 0;
+
+	if (value_size != expected) {
+		DMERR_LIMIT("%s failed: value_size %u != %zu expected by the caller",
+			    __func__, value_size, expected);
+		return -EILSEQ;
+	}
+
+	return 0;
+}
+
+int inc_children(struct dm_transaction_manager *tm, struct btree_node *n,
+		 struct dm_btree_value_type *vt)
 {
 	uint32_t nr_entries = le32_to_cpu(n->header.nr_entries);
 
 	if (le32_to_cpu(n->header.flags) & INTERNAL_NODE)
 		dm_tm_with_runs(tm, value_ptr(n, 0), nr_entries, dm_tm_inc_range);
 
-	else if (vt->inc)
+	else if (vt->inc) {
+		int r = check_value_size(n, vt->size);
+
+		if (r)
+			return r;
+
 		vt->inc(vt->context, value_ptr(n, 0), nr_entries);
+	}
+
+	return 0;
 }
 
 static int insert_at(size_t value_size, struct btree_node *node, unsigned int index,
@@ -314,6 +345,10 @@ int dm_btree_del(struct dm_btree_info *info, dm_block_t root)
 				goto out;
 
 		} else if (is_internal_level(info, f)) {
+			r = check_value_size(f->n, sizeof(__le64));
+			if (r)
+				goto out;
+
 			b = value64(f->n, f->current_child);
 			f->current_child++;
 			r = push_frame(s, b, f->level + 1);
@@ -321,9 +356,14 @@ int dm_btree_del(struct dm_btree_info *info, dm_block_t root)
 				goto out;
 
 		} else {
-			if (info->value_type.dec)
+			if (info->value_type.dec) {
+				r = check_value_size(f->n, info->value_type.size);
+				if (r)
+					goto out;
+
 				info->value_type.dec(info->value_type.context,
 						     value_ptr(f->n, 0), f->nr_children);
+			}
 			pop_frame(s);
 		}
 	}
@@ -365,8 +405,13 @@ static int btree_lookup_raw(struct ro_spine *s, dm_block_t block, uint64_t key,
 	} while (!(flags & LEAF_NODE));
 
 	*result_key = le64_to_cpu(ro_node(s)->keys[i]);
-	if (v)
+	if (v) {
+		r = check_value_size(ro_node(s), value_size);
+		if (r)
+			return r;
+
 		memcpy(v, value_ptr(ro_node(s), i), value_size);
+	}
 
 	return 0;
 }
@@ -460,6 +505,10 @@ static int dm_btree_lookup_next_single(struct dm_btree_info *info, dm_block_t ro
 		}
 
 		*rkey = le64_to_cpu(n->keys[i]);
+		r = check_value_size(n, info->value_type.size);
+		if (r)
+			goto out;
+
 		memcpy(value_le, value_ptr(n, i), info->value_type.size);
 	}
 out:
@@ -721,8 +770,14 @@ static int shadow_child(struct dm_btree_info *info, struct dm_btree_value_type *
 
 	node = dm_block_data(*result);
 
-	if (inc)
-		inc_children(info->tm, node, vt);
+	r = check_value_size(node, vt->size);
+	if (!r && inc)
+		r = inc_children(info->tm, node, vt);
+
+	if (r) {
+		unlock_block(info, *result);
+		return r;
+	}
 
 	*((__le64 *) value_ptr(parent, index)) =
 		cpu_to_le64(dm_block_location(*result));
@@ -1441,6 +1496,10 @@ static int walk_node(struct dm_btree_info *info, dm_block_t block,
 			if (r)
 				goto out;
 		} else {
+			r = check_value_size(n, info->value_type.size);
+			if (r)
+				goto out;
+
 			keys = le64_to_cpu(*key_ptr(n, i));
 			r = fn(context, &keys, value_ptr(n, i));
 			if (r)
@@ -1474,6 +1533,9 @@ static void prefetch_values(struct dm_btree_cursor *c)
 
 	BUG_ON(c->info->value_type.size != sizeof(value_le));
 
+	if (check_value_size(bn, sizeof(value_le)))
+		return;
+
 	nr = le32_to_cpu(bn->header.nr_entries);
 	for (i = 0; i < nr; i++) {
 		memcpy(&value_le, value_ptr(bn, i), sizeof(value_le));
@@ -1627,6 +1689,9 @@ int dm_btree_cursor_get_value(struct dm_btree_cursor *c, uint64_t *key, void *va
 		if (le32_to_cpu(bn->header.flags) & INTERNAL_NODE)
 			return -EINVAL;
 
+		if (check_value_size(bn, c->info->value_type.size))
+			return -EILSEQ;
+
 		*key = le64_to_cpu(*key_ptr(bn, n->index));
 		memcpy(value_le, value_ptr(bn, n->index), c->info->value_type.size);
 		return 0;

-- 
2.55.0

