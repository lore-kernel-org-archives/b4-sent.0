From: David Heidelberg <david@ixit.cz>
Date: Wed, 03 Jun 2026 01:30:46 +0200
Subject: [PATCH v6 8/8] media: qcom: camss: Enable C-PHY where available
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260603-qcom-cphy-v6-8-e50de0b557a8@ixit.cz>
References: <20260603-qcom-cphy-v6-0-e50de0b557a8@ixit.cz>
In-Reply-To: <20260603-qcom-cphy-v6-0-e50de0b557a8@ixit.cz>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 "Dr. Git" <drgitx@gmail.com>, Cory Keitz <ckeitz@amazon.com>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Kieran Bingham <kbingham@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1350; i=david@ixit.cz;
 h=from:subject:message-id; bh=WQAK+dTWd4zgEWrjdRbxx4I2y2Bah8Upe6SOIj07erk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqH2erjuxOKIAR+9NWPxdxKUDCuTfi2NbYCikRQ
 COb0d9Bi+GJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCah9nqwAKCRBgAj/E00kg
 cmjDD/4n7DVvh3LREds6dJWlxq9B/BDPRCKUbwEadOF1zpoety9Rv7X7b9Q1/tRyATv2fY+FLoE
 I7YrJMxuc7keo/YjNMsSM7SJe9AtE1g3r3capal4EELqIShe2NFX/9JXx0u7xKAkhDP2Cr9zhRr
 N7h4Fy+IFTc56UTy/cdz/+ps8ClZe2cQ++HFfbjmLRZpdmrpQXP5Nlb5NRBZVnkApD6KYEV3/do
 sI9o/6Cdskjv2mh/lL0epIkmCpeyoaJ4FdJ6Bj/R+uHexyAQcB+EmkiS/DbOVGPbpCtGj9yadrr
 +2dTC9UTvuaQiUBUPdE8HjTlL8XlplYo/uJL9zAM2eYECTkejcYqEyZYGFoVWrNBkTiQmpv/ops
 DTy8SsDCN/+B4ge2ZVX9cejnhITI9IQ2Trxj8FAAKAR1as/6BXeYvPzXHW5whcMOiJmi9ikG+/N
 0FgbcUy6nLaIaWaCHVRqwtbW4lFXKB7gkRh3/Xkao3MAdckELKLJSEyY2t9l+asEH7DE62Esexh
 nMsUEFC1BE4yJgJStdPgSRxPvIG3kjXuD0P/rqIv8wh+xPu9//CM/L3tH93b/DF/GQDEe6RkTyp
 yJ7P0/Lz2uCdoPmJ/+kA1FJlqmZ19OX1RT+poq1oudavVnWfn02GqocUfBZOYFrHd9bqUG2my8a
 xA+28VPx5AFYHQg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After all the changes done we can now safely enable C-PHY for a SoC
where it's available.

Acked-by: Cory Keitz <ckeitz@amazon.com>
Reviewed-by: Bryan O'Donoghue <bod@kernel.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/platform/qcom/camss/camss.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss.c b/drivers/media/platform/qcom/camss/camss.c
index db4e14a84a95f..555c53343a1e9 100644
--- a/drivers/media/platform/qcom/camss/camss.c
+++ b/drivers/media/platform/qcom/camss/camss.c
@@ -4761,21 +4761,21 @@ static int camss_parse_endpoint_node(struct device *dev,
 	struct v4l2_fwnode_endpoint vep = { { 0 } };
 	unsigned int i;
 	int ret;
 
 	ret = v4l2_fwnode_endpoint_parse(ep, &vep);
 	if (ret)
 		return ret;
 
-	/*
-	 * Most SoCs support both D-PHY and C-PHY standards, but currently only
-	 * D-PHY is supported in the driver.
-	 */
-	if (vep.bus_type != V4L2_MBUS_CSI2_DPHY) {
+	switch (vep.bus_type) {
+	case V4L2_MBUS_CSI2_CPHY:
+	case V4L2_MBUS_CSI2_DPHY:
+		break;
+	default:
 		dev_err(dev, "Unsupported bus type %d\n", vep.bus_type);
 		return -EINVAL;
 	}
 
 	csd->interface.csiphy_id = vep.base.port;
 
 	mipi_csi2 = &vep.bus.mipi_csi2;
 	lncfg->num_data = mipi_csi2->num_data_lanes;

-- 
2.53.0

