From: David Heidelberg <david@ixit.cz>
Date: Wed, 22 Apr 2026 11:48:38 +0200
Subject: [PATCH RESEND 4/4] drm/panel: Enable GPIOLIB for panels which uses
 functions from it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-panel-clean-up-kconfig-dep-v1-4-d825e9ffe911@ixit.cz>
References: <20260422-panel-clean-up-kconfig-dep-v1-0-d825e9ffe911@ixit.cz>
In-Reply-To: <20260422-panel-clean-up-kconfig-dep-v1-0-d825e9ffe911@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3466; i=david@ixit.cz;
 h=from:subject:message-id; bh=ZBiRe+gQ0qF5gTizCozkxDh2BdDwt4NwCy4NcwkIA/Y=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp6Jl4kCY/HgJI146RXhILETPAjE/tuZPSMXgms
 ECWjlvmXBCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaeiZeAAKCRBgAj/E00kg
 cpZwD/9vZ9FucYKgFYXr3tHHRj8yMP/0ETa0QOo7hASX8YXgej+JZ3N4UId5QbXPCN5OLceCYcr
 VqgKEtobr+IxcM6ylugM2DGgmODrx/rIBgBiSGWr5SO7UsSeZuBFUvQorv7bHPVqN5Umtp6kTEH
 CChaxNd2J5E/H+tntOwhx6/ujnUPPoI1GUgOZyWXuPr2VS5+/xInliCQMmW71e0e72tJphclkQc
 QrOsdes9sVs9N0/pGp5VF/0Fexe3dpMX4PUim18treuc+NXPy4FzsEfNRdr8LJJl84XpT6xJ3Ea
 by+iuMu2tq4MzSHfSfnNtZ37akBouhC6IXqbqiEYC/JnSKbX71ZLfsWe3dGIN4X7Hgt297D90t9
 9Mh6l7l4EWsEcgK9oy5CXxQZ71ElO5sPiwD2VdL1nX06t9DB489HowVWW9BKQ9J0pKDaLvE5Nzw
 pYJNC1KtB1wo0YwHEAmYfbNLP/1sId6MksL/Ewbrf9YHyAtK2p0nGguP4JXXZs+qH6wuk6cva1P
 pi72s4ciJyc2ZZQibC4jP6H9cwlZ+dhK7vwEw21uJYnf5SdRivXrYt/PAr2Tn/EGAm89srG+RIY
 1HnazOJvAIkL+NY2D85TKLC0mWSTIioa5KRXKGcj09gycqeMrkPTfRcbOTgCMWg04kt+DRivUZW
 aSDByIPcFYz/hIA==
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
@@ -102,17 +102,17 @@ config DRM_PANEL_BOE_TV101WUM_LL2
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	help
 	  Say Y here if you want to support for BOE TV101WUM-LL2
 	  WUXGA PANEL DSI Video Mode panel
 
 config DRM_PANEL_EBBG_FT8719
 	tristate "EBBG FT8719 panel driver"
-	depends on OF
+	depends on OF && GPIOLIB
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	help
 	  Say Y here if you want to enable support for the EBBG FT8719
 	  video mode panel. Mainly found on Xiaomi Poco F1 mobile phone.
 	  The panel has a resolution of 1080x2246. It provides a MIPI DSI
 	  interface to the host.
 
@@ -427,17 +427,17 @@ config DRM_PANEL_LG_LG4573
 	depends on OF && SPI
 	select VIDEOMODE_HELPERS
 	help
 	  Say Y here if you want to enable support for LG4573 RGB panel.
 	  To compile this driver as a module, choose M here.
 
 config DRM_PANEL_LG_SW43408
 	tristate "LG SW43408 panel"
-	depends on OF
+	depends on OF && GPIOLIB
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	select DRM_DISPLAY_DSC_HELPER
 	select DRM_DISPLAY_HELPER
 	help
 	  Say Y here if you want to enable support for LG sw43408 panel.
 	  The panel has a 1080x2160@60Hz resolution and uses 24 bit RGB per
 	  pixel. It provides a MIPI DSI interface to the host and has a
@@ -531,27 +531,27 @@ config DRM_PANEL_NOVATEK_NT36523
 	depends on BACKLIGHT_CLASS_DEVICE
 	help
 	  Say Y here if you want to enable support for the panels built
 	  around the Novatek NT36523 display controller, such as some
 	  Boe panels used in Xiaomi Mi Pad 5 and 5 Pro tablets.
 
 config DRM_PANEL_NOVATEK_NT36672A
 	tristate "Novatek NT36672A DSI panel"
-	depends on OF
+	depends on OF && GPIOLIB
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	help
 	  Say Y here if you want to enable support for the panels built
 	  around the Novatek NT36672A display controller, such as some
 	  Tianma panels used in a few Xiaomi Poco F1 mobile phones.
 
 config DRM_PANEL_NOVATEK_NT36672E
 	tristate "Novatek NT36672E DSI panel"
-	depends on OF
+	depends on OF && GPIOLIB
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	help
 	  Say Y here if you want to enable support for Novatek NT36672E DSI Video Mode
 	  LCD panel module. The panel has a resolution of 1080x2408 and uses 24 bit
 	  RGB per pixel.
 
 config DRM_PANEL_NOVATEK_NT37801
@@ -1177,17 +1177,17 @@ config DRM_PANEL_VISIONOX_R66451
 	select DRM_DISPLAY_DSC_HELPER
 	select DRM_DISPLAY_HELPER
 	help
 	  Say Y here if you want to enable support for Visionox
 	  R66451 1080x2340 AMOLED DSI panel.
 
 config DRM_PANEL_VISIONOX_RM69299
 	tristate "Visionox RM69299"
-	depends on OF
+	depends on OF && GPIOLIB
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	help
 	  Say Y here if you want to enable support for Visionox
 	  RM69299  DSI Video Mode panel.
 
 config DRM_PANEL_VISIONOX_RM692E5
 	tristate "Visionox RM692E5"

-- 
2.53.0

