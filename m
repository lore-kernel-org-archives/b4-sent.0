From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 17 Jul 2026 06:27:04 -0500
Subject: [PATCH v2 11/11] dm-pcache: only hand out initialized cache
 segments
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260717-b4-disp-4c0a0039-v2-11-19227d6e313c@proton.me>
References: <20260717-b4-disp-4c0a0039-v2-0-19227d6e313c@proton.me>
In-Reply-To: <20260717-b4-disp-4c0a0039-v2-0-19227d6e313c@proton.me>
To: Zheng Gu <cengku@gmail.com>, Dongsheng Yang <dongsheng.yang@linux.dev>
Cc: dm-devel@lists.linux.dev, Mikulas Patocka <mpatocka@redhat.com>, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784287613; l=2107;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=piR/cvm0pEPSywfzzIIYfNS8IxFVEBQOSYdmjR0YuKw=;
 b=mnkOMdV3CZk/LMNGJI8zlCZTkI98OTRWD76o+IOKs7ih4+2/tU55/NMe7B+0pwaM7QEjm9vjg
 u00TuVYay3pAnmEBzwKYBkjd5GohtY4N/XesNN//tsCyQPSRocZ8hJ3
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

get_cache_segment() scans the segment map up to cache->n_segs, the
physical device segment count, but cache_segs_init() only initializes
the first cache_info->n_segs segments. A crafted image with
cache_info->n_segs smaller than the device count leaves the remaining
pcache_cache_segment structs zeroed (segment.data == NULL), and the
allocator can hand one to cache_kset_close(), which writes through the
returned segment's data pointer with no NULL check.

Bound the allocator's search to cache_info->n_segs so only initialized
segments are ever returned. A conforming cache sets n_segs equal to the
device segment count, so this rejects nothing legitimate.

Fixes: 1d57628ff95b ("dm-pcache: add persistent cache target in device-mapper")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/md/dm-pcache/cache_segment.c | 12 ++++++++++--
 1 file changed, 10 insertions(+), 2 deletions(-)

diff --git a/drivers/md/dm-pcache/cache_segment.c b/drivers/md/dm-pcache/cache_segment.c
index 9d92e2b067ed..c698ebbc626d 100644
--- a/drivers/md/dm-pcache/cache_segment.c
+++ b/drivers/md/dm-pcache/cache_segment.c
@@ -243,8 +243,16 @@ struct pcache_cache_segment *get_cache_segment(struct pcache_cache *cache)
 
 	spin_lock(&cache->seg_map_lock);
 again:
-	seg_id = find_next_zero_bit(cache->seg_map, cache->n_segs, cache->last_cache_seg);
-	if (seg_id == cache->n_segs) {
+	/*
+	 * Only allocate initialized segments. cache_segs_init() initializes
+	 * cache_info.n_segs of the cache->n_segs device segments; a forged
+	 * smaller cache_info.n_segs leaves the rest as zeroed structs whose data
+	 * pointer is NULL. Bounding the search to cache_info.n_segs keeps such a
+	 * segment from reaching cache_kset_close(), which writes through it.
+	 */
+	seg_id = find_next_zero_bit(cache->seg_map, cache->cache_info.n_segs,
+				    cache->last_cache_seg);
+	if (seg_id == cache->cache_info.n_segs) {
 		/* reset the hint of ->last_cache_seg and retry */
 		if (cache->last_cache_seg) {
 			cache->last_cache_seg = 0;

-- 
2.43.0

