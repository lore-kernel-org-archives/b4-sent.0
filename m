From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Date: Fri, 14 Nov 2025 09:11:17 +0800
Subject: [PATCH] leds: rgb: leds-qcom-lpg: Only enable TRILED when LPG is
 used by LED
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251114-lpg_triled_fix-v1-1-9b239832c53c@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIALSBFmkC/x2MQQqAIBAAvxJ7TmhrO9hXIiJzswWx0IhA+nvSc
 QZmMiSOwgmGKkPkW5IcoQDWFaz7EhwrsYWhbdoeEUn5081XFM923uRRRKTRkDYdNVCiM3LR/3C
 c3vcDHrP9xWAAAAA=
X-Change-ID: 20251114-lpg_triled_fix-44491b49b340
To: kernel@oss.qualcomm.com, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Bjorn Andersson <andersson@kernel.org>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 Pavel Machek <pavel@ucw.cz>, linux-leds@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Fenglin Wu <fenglin.wu@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763082680; l=1599;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=ZkSaXsvBfZujLAHvPc5ZBO+V5tX5nGnW9dxKHbr4fm4=;
 b=gKYlb6Hc81ZK0ommoX8v83TmgQUCzK6Q9d/HyJngwypBSB2SHhoIMm2+iJktSmD+VGHZ9YXBt
 7icrT0EtEErB1L1MZL4LFkA3f0FqwN/iXxbEVSLjr9Mf+PyCteFvYYg
X-Developer-Key: i=fenglin.wu@oss.qualcomm.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for fenglin.wu@oss.qualcomm.com/20240327 with auth_id=406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enabling the TRILED channel will cause a voltage increase on its power
supply, which is unnecessary if the LPG channel is not being used to
control an LED.

Fixes: 24e2d05d1b68 ("leds: Add driver for Qualcomm LPG")
Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
 drivers/leds/rgb/leds-qcom-lpg.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/leds/rgb/leds-qcom-lpg.c b/drivers/leds/rgb/leds-qcom-lpg.c
index 4f2a178e3d265a2cc88e651d3e2ca6ae3dfac2e2..234059b4c0f49d0398030ae5f86967fc1905206d 100644
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
@@ -1247,7 +1247,9 @@ static int lpg_pwm_apply(struct pwm_chip *chip, struct pwm_device *pwm,
 
 	lpg_apply(chan);
 
-	triled_set(lpg, chan->triled_mask, chan->enabled ? chan->triled_mask : 0);
+	/* Only control TRILED if the LPG channel is used by TRILED */
+	if (chan->in_use && chan->triled_mask)
+		triled_set(lpg, chan->triled_mask, chan->enabled ? chan->triled_mask : 0);
 
 out_unlock:
 	mutex_unlock(&lpg->lock);

---
base-commit: ea1c4c7e648d1ca91577071fc42fdc219521098c
change-id: 20251114-lpg_triled_fix-44491b49b340

Best regards,
-- 
Fenglin Wu <fenglin.wu@oss.qualcomm.com>

