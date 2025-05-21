From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Wed, 21 May 2025 14:02:58 +0100
Subject: [PATCH v4 08/20] mfd: adp5585: add a per chip reg struture
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250521-dev-adp5589-fw-v4-8-f2c988d7a7a0@analog.com>
References: <20250521-dev-adp5589-fw-v4-0-f2c988d7a7a0@analog.com>
In-Reply-To: <20250521-dev-adp5589-fw-v4-0-f2c988d7a7a0@analog.com>
To: linux-gpio@vger.kernel.org, linux-pwm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-input@vger.kernel.org
Cc: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Liu Ying <victor.liu@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747832589; l=2635;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=XA1lWQuxb7kOwZlsBaXLIk7ho0x94HOHXp0Aq/+w5Qs=;
 b=Cq1wuLRhBG6mL4v41W1pogVMRTCSCBijPZRDyTwBB+uGLx25d4+C3+DflLtmuHVJ+agnFV7/b
 LZTB3H/0Tb4BE4x6JbSzWfOtiF2kD6HXOraScgMOwEhY3/C1LrFvGcl
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There are some differences in the register map between the devices.
Hence, add a register structure per device. This will be needed in
following patches.

On top of that adp5585_fill_regmap_config() is renamed and reworked so
that the current struct adp5585_info act as template (they indeed
contain all the different data between variants) which can then be
complemented depending on the device (as identified by the id register).
This is done like this since a lot of the data is pretty much the same
between variants of the same device.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/mfd/adp5585.c       | 10 ++++++++++
 include/linux/mfd/adp5585.h |  6 ++++++
 2 files changed, 16 insertions(+)

diff --git a/drivers/mfd/adp5585.c b/drivers/mfd/adp5585.c
index 53ac46365e56874a05855f1df1843717148f181a..e90d16389732f3d8790eb910acd82be2033eaa7e 100644
--- a/drivers/mfd/adp5585.c
+++ b/drivers/mfd/adp5585.c
@@ -164,6 +164,14 @@ static const struct regmap_config adp5589_regmap_config_template = {
 	.num_reg_defaults_raw = ADP5589_MAX_REG + 1,
 };
 
+static const struct adp5585_regs adp5585_regs = {
+	.ext_cfg = ADP5585_PIN_CONFIG_C,
+};
+
+static const struct adp5585_regs adp5589_regs = {
+	.ext_cfg = ADP5589_PIN_CONFIG_D,
+};
+
 static int adp5585_fill_variant_config(struct adp5585_dev *adp5585,
 				       struct regmap_config *regmap_config)
 {
@@ -175,12 +183,14 @@ static int adp5585_fill_variant_config(struct adp5585_dev *adp5585,
 	case ADP5585_04:
 		*regmap_config = adp5585_regmap_config_template;
 		adp5585->id = ADP5585_MAN_ID_VALUE;
+		adp5585->regs = &adp5585_regs;
 		break;
 	case ADP5589_00:
 	case ADP5589_01:
 	case ADP5589_02:
 		*regmap_config = adp5589_regmap_config_template;
 		adp5585->id = ADP5589_MAN_ID_VALUE;
+		adp5585->regs = &adp5589_regs;
 		break;
 	default:
 		return -ENODEV;
diff --git a/include/linux/mfd/adp5585.h b/include/linux/mfd/adp5585.h
index 40c87981e5a24f8a175cc41e38b1495ed9f194e5..a20aa435100aaccb5ed22910933e1856409ba397 100644
--- a/include/linux/mfd/adp5585.h
+++ b/include/linux/mfd/adp5585.h
@@ -120,6 +120,7 @@
 /* ADP5589 */
 #define		ADP5589_MAN_ID_VALUE		0x10
 #define ADP5589_GPI_STATUS_C		0x18
+#define ADP5589_PIN_CONFIG_D		0x4C
 #define ADP5589_INT_EN			0x4e
 #define ADP5589_MAX_REG			ADP5589_INT_EN
 
@@ -137,7 +138,12 @@ enum adp5585_variant {
 	ADP5585_MAX
 };
 
+struct adp5585_regs {
+	unsigned int ext_cfg;
+};
+
 struct adp5585_dev {
+	const struct adp5585_regs *regs;
 	struct regmap *regmap;
 	struct device *dev;
 	enum adp5585_variant variant;

-- 
2.49.0

