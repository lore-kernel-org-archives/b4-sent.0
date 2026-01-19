From: Biswapriyo Nath <nathbappai@gmail.com>
Date: Mon, 19 Jan 2026 15:13:05 +0000
Subject: [PATCH 3/5] arm64: dts: qcom: sm6125: Add PRNG node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260119-xiaomi-ginkgo-features-v1-3-3c8fae984bda@gmail.com>
References: <20260119-xiaomi-ginkgo-features-v1-0-3c8fae984bda@gmail.com>
In-Reply-To: <20260119-xiaomi-ginkgo-features-v1-0-3c8fae984bda@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Biswapriyo Nath <nathbappai@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768835583; l=817;
 i=nathbappai@gmail.com; s=20260118; h=from:subject:message-id;
 bh=59zkknkV+4u3lCcwhYSFnDAH6nnfGIvbUcRT8uB4bM4=;
 b=o7zG7AUUiabBW6FOM9TqEKHI50UeE9ZUt+r9/PPaEivylVEWpUeB6RW27Xt+GRMjranECLCrn
 Th7/ZLn8kXrBS+EcnG9ohgwTXQp8rWPatuvVBwOyNkHx3SzA/hXtDDt
X-Developer-Key: i=nathbappai@gmail.com; a=ed25519;
 pk=slmb/9yXbet+KTiT3EYLCp0p0MEOYa3EdjUXP+HXfjg=
X-Endpoint-Received: by B4 Relay for nathbappai@gmail.com/20260118 with auth_id=607
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a node for the PRNG to enable hardware accelerated pseudo random
number generation.

Signed-off-by: Biswapriyo Nath <nathbappai@gmail.com>
---
 arch/arm64/boot/dts/qcom/sm6125.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm6125.dtsi b/arch/arm64/boot/dts/qcom/sm6125.dtsi
index 8f2d65543..e60d4d74c 100644
--- a/arch/arm64/boot/dts/qcom/sm6125.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm6125.dtsi
@@ -686,6 +686,13 @@ hsusb_phy1: phy@1613000 {
 			status = "disabled";
 		};
 
+		rng: rng@1b53000 {
+			compatible = "qcom,prng-ee";
+			reg = <0x01b53000 0x1000>;
+			clocks = <&gcc GCC_PRNG_AHB_CLK>;
+			clock-names = "core";
+		};
+
 		spmi_bus: spmi@1c40000 {
 			compatible = "qcom,spmi-pmic-arb";
 			reg = <0x01c40000 0x1100>,

-- 
2.52.0

