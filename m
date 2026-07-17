From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 17 Jul 2026 06:27:00 -0500
Subject: [PATCH v2 07/11] dm-pcache: bound the logical key offset from
 persistent memory
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260717-b4-disp-4c0a0039-v2-7-19227d6e313c@proton.me>
References: <20260717-b4-disp-4c0a0039-v2-0-19227d6e313c@proton.me>
In-Reply-To: <20260717-b4-disp-4c0a0039-v2-0-19227d6e313c@proton.me>
To: Zheng Gu <cengku@gmail.com>, Dongsheng Yang <dongsheng.yang@linux.dev>
Cc: dm-devel@lists.linux.dev, Mikulas Patocka <mpatocka@redhat.com>, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784287613; l=1598;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=GP1/4GJNnNWJdMna2c7wHajzFf/3a0JDLm0ELeLq69s=;
 b=0XhksriEfsf3e91wOyEQ7BqAw66e85dX2S/LsXvGVVzRpelMQJ7wQnKWj/oPOiHVzm+S7tVDb
 A9KKsTuQBYIAxJLeaNjUZA7hnWXOJiYs/lYqgfQ5bHMGRyZeCs74zYv
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cache_key_decode() takes a key's logical off from the cache device and
later indexes req_key_tree->subtrees[] by it in get_subtree(). An off
past the device forms a subtree pointer outside the array, which
rb_insert() writes through during replay.

Reject a key of zero length, or whose off+len (computed in 64 bits)
exceeds the device size, before it is used.

Fixes: 1d57628ff95b ("dm-pcache: add persistent cache target in device-mapper")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/md/dm-pcache/cache_key.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/md/dm-pcache/cache_key.c b/drivers/md/dm-pcache/cache_key.c
index 2284dbc0807b..86cc9565ffc7 100644
--- a/drivers/md/dm-pcache/cache_key.c
+++ b/drivers/md/dm-pcache/cache_key.c
@@ -90,10 +90,19 @@ int cache_key_decode(struct pcache_cache *cache,
 			struct pcache_cache_key *key)
 {
 	struct dm_pcache *pcache = CACHE_TO_PCACHE(cache);
+	u64 dev_bytes = (u64)cache->dev_size << SECTOR_SHIFT;
 
 	key->off = key_onmedia->off;
 	key->len = key_onmedia->len;
 
+	if (key_onmedia->len == 0 ||
+	    key_onmedia->len > dev_bytes ||
+	    key_onmedia->off > dev_bytes - key_onmedia->len) {
+		pcache_dev_err(pcache, "key off %llu + len %u exceeds device size\n",
+				key_onmedia->off, key_onmedia->len);
+		return -EIO;
+	}
+
 	if (!cache_seg_id_valid(cache, key_onmedia->cache_seg_id)) {
 		pcache_dev_err(pcache, "invalid cache_seg_id %u in cache key (n_segs %u)\n",
 				key_onmedia->cache_seg_id, cache->n_segs);

-- 
2.43.0

