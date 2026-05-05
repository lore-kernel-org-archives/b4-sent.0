From: David Heidelberg <david@ixit.cz>
Date: Tue, 05 May 2026 15:53:42 +0200
Subject: [PATCH v2 3/4] drm/panel: Clean up S6E3HA2 config dependencies and
 fill help text
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260505-panel-clean-up-kconfig-dep-v2-3-9cc31d6e6919@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1657; i=david@ixit.cz;
 h=from:subject:message-id; bh=kaTc3CFnkJzzXMWx8bermuEVEdbEt+t1LKTOg/OEgqQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp+fZlZuFsQpcrrhCiCZQPl5lR5ffQgn5kiiG4L
 Tn5g0ph4uuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCafn2ZQAKCRBgAj/E00kg
 ckxyD/42mOAxQtMxFcc5olDd9cUMwA+teThsvrzosP6epTv4ngLYB+bfUvq2A+mQAarpIBFxxxA
 DIdRnq+9OeIVBUk5VCRIwwMU2I6g03/6tu8nun6wEYEb87ikLJD0k5OQAYU7woQl8Zq6y2COP//
 2Gxe+Ve8lYF5zB5NBL7+YnzA1O12Ap2N7FzS30w27N0lrewLAITgGRpzxmWgtP2jp5RsDZ+gQSX
 NDr5hXsPFQ4oM5i0Hy4TEOnaX4jradVJ6FDbJv3h/Z1CBsavbVj3XFxtIQB02/aVjq0wKHnUb6U
 X2mgsORWfOqbfbTn3acFNVS+ikF/A56O3HPltpBibI0r/9tBiv2NzqfECjlQCQ9Qh/eiDlgrsBq
 TWfidQ3cWmH2ZlwcbXpO1mAR/1dkPMo3WkvUS6sujca5HOHJlQj9ELP9DbfrKHbHTCyw3wHCy7+
 OC5iTXPS6pWk/ck+6qVEfCvlukKeDDLC4xjRaez7qZA0+OZgvyPrySH1vR0xIo+9g939ddRXsmA
 QgqQ0q/L8c7qG4S7Q/ldRynGbM87ChyiuDFn2FspuIv6KJ0KZ/5nalANOFTci1cSnLAevdzjc65
 3WO9lKwItZTHBkuU75MXiHEnswELuEffJ9RqLbGEMDxAygYyv97Z0xJ04fPWG7+O3zHbuBHcMcK
 3Caugx9mvZ/bqsg==
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
 drivers/gpu/drm/panel/Kconfig | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panel/Kconfig b/drivers/gpu/drm/panel/Kconfig
index 813380ca76117..9360297ee99e5 100644
--- a/drivers/gpu/drm/panel/Kconfig
+++ b/drivers/gpu/drm/panel/Kconfig
@@ -904,21 +904,28 @@ config DRM_PANEL_SAMSUNG_S6E3HA2
 	tristate "Samsung S6E3HA2 DSI video mode panel"
 	depends on OF
 	depends on DRM_MIPI_DSI
 	depends on BACKLIGHT_CLASS_DEVICE
 	select VIDEOMODE_HELPERS
 
 config DRM_PANEL_SAMSUNG_S6E3HA8
 	tristate "Samsung S6E3HA8 DSI video mode panel"
+	depends on GPIOLIB
 	depends on OF
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

