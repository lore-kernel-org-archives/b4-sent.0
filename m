From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Thu, 09 Jan 2025 22:45:46 +0100
Subject: [PATCH] drm/virtio: Support partial maps of GEM objects
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250109-virtgpu-gem-partial-map-v1-1-a914b48776bd@gmail.com>
X-B4-Tracking: v=1; b=H4sIAIlDgGcC/x3MTQqAIBBA4avErBvQSqGuEi2kJhvoR8aKILx70
 vJbvPdCJGGK0BUvCN0c+dgzdFnAuLjdE/KUDZWqjNKqxZvl9OFCTxsGJye7FTcXsK4NjY2yxk4
 ach2EZn7+cz+k9AG7IPqtaQAAAA==
X-Change-ID: 20250109-virtgpu-gem-partial-map-335ec40656d1
To: David Airlie <airlied@redhat.com>, Gerd Hoffmann <kraxel@redhat.com>, 
 Gurchetan Singh <gurchetansingh@chromium.org>, 
 Chia-I Wu <olvaffe@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, virtualization@lists.linux.dev, 
 linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736459146; l=1210;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=6LaFAVHHmrz+1IfVs72P1kiVYM0D1mQ7zg4Ht9kbRhU=;
 b=a9a4yi1JLL93u7BZpaJzIF6IITCFbBFAUMuKnh7fGXMrwgkF7Il9gEb5VBIkbOhjguOZiL1zz
 12Ar6JMxxb5AnfUsdFILyBjAOjDb96QbUMLStBIL0vBG1sNmoeNR72p
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Those are useful to implement coherent cross-vm mmap.

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 drivers/gpu/drm/virtio/virtgpu_vram.c | 5 ++---
 1 file changed, 2 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/virtio/virtgpu_vram.c b/drivers/gpu/drm/virtio/virtgpu_vram.c
index 25df81c027837c248a746e41856b5aa7e216b8d5..64e2c6dbdd678ac4c0da89fdd4c9dbf937c2c335 100644
--- a/drivers/gpu/drm/virtio/virtgpu_vram.c
+++ b/drivers/gpu/drm/virtio/virtgpu_vram.c
@@ -56,12 +56,11 @@ static int virtio_gpu_vram_mmap(struct drm_gem_object *obj,
 	else if (vram->map_info == VIRTIO_GPU_MAP_CACHE_UNCACHED)
 		vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);
 
-	/* Partial mappings of GEM buffers don't happen much in practice. */
-	if (vm_size != vram->vram_node.size)
+	if (vm_size > vram->vram_node.size)
 		return -EINVAL;
 
 	ret = io_remap_pfn_range(vma, vma->vm_start,
-				 vram->vram_node.start >> PAGE_SHIFT,
+				 (vram->vram_node.start >> PAGE_SHIFT) + vma->vm_pgoff,
 				 vm_size, vma->vm_page_prot);
 	return ret;
 }

---
base-commit: 643e2e259c2b25a2af0ae4c23c6e16586d9fd19c
change-id: 20250109-virtgpu-gem-partial-map-335ec40656d1

