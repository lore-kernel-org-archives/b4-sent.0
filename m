From: Alexandre Rapaille <arapaille@atlr-engineering.com>
Date: Wed, 18 Nov 2026 15:57:59 +0100
Subject: [PATCH 1/3] ARM: dts: qcom: msm8974: Fix WCNSS wifi interrupt
 trigger type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-wcnss-series-v1-v1-1-a64d82e151bf@atlr-engineering.com>
References: <20261118-wcnss-series-v1-v1-0-a64d82e151bf@atlr-engineering.com>
In-Reply-To: <20261118-wcnss-series-v1-v1-0-a64d82e151bf@atlr-engineering.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Luca Weiss <luca@lucaweiss.eu>, Eugene Krasnikov <k.eugene.e@gmail.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, wcn36xx@lists.infradead.org, 
 linux-wireless@vger.kernel.org, 
 Alexandre Rapaille <arapaille@atlr-engineering.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795013892; l=1133;
 i=arapaille@atlr-engineering.com; s=20261118; h=from:subject:message-id;
 bh=MaQVT98wnph2fsIYy92R7mv28iUAmYxaqVosGLAJYjY=;
 b=qJE8Yy6dz5M3QuwzvE52yFw8Ya1IOwtAB1TFs/BE9pSEEzRQZytMHkzl8FBRWBFWVQhUPR0lE
 8r3KPFaElCSA2TRjFC1+uA670WVR9cDIuib+6Au2Wvrud/apnZ1DFla
X-Developer-Key: i=arapaille@atlr-engineering.com; a=ed25519;
 pk=xskH/sIiNU/aZCeGeBB1TK/AuiG3MXlX0m2wMlbMl08=
X-Endpoint-Received: by B4 Relay for arapaille@atlr-engineering.com/20261118 with auth_id=1560
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

wcn36xx requests tx/rx as IRQF_TRIGGER_HIGH, overriding this edge type, so
the re-probe after a WCNSS restart fails ("type mismatch, failed to map
hwirq-177") and wlan0 never returns. Use level high like other WCNSS SoCs.

Fixes: c7c0edecfba8 ("ARM: dts: msm8974: Introduce the wcnss remoteproc node")
Signed-off-by: Alexandre Rapaille <arapaille@atlr-engineering.com>
---
 arch/arm/boot/dts/qcom/qcom-msm8974.dtsi | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8974.dtsi b/arch/arm/boot/dts/qcom/qcom-msm8974.dtsi
index f300de74c4..b9666feb8b 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8974.dtsi
+++ b/arch/arm/boot/dts/qcom/qcom-msm8974.dtsi
@@ -814,8 +814,8 @@ bluetooth {
 					wifi {
 						compatible = "qcom,wcnss-wlan";
 
-						interrupts = <GIC_SPI 145 IRQ_TYPE_EDGE_RISING>,
-							     <GIC_SPI 146 IRQ_TYPE_EDGE_RISING>;
+						interrupts = <GIC_SPI 145 IRQ_TYPE_LEVEL_HIGH>,
+							     <GIC_SPI 146 IRQ_TYPE_LEVEL_HIGH>;
 						interrupt-names = "tx", "rx";
 
 						qcom,smem-states = <&apps_smsm 10>, <&apps_smsm 9>;

-- 
2.43.0

