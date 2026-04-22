From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 22 Apr 2026 11:44:13 +0000
Subject: [PATCH] pinctrl: meson: amlogic-a4: fix deadlock issue
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-fix-pinconf-v1-1-abb4d2e0da55@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAIy06GkC/x3NQQqDQAyF4atI1gY02C68inQxkyY1m4xkigji3
 Tt2+fP4eCdUCZMKc3dCyG7VircY+w54Tf4RtHdroIGew0SEagdu5lxccaIsIzPpIyk0kVMVzJG
 c19toCXQ5vve0hTT5P1pe1/UD9QwM4XgAAAA=
X-Change-ID: 20260422-fix-pinconf-42be1cc2f5af
To: Linus Walleij <linusw@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-gpio@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776858256; l=2200;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=Ss1NSqKaiC5N5QiCWkTV2uRyv5Uo42HRnPH2RlMwg5E=;
 b=fr7u9d+eLFEa7sccl3XsNIMQoaiZ7WblPDxAAp4bIzh/HrYB6ydQXMiU1Ec+47fQmUWfWWegx
 Yj1u23N8KyqBcB7KMBYSwEMnn8XKl/x0IRNVvlYw3sfzP8B5LsRUsqG
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Accessing the pinconf-pins sysfs node may deadlock.

pinconf_pins_show() holds pctldev->mutex, and the platform driver
calls pinctrl_find_gpio_range_from_pin(), which tries to acquire
the same mutex again, leading to a deadlock.

Use pinctrl_find_gpio_range_from_pin_nolock() to fix this issue.

Fixes: 6e9be3abb78c ("pinctrl: Add driver support for Amlogic SoCs")
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Fix deadlock issue.
---
 drivers/pinctrl/meson/pinctrl-amlogic-a4.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/pinctrl/meson/pinctrl-amlogic-a4.c b/drivers/pinctrl/meson/pinctrl-amlogic-a4.c
index e2293a872dcb..35d27626a336 100644
--- a/drivers/pinctrl/meson/pinctrl-amlogic-a4.c
+++ b/drivers/pinctrl/meson/pinctrl-amlogic-a4.c
@@ -292,7 +292,7 @@ static int aml_calc_reg_and_bit(struct pinctrl_gpio_range *range,
 static int aml_pinconf_get_pull(struct aml_pinctrl *info, unsigned int pin)
 {
 	struct pinctrl_gpio_range *range =
-			 pinctrl_find_gpio_range_from_pin(info->pctl, pin);
+			 pinctrl_find_gpio_range_from_pin_nolock(info->pctl, pin);
 	struct aml_gpio_bank *bank = gpio_chip_to_bank(range->gc);
 	unsigned int reg, bit, val;
 	int ret, conf;
@@ -326,7 +326,7 @@ static int aml_pinconf_get_drive_strength(struct aml_pinctrl *info,
 					  u16 *drive_strength_ua)
 {
 	struct pinctrl_gpio_range *range =
-			 pinctrl_find_gpio_range_from_pin(info->pctl, pin);
+			 pinctrl_find_gpio_range_from_pin_nolock(info->pctl, pin);
 	struct aml_gpio_bank *bank = gpio_chip_to_bank(range->gc);
 	unsigned int reg, bit;
 	unsigned int val;
@@ -365,7 +365,7 @@ static int aml_pinconf_get_gpio_bit(struct aml_pinctrl *info,
 				    unsigned int reg_type)
 {
 	struct pinctrl_gpio_range *range =
-			 pinctrl_find_gpio_range_from_pin(info->pctl, pin);
+			 pinctrl_find_gpio_range_from_pin_nolock(info->pctl, pin);
 	struct aml_gpio_bank *bank = gpio_chip_to_bank(range->gc);
 	unsigned int reg, bit, val;
 	int ret;

---
base-commit: bd7fd288490c64835a74c05e631c102ce056d5e1
change-id: 20260422-fix-pinconf-42be1cc2f5af

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

