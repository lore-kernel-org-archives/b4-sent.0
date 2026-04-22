From: David Heidelberg <david@ixit.cz>
Date: Wed, 22 Apr 2026 11:48:37 +0200
Subject: [PATCH RESEND 3/4] drm/panel: Clean up S6E3HA2 config dependencies
 and fill help text
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-panel-clean-up-kconfig-dep-v1-3-d825e9ffe911@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1666; i=david@ixit.cz;
 h=from:subject:message-id; bh=6btRlHpzFWcpsPVnKzj/ASpL7mxJeb/wvSMA84mBejw=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp6Jl4Yj7VBbvMjvojVvl+CxxCBLgHAW9g3nU3Z
 ElNpVGBBXeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaeiZeAAKCRBgAj/E00kg
 cs/VEACSzK8B/mOtJAB8GVBdcF4dDL1JH8JUOVbrc4eQbDruTr9/S8+n4IOTVA1Vdu+pjStQm84
 /7Gjh/bOZjf3/VdmhMZn/0AnBvwViXU1WbrwWN19UySL31Ahfw9MoYFact0jRn/M0NwJqYuwUpc
 ehrWi8pXTc8cIkEQI+v/KvGihbaD1F11asRvPg8Ga8QwNqAjeOb+WcBoqffmUv01DpDjhiiGAEe
 faUKFDLIRXsA1i9BYcCRY/D+/zsGFsLfSC2gcFS0/lv5Bvmv8Dq4p5Zv/lE2zxRtB5eniZf85nY
 gboqq2ifR7rZkKZ5V+3aZSwmgQKl5YM1Ux/PQH7vDAjTzXj++Jh9a879E/T8uPCpS95Vz8FJ1jC
 u6ylOCky7PSy0oZF9kzueYi9xmix3/5KjJrXpBisSUgifYFmPocPiNVxPbsDHq7PpjiiUzzEBlM
 fuPR0edzLtFv6u64A0+mRgcVLBswqyLQwgTueNB0kq2sj44FrUFrr2Jz1qX56dtNpK7HbYaxP7o
 MQNxAp9MI9kyKuo4URGfVGqnHaa91QPROsaZqHqjMuUV7sGSUfBJdcRxViJy1KxMBjQ56LVxW4p
 /vMRPTCeV2YQ1RU7d7sm5ftZL9mfHEjIRgxtAx+CgKTtV3VBmadXxl3mQ/fzeSWOECajKOG09nn
 V1mvxs83l+BYabQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As per the config name this Display IC features a DSI command-mode
interface (or the command to switch to video mode is not
known/documented) and does not use any of the video-mode helper
utilities, hence should not select VIDEOMODE_HELPERS. In addition it
uses devm_gpiod_get() and related functions from GPIOLIB.

Fixes: 779679d3c164 ("drm/panel: Add support for S6E3HA8 panel driver")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/Kconfig | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/panel/Kconfig b/drivers/gpu/drm/panel/Kconfig
index a81ea7755c03f..4e7b4808f6e7c 100644
--- a/drivers/gpu/drm/panel/Kconfig
+++ b/drivers/gpu/drm/panel/Kconfig
@@ -844,21 +844,27 @@ config DRM_PANEL_SAMSUNG_S6E3HA2
 	tristate "Samsung S6E3HA2 DSI video mode panel"
 	depends on OF
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	select VIDEOMODE_HELPERS
 
 config DRM_PANEL_SAMSUNG_S6E3HA8
 	tristate "Samsung S6E3HA8 DSI video mode panel"
-	depends on OF
+	depends on OF && GPIOLIB
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	select DRM_DISPLAY_DSC_HELPER
-	select VIDEOMODE_HELPERS
+	help
+	  Say Y or M here if you want to enable support for the
+	  Samsung S6E3HA8 DDIC and connected MIPI DSI panel.
+	  Currently supported panels:
+
+	    Samsung AMB577PX01 (found in the Samsung S9 smartphone)
+
 
 config DRM_PANEL_SAMSUNG_S6E63J0X03
 	tristate "Samsung S6E63J0X03 DSI command mode panel"
 	depends on OF
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	select VIDEOMODE_HELPERS
 

-- 
2.53.0

