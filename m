From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Fri, 26 Jun 2026 20:24:23 +0800
Subject: [PATCH v2 2/2] pwm: loongson: Reload PWM configuration through
 counter reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260626-pwm-loongson-fix-v2-2-5492db953879@gmail.com>
References: <20260626-pwm-loongson-fix-v2-0-5492db953879@gmail.com>
In-Reply-To: <20260626-pwm-loongson-fix-v2-0-5492db953879@gmail.com>
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>
Cc: linux-pwm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Keguang Zhang <keguang.zhang@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782476683; l=1528;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=WKaBUbBwEp56BQVM1m/OWceSdP7Tfsab3W614QpROZU=;
 b=bBfJDX7LTO7CnuOmKaofjRo/2vPxnRjSTOJCgj0u7FfUIVKi+XzHibYA55IJ3+VD7zFhDhB1f
 3M139q5GWxRAJKUvNRN32EphIUxi0Lxfy+ghcKtVGWWT8YuFyBk4hW7
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Loongson PWM controller latches the LOW and PERIOD registers only at
the start of each PWM period. After disabling and re-enabling the PWM,
the controller resumes from the previous counter value and completes the
current period before re-latching the updated LOW and PERIOD values.

Reset the PWM counter when disabling the PWM and release it when
enabling the PWM so that the updated LOW and PERIOD values are latched
before the PWM starts running again.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 drivers/pwm/pwm-loongson.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/pwm/pwm-loongson.c b/drivers/pwm/pwm-loongson.c
index 69514b5a1324..eec110ed9be4 100644
--- a/drivers/pwm/pwm-loongson.c
+++ b/drivers/pwm/pwm-loongson.c
@@ -103,6 +103,7 @@ static void pwm_loongson_disable(struct pwm_chip *chip, struct pwm_device *pwm)
 	struct pwm_loongson_ddata *ddata = to_pwm_loongson_ddata(chip);
 
 	val = pwm_loongson_readl(ddata, LOONGSON_PWM_REG_CTRL);
+	val |= LOONGSON_PWM_CTRL_REG_RST;
 	val &= ~LOONGSON_PWM_CTRL_REG_EN;
 	pwm_loongson_writel(ddata, val, LOONGSON_PWM_REG_CTRL);
 }
@@ -113,6 +114,7 @@ static int pwm_loongson_enable(struct pwm_chip *chip, struct pwm_device *pwm)
 	struct pwm_loongson_ddata *ddata = to_pwm_loongson_ddata(chip);
 
 	val = pwm_loongson_readl(ddata, LOONGSON_PWM_REG_CTRL);
+	val &= ~LOONGSON_PWM_CTRL_REG_RST;
 	val |= LOONGSON_PWM_CTRL_REG_EN;
 	pwm_loongson_writel(ddata, val, LOONGSON_PWM_REG_CTRL);
 

-- 
2.43.0

