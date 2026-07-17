From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 17 Jul 2026 06:26:57 -0500
Subject: [PATCH v2 04/11] dm-pcache: bound the persisted tail-position
 offset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260717-b4-disp-4c0a0039-v2-4-19227d6e313c@proton.me>
References: <20260717-b4-disp-4c0a0039-v2-0-19227d6e313c@proton.me>
In-Reply-To: <20260717-b4-disp-4c0a0039-v2-0-19227d6e313c@proton.me>
To: Zheng Gu <cengku@gmail.com>, Dongsheng Yang <dongsheng.yang@linux.dev>
Cc: dm-devel@lists.linux.dev, Mikulas Patocka <mpatocka@redhat.com>, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784287613; l=1129;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=hN9K2tznX8h1QG7GfDCqM9oGo/1YYUnmVCUIvgXpICk=;
 b=c2HibsNGq9PxA8UzqkT0stULoj1gCQtVqGCnfhMPLoa9x4nKTbuPlkhkC+6Y4Dl+KKaXJXibs
 WAOkYPB93BED92xic8EJWQN1a3dkwaVS6AtP8IhcgtK6I33AZgxv6IW
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cache_pos_decode() takes the persisted key_tail and dirty_tail seg_off from
the cache device and addresses within the segment with it. A seg_off at or
past the segment data_size, controllable by whoever supplies the device
(CAP_SYS_ADMIN), reads past the segment data.

Reject a decoded seg_off that is not below the segment data_size.

Fixes: 1d57628ff95b ("dm-pcache: add persistent cache target in device-mapper")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/md/dm-pcache/cache.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/md/dm-pcache/cache.c b/drivers/md/dm-pcache/cache.c
index e4784578b9af..a94eadb7affd 100644
--- a/drivers/md/dm-pcache/cache.c
+++ b/drivers/md/dm-pcache/cache.c
@@ -122,6 +122,10 @@ int cache_pos_decode(struct pcache_cache *cache,
 		return -EIO;
 
 	pos->cache_seg = &cache->segments[latest.cache_seg_id];
+
+	if (latest.seg_off >= pos->cache_seg->segment.data_size)
+		return -EIO;
+
 	pos->seg_off = latest.seg_off;
 	*seq = latest.header.seq;
 	*index = (latest_addr - pos_onmedia);

-- 
2.43.0

