From: Nickolay Goppen <setotau@yandex.ru>
Date: Fri, 15 Aug 2025 19:56:51 +0300
Subject: [PATCH 1/2] dt-bindings: clock: gcc-sdm660: Add LPASS/CDSP vote
 clocks/GDSCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250815-gcc-sdm660-vote-clocks-and-gdscs-v1-1-c5a8af040093@yandex.ru>
References: <20250815-gcc-sdm660-vote-clocks-and-gdscs-v1-0-c5a8af040093@yandex.ru>
In-Reply-To: <20250815-gcc-sdm660-vote-clocks-and-gdscs-v1-0-c5a8af040093@yandex.ru>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nickolay Goppen <setotau@yandex.ru>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755277013; l=1259;
 i=setotau@yandex.ru; s=20250815; h=from:subject:message-id;
 bh=AoBDT6b0uXhJ4amBaHImHoToM08z45e1CvJ1xPwygak=;
 b=4W9WG60wNXi8SMokbFHuJMZ+BxikzBsYa8aObjWofHxKtTW/yhkFLY68bceJcXpnKMzenDqFs
 tJepivwLnSdAtDREvFd+YVm+pEbp2iXm/aKSwM670nkQURMxcsu04mi
X-Developer-Key: i=setotau@yandex.ru; a=ed25519;
 pk=Og7YO6LfW+M2QfcJfjaUaXc8oOr5zoK8+4AtX5ICr4o=
X-Endpoint-Received: by B4 Relay for setotau@yandex.ru/20250815 with auth_id=492
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add defines for the missing clocks, which are required to power up the
related remote processors.

Co-developed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Nickolay Goppen <setotau@yandex.ru>
---
 include/dt-bindings/clock/qcom,gcc-sdm660.h | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/include/dt-bindings/clock/qcom,gcc-sdm660.h b/include/dt-bindings/clock/qcom,gcc-sdm660.h
index 74c22f67da213b8e54109785a564d3be756fd6c6..f19018b742f5ce7f96fad99c126934347cececae 100644
--- a/include/dt-bindings/clock/qcom,gcc-sdm660.h
+++ b/include/dt-bindings/clock/qcom,gcc-sdm660.h
@@ -138,10 +138,16 @@
 #define GCC_UFS_UNIPRO_CORE_HW_CTL_CLK		128
 #define GCC_RX0_USB2_CLKREF_CLK			129
 #define GCC_RX1_USB2_CLKREF_CLK			130
+#define GCC_HLOS1_VOTE_LPASS_ADSP_SMMU_CLK	131
+#define GCC_HLOS1_VOTE_TURING_ADSP_SMMU_CLK	132
+#define GCC_HLOS2_VOTE_TURING_ADSP_SMMU_CLK	133
 
 #define PCIE_0_GDSC	0
 #define UFS_GDSC	1
 #define USB_30_GDSC	2
+#define HLOS1_VOTE_TURING_ADSP_GDSC 3
+#define HLOS2_VOTE_TURING_ADSP_GDSC 4
+#define HLOS1_VOTE_LPASS_ADSP_GDSC 5
 
 #define GCC_QUSB2PHY_PRIM_BCR		0
 #define GCC_QUSB2PHY_SEC_BCR		1

-- 
2.50.1

