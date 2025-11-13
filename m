From: David Heidelberg <david@ixit.cz>
Date: Thu, 13 Nov 2025 18:57:44 +0100
Subject: [PATCH v2 10/12] drm/panel: sofef00: Simplify get_modes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251113-sofef00-rebuild-v2-10-e175053061ec@ixit.cz>
References: <20251113-sofef00-rebuild-v2-0-e175053061ec@ixit.cz>
In-Reply-To: <20251113-sofef00-rebuild-v2-0-e175053061ec@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1958; i=david@ixit.cz;
 h=from:subject:message-id; bh=8diXpj4flXvL6PBJCymDKTVmS7jlHjaf2gFdGCxh2WA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpFhwVKIRpFqk9VNuj0DzQ/MME2NFt0dVorHkqM
 TzTQ+QjZL2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRYcFQAKCRBgAj/E00kg
 ckEDD/9lSX6mTKnL3nHiq4n7s39OdBTvTG0m5j7WJtVgpLXBL1TCRnBNvI1WVbHKleLmB45A2JR
 FeefsU/bfld7LSTz6+QzApBnegBsLiWFPh3LA5RqSWBXsXoaVgBnox89xEiVGE8oOd+I++acFfb
 APTTKlCVARJJ5pfLAKPiA/wNtD1W+ogE+MYbQ+JascO/fcPvagjlRZRzfN61eZWyOL0He5d9A4J
 nL4B0nuGfhGUXutQGwkm4mWS4Ke9vyF2j0kE2ibtKGhWQbrwKzKieBCXvASM9Q1FAPNVFvGgxJO
 RlEaGWo/KgSZBQv4HQkGfAgm0sK7jZ2Z4cRpX/AzAbX7xeMqNnos5PSPwiRSubMQkw6wbOfckq6
 3PfEEHVqx/PyAbUA8fNrcVVwbaKE1mIxRqGjRWVGhB0C7Hb63HR5kK9gFdKfDXsfhNeWX8GRHAP
 t3Nb0zPYxrLa5kFoidvShTVBPUV7m+Eele6MigA6RweflH8+LteT+WYpu7UQ9sFU7j+CUY+hV7e
 Qk8g+RTBRdF6IzJPedvHoRU+KspCLQ4f7e1cC72l774vqd1DEz6M4ynw2nv0xHI4CUHZJ0pPV2y
 7OGoHPvoQjJOE+7ED5dct9tU0qoga6PREhYchDoN5ttHJLiy4Jb3LAObtdjxotxd1Jta0okE0Bt
 UfyfgIp7bCu+fXw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Levearage drm_connector_helper_get_modes_fixed helper function.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-sofef00.c | 21 +++++++--------------
 1 file changed, 7 insertions(+), 14 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-samsung-sofef00.c b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
index 7947adf908772..e69a28628b656 100644
--- a/drivers/gpu/drm/panel/panel-samsung-sofef00.c
+++ b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
@@ -16,6 +16,7 @@
 #include <drm/drm_mipi_dsi.h>
 #include <drm/drm_modes.h>
 #include <drm/drm_panel.h>
+#include <drm/drm_probe_helper.h>
 
 struct sofef00_panel {
 	struct drm_panel panel;
@@ -143,34 +144,26 @@ static int sofef00_panel_unprepare(struct drm_panel *panel)
 
 static const struct drm_display_mode ams628nw01_panel_mode = {
 	.clock = (1080 + 112 + 16 + 36) * (2280 + 36 + 8 + 12) * 60 / 1000,
+
 	.hdisplay = 1080,
 	.hsync_start = 1080 + 112,
 	.hsync_end = 1080 + 112 + 16,
 	.htotal = 1080 + 112 + 16 + 36,
+
 	.vdisplay = 2280,
 	.vsync_start = 2280 + 36,
 	.vsync_end = 2280 + 36 + 8,
 	.vtotal = 2280 + 36 + 8 + 12,
+
 	.width_mm = 68,
 	.height_mm = 145,
+
+	.type = DRM_MODE_TYPE_DRIVER | DRM_MODE_TYPE_PREFERRED,
 };
 
 static int sofef00_panel_get_modes(struct drm_panel *panel, struct drm_connector *connector)
 {
-	struct drm_display_mode *mode;
-
-	mode = drm_mode_duplicate(connector->dev, &ams628nw01_panel_mode);
-	if (!mode)
-		return -ENOMEM;
-
-	drm_mode_set_name(mode);
-
-	mode->type = DRM_MODE_TYPE_DRIVER | DRM_MODE_TYPE_PREFERRED;
-	connector->display_info.width_mm = mode->width_mm;
-	connector->display_info.height_mm = mode->height_mm;
-	drm_mode_probed_add(connector, mode);
-
-	return 1;
+	return drm_connector_helper_get_modes_fixed(connector, &ams628nw01_panel_mode);
 }
 
 static const struct drm_panel_funcs sofef00_panel_panel_funcs = {

-- 
2.51.0

