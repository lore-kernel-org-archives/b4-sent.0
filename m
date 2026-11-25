From: David Heidelberg <david@ixit.cz>
Date: Wed, 25 Nov 2026 14:08:13 +0100
Subject: [PATCH v3 2/5] drm/panel: lg-sw43408: skip backlight updates when
 unprepared
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-fix-blueline-panel-v3-2-914b4a30b73e@ixit.cz>
References: <20261125-fix-blueline-panel-v3-0-914b4a30b73e@ixit.cz>
In-Reply-To: <20261125-fix-blueline-panel-v3-0-914b4a30b73e@ixit.cz>
To: Abel Vesa <abelvesa@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Airlie <airlied@gmail.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, Jessica Zhang <jesszhan0024@gmail.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Maxime Ripard <mripard@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Simona Vetter <simona@ffwll.ch>, Sumit Semwal <sumit.semwal@linaro.org>, 
 Thomas Zimmermann <tzimmermann@suse.de>, Vinod Koul <vkoul@kernel.org>
Cc: devicetree@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2376; i=david@ixit.cz;
 h=from:subject:message-id; bh=eVtvNYF6Jw8G9i6E3BdhxsPEl/EphHJG2zF/4pJIRNY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrBt3BU/zs+0xLgw8sbeQMDWdbnEnjAHYDFIFcU
 a4B+64hqpeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawbdwQAKCRBgAj/E00kg
 crz7D/9B3BrWRhTlBxnU+3RW/MIdg6N0RlHDN9rWz2Szg9W0wGtGJ564NXWE5cemGMm6gqq6j1O
 oZQ45evMbnxKADAaBgshhOnaUdCFnHLQJEEPKPguHH0z1V7I/22q23Zap8QmaDY2+rR6jI1GMD2
 K9qvib52tQXT/UlPDtNC+KqyK0SoU+XdMSYSLaAhswWndbA7dcVpuJx5MyCb1PXOHdIjW/u4qFE
 MYrN+mosXGWVejeOu/M44ig39sQev97rKlUytd5X17Lm0nu/V5chi5QjnZHHAFxSbaAR3VjYudJ
 AQQ11Ia7+QbGNd2IBlB/cTIa6K6HysGOPfNVd/qOl5fDOhkFGHJzXLHco5IoANKWLHkUrp4wdpc
 kWAKomEwqm//8CirPVO0IE0hFRl5s6rbjfY+V18A9Ik0OCWT28x3k0HW3jp+RzyQw/OlVfjWXoZ
 o7c/I4WEGfF1nGP/1Y44XKNOkuVA3pEoUM8OKkP6/P/O5DNeEim9hLPP6qQm5PnYo2Ps8OJ4diY
 QduR3Dsxukuf7A8zoY45WvJxp41dJMB/N0WxCvwCmA8/f3Mwamvt9SwPC2QgCkPe1UPhw/3VfgH
 Q018ShRjmK/Ei3mwTqy+UJ2drkk9BM25uQuQQMxImX3U8PsNfH+KZ/NFQBHtmFC5cbNeIOhmXpg
 bqcOgQJisRC1+xg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sw43408_backlight_update_status() unconditionally sends a MIPI DSI DCS
brightness command even when the panel is unprepared and the DSI host is
powered down, causing sysfs brightness writes while blanked to fail with
-EIO.

Pass struct sw43408_panel as the backlight device private data and return
early when !ctx->base.prepared, matching other mainline MIPI DSI panel
drivers.

Fixes: 069a6c0e94f9 ("drm: panel: Add LG sw43408 panel driver")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-lg-sw43408.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-lg-sw43408.c b/drivers/gpu/drm/panel/panel-lg-sw43408.c
index 92cab6478ea61..7f7d7b6b17f61 100644
--- a/drivers/gpu/drm/panel/panel-lg-sw43408.c
+++ b/drivers/gpu/drm/panel/panel-lg-sw43408.c
@@ -181,20 +181,23 @@ static const struct drm_display_mode lh546wf1_ed01_mode = {
 static int sw43408_get_modes(struct drm_panel *panel,
 			     struct drm_connector *connector)
 {
 	return drm_connector_helper_get_modes_fixed(connector, &lh546wf1_ed01_mode);
 }
 
 static int sw43408_backlight_update_status(struct backlight_device *bl)
 {
-	struct mipi_dsi_device *dsi = bl_get_data(bl);
+	struct sw43408_panel *ctx = bl_get_data(bl);
 	u16 brightness = backlight_get_brightness(bl);
 
-	return mipi_dsi_dcs_set_display_brightness_large(dsi, brightness);
+	if (!ctx->base.prepared)
+		return 0;
+
+	return mipi_dsi_dcs_set_display_brightness_large(ctx->link, brightness);
 }
 
 static const struct backlight_ops sw43408_backlight_ops = {
 	.update_status = sw43408_backlight_update_status,
 };
 
 static int sw43408_backlight_init(struct sw43408_panel *ctx)
 {
@@ -202,17 +205,17 @@ static int sw43408_backlight_init(struct sw43408_panel *ctx)
 	const struct backlight_properties props = {
 		.type = BACKLIGHT_PLATFORM,
 		.brightness = 255,
 		/* HBM can go up to 1023, stay safe for now */
 		.max_brightness = 900,
 	};
 
 	ctx->base.backlight = devm_backlight_device_register(dev, dev_name(dev), dev,
-							     ctx->link,
+							     ctx,
 							     &sw43408_backlight_ops,
 							     &props);
 
 	if (IS_ERR(ctx->base.backlight))
 		return dev_err_probe(dev, PTR_ERR(ctx->base.backlight),
 				     "Failed to create backlight\n");
 
 	return 0;

-- 
2.55.0

