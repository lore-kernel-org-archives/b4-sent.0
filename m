From: David Heidelberg <david@ixit.cz>
Date: Thu, 26 Feb 2026 12:57:36 +0100
Subject: [PATCH 1/4] drm/panel: Clean up SOFEF00 config dependencies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260226-panel-clean-up-kconfig-dep-v1-1-bb28a2355b4c@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1352; i=david@ixit.cz;
 h=from:subject:message-id; bh=S2VmpYOqwuL+0OJ8gYr+mbqdWnTXUGRv7C3ek1BRY3c=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpoDUwi1CjtxFs5Sj/rXK7pY5bi2RLpIoCFPyEq
 woAahnB0l6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaaA1MAAKCRBgAj/E00kg
 csbJEACtWhRwtEV68IEUPumQ+0W9UDjFpTKqA8vLw/EGhDWAix7givziihyRR1aHGeHf/dKVy3O
 9pBRNgts4TpFp+BWpTRDvsbrbyMbPN/6/S3Ov0hZngQ6YEFxUtoFfk/N2iveGvjm69OZnvm+2Ef
 JcK6Q3y0EhevQUzu8iIuX+KL1TNO7TCphyA/fx7ij1+NW+u5Eh04hGK1a85wrpfEiPDtcgqJoU+
 X9uEt5lxwmtKtB8tHvNEwGe9sFJpm9RQSGrAz165iQrFLkuISl6SwUBy6Vq9boP04jCsCR1KQ34
 nMZ9u7Dg9BJRLiNhN1A44OItCJxNMS+ub9ewBb4ByTSQWVwiZS5ACHL9FqK561saFj0FGqSyJAH
 e/eZg/WcKOsBqj7r9X+V6TfpPKZR40Dlp7zDscBGkKleTPsusuC5susIwQpVcXSosn9XvSSPLFq
 zv4uxSljWYPJ8ZsJdOj0jUucRydhC/YHX2uGaAqEw6OKDPeT0fh7xoQWgMUIK41nMyB3Yie2jhW
 sxxhnhq9JaURXRZif4pcIgxHk/eh3yI6tt+mVxE7+9s26varnrOg73ZusLYpcryditqWCJx8PFf
 ilSm7nGXfu/5zOlE7QutiTJIi2N/MFVr9OEX4gMfu61fiRhjFDg4qJb5PJS7/eTHaoOHVFuBNow
 US66dQ3OiFT+CyQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Marijn Suijten <marijn.suijten@somainline.org>

As per the config name this Display IC features a DSI command-mode
interface (or the command to switch to video mode is not
known/documented) and does not use any of the video-mode helper
utilities, hence should not select VIDEOMODE_HELPERS.  In addition it
uses devm_gpiod_get() and related functions from GPIOLIB.

Fixes: 5933baa36e26 ("drm/panel/samsung-sofef00: Add panel for OnePlus 6/T devices")
Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Reviewed-by: Casey Connolly <casey.connolly@linaro.org>
Reviewed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: Marijn Suijten <marijn.suijten@somainline.org>
---
 drivers/gpu/drm/panel/Kconfig | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panel/Kconfig b/drivers/gpu/drm/panel/Kconfig
index 79264f7bbd0e2..2fd3222ba2e3b 100644
--- a/drivers/gpu/drm/panel/Kconfig
+++ b/drivers/gpu/drm/panel/Kconfig
@@ -909,10 +909,10 @@ config DRM_PANEL_SAMSUNG_S6E8AA5X01_AMS561RA01
 
 config DRM_PANEL_SAMSUNG_SOFEF00
 	tristate "Samsung SOFEF00 DSI panel controller"
+	depends on GPIOLIB
 	depends on OF
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
-	select VIDEOMODE_HELPERS
 	help
 	  Say Y or M here if you want to enable support for the Samsung AMOLED
 	  panel SOFEF00 DDIC and connected panel.

-- 
2.51.0

