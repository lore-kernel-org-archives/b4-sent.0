From: George Moussalem <george.moussalem@outlook.com>
Date: Mon, 21 Jul 2025 10:30:46 +0400
Subject: [PATCH] arm64: dts: qcom: ipq5018: add PRNG node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250721-ipq5018-prng-v1-1-474310e0575d@outlook.com>
X-B4-Tracking: v=1; b=H4sIAJbefWgC/x3MTQqAIBBA4avIrBP8wbCuEi0sJ5uNmUIE4t2Tl
 t/ivQoFM2GBmVXI+FChK3bIgcF+uhiQk+8GJZQRRmlO6TZCWp5yDFwa3DSOzk/CQk9SxoPef7e
 srX1lllBpXgAAAA==
X-Change-ID: 20250523-ipq5018-prng-15eb3e6ad908
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753079455; l=1074;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=uB/HCEZYInOL5Lcj4Z1RVwpnu7EOA4IaF8qdmjn0/5w=;
 b=yuX4ZHzn+VlOybcdKhAIbS9y3D/tRAQcQ1GI5MBSUTUQOkScNyTSTFviXhtugb9ZZN6pEhiKd
 CXw1aB+h3Y7AYtJg9dLlHmGRkVpnHGYwSPrtMmsImIFeTpArRGb9g6f
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

PRNG inside of IPQ5018 is already supported, so let's add the node for it.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index 9ce73682e4ae7cde90f151dfcd41a5201ced2aa6..9efa831e7d4e64326dc9bbdbab3541c486ad3b9c 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -301,6 +301,14 @@ tsens_s4_p2: s4-p2@254 {
 			};
 		};
 
+		prng: rng@e3000 {
+			compatible = "qcom,prng-ee";
+			reg = <0x000e3000 0x1000>;
+			clocks = <&gcc GCC_PRNG_AHB_CLK>;
+			clock-names = "core";
+			status = "disabled";
+		};
+
 		tsens: thermal-sensor@4a9000 {
 			compatible = "qcom,ipq5018-tsens", "qcom,tsens-v1";
 			reg = <0x004a9000 0x1000>,

---
base-commit: 1b0324d3b8375fcfaf80789092347a52529059eb
change-id: 20250523-ipq5018-prng-15eb3e6ad908

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

