From: David Heidelberg <david@ixit.cz>
Date: Thu, 24 Sep 2026 16:01:35 +0200
Subject: [PATCH v2 07/11] drm/panel: s6e3ha8: Assert reset GPIO in
 unprepare
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-crosshatch-panel-v2-7-08d5c7bf72fc@ixit.cz>
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
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1147; i=david@ixit.cz;
 h=from:subject:message-id; bh=+wJwzxl6R6kFsAw/IP8INT9PZdDDVelgZpdEfbOYejM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtS09+kmOyC3qmmduvr07jHQ5sps+RXxREaQTh
 TqcBIdNFPOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarUtPQAKCRBgAj/E00kg
 ctzqD/4vq65LGGkUX0Ykq7LT8/pNIFwf2tY0PmuVkWhAPlyAfbx2oofy4IwyvvBH5Ch+45SiLuO
 ikgycsyvBwM7P+tF+JfpoUuzTpJ+AaSGxtqQ5okGW9t8DQWQlpuuwl300jKBMO8sH2FfO8UaSbK
 fyTF8sWh5u7M1nXo88TTOR9gGPpeBzTUNDI2eEKPqk09mpAojj34+WjNehvImSYDNRUrRDlkrNq
 twr4EIv3nEkcJleLAC1wHiGbR/rwvm6bb2EZLRNr6i7jLc7qtORBEaK+KgGYtH/vgTyydDEJztR
 DsvtdiLLIGsDbV3IoAWTZS6BP6zT5ToDE1+zokt1X2DzCRonY3sQxJ3F2zs48dOOIA40MOlHeOg
 bDgFXyONE0vMZ9qwgq9DKM9/pJHViDl3cSgzKIRPNMT9Lh3bzFOTTKJ1H3QNjU65Tsl1ADZFHSA
 LisOhkepB+s93s1jj4pPlgG+mk3wJQJgOpq9QGBc+RweW5rbIBPN+njmi0jg9nq8WGcac9KYuJh
 FOt8rSn1XXoXg41NCC3k7bONDN9ovLnk40AFqoisqOODZVLL0RP6n2VH1lYU9F8kN/UXqQF3AVM
 1G9vCw/I9HVCI+2n/H6O70PwBqb7J+u/yoakVJFCBavZAYiBvO9of/JPF/0IAGSxdrW70yhPekR
 X7aSXeaY2/j4ieg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For correct shutdown, the reset should be asserted.

Assisted-by: LLM
Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c b/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
index 99290913de69a..2591b8c1a7753 100644
--- a/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
+++ b/drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c
@@ -58,16 +58,17 @@ static int s6e3ha8_get_modes(struct drm_panel *panel,
 
 	return drm_connector_helper_get_modes_fixed(connector, priv->desc->mode);
 }
 
 static int s6e3ha8_unprepare(struct drm_panel *panel)
 {
 	struct s6e3ha8 *priv = to_s6e3ha8(panel);
 
+	gpiod_set_value_cansleep(priv->reset_gpio, 1);
 	return regulator_bulk_disable(priv->desc->num_supplies, priv->supplies);
 }
 
 static void s6e3ha8_amb577px01_wqhd_reset(struct s6e3ha8 *priv)
 {
 	gpiod_set_value_cansleep(priv->reset_gpio, 0);
 	usleep_range(5000, 6000);
 	gpiod_set_value_cansleep(priv->reset_gpio, 1);

-- 
2.55.0

