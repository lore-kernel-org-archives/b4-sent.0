From: Aaron Kling <webgeek1234@gmail.com>
Date: Fri, 21 Aug 2026 23:42:59 -0500
Subject: [PATCH v2] drm/nouveau: Use write-combined maps for coherent
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-tegra-coherent-wc-v2-1-2b1ddb67bf18@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ6CMBBFr0Jm7RimEUxdeQ/Dok4HmESoaRvUE
 O5u5QAu30v++yskiSoJLtUKURZNGuYC5lABj24eBNUXBlObtj6bBrMM0SGHUaLMGV+MZO2JPLn
 GtTWU3TNKr++9eesKj5pyiJ/9YqGf/VdbCAl975mtsWzofh0mp48jhwm6bdu+iwT7VbIAAAA=
X-Change-ID: 20260725-tegra-coherent-wc-19941d1a5a60
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Karol Herbst <kherbst@redhat.com>, 
 Faith Ekstrand <faith.ekstrand@collabora.com>, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787373804; l=1825;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=6HYeU8KylnBhcnrcZPOXIGFiI2xLSNaxtWKW6C5P3EY=;
 b=E+K0KUreTCalBE7SgwbmAoYYgW1vWcIP+4h8O5xvCnM/Xw/+v3R7Ojy+JrPJaTgM+vbqU6QDQ
 TqOCd3WkGgIDuzAuBIfm4z/IH0L8P9txEOi2/citcAVSjvqvuIRgS7A
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Faith Ekstrand <faith.ekstrand@collabora.com>

On Tegra devices, uncached maps traslate to device memory, causing
unaligned accesses by userspace resulting in a SIGBUS. Instead, use
write-combined maps to ensure proper access.

This would also affect discrete cards on any Arm device. It was
determined that discrete cards regardless of cpu arch should use
write-combined maps for coherent anyways. Thus this change is made for
all gpu types.

Signed-off-by: Faith Ekstrand <faith.ekstrand@collabora.com>
Co-developed-by: Aaron Kling <webgeek1234@gmail.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Without this change, nouveau can easily hit sigbus errors in the Android
UI rendering via nvk or running vulkan deqp tests on Tegra. Changing
coherent maps to use write-combined stops the crashing.
---
Changes in v2:
- Set write-combined for coherent on all gpu types
- Link to v1: https://lore.kernel.org/r/20260725-tegra-coherent-wc-v1-1-dfdcc929c21b@gmail.com
---
 drivers/gpu/drm/nouveau/nouveau_sgdma.c | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/nouveau/nouveau_sgdma.c b/drivers/gpu/drm/nouveau/nouveau_sgdma.c
index fa3b4ebf38a83..2bd0376193aee 100644
--- a/drivers/gpu/drm/nouveau/nouveau_sgdma.c
+++ b/drivers/gpu/drm/nouveau/nouveau_sgdma.c
@@ -72,9 +72,7 @@ nouveau_sgdma_create_ttm(struct ttm_buffer_object *bo, uint32_t page_flags)
 	struct nouveau_sgdma_be *nvbe;
 	enum ttm_caching caching;
 
-	if (nvbo->force_coherent)
-		caching = ttm_uncached;
-	else if (drm->agp.bridge)
+	if (nvbo->force_coherent || drm->agp.bridge)
 		caching = ttm_write_combined;
 	else
 		caching = ttm_cached;

---
base-commit: 903c1cf6dff9964e71eda98a39e2e5d442050472
change-id: 20260725-tegra-coherent-wc-19941d1a5a60

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

