From: Joe Sandom <jsandom@axon.com>
Date: Tue, 07 Apr 2026 16:46:44 +0100
Subject: [PATCH v2 1/5] arm64: dts: qcom: sm8550: add PCIe MHI register
 regions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260407-rb5gen2-dts-v2-1-d0c7f447ee73@axon.com>
References: <20260407-rb5gen2-dts-v2-0-d0c7f447ee73@axon.com>
In-Reply-To: <20260407-rb5gen2-dts-v2-0-d0c7f447ee73@axon.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joe Sandom <jsandom@axon.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775576820; l=1736;
 i=jsandom@axon.com; s=20260319; h=from:subject:message-id;
 bh=zqeIqGY0ruAR+kg3tcV4DAYxkIVC1JYpXX7imW3l6zM=;
 b=QB6NgBqN5aVf/a8PYwZobdMpjC7FGvZVQpFZneYFNDbKbNQV+3etFGaAVxyLG4bzbe8J4n05B
 USova4LG1WWA8zzinhP6vnq8oIhXS2VuFbdLVnv5FVV0WJ4rguIi52h
X-Developer-Key: i=jsandom@axon.com; a=ed25519;
 pk=Q/yflwj2WhkgBVTskrS9Vl5oScD0Bp3vTzDi+OxskTo=
X-Endpoint-Received: by B4 Relay for jsandom@axon.com/20260319 with auth_id=687
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the MHI register regions to the pcie0 and pcie1 controller nodes
so that the MHI bus layer can access controller registers directly.

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

