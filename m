From: Gregory Fuchedgi <gfuchedgi@gmail.com>
Date: Wed, 29 Apr 2026 14:54:14 -0700
Subject: [PATCH] amd-xgbe: fix PTP addend overflow causing frozen clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260429-fix-xgbe-ptp-addend-v1-1-fca5b0ca5e62@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAV+8mkC/x2MQQqAMAzAviI9W9AiU/yKeHBrnb3MsYkIsr87P
 AaSvJAlqWSYmxeS3Jr1DBX6tgF3bMELKlcG6sh0A02464OPt4LxirgxS2B0zva8GxoNEdQyJqn
 af13WUj5Pv04MZQAAAA==
To: Raju Rangoju <Raju.Rangoju@amd.com>, 
 Prashanth Kumar K R <PrashanthKumar.K.R@amd.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Richard Cochran <richardcochran@gmail.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Gregory Fuchedgi <gfuchedgi@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777499655; l=2038;
 i=gfuchedgi@gmail.com; s=20250811; h=from:subject:message-id;
 bh=Cw28xQLOHUHtos1dic3d/FADE55TTbWnyZfMkX9S3cY=;
 b=2iJIHjvr4n+p0miuEdP5oBsAcJJ7E1suy1Np1mk0fMWu8OgBrHPkKGWiIbuPZbGQyBsxafxs9
 RedEe1CdjBlDAaLlrHQs+QG5qNwfNuHHt6DidbU9v0WFAbmQFq80VQF
X-Developer-Key: i=gfuchedgi@gmail.com; a=ed25519;
 pk=J3o48+1a2mUIebH8K4S3SPuR5bmamUvjlsf8onoIccA=
X-Endpoint-Received: by B4 Relay for gfuchedgi@gmail.com/20250811 with auth_id=484
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

XGBE_PTP_ACT_CLK_FREQ and XGBE_V2_PTP_ACT_CLK_FREQ were 10x too
large (500MHz/1GHz instead of 50MHz/100MHz), causing the computed
addend to overflow the 32-bit tstamp_addend. In the general case
this would result in the clock advancing at the wrong rate. For v2
(PCI), ptpclk_rate is hardcoded to 125MHz, so the addend formula
(ACT_CLK_FREQ << 32) / ptpclk_rate yields exactly 8 * 2^32, and
when stored to the 32-bit tstamp_addend the value is zero. With
addend = 0 the hardware accumulator never overflows and the PTP
clock is fully stopped. For v1 (platform), ptpclk_rate is read from
ACPI/DT so the exact overflow behavior depends on the
firmware-reported frequency.

Define the constants as NSEC_PER_SEC / SSINC so the relationship is
explicit and cannot drift out of sync.

Fixes: fbd47be098b5 ("amd-xgbe: add hardware PTP timestamping support")
Tested-by: Gregory Fuchedgi <gfuchedgi@gmail.com>
Signed-off-by: Gregory Fuchedgi <gfuchedgi@gmail.com>
---
Tested by running ptp4l and verifying successful clock synchronization on v2
(PCI) hardware.
---
 drivers/net/ethernet/amd/xgbe/xgbe.h | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/net/ethernet/amd/xgbe/xgbe.h b/drivers/net/ethernet/amd/xgbe/xgbe.h
index 60b7e53206d1..3d3b09010d48 100644
--- a/drivers/net/ethernet/amd/xgbe/xgbe.h
+++ b/drivers/net/ethernet/amd/xgbe/xgbe.h
@@ -135,11 +135,11 @@
  */
 #define XGBE_TSTAMP_SSINC	20
 #define XGBE_TSTAMP_SNSINC	0
-#define XGBE_PTP_ACT_CLK_FREQ	500000000
+#define XGBE_PTP_ACT_CLK_FREQ	(NSEC_PER_SEC / XGBE_TSTAMP_SSINC)
 
 #define XGBE_V2_TSTAMP_SSINC	0xA
 #define XGBE_V2_TSTAMP_SNSINC	0
-#define XGBE_V2_PTP_ACT_CLK_FREQ	1000000000
+#define XGBE_V2_PTP_ACT_CLK_FREQ	(NSEC_PER_SEC / XGBE_V2_TSTAMP_SSINC)
 
 /* Define maximum supported values */
 #define XGBE_MAX_PPS_OUT	4

---
base-commit: 0c7a5ba011d336df4fcd1f667fcc16ea5549be12
change-id: 20260428-fix-xgbe-ptp-addend-ccb1df627622

Best regards,
-- 
Gregory Fuchedgi <gfuchedgi@gmail.com>

