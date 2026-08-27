From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Thu, 27 Aug 2026 09:52:48 +0200
Subject: [PATCH 1/2] arm64: dts: qcom: sc8280xp-x13s: Enable HBR3 on
 external DPs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260827-x13s-dpaudio-v1-1-da73414c6ab5@oldschoolsolutions.biz>
References: <20260827-x13s-dpaudio-v1-0-da73414c6ab5@oldschoolsolutions.biz>
In-Reply-To: <20260827-x13s-dpaudio-v1-0-da73414c6ab5@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787817176; l=1164;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=IjBkXSfkK+lfRJ3mvGyWB4aKyDDuLURHFzJheJeLHog=;
 b=vxag/gwVTrklX/tl1jGbdMUmGtDbY+AOpYRu6dZ9PpoLXvyvbMPGdLUuuBljYwN/tMPYmniNM
 DhXpEv96bnSDIr4Z8L0iWdPom5rUbc31j6E4vnfFc1ATHhGz/pr4jtg
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When no link frequencies are set, the msm/dp driver defaults to HBR2.
Explicitly list the supported rates including HBR3 (8.1 Gbps) on both
USB-C DisplayPort endpoints so high-resolution docks and monitors can
train above 5.4 Gbps.

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts b/arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts
index 218573a97785b..467e14ca21e56 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts
+++ b/arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts
@@ -734,6 +734,7 @@ &mdss0_dp0 {
 
 &mdss0_dp0_out {
 	data-lanes = <0 1 2 3>;
+	link-frequencies = /bits/ 64 <1620000000 2700000000 5400000000 8100000000>;
 	remote-endpoint = <&usb_0_qmpphy_dp_in>;
 };
 
@@ -743,6 +744,7 @@ &mdss0_dp1 {
 
 &mdss0_dp1_out {
 	data-lanes = <0 1 2 3>;
+	link-frequencies = /bits/ 64 <1620000000 2700000000 5400000000 8100000000>;
 	remote-endpoint = <&usb_1_qmpphy_dp_in>;
 };
 

-- 
2.53.0

