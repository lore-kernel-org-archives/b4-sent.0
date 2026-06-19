From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 19 Jun 2026 06:44:57 -0500
Subject: [PATCH 3/3] dm-pcache: validate kset key_num and intra-segment
 bounds
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260619-b4-disp-997773a1-v1-3-14df8aedb323@proton.me>
References: <20260619-b4-disp-997773a1-v1-0-14df8aedb323@proton.me>
In-Reply-To: <20260619-b4-disp-997773a1-v1-0-14df8aedb323@proton.me>
To: Dongsheng Yang <dongsheng.yang@linux.dev>, Zheng Gu <cengku@gmail.com>
Cc: linux-kernel@vger.kernel.org, Mikulas Patocka <mpatocka@redhat.com>, 
 dm-devel@lists.linux.dev
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781869494; l=5615;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=A3BdP26I4fkfP3zVHBLiakVPHYgW4y6IPtWW9Ji+tj4=;
 b=xGadi54xO5DsnxeYtuSgZehWO4BAQ0vEweH7y39KaDkrPBaynUppNzpC5Uabu0/B/PZQOYaX5
 iBhSKF+bJNwAoeyQ2HKoDU8fa8vtud6y2DsXBWlwlBcS9N7LhMMy3Rc
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two more fields decoded from the cache device go unbounded. The kset
key_num drives cache_kset_crc() and the replay loop in cache_replay(),
the writeback worker and the GC worker, but only the magic and a
fixed-seed CRC are checked first, so a non-last kset whose key_num exceeds
the PCACHE_KSET_KEYS_MAX buffer reads past its end before the CRC compare.
A key's intra-segment offset and length in cache_key_decode() are taken
verbatim, so a key running past its segment is replayed into the cache
tree and the data CRC check and every later read hit then copy adjacent
persistent memory into the caller's bio -- an out-of-bounds read that
leaks to user space. Both fields are controlled by whoever supplies the
cache device (CAP_SYS_ADMIN); the CRC seed is public.

Add kset_onmedia_valid() to bound key_num before any kset read, and
reject a key whose offset plus length, computed in 64 bits, exceeds the
segment data_size. Valid metadata is unaffected.

Fixes: 1d57628ff95b ("dm-pcache: add persistent cache target in device-mapper")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/md/dm-pcache/cache.h           | 21 +++++++++++++++++++++
 drivers/md/dm-pcache/cache_gc.c        |  8 ++++----
 drivers/md/dm-pcache/cache_key.c       | 10 +++++++++-
 drivers/md/dm-pcache/cache_writeback.c |  8 ++++----
 4 files changed, 38 insertions(+), 9 deletions(-)

diff --git a/drivers/md/dm-pcache/cache.h b/drivers/md/dm-pcache/cache.h
index 653ceea43131..d470e457b23f 100644
--- a/drivers/md/dm-pcache/cache.h
+++ b/drivers/md/dm-pcache/cache.h
@@ -505,6 +505,27 @@ static inline u32 cache_key_data_crc(struct pcache_cache_key *key)
 	return crc32c(PCACHE_CRC_SEED, data, key->len);
 }
 
