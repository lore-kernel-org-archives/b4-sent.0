From: Noralf Trønnes <noralf@tronnes.org>
Date: Wed, 30 Nov 2022 20:26:51 +0100
Subject: [PATCH v2 3/6] drm/gud: Split up gud_flush_work()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20221122-gud-shadow-plane-v2-3-435037990a83@tronnes.org>
References: <20221122-gud-shadow-plane-v2-0-435037990a83@tronnes.org>
In-Reply-To: <20221122-gud-shadow-plane-v2-0-435037990a83@tronnes.org>
To: Thomas Zimmermann <tzimmermann@suse.de>, Javier Martinez Canillas <javierm@redhat.com>,
 dri-devel@lists.freedesktop.org, Maxime Ripard <mripard@kernel.org>, stable@vger.kernel.org,
 Noralf Trønnes <noralf@tronnes.org>
X-Mailer: b4 0.11.0-dev-cc6f6
X-Developer-Signature: v=1; a=ed25519-sha256; t=1669836415; l=3363;
 i=noralf@tronnes.org; s=20221122; h=from:subject:message-id;
 bh=lCjGzAZ7bxM1S7qLvHQeXQGVjd0Bi+R8x1irdlf9+K4=;
 b=nluNP2lX6N1D8IYrI+Ot2A8Jv5nz5hR4qkTIatQN1EQj8cV3TpAztjUfYW1VPRyiCOVBXeqbTpQ5
 +b/9xNdVB/FTHfFAUsG5iFUN1wKeImtf/y6Y2AQhpBodcDtgmdmC
X-Developer-Key: i=noralf@tronnes.org; a=ed25519;
 pk=0o9is4iddvvlrY3yON5SVtAbgPnVs0LfQsjfqR2Hvz8=
X-Endpoint-Received: by B4 Submission Endpoint for noralf@tronnes.org/20221122 with auth_id=8
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

In preparation for inlining synchronous flushing split out the part of
gud_flush_work() that can be shared by the sync and async code paths.

Reviewed-by: Javier Martinez Canillas <javierm@redhat.com>
Reviewed-by: Thomas Zimmermann <tzimmermann@suse.de>
Signed-off-by: Noralf Trønnes <noralf@tronnes.org>
---
 drivers/gpu/drm/gud/gud_pipe.c | 72 +++++++++++++++++++++++-------------------
 1 file changed, 39 insertions(+), 33 deletions(-)

diff --git a/drivers/gpu/drm/gud/gud_pipe.c b/drivers/gpu/drm/gud/gud_pipe.c
index ff1358815af5..d2af9947494f 100644
--- a/drivers/gpu/drm/gud/gud_pipe.c
+++ b/drivers/gpu/drm/gud/gud_pipe.c
@@ -333,15 +333,49 @@ void gud_clear_damage(struct gud_device *gdrm)
 	gdrm->damage.y2 = 0;
 }
 
+static void gud_flush_damage(struct gud_device *gdrm, struct drm_framebuffer *fb,
+			     struct drm_rect *damage)
+{
+	const struct drm_format_info *format;
+	unsigned int i, lines;
+	size_t pitch;
+	int ret;
+
+	format = fb->format;
+	if (format->format == DRM_FORMAT_XRGB8888 && gdrm->xrgb8888_emulation_format)
+		format = gdrm->xrgb8888_emulation_format;
+
+	/* Split update if it's too big */
+	pitch = drm_format_info_min_pitch(format, 0, drm_rect_width(damage));
+	lines = drm_rect_height(damage);
+
+	if (gdrm->bulk_len < lines * pitch)
+		lines = gdrm->bulk_len / pitch;
+
+	for (i = 0; i < DIV_ROUND_UP(drm_rect_height(damage), lines); i++) {
+		struct drm_rect rect = *damage;
+
+		rect.y1 += i * lines;
+		rect.y2 = min_t(u32, rect.y1 + lines, damage->y2);
+
+		ret = gud_flush_rect(gdrm, fb, format, &rect);
+		if (ret) {
+			if (ret != -ENODEV && ret != -ECONNRESET &&
+			    ret != -ESHUTDOWN && ret != -EPROTO)
+				dev_err_ratelimited(fb->dev->dev,
+						    "Failed to flush framebuffer: error=%d\n", ret);
+			gdrm->prev_flush_failed = true;
+			break;
+		}
+	}
+}
+
 void gud_flush_work(struct work_struct *work)
 {
 	struct gud_device *gdrm = container_of(work, struct gud_device, work);
-	const struct drm_format_info *format;
 	struct drm_framebuffer *fb;
 	struct drm_rect damage;
-	unsigned int i, lines;
-	int idx, ret = 0;
-	size_t pitch;
+	int idx;
 
 	if (!drm_dev_enter(&gdrm->drm, &idx))
 		return;
@@ -356,35 +390,7 @@ void gud_flush_work(struct work_struct *work)
 	if (!fb)
 		goto out;
 
-	format = fb->format;
-	if (format->format == DRM_FORMAT_XRGB8888 && gdrm->xrgb8888_emulation_format)
-		format = gdrm->xrgb8888_emulation_format;
-
-	/* Split update if it's too big */
-	pitch = drm_format_info_min_pitch(format, 0, drm_rect_width(&damage));
-	lines = drm_rect_height(&damage);
-
-	if (gdrm->bulk_len < lines * pitch)
-		lines = gdrm->bulk_len / pitch;
-
-	for (i = 0; i < DIV_ROUND_UP(drm_rect_height(&damage), lines); i++) {
-		struct drm_rect rect = damage;
-
-		rect.y1 += i * lines;
-		rect.y2 = min_t(u32, rect.y1 + lines, damage.y2);
-
-		ret = gud_flush_rect(gdrm, fb, format, &rect);
-		if (ret) {
-			if (ret != -ENODEV && ret != -ECONNRESET &&
-			    ret != -ESHUTDOWN && ret != -EPROTO)
-				dev_err_ratelimited(fb->dev->dev,
-						    "Failed to flush framebuffer: error=%d\n", ret);
-			gdrm->prev_flush_failed = true;
-			break;
-		}
-
-		gdrm->prev_flush_failed = false;
-	}
+	gud_flush_damage(gdrm, fb, &damage);
 
 	drm_framebuffer_put(fb);
 out:

-- 
2.34.1
