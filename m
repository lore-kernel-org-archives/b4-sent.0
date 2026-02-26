From: David Heidelberg <david@ixit.cz>
Date: Thu, 26 Feb 2026 12:57:39 +0100
Subject: [PATCH 4/4] drm/panel: Enable GPIOLIB for panels which uses
 functions from it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260226-panel-clean-up-kconfig-dep-v1-4-bb28a2355b4c@ixit.cz>
References: <20260226-panel-clean-up-kconfig-dep-v1-0-bb28a2355b4c@ixit.cz>
In-Reply-To: <20260226-panel-clean-up-kconfig-dep-v1-0-bb28a2355b4c@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Dzmitry Sankouski <dsankouski@gmail.com>, Sam Ravnborg <sam@ravnborg.org>
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 marijn.suijten@somainline.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1697; i=david@ixit.cz;
 h=from:subject:message-id; bh=kZqVQhCz8mO/Ob0x0kf6kkJ6bC/I+HuiI6tMN2lM1HQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpoDUxIb1oNiM1pQcZ1IRqumsJw/dWkq/+JQ72L
 yYs7x/cI8OJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaaA1MQAKCRBgAj/E00kg
 cgk0D/9bMlMKwYH2QWAlbPPeFxQyphU8IEwQperjlEj13B5GyXRUVAF5IT13WBCltEfkzK1fNK1
 ots0iZrioqvhVXQJ4y1cowvEscmdFo/lGCPpoG6Zy7tO8ylbY//PzKvWC1A3vV+kkfQA5JatwpE
 KDBozz6jSEuQkRfqg4GmvLJ0qZC8JP/j7u/OB6OXseY1eB6nqDQln/H49CobFFuIJtlEW2Q08Ky
 M3iDbelVcMffLySyDOum9RrQXflc7VAUV+jOBZdwTCZkql2H+07iXNtQdzrYEDQKck7pH4JjIgT
 dlDXjev/3FuOGOCmHMR8FQiXauN+Cm4sdhsgJrO3q0EKb8TxBXt/X+LCQ/RAinjARKC7g4KfhuK
 +srBpQSt+w6RCIyXTG/X7BHkwX4+N5f8/z/ysTTkM+Lw0eI3MErK/61BEF1A8tbxzClN+o1jsS6
 pXKSTL1GGidr1Gui6quQ7D7HeUaY52incKuuczwRh//J4luWrPyEuIM2kSIqFN/lYQnVbTuyln4
 mR5qquUglVQPPViiC/f3wuL0d/7H1dHxhyPSVRnkfxnitoZbNyego7zW4gHs3TsQ5/Nti2ywa6D
 Lj1XkJyWj5l6vS7/zXNEtFpNeujObWu04wBxABirImfsADFrZhX9exvdyedCUxYkXp8/fwvYRp3
 v02FFURHEOZPYjw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These panels used on sdm845 devices are using GPIOLIB functions,
ensure it's enabled.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/Kconfig | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/drivers/gpu/drm/panel/Kconfig b/drivers/gpu/drm/panel/Kconfig
index 4e7b4808f6e7c..3e819b4b23962 100644
--- a/drivers/gpu/drm/panel/Kconfig
+++ b/drivers/gpu/drm/panel/Kconfig
@@ -107,7 +107,7 @@ config DRM_PANEL_BOE_TV101WUM_LL2
 
 config DRM_PANEL_EBBG_FT8719
 	tristate "EBBG FT8719 panel driver"
-	depends on OF
+	depends on OF && GPIOLIB
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	help
@@ -432,7 +432,7 @@ config DRM_PANEL_LG_LG4573
 
 config DRM_PANEL_LG_SW43408
 	tristate "LG SW43408 panel"
-	depends on OF
+	depends on OF && GPIOLIB
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	select DRM_DISPLAY_DSC_HELPER
@@ -536,7 +536,7 @@ config DRM_PANEL_NOVATEK_NT36523
 
 config DRM_PANEL_NOVATEK_NT36672A
 	tristate "Novatek NT36672A DSI panel"
-	depends on OF
+	depends on OF && GPIOLIB
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	help
@@ -546,7 +546,7 @@ config DRM_PANEL_NOVATEK_NT36672A
 
 config DRM_PANEL_NOVATEK_NT36672E
 	tristate "Novatek NT36672E DSI panel"
-	depends on OF
+	depends on OF && GPIOLIB
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	help
@@ -1182,7 +1182,7 @@ config DRM_PANEL_VISIONOX_R66451
 
 config DRM_PANEL_VISIONOX_RM69299
 	tristate "Visionox RM69299"
-	depends on OF
+	depends on OF && GPIOLIB
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	help

-- 
2.51.0

