From: David Heidelberg <david@ixit.cz>
Date: Wed, 17 Jun 2026 10:32:27 +0200
Subject: [PATCH v9 9/9] media: qcom: camss: Enable C-PHY where available
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260617-qcom-cphy-v9-9-83da8a8e4e44@ixit.cz>
References: <20260617-qcom-cphy-v9-0-83da8a8e4e44@ixit.cz>
In-Reply-To: <20260617-qcom-cphy-v9-0-83da8a8e4e44@ixit.cz>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 "Dr. Git" <drgitx@gmail.com>, Cory Keitz <ckeitz@amazon.com>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Nihal Kumar Gupta <nihal.gupta@oss.qualcomm.com>
Cc: Frank Li <Frank.Li@nxp.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Kieran Bingham <kbingham@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1392; i=david@ixit.cz;
 h=from:subject:message-id; bh=XCi14gM/uWIoK+pzO3oCf9ehRkiwcrxS49fsQobP0+s=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqMluW+jF3Lr8VpM2COVKWC6hom9xxExNCesNF0
 ji1AO+ZoZqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCajJblgAKCRBgAj/E00kg
 cgKqEACYPm+mneNrVxrgg9Cz90IrI+Lw0KVPE3vMznPnf2VnIGXHtMbVIWNUoWDsQnWymZqOaM5
 4rLQHTc/Fq3lkDFlYUkuZ21fcYT9/760MUyiSrp5Eg/vhrLYXmO6mZl4bZgh27JYbpiDw+OgFho
 rQH0svTAMn6gfrUe14vrfAmb6+k6B/H4Z0h+CPq6EkGIDFmaECxcmRMOydv+QyBlJzflXHkBO1i
 8yzs+RK0RTVnYQOKKzMDYg5T0uP+vWexNdWVW0wIQRUBU+LbL6CeOB+ZE2hCfckx9y43NpK8tfX
 ijsiUmCWOppkUQqIQn3+GedKo/AHGlzur7cx82zR0m1xKrhDPaV23kK/F3oUovg7e9PWMDaPGUi
 xD5qeyBgQqFcgp5tQY9nVGOkmlb5EQwHslvXOpNsJYlK6Pbp69nHWqm3Obdkn5vmcyAcYD/cFwg
 ndF5uGxec0RmjKzRumFL1+EP3hn7EiF0SeewgJnwW7+QSVKxcbkY7P19xgA73U429k7mp3T2/bM
 7AAFpkWc+qD/vGikV8iENakNtm1ldblBad+4p2nfAIAj+NvHTxnzqKFFwVoAXNdRmWHPSfN6ijM
 0D/mY1PglUVQdddpWGgySSTbFKONS2i4NuTmyLM6o9+YmaFXAuPj0Mcg6GZSgxvG7YsViO6LtyQ
 Amj/5NUDzpYhd/w==
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
index 66171069057f8..ebf8f21b5fa2e 100644
--- a/drivers/media/platform/qcom/camss/camss.c
+++ b/drivers/media/platform/qcom/camss/camss.c
@@ -4760,21 +4760,21 @@ static int camss_parse_endpoint_node(struct device *dev,
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

