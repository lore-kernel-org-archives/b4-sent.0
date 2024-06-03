From: =?utf-8?q?Noralf_Tr=C3=B8nnes?= <noralf@tronnes.org>
Date: Mon, 03 Jun 2024 13:21:35 +0200
Subject: [PATCH v3 4/5] drm/mipi-dbi: Add support for DRM_FORMAT_RGB888
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240603-panel-mipi-dbi-rgb666-v3-4-59ed53ca73da@tronnes.org>
References: <20240603-panel-mipi-dbi-rgb666-v3-0-59ed53ca73da@tronnes.org>
In-Reply-To: <20240603-panel-mipi-dbi-rgb666-v3-0-59ed53ca73da@tronnes.org>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, Sam Ravnborg <sam@ravnborg.org>, 
 David Airlie <airlied@gmail.com>, Daniel Vetter <daniel@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Lechner <david@lechnology.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Kamlesh Gurudasani <kamlesh.gurudasani@gmail.com>, 
 Tommaso Merciai <tommaso.merciai@amarulasolutions.com>, 
 =?utf-8?q?Noralf_Tr=C3=B8nnes?= <noralf@tronnes.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717413714; l=5004;
 i=noralf@tronnes.org; s=20221122; h=from:subject:message-id;
 bh=NtI71S7qYFvJKxnnpF9sBqJW6UBDbKXW4W6XWCEPzEY=;
 b=/UU9GgDJ9YL9QphxZFmp1tSU8LpQy7IMUWbdVSQzfov3HnX//IFGl4Y8zlx8GQhRBHDjVBcmS
 AauvRxanc6TCfMwDqfiAEm7UXSq8r6b8+1GrZVbAEXh7Ep5kYx1X6Zh
X-Developer-Key: i=noralf@tronnes.org; a=ed25519;
 pk=0o9is4iddvvlrY3yON5SVtAbgPnVs0LfQsjfqR2Hvz8=
X-Endpoint-Received: by B4 Relay for noralf@tronnes.org/20221122 with auth_id=8
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DRM_FORMAT_RGB888 is 24 bits per pixel and it would be natural to send it
on the SPI bus using a 24 bits per word transfer. The problem with this
is that not all SPI controllers support 24 bpw.

Since DRM_FORMAT_RGB888 is stored in memory as little endian and the SPI
bus is big endian we use 8 bpw to always get the same pixel format on the
bus: b8g8r8.

The MIPI DCS specification lists the standard commands that can be sent
over the MIPI DBI interface. The set_address_mode (36h) command has one
bit in the parameter that controls RGB/BGR order. This means that the
controller can be configured to receive the pixel as BGR.

RGB888 is rarely supported on these controllers but RGB666 is very common.
All datasheets I have seen do at least support the pixel format option
where each color is sent as one byte and the 6 MSB's are used.

All this put together means that we can send each pixel as b8g8r8 and an
RGB666 capable controller sees this as b6x2g6x2r6x2.

Signed-off-by: Noralf Trønnes <noralf@tronnes.org>
---
 drivers/gpu/drm/drm_mipi_dbi.c | 29 +++++++++++++++++++++++++----
 include/drm/drm_mipi_dbi.h     |  5 +++++
 2 files changed, 30 insertions(+), 4 deletions(-)

