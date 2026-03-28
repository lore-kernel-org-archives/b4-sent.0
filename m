From: =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>
Date: Sat, 28 Mar 2026 23:58:42 +0100
Subject: [PATCH v2 3/3] arm64: dts: qcom: sdm670-google-common: enable
 debug uart
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260328-pabloyoyoista-debug-uart-on-rdacayan-next-v2-3-53abd9db8f0a@postmarketos.org>
References: <20260328-pabloyoyoista-debug-uart-on-rdacayan-next-v2-0-53abd9db8f0a@postmarketos.org>
In-Reply-To: <20260328-pabloyoyoista-debug-uart-on-rdacayan-next-v2-0-53abd9db8f0a@postmarketos.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Richard Acayan <mailingradian@gmail.com>, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1252;
 i=pabloyoyoista@postmarketos.org; h=from:subject:message-id;
 bh=VHLwmsN4P772ow9/6v2H4OaVcZPfDAQIcntWKTFdTMc=;
 b=owEBbQKS/ZANAwAKAXo0JWX/Y195AcsmYgBpyF0jwo9ChontKOekSZeLAjjzU+r6p2WR0QcFi
 vA/A5w5wPSJAjMEAAEKAB0WIQS9CheUSi6o/ykTCaJ6NCVl/2NfeQUCachdIwAKCRB6NCVl/2Nf
 ebVsD/0QRLuK8Ucw1STYeq/wT+8NLzuboHnCm7ZTq9pm1guBCDN1wiLK0waovOjOjCaHizTN70L
 qE5wX1FmsU0RiBNz4HYmRh2NYi+CZqGQwbCdcKGn6LWa/TrIDuffWf4W1W8bZ0PbpivJKaVw2uZ
 mZad7ViAZ243rQL2aJGI3571o6vYJkrK9kf5vg9lgdSfuyYtfzdQYmIMSK8fzz5ciHL3iaG5i//
 G7Zhl6L1jAaasLTRyjjPuJId/DzOQo9OU4c8fx2cYUOto2YM+q9D02m3QUcNxzCg0PQOo10hAoO
 Y6CTBswwUm/qsWQ/uDAsDAdiHEI2vSNGhpQouHPoGEFHMeT4nJh2uIoD7zVWhg3LxQzvCbKqNwr
 Wb1cnCnk7Equ8cqPTT2MPKnPlm3X8JldXltsIH0CJDKCIFbTQOz7N/Qc2js6O1QnKgzNH3EvhS4
 dr0IldQetl1S1PskjGv2RSVo5TmRZlNUyeoN7AvLDV/guSaEiiIomXZ863kNjVVjGqdDLUC1elw
 QoaCWj51oRphKBEs/Ny3lCz5em+J7jKEiIwZSGcYSwezZAx/fgdS65EJKSME90uL/k0SPUXkJOA
 Hr/MiSAuKuNjR8U9h+mZrUR4SX9K6LCQLQ4Q+L9orkIerLy05lLR8vIGPpfhmsQZSy3YC95N4WU
 DFFg0fDnr6AtDEA==
X-Developer-Key: i=pabloyoyoista@postmarketos.org; a=openpgp;
 fpr=BD0A17944A2EA8FF291309A27A342565FF635F79
X-Endpoint-Received: by B4 Relay for pabloyoyoista@postmarketos.org/default with auth_id=698
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This has been tested on the Pixel 3a with USB Cereal board

Depends on
https://lore.kernel.org/all/20260310002606.16413-5-mailingradian@gmail.com/

Signed-off-by: Pablo Correa Gómez <pabloyoyoista@postmarketos.org>
---
 arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi | 18 +++++++++++++++++-
 1 file changed, 17 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
index 32dce1cfdf6f..e8bd5f3861e4 100644
--- a/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
@@ -27,7 +27,9 @@
 /delete-node/ &gpu_mem;
 
 / {
-	aliases { };
+	aliases {
+		serial0 = &uart12;
+	};
 
 	battery: battery {
 		compatible = "simple-battery";
@@ -683,6 +685,16 @@ &qupv3_id_1 {
 	status = "okay";
 };
 
+&qup_uart12_rx {
+	drive-strength = <2>;
+	bias-pull-up;
+};
+
+&qup_uart12_tx {
+	drive-strength = <2>;
+	bias-disable;
+};
+
 &sdhc_1 {
 	supports-cqe;
 	mmc-hs200-1_8v;
@@ -749,6 +761,10 @@ ts-switch-pins {
 	};
 };
 
+&uart12 {
+	status = "okay";
+};
+
 &usb_1_hsphy {
 	vdd-supply = <&vreg_l1b_0p925>;
 	vdda-pll-supply = <&vreg_l10a_1p8>;

-- 
2.53.0

