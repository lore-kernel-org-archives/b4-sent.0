From: David Heidelberg <david@ixit.cz>
Date: Thu, 24 Sep 2026 16:01:31 +0200
Subject: [PATCH v2 03/11] drm/panel: s6e3ha8: Really assert reset on the
 failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-crosshatch-panel-v2-3-08d5c7bf72fc@ixit.cz>
References: <20260924-crosshatch-panel-v2-0-08d5c7bf72fc@ixit.cz>
In-Reply-To: <20260924-crosshatch-panel-v2-0-08d5c7bf72fc@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Petr Vorel <petr.vorel@gmail.com>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1446; i=david@ixit.cz;
 h=from:subject:message-id; bh=sUy0BR5Bzr/Y22ddFb/f+LRIKy5v8DuL6NuaUod5V1U=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtS08wHR9zYSx/3A2hmDQ05c0FOMS965h5V6ML
 hEg8/cxi+CJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarUtPAAKCRBgAj/E00kg
 cq8JD/4wsfSqoqairaLYwA3fSUe7IyhRf9Us7/9/0O2w6U4oV58WwpwXYz1aF/oR2Ld+37tSCrp
 9f8AZsVIKqLL8ykHh45L9s6XcAFc1SoXhVes5WdbyQq+HweLzf0McOYZIG/sKup4nQJovUTuQft
 O2S4j5tQzrlA/rJr5TQmYYb4oCioOuahLb4Lzp0ezRsBBnXo17UieJnKvp6dZD5vSbq2ZnBpHG0
 v/AbASTfUczXTkMMQzZL4N+62ZdpLd4BZ396DWNNHQs2AayCWC4lt3ZWHOYtHS+ZqtuMR37KUVl
 kPRZmdcyK5wrZny7vW3aqgBcUo4dHDdlLKQaQM6Bp0UiITCP1nc9mREDTt4zjNFpXZ3ECVcQXCe
 Xrb0YH7Jx8liPGpFyU1J0zJTiWUBTpg3f0QH+kN5WIxKTcvM8TBEkFF/SeoS5NldFDntmA3i/l2
 8OInuoHyvsuIGht01GzUACKMnXs/YBwcCZqhHimQE6w8GOg4OD9w3fV546/yEaexNDHAXSUYgfj
 zYaX8qVMhz+Gh/YGxF4rgo5ndFrNPYZq7WL6VkJvFlXznIpJaO/Mu9+35hYxkOKcubVrXqWldo8
 nTwVqvux6WJjac/UKMLn30L4acxcxHNArJVUibYYTMSmG+2kUUadYdullZU3DooMhnOXDwIHbSj
 OTZavnrCWCIaX4Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Due to incorrect implementation 0 == asserted, thus when driver fails it
needs to assert reset.

Minimal fix for stable; the polarity convention is corrected properly
later in this series.

Fixes: 779679d3c1640 ("drm/panel: Add support for S6E3HA8 panel driver")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c b/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
index 078523df48860..835121b322f4a 100644
--- a/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
+++ b/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
@@ -179,17 +179,17 @@ static int s6e3ha8_amb577px01_wqhd_prepare(struct drm_panel *panel)
 	ret = regulator_bulk_enable(ARRAY_SIZE(s6e3ha8_supplies), priv->supplies);
 	if (ret < 0)
 		return ret;
 	mipi_dsi_msleep(&ctx, 120);
 	s6e3ha8_amb577px01_wqhd_reset(priv);
 
 	ret = s6e3ha8_amb577px01_wqhd_on(priv);
 	if (ret < 0) {
-		gpiod_set_value_cansleep(priv->reset_gpio, 1);
+		gpiod_set_value_cansleep(priv->reset_gpio, 0);
 		goto err;
 	}
 
 	drm_dsc_pps_payload_pack(&pps, &priv->dsc);
 
 	samsung_dsi_test_key_on_lvl1(&ctx);
 	mipi_dsi_picture_parameter_set_multi(&ctx, &pps);
 	samsung_dsi_test_key_off_lvl1(&ctx);

-- 
2.55.0

