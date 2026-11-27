From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Fri, 27 Nov 2026 21:26:24 +0100
Subject: [PATCH 1/5] media: qcom: camss: vfe-17x: fix VFE-Lite reset,
 debug, and bus IRQ handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-camss-titan17x-fixes-v1-1-541ab39e5889@gmail.com>
References: <20261127-camss-titan17x-fixes-v1-0-541ab39e5889@gmail.com>
In-Reply-To: <20261127-camss-titan17x-fixes-v1-0-541ab39e5889@gmail.com>
To: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Robert Foss <rfoss@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Andrey Konovalov <andrey.konovalov@linaro.org>, 
 Atanas Filipov <atanas.filipov@oss.qualcomm.com>, 
 Milen Mitkov <quic_mmitkov@quicinc.com>, 
 Gjorgji Rosikopulos <quic_grosikop@quicinc.com>
Cc: Mauro Carvalho Chehab <mchehab+huawei@kernel.org>, 
 linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Robert Ijtsma <robertijtsma@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795811183; l=4436;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=slCIoW8m+WuCtOrrO1UwNBrEMbQUo6Idymd4H2UtdxU=;
 b=mQQOZQs7cEzHmU9BAbADjuQLqPqZn/K3vrt6TffVHzZYl34A39Lc8ATvYO8p4ibECaF3bHEfJ
 Hl2sQTRHUB9CVgtIqO8+Pg2wpQbt49L8SEFJg+U2jgcf2P3BQwr9xbu
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Titan 17x VFE-Lite instances differ from the full VFE in several
registers and bus master counts:

- VFE-Lite does not implement CAMIF, bus bridge, testgen, or DSP blocks;
  omit those bits from vfe_global_reset() when vfe_is_lite(vfe).
- VFE-Lite lacks VFE_BUS_WM_DEBUG_STATUS_CFG (0x226c); guard writes to
  it behind !vfe_is_lite(vfe).
- VFE-Lite only has 4 write master clients rather than 24; program the
  4-client WM_ADDR_NO_SYNC_LITE_VAL mask into
  VFE_BUS_WM_ADDR_SYNC_NO_SYNC.
- VFE_BUS_IRQ_STATUS(n) and VFE_BUS_IRQ_CLEAR(n) consist of 3 bus IRQ
  registers (0..2), not vfe->res->line_num. On 4-line VFEs, iterating to
  line_num reads/writes offset 0x2068 (VFE_BUS_IRQ_CLEAR_GLOBAL), and on
  VFEs with fewer than 2 lines vfe_bus_status[1] would be left
  uninitialized. Iterate over the 3 bus IRQ registers instead.

Fixes: 7319cdf189bb ("media: camss: Add support for VFE hardware version Titan 170")
Cc: stable@vger.kernel.org
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/media/platform/qcom/camss/camss-vfe-17x.c | 30 ++++++++++++++---------
 1 file changed, 19 insertions(+), 11 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-vfe-17x.c b/drivers/media/platform/qcom/camss/camss-vfe-17x.c
index 9606236046629c2210740d829bbf5f55cbc09f1a..304dafb39ad5121ade50cf278e0ada53f5e5203e 100644
--- a/drivers/media/platform/qcom/camss/camss-vfe-17x.c
+++ b/drivers/media/platform/qcom/camss/camss-vfe-17x.c
@@ -137,9 +137,12 @@
 #define VFE_BUS_WM_ADDR_SYNC_FRAME_HEADER	(0x2080)
 
 #define VFE_BUS_WM_ADDR_SYNC_NO_SYNC		(0x2084)
-#define		BUS_VER2_MAX_CLIENTS (24)
+#define		BUS_VER2_MAX_CLIENTS		(24)
+#define		BUS_VER2_LITE_MAX_CLIENTS	(4)
 #define		WM_ADDR_NO_SYNC_DEFAULT_VAL \
 				((1 << BUS_VER2_MAX_CLIENTS) - 1)
+#define		WM_ADDR_NO_SYNC_LITE_VAL \
+				((1 << BUS_VER2_LITE_MAX_CLIENTS) - 1)
 
 #define VFE_BUS_WM_CGC_OVERRIDE			(0x200c)
 #define		WM_CGC_OVERRIDE_ALL		(0xFFFFF)
