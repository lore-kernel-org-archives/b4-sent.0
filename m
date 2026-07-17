From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 17 Jul 2026 06:26:59 -0500
Subject: [PATCH v2 06/11] dm-pcache: detect a cycle in the last-kset chain
 during replay
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260717-b4-disp-4c0a0039-v2-6-19227d6e313c@proton.me>
References: <20260717-b4-disp-4c0a0039-v2-0-19227d6e313c@proton.me>
In-Reply-To: <20260717-b4-disp-4c0a0039-v2-0-19227d6e313c@proton.me>
To: Zheng Gu <cengku@gmail.com>, Dongsheng Yang <dongsheng.yang@linux.dev>
Cc: dm-devel@lists.linux.dev, Mikulas Patocka <mpatocka@redhat.com>, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784287613; l=1415;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=ZwCcFfHgFT+HQDBZxOs1rAKOfWWhRa9VFuMd2jR4RIs=;
 b=2QfF3AR5XbVtkeYQvFhpMG0sqALSKUkx498zGe5TuNgDe9Quf9uV1zxQIIq85/+9UkYdd/y0d
 RPSpPZV7Vx1BUAyHYLrbyuso+MYylindUlaDZckla5kiJbUkmjQKUOC
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cache_replay() follows the on-media last-kset chain by next_cache_seg_id
with no cond_resched(). A forged chain that points back into a segment it
has already visited makes the replay loop follow it forever.

Cap the last-kset hops at cache->n_segs; a valid chain visits each segment
at most once.

Fixes: 1d57628ff95b ("dm-pcache: add persistent cache target in device-mapper")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/md/dm-pcache/cache_key.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/md/dm-pcache/cache_key.c b/drivers/md/dm-pcache/cache_key.c
index d00497f9e462..2284dbc0807b 100644
--- a/drivers/md/dm-pcache/cache_key.c
+++ b/drivers/md/dm-pcache/cache_key.c
@@ -768,7 +768,7 @@ int cache_replay(struct pcache_cache *cache)
 	struct pcache_cache_pos pos_tail;
 	struct pcache_cache_pos *pos;
 	struct pcache_cache_kset_onmedia *kset_onmedia;
-	u32 to_copy, count = 0;
+	u32 to_copy, count = 0, last_hops = 0;
 	int ret = 0;
 
 	kset_onmedia = kzalloc(PCACHE_KSET_ONMEDIA_SIZE_MAX, GFP_KERNEL);
@@ -808,6 +808,11 @@ int cache_replay(struct pcache_cache *cache)
 				goto out;
 			}
 
+			if (++last_hops > cache->n_segs) {
+				ret = -EIO;
+				goto out;
+			}
+
 			next_seg = &cache->segments[kset_onmedia->next_cache_seg_id];
 
 			pos->cache_seg = next_seg;

-- 
2.43.0

