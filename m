From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 09:02:54 +0000
Subject: [PATCH v3 02/14] drm/panfrost: Refuse to sync the CPU caches of a
 heap BO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-panfrost-long-jobs-v3-2-80ae78d38f6e@gmail.com>
References: <20261113-panfrost-long-jobs-v3-0-80ae78d38f6e@gmail.com>
In-Reply-To: <20261113-panfrost-long-jobs-v3-0-80ae78d38f6e@gmail.com>
To: Boris Brezillon <boris.brezillon@collabora.com>, 
 Rob Herring <robh@kernel.org>, Steven Price <steven.price@arm.com>, 
 =?utf-8?q?Adri=C3=A1n_Larumbe?= <adrian.larumbe@collabora.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794560572; l=1768;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=HrsdWKsSgiGXkqlebjInUOvLazjeFD30/bAvYhzVDVs=;
 b=dlCqTBSrojRZUFzJOLlMFkRPGOmIXJ0x6/dG8G1sDEWPKbDF/4+G3xB2st9BIgmevHkEzr5mS
 X68MKJzh15XBSVEagT7ngMK9XkSkW+FOGCdhTwn/r1qy97NxP/J3Wce
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a coherent GPU a heap BO is not write-combined, so PANFROST_SYNC_BO
on it reaches drm_gem_shmem_get_pages_sgt() with bo->base.pages being
the fault handler's sparse page array, and drm_prime_pages_to_sg()
dereferences the NULL entries of the chunks not faulted in yet. With no
chunk faulted in, it pins the whole heap and sets bo->base.pages without
bo->sgts, which the next GPU fault on the heap dereferences.

Heap BOs are not CPU-mappable (panfrost_ioctl_mmap_bo() refuses them,
panfrost_gem_create() refuses PANFROST_BO_WB_MMAP for them), so there is
nothing to sync: return -EINVAL, as for imported BOs.

Found by code review (Sashiko). Not tested on a coherent GPU: on the
Mali-G31 here a heap BO is write-combined and the sync returned early.

Fixes: 7be45f548976 ("drm/panfrost: Add a PANFROST_SYNC_BO ioctl")
Cc: stable@vger.kernel.org
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/sashiko-outbox-206561@kernel.org/
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_gem.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/gpu/drm/panfrost/panfrost_gem.c b/drivers/gpu/drm/panfrost/panfrost_gem.c
index 518f24549..f72edb65b 100644
--- a/drivers/gpu/drm/panfrost/panfrost_gem.c
+++ b/drivers/gpu/drm/panfrost/panfrost_gem.c
@@ -569,6 +569,10 @@ panfrost_gem_sync(struct drm_gem_object *obj, u32 type, u32 offset, u32 size)
 	if (drm_gem_is_imported(&shmem->base))
 		return -EINVAL;
 
+	/* A heap BO's pages and sg tables belong to the GPU fault handler. */
+	if (bo->is_heap)
+		return -EINVAL;
+
 	switch (type) {
 	case PANFROST_BO_SYNC_CPU_CACHE_FLUSH:
 	case PANFROST_BO_SYNC_CPU_CACHE_FLUSH_AND_INVALIDATE:

-- 
2.55.0

