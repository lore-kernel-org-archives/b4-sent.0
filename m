From: David Heidelberg <david@ixit.cz>
Date: Tue, 05 May 2026 15:53:43 +0200
Subject: [PATCH v2 4/4] drm/panel: Enable GPIOLIB for panels which uses
 functions from it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260505-panel-clean-up-kconfig-dep-v2-4-9cc31d6e6919@ixit.cz>
References: <20260505-panel-clean-up-kconfig-dep-v2-0-9cc31d6e6919@ixit.cz>
In-Reply-To: <20260505-panel-clean-up-kconfig-dep-v2-0-9cc31d6e6919@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4731; i=david@ixit.cz;
 h=from:subject:message-id; bh=Uigl/kqj5rg3YP60cQ5j5/+HMEkyA3xJf42f3JZNrHs=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp+fZlyaQuvXQbusf8IyJixRXPJ5fbXXpDrMbnm
 WEEjb+CGWCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCafn2ZQAKCRBgAj/E00kg
 cg/GD/wNeiS8CeFlaYhKFdyQxx/iJc3ykfSdMPBmUFrLrVM4jypAnoNV0dtC40xSrXzd1HRhUPD
 NNGfYdimvm9gk0rMucf/arx9Tv+3w7GzDbXCfoYT07puf/4uk0WOWVoC5NUf3gCYo8slZb1UPT7
 jp8xZj5bXLpDXiYB/RAAftOKcpulqH33lxpqfuLCH2IquMNwyq6UilgzFwN/7AhGVnLhZC0cWcx
 6IEcT4W6wNWtoan4wOCPHIgN8i/6VtXI4hbHMtqpw0jV6KZ7rLwh6kmWC7Fz+SxN+wfkCDswd52
 5jrZjbbaHw+j9V2HSfbSapkR806O1No+6xQTfcYLtJr/A5dPs6Q9ahNinmGyauZ6gt6HkHtFOMw
 Z7xImDSpB7McVvifuS2iBibvsKUdwVKH4N++8NjLnto2YRlbUa7MVUP/t4+aPZDXPPUyc9A4duo
 8D4pr3ZCwc716WDlqTqAvzTrfeW7frfmxgzDGlDoOloteY+s49URNft2qoWdO9vLLjLlwOOAEr4
 i3wEw6E6EiFEi7aM3RTk4K7Zmai3701dgbCWhOMSKkRD8q/f1Se1NqemzFAb7IVOW3Dnx5WqVKO
 7vSakmikq7pRGQz8vh42qo7i4HhI6G6lx4YI1KQBbiZBhm+X8YbH6pQNVcen1c7R6QOEn7TdRvu
 0iJD7VMlBegkrfg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These panels used on sdm845 devices are using GPIOLIB functions,
ensure it's enabled.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/Kconfig | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/panel/Kconfig b/drivers/gpu/drm/panel/Kconfig
index 9360297ee99e5..268b45d4b82f5 100644
--- a/drivers/gpu/drm/panel/Kconfig
+++ b/drivers/gpu/drm/panel/Kconfig
@@ -102,16 +102,17 @@ config DRM_PANEL_BOE_TV101WUM_LL2
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	help
 	  Say Y here if you want to support for BOE TV101WUM-LL2
 	  WUXGA PANEL DSI Video Mode panel
 
 config DRM_PANEL_EBBG_FT8719
 	tristate "EBBG FT8719 panel driver"
+	depends on GPIOLIB
 	depends on OF
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	help
 	  Say Y here if you want to enable support for the EBBG FT8719
 	  video mode panel. Mainly found on Xiaomi Poco F1 mobile phone.
 	  The panel has a resolution of 1080x2246. It provides a MIPI DSI
 	  interface to the host.
