From: David Heidelberg <david@ixit.cz>
Date: Thu, 13 Nov 2025 18:57:38 +0100
Subject: [PATCH v2 04/12] drm/panel: sofef00: Handle all regulators
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251113-sofef00-rebuild-v2-4-e175053061ec@ixit.cz>
References: <20251113-sofef00-rebuild-v2-0-e175053061ec@ixit.cz>
In-Reply-To: <20251113-sofef00-rebuild-v2-0-e175053061ec@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jessica.zhang@oss.qualcomm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2667; i=david@ixit.cz;
 h=from:subject:message-id; bh=mwo54CYnw7MO3Xycn85wubPyOShFMxI9iCM2JhaFHcY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpFhwU/i5TRLIYYU3ANHTvpFIdyLpFU8Xx19TIX
 nVDhA2jWqaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRYcFAAKCRBgAj/E00kg
 cgZ0D/0V1/PLjvSKzMRgKLRV28Ya1Uxmo4zbM/mZVaw6WJmrRpAZECmRyDaiYatgkWlGZW0IkOq
 kNAnvUHcHzNoAK7qyWfscQMIdNl3Ki+VEIWattnMQ9tuzqWPWMgggLGJ+VsYX8GOh0uF0nP9p7e
 LqSGxVXC/JdcpUZdZpttF0dsoaK9A8uQbrhCi9bcr8KDjAY9jcsvvghLjo6wRn5I/oz1RlDLMJM
 eZDNVBiJkSA0C/dqnLtrthEwGHsEvbiZSVeUgX4h3vC48R2fVFAQeOf2Tyq1EwntVTqnWIoNDLk
 CqdEOq7ciSRBO/1WMUnOZUsaJlWjhJ5dzdyknTrY9Rc7jJ2DoWbdxxZubPlD1oaS/Mremq01R4x
 DyOSa+RdzgpuFCglItzlK1wY/Qz22rjsuCJT9D+/cJ23bIUCftY/8tBHx/uqXXDWmhBW8f5niJk
 PFPSnPQP1xWbnuQOLo3bK9ERpiOQKlfZC79enX9RYfUsPpEPR84OzQ458DaZibHcVL0gQX3nxdU
 v1p8P0AwheScKgjU/sn66m7lnzCV3dYXIBizLKl0/HvcqQN7/aNZzA82dszU5focAIl6EiUHCnK
 MZQ7NRtk4yON+W0lyABx6Ncfv4B97tkBqutdBUaF60WHs1t7g5LmkYyqhMSeOYFXsU5/eghBDN/
 Uo5ZUxRTHcX3y/Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Recently we documented, there is more than vddio regulator, adapt the
driver to work with VCI and POC regulator.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-sofef00.c | 28 ++++++++++++++++-----------
 1 file changed, 17 insertions(+), 11 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-samsung-sofef00.c b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
index c88574ea66e1c..3097040e6bfa0 100644
--- a/drivers/gpu/drm/panel/panel-samsung-sofef00.c
+++ b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
@@ -20,10 +20,16 @@
 struct sofef00_panel {
 	struct drm_panel panel;
 	struct mipi_dsi_device *dsi;
-	struct regulator *supply;
+	struct regulator_bulk_data *supplies;
 	struct gpio_desc *reset_gpio;
 };
 
+static const struct regulator_bulk_data sofef00_supplies[] = {
+	{ .supply = "vddio" },
+	{ .supply = "vci" },
+	{ .supply = "poc" },
+};
+
 static inline
 struct sofef00_panel *to_sofef00_panel(struct drm_panel *panel)
 {
@@ -86,20 +92,18 @@ static int sofef00_panel_off(struct sofef00_panel *ctx)
 static int sofef00_panel_prepare(struct drm_panel *panel)
 {
 	struct sofef00_panel *ctx = to_sofef00_panel(panel);
-	struct device *dev = &ctx->dsi->dev;
 	int ret;
 
-	ret = regulator_enable(ctx->supply);
-	if (ret < 0) {
-		dev_err(dev, "Failed to enable regulator: %d\n", ret);
+	ret = regulator_bulk_enable(ARRAY_SIZE(sofef00_supplies), ctx->supplies);
+	if (ret < 0)
 		return ret;
-	}
 
 	sofef00_panel_reset(ctx);
 
 	ret = sofef00_panel_on(ctx);
 	if (ret < 0) {
 		gpiod_set_value_cansleep(ctx->reset_gpio, 1);
+		regulator_bulk_disable(ARRAY_SIZE(sofef00_supplies), ctx->supplies);
 		return ret;
 	}
 
@@ -111,7 +115,7 @@ static int sofef00_panel_unprepare(struct drm_panel *panel)
 	struct sofef00_panel *ctx = to_sofef00_panel(panel);
 
 	sofef00_panel_off(ctx);
-	regulator_disable(ctx->supply);
+	regulator_bulk_disable(ARRAY_SIZE(sofef00_supplies), ctx->supplies);
 
 	return 0;
 }
@@ -197,10 +201,12 @@ static int sofef00_panel_probe(struct mipi_dsi_device *dsi)
 	if (IS_ERR(ctx))
 		return PTR_ERR(ctx);
 
-	ctx->supply = devm_regulator_get(dev, "vddio");
-	if (IS_ERR(ctx->supply))
-		return dev_err_probe(dev, PTR_ERR(ctx->supply),
-				     "Failed to get vddio regulator\n");
+	ret = devm_regulator_bulk_get_const(dev,
+					    ARRAY_SIZE(sofef00_supplies),
+					    sofef00_supplies,
+					    &ctx->supplies);
+	if (ret)
+		return dev_err_probe(dev, ret, "Failed to get regulators\n");
 
 	ctx->reset_gpio = devm_gpiod_get(dev, "reset", GPIOD_OUT_HIGH);
 	if (IS_ERR(ctx->reset_gpio))

-- 
2.51.0

