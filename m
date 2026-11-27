From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Fri, 27 Nov 2026 21:32:24 +0800
Subject: [PATCH RESEND v4 2/3] pwm: loongson: Reset the counters before
 enabling PWM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261127-pwm-loongson-fix-v4-2-607f325b74d4@gmail.com>
References: <20261127-pwm-loongson-fix-v4-0-607f325b74d4@gmail.com>
In-Reply-To: <20261127-pwm-loongson-fix-v4-0-607f325b74d4@gmail.com>
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>
Cc: linux-pwm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 "Imported from f20260920-pwm-loongson-fix-v4-0-41b36b3c6497"@gmail.com, 
 Keguang Zhang <keguang.zhang@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795786349; l=1375;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=nEffXoAuY0LXvNjn27LU1Ds6mcGSPElXiuPjP4r7awA=;
 b=ZB6/mPRpggxjXqpMw+PQxxBcr7XBNTXFyP0f5LOwzzfn8+/KTNrnXSx27T4SoWr60ydsrGBSd
 lbdpV78SKvJCROA1kEtfRv87GHevahMN77XE4zJZGexQS+OIhvnZZHq
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
index 0ec773fba813..6f609fd0b90b 100644
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
2.53.0