+/**
+ * kset_onmedia_valid - Validate a kset header read from the cache device.
+ * @kset_onmedia: Pointer to the kset copied from on-media metadata.
+ *
+ * The magic and CRC are attacker-computable (fixed public seed). A non-last
+ * kset stores key_num keys inline, and cache_kset_crc() and the replay loop
+ * read struct_size(.., data, key_num) bytes from a buffer sized for
+ * PCACHE_KSET_KEYS_MAX keys, so key_num must be bounded before any such use.
+ */
+static inline bool kset_onmedia_valid(struct pcache_cache_kset_onmedia *kset_onmedia)
+{
+	if (kset_onmedia->magic != PCACHE_KSET_MAGIC)
+		return false;
+
+	if (!(kset_onmedia->flags & PCACHE_KSET_FLAGS_LAST) &&
+	    kset_onmedia->key_num > PCACHE_KSET_KEYS_MAX)
+		return false;
+
+	return true;
+}
+
 static inline u32 cache_kset_crc(struct pcache_cache_kset_onmedia *kset_onmedia)
 {
 	u32 crc_size;
diff --git a/drivers/md/dm-pcache/cache_gc.c b/drivers/md/dm-pcache/cache_gc.c
index 02fa0ce03134..1ed513745023 100644
--- a/drivers/md/dm-pcache/cache_gc.c
+++ b/drivers/md/dm-pcache/cache_gc.c
@@ -44,11 +44,11 @@ static bool need_gc(struct pcache_cache *cache, struct pcache_cache_pos *dirty_t
 		return false;
 	}
 
-	/* Check if kset_onmedia is corrupted */
-	if (kset_onmedia->magic != PCACHE_KSET_MAGIC) {
-		pcache_dev_debug(pcache, "gc error: magic is not as expected. key_tail: %u:%u magic: %llx, expected: %llx\n",
+	/* Reject a corrupted or out-of-bounds kset before reading its keys */
+	if (!kset_onmedia_valid(kset_onmedia)) {
+		pcache_dev_debug(pcache, "gc error: invalid kset. key_tail: %u:%u magic: %llx, key_num: %u\n",
 					key_tail->cache_seg->cache_seg_id, key_tail->seg_off,
-					kset_onmedia->magic, PCACHE_KSET_MAGIC);
+					kset_onmedia->magic, kset_onmedia->key_num);
 		return false;
 	}
 
diff --git a/drivers/md/dm-pcache/cache_key.c b/drivers/md/dm-pcache/cache_key.c
index 8eec5238c5da..f4459b2e1b3b 100644
--- a/drivers/md/dm-pcache/cache_key.c
+++ b/drivers/md/dm-pcache/cache_key.c
@@ -103,6 +103,14 @@ int cache_key_decode(struct pcache_cache *cache,
 	key->cache_pos.cache_seg = &cache->segments[key_onmedia->cache_seg_id];
 	key->cache_pos.seg_off = key_onmedia->cache_seg_off;
 
+	if ((u64)key->cache_pos.seg_off + key->len >
+			key->cache_pos.cache_seg->segment.data_size) {
+		pcache_dev_err(pcache, "key seg_off %u + len %u exceeds segment data size %u\n",
+				key->cache_pos.seg_off, key->len,
+				key->cache_pos.cache_seg->segment.data_size);
+		return -EIO;
+	}
+
 	key->seg_gen = key_onmedia->seg_gen;
 	key->flags = key_onmedia->flags;
 
@@ -784,7 +792,7 @@ int cache_replay(struct pcache_cache *cache)
 			goto out;
 		}
 
-		if (kset_onmedia->magic != PCACHE_KSET_MAGIC ||
+		if (!kset_onmedia_valid(kset_onmedia) ||
 				kset_onmedia->crc != cache_kset_crc(kset_onmedia)) {
 			break;
 		}
diff --git a/drivers/md/dm-pcache/cache_writeback.c b/drivers/md/dm-pcache/cache_writeback.c
index a104e6ee8aa8..f96657a1dc1a 100644
--- a/drivers/md/dm-pcache/cache_writeback.c
+++ b/drivers/md/dm-pcache/cache_writeback.c
@@ -55,11 +55,11 @@ static inline bool is_cache_clean(struct pcache_cache *cache, struct pcache_cach
 		return true;
 	}
 
-	/* Check if the magic number matches the expected value */
-	if (kset_onmedia->magic != PCACHE_KSET_MAGIC) {
-		pcache_dev_debug(pcache, "dirty_tail: %u:%u magic: %llx, not expected: %llx\n",
+	/* Reject a corrupted or out-of-bounds kset before reading its keys */
+	if (!kset_onmedia_valid(kset_onmedia)) {
+		pcache_dev_debug(pcache, "dirty_tail: %u:%u invalid kset magic: %llx, key_num: %u\n",
 				dirty_tail->cache_seg->cache_seg_id, dirty_tail->seg_off,
-				kset_onmedia->magic, PCACHE_KSET_MAGIC);
+				kset_onmedia->magic, kset_onmedia->key_num);
 		return true;
 	}
 

-- 
2.43.0

