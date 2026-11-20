From: Alexandre Rapaille <arapaille@atlr-engineering.com>
Date: Fri, 20 Nov 2026 09:05:45 +0100
Subject: [PATCH v2 1/3] ARM: dts: qcom: msm8974: Fix WCNSS wifi interrupt
 trigger type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-wcnss-series-v1-v2-1-3fed518decfb@atlr-engineering.com>
References: <20261120-wcnss-series-v1-v2-0-3fed518decfb@atlr-engineering.com>
In-Reply-To: <20261120-wcnss-series-v1-v2-0-3fed518decfb@atlr-engineering.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Luca Weiss <luca@lucaweiss.eu>, Eugene Krasnikov <k.eugene.e@gmail.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, wcn36xx@lists.infradead.org, 
 linux-wireless@vger.kernel.org, 
 Alexandre Rapaille <arapaille@atlr-engineering.com>, stable@vger.kernel.org, 
 Luca Weiss <luca.weiss@fairphone.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795161947; l=1213;
 i=arapaille@atlr-engineering.com; s=20261118; h=from:subject:message-id;
 bh=6q+rKn/BSVI/TfNaPILBloVMSgiRR3L4xqWRbPuJa0Q=;
 b=47cxJFlzFiTDcHUZs6zuR4YijCZcCkSb+iNkKof2I4Z7LlabC4BrCArM3sCmR109I/b5BsTSl
 9S67jRxwE4GAeWqfqP9n0rVGb4lc9tzsmDSVIqJNvoQe9ykzTeUYEoW
X-Developer-Key: i=arapaille@atlr-engineering.com; a=ed25519;
 pk=xskH/sIiNU/aZCeGeBB1TK/AuiG3MXlX0m2wMlbMl08=
X-Endpoint-Received: by B4 Relay for arapaille@atlr-engineering.com/20261118 with auth_id=1560
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

wcn36xx requests tx/rx as IRQF_TRIGGER_HIGH, overriding this edge type, so
the re-probe after a WCNSS restart fails ("type mismatch, failed to map
hwirq-177") and wlan0 never returns. Use level high like other WCNSS SoCs.

Fixes: c7c0edecfba8 ("ARM: dts: msm8974: Introduce the wcnss remoteproc node")
Cc: stable@vger.kernel.org
Reviewed-by: Luca Weiss <luca.weiss@fairphone.com>
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

