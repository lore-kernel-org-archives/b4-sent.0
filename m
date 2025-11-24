From: David Heidelberg <david@ixit.cz>
Date: Mon, 24 Nov 2025 22:53:36 +0100
Subject: [PATCH RFC 3/8] arm64: dts: qcom: pmi8998: Add fuel gauge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251124-pmi8998_fuel_gauge-v1-3-dd3791f61478@ixit.cz>
References: <20251124-pmi8998_fuel_gauge-v1-0-dd3791f61478@ixit.cz>
In-Reply-To: <20251124-pmi8998_fuel_gauge-v1-0-dd3791f61478@ixit.cz>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Casey Connolly <casey@connolly.tech>, Joel Selvaraj <foss@joelselvaraj.com>, 
 Yassine Oudjana <y.oudjana@protonmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 =?utf-8?q?Barnab=C3=A1s_Cz=C3=A9m=C3=A1n?= <barnabas.czeman@mainlining.org>, 
 Richard Acayan <mailingradian@gmail.com>, 
 Alexey Minnekhanov <alexeymin@postmarketos.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=802; i=david@ixit.cz;
 h=from:subject:message-id; bh=3NH+XDRf7boZ2ZmNb3Bl1vms6aKp3xOCdIZF3YQ+0F0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpJNPg55+d8XT532qjbGQqchmayDZA+eMWof6+X
 UhVu69VKuaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaSTT4AAKCRBgAj/E00kg
 cmIkD/9vn0ydEfm5TSte0rhonIcjJ75d0IPSoApYAqj7a0JXnks5F8oeRsqXevA4dWjzJTEtsr0
 8TgfpB+I0TaPlku/gG+ygcXN0KZ8C7BCKChSQFeh2pFuVxjNgwCmdGUvz+Yl8+lGYO8kb8jooa5
 ZzNU50kl8IaOvj/xv0U6urmvutjMPugV7x+r7XpCBO3joSPKWSVOvBx6YBJhZiS1Yp2Ywxupk+B
 sCRSpA82oUlEnQxrKDNMSXXgsTs6j6u69slgRAjQJkSRKJdI0dpEEGhe/wuIYfQhQSujLCENPb5
 fdELrOegE8b2Gd+tS/rIItpdZRTSVlDWFl+fGRtAMc+Z+IrJAEDAqDjIIM6Gl9fL/lsVwP7YqB3
 rVmgagRgM4sY0aBl0zLkYYmsywAFPezUSk3BeKyEctfWX3y61GbvxdezPzBOon2+3VRXpBa5h0y
 N4TN4BNTXnWMzWczO4SVnDxUUiYAObJzBin7k12eFsgLWN3POw90lEkcg3ef7v+0d0KJnUkSS8O
 bNnkdfwcJQX1lZ9gQymokImssKfZTiHCoNfIkXZVy9e/44aiJROOgMNZ28KSKtJYxzd9LEMefTS
 RCBEJAk439MOb6MD3ha7wGfKOwuJJUMaTg8siYfipF3QOBAY2dGM06QK+XOsKp/PCYnW7QMgFWM
 aRBL+N19XB5s59w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

Introduce the fuel gauge node for pmi8998.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/pmi8998.dtsi | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/pmi8998.dtsi b/arch/arm64/boot/dts/qcom/pmi8998.dtsi
index cd3f0790fd420..ab3bc66502657 100644
--- a/arch/arm64/boot/dts/qcom/pmi8998.dtsi
+++ b/arch/arm64/boot/dts/qcom/pmi8998.dtsi
@@ -44,6 +44,17 @@ pmi8998_rradc: adc@4500 {
 			reg = <0x4500>;
 			#io-channel-cells = <1>;
 		};
+
+		pmi8998_fg: fuel-gauge@4000 {
+			compatible = "qcom,pmi8998-fg";
+			reg = <0x4000>;
+
+			interrupts = <0x2 0x40 0x3 IRQ_TYPE_EDGE_RISING>;
+			interrupt-names = "soc-delta";
+
+			status = "disabled";
+		};
+
 	};
 
 	pmi8998_lsid1: pmic@3 {

-- 
2.51.0

