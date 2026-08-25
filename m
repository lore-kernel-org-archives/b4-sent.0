From: George Moussalem <george.moussalem@outlook.com>
Date: Tue, 25 Aug 2026 14:42:28 +0400
Subject: [PATCH 3/9] usb: dwc3: qcom: Add support for selecting UTMI as
 reference clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-ipq-flatten-usb-v1-3-5c1f3170bbe9@outlook.com>
References: <20260825-ipq-flatten-usb-v1-0-5c1f3170bbe9@outlook.com>
In-Reply-To: <20260825-ipq-flatten-usb-v1-0-5c1f3170bbe9@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787654580; l=2074;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=IcMBry42eYPvkI9bqgoJ0mKN1T29dETKkJm3TDSEDqQ=;
 b=BsQfnDzO0TLBZ6Yyad0M5dIlm2SMDXkIzWw0tUEGJxjetAasa20HW8fCBpwhX2iRvsnfSlCM/
 umhR9eH1+uLDHby/I+dvLMOVcMai1utHlDYS2qEN2QbYjT3t+L357PS
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On many Qualcomm chipsets, the UTMI clock is used as the reference clock
(ex. IPQ5018, IPQ6018, and IPQ9574 and more). Since moving to the new
flattened snps-dwc3 model, it is no longer possible to pass the
reference clock to the dwc3 core driver.

The clock rate is used by dwc3 core to derive the reference clock period
and frame length adjusment. This is needed when the reference clock
deviates from the hardware default (typically 19.2MHz). Above mentioned
SoCs use different rates and, as such, the core initializes with the
wrong values which leads to non-functional USB operation.

Read the "qcom,select-utmi-as-ref-clk" property to determine if the UTMI
clock should be used as the reference clock. If so, set it as the
reference clock in the dwc3_probe_data structure.
The dwc3 core driver will then use this clock to derive the clock rate.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/usb/dwc3/dwc3-qcom.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/drivers/usb/dwc3/dwc3-qcom.c b/drivers/usb/dwc3/dwc3-qcom.c
index ac68b4218b56..17292517c594 100644
--- a/drivers/usb/dwc3/dwc3-qcom.c
+++ b/drivers/usb/dwc3/dwc3-qcom.c
@@ -617,6 +617,8 @@ static int dwc3_qcom_probe(struct platform_device *pdev)
 	int			ret;
 	bool			ignore_pipe_clk;
 	bool			wakeup_source;
+	bool			select_utmi_as_ref_clk;
+	struct clk		*ref_clk;
 
 	qcom = devm_kzalloc(&pdev->dev, sizeof(*qcom), GFP_KERNEL);
 	if (!qcom)
@@ -698,6 +700,18 @@ static int dwc3_qcom_probe(struct platform_device *pdev)
 			qcom->current_role = USB_ROLE_DEVICE;
 	}
 
+	select_utmi_as_ref_clk = device_property_read_bool(dev,
+					"qcom,select-utmi-as-ref-clk");
+	if (select_utmi_as_ref_clk) {
+		ref_clk = devm_clk_get_optional(dev, "mock_utmi");
+		if (IS_ERR(ref_clk)) {
+			ret = PTR_ERR(ref_clk);
+			dev_warn(dev, "failed to get ref clock: %d\n", ret);
+		} else {
+			probe_data.ref_clk = ref_clk;
+		}
+	}
+
 	qcom->dwc.glue_ops = &dwc3_qcom_glue_ops;
 
 	qcom->dwc.dev = dev;

-- 
2.53.0

