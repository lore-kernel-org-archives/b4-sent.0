From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 19 Jun 2026 06:44:56 -0500
Subject: [PATCH 2/3] dm-pcache: validate geometry fields from on-disk
 cache_info
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260619-b4-disp-997773a1-v1-2-14df8aedb323@proton.me>
References: <20260619-b4-disp-997773a1-v1-0-14df8aedb323@proton.me>
In-Reply-To: <20260619-b4-disp-997773a1-v1-0-14df8aedb323@proton.me>
To: Dongsheng Yang <dongsheng.yang@linux.dev>, Zheng Gu <cengku@gmail.com>
Cc: linux-kernel@vger.kernel.org, Mikulas Patocka <mpatocka@redhat.com>, 
 dm-devel@lists.linux.dev
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781869494; l=2084;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=bb6DrPNz+Bfj+QxSSibZlFjrtYBvqCnc6cN4V9NacuA=;
 b=4pml7tRY5d1LmqKNrj6uCcpKEWNTF9ovhDPkfHBNoohwbnAyzW7IQERPzklSPIoz62bj7Y3zy
 JPIlv/KkPiSAtBhAuWPknFGeTZLLWHM92OCnFprWcsReSfCuZYJejDl
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cache_segs_init() iterates cache_info->n_segs times indexing
cache->segments[], which is sized to the cache device geometry, and
get_seg_id() takes each segment id from the on-media cache_info and the
per-segment next_seg link. Both come from cache device metadata that is
only CRC-protected with a fixed public seed, so whoever supplies the
cache device on a table load (CAP_SYS_ADMIN) controls them: an oversized
n_segs or an out-of-range id drives an out-of-bounds access of
cache->segments[] and a wild CACHE_DEV_SEGMENT() pointer into the device
mapping -- an out-of-bounds read and write from on-disk data.

Reject an n_segs that exceeds the device segment count and a segment id
that is out of range before either is used. Valid metadata is unaffected.

Fixes: 1d57628ff95b ("dm-pcache: add persistent cache target in device-mapper")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/md/dm-pcache/cache.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/drivers/md/dm-pcache/cache.c b/drivers/md/dm-pcache/cache.c
index e6a2f4460f6e..08decbebd238 100644
--- a/drivers/md/dm-pcache/cache.c
+++ b/drivers/md/dm-pcache/cache.c
@@ -250,6 +250,13 @@ static int get_seg_id(struct pcache_cache *cache,
 		} else {
 			*seg_id = cache->cache_info.seg_id;
 		}
+
+		if (*seg_id >= cache_dev->seg_num) {
+			pcache_dev_err(pcache, "invalid segment id %u from cache device (seg_num %u)\n",
+				       *seg_id, cache_dev->seg_num);
+			ret = -EIO;
+			goto err;
+		}
 	}
 	return 0;
 err:
@@ -265,6 +272,13 @@ static int cache_segs_init(struct pcache_cache *cache)
 	int ret;
 	u32 i;
 
+	if (cache_info->n_segs > cache->cache_dev->seg_num) {
+		pcache_dev_err(CACHE_TO_PCACHE(cache),
+			       "cache_info n_segs %u exceeds cache device segments %u\n",
+			       cache_info->n_segs, cache->cache_dev->seg_num);
+		return -EIO;
+	}
+
 	for (i = 0; i < cache_info->n_segs; i++) {
 		ret = get_seg_id(cache, prev_cache_seg, new_cache, &seg_id);
 		if (ret)

-- 
2.43.0