diff --git a/drivers/gpu/drm/drm_mipi_dbi.c b/drivers/gpu/drm/drm_mipi_dbi.c
index 77f8a828d6e0..eb330676857c 100644
--- a/drivers/gpu/drm/drm_mipi_dbi.c
+++ b/drivers/gpu/drm/drm_mipi_dbi.c
@@ -206,6 +206,7 @@ int mipi_dbi_buf_copy(void *dst, struct iosys_map *src, struct drm_framebuffer *
 		      struct drm_rect *clip, bool swap,
 		      struct drm_format_conv_state *fmtcnv_state)
 {
+	struct mipi_dbi_dev *dbidev = drm_to_mipi_dbi_dev(fb->dev);
 	struct drm_gem_object *gem = drm_gem_fb_get_obj(fb, 0);
 	struct iosys_map dst_map = IOSYS_MAP_INIT_VADDR(dst);
 	int ret;
@@ -222,8 +223,18 @@ int mipi_dbi_buf_copy(void *dst, struct iosys_map *src, struct drm_framebuffer *
 		else
 			drm_fb_memcpy(&dst_map, NULL, src, fb, clip);
 		break;
+	case DRM_FORMAT_RGB888:
+		drm_fb_memcpy(&dst_map, NULL, src, fb, clip);
+		break;
 	case DRM_FORMAT_XRGB8888:
-		drm_fb_xrgb8888_to_rgb565(&dst_map, NULL, src, fb, clip, fmtcnv_state, swap);
+		switch (dbidev->emulation_format) {
+		case DRM_FORMAT_RGB565:
+			drm_fb_xrgb8888_to_rgb565(&dst_map, NULL, src, fb, clip, fmtcnv_state, swap);
+			break;
+		case DRM_FORMAT_RGB888:
+			drm_fb_xrgb8888_to_rgb888(&dst_map, NULL, src, fb, clip, fmtcnv_state);
+			break;
+		}
 		break;
 	default:
 		drm_err_once(fb->dev, "Format is not supported: %p4cc\n",
@@ -260,9 +271,11 @@ static void mipi_dbi_fb_dirty(struct iosys_map *src, struct drm_framebuffer *fb,
 	struct mipi_dbi_dev *dbidev = drm_to_mipi_dbi_dev(fb->dev);
 	unsigned int height = rect->y2 - rect->y1;
 	unsigned int width = rect->x2 - rect->x1;
+	const struct drm_format_info *dst_format;
 	struct mipi_dbi *dbi = &dbidev->dbi;
 	bool swap = dbi->swap_bytes;
 	int ret = 0;
+	size_t len;
 	bool full;
 	void *tr;
 
@@ -283,8 +296,13 @@ static void mipi_dbi_fb_dirty(struct iosys_map *src, struct drm_framebuffer *fb,
 	mipi_dbi_set_window_address(dbidev, rect->x1, rect->x2 - 1, rect->y1,
 				    rect->y2 - 1);
 
-	ret = mipi_dbi_command_buf(dbi, MIPI_DCS_WRITE_MEMORY_START, tr,
-				   width * height * 2);
+	if (fb->format->format == DRM_FORMAT_XRGB8888)
+		dst_format = drm_format_info(dbidev->emulation_format);
+	else
+		dst_format = fb->format;
+	len = drm_format_info_min_pitch(dst_format, 0, width) * height;
+
+	ret = mipi_dbi_command_buf(dbi, MIPI_DCS_WRITE_MEMORY_START, tr, len);
 err_msg:
 	if (ret)
 		drm_err_once(fb->dev, "Failed to update display %d\n", ret);
@@ -572,7 +590,7 @@ static const uint32_t mipi_dbi_formats[] = {
  * has one fixed &drm_display_mode which is rotated according to @rotation.
  * This mode is used to set the mode config min/max width/height properties.
  *
- * Use mipi_dbi_dev_init() if you don't need custom formats.
+ * Use mipi_dbi_dev_init() if you want native RGB565 and emulated XRGB8888 format.
  *
  * Note:
  * Some of the helper functions expects RGB565 to be the default format and the
@@ -631,6 +649,9 @@ int mipi_dbi_dev_init_with_formats(struct mipi_dbi_dev *dbidev,
 	drm->mode_config.min_height = dbidev->mode.vdisplay;
 	drm->mode_config.max_height = dbidev->mode.vdisplay;
 	dbidev->rotation = rotation;
+	dbidev->emulation_format = formats[0];
+	if (formats[0] == DRM_FORMAT_RGB888)
+		dbidev->dbi.write_memory_bpw = 8;
 
 	DRM_DEBUG_KMS("rotation = %u\n", rotation);
 
diff --git a/include/drm/drm_mipi_dbi.h b/include/drm/drm_mipi_dbi.h
index b36596efdcc3..85bf19b98cee 100644
--- a/include/drm/drm_mipi_dbi.h
+++ b/include/drm/drm_mipi_dbi.h
@@ -101,6 +101,11 @@ struct mipi_dbi_dev {
 	 */
 	struct drm_display_mode mode;
 
+	/**
+	 * @emulation_format: Pixel format to use when emulating XRGB8888
+	 */
+	u32 emulation_format;
+
 	/**
 	 * @tx_buf: Buffer used for transfer (copy clip rect area)
 	 */

-- 
2.45.1

