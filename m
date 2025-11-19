From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Date: Wed, 19 Nov 2025 14:06:43 +0800
Subject: [PATCH v3 2/2] leds: rgb: leds-qcom-lpg: Don't enable TRILED when
 configuring PWM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-lpg_triled_fix-v3-2-84b6dbdc774a@oss.qualcomm.com>
References: <20251119-lpg_triled_fix-v3-0-84b6dbdc774a@oss.qualcomm.com>
In-Reply-To: <20251119-lpg_triled_fix-v3-0-84b6dbdc774a@oss.qualcomm.com>
To: kernel@oss.qualcomm.com, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Bjorn Andersson <andersson@kernel.org>, linux-arm-msm@vger.kernel.org, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 Pavel Machek <pavel@ucw.cz>, linux-leds@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Fenglin Wu <fenglin.wu@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763532404; l=1457;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=U+wcmaq3xYdZ4UGGBdL6UlkAePK6V2RVv6Nso37Fbso=;
 b=7NXgXUkI+Lc6RUBYvT8HCUX3BNbVJKBH/xcndfzx5AOUB6kvxNrBRFc/IlIzFADoASq4/3wos
 XA0PR8iqBqnBPoAEgnXVFJDxMS/OcEvn3/iuVGwMYBlVCqX8MhhWvf1
X-Developer-Key: i=fenglin.wu@oss.qualcomm.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for fenglin.wu@oss.qualcomm.com/20240327 with auth_id=406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PWM signal from the LPG channel can be routed to PMIC GPIOs with
proper GPIO configuration, and it is not necessary to enable the
TRILED channel in that case. This also applies to the LPG channels
that mapped to TRILED channels. Additionally, enabling the TRILED
channel unnecessarily would cause a voltage increase in its power
supply. Hence remove it.

Fixes: 24e2d05d1b68 ("leds: Add driver for Qualcomm LPG")
Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
 drivers/leds/rgb/leds-qcom-lpg.c | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/drivers/leds/rgb/leds-qcom-lpg.c b/drivers/leds/rgb/leds-qcom-lpg.c
index 4f2a178e3d265a2cc88e651d3e2ca6ae3dfac2e2..e197f548cddb03d079c54c4a0f402402c5d047e2 100644
--- a/drivers/leds/rgb/leds-qcom-lpg.c
+++ b/drivers/leds/rgb/leds-qcom-lpg.c
@@ -2,7 +2,7 @@
 /*
  * Copyright (c) 2017-2022 Linaro Ltd
  * Copyright (c) 2010-2012, The Linux Foundation. All rights reserved.
- * Copyright (c) 2023-2024, Qualcomm Innovation Center, Inc. All rights reserved.
+ * Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
  */
 #include <linux/bits.h>
 #include <linux/bitfield.h>
@@ -1247,8 +1247,6 @@ static int lpg_pwm_apply(struct pwm_chip *chip, struct pwm_device *pwm,
 
 	lpg_apply(chan);
 
-	triled_set(lpg, chan->triled_mask, chan->enabled ? chan->triled_mask : 0);
-
 out_unlock:
 	mutex_unlock(&lpg->lock);
 

-- 
2.34.1

