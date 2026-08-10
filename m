From: David Heidelberg <david@ixit.cz>
Date: Mon, 10 Aug 2026 11:55:38 +0200
Subject: [PATCH v2 2/2] drm/panel: lg-sw43408: use the full DCS brightness
 range
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-fix-blueline-panel-v2-2-9344dfdbc3f9@ixit.cz>
References: <20260810-fix-blueline-panel-v2-0-9344dfdbc3f9@ixit.cz>
In-Reply-To: <20260810-fix-blueline-panel-v2-0-9344dfdbc3f9@ixit.cz>
To: Sumit Semwal <sumit.semwal@linaro.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Vinod Koul <vkoul@kernel.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1395; i=david@ixit.cz;
 h=from:subject:message-id; bh=scglJ6aSldaji48JvrBM5A5u97auNkDSvGSlJqKRe5k=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqeaAc3VgRZEOaTM54OKlXYIzYbhoEhA65NKcDg
 1Hc3lGC9UaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCanmgHAAKCRBgAj/E00kg
 cg7OD/40s8ISIFOnNA0G1UHYJYr6xaE0We5PGFZzosOsifznr43Ec3S+ss3FAnXBQ69OX8RTwVs
 kJb+U1thvNoo9EDrtBgyvaBZrGGSYyjxo9VmtLgytOxVi482WD3RG4LuZkgaWu81GUDwZ9zYSVy
 NO4/xXC3HARtYloGwunPGDZHOhOiz3iC+qScKC6ccLtUKa3jApxVtzMspF4rrIQQxJ2d+e6NNGV
 gokA/gVp71z/tNSNCv1vftLCqn/nji/w/Iq7iJEi+7QdMhQyMdN94H9Jz5/Pf7gdl07F/tz8GCz
 MJdsjurpIJbesWJhUNuy7nhnjGQw3g7YSOsHSrFPwuJSRSfzh4EIVzy9G168FdLV6WVuChMhLx5
 bp0kQHbgrafoO1jtErlieC6lncLujZQt4MqORy2SD346WkN0cgWiFMREJPGBoBWcPgJxBjEXKaa
 mVTlnbJJThZ6SM81TKPVBjwouCw6auCzBwKpFmGr3do+kg7a+AICrGrcbKijzQTi2XYC58kVkV8
 gK5XqCPRd5Cf8XA2GCSk4eZvVzomoul2uVz0F+ReyHpOdZelZI84QLXtHMS9yOOe6OhIsTKn4PF
 cXaXsNGbwJVrGhDCEBHxjx87SEKxH2BIGrrFgHM5QHH7A86C2Bokwea9FARk28AgNI2q9NF/T4/
 ilWGZFgvrZMA/7Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The vendor firmware panel configuration (XBL DisplayDxe panel XML)
declares DCSMaxBrightness 0x332 with a two-byte brightness command,
and the driver already sends two bytes via
mipi_dsi_dcs_set_display_brightness_large().

Capping max_brightness at 255 therefore limits the panel to ~31% of
its real brightness range. Use the firmware maximum.

Fixes: 069a6c0e94f9 ("drm: panel: Add LG sw43408 panel driver")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-lg-sw43408.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panel/panel-lg-sw43408.c b/drivers/gpu/drm/panel/panel-lg-sw43408.c
index 0bf8e08f10b9c..be132b65b0c13 100644
--- a/drivers/gpu/drm/panel/panel-lg-sw43408.c
+++ b/drivers/gpu/drm/panel/panel-lg-sw43408.c
@@ -203,17 +203,17 @@ static const struct backlight_ops sw43408_backlight_ops = {
 };
 
 static int sw43408_backlight_init(struct sw43408_panel *ctx)
 {
 	struct device *dev = &ctx->link->dev;
 	const struct backlight_properties props = {
 		.type = BACKLIGHT_PLATFORM,
 		.brightness = 255,
-		.max_brightness = 255,
+		.max_brightness = 818,
 	};
 
 	ctx->base.backlight = devm_backlight_device_register(dev, dev_name(dev), dev,
 							     ctx->link,
 							     &sw43408_backlight_ops,
 							     &props);
 
 	if (IS_ERR(ctx->base.backlight))

-- 
2.55.0

