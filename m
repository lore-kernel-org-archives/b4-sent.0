From: George Moussalem <george.moussalem@outlook.com>
Date: Tue, 25 Aug 2026 14:42:26 +0400
Subject: [PATCH 1/9] dt-bindings: usb: qcom,snps-dwc3: Add ability to
 select UTMI as reference clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-ipq-flatten-usb-v1-1-5c1f3170bbe9@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787654580; l=2093;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=PpmFa72hwQoy5I4zpkHd0b3hra/QO3YfJD1WlPOqoa4=;
 b=EuVX9KSNZOwoA0oaPoUM8tQBGYI6bSeOyFoi0yRtwHUcr0O+MAF2deFukun0alQeBviIQSN4B
 2YaYa9tHmR7DjbZ/uO/BfKDesBD0tj1LuB8LDkFsbLqH8Kd0RFvc0OB
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ability to select the UTMI clock as reference clock which is passed
by the glue layer to the DWC3 core to calculate the reference clock
period and frame length adjustment based on its clock rate.

In the flattened snsp-dwc3 model, it is currently not possible to pass a
reference clock that differs from the default since:
commit 613a2e655d4d ("usb: dwc3: core: Expose core driver as library")

This prevents moving chipsets such as IPQ5018, IPQ6018, IPQ5332, IPQ5424
and IPQ9574 with a reference clock rate different from 19.2 MHz from
moving to the flattened model.

The Qualcomm takes care of clock and resets management itself and sets
the ignore_clocks_and_resets flag in dwc3_probe_data to true, so the
core doesn't acquire the reference clock from the devicetree.

The existing DT property 'snps,quirk-ref-clk-period-ns' has been
deprecated.

So, add a property to select the UTMI clock used by many (if not all)
Qualcomm USB controllers as the reference clock.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 Documentation/devicetree/bindings/usb/qcom,snps-dwc3.yaml | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/Documentation/devicetree/bindings/usb/qcom,snps-dwc3.yaml b/Documentation/devicetree/bindings/usb/qcom,snps-dwc3.yaml
index ea60f7220afe..aa263dfd42a1 100644
--- a/Documentation/devicetree/bindings/usb/qcom,snps-dwc3.yaml
+++ b/Documentation/devicetree/bindings/usb/qcom,snps-dwc3.yaml
@@ -155,6 +155,15 @@ properties:
       HS/FS/LS modes are supported.
     type: boolean
 
+  qcom,select-utmi-as-ref-clk:
+    description:
+      If present, pass the UTMI clock as the reference clock to the DWC3 core to
+      use its clock rate to calculate the reference clock period and frame
+      length adjustment in GUCTL and GFLADJ registers. This is needed when these
+      values based on the standard clock rate deviate from the hardware default
+      values. If not set, the hardware default values are used.
+    type: boolean
+
   wakeup-source: true
 
 required:

-- 
2.53.0

