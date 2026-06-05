From: David Heidelberg <david@ixit.cz>
Date: Fri, 05 Jun 2026 15:14:46 +0200
Subject: [PATCH v7 8/8] media: qcom: camss: Enable C-PHY where available
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-qcom-cphy-v7-8-426c37e9008f@ixit.cz>
References: <20260605-qcom-cphy-v7-0-426c37e9008f@ixit.cz>
In-Reply-To: <20260605-qcom-cphy-v7-0-426c37e9008f@ixit.cz>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 "Dr. Git" <drgitx@gmail.com>, Cory Keitz <ckeitz@amazon.com>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>
Cc: Frank Li <Frank.Li@nxp.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Kieran Bingham <kbingham@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1392; i=david@ixit.cz;
 h=from:subject:message-id; bh=yfuNEpBnQgvYmUSkvI5U4j/G6UateQzCMCBG6SxmfO0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqIsvCGPCeA6Vs/cZWC74UxxwO3XMTA73Yifj1y
 nb6TtTIXdqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaiLLwgAKCRBgAj/E00kg
 cvDwD/9N0SLyhXrNDXxcob+1QDH1XlDJH/a9IgDU+RMX/2YzGvIj5sE8A/LrCVcQjRW4xv+yVmU
 xhBOqmZRyWEqVJb8JYS3wto2Hjg3x88u5z5Xn7v0bI5J1fS4/pCFnQLlgEmWdm0ObtjDWmt83lH
 RZ7RebCn0YSnhvZwflkWGM5syyA2wBJkl3Mear/zJcXDg7MLysiXNxG62S+tENla3NldYYtook3
 Dwf41MF56Qqo/jPwESXhHqgfLsKjFGlhayui9Gbp5LDrfbph4BBna9pKZ3wsU3FZVoH3IkG7hhS
 7d2EWCMg2nihfN+6Zuxbog0KajAoKupv6QGXeilQuTlAB8Wu78CSXmI3IMxYOm6yz8uRJqfVtWv
 fn7VifJEjATmL0epGJS4Hat8Ev4NY3vGH/uzuJSO0Bd1GK6FgR0FqCNgZQJi8btNH1N1139HA/H
 xU0HtFCJrBlB8VZS/6KTQf+ot14T8c9aE6gIAj5yxy7+PmyQ/uoni4/wlxo8LMdsVHujyTZD8Fq
 +Yibhb+0GWuSWJf++z2pdKkIVNCCrAMp/7w/sut95OOkDarfuIXhnv3pVbw7GQ5rlJWt/CG/FSO
 XojozBjaDbxwI3h8qI5W7NUqULsmu2Acg1i/aQ4QSPFpnf87+UDxj1GfmxES41+1O9MfH6VllEM
 jHoOngc8lFjLKkA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After all the changes done we can now safely enable C-PHY for a SoC
where it's available.

Acked-by: Cory Keitz <ckeitz@amazon.com>
Reviewed-by: Bryan O'Donoghue <bod@kernel.org>
Reviewed-by: Frank Li <Frank.Li@nxp.com>
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

