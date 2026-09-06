From: George Moussalem <george.moussalem@outlook.com>
Date: Sun, 06 Sep 2026 08:46:41 +0400
Subject: [PATCH v3 02/10] usb: dwc3: qcom: Add support for selecting UTMI
 as reference clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-ipq-flatten-usb-v3-2-13e4e0f63123@outlook.com>
References: <20260906-ipq-flatten-usb-v3-0-13e4e0f63123@outlook.com>
In-Reply-To: <20260906-ipq-flatten-usb-v3-0-13e4e0f63123@outlook.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Wesley Cheng <quic_wcheng@quicinc.com>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788670018; l=1928;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=o+kaADaB/p5iiIE1oFwC/8s5jkCmJhEr9uLhza+Gk4A=;
 b=jdoxNq02LkiVU+QjL52dFm4hoFrIyClozniAK3hpKN92xpLxs2NgMSqqRhfHI1+E5H+C8j/KZ
 TKvs9C59Ds1D2RK6MEsDvJRMBNGLmaS1BbILAb/4fa8lUksoqVSD6Ac
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On many Qualcomm chipsets, the UTMI clock is used as the reference clock
(ex. IPQ5018, IPQ6018, and IPQ9574 and more). Since moving to the new
flattened snps-dwc3 model, it is no longer possible to pass the
reference clock to the dwc3 core driver.

The clock rate is used by the dwc3 core to compute the reference clock
period and frame length adjustment. This is needed when the reference
clock rate used computes values that deviate from the hardware defaults.
Above mentioned SoCs require values different from the defaults and, as
such, the core initializes with the wrong values which leads to
non-functional USB operation.

In Qualcomm chipsets, if available, the UTMI clock is used as the
reference clock. Therefore, acquire the reference clock by name
('mock_utmi') and pass its clock rate to the core using the probe_data
structure.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/usb/dwc3/dwc3-qcom.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/usb/dwc3/dwc3-qcom.c b/drivers/usb/dwc3/dwc3-qcom.c
index ac68b4218b56..8c1aca40c810 100644
--- a/drivers/usb/dwc3/dwc3-qcom.c
+++ b/drivers/usb/dwc3/dwc3-qcom.c
@@ -617,6 +617,7 @@ static int dwc3_qcom_probe(struct platform_device *pdev)
 	int			ret;
 	bool			ignore_pipe_clk;
 	bool			wakeup_source;
+	struct clk		*ref_clk;
 
 	qcom = devm_kzalloc(&pdev->dev, sizeof(*qcom), GFP_KERNEL);
 	if (!qcom)
@@ -698,6 +699,14 @@ static int dwc3_qcom_probe(struct platform_device *pdev)
 			qcom->current_role = USB_ROLE_DEVICE;
 	}
 
+	ref_clk = devm_clk_get_optional(dev, "mock_utmi");
+	if (IS_ERR(ref_clk)) {
+		ret = dev_err_probe(dev, PTR_ERR(ref_clk), "failed to get ref clock\n");
+		goto clk_disable;
+	} else if (ref_clk) {
+		probe_data.ref_clk_rate = clk_get_rate(ref_clk);
+	}
+
 	qcom->dwc.glue_ops = &dwc3_qcom_glue_ops;
 
 	qcom->dwc.dev = dev;

-- 
2.53.0

