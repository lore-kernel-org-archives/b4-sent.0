From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Sun, 20 Sep 2026 20:02:07 +0800
Subject: [PATCH v4 2/3] pwm: loongson: Reset the counters before enabling
 PWM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260920-pwm-loongson-fix-v4-2-41b36b3c6497@gmail.com>
References: <20260920-pwm-loongson-fix-v4-0-41b36b3c6497@gmail.com>
In-Reply-To: <20260920-pwm-loongson-fix-v4-0-41b36b3c6497@gmail.com>
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>
Cc: linux-pwm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Keguang Zhang <keguang.zhang@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789905770; l=1375;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=NyDNTlsnJdK4cl0ga4IeWZLMrmPfP3DVW7yBKqicjC4=;
 b=/Ly+hsfIlgz3pdAE1Sn8R2ixiFAUhwfEbv8E/4H2cjhVMkTojBjj4aAHFVbxAza5y5pS40oEg
 fvjNVzJg++YCwVn/bKGFN38eCoq0TFqK34L+aGve13mcv+iqyi0Gy61
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PWM controller may retain its initial hardware state when the driver
binds. Reset the counters before enabling to ensure that the PWM starts
from a known state.

Fixes: 2b62c89448dd ("pwm: Add Loongson PWM controller support")
Fixes: 0de9b836a3bc ("pwm: loongson: Reload PWM configuration through counter reset")
Cc: stable@vger.kernel.org
Suggested-by: Uwe Kleine-König <ukleinek@kernel.org>
Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 drivers/pwm/pwm-loongson.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/pwm/pwm-loongson.c b/drivers/pwm/pwm-loongson.c
index 7af5d4ce1060..977d867bdb8a 100644
--- a/drivers/pwm/pwm-loongson.c
+++ b/drivers/pwm/pwm-loongson.c
@@ -110,6 +110,14 @@ static int pwm_loongson_enable(struct pwm_chip *chip, struct pwm_device *pwm)
 	struct pwm_loongson_ddata *ddata = to_pwm_loongson_ddata(chip);
 
 	val = pwm_loongson_readl(ddata, LOONGSON_PWM_REG_CTRL);
+
+	/*
+	 * Ensure that the values of LOW and PERIOD are sampled into
+	 * the shadow register when the hardware starts running.
+	 */
+	if (!(val & LOONGSON_PWM_CTRL_REG_RST))
+		pwm_loongson_writel(ddata, val | LOONGSON_PWM_CTRL_REG_RST, LOONGSON_PWM_REG_CTRL);
+
 	val &= ~LOONGSON_PWM_CTRL_REG_RST;
 	val |= LOONGSON_PWM_CTRL_REG_EN;
 	pwm_loongson_writel(ddata, val, LOONGSON_PWM_REG_CTRL);

-- 
2.43.0