@@ -339,17 +340,18 @@ config DRM_PANEL_JADARD_JD9365DA_H3
 	depends on BACKLIGHT_CLASS_DEVICE
 	help
 	  Say Y here if you want to enable support for Jadard JD9365DA-H3
 	  WXGA MIPI DSI panel. The panel support TFT dot matrix LCD with
 	  800RGBx1280 dots at maximum.
 
 config DRM_PANEL_JDI_LPM102A188A
 	tristate "JDI LPM102A188A DSI panel"
-	depends on OF && GPIOLIB
+	depends on GPIOLIB
+	depends on OF
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	help
 	  Say Y here if you want to enable support for JDI LPM102A188A DSI
 	  command mode panel as found in Google Pixel C devices.
 	  The panel has a 2560×1800 resolution. It provides a MIPI DSI interface
 	  to the host.
 
@@ -454,16 +456,17 @@ config DRM_PANEL_LG_LG4573
 	depends on OF && SPI
 	select VIDEOMODE_HELPERS
 	help
 	  Say Y here if you want to enable support for LG4573 RGB panel.
 	  To compile this driver as a module, choose M here.
 
 config DRM_PANEL_LG_SW43408
 	tristate "LG SW43408 panel"
+	depends on GPIOLIB
 	depends on OF
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	select DRM_DISPLAY_DSC_HELPER
 	select DRM_DISPLAY_HELPER
 	help
 	  Say Y here if you want to enable support for LG sw43408 panel.
 	  The panel has a 1080x2160@60Hz resolution and uses 24 bit RGB per
@@ -579,26 +582,28 @@ config DRM_PANEL_NOVATEK_NT36523
 	depends on BACKLIGHT_CLASS_DEVICE
 	help
 	  Say Y here if you want to enable support for the panels built
 	  around the Novatek NT36523 display controller, such as some
 	  Boe panels used in Xiaomi Mi Pad 5 and 5 Pro tablets.
 
 config DRM_PANEL_NOVATEK_NT36672A
 	tristate "Novatek NT36672A DSI panel"
+	depends on GPIOLIB
 	depends on OF
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	help
 	  Say Y here if you want to enable support for the panels built
 	  around the Novatek NT36672A display controller, such as some
 	  Tianma panels used in a few Xiaomi Poco F1 mobile phones.
 
 config DRM_PANEL_NOVATEK_NT36672E
 	tristate "Novatek NT36672E DSI panel"
+	depends on GPIOLIB
 	depends on OF
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	help
 	  Say Y here if you want to enable support for Novatek NT36672E DSI Video Mode
 	  LCD panel module. The panel has a resolution of 1080x2408 and uses 24 bit
 	  RGB per pixel.
 
@@ -726,17 +731,18 @@ config DRM_PANEL_RAYDIUM_RM692E5
 	select DRM_DISPLAY_DSC_HELPER
 	select DRM_DISPLAY_HELPER
 	help
 	  Say Y here if you want to enable support for Raydium RM692E5-based
 	  display panels, such as the one found in the Fairphone 5 smartphone.
 
 config DRM_PANEL_RAYDIUM_RM69380
 	tristate "Raydium RM69380-based DSI panel"
-	depends on OF && GPIOLIB
+	depends on GPIOLIB
+	depends on OF
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	help
 	  Say Y here if you want to enable support for Raydium RM69380-based
 	  display panels.
 
 	  This panel controller can be found in the Lenovo Xiaoxin Pad Pro 2021
 	  in combination with an EDO OLED panel.
@@ -1251,16 +1257,17 @@ config DRM_PANEL_VISIONOX_R66451
 	select DRM_DISPLAY_DSC_HELPER
 	select DRM_DISPLAY_HELPER
 	help
 	  Say Y here if you want to enable support for Visionox
 	  R66451 1080x2340 AMOLED DSI panel.
 
 config DRM_PANEL_VISIONOX_RM69299
 	tristate "Visionox RM69299"
+	depends on GPIOLIB
 	depends on OF
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	help
 	  Say Y here if you want to enable support for Visionox
 	  RM69299  DSI Video Mode panel.
 
 config DRM_PANEL_VISIONOX_RM692E5

-- 
2.53.0

