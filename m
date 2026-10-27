From: Alexandre Marquet <tb@a-marquet.fr>
Date: Tue, 27 Oct 2026 13:01:43 +0100
Subject: [PATCH 2/3] drm/exynos: exynos_dp: change poweron/off to encoder
 enable/disable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-drm-misc-next-manta-auxbus-v1-2-3a45c3cf531d@a-marquet.fr>
References: <20261027-drm-misc-next-manta-auxbus-v1-0-3a45c3cf531d@a-marquet.fr>
In-Reply-To: <20261027-drm-misc-next-manta-auxbus-v1-0-3a45c3cf531d@a-marquet.fr>
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Luca Ceresoli <luca.ceresoli@bootlin.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jingoo Han <jingoohan1@gmail.com>, Inki Dae <inki.dae@samsung.com>, 
 Seung-Woo Kim <sw0312.kim@samsung.com>, 
 Kyungmin Park <kyungmin.park@samsung.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, 
 Douglas Anderson <dianders@chromium.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 Lukas Timmermann <linux@timmermann.space>, 
 Henrik Grimler <henrik@grimler.se>, Hendrik Noack <hendrik-noack@gmx.de>, 
 Alexandre Marquet <tb@a-marquet.fr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793102508; l=3149;
 i=tb@a-marquet.fr; s=20261023; h=from:subject:message-id;
 bh=niciPhHYJMxmPiaLdY+j6FZWFXq5DN1CObPsB/9SrOs=;
 b=W3oDPujpfRAKf7/x7WSPSc9GAbQ8GiBn1glOfFzN8eiBh04Wrgc4gBWJ25Z4sRJbPyYzcbcvr
 oMRsCO0EwzkBu3vR4EGr7MhPT3QF/7aomVTJK+mslMOTFzRjBNM3q0a
X-Developer-Key: i=tb@a-marquet.fr; a=ed25519;
 pk=zVRSO6FDK46rqmeA2GuzAhM24eFlUq1QpmXi9/KCFyk=
X-Endpoint-Received: by B4 Relay for tb@a-marquet.fr/20261023 with auth_id=1334
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Current functions exynos_dp_poweron()/exynos_dp_poweroff(), that
supposedly powers on/off the device, actually only enable the encoder
clock. This cause issues where poweron() calls fail silently in
analogix_dp_probe(), leading in some cases to a state were the encoder
is never enabled but the rest of the driver assumes that it is.

Signed-off-by: Alexandre Marquet <tb@a-marquet.fr>
---
 drivers/gpu/drm/exynos/exynos_dp.c | 40 +++++++++++++-------------------------
 1 file changed, 13 insertions(+), 27 deletions(-)

diff --git a/drivers/gpu/drm/exynos/exynos_dp.c b/drivers/gpu/drm/exynos/exynos_dp.c
index 82c238829921..16b00aacd55b 100644
--- a/drivers/gpu/drm/exynos/exynos_dp.c
+++ b/drivers/gpu/drm/exynos/exynos_dp.c
@@ -43,39 +43,27 @@ struct exynos_dp_device {
 	struct analogix_dp_plat_data plat_data;
 };
 
-static int exynos_dp_crtc_clock_enable(struct analogix_dp_plat_data *plat_data,
-				bool enable)
-{
-	struct exynos_dp_device *dp = to_dp(plat_data);
-	struct drm_encoder *encoder = &dp->encoder;
-
-	if (!encoder->crtc)
-		return -EPERM;
-
-	exynos_drm_pipe_clk_enable(to_exynos_crtc(encoder->crtc), enable);
-
-	return 0;
-}
-
-static int exynos_dp_poweron(struct analogix_dp_plat_data *plat_data)
+static void exynos_dp_mode_set(struct drm_encoder *encoder,
+			       struct drm_display_mode *mode,
+			       struct drm_display_mode *adjusted_mode)
 {
-	return exynos_dp_crtc_clock_enable(plat_data, true);
 }
 
-static int exynos_dp_poweroff(struct analogix_dp_plat_data *plat_data)
+static void exynos_dp_crtc_clock_enable(struct drm_encoder *encoder,
+					bool enable)
 {
-	return exynos_dp_crtc_clock_enable(plat_data, false);
+	if (encoder->crtc)
+		exynos_drm_pipe_clk_enable(to_exynos_crtc(encoder->crtc), enable);
 }
 
-static void exynos_dp_mode_set(struct drm_encoder *encoder,
-			       struct drm_display_mode *mode,
-			       struct drm_display_mode *adjusted_mode)
+static void exynos_dp_enable(struct drm_encoder *encoder)
 {
+	exynos_dp_crtc_clock_enable(encoder, true);
 }
 
-static void exynos_dp_nop(struct drm_encoder *encoder)
+static void exynos_dp_disable(struct drm_encoder *encoder)
 {
-	/* do nothing */
+	exynos_dp_crtc_clock_enable(encoder, false);
 }
 
 static const struct drm_encoder_funcs exynos_dp_encoder_funcs = {
@@ -84,8 +72,8 @@ static const struct drm_encoder_funcs exynos_dp_encoder_funcs = {
 
 static const struct drm_encoder_helper_funcs exynos_dp_encoder_helper_funcs = {
 	.mode_set = exynos_dp_mode_set,
-	.enable = exynos_dp_nop,
-	.disable = exynos_dp_nop,
+	.enable = exynos_dp_enable,
+	.disable = exynos_dp_disable,
 };
 
 static int exynos_dp_bind(struct device *dev, struct device *master, void *data)
@@ -171,8 +159,6 @@ static int exynos_dp_probe(struct platform_device *pdev)
 
 	/* The remote port can be either a panel or a bridge */
 	dp->plat_data.dev_type = EXYNOS_DP;
-	dp->plat_data.power_on = exynos_dp_poweron;
-	dp->plat_data.power_off = exynos_dp_poweroff;
 	dp->plat_data.ops = &exynos_dp_ops;
 
 	dp->adp = analogix_dp_probe(dev, &dp->plat_data);

-- 
2.43.0

