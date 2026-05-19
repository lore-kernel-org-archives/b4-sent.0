From: George Moussalem <george.moussalem@outlook.com>
Date: Tue, 19 May 2026 09:56:06 +0400
Subject: [PATCH] arm64: dts: qcom: ipq5018: Correct CMN PLL reference clock
 rate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-ipq5018-cmn-pll-rate-fix-v1-1-3c83a173c27f@outlook.com>
X-B4-Tracking: v=1; b=H4sIAHX7C2oC/yXM0Q5EMBCF4VeRuTZJS9jaVxEXVcPOxnarRSTi3
 RWX30nOv0MgzxTgnezgaeXAfxsh0wTMR9uBkLtoyERWikJWyG4qhFRofhbdOKLXM2HPG+ZK6fx
 VtT1JAfHuPMX5TtfN47C0XzLz1YPjOAHWP1SbfAAAAA==
X-Change-ID: 20260519-ipq5018-cmn-pll-rate-fix-388a379bfe10
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Luo Jie <jie.luo@oss.qualcomm.com>, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779170166; l=1302;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=U/e+sHep+NDUEPBbykGQ7tknr4hOCzaANIv9del2SXY=;
 b=ylGeyNJlRJtXoZrDQ8onYc6fVQ67HU+OqwbJXah/CZ/VC+tBBGi/OrRlMD7X9btf2HSWoVuQX
 f0Wfwsw/6Y+BLbMG2hqRoXedwxRGe4QJfWSM7p5xJUYY4YUcRSitaaG
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The correct CMN PLL reference clock rate for IPQ5018 is 4.8 GHz.

The CMN PLL driver did not account for the ref clock divider which is 2
for IPQ5018. Therefore, the computed rate was twice the actual output.

With the driver now accounting for the CMN PLL reference clock
divider (commit: 88c543fff756), set the correct reference clock rate.

Fixes: c006b249c544 ("arm64: dts: ipq5018: Add CMN PLL node")

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index 6f8004a22a1f..f6cf2cca44eb 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -256,7 +256,7 @@ cmn_pll: clock-controller@9b000 {
 				      "sys";
 			#clock-cells = <1>;
 			assigned-clocks = <&cmn_pll IPQ5018_CMN_PLL_CLK>;
-			assigned-clock-rates-u64 = /bits/ 64 <9600000000>;
+			assigned-clock-rates-u64 = /bits/ 64 <4800000000>;
 		};
 
 		qfprom: qfprom@a0000 {

---
base-commit: 80dd246accce631c328ea43294e53b2b2dd2aa32
change-id: 20260519-ipq5018-cmn-pll-rate-fix-388a379bfe10

Best regards,
--  
George Moussalem <george.moussalem@outlook.com>

