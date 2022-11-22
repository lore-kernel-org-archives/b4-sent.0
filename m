From: =?utf-8?q?Noralf=20Tr=C3=B8nnes?= <noralf@tronnes.org>
Date: Tue, 22 Nov 2022 21:58:42 +0100
Subject: [PATCH 4/6] drm/gud: Split up gud_flush_work()
MIME-Version: 1.0
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset="utf-8"
Message-Id: <20221122-gud-shadow-plane-v1-4-9de3afa3383e@tronnes.org>
References: <20221122-gud-shadow-plane-v1-0-9de3afa3383e@tronnes.org>
In-Reply-To: <20221122-gud-shadow-plane-v1-0-9de3afa3383e@tronnes.org>
To: Thomas Zimmermann <tzimmermann@suse.de>, stable@vger.kernel.org, Dave Airlie <airlied@redhat.com>,
 dri-devel@lists.freedesktop.org, Hans de Goede <hdegoede@redhat.com>, Noralf Trønnes <noralf@tronnes.org>,
 Maxime Ripard <mripard@kernel.org>, Javier Martinez Canillas <javierm@redhat.com>
X-Mailer: b4 0.10.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1669150743; l=3252;
 i=noralf@tronnes.org; s=20221122; h=from:subject:message-id;
 bh=ahKXg6Xr5HyjHv3T70OJ3XcsDN6UVfaIf3j92RcQJLk=;
 b=hkaLXrdhOvsy9qN2VfPsRyfI9DZkqa2UeUx0U0XU0wFHKawXhNL2KI2S1T+ur/NDk3fi8kqzYPF/
 TjXmjMmeDSfIANrGmBl1cTuF7PzO6FiDTYqy1fc07oh/atsvo1XY
X-Developer-Key: i=noralf@tronnes.org; a=ed25519;
 pk=0o9is4iddvvlrY3yON5SVtAbgPnVs0LfQsjfqR2Hvz8=
X-Endpoint-Received: by B4 Submission Endpoint for noralf@tronnes.org/20221122 with auth_id=8
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

In preparation for inlining synchronous flushing split out the part of
gud_flush_work() that can be shared by the sync and async code paths.

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
b4 0.10.1
