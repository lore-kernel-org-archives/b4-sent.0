From: Fenglin Wu <quic_fenglinw@quicinc.com>
Date: Thu, 04 Jan 2024 16:06:15 +0800
Subject: [PATCH] arm64: dts: qcom: ipq6018: add #power-domain-cells for gcc
 node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240104-gcc-docs-update-v1-1-127e4816b798@quicinc.com>
X-B4-Tracking: v=1; b=H4sIAPdmlmUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDQwNj3fTkZN2U/ORi3dKClMSSVN20RDMDE1Nzy1QTMwsloK6CotS0zAq
 widGxtbUAaVWelGEAAAA=
To: kernel@quicinc.com, Andy Gross <agross@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Fenglin Wu <quic_fenglinw@quicinc.com>
X-Mailer: b4 0.13-dev-83828
X-Developer-Signature: v=1; a=ed25519-sha256; t=1704355580; l=1131;
 i=quic_fenglinw@quicinc.com; s=20230725; h=from:subject:message-id;
 bh=k5FTL0tX68N7q+lBdyKrIo31KP7acdzIrxYT2OyhZgc=;
 b=abrCFCuxmPSnsCJ/y93AtFGTJtZeBMF/Ug3F25N8p70GehtN+AlwjkWZ6xyxqiJwe88E62ByO
 1HXk03ySoYeD2BMgm1d61JWlTKQ+WvwsPE4zDk34U38oNGgJjycfQeK
X-Developer-Key: i=quic_fenglinw@quicinc.com; a=ed25519;
 pk=hleIDz3Unk1zeiwwOnZUjoQVMMelRancDFXg927lNjI=
X-Endpoint-Received: by B4 Relay for quic_fenglinw@quicinc.com/20230725 with auth_id=68
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Property '#power-domain-cells' is required as per defined in qcom,gcc.yaml
so add it for ipq6018 gcc device node to eliminate following warning in
dtbs_check:

arch/arm64/boot/dts/qcom/ipq6018-cp01-c1.dtb: gcc@1800000:
	'#power-domain-cells' is a required property
from schema $id: http://devicetree.org/schemas/clock/qcom,gcc-ipq6018.yaml#

Signed-off-by: Fenglin Wu <quic_fenglinw@quicinc.com>
---
 arch/arm64/boot/dts/qcom/ipq6018.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/qcom/ipq6018.dtsi b/arch/arm64/boot/dts/qcom/ipq6018.dtsi
index 39cd6b76b4c1..54914912d610 100644
--- a/arch/arm64/boot/dts/qcom/ipq6018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq6018.dtsi
@@ -386,6 +386,7 @@ gcc: gcc@1800000 {
 			reg = <0x0 0x01800000 0x0 0x80000>;
 			clocks = <&xo>, <&sleep_clk>;
 			clock-names = "xo", "sleep_clk";
+			#power-domain-cells = <1>;
 			#clock-cells = <1>;
 			#reset-cells = <1>;
 		};

---
base-commit: 17cb8a20bde66a520a2ca7aad1063e1ce7382240
change-id: 20240103-gcc-docs-update-fa604579e468

Best regards,
-- 
Fenglin Wu <quic_fenglinw@quicinc.com>

