From: David Heidelberg <david@ixit.cz>
Date: Fri, 17 Apr 2026 08:55:42 +0200
Subject: [PATCH v2] drm/panel: visionox-rm69299: Make use of
 prepare_prev_first
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260417-axolotl-display-v2-1-8ce5341e46c2@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAG3Z4WkC/3WNwQ6DIBAFf8XsuTRCQU1P/Y/GA8K2bkLEACFaw
 7+Xeu9xJnnzDogYCCPcmwMCZorklwri0oCZ9fJGRrYyiFZ0reSK6c07nxyzFFend9ZzZVDyDpU
 ZoK7WgC/azuJzrDxTTD7s50HmP/u/lTnjrNfTJKyQw02pB22UruYDYynlCwCuFoOsAAAA
X-Change-ID: 20260415-axolotl-display-715ce416e5c8
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <quic_abhinavk@quicinc.com>, 
 Douglas Anderson <dianders@chromium.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, 
 =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1693; i=david@ixit.cz;
 h=from:subject:message-id; bh=9qaIOk2jaDgB2Cwe96XjpEy/bDYDz7aCW+7/jIamQeA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp4dlwDVNUHkEYKJ4EK7EcKFKl9f3Jw1BBY493q
 Y324AJTfe6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaeHZcAAKCRBgAj/E00kg
 cttsD/9m2anpA36jjz0zc5Pmrdj7RngeZZnHIPytR2ydyH1jeLbPHn2F3Ibnu+mYJPis3syIgUk
 KLSCVr7eT56sD8tETG37D/OvZfDqkCyG9fNoKC1m1+I9pw912f32cPe+GsC6mVIEcsOD+RTIAyD
 YDddEQRCYz8hTnlm+9pNpYU5iIYzRRurP12ItgvLGRTToPtJ8SOYudEiDnTsN4AO1iF0o6MUDhl
 ce70P+RizgTNbVt58vdBANuGmQ3NomKt/Al/UfTT/cSse836BevvVkmyXEfBHyU7lDzSA7MaZ3y
 DWX3iYRulpWJN+xY3iDujFthoZZj0W8z0W3Q8DtZWYguIKEH92785pu4TAtA3HHasKDFdc3Apih
 JyKhDwFhhQQCZ6LZUPG+BKTrH1a8wBDqE/F8RXW3+xN0Sp7yzXlXvdXTtrtXmO6iOGb2pIcOBhr
 0zomRSKVy7xoI0T5t8TAwpyvIEYpAaf23uioV+yXyPiH7+VMNTylg8Z7zU81mWOmgmgqgi9ldp4
 ehxKx7DtYVYHWReGTKS8zCkRxzBnxbcUkbEau2JLOhGjR4+smPCLAodZYHDYtbUBoji3xoiomMt
 2Yuiz1fmJuyDWbgAFI6AS3uLVjEdNBuR08wfr0ZvoFZ1XpM71s5jAkR2yZRFZA/GYrzMlduEqiT
 O16IDSInnSNhg1g==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Guido Günther <agx@sigxcpu.org>

The DSI link must be powered up to let panel driver to talk to the panel
during prepare() callback execution. Set the prepare_prev_first flag to
guarantee this.

Fixes: 9e15123eca79 ("drm/msm/dsi: Stop unconditionally powering up DSI hosts at modeset")
Signed-off-by: Guido Günther <agx@sigxcpu.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- Move the prepare_prev_first before drm_panel_add(). (Douglas)
- Link to v1: https://lore.kernel.org/r/20260415-axolotl-display-v1-1-7abb2d248355@ixit.cz
---
 drivers/gpu/drm/panel/panel-visionox-rm69299.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/gpu/drm/panel/panel-visionox-rm69299.c b/drivers/gpu/drm/panel/panel-visionox-rm69299.c
index e5e688cf98fdc..f1430370ff942 100644
--- a/drivers/gpu/drm/panel/panel-visionox-rm69299.c
+++ b/drivers/gpu/drm/panel/panel-visionox-rm69299.c
@@ -371,16 +371,18 @@ static int visionox_rm69299_probe(struct mipi_dsi_device *dsi)
 		return ret;
 
 	ctx->reset_gpio = devm_gpiod_get(dev, "reset", GPIOD_OUT_LOW);
 	if (IS_ERR(ctx->reset_gpio)) {
 		dev_err(dev, "cannot get reset gpio %ld\n", PTR_ERR(ctx->reset_gpio));
 		return PTR_ERR(ctx->reset_gpio);
 	}
 
+	ctx->panel.prepare_prev_first = true;
+
 	ctx->panel.backlight = visionox_rm69299_create_backlight(ctx);
 	if (IS_ERR(ctx->panel.backlight))
 		return dev_err_probe(dev, PTR_ERR(ctx->panel.backlight),
 				     "Failed to create backlight\n");
 
 	drm_panel_add(&ctx->panel);
 
 	dsi->lanes = 4;

---
base-commit: e6efabc0afca02efa263aba533f35d90117ab283
change-id: 20260415-axolotl-display-715ce416e5c8

Best regards,
-- 
David Heidelberg <david@ixit.cz>

