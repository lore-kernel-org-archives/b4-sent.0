From: EMCP333 <emcp@enser.io>
Date: Sun, 22 Nov 2026 05:13:26 +0000
Subject: [PATCH 3/3] arm64: dts: qcom: sdm845: Add CAMSS interconnects
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-camss-sdm845-icc-v1-3-0671ef770fd0@enser.io>
References: <20261122-b4-camss-sdm845-icc-v1-0-0671ef770fd0@enser.io>
In-Reply-To: <20261122-b4-camss-sdm845-icc-v1-0-0671ef770fd0@enser.io>
To: Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>
Cc: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Robert Foss <rfoss@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 EMCP333 <emcp@enser.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324405; l=1474;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=vetqSv1oRjiySBze/nzqgzM3hC1OiU7h99VJ2Cazd+Q=;
 b=u1AUgAtlHUrvXG+9LsYER0zQrszSscsQaEe3WPlwJOB6wRkfpmH2XAU2iH0Nm2Zcy7u6fWyN6
 EsQWtvDccTTAmdVfWcpPiM2StViJusmu+NjH1EvCnFlcqbXR5xuPWEb
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Give CAMSS its four interconnect paths: the AHB config path, and the two
camnoc HF ports plus the SF port into DDR. Without them CAMSS has no
bandwidth votes of its own, and capture stalls when the display is off.

Tested on a OnePlus 6T: with the display off, 10 of 10 1080p captures of
100 frames complete, with CAMSS voting on both HF ports while streaming.

The code and this changelog were prepared with the help of an AI coding
assistant. The submitter has reviewed both and takes responsibility for
them.

Signed-off-by: EMCP333 <emcp@enser.io>
---
 arch/arm64/boot/dts/qcom/sdm845.dtsi | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845.dtsi b/arch/arm64/boot/dts/qcom/sdm845.dtsi
index 844b840bc5..4710556324 100644
--- a/arch/arm64/boot/dts/qcom/sdm845.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845.dtsi
@@ -4518,6 +4518,16 @@ camss: camss@acb3000 {
 				"vfe_lite_cphy_rx",
 				"vfe_lite_src";
 
+			interconnects = <&gladiator_noc MASTER_APPSS_PROC 0
+					 &config_noc SLAVE_CAMERA_CFG 0>,
+					<&mmss_noc MASTER_CAMNOC_HF0 0 &mem_noc SLAVE_EBI1 0>,
+					<&mmss_noc MASTER_CAMNOC_HF1 0 &mem_noc SLAVE_EBI1 0>,
+					<&mmss_noc MASTER_CAMNOC_SF 0 &mem_noc SLAVE_EBI1 0>;
+			interconnect-names = "ahb",
+					     "hf_0",
+					     "hf_1",
+					     "sf_mnoc";
+
 			iommus = <&apps_smmu 0x0808 0x0>,
 				 <&apps_smmu 0x0810 0x8>,
 				 <&apps_smmu 0x0c08 0x0>,

-- 
2.47.3

