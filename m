From: Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
Date: Sat, 18 Apr 2026 11:38:15 +0530
Subject: [PATCH] arm64: dts: qcom: hamoa: add audio PD remote heap region
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260418-hamoaaudio-v1-1-a92866f744a6@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIAM4f42kC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDE0ML3YzE3PzExNKUzHxdS0OTRDNjM8tES5MUJaCGgqLUtMwKsGHRsbW
 1AItMNWVcAAAA
X-Change-ID: 20260418-hamoaaudio-914a6369a94d
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Bharath Kumar <quic_bkumar@quicinc.com>, 
 Chenna Kesava Raju <quic_chennak@quicinc.com>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776492495; l=1437;
 i=ekansh.gupta@oss.qualcomm.com; s=20260223; h=from:subject:message-id;
 bh=t8xKrGP5JlZ29QeT2aH4/4HxK5N4poIHW/rEsjbHC34=;
 b=6Tn3gQGGE69Mma0ktj82/PQxI2QTsMpvMWqD7NMGD2MmU5gb9Qe121YjbAuABdE6d0xFg6glt
 zoX38nXR2fOCwfvIx6cnpfG5Y74GkSy3YkR8BnNosOa1ajACeyfMLCu
X-Developer-Key: i=ekansh.gupta@oss.qualcomm.com; a=ed25519;
 pk=n0SepARizye+pYjhjg1RA5J+Nq4+IJbyRcBybU+/ERQ=
X-Endpoint-Received: by B4 Relay for ekansh.gupta@oss.qualcomm.com/20260223 with auth_id=647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reference the reserved memory region for audio PD dynamic loading
and remote heap requirements. Add the required VMID list for memory
ownership transfers.

Signed-off-by: Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/hamoa.dtsi | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/hamoa.dtsi b/arch/arm64/boot/dts/qcom/hamoa.dtsi
index 051dee076416..3a0717d49990 100644
--- a/arch/arm64/boot/dts/qcom/hamoa.dtsi
+++ b/arch/arm64/boot/dts/qcom/hamoa.dtsi
@@ -11,6 +11,7 @@
 #include <dt-bindings/clock/qcom,x1e80100-gpucc.h>
 #include <dt-bindings/clock/qcom,x1e80100-tcsr.h>
 #include <dt-bindings/dma/qcom-gpi.h>
+#include <dt-bindings/firmware/qcom,scm.h>
 #include <dt-bindings/interconnect/qcom,icc.h>
 #include <dt-bindings/interconnect/qcom,x1e80100-rpmh.h>
 #include <dt-bindings/interrupt-controller/arm-gic.h>
@@ -4371,6 +4372,9 @@ fastrpc {
 					compatible = "qcom,fastrpc";
 					qcom,glink-channels = "fastrpcglink-apps-dsp";
 					label = "adsp";
+					memory-region = <&adsp_rpc_remote_heap_mem>;
+					qcom,vmids = <QCOM_SCM_VMID_LPASS
+						      QCOM_SCM_VMID_ADSP_HEAP>;
 					qcom,non-secure-domain;
 					#address-cells = <1>;
 					#size-cells = <0>;

---
base-commit: c7275b05bc428c7373d97aa2da02d3a7fa6b9f66
change-id: 20260418-hamoaaudio-914a6369a94d

Best regards,
-- 
Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>