@@ -184,18 +187,20 @@ static inline void vfe_reg_set(struct vfe_device *vfe, u32 reg, u32 set_bits)
 static void vfe_global_reset(struct vfe_device *vfe)
 {
 	u32 reset_bits = GLOBAL_RESET_CMD_CORE		|
-			 GLOBAL_RESET_CMD_CAMIF		|
 			 GLOBAL_RESET_CMD_BUS		|
-			 GLOBAL_RESET_CMD_BUS_BDG	|
 			 GLOBAL_RESET_CMD_REGISTER	|
-			 GLOBAL_RESET_CMD_TESTGEN	|
-			 GLOBAL_RESET_CMD_DSP		|
 			 GLOBAL_RESET_CMD_IDLE_CGC	|
 			 GLOBAL_RESET_CMD_RDI0		|
 			 GLOBAL_RESET_CMD_RDI1		|
 			 GLOBAL_RESET_CMD_RDI2		|
 			 GLOBAL_RESET_CMD_RDI3;
 
+	if (!vfe_is_lite(vfe))
+		reset_bits |= GLOBAL_RESET_CMD_CAMIF	|
+			      GLOBAL_RESET_CMD_BUS_BDG	|
+			      GLOBAL_RESET_CMD_TESTGEN	|
+			      GLOBAL_RESET_CMD_DSP;
+
 	writel_relaxed(BIT(31), vfe->base + VFE_IRQ_MASK_0);
 
 	/* Make sure IRQ mask has been written before resetting */
@@ -208,10 +213,12 @@ static void vfe_wm_start(struct vfe_device *vfe, u8 wm, struct vfe_line *line)
 {
 	u32 val;
 
-	/*Set Debug Registers*/
-	val = DEBUG_STATUS_CFG_STATUS0(1) |
-	      DEBUG_STATUS_CFG_STATUS0(7);
-	writel_relaxed(val, vfe->base + VFE_BUS_WM_DEBUG_STATUS_CFG);
+	/* Set Debug Registers (Full VFE only; VFE Lite lacks 0x226c) */
+	if (!vfe_is_lite(vfe)) {
+		val = DEBUG_STATUS_CFG_STATUS0(1) |
+		      DEBUG_STATUS_CFG_STATUS0(7);
+		writel_relaxed(val, vfe->base + VFE_BUS_WM_DEBUG_STATUS_CFG);
+	}
 
 	/* BUS_WM_INPUT_IF_ADDR_SYNC_FRAME_HEADER */
 	writel_relaxed(0, vfe->base + VFE_BUS_WM_ADDR_SYNC_FRAME_HEADER);
@@ -223,7 +230,8 @@ static void vfe_wm_start(struct vfe_device *vfe, u8 wm, struct vfe_line *line)
 	writel_relaxed(0x0, vfe->base + VFE_BUS_WM_TEST_BUS_CTRL);
 
 	/* if addr_no_sync has default value then config the addr no sync reg */
-	val = WM_ADDR_NO_SYNC_DEFAULT_VAL;
+	val = vfe_is_lite(vfe) ? WM_ADDR_NO_SYNC_LITE_VAL :
+				 WM_ADDR_NO_SYNC_DEFAULT_VAL;
 	writel_relaxed(val, vfe->base + VFE_BUS_WM_ADDR_SYNC_NO_SYNC);
 
 	writel_relaxed(0xf, vfe->base + VFE_BUS_WM_BURST_LIMIT(wm));
@@ -337,7 +345,7 @@ static irqreturn_t vfe_isr(int irq, void *dev)
 	writel_relaxed(status0, vfe->base + VFE_IRQ_CLEAR_0);
 	writel_relaxed(status1, vfe->base + VFE_IRQ_CLEAR_1);
 
-	for (i = VFE_LINE_RDI0; i < vfe->res->line_num; i++) {
+	for (i = 0; i < 3; i++) {
 		vfe_bus_status[i] = readl_relaxed(vfe->base + VFE_BUS_IRQ_STATUS(i));
 		writel_relaxed(vfe_bus_status[i], vfe->base + VFE_BUS_IRQ_CLEAR(i));
 	}

-- 
2.47.3

