From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:48:35 +0000
Subject: [PATCH v2 02/11] drm/panfrost: Refuse to sync the CPU caches of a
 heap BO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-panfrost-long-jobs-v2-2-a06830da3d99@gmail.com>
References: <20261112-panfrost-long-jobs-v2-0-a06830da3d99@gmail.com>
In-Reply-To: <20261112-panfrost-long-jobs-v2-0-a06830da3d99@gmail.com>
To: Boris Brezillon <boris.brezillon@collabora.com>, 
 Rob Herring <robh@kernel.org>, Steven Price <steven.price@arm.com>, 
 =?utf-8?q?Adri=C3=A1n_Larumbe?= <adrian.larumbe@collabora.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794473314; l=2148;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=sabqZXiqcOVlHYAJg0avzqnHVWyyC8nVoD/l1btGZFM=;
 b=EZaFwvzELyUZIeDpHLBigkeb0f38sxfR+QENoZ2o+SujrdnYH8BpvXs9ae9t/9l/ldZOF276x
 YSfTG2G0puWDNT6nGnOkBYQFT6SpvtrNj4eOEBTq5fOfdol2A12jwoK
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

panfrost_gem_sync() calls drm_gem_shmem_get_pages_sgt() on any BO that is
not write-combined. Heap BOs are write-combined only on non-coherent
GPUs; on a coherent one, a PANFROST_SYNC_BO on a heap BO reaches
drm_gem_shmem_get_pages_sgt() with bo->base.pages being the sparse page
array of the GPU fault handler, and drm_prime_pages_to_sg() dereferences
the NULL entries of the chunks not faulted in yet. On a heap BO with no
chunk faulted in yet, it instead pins the whole heap and leaves
bo->base.pages set without bo->sgts, and the next GPU fault on the heap
dereferences the NULL bo->sgts.

Heap BOs are not CPU-mappable (panfrost_ioctl_mmap_bo() refuses them, and
panfrost_gem_create() refuses PANFROST_BO_WB_MMAP for them), so there is
nothing to sync: return -EINVAL, as for imported BOs.

Found by code review (Sashiko). Not tested on a coherent GPU: the
Mali-G31 here is not coherent, so a heap BO is write-combined and the
sync returned early before.

Fixes: 7be45f548976 ("drm/panfrost: Add a PANFROST_SYNC_BO ioctl")
Cc: stable@vger.kernel.org
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/sashiko-outbox-206561@kernel.org/
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_gem.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/gpu/drm/panfrost/panfrost_gem.c b/drivers/gpu/drm/panfrost/panfrost_gem.c
index 518f24549..5d3925abd 100644
--- a/drivers/gpu/drm/panfrost/panfrost_gem.c
+++ b/drivers/gpu/drm/panfrost/panfrost_gem.c
@@ -569,6 +569,14 @@ panfrost_gem_sync(struct drm_gem_object *obj, u32 type, u32 offset, u32 size)
 	if (drm_gem_is_imported(&shmem->base))
 		return -EINVAL;
 
+	/* Heap BOs are not CPU-mappable, and their pages are populated by the
+	 * GPU fault handler, one 2 MB chunk at a time, with a page array and
+	 * sg tables of its own: drm_gem_shmem_get_pages_sgt() must not touch
+	 * them.
+	 */
+	if (bo->is_heap)
+		return -EINVAL;
+
 	switch (type) {
 	case PANFROST_BO_SYNC_CPU_CACHE_FLUSH:
 	case PANFROST_BO_SYNC_CPU_CACHE_FLUSH_AND_INVALIDATE:

-- 
2.55.0

