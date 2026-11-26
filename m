From: David Heidelberg <david@ixit.cz>
Date: Thu, 26 Nov 2026 20:57:07 +0100
Subject: [PATCH v2 2/2] drm/panel: visionox-rm69299: Move power_off() into
 unprepare()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261126-visionox-rm69299-enable-v2-2-d4aca6d50b05@ixit.cz>
References: <20261126-visionox-rm69299-enable-v2-0-d4aca6d50b05@ixit.cz>
In-Reply-To: <20261126-visionox-rm69299-enable-v2-0-d4aca6d50b05@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Douglas Anderson <dianders@chromium.org>
Cc: =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2137; i=david@ixit.cz;
 h=from:subject:message-id; bh=ZKlt2J9SJtaagBBmDdD9/bxAqIHPNUXlK1gRO/z3ohk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrCI8UvC0CJAMi5XXibNlumI2RiN5xcYwHe7Q8B
 hClARDVFZ+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawiPFAAKCRBgAj/E00kg
 ciPdD/46lqiyAIrbOjBbe1l36hKM1I6ZpUFn4Fivcoc2UuFfG1wcKM17gGr47FjumPZv0SvnzpA
 kh1iEAygfQZwdzq5tIbdOV4KqGnaWoIN8rkVuO/UUnMKpbhYhc5lK1gR7WcjhemWb0LWAMa27od
 CDsI9iHR4E3mx/YHKx1SKeUMG9NLMfdcuvkvojL6frhktXRIkcITR1D01wbRsKiBFVC5BHo80oJ
 arpaUVzBWnVSzRVP/+LHhhAx4MLXZtp0u/ZqH8jHTO3YvbGO9Vam+A0tZXmQUtERC5OGz05V92H
 oA8amxoGB7SELA11/TBvkKE1jRwrLJvKnNqFDOjitvF1PBpU31HjG5jb/EP/o0As7z98/IqUdaB
 9nRZIs/od24vL4EydmPN7k51HM5JvOeOIYXZjhj9qxJL07zNpRzaZz0bwvFhtgxpMHRuHo2p5pO
 t3u2T5YjcHUsDZeJsvOIQ8lNvNhrYbXmnAwc0WmBGu9Vi6O4mF5NhuRLYdt9mYbfZdfJVR7KBuF
 aWadmqsbiohHPJ5op71mIMjI8WolgpPdjg4x1gpWrpTwHCENt5Vqhpzj8bLvGZby5s3qJTWvScA
 JU/ioTyId7QW37eI6PhZqI44aFtJ9cuzx5wkJVPgyrrpeN6rKc7gYBClAMNtt2dnhh4sWKZQaCI
 hylf1iWxr6C4k3Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Guido Günther <agx@sigxcpu.org>

No need to have a separate visionox_rm69299_power_off() helper now that
visionox_rm69299_unprepare() only handles powering off the panel.

Signed-off-by: Guido Günther <agx@sigxcpu.org>
[David: only fold power_off() into unprepare(), keeping power_on() in prepare()]
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-visionox-rm69299.c | 13 ++++---------
 1 file changed, 4 insertions(+), 9 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-visionox-rm69299.c b/drivers/gpu/drm/panel/panel-visionox-rm69299.c
index bca1004656e45..54005d4660c33 100644
--- a/drivers/gpu/drm/panel/panel-visionox-rm69299.c
+++ b/drivers/gpu/drm/panel/panel-visionox-rm69299.c
@@ -176,24 +176,16 @@ static int visionox_rm69299_power_on(struct visionox_rm69299 *ctx)
 	gpiod_set_value(ctx->reset_gpio, 0);
 	usleep_range(10000, 20000);
 	gpiod_set_value(ctx->reset_gpio, 1);
 	usleep_range(10000, 20000);
 
 	return 0;
 }
 
-static int visionox_rm69299_power_off(struct visionox_rm69299 *ctx)
-{
-	gpiod_set_value(ctx->reset_gpio, 0);
-
-	return regulator_bulk_disable(ARRAY_SIZE(visionox_rm69299_supplies),
-				      ctx->supplies);
-}
-
 static int visionox_rm69299_disable(struct drm_panel *panel)
 {
 	struct visionox_rm69299 *ctx = panel_to_ctx(panel);
 	struct mipi_dsi_multi_context dsi_ctx = { .dsi = ctx->dsi };
 
 	ctx->dsi->mode_flags &= ~MIPI_DSI_MODE_LPM;
 
 	mipi_dsi_dcs_set_display_off_multi(&dsi_ctx);
@@ -205,17 +197,20 @@ static int visionox_rm69299_disable(struct drm_panel *panel)
 
 	return dsi_ctx.accum_err;
 }
 
 static int visionox_rm69299_unprepare(struct drm_panel *panel)
 {
 	struct visionox_rm69299 *ctx = panel_to_ctx(panel);
 
-	return visionox_rm69299_power_off(ctx);
+	gpiod_set_value(ctx->reset_gpio, 0);
+
+	return regulator_bulk_disable(ARRAY_SIZE(visionox_rm69299_supplies),
+				      ctx->supplies);
 }
 
 static int visionox_rm69299_prepare(struct drm_panel *panel)
 {
 	struct visionox_rm69299 *ctx = panel_to_ctx(panel);
 	struct mipi_dsi_multi_context dsi_ctx = { .dsi = ctx->dsi };
 	int ret, i;
 

-- 
2.55.0

