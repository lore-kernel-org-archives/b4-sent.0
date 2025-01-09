From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Thu, 09 Jan 2025 23:07:51 +0100
Subject: [PATCH] drm/virtio: Align host mapping request to maximum platform
 page size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250109-virtgpu-mixed-page-size-v1-1-c8fe1e1859f3@gmail.com>
X-B4-Tracking: v=1; b=H4sIALZIgGcC/xWMQQ5AMBAAvyJ7tkltSPAVcSi27AFNSyPE363jJ
 DPzQOQgHKHNHgicJMq+KRR5BuNit5lRJmUgQ5UpTINJwjH7E1e5eEJv1YhyM1JNQ+1Ka8iNoLU
 P7FT5z13/vh/0keKGaQAAAA==
X-Change-ID: 20250109-virtgpu-mixed-page-size-282b8f4a02fc
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736460471; l=1517;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=lIIbgfeZ3OArzbnTe9ftPQjp52A5SwWq2Us6yyQ7tQ0=;
 b=GRQcjPla8yqP6JTh2Z3QypfIo8fRlvmdI6WroBA0UzI9AhZMUTpbwOaw9hNIUDcWLGZG+FP0F
 m5oIlszkSqaDOhv+fa55vMcxXApmSENNLbgryQUg7vvN+LnGTqHqaue
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This allows running different page sizes between host and guest on
platforms that support mixed page sizes.

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 drivers/gpu/drm/virtio/virtgpu_vram.c | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/virtio/virtgpu_vram.c b/drivers/gpu/drm/virtio/virtgpu_vram.c
index 25df81c027837c248a746e41856b5aa7e216b8d5..8a0577c2170ec9c12cad12be57f9a41c14f04660 100644
--- a/drivers/gpu/drm/virtio/virtgpu_vram.c
+++ b/drivers/gpu/drm/virtio/virtgpu_vram.c
@@ -138,6 +138,12 @@ bool virtio_gpu_is_vram(struct virtio_gpu_object *bo)
 	return bo->base.base.funcs == &virtio_gpu_vram_funcs;
 }
 
+#if defined(__powerpc64__) || defined(__aarch64__) || defined(__mips__) || defined(__loongarch__)
+#define MAX_PAGE_SIZE 65536
+#else
+#define MAX_PAGE_SIZE PAGE_SIZE
+#endif
+
 static int virtio_gpu_vram_map(struct virtio_gpu_object *bo)
 {
 	int ret;
@@ -150,8 +156,8 @@ static int virtio_gpu_vram_map(struct virtio_gpu_object *bo)
 		return -EINVAL;
 
 	spin_lock(&vgdev->host_visible_lock);
-	ret = drm_mm_insert_node(&vgdev->host_visible_mm, &vram->vram_node,
-				 bo->base.base.size);
+	ret = drm_mm_insert_node_generic(&vgdev->host_visible_mm, &vram->vram_node,
+					 bo->base.base.size, MAX_PAGE_SIZE, 0, 0);
 	spin_unlock(&vgdev->host_visible_lock);
 
 	if (ret)

---
base-commit: 643e2e259c2b25a2af0ae4c23c6e16586d9fd19c
change-id: 20250109-virtgpu-mixed-page-size-282b8f4a02fc

