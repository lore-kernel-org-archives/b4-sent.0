From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 27 Aug 2026 08:40:12 +0000
Subject: [PATCH v4 3/4] pwm: meson: use bulk API for per-channel clocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260827-s6-s7-pwm-v4-3-d28a2015177d@amlogic.com>
References: <20260827-s6-s7-pwm-v4-0-d28a2015177d@amlogic.com>
In-Reply-To: <20260827-s6-s7-pwm-v4-0-d28a2015177d@amlogic.com>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787820043; l=2584;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=I6lbpR1bOMmChsZo3uQ/k/8BNNbhwj3qLcmflQoEjK8=;
 b=j1659NKbIuXJqxgowGvB/TkkqxEEPFicBgqlHDxBXEX9bMCN9fRiQx9seZz5ofywGTUY37R5K
 0EH1aPdXWnQBkszh56C7j+op9cREnOXfODis0Hj3utlZ1eD5vzSxP3i
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The S4 PWM driver currently gets each channel clock individually with
of_clk_get() and uses a custom cleanup action to release the clocks.

Use devm_clk_bulk_get_all() instead to retrieve all per-channel clocks
at once. Verify that the number of clocks matches the number of PWM
channels and assign each clock to its corresponding channel.

This also allows the per-channel clock initialization code to be shared
by Meson PWM variants using one clock per channel.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/pwm/pwm-meson.c | 40 ++++++++++++++++------------------------
 1 file changed, 16 insertions(+), 24 deletions(-)

diff --git a/drivers/pwm/pwm-meson.c b/drivers/pwm/pwm-meson.c
index 22cefc6d5dd0..6f151464d7cc 100644
--- a/drivers/pwm/pwm-meson.c
+++ b/drivers/pwm/pwm-meson.c
@@ -497,33 +497,25 @@ static int meson_pwm_init_channels_meson8b_v2(struct pwm_chip *chip)
 	return meson_pwm_init_clocks_meson8b(chip, mux_parent_data);
 }
 
-static void meson_pwm_s4_put_clk(void *data)
-{
-	struct clk *clk = data;
-
-	clk_put(clk);
-}
-
-static int meson_pwm_init_channels_s4(struct pwm_chip *chip)
+static int meson_pwm_init_channels_per_channel_clk(struct pwm_chip *chip)
 {
 	struct device *dev = pwmchip_parent(chip);
-	struct device_node *np = dev->of_node;
 	struct meson_pwm *meson = to_meson_pwm(chip);
-	int i, ret;
+	struct clk_bulk_data *clks;
+	unsigned int i;
+	int num;
 
-	for (i = 0; i < chip->npwm; i++) {
-		meson->channels[i].clk = of_clk_get(np, i);
-		if (IS_ERR(meson->channels[i].clk))
-			return dev_err_probe(dev,
-					     PTR_ERR(meson->channels[i].clk),
-					     "Failed to get clk\n");
-
-		ret = devm_add_action_or_reset(dev, meson_pwm_s4_put_clk,
-					       meson->channels[i].clk);
-		if (ret)
-			return dev_err_probe(dev, ret,
-					     "Failed to add clk_put action\n");
-	}
+	num = devm_clk_bulk_get_all(dev, &clks);
+	if (num < 0)
+		return dev_err_probe(dev, num, "Failed to get clocks\n");
+
+	if (num != chip->npwm)
+		return dev_err_probe(dev, -EINVAL,
+				"expected %u clocks, got %d\n",
+				chip->npwm, num);
+
+	for (i = 0; i < chip->npwm; i++)
+		meson->channels[i].clk = clks[i].clk;
 
 	return 0;
 }
@@ -597,7 +589,7 @@ static const struct meson_pwm_data pwm_meson_axg_v2_data = {
 };
 
 static const struct meson_pwm_data pwm_s4_data = {
-	.channels_init = meson_pwm_init_channels_s4,
+	.channels_init = meson_pwm_init_channels_per_channel_clk,
 	.has_constant = true,
 	.has_polarity = true,
 	.npwm = 2,

-- 
2.52.0

