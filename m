From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Mon, 12 May 2025 13:39:01 +0100
Subject: [PATCH v3 09/22] mfd: adp5585: add a per chip reg struture
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250512-dev-adp5589-fw-v3-9-092b14b79a88@analog.com>
References: <20250512-dev-adp5589-fw-v3-0-092b14b79a88@analog.com>
In-Reply-To: <20250512-dev-adp5589-fw-v3-0-092b14b79a88@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747053537; l=3315;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=3iVX0xVXHMfTCqOCxVQCFOTkZu5YBUKukpZ3BtjbaQw=;
 b=dD9lYueUb1m7cfrndB9h8wYTptIunkTdZ+2Ntt+y1i4/n4v2Mz9eFGoN3/dqwYrq5t7/I03aQ
 cewtfgCLNzDAN1ws2BwOI+uEk5izTn7ktu+Kx/TT1C1ebkJPlipbHda
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
 drivers/mfd/adp5585.c       | 39 ++++++++++++++++++++++++++++++---------
 include/linux/mfd/adp5585.h |  6 ++++++
 2 files changed, 36 insertions(+), 9 deletions(-)

diff --git a/drivers/mfd/adp5585.c b/drivers/mfd/adp5585.c
index d593d21920c960f397a79f1b3f5c7118fedea73a..8be7a76842f639cbe90ad0eb956a7a3eef43fa3d 100644
--- a/drivers/mfd/adp5585.c
+++ b/drivers/mfd/adp5585.c
@@ -152,13 +152,38 @@ static const struct regmap_config adp5585_regmap_config_template = {
 	.num_reg_defaults_raw = ADP5585_MAX_REG + 1,
 };
 
-static int adp5585_fill_regmap_config(const struct adp5585_dev *adp5585,
-				      struct regmap_config *regmap_config)
+static const struct adp5585_regs adp5585_regs = {
+	.ext_cfg = ADP5585_PIN_CONFIG_C,
+};
+
+static const struct adp5585_regs adp5589_regs = {
+	.ext_cfg = ADP5589_PIN_CONFIG_D,
+};
+
+static int adp5585_fill_chip_configs(struct adp5585_dev *adp5585,
+				     struct i2c_client *i2c,
+				     struct regmap_config *regmap_config)
 {
-	if (adp5585->info->id == ADP5585_MAN_ID_VALUE)
+	struct adp5585_info *info;
+
+	info = (struct adp5585_info *)i2c_get_match_data(i2c);
+	if (!info)
+		return -ENODEV;
+
+	switch (info->id) {
+	case ADP5585_MAN_ID_VALUE:
 		*regmap_config = adp5585_regmap_config_template;
-	else
+		info->regs = &adp5585_regs;
+		break;
+	case ADP5589_MAN_ID_VALUE:
 		*regmap_config = adp5589_regmap_config_template;
+		info->regs = &adp5589_regs;
+		break;
+	default:
+		return -ENODEV;
+	}
+
+	adp5585->info = info;
 
 	switch (adp5585->info->regmap_type) {
 	case ADP5585_REGMAP_00:
@@ -238,11 +263,7 @@ static int adp5585_i2c_probe(struct i2c_client *i2c)
 
 	i2c_set_clientdata(i2c, adp5585);
 
-	adp5585->info = i2c_get_match_data(i2c);
-	if (!adp5585->info)
-		return -ENODEV;
-
-	ret = adp5585_fill_regmap_config(adp5585, &regmap_config);
+	ret = adp5585_fill_chip_configs(adp5585, i2c, &regmap_config);
 	if (ret)
 		return ret;
 
diff --git a/include/linux/mfd/adp5585.h b/include/linux/mfd/adp5585.h
index 5e19e38d4eac563275b01c3ec613ea62eba9d6c6..c8fa9684ecd3e869ab1fed7f257a340bfa4602f9 100644
--- a/include/linux/mfd/adp5585.h
+++ b/include/linux/mfd/adp5585.h
@@ -120,6 +120,7 @@
 /* ADP5589 */
 #define		ADP5589_MAN_ID_VALUE		0x10
 #define ADP5589_GPI_STATUS_C		0x18
+#define ADP5589_PIN_CONFIG_D		0x4C
 #define ADP5589_INT_EN			0x4e
 #define ADP5589_MAX_REG			ADP5589_INT_EN
 
@@ -134,7 +135,12 @@ enum adp5585_regmap_type {
 	ADP5589_REGMAP_02,
 };
 
+struct adp5585_regs {
+	unsigned int ext_cfg;
+};
+
 struct adp5585_info {
+	const struct adp5585_regs *regs;
 	enum adp5585_regmap_type regmap_type;
 	unsigned int id;
 };

-- 
2.49.0

