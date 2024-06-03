From: =?utf-8?q?Noralf_Tr=C3=B8nnes?= <noralf@tronnes.org>
Date: Mon, 03 Jun 2024 13:21:36 +0200
Subject: [PATCH v3 5/5] drm/tiny: panel-mipi-dbi: Support the pixel format
 property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240603-panel-mipi-dbi-rgb666-v3-5-59ed53ca73da@tronnes.org>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717413714; l=2983;
 i=noralf@tronnes.org; s=20221122; h=from:subject:message-id;
 bh=NSd8WCcz3mEyAmd3gnS4mEuzeD9kKvKEnfrPdQSMiME=;
 b=rk0s0cf6Z4JK2YWt1WV6F4iBsGXgYmUNe3I+/zuyMQRncbIMF048+BhY4RB3VVtvWGpa02jCb
 deRkn0xd3SVCUcdQPO6WsYavAgKix3ZiHgELhc0Xj56fE8BoEKQ1Jhz
X-Developer-Key: i=noralf@tronnes.org; a=ed25519;
 pk=0o9is4iddvvlrY3yON5SVtAbgPnVs0LfQsjfqR2Hvz8=
X-Endpoint-Received: by B4 Relay for noralf@tronnes.org/20221122 with auth_id=8
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for these pixel format property values:
- r5g6b5, RGB565
- b6x2g6x2r6x2, BGR666

BGR666 is presented to userspace as RGB888. The 2 LSB in each color
are discarded by the controller. The pixel is sent on the wire using
8 bits per word (little endian) so the controller sees it as BGR.

RGB565 is the default if the property is not present.

Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: Noralf Trønnes <noralf@tronnes.org>
---
 drivers/gpu/drm/tiny/panel-mipi-dbi.c | 55 ++++++++++++++++++++++++++++++++++-
 1 file changed, 54 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/tiny/panel-mipi-dbi.c b/drivers/gpu/drm/tiny/panel-mipi-dbi.c
index f80a141fcf36..f3aa2abce314 100644
--- a/drivers/gpu/drm/tiny/panel-mipi-dbi.c
+++ b/drivers/gpu/drm/tiny/panel-mipi-dbi.c
@@ -26,6 +26,49 @@
 
 #include <video/mipi_display.h>
 
+struct panel_mipi_dbi_format {
+	const char *name;
+	u32 fourcc;
+	unsigned int bpp;
+};
+
+static const struct panel_mipi_dbi_format panel_mipi_dbi_formats[] = {
+	{ "r5g6b5", DRM_FORMAT_RGB565, 16 },
+	{ "b6x2g6x2r6x2", DRM_FORMAT_RGB888, 24 },
+};
+
+static int panel_mipi_dbi_get_format(struct device *dev, u32 *formats, unsigned int *bpp)
+{
+	const char *format_name;
+	unsigned int i;
+	int ret;
+
+	formats[1] = DRM_FORMAT_XRGB8888;
+
+	ret = device_property_read_string(dev, "format", &format_name);
+	if (ret) {
+		/* Old Device Trees don't have this property */
+		formats[0] = DRM_FORMAT_RGB565;
+		*bpp = 16;
+		return 0;
+	}
+
+	for (i = 0; i < ARRAY_SIZE(panel_mipi_dbi_formats); i++) {
+		const struct panel_mipi_dbi_format *format = &panel_mipi_dbi_formats[i];
+
+		if (strcmp(format_name, format->name))
+			continue;
+
+		formats[0] = format->fourcc;
+		*bpp = format->bpp;
+		return 0;
+	}
+
+	dev_err(dev, "Pixel format is not supported: '%s'\n", format_name);
+
+	return -EINVAL;
+}
+
 static const u8 panel_mipi_dbi_magic[15] = { 'M', 'I', 'P', 'I', ' ', 'D', 'B', 'I',
 					     0, 0, 0, 0, 0, 0, 0 };
 
@@ -276,6 +319,9 @@ static int panel_mipi_dbi_spi_probe(struct spi_device *spi)
 	struct drm_device *drm;
 	struct mipi_dbi *dbi;
 	struct gpio_desc *dc;
+	unsigned int bpp;
+	size_t buf_size;
+	u32 formats[2];
 	int ret;
 
 	dbidev = devm_drm_dev_alloc(dev, &panel_mipi_dbi_driver, struct mipi_dbi_dev, drm);
@@ -323,7 +369,14 @@ static int panel_mipi_dbi_spi_probe(struct spi_device *spi)
 	if (IS_ERR(dbidev->driver_private))
 		return PTR_ERR(dbidev->driver_private);
 
-	ret = mipi_dbi_dev_init(dbidev, &panel_mipi_dbi_pipe_funcs, &mode, 0);
+	ret = panel_mipi_dbi_get_format(dev, formats, &bpp);
+	if (ret)
+		return ret;
+
+	buf_size = DIV_ROUND_UP(mode.hdisplay * mode.vdisplay * bpp, 8);
+	ret = mipi_dbi_dev_init_with_formats(dbidev, &panel_mipi_dbi_pipe_funcs,
+					     formats, ARRAY_SIZE(formats),
+					     &mode, 0, buf_size);
 	if (ret)
 		return ret;
 

-- 
2.45.1

