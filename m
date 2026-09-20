From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Sun, 20 Sep 2026 20:02:08 +0800
Subject: [PATCH v4 3/3] pwm: loongson: Use field helpers for period
 validation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260920-pwm-loongson-fix-v4-3-41b36b3c6497@gmail.com>
References: <20260920-pwm-loongson-fix-v4-0-41b36b3c6497@gmail.com>
In-Reply-To: <20260920-pwm-loongson-fix-v4-0-41b36b3c6497@gmail.com>
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>
Cc: linux-pwm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Keguang Zhang <keguang.zhang@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789905770; l=1574;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=y8tF/NQwV1xqRjbBFvvs1zZHcp9ww6rdG1gubXIGg+c=;
 b=MNU+K3C3DUDWEDrHPWSs95S3BRoARMbgu6OZqgwmWf09utvFBtGkD5IStGw3Sf60SWihY9VU/
 neEUbOoSwltApQclCphLn2VZeqhCD/W/mVyNVZwEr9CobdvVNOBeJwG
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
index 977d867bdb8a..178a7a69a11c 100644
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
2.43.0

