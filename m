From: David Heidelberg <david@ixit.cz>
Date: Tue, 05 May 2026 15:53:40 +0200
Subject: [PATCH v2 1/4] drm/panel: Clean up SOFEF00 config dependencies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260505-panel-clean-up-kconfig-dep-v2-1-9cc31d6e6919@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1680; i=david@ixit.cz;
 h=from:subject:message-id; bh=TVGOFZIIfQs7jOp2zryQfUMRnfUQK6EtJZ6mq42pgvA=;
 b=kA0DAAgBYAI/xNNJIHIByyZiAGn59mWg904dRVwsSoZ2pmLahuq2VvOjkEQLPq3qQyTcohEUl
 YkCMwQAAQgAHRYhBNd6Cc/u3Cu9U6cEdGACP8TTSSByBQJp+fZlAAoJEGACP8TTSSByAncP/R6y
 rXp3lXzYCRzCEjocs7PTfuDH6KuHywwvH0C34lPGnnlGMmk4Mr4BjQTP1r2DDre/fp/l4bhcebD
 ET4dCz2PlhvU3bvQfBtktPykIfBtcxbCM4x4xSD1uiteT//9uSWgccD5i3kr8WYh2hdSYf5nlFF
 IIHxkBqUSDrzai9PrCkhrJZjViZoU13Z1XSwDnK+3dAce/pM8DM112e3j0VSo2Bb9sSihs8PBGd
 8kvEn1JjT0WNA42JFqw61Uc26SMzAjMcykkdyyJzw0A2ukmRy5bpsdY41DT4OrW8DwdbiPKiOSL
 t0C6FKJFxM0o8sN+n4UAhk0T4UlAOmH+wHUqCpEwDRrLfedwCzwdsR9E2Vk/TdAqz5Rm3Kpjr/7
 /jG6BM/J8MoCMpI2mjKk0dv58AUrci/ww8s6UuWCf2v4/c3xAWtv5xnoAklsyW2o58RYfGWiCIO
 dCyU2uAdkYwIvDjQfsJ6nRGWJyVGltwfUwx+nG7AOf6cMR/X6g+8YVuz2fFy4SK+o+8RIbRNClN
 M6YYu9p2hqadIuVG9ZSQbu3J9FdXo+eiVHL1y4R7wiUfzfXa1jq49bYiTcX7bNgtFxlmilSJR+g
 K8vPSQNPRN9W2h+WoN/1WjCWhdGu51EDCaCUX5gMvtKVVi25Flzp2poSQquBCKoPciCoLPcLvBE
 Ykvzl
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
index d6863b28ddc55..627b839ac9edb 100644
--- a/drivers/gpu/drm/panel/Kconfig
+++ b/drivers/gpu/drm/panel/Kconfig
@@ -976,20 +976,20 @@ config DRM_PANEL_SAMSUNG_S6E8FC0
 	  S6E8FC0 DSI controller and connected panel.
 	  Currently supported panels:
 
 	    M1906F9 (M1906F9SH or M1906F9SI), 6.09 inch 720x1560, found
 	    in the Xiaomi Mi A3 smartphone (xiaomi-laurel).
 
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
 	  Currently supported panels:
 
 	    Samsung AMS628NW01 (found in OnePlus 6, 1080x2280@60Hz)
 
 config DRM_PANEL_SEIKO_43WVF1G

-- 
2.53.0

