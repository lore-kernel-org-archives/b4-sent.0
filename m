From: Aaron Kling <webgeek1234@gmail.com>
Date: Sat, 25 Jul 2026 18:28:32 -0500
Subject: [PATCH RFC] drm/nouveau: Use write-combined maps for coherent on
 Tegra
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260725-tegra-coherent-wc-v1-1-dfdcc929c21b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDcyNT3ZLU9KJE3eT8jNSi1LwS3fJkXUNLSxPDFMNE00QzAyWgvoKi1LT
 MCrCZ0UpBbs5KsbW1AA2ZuwFoAAAA
X-Change-ID: 20260725-tegra-coherent-wc-19941d1a5a60
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Faith Ekstrand <faith.ekstrand@collabora.com>, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785022113; l=1746;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=xGh6pnkZaocwOU8pE4vCOlQMWxF+mRIdr+h8cac+BR8=;
 b=sZmYcD/8oqKCgPrreK+uUgwVNQC8Jhvg4Efd/oYQ2kQl27ZNYV1yAG5oJGt6ob13Hf9ei1CYJ
 FamnB0RS4/7Bo+AHo4Uv/Koyj/a4UZPu1n3Z6O1Iyb6aXJKPXnmi/sJ
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Faith Ekstrand <faith.ekstrand@collabora.com>

On Tegra devices, uncached maps traslate to device memory, causing
unaligned accesses by userspace resulting in a SIGBUS. Instead, use
write-combined maps to ensure proper access.

Signed-off-by: Faith Ekstrand <faith.ekstrand@collabora.com>
Co-developed-by: Aaron Kling <webgeek1234@gmail.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
This patch is marked RFC because there is not complete confidence that
the change is correct. Without this change, nouveau can easily hit
sigbus errors in Android UI rendering via nvk or running vulkan deqp
tests on Tegra. Changing coherent maps to use write-combined stops the
crashing, but it is unknown what the performance impact is, if any.
---
 drivers/gpu/drm/nouveau/nouveau_sgdma.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/nouveau/nouveau_sgdma.c b/drivers/gpu/drm/nouveau/nouveau_sgdma.c
index fa3b4ebf38a83..10f6ef1c541bd 100644
--- a/drivers/gpu/drm/nouveau/nouveau_sgdma.c
+++ b/drivers/gpu/drm/nouveau/nouveau_sgdma.c
@@ -72,9 +72,12 @@ nouveau_sgdma_create_ttm(struct ttm_buffer_object *bo, uint32_t page_flags)
 	struct nouveau_sgdma_be *nvbe;
 	enum ttm_caching caching;
 
-	if (nvbo->force_coherent)
-		caching = ttm_uncached;
-	else if (drm->agp.bridge)
+	if (nvbo->force_coherent) {
+		if (drm->client.device.info.platform == NV_DEVICE_INFO_V0_SOC)
+			caching = ttm_write_combined;
+		else
+			caching = ttm_uncached;
+	} else if (drm->agp.bridge)
 		caching = ttm_write_combined;
 	else
 		caching = ttm_cached;

---
base-commit: 1a1757b76427f6201bfe0bf1bea9f7574f332a93
change-id: 20260725-tegra-coherent-wc-19941d1a5a60

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

