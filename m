From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sun, 15 Nov 2026 08:21:29 +0000
Subject: [PATCH 2/2] media: rkvdec: Stop the VDPU383 core on timeout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-rkvdec-wdt-stop-v1-2-59e687c6cc63@gmail.com>
References: <20261115-rkvdec-wdt-stop-v1-0-59e687c6cc63@gmail.com>
In-Reply-To: <20261115-rkvdec-wdt-stop-v1-0-59e687c6cc63@gmail.com>
To: Detlev Casanova <detlev.casanova@collabora.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Alex Kazinsky <a.kazinsky@ideco.ru>, stable@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794730887; l=2992;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=igPIRoqR10XhXtRMntnOpxbLAunwjLzr9JIJfVVGwv8=;
 b=uDK7aEpPgMbGShhyHDHLQc5AGfT0UOsY5Ar/vSvRfvtp0JO7iOAsFrAIYv26VDvlfCA84Yf7c
 BNKe0CtcK23BXvO7k1DdQN0BDVFHfHaZXly0aQybwFwW5F0cxzPhAS0
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The watchdog's RK3399 register write does not stop a VDPU383 core
either. Use the IP reset, as the Rockchip BSP does, then reprogram the
IOMMU, which the reset leaves in bypass. No reset line pulse: on RK3576
the DT lines are the BIU resets.

Compile-tested only.

Fixes: fde24907570d ("media: rkvdec: Add H264 support for the VDPU383 variant")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../platform/rockchip/rkvdec/rkvdec-vdpu383-regs.h   |  4 ++++
 drivers/media/platform/rockchip/rkvdec/rkvdec.c      | 20 +++++++++++++++++++-
 2 files changed, 23 insertions(+), 1 deletion(-)

diff --git a/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu383-regs.h b/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu383-regs.h
index 04eb23297e37..b8ee9c4dd294 100644
--- a/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu383-regs.h
+++ b/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu383-regs.h
@@ -33,6 +33,9 @@
 #define VDPU383_LINK_DEC_ENABLE		0x40
 #define VDPU383_DEC_E_BIT		BIT(0)
 
+#define VDPU383_LINK_IP_RESET		0x044
+#define VDPU383_IP_RESET_EN		BIT(0)
+
 #define VDPU383_LINK_INT_EN		0x048
 #define VDPU383_INT_EN_IRQ		BIT(0)
 #define VDPU383_INT_EN_LINE_IRQ		BIT(1)
@@ -40,6 +43,7 @@
 #define VDPU383_LINK_STA_INT		0x04c
 #define VDPU383_STA_INT_DEC_RDY_STA	BIT(0)
 #define VDPU383_STA_INT_SOFTRESET_RDY	(BIT(10) | BIT(11))
+#define VDPU383_STA_INT_IP_RESET_RDY	BIT(11)
 #define VDPU383_STA_INT_ALL		0x3ff
 
 struct vdpu383_regs_common {
diff --git a/drivers/media/platform/rockchip/rkvdec/rkvdec.c b/drivers/media/platform/rockchip/rkvdec/rkvdec.c
index a8fdad2850fb..63482354bc2e 100644
--- a/drivers/media/platform/rockchip/rkvdec/rkvdec.c
+++ b/drivers/media/platform/rockchip/rkvdec/rkvdec.c
@@ -1644,6 +1644,24 @@ static void vdpu381_stop(struct rkvdec_dev *rkvdec)
 	rkvdec_iommu_restore(rkvdec);
 }
 
+static void vdpu383_stop(struct rkvdec_dev *rkvdec)
+{
+	void __iomem *link = rkvdec->link;
+	u32 status;
+
+	writel(FIELD_PREP_WM16(VDPU383_INT_EN_IRQ | VDPU383_INT_EN_LINE_IRQ, 0),
+	       link + VDPU383_LINK_INT_EN);
+	writel(VDPU383_IP_RESET_EN, link + VDPU383_LINK_IP_RESET);
+	if (readl_poll_timeout_atomic(link + VDPU383_LINK_STA_INT, status,
+				      status & VDPU383_STA_INT_IP_RESET_RDY,
+				      1, 200))
+		dev_warn(rkvdec->dev, "IP reset failed\n");
+	writel(FIELD_PREP_WM16(VDPU383_STA_INT_ALL | VDPU383_STA_INT_SOFTRESET_RDY, 0),
+	       link + VDPU383_LINK_STA_INT);
+
+	rkvdec_iommu_restore(rkvdec);
+}
+
 static void rkvdec_watchdog_func(struct work_struct *work)
 {
 	struct rkvdec_dev *rkvdec;
@@ -1779,7 +1797,7 @@ static const struct rcb_size_info vdpu383_rcb_sizes[] = {
 
 static const struct rkvdec_variant_ops vdpu383_variant_ops = {
 	.irq_handler = vdpu383_irq_handler,
-	.stop = rk3399_stop,
+	.stop = vdpu383_stop,
 	.colmv_size = vdpu383_colmv_size,
 	.flatten_matrices = vdpu383_flatten_matrices,
 };

-- 
2.55.0

