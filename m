From: Yang Xiwen <forbidden405@outlook.com>
Date: Tue, 17 Jun 2025 01:01:17 +0800
Subject: [PATCH v3] pinctrl: meson: support gpio toggle command
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250617-meson_ppinctrl-v3-1-218d9321a8d2@outlook.com>
X-B4-Tracking: v=1; b=H4sIANxNUGgC/33MQQ6CMBCF4auYrq1hBorFlfcwxpQySCO0pMVGQ
 7i7hZ0LXf4ved/MAnlDgZ12M/MUTTDOpsj3O6Y7Ze/ETZOaYYYiK+HIBwrO3sbRWD35ngvIK62
 yspYoWTqNnlrz2sDLNXVnwuT8e/MjrOtPKgIHLqpcKRAtSqnO7jn1zj0O2g1sxSL+BzABUDaga
 6wKaotvYFmWD3siz33vAAAA
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Tom Rini <trini@konsulko.com>, Beniamino Galvani <b.galvani@gmail.com>, 
 Simon Glass <sjg@chromium.org>
Cc: u-boot-amlogic@groups.io, u-boot@lists.denx.de, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750093277; l=2010;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=mxEAH2HvvvTNVZBSJXBVuHoaV1oekBHxb7P51f0Nz5U=;
 b=fNHW5rKhDt8VsiZdJnJclRdAFYcv8vj9psCaoCKlAXbLGuLXp+pwcOzljkhTJSJ9AUhG2vFY9
 kSV/KvqUb9kAYHhsFw3Gc+c3hXLVEhMXMBSlzKamyfP9vleC1vULvnd
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

meson_gpio_get() always assumes gpio is configured to input mode. This
is incorrect and breaks `gpio toggle` command:

gpio: pin aobus-banks2 (gpio 2) value is 0
   Warning: value of pin is still 1

Fix it by adding the logic to handle both input and output mode.

Fixes: 2009a8d03fe5 ("pinctrl: meson: add GPIO support")
Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v3:
- remove unused reg_type assignment.
- Link to v2: https://lore.kernel.org/r/20250617-meson_ppinctrl-v2-1-16d1cb294ef4@outlook.com

Changes in v2:
- return -EINVAL directly in case of error. (Neil Armstrong <neil.armstrong@linaro.org>)
- Link to v1: https://lore.kernel.org/r/20250617-meson_ppinctrl-v1-1-593aa15f288a@outlook.com
---
 drivers/pinctrl/meson/pinctrl-meson.c | 20 +++++++++++++++++++-
 1 file changed, 19 insertions(+), 1 deletion(-)

diff --git a/drivers/pinctrl/meson/pinctrl-meson.c b/drivers/pinctrl/meson/pinctrl-meson.c
index babf1bccc969..7dbaf966f93f 100644
--- a/drivers/pinctrl/meson/pinctrl-meson.c
+++ b/drivers/pinctrl/meson/pinctrl-meson.c
@@ -117,8 +117,26 @@ int meson_gpio_get(struct udevice *dev, unsigned int offset)
 	struct meson_pinctrl *priv = dev_get_priv(dev->parent);
 	unsigned int reg, bit;
 	int ret;
+	enum gpio_func_t direction;
+	enum meson_reg_type reg_type;
 
-	ret = meson_gpio_calc_reg_and_bit(dev->parent, offset, REG_IN, &reg,
+	direction = meson_gpio_get_direction(dev, offset);
+
+	switch (direction) {
+	case GPIOF_INPUT:
+		reg_type = REG_IN;
+		break;
+
+	case GPIOF_OUTPUT:
+		reg_type = REG_OUT;
+		break;
+
+	default:
+		dev_warn(dev, "Failed to get current direction of Pin %u\n", offset);
+		return -EINVAL;
+	}
+
+	ret = meson_gpio_calc_reg_and_bit(dev->parent, offset, reg_type, &reg,
 					  &bit);
 	if (ret)
 		return ret;

---
base-commit: c5afa1fef49f55146e78d6157470520391c40eca
change-id: 20250617-meson_ppinctrl-5139ca06b828

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

