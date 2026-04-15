From: Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
Date: Wed, 15 Apr 2026 12:10:46 +0530
Subject: [PATCH] arm64: dts: qcom: monaco: add GDSP fastrpc-compute-cb
 nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260415-monacogdsp-v1-1-077ded36c7fc@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIAO0y32kC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDE0NT3dz8vMTk/PSU4gLdlCRzC9OUVAMLg1RTJaCGgqLUtMwKsGHRsbW
 1AFZZrDVcAAAA
X-Change-ID: 20260415-monacogdsp-db785de080e5
To: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, quic_bkumar@quicinc.com, 
 quic_chennak@quicinc.com, srinivas.kandagatla@oss.qualcomm.com
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776235246; l=1445;
 i=ekansh.gupta@oss.qualcomm.com; s=20260223; h=from:subject:message-id;
 bh=/EG/yomTV06O1VHp8itajNVeYotdDNN6kgP9T9ejF8I=;
 b=AnuUg5syqVnJpw+A6G+a6GG6nuPAgItZu+FyhX/IPzcS5wvq+dDEkVCvjc9+Oqi1t/cc9VFx1
 DB/V0xJlfzOCUXtJcBwccHRtOWufMsq4/0UivfWq4LxYE3xD4zCXNYe
X-Developer-Key: i=ekansh.gupta@oss.qualcomm.com; a=ed25519;
 pk=n0SepARizye+pYjhjg1RA5J+Nq4+IJbyRcBybU+/ERQ=
X-Endpoint-Received: by B4 Relay for ekansh.gupta@oss.qualcomm.com/20260223 with auth_id=647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add GDSP fastrpc compute-cb nodes for monaco SoC.

Signed-off-by: Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/monaco.dtsi | 29 +++++++++++++++++++++++++++++
 1 file changed, 29 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/monaco.dtsi b/arch/arm64/boot/dts/qcom/monaco.dtsi
index 7b1d57460f1e..ce6ff259cb4a 100644
--- a/arch/arm64/boot/dts/qcom/monaco.dtsi
+++ b/arch/arm64/boot/dts/qcom/monaco.dtsi
@@ -7615,6 +7615,35 @@ IPCC_MPROC_SIGNAL_GLINK_QMP
 
 				label = "gpdsp";
 				qcom,remote-pid = <17>;
+
+				fastrpc {
+					compatible = "qcom,fastrpc";
+					qcom,glink-channels = "fastrpcglink-apps-dsp";
+					label = "gdsp0";
+					#address-cells = <1>;
+					#size-cells = <0>;
+
+					compute-cb@1 {
+						compatible = "qcom,fastrpc-compute-cb";
+						reg = <1>;
+						iommus = <&apps_smmu 0x28a1 0x0>;
+						dma-coherent;
+					};
+
+					compute-cb@2 {
+						compatible = "qcom,fastrpc-compute-cb";
+						reg = <2>;
+						iommus = <&apps_smmu 0x28a2 0x0>;
+						dma-coherent;
+					};
+
+					compute-cb@3 {
+						compatible = "qcom,fastrpc-compute-cb";
+						reg = <3>;
+						iommus = <&apps_smmu 0x28a3 0x0>;
+						dma-coherent;
+					};
+				};
 			};
 		};
 

---
base-commit: 1c7cc4904160c6fc6377564140062d68a3dc93a0
change-id: 20260415-monacogdsp-db785de080e5

Best regards,
-- 
Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>

