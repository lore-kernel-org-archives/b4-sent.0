From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 27 Aug 2026 08:40:13 +0000
Subject: [PATCH v4 4/4] pwm: meson: Add support for Amlogic S7
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260827-s6-s7-pwm-v4-4-d28a2015177d@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787820043; l=1273;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=bxanl4T1hd21Hw06PnQXj6xGMQbU+zReu1OrHg7McSk=;
 b=0vaQo/fBgbLRHzWKS3mXgLiyVajPMUz9dbrbZVd3jjmB/2F56tL5Ry9j/ENdIlQL/PLCowQAm
 P2g2nAg4w+RBIldLTwsxHkfgwYiA7ukj3SBodgsTJ8I/HNKY0pwBTxL
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for Amlogic S7 PWM. Amlogic S7 different from the previous
SoCs, a controller includes one pwm, at the same time,the controller has
only one input clock source.

Also use the kernel coding style for the empty of_device_id terminator.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/pwm/pwm-meson.c | 13 ++++++++++++-
 1 file changed, 12 insertions(+), 1 deletion(-)

diff --git a/drivers/pwm/pwm-meson.c b/drivers/pwm/pwm-meson.c
index 6f151464d7cc..2da958231719 100644
--- a/drivers/pwm/pwm-meson.c
+++ b/drivers/pwm/pwm-meson.c
@@ -595,6 +595,13 @@ static const struct meson_pwm_data pwm_s4_data = {
 	.npwm = 2,
 };
 
+static const struct meson_pwm_data pwm_s7_data = {
+	.channels_init = meson_pwm_init_channels_per_channel_clk,
+	.has_constant = true,
+	.has_polarity = true,
+	.npwm = 1,
+};
+
 static const struct of_device_id meson_pwm_matches[] = {
 	{
 		.compatible = "amlogic,meson8-pwm-v2",
@@ -645,7 +652,11 @@ static const struct of_device_id meson_pwm_matches[] = {
 		.compatible = "amlogic,meson-s4-pwm",
 		.data = &pwm_s4_data
 	},
-	{},
+	{
+		.compatible = "amlogic,s7-pwm",
+		.data = &pwm_s7_data
+	},
+	{ }
 };
 MODULE_DEVICE_TABLE(of, meson_pwm_matches);
 

-- 
2.52.0

