From: Ben Grisdale <bengris32@protonmail.ch>
Date: Fri, 06 Nov 2026 15:13:06 +0000
Subject: [PATCH 2/2] regulator: fan53555: Add support for Silergy SYM827
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-fan53555-silergy-sym827-support-v1-2-4e871c7f475c@protonmail.ch>
References: <20261106-fan53555-silergy-sym827-support-v1-0-4e871c7f475c@protonmail.ch>
In-Reply-To: <20261106-fan53555-silergy-sym827-support-v1-0-4e871c7f475c@protonmail.ch>
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793978058; l=1952;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=lTLxd0Alrxv01Mxu2bJsLMCCl2lEDtrVsj8UGBRpWO0=;
 b=MBJGxh6TDGaUv3+RYd1ITluz1IaLjchTD9MijA/wGGWwftyV6gJtNLZoGMTTkUzyXGjMdtAG/
 ncItC6dfD7FDzEmKGRwANtbPR96hs5yceXd12+vfYtIQwSRlIti2s1g
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Silergy SYM827 is a 6A synchronous step-down converter with a
similar I2C register map to the FAN53555.

SYM827 reports die ID 1. Its output starts at 600mV and increments in
12.5mV steps. No datasheet is available for this hardware, so the die ID
was read from devices, and the voltage range was taken from the
downstream driver [1].

Link: https://github.com/amazon-oss/android_kernel_amazon_mt8163/blob/7c8251b354f11a4703e6f7d5ad7b0c545bbed15d/drivers/regulator/sym827-regulator.c#L60-L62 [1]
Signed-off-by: Ben Grisdale <bengris32@protonmail.ch>
---
 drivers/regulator/fan53555.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/drivers/regulator/fan53555.c b/drivers/regulator/fan53555.c
index 6557d8cbe98d..9ac3a4e6832e 100644
--- a/drivers/regulator/fan53555.c
+++ b/drivers/regulator/fan53555.c
@@ -118,6 +118,7 @@ enum {
 };
 
 enum {
+	SILERGY_SYM827 = 1,
 	SILERGY_SYR82X = 8,
 	SILERGY_SYR83X = 9,
 };
@@ -412,6 +413,10 @@ static int fan53555_voltages_setup_silergy(struct fan53555_device_info *di)
 {
 	/* Init voltage range and step */
 	switch (di->chip_id) {
+	case SILERGY_SYM827:
+		di->vsel_min = 600000;
+		di->vsel_step = 12500;
+		break;
 	case SILERGY_SYR82X:
 	case SILERGY_SYR83X:
 		di->vsel_min = 712500;
@@ -684,6 +689,9 @@ static const struct of_device_id __maybe_unused fan53555_dt_ids[] = {
 	}, {
 		.compatible = "rockchip,rk8602",
 		.data = (void *)RK8602_VENDOR_ROCKCHIP
+	}, {
+		.compatible = "silergy,sym827",
+		.data = (void *)FAN53555_VENDOR_SILERGY,
 	}, {
 		.compatible = "silergy,syr827",
 		.data = (void *)FAN53555_VENDOR_SILERGY,
@@ -794,6 +802,9 @@ static const struct i2c_device_id fan53555_id[] = {
 	}, {
 		.name = "rk8602",
 		.driver_data = RK8602_VENDOR_ROCKCHIP
+	}, {
+		.name = "sym827",
+		.driver_data = FAN53555_VENDOR_SILERGY
 	}, {
 		.name = "syr827",
 		.driver_data = FAN53555_VENDOR_SILERGY

-- 
2.56.0

