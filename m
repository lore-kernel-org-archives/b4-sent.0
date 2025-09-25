From: David Heidelberg <david@ixit.cz>
Date: Thu, 25 Sep 2025 11:12:53 +0200
Subject: [PATCH 7/8] drm/panel: samsung-sofef00: Invert reset gpio polarity
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250925-s6e3fc2x01-v1-7-9293016768f7@ixit.cz>
References: <20250925-s6e3fc2x01-v1-0-9293016768f7@ixit.cz>
In-Reply-To: <20250925-s6e3fc2x01-v1-0-9293016768f7@ixit.cz>
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
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1882; i=david@ixit.cz;
 h=from:subject:message-id; bh=ZfoMesL62ioUNjBQKPO8CHzPTpBtCCT4BPeRvoqMncU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo1QeR4cBqvSN+51Lv7PCudNw9nbZ0mitaGklLE
 SqMQmY4lKeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaNUHkQAKCRBgAj/E00kg
 csbbEACtZdtzis8MWoxBI3kf5nqgfdG96sQtuvLU4KxUApxNzaNgCdf0UQhSpBjzhhdSWLOUUHn
 flFARW4JcyvzKY61z2WuCYIgY7Po1i0uaYm4DL3rGFXqAhGkovvTeowzyMi6oq5kvzXnOwUuCFX
 k4K4NLhkD97UGx5ReC6RQAntQ9jUk1ecrSKYx4RHN7kKdp6UXw/IbE9VWK/I75cfVZtmoNG9LfP
 MLomOL5HJrjRH2XundWmzULOhDshRdJVGf3vlj3/TOdoZAy+KYCpepXLPUU4phX5U/TWHFIHL4g
 NeUvVndCheZfJfw8PXOuk6jRClH3wrfO8wGgXLhXjGUSTxFJq5tcujHGf4UIYTbQJ1ATuw+dm57
 QSIlX+nQmaZg7SIu+BLFAsZbDVNKTcZY7xn+UH3vf1Br5mBeSTOVApczvFhOk/RDT4jsu2J/LBl
 /5EdNXCawMbgh03KXtHrPBdtI6EmedgGOQ+Ra29J8Qb3gnSKWNjqSo4oZEdftlQE7gHQ1/hTZe0
 dDRIAKtJU3wk32aepsSDP/h0b7R5qm+QxPwqLenaJ7xTKx8eEuIwTA18eaq7SSb7HuOvMt55tOL
 SGVGHnZdPaFUT3aaPYte/xDP69n9XfHpgQXh1ivW6RAbdHhy7e4bd8oPld3pvscWk0VOXBTu8uK
 iXU+Zi0sne/KMng==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Follow the device-tree change for OnePlus 6/6T and invert the reset
polarity in the driver.

Fixes: 5933baa36e26 ("drm/panel/samsung-sofef00: Add panel for OnePlus 6/T devices")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-samsung-sofef00.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-samsung-sofef00.c b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
index 064258217d50ad6f02d27a97f8aff2e298260d4b..e29badbdb6b9ee0c63167d452d62ecb96e9caef8 100644
--- a/drivers/gpu/drm/panel/panel-samsung-sofef00.c
+++ b/drivers/gpu/drm/panel/panel-samsung-sofef00.c
@@ -32,11 +32,11 @@ struct sofef00_panel *to_sofef00_panel(struct drm_panel *panel)
 
 static void sofef00_panel_reset(struct sofef00_panel *ctx)
 {
-	gpiod_set_value_cansleep(ctx->reset_gpio, 0);
-	usleep_range(5000, 6000);
 	gpiod_set_value_cansleep(ctx->reset_gpio, 1);
-	usleep_range(2000, 3000);
+	usleep_range(5000, 6000);
 	gpiod_set_value_cansleep(ctx->reset_gpio, 0);
+	usleep_range(2000, 3000);
+	gpiod_set_value_cansleep(ctx->reset_gpio, 1);
 	usleep_range(12000, 13000);
 }
 
@@ -99,7 +99,7 @@ static int sofef00_panel_prepare(struct drm_panel *panel)
 
 	ret = sofef00_panel_on(ctx);
 	if (ret < 0) {
-		gpiod_set_value_cansleep(ctx->reset_gpio, 1);
+		gpiod_set_value_cansleep(ctx->reset_gpio, 0);
 		return ret;
 	}
 
@@ -202,7 +202,7 @@ static int sofef00_panel_probe(struct mipi_dsi_device *dsi)
 		return dev_err_probe(dev, PTR_ERR(ctx->supply),
 				     "Failed to get vddio regulator\n");
 
-	ctx->reset_gpio = devm_gpiod_get(dev, "reset", GPIOD_OUT_HIGH);
+	ctx->reset_gpio = devm_gpiod_get(dev, "reset", GPIOD_OUT_LOW);
 	if (IS_ERR(ctx->reset_gpio))
 		return dev_err_probe(dev, PTR_ERR(ctx->reset_gpio),
 				     "Failed to get reset-gpios\n");

-- 
2.51.0

