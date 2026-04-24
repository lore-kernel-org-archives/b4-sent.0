From: Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
Date: Fri, 24 Apr 2026 15:40:22 +0530
Subject: [PATCH v3] arm64: dts: qcom: talos: Add memory-region for audio PD
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260424-talosaudio-v3-1-9e2ad5d78a2e@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIAI5B62kC/23MQQ6DIBCF4auYWRcjoBa76j2aLgaBSqLSgpI2x
 rsXXbWJm0n+Sd63QNDe6gCXbAGvow3WjSn4KYO2w/GhiVWpgRWsLkoqyIS9Czgr64gUujVCNkg
 lhzR4em3se8du99SdDZPzn92OdPseMpESSipRoWTMIJry6kLIXzP2rRuGPB3YtMh+heZPYEngy
 GWlVH1W6khY1/ULhq2KtO0AAAA=
X-Change-ID: 20260418-talosaudio-b8ecf8b9a1b3
To: konrad.dybcio@oss.qualcomm.com, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, quic_bkumar@quicinc.com, 
 quic_chennak@quicinc.com, dmitry.baryshkov@oss.qualcomm.com
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777025424; l=2086;
 i=ekansh.gupta@oss.qualcomm.com; s=20260223; h=from:subject:message-id;
 bh=BMQhN87MOW3Bin4ZVjUzWQxUOWRhdvvp1i+NLcdrruM=;
 b=AZSk/nnoNK1O+zaH16pGtagQAZwKk0vhXw+p0ekjNHu6e5j9UK9UM1bQTzBZEP1WF31mtDx2f
 z754EqRI2xlBOMYhrWaV+hAfPDlB+kOOPR+Gg2S+qurnJEdSh7cuAbD
X-Developer-Key: i=ekansh.gupta@oss.qualcomm.com; a=ed25519;
 pk=n0SepARizye+pYjhjg1RA5J+Nq4+IJbyRcBybU+/ERQ=
X-Endpoint-Received: by B4 Relay for ekansh.gupta@oss.qualcomm.com/20260223 with auth_id=647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reserve memory region for audio PD dynamic loading and remote heap
requirements. Add the required VMID list for memory ownership
transfers.

Signed-off-by: Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
---
Changes in v3:
- Use shared-dma-pool representation for adsp_rpc_remote_heap_mem.
- Link to v2: https://lore.kernel.org/r/20260419-talosaudio-v2-1-3a3b5dd67dd4@oss.qualcomm.com

Changes in v2:
- Fixed VMID list alignment.
- Link to v1: https://lore.kernel.org/r/20260418-talosaudio-v1-1-585ab22faaf4@oss.qualcomm.com
---
 arch/arm64/boot/dts/qcom/talos.dtsi | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/talos.dtsi b/arch/arm64/boot/dts/qcom/talos.dtsi
index ff5afbfce2a4..c230d46616ea 100644
--- a/arch/arm64/boot/dts/qcom/talos.dtsi
+++ b/arch/arm64/boot/dts/qcom/talos.dtsi
@@ -11,6 +11,7 @@
 #include <dt-bindings/clock/qcom,qcs615-videocc.h>
 #include <dt-bindings/clock/qcom,rpmh.h>
 #include <dt-bindings/dma/qcom-gpi.h>
+#include <dt-bindings/firmware/qcom,scm.h>
 #include <dt-bindings/interconnect/qcom,icc.h>
 #include <dt-bindings/interconnect/qcom,osm-l3.h>
 #include <dt-bindings/interconnect/qcom,qcs615-rpmh.h>
@@ -657,6 +658,14 @@ pil_gpu_mem: pil-gpu@97715000 {
 			reg = <0x0 0x97715000 0x0 0x2000>;
 			no-map;
 		};
+
+		adsp_rpc_remote_heap_mem: adsp-rpc-remote-heap {
+			compatible = "shared-dma-pool";
+			alloc-ranges = <0x0 0x80000000 0x0 0x80000000>;
+			reusable;
+			alignment = <0x0 0x400000>;
+			size = <0x0 0x800000>;
+		};
 	};
 
 	soc: soc@0 {
@@ -5100,6 +5109,9 @@ fastrpc {
 					compatible = "qcom,fastrpc";
 					qcom,glink-channels = "fastrpcglink-apps-dsp";
 					label = "adsp";
+					memory-region = <&adsp_rpc_remote_heap_mem>;
+					qcom,vmids = <QCOM_SCM_VMID_LPASS
+						      QCOM_SCM_VMID_ADSP_HEAP>;
 					#address-cells = <1>;
 					#size-cells = <0>;
 

---
base-commit: c7275b05bc428c7373d97aa2da02d3a7fa6b9f66
change-id: 20260418-talosaudio-b8ecf8b9a1b3

Best regards,
-- 
Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>

