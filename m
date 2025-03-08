From: Xilin Wu <wuxilin123@gmail.com>
Date: Sat, 08 Mar 2025 18:27:51 +0800
Subject: [PATCH] arm64: dts: qcom: sm8250: Fix CPU7 opp table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250308-fix-sm8250-cpufreq-v1-1-8a0226721399@gmail.com>
X-B4-Tracking: v=1; b=H4sIAKYbzGcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDYwML3bTMCt3iXAsgTze5oDStKLVQN8XS1NLEJMksxTDRWAmosaAoFag
 KbGh0bG0tAADDTpNkAAAA
X-Change-ID: 20250308-fix-sm8250-cpufreq-d95944b6d1a3
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>, 
 Thara Gopinath <thara.gopinath@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Xilin Wu <wuxilin123@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741429673; l=1086;
 i=wuxilin123@gmail.com; s=20240424; h=from:subject:message-id;
 bh=D9z9X3e5J8ftwp1wdYD55jK/Ci2H15jjh248DelqCdQ=;
 b=n/PHBwcxilz316ny13BQE1y4sYxBxB+E1XcDU8ZpXttkORZqR1x5/1iFqaQrQGz9NKE1uu/6t
 JxzlZ3NhRU/CLeR1T8p+Sb2zWFU4raSRtCwL0CSPOmL+K9DksCzJMA/
X-Developer-Key: i=wuxilin123@gmail.com; a=ed25519;
 pk=vPnxeJnlD/PfEbyQPZzaay5ezxI/lMrke7qXy31lSM8=
X-Endpoint-Received: by B4 Relay for wuxilin123@gmail.com/20240424 with auth_id=157
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There is a typo in cpu7_opp9. Fix it to get rid of the following
errors.

[    0.198043] cpu cpu7: Voltage update failed freq=1747200
[    0.198052] cpu cpu7: failed to update OPP for freq=1747200

Fixes: 8e0e8016cb79 ("arm64: dts: qcom: sm8250: Add CPU opp tables")
Signed-off-by: Xilin Wu <wuxilin123@gmail.com>
---
 arch/arm64/boot/dts/qcom/sm8250.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8250.dtsi b/arch/arm64/boot/dts/qcom/sm8250.dtsi
index c2937b4d9f180296733b6d7a7a16a088f1f96b76..68613ea7146c8882150f1b81dbc0f3384d3380ba 100644
--- a/arch/arm64/boot/dts/qcom/sm8250.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8250.dtsi
@@ -606,7 +606,7 @@ cpu7_opp8: opp-1632000000 {
 		};
 
 		cpu7_opp9: opp-1747200000 {
-			opp-hz = /bits/ 64 <1708800000>;
+			opp-hz = /bits/ 64 <1747200000>;
 			opp-peak-kBps = <5412000 42393600>;
 		};
 

---
base-commit: 0a2f889128969dab41861b6e40111aa03dc57014
change-id: 20250308-fix-sm8250-cpufreq-d95944b6d1a3

Best regards,
-- 
Xilin Wu <wuxilin123@gmail.com>

