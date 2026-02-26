From: David Heidelberg <david@ixit.cz>
Date: Thu, 26 Feb 2026 12:57:37 +0100
Subject: [PATCH 2/4] drm/panel: Clean up S6E3FC2X01 config dependencies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260226-panel-clean-up-kconfig-dep-v1-2-bb28a2355b4c@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1170; i=david@ixit.cz;
 h=from:subject:message-id; bh=1E7aVpRA10O6F1jEpxvHIj22BqTrWHJFHanlhtXUI1g=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpoDUwrjHompueBqEMEG/sPuQckQy/doRmtGAiM
 41Q6oUHSEWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaaA1MAAKCRBgAj/E00kg
 coXXD/9c6tXLegZ5OTv375490elWzhRTjE0pplWcDDbaQgRxZVMvThHWQ8PEdK4Rje1OrCu8Yqw
 iZtf9lqajpg9ZOnqyslWLHMdQvyycbZVZJbkuV4dmg9M61csS3zvxzsSJKWPRtLdU/uctArl+VS
 +9viiYAYcjQPIKOVmMKJIr0K7LPHBdh/WxzPYpmbKxu9Ikzid4vUvVP4XE50GKWlQq+kHuvDgoQ
 OQFSdvDT9nUgc0/b2geRpHxeowDdG5sVV9EK/lahBumcVb/U+59W4Z8WsQooUgR34Q/6/2bED4n
 xONrDYoRPDpUAX1qWX141HnY1Rwtr2EsglFLDT14rXJRA9fKYd1iBimRiq4lVAJoxuK0g4PNr2u
 HCVv06mf8ivmbErJB8JnmWQIsYezZpiqUr/FgE8OBt9SVPBdf3f9MQkITYiATK6ofbPDHapShTo
 V42hIHKt3MMRSvhlK4prqVeeO6xasfjBRqPLJzy0cjz73awv+EAhYagcPr450xlNFvyfpl139Rf
 zzhNVwb1MQDxlpi0ebDy+e7EgOtO9/qTogcCN5Jzouszhx8b5+qvNiXGt+7L60BQFMO7oI+Ww2r
 xXoN7TOS90MlkCfqIObn5MzMwXpvVhy/D4ZPRViCUikgbnkioEglzJCFcs7pw8hw0lcdKabxQ7r
 HG0HJwtzPAcdyPg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As per the config name this Display IC features a DSI command-mode
interface (or the command to switch to video mode is not
known/documented) and does not use any of the video-mode helper
utilities, hence should not select VIDEOMODE_HELPERS.  In addition it
uses devm_gpiod_get() and related functions from GPIOLIB.

Fixes: 88148c30ef26 ("drm/panel: Add Samsung S6E3FC2X01 DDIC with AMS641RW panel")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/Kconfig | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/panel/Kconfig b/drivers/gpu/drm/panel/Kconfig
index 2fd3222ba2e3b..a81ea7755c03f 100644
--- a/drivers/gpu/drm/panel/Kconfig
+++ b/drivers/gpu/drm/panel/Kconfig
@@ -830,10 +830,9 @@ config DRM_PANEL_SAMSUNG_S6D7AA0
 
 config DRM_PANEL_SAMSUNG_S6E3FC2X01
 	tristate "Samsung S6E3FC2X01 DSI panel controller"
-	depends on OF
+	depends on OF && GPIOLIB
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
-	select VIDEOMODE_HELPERS
 	help
 	  Say Y or M here if you want to enable support for the
 	  Samsung S6E3FC2 DDIC and connected MIPI DSI panel.

-- 
2.51.0

