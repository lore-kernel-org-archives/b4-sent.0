From: Joe Sandom <jsandom@axon.com>
Date: Mon, 20 Apr 2026 10:13:13 +0100
Subject: [PATCH v4 1/5] arm64: dts: qcom: sm8550: add PCIe MHI register
 regions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260420-rb5gen2-dts-v4-1-b461909c2de8@axon.com>
References: <20260420-rb5gen2-dts-v4-0-b461909c2de8@axon.com>
In-Reply-To: <20260420-rb5gen2-dts-v4-0-b461909c2de8@axon.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joe Sandom <jsandom@axon.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776676395; l=1909;
 i=jsandom@axon.com; s=20260319; h=from:subject:message-id;
 bh=Vi+0IvziSsy7bRQBuTCX0upSx5r7zT4LrrG+rgsBuCw=;
 b=0bXjcyd6K6tC1I21oPSPLM85JgG3kJHrUiVSBvb534nzaNWR3ui8LDWnHAcurATFY1PuSE6qk
 lY1A/RXHd4+CY3HN2mSwQS5m5XU8QlxzfgE1X9LZDX0Twb6J3JGPun7
X-Developer-Key: i=jsandom@axon.com; a=ed25519;
 pk=Q/yflwj2WhkgBVTskrS9Vl5oScD0Bp3vTzDi+OxskTo=
X-Endpoint-Received: by B4 Relay for jsandom@axon.com/20260319 with auth_id=687
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the MHI register regions to the pcie0 and pcie1 controller nodes
to expose link power state transition counters (L0s/L1/L1.1/L1.2/L2)
via debugfs. The PCIe host driver uses this region to read the
link_transition_count from the MHI registers.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Joe Sandom <jsandom@axon.com>
---
 arch/arm64/boot/dts/qcom/sm8550.dtsi | 20 ++++++++++++++++----
 1 file changed, 16 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8550.dtsi b/arch/arm64/boot/dts/qcom/sm8550.dtsi
index 912525e9bca6f5e1cbb8887ee0bf9e39650dc4ff..055ca931c04859f3a312eb9921aeb7a8cc676822 100644
--- a/arch/arm64/boot/dts/qcom/sm8550.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8550.dtsi
@@ -1964,8 +1964,14 @@ pcie0: pcie@1c00000 {
 			      <0 0x60000000 0 0xf1d>,
 			      <0 0x60000f20 0 0xa8>,
 			      <0 0x60001000 0 0x1000>,
-			      <0 0x60100000 0 0x100000>;
-			reg-names = "parf", "dbi", "elbi", "atu", "config";
+			      <0 0x60100000 0 0x100000>,
+			      <0 0x01c03000 0 0x1000>;
+			reg-names = "parf",
+				    "dbi",
+				    "elbi",
+				    "atu",
+				    "config",
+				    "mhi";
 			#address-cells = <3>;
 			#size-cells = <2>;
 			ranges = <0x01000000 0x0 0x00000000 0x0 0x60200000 0x0 0x100000>,
@@ -2138,8 +2144,14 @@ pcie1: pcie@1c08000 {
 			      <0x0 0x40000000 0x0 0xf1d>,
 			      <0x0 0x40000f20 0x0 0xa8>,
 			      <0x0 0x40001000 0x0 0x1000>,
-			      <0x0 0x40100000 0x0 0x100000>;
-			reg-names = "parf", "dbi", "elbi", "atu", "config";
+			      <0x0 0x40100000 0x0 0x100000>,
+			      <0x0 0x01c0b000 0x0 0x1000>;
+			reg-names = "parf",
+				    "dbi",
+				    "elbi",
+				    "atu",
+				    "config",
+				    "mhi";
 			#address-cells = <3>;
 			#size-cells = <2>;
 			ranges = <0x01000000 0x0 0x00000000 0x0 0x40200000 0x0 0x100000>,

-- 
2.34.1

