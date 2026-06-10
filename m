From: David Heidelberg <david@ixit.cz>
Date: Wed, 10 Jun 2026 20:28:29 +0200
Subject: [PATCH v8 9/9] media: qcom: camss: Enable C-PHY where available
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260610-qcom-cphy-v8-9-cd4387785179@ixit.cz>
References: <20260610-qcom-cphy-v8-0-cd4387785179@ixit.cz>
In-Reply-To: <20260610-qcom-cphy-v8-0-cd4387785179@ixit.cz>
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
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqKazHPe7CrgTnpkmLrgbTun0CS0vFquYPcOBUc
 KqlyD1M+sqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaimsxwAKCRBgAj/E00kg
 co6BD/9zJdywY/m3WkTsIDim0Q6DStBPZcAFcGNUAKlldtZmEaG79K/bXMT3ioLz/dFHToNqwxm
 fzg75YJ1ZvElGmEW4rgRs2T+elX8zkgPfKCTqYIjxnSR7d7hrAPIPG1R9+jh3r8P4+i7GO0annI
 /eFkigAtIAvCGWuK14B1Kx61rERze4Edi4wPrn3DPXhR4G+YMAFIRfRxndLW8vXR2zgAVdj3ys9
 mQto3/EcRBNGt4aJ3zpvi5OQkpW04nsEyg6sycP6P/85ehBEv6Zic30ZIygbFW0pGfGzVJotNeU
 InEEUsiWvaZJ0ryOTFLZGoux0qa6vV6oe/k/rTigEVS7Z/BsWab17gLsTCTXQcqEh7RvT3OIWMg
 Lugm0moVOHaBvgvSrVnOz+YUln/JlfG1REKVevv7z36Ukn6i3grvhqoyNCejSMHXLJ5NlTUUAGi
 bkwyleFIJl73/47s/XHVIAp5V/79HunTC/EMhC7RIQ6gGUceYhS0I4mMz9u8vlzCjLORZ0RtD4D
 +o/YMG8a8mZt3fsTQg9c3yXIUDHwdmsqjBJ2hVAI4+kXcCgxx6utbYcbL3Cty47ZT6y5dJfdW12
 y0i4NyC71Kp+1GLUkf6R0ulqT75lqNy7cNKEcCwgexMk/WMqAWBKlHVhDKqF9HOplnBEHaU+3c0
 okxRp8ki8X8Jowg==
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

