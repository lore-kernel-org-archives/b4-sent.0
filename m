From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Nov 2025 15:21:35 +0100
Subject: [PATCH v3 10/12] drm/panel: sofef00: Simplify get_modes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-sofef00-rebuild-v3-10-6cd55471e84e@ixit.cz>
References: <20251119-sofef00-rebuild-v3-0-6cd55471e84e@ixit.cz>
In-Reply-To: <20251119-sofef00-rebuild-v3-0-6cd55471e84e@ixit.cz>
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
 Casey Connolly <casey.connolly@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1958; i=david@ixit.cz;
 h=from:subject:message-id; bh=t7Ham4KLGv7LXKlYHbza6Ihf3qcaU4uzq3IWHkZmI8s=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpHdJytotmCbEIhNbMBr/c4FHlWH9+HbBvj1Q/A
 t3ypVKh/RWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaR3ScgAKCRBgAj/E00kg
 ck4YD/9sd/ZVgWPo/UW05hluFXuojHouqw0eWVPDrW4KTdGswP273ZwMrd71jKdx7DBczSfVs4U
 T+6Gp/2wCCrSefms0774lAEWdSyEtf+akci2vPIahew5JUygOl4cMwLN5n8iuORArZXzxLTZLiU
 O6fD4vl5Ac84Vcdb/ieDUXGrsAtjmlQGMw1BJXAexK88/+20hhJYMOh6aMzb7MIqWgDSfFhw5nf
 0kug5QYgVfbfrAVBTcQqjYO/0D+M6X6xLVRqbV4+E4yK83jWmnkcEMyKhcT0NOwboNgNLkgFPu9
 Lkob/pyTAxMwzvI5E2ZwfDqP8Sd/nJyfDp0U21N1XJ3hfa/if6+ArNRGfSG1boUQmXzmN3Yl82Q
 l3qIgRG0Otogy+29y4PLYPhfUhls7NlCC6jrRRRHkgx1MJArx0WJFYdJJwVmIDHmkOsasl8Jg5R
 uv5XmAH82jNFiafxaU3dStm8EnG+UfyMaX8o5wC0lmqwty+1FA9hABCU5DbIivXB/aDgX01RIRA
 uzvXXh5aq8qSmItEAIZB58Ett+YGG4dGkzbyF0jMvAL402Wlc6yi01xeJ/9outhimgugHOrmQpy
 kxPP0kKTVh+iapqHqDrtbrzOT1GGVHrvl1hES+lPO2cQGfr2dkPqI1aese2eyr/rYWhN9QMLfuI
 P7qCVKKjlcjHKsw==
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
index c2cb85997e4f3..0e857abda5964 100644
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

