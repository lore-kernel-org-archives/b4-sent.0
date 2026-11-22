From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Sun, 22 Nov 2026 14:35:49 +0100
Subject: [PATCH 1/5] media: qcom: camss: vfe-17x: check status1 for RDI SOF
 interrupts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-camss-fixes-v1-1-9df4deb87ea2@gmail.com>
References: <20261122-camss-fixes-v1-0-9df4deb87ea2@gmail.com>
In-Reply-To: <20261122-camss-fixes-v1-0-9df4deb87ea2@gmail.com>
To: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795354550; l=1123;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=/XplKxzo3xBe+qvINmUy9iYAgDI+ymaYkcn4JNfIyLM=;
 b=THI9NN12J8zHoYM+F9D7O4jV56puBXikRwbTvHTZW5S8l23e/4DVDRNNeeVT3upVMGxykRLZL
 0IuSQQ7CGkSB0E0dooOCvWZZuZEr6x3Ln1bcUjEcagTO4WkUK4TuQPV
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In vfe_isr(), STATUS_1_RDI_SOF(i) is a bitmask for VFE_IRQ_STATUS_1
(status1), not VFE_IRQ_STATUS_0 (status0). Checking status0 instead
tests the unrelated STATUS_0_IMAGE_COMPOSITE_DONE bits (27..30).

Check status1 against STATUS_1_RDI_SOF(i) as intended.

Fixes: 7319cdf189bb ("media: camss: Add support for VFE hardware version Titan 170")
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/media/platform/qcom/camss/camss-vfe-17x.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/media/platform/qcom/camss/camss-vfe-17x.c b/drivers/media/platform/qcom/camss/camss-vfe-17x.c
index 62c2405..502a0d4 100644
--- a/drivers/media/platform/qcom/camss/camss-vfe-17x.c
+++ b/drivers/media/platform/qcom/camss/camss-vfe-17x.c
@@ -356,7 +356,7 @@ static irqreturn_t vfe_isr(int irq, void *dev)
 			vfe->isr_ops.reg_update(vfe, i);
 
 	for (i = VFE_LINE_RDI0; i < vfe->res->line_num; i++)
-		if (status0 & STATUS_1_RDI_SOF(i))
+		if (status1 & STATUS_1_RDI_SOF(i))
 			vfe->isr_ops.sof(vfe, i);
 
 	for (i = 0; i < MSM_VFE_COMPOSITE_IRQ_NUM; i++)

-- 
2.56.0

