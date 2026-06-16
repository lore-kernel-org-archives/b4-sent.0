From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Tue, 16 Jun 2026 19:13:18 +0800
Subject: [PATCH 2/2] pwm: loongson: Reload PWM configuration through
 counter reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260616-pwm-loongson-fix-v1-2-491dbf260a7f@gmail.com>
References: <20260616-pwm-loongson-fix-v1-0-491dbf260a7f@gmail.com>
In-Reply-To: <20260616-pwm-loongson-fix-v1-0-491dbf260a7f@gmail.com>
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>
Cc: linux-pwm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Keguang Zhang <keguang.zhang@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781608406; l=1462;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=gA7rBvBB2Sub27SnbTAe9bo34GLjvfL8/AMyT7b0/So=;
 b=CxJv9TjcbMOT5ECEV6qjJLXf0uHvkWiUq+iREd26eQiuA6gTrL5gNGkGVXLdCv6Clchv5tNqf
 aL6EFdsx5OeC4MEpMLTaVqr7AC+DZGeo6c+Y3N103VdVVn1Uj0rkTWC
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

By default, the Loongson PWM controller latches the LOW and PERIOD
registers only at the start of each PWM period, causing configuration
updates to be delayed until the next period.

Reset the PWM counter when disabling the PWM and release it when enabling
the PWM to force the controller to re-latch the updated LOW and PERIOD
values, allowing configuration changes to take effect immediately.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 drivers/pwm/pwm-loongson.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/pwm/pwm-loongson.c b/drivers/pwm/pwm-loongson.c
index dc77f82fd888..eb89ced530e1 100644
--- a/drivers/pwm/pwm-loongson.c
+++ b/drivers/pwm/pwm-loongson.c
@@ -102,6 +102,7 @@ static void pwm_loongson_disable(struct pwm_chip *chip, struct pwm_device *pwm)
 	struct pwm_loongson_ddata *ddata = to_pwm_loongson_ddata(chip);
 
 	val = pwm_loongson_readl(ddata, LOONGSON_PWM_REG_CTRL);
+	val |= LOONGSON_PWM_CTRL_REG_RST;
 	val &= ~LOONGSON_PWM_CTRL_REG_EN;
 	pwm_loongson_writel(ddata, val, LOONGSON_PWM_REG_CTRL);
 }
@@ -112,6 +113,7 @@ static int pwm_loongson_enable(struct pwm_chip *chip, struct pwm_device *pwm)
 	struct pwm_loongson_ddata *ddata = to_pwm_loongson_ddata(chip);
 
 	val = pwm_loongson_readl(ddata, LOONGSON_PWM_REG_CTRL);
+	val &= ~LOONGSON_PWM_CTRL_REG_RST;
 	val |= LOONGSON_PWM_CTRL_REG_EN;
 	pwm_loongson_writel(ddata, val, LOONGSON_PWM_REG_CTRL);
 

-- 
2.43.0

