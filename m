From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Fri, 27 Nov 2026 21:32:23 +0800
Subject: [PATCH RESEND v4 1/3] pwm: loongson: Fix low pulse buffer register
 handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-pwm-loongson-fix-v4-1-607f325b74d4@gmail.com>
References: <20261127-pwm-loongson-fix-v4-0-607f325b74d4@gmail.com>
In-Reply-To: <20261127-pwm-loongson-fix-v4-0-607f325b74d4@gmail.com>
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>
Cc: linux-pwm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 "Imported from f20260920-pwm-loongson-fix-v4-0-41b36b3c6497"@gmail.com, 
 Keguang Zhang <keguang.zhang@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795786349; l=3560;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=DFazlz12Y6/wBIS6Dam/b9mRin3D6Nzh0Lwh4VsJ77g=;
 b=F1S+cjVPx2cGUd30vfgrtNyngtI2i5floNkR6Ftpo5t3TBUWvjdJNIk3+ziX4s71NDetBNWfD
 P/39O+Vtaz/A7Ib1NQT0lnzg7/T6HxL9v8AN11T7AxY6J8AS0jWmsvm
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

Fixes: 2b62c89448dd ("pwm: Add Loongson PWM controller support")
Cc: stable@vger.kernel.org
Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 drivers/pwm/pwm-loongson.c | 29 +++++++++++++++++------------
 1 file changed, 17 insertions(+), 12 deletions(-)

diff --git a/drivers/pwm/pwm-loongson.c b/drivers/pwm/pwm-loongson.c
index 4e8b54c8016c..0ec773fba813 100644
--- a/drivers/pwm/pwm-loongson.c
+++ b/drivers/pwm/pwm-loongson.c
@@ -33,7 +33,7 @@
 #include <linux/units.h>
 
 /* Loongson PWM registers */
-#define LOONGSON_PWM_REG_DUTY		0x4 /* Low Pulse Buffer Register */
+#define LOONGSON_PWM_REG_LOW		0x4 /* Low Pulse Buffer Register */
 #define LOONGSON_PWM_REG_PERIOD		0x8 /* Pulse Period Buffer Register */
 #define LOONGSON_PWM_REG_CTRL		0xc /* Control Register */
 
@@ -120,20 +120,20 @@ static int pwm_loongson_enable(struct pwm_chip *chip, struct pwm_device *pwm)
 static int pwm_loongson_config(struct pwm_chip *chip, struct pwm_device *pwm,
 			       u64 duty_ns, u64 period_ns)
 {
-	u64 duty, period;
+	u64 low, duty, period;
 	struct pwm_loongson_ddata *ddata = to_pwm_loongson_ddata(chip);
 
-	/* duty = duty_ns * ddata->clk_rate / NSEC_PER_SEC */
-	duty = mul_u64_u64_div_u64(duty_ns, ddata->clk_rate, NSEC_PER_SEC);
-	if (duty > U32_MAX)
-		duty = U32_MAX;
-
 	/* period = period_ns * ddata->clk_rate / NSEC_PER_SEC */
 	period = mul_u64_u64_div_u64(period_ns, ddata->clk_rate, NSEC_PER_SEC);
 	if (period > U32_MAX)
 		period = U32_MAX;
 
-	pwm_loongson_writel(ddata, duty, LOONGSON_PWM_REG_DUTY);
+	/* duty = duty_ns * ddata->clk_rate / NSEC_PER_SEC */
+	duty = mul_u64_u64_div_u64_roundup(duty_ns, ddata->clk_rate, NSEC_PER_SEC);
+	duty = min(duty, period);
+	low = period - duty;
+
+	pwm_loongson_writel(ddata, low, LOONGSON_PWM_REG_LOW);
 	pwm_loongson_writel(ddata, period, LOONGSON_PWM_REG_PERIOD);
 
 	return 0;
@@ -168,15 +168,20 @@ static int pwm_loongson_apply(struct pwm_chip *chip, struct pwm_device *pwm,
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
+	/* low & period have a max of 2^32 - 1, so we can't overflow */
+	if (low >= period)
+		state->duty_cycle = 0;
+	else
+		state->duty_cycle =
+		    DIV64_U64_ROUND_UP((u64)(period - low) * NSEC_PER_SEC, ddata->clk_rate);
+
 	state->period = DIV64_U64_ROUND_UP((u64)period * NSEC_PER_SEC, ddata->clk_rate);
 	state->polarity = (ctrl & LOONGSON_PWM_CTRL_REG_INVERT) ? PWM_POLARITY_INVERSED :
 			  PWM_POLARITY_NORMAL;

-- 
2.53.0

