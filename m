From: Lucas Frendorf <lucasfrendorf@proton.me>
Date: Thu, 08 Oct 2026 13:39:47 +0200
Subject: [PATCH] drm/ttm: Skip GPU MM stats for DMA-allocated pool pages
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-ttm-gpu-stats-dma-v1-1-2922ae4d372d@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqEMAxA4atI1hOoxYrOVWQWtUaN4A9NHAbEu
 9vR5bd47wChyCTwzg6I9GXhdUnIXxmE0S8DIXfJYI0tc2MqVJ1x2HYU9SrYzR7rPjiqnfWFayF
 1W6Sef/ez+TyWvZ0o6H8E53kBXUj42XUAAAA=
X-Change-ID: 20261008-ttm-gpu-stats-dma-9fc5e952a45b
To: Thomas Zimmermann <tzimmermann@suse.de>, 
 Simona Vetter <simona@ffwll.ch>, 
 Christian Koenig <christian.koenig@amd.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Matthew Auld <matthew.auld@intel.com>, 
 Huang Rui <ray.huang@amd.com>, David Airlie <airlied@gmail.com>, 
 Matthew Brost <matthew.brost@intel.com>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791459605; l=3687;
 i=lucasfrendorf@proton.me; s=20261008; h=from:subject:message-id;
 bh=kWINnrTxPf/UJdWXQRq0OxWFpdRLdVyF8aeGd93+1n0=;
 b=ilFnetDJSPqDknQvJ919aZlejSr87t9O54w92Cfcc8VqOAuRqF1298dwSMo3RUkV1OnHUtrrt
 jy92MERfoVPDJPjtAqzI20WP7bl6eMXMNJNR7USE7rbEHiw9cuXHmX0
X-Developer-Key: i=lucasfrendorf@proton.me; a=ed25519;
 pk=v8K8GS0xRvfhhVxjq0t7VICeqma8piHxgNSzSM4Uytg=
X-Endpoint-Received: by B4 Relay for lucasfrendorf@proton.me/20261008 with auth_id=1129
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ttm_pool_alloc_page() and ttm_pool_free_page() account NR_GPU_ACTIVE
and NR_GPU_RECLAIM only for pages from the page allocator, but
ttm_pool_type_give() and ttm_pool_type_take() update them for every
page. Each DMA-allocated page that is given to a pool and later freed
from it therefore leaves NR_GPU_RECLAIM incremented and NR_GPU_ACTIVE
decremented.

DMA-allocating pools are used by amdgpu, radeon and nouveau when
drm_need_swiotlb() is true, and by vmwgfx in coherent mode. On an
amdgpu Rembrandt APU, GPUReclaim reached 20 GiB on a 30.6 GiB machine
after 2 days while the pool held 34 MiB, and GPUActive read 0 kB.

The imbalance was found with LLM assistance while investigating a
memory monitor that reported 95% use.

The allocation and free paths do not account DMA API memory. Skip the
give and take accounting for DMA-allocating pools as well.

Fixes: ae80122f3896 ("drm/ttm: use gpu mm stats to track gpu memory allocations. (v4)")
Link: https://github.com/AvengeMedia/dgop/issues/44
Cc: Christian Koenig <christian.koenig@amd.com>
Cc: Huang Rui <ray.huang@amd.com>
Cc: Matthew Auld <matthew.auld@intel.com>
Cc: Matthew Brost <matthew.brost@intel.com>
Cc: David Airlie <airlied@gmail.com>
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Lucas Frendorf <lucasfrendorf@proton.me>
---
I noticed dgop, a memory monitor, reported 95% usage. An LLM found the
cause in the GPUReclaim accounting, wrote this patch and drafted its
changelog, which I reviewed and revised.

To reproduce, compare GPUReclaim in /proc/meminfo with the page total
in /sys/kernel/debug/dri/<pci-id>/ttm_page_pool on a device with a
DMA-allocating pool.

Tested on v7.2.9 with the patched ttm.ko: GPUReclaim stayed at 0 kB
through a glmark2 run on the 680M while its DMA pool held 298 MiB. The
RX 6800S, which uses the non-DMA pools, still raised and lowered
GPUReclaim normally. The patch builds with W=1 on v7.3-rc6.

Dave Airlie's memcg series (part 2 v2, patch 05/10) rewrites both
hunks and would need the same check.
---
 drivers/gpu/drm/ttm/ttm_pool.c | 12 ++++++++----
 1 file changed, 8 insertions(+), 4 deletions(-)

diff --git a/drivers/gpu/drm/ttm/ttm_pool.c b/drivers/gpu/drm/ttm/ttm_pool.c
index 1bf37023f..1f2d31c3e 100644
--- a/drivers/gpu/drm/ttm/ttm_pool.c
+++ b/drivers/gpu/drm/ttm/ttm_pool.c
@@ -341,8 +341,10 @@ static void ttm_pool_type_give(struct ttm_pool_type *pt, struct page *p)
 	rcu_read_unlock();
 
 	atomic_long_add(num_pages, &allocated_pages[nid]);
-	mod_lruvec_page_state(p, NR_GPU_ACTIVE, -num_pages);
-	mod_lruvec_page_state(p, NR_GPU_RECLAIM, num_pages);
+	if (!pt->pool || !ttm_pool_uses_dma_alloc(pt->pool)) {
+		mod_lruvec_page_state(p, NR_GPU_ACTIVE, -num_pages);
+		mod_lruvec_page_state(p, NR_GPU_RECLAIM, num_pages);
+	}
 }
 
 static enum lru_status take_one_from_lru(struct list_head *item,
@@ -367,8 +369,10 @@ static struct page *ttm_pool_type_take(struct ttm_pool_type *pt, int nid)
 	ret = list_lru_walk_node(&pt->pages, nid, take_one_from_lru, (void *)&p, &nr_to_walk);
 	if (ret == 1 && p) {
 		atomic_long_sub(1 << pt->order, &allocated_pages[nid]);
-		mod_lruvec_page_state(p, NR_GPU_ACTIVE, (1 << pt->order));
-		mod_lruvec_page_state(p, NR_GPU_RECLAIM, -(1 << pt->order));
+		if (!pt->pool || !ttm_pool_uses_dma_alloc(pt->pool)) {
+			mod_lruvec_page_state(p, NR_GPU_ACTIVE, (1 << pt->order));
+			mod_lruvec_page_state(p, NR_GPU_RECLAIM, -(1 << pt->order));
+		}
 	}
 	return p;
 }

---
base-commit: a90ee4305c4a5df72c11b31dacfdc76e00fcf78a
change-id: 20261008-ttm-gpu-stats-dma-9fc5e952a45b

Best regards,
--  
Lucas Frendorf <lucasfrendorf@proton.me>

