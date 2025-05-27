From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 27 May 2025 13:23:29 +0800
Subject: [PATCH v3 2/6] pinctrl: meson: a4: remove special data processing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250527-s6-s7-pinctrl-v3-2-44f6a0451519@amlogic.com>
References: <20250527-s6-s7-pinctrl-v3-0-44f6a0451519@amlogic.com>
In-Reply-To: <20250527-s6-s7-pinctrl-v3-0-44f6a0451519@amlogic.com>
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748323408; l=1982;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=g72piH28WZYJsuGTLrHAVcqtzDHjy35+PP/ZYnzW+rI=;
 b=rrK5/km3xKR3SJKuUH/4jDuMIKsv8qSz/aPkYq10bR2tZPJayF7mVdVQyuwBjHtR+yWBtREce
 LR2LUpEfu5tDH/vEu3hsoIA7N96Ws/T7KUNGgupXnZcd5CKOdSjxjNN
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

According to the data specifications of Amlogic's existing SoCs,
the function register offset and the bit offset are the same
value among various chips. Therefore, general processing can
be carried out without the need for private data modification.
Drop special data processing.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/pinctrl/meson/pinctrl-amlogic-a4.c | 33 +++---------------------------
 1 file changed, 3 insertions(+), 30 deletions(-)

diff --git a/drivers/pinctrl/meson/pinctrl-amlogic-a4.c b/drivers/pinctrl/meson/pinctrl-amlogic-a4.c
index 385cc619df13..11f68224342e 100644
--- a/drivers/pinctrl/meson/pinctrl-amlogic-a4.c
+++ b/drivers/pinctrl/meson/pinctrl-amlogic-a4.c
@@ -50,15 +50,8 @@ struct aml_pio_control {
 	u32 bit_offset[AML_NUM_REG];
 };
 
-struct aml_reg_bit {
-	u32 bank_id;
-	u32 reg_offs[AML_NUM_REG];
-	u32 bit_offs[AML_NUM_REG];
-};
-
 struct aml_pctl_data {
 	unsigned int number;
-	struct aml_reg_bit rb_offs[];
 };
 
 struct aml_pmx_func {
@@ -829,31 +822,11 @@ static const struct gpio_chip aml_gpio_template = {
 static void init_bank_register_bit(struct aml_pinctrl *info,
 				   struct aml_gpio_bank *bank)
 {
-	const struct aml_pctl_data *data = info->data;
-	const struct aml_reg_bit *aml_rb;
-	bool def_offs = true;
 	int i;
 
-	if (data) {
-		for (i = 0; i < data->number; i++) {
-			aml_rb = &data->rb_offs[i];
-			if (bank->bank_id == aml_rb->bank_id) {
-				def_offs = false;
-				break;
-			}
-		}
-	}
-
-	if (def_offs) {
-		for (i = 0; i < AML_NUM_REG; i++) {
-			bank->pc.reg_offset[i] = aml_def_regoffs[i];
-			bank->pc.bit_offset[i] = 0;
-		}
-	} else {
-		for (i = 0; i < AML_NUM_REG; i++) {
-			bank->pc.reg_offset[i] = aml_rb->reg_offs[i];
-			bank->pc.bit_offset[i] = aml_rb->bit_offs[i];
-		}
+	for (i = 0; i < AML_NUM_REG; i++) {
+		bank->pc.reg_offset[i] = aml_def_regoffs[i];
+		bank->pc.bit_offset[i] = 0;
 	}
 }
 

-- 
2.37.1

