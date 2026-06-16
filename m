From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Tue, 16 Jun 2026 19:13:17 +0800
Subject: [PATCH 1/2] pwm: loongson: Fix low pulse buffer register handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260616-pwm-loongson-fix-v1-1-491dbf260a7f@gmail.com>
References: <20260616-pwm-loongson-fix-v1-0-491dbf260a7f@gmail.com>
In-Reply-To: <20260616-pwm-loongson-fix-v1-0-491dbf260a7f@gmail.com>
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>
Cc: linux-pwm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Keguang Zhang <keguang.zhang@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781608406; l=3888;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=DNMp7Yft9qmQudEtetNcd8RiwL5OJSFdiB2+KDs/znE=;
 b=b0vsrenpdusZYMR2eyHeWpFQEswnVwkLurESOF81tgOwBsDkeB2eHPZ8YNScWtm76r8nUR1U1
 a+HtFXXXbsjCX+LN249Zs9Xe8Vpcy2fsQkFhp1sFLh25hmahL3YlKzV
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Loongson PWM register at offset 0x4 is documented as the Low
Pulse Buffer Register, which stores the low pulse width rather than
the duty cycle.

However, this register was incorrectly defined and treated as a
duty-cycle register. As a result, the duty cycle and low pulse cycle
are swapped in the generated PWM waveform.

Program the low pulse (period - duty) into the register and
adjust pwm_loongson_get_state() accordingly when reconstructing the
duty cycle.

Also return -ERANGE when the requested period exceeds the hardware
32-bit limit instead of silently truncating the value.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 drivers/pwm/pwm-loongson.c | 29 ++++++++++++++---------------
 1 file changed, 14 insertions(+), 15 deletions(-)

diff --git a/drivers/pwm/pwm-loongson.c b/drivers/pwm/pwm-loongson.c
index 31a57edecfd0..dc77f82fd888 100644
--- a/drivers/pwm/pwm-loongson.c
+++ b/drivers/pwm/pwm-loongson.c
@@ -22,6 +22,7 @@
  */
 
 #include <linux/acpi.h>
+#include <linux/bitfield.h>
 #include <linux/clk.h>
 #include <linux/device.h>
 #include <linux/init.h>
@@ -33,10 +34,12 @@
 #include <linux/units.h>
 
 /* Loongson PWM registers */
-#define LOONGSON_PWM_REG_DUTY		0x4 /* Low Pulse Buffer Register */
+#define LOONGSON_PWM_REG_LOW		0x4 /* Low Pulse Buffer Register */
 #define LOONGSON_PWM_REG_PERIOD		0x8 /* Pulse Period Buffer Register */
 #define LOONGSON_PWM_REG_CTRL		0xc /* Control Register */
 
+#define LOONGSON_PWM_MAX_PERIOD		GENMASK(31, 0)
+
 /* Control register bits */
 #define LOONGSON_PWM_CTRL_REG_EN	BIT(0)  /* Counter Enable Bit */
 #define LOONGSON_PWM_CTRL_REG_OE	BIT(3)  /* Pulse Output Enable Control Bit, Valid Low */
@@ -118,20 +121,16 @@ static int pwm_loongson_enable(struct pwm_chip *chip, struct pwm_device *pwm)
 static int pwm_loongson_config(struct pwm_chip *chip, struct pwm_device *pwm,
 			       u64 duty_ns, u64 period_ns)
 {
-	u64 duty, period;
+	u64 low, period;
 	struct pwm_loongson_ddata *ddata = to_pwm_loongson_ddata(chip);
 
-	/* duty = duty_ns * ddata->clk_rate / NSEC_PER_SEC */
-	duty = mul_u64_u64_div_u64(duty_ns, ddata->clk_rate, NSEC_PER_SEC);
-	if (duty > U32_MAX)
-		duty = U32_MAX;
-
-	/* period = period_ns * ddata->clk_rate / NSEC_PER_SEC */
 	period = mul_u64_u64_div_u64(period_ns, ddata->clk_rate, NSEC_PER_SEC);
-	if (period > U32_MAX)
-		period = U32_MAX;
+	if ((!FIELD_FIT(LOONGSON_PWM_MAX_PERIOD, period)))
+		return -ERANGE;
+
+	low = mul_u64_u64_div_u64(period_ns - duty_ns, ddata->clk_rate, NSEC_PER_SEC);
 
-	pwm_loongson_writel(ddata, duty, LOONGSON_PWM_REG_DUTY);
+	pwm_loongson_writel(ddata, low, LOONGSON_PWM_REG_LOW);
 	pwm_loongson_writel(ddata, period, LOONGSON_PWM_REG_PERIOD);
 
 	return 0;
@@ -166,15 +165,15 @@ static int pwm_loongson_apply(struct pwm_chip *chip, struct pwm_device *pwm,
 static int pwm_loongson_get_state(struct pwm_chip *chip, struct pwm_device *pwm,
 				  struct pwm_state *state)
 {
-	u32 duty, period, ctrl;
+	u32 low, period, ctrl;
 	struct pwm_loongson_ddata *ddata = to_pwm_loongson_ddata(chip);
 
-	duty = pwm_loongson_readl(ddata, LOONGSON_PWM_REG_DUTY);
+	low = pwm_loongson_readl(ddata, LOONGSON_PWM_REG_LOW);
 	period = pwm_loongson_readl(ddata, LOONGSON_PWM_REG_PERIOD);
 	ctrl = pwm_loongson_readl(ddata, LOONGSON_PWM_REG_CTRL);
 
-	/* duty & period have a max of 2^32, so we can't overflow */
-	state->duty_cycle = DIV64_U64_ROUND_UP((u64)duty * NSEC_PER_SEC, ddata->clk_rate);
+	/* low & period have a max of 2^32, so we can't overflow */
+	state->duty_cycle = DIV64_U64_ROUND_UP((u64)(period - low) * NSEC_PER_SEC, ddata->clk_rate);
 	state->period = DIV64_U64_ROUND_UP((u64)period * NSEC_PER_SEC, ddata->clk_rate);
 	state->polarity = (ctrl & LOONGSON_PWM_CTRL_REG_INVERT) ? PWM_POLARITY_INVERSED :
 			  PWM_POLARITY_NORMAL;

-- 
2.43.0

