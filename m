From: David Heidelberg <david@ixit.cz>
Date: Sun, 20 Sep 2026 13:05:46 +0200
Subject: [PATCH 03/11] drm/panel: s6e3ha8: Really assert reset on the
 failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260920-crosshatch-panel-v1-3-de6e9512da96@ixit.cz>
References: <20260920-crosshatch-panel-v1-0-de6e9512da96@ixit.cz>
In-Reply-To: <20260920-crosshatch-panel-v1-0-de6e9512da96@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1389; i=david@ixit.cz;
 h=from:subject:message-id; bh=OzfdLbaebYlg4g6M/9ljeqwCz3P5UUikOpZwTfDJ7s0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqr74IiMaZ7eLSG3j8Ye4MMpjqsDY0WqPVVnciA
 RGMdGMkZo+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaq++CAAKCRBgAj/E00kg
 cn7QEACQA+ybHIvQR/Yu+E2AKsYzq8P5HZlmFlqdHwKT5AQioEW6jFpABsWBJ/uxVNOv32VGwSu
 ncr6ADDQsHfHJOBaipFhVHKDeDlFyG2iprIGXmhQiZOvd3FL3jfQTY0XbypWxJO3SdKc//0YI9g
 CzHkSK4boes7UYqZL0p428PuMd7Hd9hm+i9QfzVv9OlhIsvb4ZV/IE0S8jMenZZ8xNwcE14acKl
 QyA/ubpfJ8hRnKI+qdes+EPwSgpXI8WvBeeDNtjegucNlKDiG1PzlAwI5WAFOAiLjK2sMfE5aRp
 9GP8WOxyMfT0+V2PCXPOgX7N5LvafeiIFuEahMxuG1awrYE5wYnUVrVh+VvmSWt+LAHcn8F8lMR
 +dq7DuJDS4OONC0qlCe4gmAcabPcqxqkF04IuxMy7YMfA15FKI/CRWtDy7G6qCtnZ+svkE+rYNe
 oGJs8iMLYJlTKByD195Xu4/ISCLOoHJZSdxoFI91dtfLtyfGY+YUDkk9ezxrUQFrPShs+AXDbV4
 mPy2T9YP36Co5Owsgr5BB+s+9MQgg3TZSBnR+Wpbai8mS5yNSg1XbkxFzkKp+yJwoQNFgXNUeGh
 vSnHYxPOAhJM+cy5d0CM2KzbrlQQO+orvcl2Ga9ou0B1PRq5c6NJmVziKJeej4pA+1sxOeZW6RC
 HK6oY9OVFo7//vw==
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

