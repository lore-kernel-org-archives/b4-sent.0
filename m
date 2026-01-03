From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sat, 03 Jan 2026 10:00:23 +0100
Subject: [PATCH v2 1/2] arm64: dts: qcom: x1p42100-lenovo-thinkbook-16:
 force usb2-only mode on usb_1_ss2_dwc3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260103-tb16-hdmi-v2-1-92b0930fa82e@oldschoolsolutions.biz>
References: <20260103-tb16-hdmi-v2-0-92b0930fa82e@oldschoolsolutions.biz>
In-Reply-To: <20260103-tb16-hdmi-v2-0-92b0930fa82e@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Val Packett <val@packett.cool>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767430836; l=1047;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=qvHXN7aWllqPZdMuwrvQeLOkad2q5h6xoZcuTsDoVV8=;
 b=Uwbh4jqxo6srQ5LHmEn3AppEaRJ8Hc/zFhCDp4jEAc0mUm5uojBlT1bMAHcjt+ydi6ZXpnVK5
 QZDmr1QzN5nAiCp3jo011vhHK2k4uJ+JRK8d3v0qkmw/vVvrpojVC3Z
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The usb_1_ss2 complex has 2 phys, usb_1_ss2_hsphy and usb_1_ss2_qmpphy. On this
laptop, they are used for different peripherals: The hsphy for the fingerprint
reader, the qmpphy to drive a hdmi bridge. The normal logical wiring for the dwc3
controller is to both phys. Delete the port@1 to the qmpphy.

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 arch/arm64/boot/dts/qcom/x1p42100-lenovo-thinkbook-16.dts | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/x1p42100-lenovo-thinkbook-16.dts b/arch/arm64/boot/dts/qcom/x1p42100-lenovo-thinkbook-16.dts
index 3186e79e862de67cbda48a4b85a459e6e965ba65..b4a40904f0a01b36ff2fc72e801a5fe7d6971e2a 100644
--- a/arch/arm64/boot/dts/qcom/x1p42100-lenovo-thinkbook-16.dts
+++ b/arch/arm64/boot/dts/qcom/x1p42100-lenovo-thinkbook-16.dts
@@ -1560,6 +1560,8 @@ &usb_1_ss2_dwc3 {
 	maximum-speed = "high-speed";
 	phys = <&usb_1_ss2_hsphy>;
 	phy-names = "usb2-phy";
+
+	/delete-property/ port@1;
 };
 
 &usb_1_ss2_hsphy {

-- 
2.51.0

