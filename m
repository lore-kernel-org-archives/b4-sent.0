From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Fri, 27 Nov 2026 21:32:25 +0800
Subject: [PATCH RESEND v4 3/3] pwm: loongson: Use field helpers for period
 validation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-pwm-loongson-fix-v4-3-607f325b74d4@gmail.com>
References: <20261127-pwm-loongson-fix-v4-0-607f325b74d4@gmail.com>
In-Reply-To: <20261127-pwm-loongson-fix-v4-0-607f325b74d4@gmail.com>
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>
Cc: linux-pwm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 "Imported from f20260920-pwm-loongson-fix-v4-0-41b36b3c6497"@gmail.com, 
 Keguang Zhang <keguang.zhang@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795786349; l=1574;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=dw6b52g9dClE8N8lKTN5RhDZ6+WGuUSpcSRiL+WUkiM=;
 b=HjhaJuQ2+PE91tNSjPT0IAc9Lb7ik2E4CZ4uOg3zWjd6Djh2DPbTdfoFpMh92oXetLYhe0quc
 dvWhxRcrWqRA2szbzXX7Q9DZJYuz0qQ5ia3g4/ipH/TCriDim+e6FLd
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use FIELD_FIT() to validate the calculated period value and FIELD_MAX()
to get the maximum value allowed by the 32-bit period field.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 drivers/pwm/pwm-loongson.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/drivers/pwm/pwm-loongson.c b/drivers/pwm/pwm-loongson.c
index 6f609fd0b90b..33367c7473a3 100644
--- a/drivers/pwm/pwm-loongson.c
+++ b/drivers/pwm/pwm-loongson.c
@@ -22,6 +22,7 @@
  */
 
 #include <linux/acpi.h>
+#include <linux/bitfield.h>
 #include <linux/clk.h>
 #include <linux/device.h>
 #include <linux/init.h>
@@ -37,6 +38,8 @@
 #define LOONGSON_PWM_REG_PERIOD		0x8 /* Pulse Period Buffer Register */
 #define LOONGSON_PWM_REG_CTRL		0xc /* Control Register */
 
+#define LOONGSON_PWM_PERIOD_MASK	GENMASK(31, 0)
+
 /* Control register bits */
 #define LOONGSON_PWM_CTRL_REG_EN	BIT(0)  /* Counter Enable Bit */
 #define LOONGSON_PWM_CTRL_REG_OE	BIT(3)  /* Pulse Output Enable Control Bit, Valid Low */
@@ -133,8 +136,8 @@ static int pwm_loongson_config(struct pwm_chip *chip, struct pwm_device *pwm,
 
 	/* period = period_ns * ddata->clk_rate / NSEC_PER_SEC */
 	period = mul_u64_u64_div_u64(period_ns, ddata->clk_rate, NSEC_PER_SEC);
-	if (period > U32_MAX)
-		period = U32_MAX;
+	if (!FIELD_FIT(LOONGSON_PWM_PERIOD_MASK, period))
+		period = FIELD_MAX(LOONGSON_PWM_PERIOD_MASK);
 
 	/* duty = duty_ns * ddata->clk_rate / NSEC_PER_SEC */
 	duty = mul_u64_u64_div_u64_roundup(duty_ns, ddata->clk_rate, NSEC_PER_SEC);

-- 
2.53.0

