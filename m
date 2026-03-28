From: =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>
Date: Sat, 28 Mar 2026 23:49:16 +0100
Subject: [PATCH 3/3] arm64: dts: qcom: sdm670-google-common: enabled debug
 uart
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260328-pabloyoyoista-debug-uart-on-rdacayan-next-v1-3-0babf584acdb@postmarketos.org>
References: <20260328-pabloyoyoista-debug-uart-on-rdacayan-next-v1-0-0babf584acdb@postmarketos.org>
In-Reply-To: <20260328-pabloyoyoista-debug-uart-on-rdacayan-next-v1-0-0babf584acdb@postmarketos.org>
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
 b=owEBbQKS/ZANAwAKAXo0JWX/Y195AcsmYgBpyFrr6yxaCAZfF6nwPfGCllYi9Uwpe8Sh+kyUo
 03w8ZPL/i6JAjMEAAEKAB0WIQS9CheUSi6o/ykTCaJ6NCVl/2NfeQUCacha6wAKCRB6NCVl/2Nf
 eYD4D/456HqecDssmjPOnvmNqZg4/wivHZJPn0rYiFSBup5h9cqKUEjaG96XACKW8V4Dx0O+EQ0
 77HTYNxLV/FUavEB1a43O5visnvFlCJPyE7QlQXXXx0iVB8VeTxb/DAf5wpqHpYaBch/6wHA8Oe
 TVuhoMbFTB/BPl2k3d4NFVtvjpOAajIALBDWoKm3BKNb1shE7ycZjGMQC5bGz8nV9tiFkL4OKBD
 IIJ7CnaSAhtmuhhmx/USxeIO7nl/HJOXjNunEPTU/lLkKWelyqz2vo7wgPSS20GMdwv9ba2FhGt
 NiUhD6f9W5/Imj8tgOFdpIsn6lsk/9JYyFnBWO67nRUk0a3TQ9bCtR+s7DwDdzzqNmPV7peGpEE
 tVE8Ag9HySn3gfSEDqDukzYE+Q+Pq0HzCCrirzocRjjsC8w/1h88nlXRngajpSmaBOCFPXhhhJK
 CYhYTStCtMXS/2v+c2IRVHmmAJkZeKEoO0Pp7Yp0lCHdSmy6nZOE1ng/NgBGUvu9e1ivZTCrwU3
 z7SIeAfOEx4RSaaEliNRNw+Pq1QgjPJR2zd0rL5LinBQXOMqJ5A9CrcIyqttbQEhBIaYApVEnNk
 BTsWshEXSM35BI1xBleJuvWU3cXKO8h9GxEsjw0r7gf6SJT9PEt3Pldk82ohP9y5Fa7+ov17hBS
 LNsKUYn/XKfxXxw==
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

