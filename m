From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sat, 20 Dec 2025 18:47:09 +0100
Subject: [PATCH 1/2] arm64: dts: qcom: x1p42100-lenovo-thinkbook-16: force
 usb2-only mode on usb_1_ss2_dwc3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251220-tb16-hdmi-v1-1-18b1e20b396e@oldschoolsolutions.biz>
References: <20251220-tb16-hdmi-v1-0-18b1e20b396e@oldschoolsolutions.biz>
In-Reply-To: <20251220-tb16-hdmi-v1-0-18b1e20b396e@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Val Packett <val@packett.cool>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766252834; l=1227;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=E8oavXRiJ9H1foB04HdpgfXtgNtFJTJ6fhdED81IK24=;
 b=BGWpsS3qk/sTbV/IEd1uBM6f7fX4TAFb+4rSSmfGhelGAK+Oy1wlfkmy3PxfSvVv+HcQvZp19
 jI2qWoVYd9nCmgZbauYkkfqAbRx+loeZ5IyF3cGfntXjVMZoTOipkz7
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The usb_1_ss2 complex has 2 phys, usb_1_ss2_hsphy and usb_1_ss2_qmpphy. On this
laptop, they are used for different peripherals: The hsphy for the fingerprint
reader, the qmpphy to drive a hdmi bridge. The normal logical wiring for the dwc3
controller is to both phys. Overwrite that with ports only to the hsphy.

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 arch/arm64/boot/dts/qcom/x1p42100-lenovo-thinkbook-16.dts | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/x1p42100-lenovo-thinkbook-16.dts b/arch/arm64/boot/dts/qcom/x1p42100-lenovo-thinkbook-16.dts
index 3186e79e862de67cbda48a4b85a459e6e965ba65..b505a4cbb4350a962bbf779ec788265c7583bf20 100644
--- a/arch/arm64/boot/dts/qcom/x1p42100-lenovo-thinkbook-16.dts
+++ b/arch/arm64/boot/dts/qcom/x1p42100-lenovo-thinkbook-16.dts
@@ -1560,6 +1560,20 @@ &usb_1_ss2_dwc3 {
 	maximum-speed = "high-speed";
 	phys = <&usb_1_ss2_hsphy>;
 	phy-names = "usb2-phy";
+
+	/delete-property/ ports;
+
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@0 {
+			reg = <0>;
+
+			usb_1_ss2_dwc3_hs: endpoint {
+			};
+		};
+	};
 };
 
 &usb_1_ss2_hsphy {

-- 
2.51.0

