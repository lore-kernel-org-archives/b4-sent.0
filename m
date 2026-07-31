From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 31 Jul 2026 17:54:54 -0500
Subject: [PATCH v2 1/2] dm array: validate array block headers on read
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-b4-disp-4fd3bed9-v2-1-7b1835e4e7f6@proton.me>
References: <20260731-b4-disp-4fd3bed9-v2-0-7b1835e4e7f6@proton.me>
In-Reply-To: <20260731-b4-disp-4fd3bed9-v2-0-7b1835e4e7f6@proton.me>
To: Mike Snitzer <snitzer@kernel.org>, 
 Mikulas Patocka <mpatocka@redhat.com>
Cc: Ming-Hung Tsai <mtsai@redhat.com>, 
 Benjamin Marzinski <bmarzins@redhat.com>, dm-devel@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Alasdair Kergon <agk@redhat.com>, 
 Joe Thornber <ejt@redhat.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785538493; l=3385;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=3TugB3ShfulMF0Ws150WFu3vRI3cUITFclPEvmxghdM=;
 b=nqIsT4mK5C34isYF3tPHiRU9r7DF4Lq9nkKilWofOcgdZSIXxUR7h+7qs+zJ7EqtUByRpXQ2B
 nUnVgIylUpaDvtWowj2oPR1shL6dohFO0qJfuGAPeAZQSXPnRmJnRyv
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

array_block_check() validates blocknr and csum and nothing else, while
node_check(), next to it, has bounded the structural fields since both
were written. dm_array_cursor_next() takes its loop bound from the
on-disk nr_entries and element_at() is unguarded pointer arithmetic, so
a count larger than the block holds keeps the cursor in one block while
the index grows past it and the read walks off the dm-bufio buffer --
dm_cache_load_mappings() drives it once per cache block at activation.

Check the header against itself: reject a zero value_size, require
max_entries to equal calc_max_entries() for that value_size and block
size, and require nr_entries to fit. Equality rather than an upper bound,
since a count below the real capacity trips BUG_ON() in fill_ablock() and
trim_ablock(). Metadata dm-array writes satisfies all three.

Fixes: 6513c29f44f2 ("dm persistent data: add transactional array")
Suggested-by: Ming-Hung Tsai <mtsai@redhat.com>
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/md/persistent-data/dm-array.c | 38 +++++++++++++++++++++++++++--------
 1 file changed, 30 insertions(+), 8 deletions(-)

diff --git a/drivers/md/persistent-data/dm-array.c b/drivers/md/persistent-data/dm-array.c
index 8f8792e55806..5949fb0e16c6 100644
--- a/drivers/md/persistent-data/dm-array.c
+++ b/drivers/md/persistent-data/dm-array.c
@@ -38,6 +38,14 @@ struct array_block {
  */
 #define CSUM_XOR 595846735
 
+/*
+ * Each array block can hold this many values.
+ */
+static uint32_t calc_max_entries(size_t value_size, size_t size_of_block)
+{
+	return (size_of_block - sizeof(struct array_block)) / value_size;
+}
+
 static void array_block_prepare_for_write(const struct dm_block_validator *v,
 					  struct dm_block *b,
 					  size_t size_of_block)
@@ -55,6 +63,7 @@ static int array_block_check(const struct dm_block_validator *v,
 			     size_t size_of_block)
 {
 	struct array_block *bh_le = dm_block_data(b);
+	uint32_t nr_entries, max_entries, value_size, wanted;
 	__le32 csum_disk;
 
 	if (dm_block_location(b) != le64_to_cpu(bh_le->blocknr)) {
@@ -74,6 +83,27 @@ static int array_block_check(const struct dm_block_validator *v,
 		return -EILSEQ;
 	}
 
+	nr_entries = le32_to_cpu(bh_le->nr_entries);
+	max_entries = le32_to_cpu(bh_le->max_entries);
+	value_size = le32_to_cpu(bh_le->value_size);
+
+	if (!value_size) {
+		DMERR_LIMIT("%s failed: value_size is zero", __func__);
+		return -EILSEQ;
+	}
+
+	wanted = calc_max_entries(value_size, size_of_block);
+	if (max_entries != wanted) {
+		DMERR_LIMIT("%s failed: max_entries %u != wanted %u for value_size %u",
+			    __func__, max_entries, wanted, value_size);
+		return -EILSEQ;
+	}
+
+	if (nr_entries > max_entries) {
+		DMERR_LIMIT("%s failed: too many entries", __func__);
+		return -EILSEQ;
+	}
+
 	return 0;
 }
 
@@ -138,14 +168,6 @@ static void dec_ablock_entries(struct dm_array_info *info, struct array_block *a
 		on_entries(info, ab, vt->dec);
 }
 
-/*
- * Each array block can hold this many values.
- */
-static uint32_t calc_max_entries(size_t value_size, size_t size_of_block)
-{
-	return (size_of_block - sizeof(struct array_block)) / value_size;
-}
-
 /*
  * Allocate a new array block.  The caller will need to unlock block.
  */

-- 
2.55.0

