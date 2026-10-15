From: George Neacsu <geocausa@gmail.com>
Date: Thu, 15 Oct 2026 23:20:38 +0100
Subject: [PATCH RFC 3/4] media: qcom: camss: csid-680: Select C-PHY in the
 receiver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-x1e-cphy-rfc-v1-3-1f3fa9af940a@gmail.com>
References: <20261015-x1e-cphy-rfc-v1-0-1f3fa9af940a@gmail.com>
In-Reply-To: <20261015-x1e-cphy-rfc-v1-0-1f3fa9af940a@gmail.com>
To: Bryan O'Donoghue <bod@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 David Heidelberg <david@ixit.cz>
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, linux-phy@lists.infradead.org, 
 linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, George Neacsu <geocausa@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792102835; l=954;
 i=geocausa@gmail.com; s=20261015; h=from:subject:message-id;
 bh=zIA90Rl/gtkLGho4hrUCxdrlhc5niDyVArSGj4xfgdM=;
 b=dxq1mf8fO50sxXqgXje86lxdhpWCCkmpix7jS568ln4jpofHpoSqOKdUHmWuSicEhghudMqwy
 zROe31y06DkCFz0gFQ8ltbPCGY67/Y7Q6MEooCwAXKNVWlTfde6sBz0
X-Developer-Key: i=geocausa@gmail.com; a=ed25519;
 pk=KyQk/iWbxsikewDBh0SwlHI51RvAqahD3loqmRp9DVI=
X-Endpoint-Received: by B4 Relay for geocausa@gmail.com/20261015 with auth_id=1199
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CSID 680 has a PHY type select in CSI2_RX_CFG0, next to the PHY number.
The field is defined but never written, so the receiver always decodes
D-PHY. Write phy_sel to it, as csid-gen2 does for C-PHY.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: George Neacsu <geocausa@gmail.com>
---
 drivers/media/platform/qcom/camss/camss-csid-680.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/media/platform/qcom/camss/camss-csid-680.c b/drivers/media/platform/qcom/camss/camss-csid-680.c
index 345a67c8f..16b199f06 100644
--- a/drivers/media/platform/qcom/camss/camss-csid-680.c
+++ b/drivers/media/platform/qcom/camss/camss-csid-680.c
@@ -202,6 +202,8 @@ static void __csid_configure_rx(struct csid_device *csid,
 			<< CSI2_RX_CFG0_PHY_NUM_SEL;
 	}
 
+	val |= phy->phy_sel << CSI2_RX_CFG0_PHY_TYPE_SEL;
+
 	writel(val, csid->base + CSID_CSI2_RX_CFG0);
 
 	val = CSI2_RX_CFG1_PACKET_ECC_CORRECTION_EN;

-- 
2.53.0

