From: David Heidelberg <david@ixit.cz>
Date: Tue, 04 Nov 2025 23:16:11 +0100
Subject: [PATCH 03/12] drm/panel: sofef00: Clean up panel description after
 s6e3fc2x01 removal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251104-sofef00-rebuild-v1-3-dfcfa17eb176@ixit.cz>
References: <20251104-sofef00-rebuild-v1-0-dfcfa17eb176@ixit.cz>
In-Reply-To: <20251104-sofef00-rebuild-v1-0-dfcfa17eb176@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jessica.zhang@oss.qualcomm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2398; i=david@ixit.cz;
 h=from:subject:message-id; bh=Tdo9B853+u45bPiZrtcM4vLFZtgNYIKOGwI7Qd8WyHo=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpCnss6m/xMnOrr9iT10hP1+vEnzI5f4krDVh6A
 4nEMofrszKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaQp7LAAKCRBgAj/E00kg
 cotfEACo8El5qi+C7R3YMofHslfSXPvSnfEJKGp73NLxFMXTr8cqx6L0hg2fNabEXu/fP7DjKnn
 tI8+WWlcGnpIg0jZh4twKuuzc7JtRzLrj+mv3rBE1OBacjpFBmInLHvWl11Oc+OAc+YCF1/y6y3
 tTF9b8KaZS4HDr8s+U8+E2apACCxDd591/5ujFPiI8u/7g5y/25G93OlvHzb97tHc54TeJsX8mw
 mJLhpu2fYeBVk2d/JkyuU/TwXKVtPXFZo1K9swIA22MrS+jAmttCpSOIM/Fu1Ic9jizL94xPVMW
 ia55xNbZrv+TT41rSRBEmmPRsqfTv7UA6qjt2yH/gKAhaZTemJ65xQD/EmSrkSnn0qP281Cjwgj
 0OgI2FcjHhwCubNa+5QSAvlAYlUUVdYRkgd1Nr1E4ljrh8P0AFuke/EXJdpAItynqzU9eZF2vGp
 PrqC0t7YuW23B96mkEF5dIzNufcw20untev+OrVZm0mxgGN5liSbka1JJxgXuwKZd6+n9sgfbGn
 yJg3bnSP+hircJcF7KBkQ/3lvaj211+AF/Cvh+ZC6aLQRLfNcwQBboC45auLfqESFqXLlHqm2H+
 X7jocDWJZ9SoZRxYDejcKS5kgb4B2h8JiXgUSLR5u5lAMQWv4I3zHRhjXkAXbaOuOXdA3KZKWaD
 S8d8IAaVgfYV3Pw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove leftover from s6e3fc2x01 support drop and clarify supported panel.

The Samsung SOFEF00 DDIC is used in multiple phones, so describe it
properly and generalize.

Fixes: e1eb7293ab41 ("drm/panel: samsung-sofef00: Drop s6e3fc2x01 support")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/Kconfig                 | 7 ++++---
 drivers/gpu/drm/panel/panel-samsung-sofef00.c | 4 ++--
 2 files changed, 6 insertions(+), 5 deletions(-)

diff --git a/drivers/gpu/drm/panel/Kconfig b/drivers/gpu/drm/panel/Kconfig
index 407c5f6a268b2..3442b1be6424c 100644
--- a/drivers/gpu/drm/panel/Kconfig
+++ b/drivers/gpu/drm/panel/Kconfig
@@ -868,16 +868,17 @@ config DRM_PANEL_SAMSUNG_S6E8AA5X01_AMS561RA01
 	  DSI protocol with 4 lanes.
 
 config DRM_PANEL_SAMSUNG_SOFEF00
-	tristate "Samsung sofef00/s6e3fc2x01 OnePlus 6/6T DSI cmd mode panels"
+	tristate "Samsung SOFEF00 DSI panel controller"
 	depends on OF
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	select VIDEOMODE_HELPERS
 	help
 	  Say Y or M here if you want to enable support for the Samsung AMOLED
-	  command mode panels found in the OnePlus 6/6T smartphones.
+	  panel SOFEF00 DDIC and connected panel.
+	  Currently supported panels:
 
-	  The panels are 2280x1080@60Hz and 2340x1080@60Hz respectively
+	    Samsung AMS628NW01 (found in OnePlus 6, 1080x2280@60Hz)
 
 config DRM_PANEL_SEIKO_43WVF1G
 	tristate "Seiko 43WVF1G panel"
diff --git a/drivers/gpu/drm/panel/panel-samsung-sofef00.c b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
index 064258217d50a..c88574ea66e1c 100644
--- a/drivers/gpu/drm/panel/panel-samsung-sofef00.c
+++ b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
@@ -252,7 +252,7 @@ static struct mipi_dsi_driver sofef00_panel_driver = {
 	.probe = sofef00_panel_probe,
 	.remove = sofef00_panel_remove,
 	.driver = {
-		.name = "panel-oneplus6",
+		.name = "panel-samsung-sofef00",
 		.of_match_table = sofef00_panel_of_match,
 	},
 };
@@ -260,5 +260,5 @@ static struct mipi_dsi_driver sofef00_panel_driver = {
 module_mipi_dsi_driver(sofef00_panel_driver);
 
 MODULE_AUTHOR("Casey Connolly <casey.connolly@linaro.org>");
-MODULE_DESCRIPTION("DRM driver for Samsung AMOLED DSI panels found in OnePlus 6/6T phones");
+MODULE_DESCRIPTION("DRM driver for Samsung SOFEF00 DDIC");
 MODULE_LICENSE("GPL v2");

-- 
2.51.0

