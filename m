From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Thu, 10 Apr 2025 12:07:30 +0200
Subject: [PATCH v2 3/3] arm64: dts: qcom: x1e80100-hp-x14: amend order of
 nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250410-hp-x14-v2-3-d36414704a0a@oldschoolsolutions.biz>
References: <20250410-hp-x14-v2-0-d36414704a0a@oldschoolsolutions.biz>
In-Reply-To: <20250410-hp-x14-v2-0-d36414704a0a@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744279681; l=1222;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=bnPuoslWPgNZvAQ9/Qrw/txzq3JvrErhTj3TzDMEntY=;
 b=kuwVoeZ26n8+Ah4fxp7+P2goDpgr5mMwxtP/V9pTNTnYdmjwxB0NyQdgwbv/++Zb91kI/F6tI
 ShzMvfYqHCAAgX7AM5t0hkPNNahYYrXtAbPhIONVp0IA821IFO/uMGW
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

amend the order of pmk8550_* nodes afte pmc8380_*

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 .../boot/dts/qcom/x1e80100-hp-omnibook-x14.dts     | 22 +++++++++++-----------
 1 file changed, 11 insertions(+), 11 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/x1e80100-hp-omnibook-x14.dts b/arch/arm64/boot/dts/qcom/x1e80100-hp-omnibook-x14.dts
index 6c0e56168eaf133b9500c32b98821fa1fc3e7a2d..b492901f2d8c610e955c95aea60eb6c3d80d4f65 100644
--- a/arch/arm64/boot/dts/qcom/x1e80100-hp-omnibook-x14.dts
+++ b/arch/arm64/boot/dts/qcom/x1e80100-hp-omnibook-x14.dts
@@ -1196,17 +1196,6 @@ edp_bl_reg_en: edp-bl-reg-en-state {
 
 };
 
-&pmk8550_gpios {
-	edp_bl_pwm: edp-bl-pwm-state {
-		pins = "gpio5";
-		function = "func3";
-	};
-};
-
-&pmk8550_pwm {
-	status = "okay";
-};
-
 &pmc8380_5_gpios {
 	usb0_pwr_1p15_reg_en: usb0-pwr-1p15-reg-en-state {
 		pins = "gpio8";
@@ -1218,6 +1207,17 @@ usb0_pwr_1p15_reg_en: usb0-pwr-1p15-reg-en-state {
 	};
 };
 
+&pmk8550_gpios {
+	edp_bl_pwm: edp-bl-pwm-state {
+		pins = "gpio5";
+		function = "func3";
+	};
+};
+
+&pmk8550_pwm {
+	status = "okay";
+};
+
 &qupv3_0 {
 	status = "okay";
 };

-- 
2.48.1

