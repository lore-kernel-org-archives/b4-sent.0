From: David Heidelberg <david@ixit.cz>
Date: Tue, 18 Nov 2025 12:30:41 +0100
Subject: [PATCH v3 6/8] drm/panel: sw43408: Switch to
 devm_regulator_bulk_get_const
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251118-pixel-3-v3-6-317a2b400d8a@ixit.cz>
References: <20251118-pixel-3-v3-0-317a2b400d8a@ixit.cz>
In-Reply-To: <20251118-pixel-3-v3-0-317a2b400d8a@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sumit Semwal <sumit.semwal@linaro.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: phodina@protonmail.com, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2649; i=david@ixit.cz;
 h=from:subject:message-id; bh=RmiIuFd1oStd80sm8454mAMk0dIbubgWeKUm8l8QqhA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpHFjgrqhBwSznXUBgsLBDos7WSQjI6FB+X4BNp
 TiiJ21SYSGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRxY4AAKCRBgAj/E00kg
 ckPgEAC4QvJiHi82H9WX98rZgG3EZKf3hzr1ZM29Lc46woQVC/9o0HyGndPjx28x1d1EHHmHClG
 cpYscBUuWrJWWpCfiICfBD1woiKANzcLB9E1MAO5krNqaelISEpoGB0VVBZFRH7cDviZ+eRhNLy
 AdDl03TtFP69P7/AZpJm0t+fAxbzOrsvTD5BakKp/P76zuAHQHYBIRCu0qceaos81S7yT8a45/L
 5UfOaV1egHoGEoE5S89JvgZnYMNXYZdrLdhdRIfANgozBwFubRmXDxo65kUnwqRJ3ULXKExuvld
 zjCJt+MlozJ3gSz7LfkKQ6tIokQxEEUXRyJ0/ufFq1YWJ6MMmXltLUfhTIThlEHCjB9EcnJUbFi
 WKg/EtOLq4xDSZCwqiCtb/kQMV0D+uBXQ3aFGUIN0e7m9ym149J9yjiPTk0TdadVgrG8GpbsXKx
 2/rcglNeM46QFdPhzbwduH5UYPluwA/HscJ8sHv0uFomaaXVIFS/6GrvFoe01W+Xm6lFu6Tj6Rm
 b+0ZzqPIkGMxMdoERmxBwL9mwDQGYwdJruNhSx0aCb+sT37ZqvbvqjUgIQJLZUVaxBflatCJCpn
 ZRTFElrnwgutwc8S90QHD2I+/16kARvOXbDt7bajPbRfV16J2Q8g36JL/hY0D4M7GTzMfGXaIcu
 DFhwydPNAJ9zXFw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Switch to devm_regulator_bulk_get_const() to stop setting the supplies
list in probe(), and move the regulator_bulk_data struct in static const.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-lg-sw43408.c | 26 ++++++++++++++------------
 1 file changed, 14 insertions(+), 12 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-lg-sw43408.c b/drivers/gpu/drm/panel/panel-lg-sw43408.c
index d8481bdafd6dd..0a902470e03fa 100644
--- a/drivers/gpu/drm/panel/panel-lg-sw43408.c
+++ b/drivers/gpu/drm/panel/panel-lg-sw43408.c
@@ -20,13 +20,18 @@
 #include <drm/display/drm_dsc.h>
 #include <drm/display/drm_dsc_helper.h>
 
-#define NUM_SUPPLIES 2
+static const struct regulator_bulk_data sw43408_supplies[] = {
+	{ .supply = "vddi", /* 1.88V */
+	  .init_load_uA = 62000 },
+	{ .supply = "vpnl", /* 3.0 V */
+	  .init_load_uA = 857000 },
+};
 
 struct sw43408_panel {
 	struct drm_panel base;
 	struct mipi_dsi_device *link;
 
-	struct regulator_bulk_data supplies[NUM_SUPPLIES];
+	struct regulator_bulk_data *supplies;
 
 	struct gpio_desc *reset_gpio;
 
@@ -59,7 +64,7 @@ static int sw43408_unprepare(struct drm_panel *panel)
 
 	gpiod_set_value(sw43408->reset_gpio, 1);
 
-	ret = regulator_bulk_disable(ARRAY_SIZE(sw43408->supplies), sw43408->supplies);
+	ret = regulator_bulk_disable(ARRAY_SIZE(sw43408_supplies), sw43408->supplies);
 
 	return ret;
 }
@@ -152,7 +157,7 @@ static int sw43408_prepare(struct drm_panel *panel)
 	struct sw43408_panel *ctx = to_panel_info(panel);
 	int ret;
 
-	ret = regulator_bulk_enable(ARRAY_SIZE(ctx->supplies), ctx->supplies);
+	ret = regulator_bulk_enable(ARRAY_SIZE(sw43408_supplies), ctx->supplies);
 	if (ret < 0)
 		return ret;
 
@@ -166,7 +171,7 @@ static int sw43408_prepare(struct drm_panel *panel)
 
 poweroff:
 	gpiod_set_value(ctx->reset_gpio, 1);
-	regulator_bulk_disable(ARRAY_SIZE(ctx->supplies), ctx->supplies);
+	regulator_bulk_disable(ARRAY_SIZE(sw43408_supplies), ctx->supplies);
 	return ret;
 }
 
@@ -249,13 +254,10 @@ static int sw43408_add(struct sw43408_panel *ctx)
 	struct device *dev = &ctx->link->dev;
 	int ret;
 
-	ctx->supplies[0].supply = "vddi"; /* 1.88 V */
-	ctx->supplies[0].init_load_uA = 62000;
-	ctx->supplies[1].supply = "vpnl"; /* 3.0 V */
-	ctx->supplies[1].init_load_uA = 857000;
-
-	ret = devm_regulator_bulk_get(dev, ARRAY_SIZE(ctx->supplies),
-				      ctx->supplies);
+	ret = devm_regulator_bulk_get_const(dev,
+					    ARRAY_SIZE(sw43408_supplies),
+					    sw43408_supplies,
+					    &ctx->supplies);
 	if (ret < 0)
 		return ret;
 

-- 
2.51.0

