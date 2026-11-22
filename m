From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Sun, 22 Nov 2026 14:35:50 +0100
Subject: [PATCH 2/5] media: qcom: camss: csid-gen2: fix RDI enable bit
 manipulation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-camss-fixes-v1-2-9df4deb87ea2@gmail.com>
References: <20261122-camss-fixes-v1-0-9df4deb87ea2@gmail.com>
In-Reply-To: <20261122-camss-fixes-v1-0-9df4deb87ea2@gmail.com>
To: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795354550; l=1306;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=zM0Uu42Ddbem/8g+LtmsRQWe2AGrOjZvPkoLX5fxwxQ=;
 b=+HONEA34kOJw6KxpCU5Ac6z9m4aEkiH03Dyb7k/gaOCrt5fENaZZKDV0hXwqrK4jGpfSf6bv2
 MvcaqqgraciArJTx3CB3YO7Ac36Bj1izsNrxbJ87yLxptFY6sQtECyw
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In __csid_configure_rdi_stream(), shifting the u8 parameter `enable`
(promoted to signed int) left by RDI_CFG0_ENABLE (31) shifts into the
sign bit, and bitwise ORing never explicitly clears the enable bit when
`enable` is zero.

Use BIT(RDI_CFG0_ENABLE) to explicitly set or clear the bit depending
on `enable`, matching camss-csid-680.c.

Fixes: 729fc005c8e2 ("media: qcom: camss: Split testgen, RDI and RX for CSID 170")
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/media/platform/qcom/camss/camss-csid-gen2.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csid-gen2.c b/drivers/media/platform/qcom/camss/camss-csid-gen2.c
index eadcb2f..804c8fe 100644
--- a/drivers/media/platform/qcom/camss/camss-csid-gen2.c
+++ b/drivers/media/platform/qcom/camss/camss-csid-gen2.c
@@ -318,7 +318,10 @@ static void __csid_configure_rdi_stream(struct csid_device *csid, u8 enable, u8
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

