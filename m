From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Tue, 24 Nov 2026 00:43:54 +0100
Subject: [PATCH v2 2/5] media: qcom: camss: csid-gen2: fix RDI enable bit
 manipulation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-camss-fixes-v2-2-231a5523cd59@gmail.com>
References: <20261124-camss-fixes-v2-0-231a5523cd59@gmail.com>
In-Reply-To: <20261124-camss-fixes-v2-0-231a5523cd59@gmail.com>
To: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795477434; l=1833;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=HdZ/kiLTYzmyYGEK8RNIy5DJBdKNKjogTSj8Z7rvO+E=;
 b=XkhckD3zoYg0tAT2Fys1PjQHYuZl06bniTUNdElDPtVTPPlmj1vPebSjh7BGfLM+RIAQihJ14
 ILvIxh/YcUaAlbBxGjweAGrkgWmEPFpwIsEvSqJaV/InRyW/ybpzuRH
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In __csid_configure_rdi_stream(), bitwise ORing `enable << RDI_CFG0_ENABLE`
into `val` never clears the enable bit when `enable` is zero.

Change `enable` to bool and explicitly set or clear BIT(RDI_CFG0_ENABLE)
depending on `enable`, matching camss-csid-680.c.

Fixes: 729fc005c8e2 ("media: qcom: camss: Split testgen, RDI and RX for CSID 170")
Reviewed-by: Bryan O'Donoghue <bryan.odonoghue@linaro.org>
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/media/platform/qcom/camss/camss-csid-gen2.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csid-gen2.c b/drivers/media/platform/qcom/camss/camss-csid-gen2.c
index eadcb2f..57ccfeb 100644
--- a/drivers/media/platform/qcom/camss/camss-csid-gen2.c
+++ b/drivers/media/platform/qcom/camss/camss-csid-gen2.c
@@ -253,7 +253,8 @@ static void __csid_configure_testgen(struct csid_device *csid, u8 enable, u8 por
 	writel_relaxed(val, csid->base + CSID_TPG_CTRL);
 }
 
-static void __csid_configure_rdi_stream(struct csid_device *csid, u8 enable, u8 port, u8 vc)
+static void __csid_configure_rdi_stream(struct csid_device *csid, bool enable,
+					u8 port, u8 vc)
 {
 	/* Source pads matching RDI channels on hardware. Pad 1 -> RDI0, Pad 2 -> RDI1, etc. */
 	struct v4l2_mbus_framefmt *input_format = &csid->fmt[MSM_CSID_PAD_FIRST_SRC + port];
@@ -318,7 +319,10 @@ static void __csid_configure_rdi_stream(struct csid_device *csid, u8 enable, u8
 	writel_relaxed(val, csid->base + CSID_RDI_CTRL(port));
 
 	val = readl_relaxed(csid->base + CSID_RDI_CFG0(port));
-	val |=  enable << RDI_CFG0_ENABLE;
+	if (enable)
+		val |= BIT(RDI_CFG0_ENABLE);
+	else
+		val &= ~BIT(RDI_CFG0_ENABLE);
 	writel_relaxed(val, csid->base + CSID_RDI_CFG0(port));
 }
 

-- 
2.56.0

