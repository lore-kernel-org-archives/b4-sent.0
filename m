From: David Heidelberg <david@ixit.cz>
Date: Thu, 31 Jul 2025 23:02:43 +0200
Subject: [PATCH 1/2] arm64: dts: qcom: sdm845*: Use definition for msm-id
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250731-sdm845-msmid-v1-1-98489ece786e@ixit.cz>
References: <20250731-sdm845-msmid-v1-0-98489ece786e@ixit.cz>
In-Reply-To: <20250731-sdm845-msmid-v1-0-98489ece786e@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4695; i=david@ixit.cz;
 h=from:subject:message-id; bh=teEwdjDRl51VFNsa6G45tTJ9HtVMMKKWiVrCKkMUME4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBoi9nzS5cInR+UQLJgvKhE57WUq3dibLHJK51rR
 oij1DX4zD6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaIvZ8wAKCRBgAj/E00kg
 crbOD/49eVVV6SebGU/Db6NeMXkAnKRa64HYxpMFnq7sC6BUy0yYhn7Y0xuIMBenfLWGZTwJ7Mo
 Bjv6MqY8eku/Xem7SMhkpPaY3ENnfdw/u4cmKG6/GyDa1F+ivGM0ks6bRuirjlDo54dPM4lYLW7
 snuk2bNLjVfp8trNUOkoURiT9qL7yMnes61C9o3J4lesRYtmBQFm975b4jdbZLrLGR3LfWFsVNu
 KW9/YdfTyQgsvEIcsBPNGC3vO4kfyW/gI2mZjeHMQHctQccU246oYkZprQVz9ADgHQzcclc8dGs
 sjD+ECPlcPNiAwckTHptCGu8ohKSkB/GJBxzAcFSxGQKLBWMUBRf2ZB9jd3VqfhaQx6eX9yfJJS
 gSVAxMJwzxKRQXbBwNrUPKbIKwFFLcMB0LUYaCIurCfvN9P+XnrLVpvRFC4V884HeJosZkaZsVb
 fWeWKgZXPeXCLyOymVjwyH4XBixH2K7xqaRa/TJ3Ob//pfsJM99m1I+kt4aULYoxPbKH0BfaUDL
 Hb82+8amTX6sEF8n3s/LAl+GPdzPh7OvmifVHykreH8lQgTW4L+BRGlyVUcuVXSwchU02TxsMOf
 3nXApNVbpVrfYj4KBLdcRrGrzFBI0aNMlEKH8nQlb03fsdfLsOQzbZnxPtQ/khBRBkQzSc7t5JM
 z/CA/qxQr6FFNfA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For all boards it's QCOM_ID_SDM845 except Dragonboard, where it's
QCOM_ID_SDA845.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-db845c.dts                   | 2 +-
 arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts        | 2 +-
 arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts           | 2 +-
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts            | 2 +-
 arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi        | 2 +-
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 2 +-
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts           | 2 +-
 7 files changed, 7 insertions(+), 7 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-db845c.dts b/arch/arm64/boot/dts/qcom/sdm845-db845c.dts
index b5c63fa0365d28fdc4a61dfe67ab6a184e748473..fa997a568f46ff54aa5ea60530c33f8bf6361ade 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-db845c.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-db845c.dts
@@ -18,7 +18,7 @@
 / {
 	model = "Thundercomm Dragonboard 845c";
 	compatible = "thundercomm,db845c", "qcom,sdm845";
-	qcom,msm-id = <341 0x20001>;
+	qcom,msm-id = <QCOM_ID_SDA845 0x20001>;
 	qcom,board-id = <8 0>;
 
 	aliases {
diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts b/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
index 4005e04d998a40d25a64d652a526bf93efc20332..474759ab61043005fcabadb5c061bbd2eccb2447 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
@@ -11,7 +11,7 @@ / {
 	model = "OnePlus 6";
 	compatible = "oneplus,enchilada", "qcom,sdm845";
 	chassis-type = "handset";
-	qcom,msm-id = <0x141 0x20001>;
+	qcom,msm-id = <QCOM_ID_SDM845 0x20001>;
 	qcom,board-id = <8 0 17819 22>;
 
 	battery: battery {
diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
index 9471ada0d6ad8bd44cc58a6efa07f7eb27921af9..a0affaa246fea5514a00b6c37edb30c6dceb2c59 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
@@ -11,7 +11,7 @@ / {
 	model = "OnePlus 6T";
 	compatible = "oneplus,fajita", "qcom,sdm845";
 	chassis-type = "handset";
-	qcom,msm-id = <0x141 0x20001>;
+	qcom,msm-id = <QCOM_ID_SDM845 0x20001>;
 	qcom,board-id = <8 0 18801 41>;
 
 	battery: battery {
diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index 2cf7b5e1243caca6a6a0b0beebf52d5f354fe56f..f1dcf69238d6682130238e775ca13e317f53052b 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -17,7 +17,7 @@
 / {
 	model = "SHIFT SHIFT6mq";
 	compatible = "shift,axolotl", "qcom,sdm845";
-	qcom,msm-id = <321 0x20001>;
+	qcom,msm-id = <QCOM_ID_SDM845 0x20001>;
 	qcom,board-id = <11 0>;
 
 	aliases {
diff --git a/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi b/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi
index a3a304e1ac8737ea2330bfe0ba92008e9fbba6af..8f1526fffd2a2ec10f880053cdf3d613b92ab4d9 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama.dtsi
@@ -12,7 +12,7 @@
 #include "pmi8998.dtsi"
 
 / {
-	qcom,msm-id = <321 0x20001>; /* SDM845 v2.1 */
+	qcom,msm-id = <QCOM_ID_SDM845 0x20001>; /* SDM845 v2.1 */
 	qcom,board-id = <8 0>;
 
 	aliases {
diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 7810b0ce7591ecc29e62116a859dcc6b93185b0c..3e1cea965c83d6757e586e36c469d1cf4a603304 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -32,7 +32,7 @@ / {
 
 	/* required for bootloader to select correct board */
 	qcom,board-id = <69 0>;
-	qcom,msm-id = <321 0x20001>;
+	qcom,msm-id = <QCOM_ID_SDM845 0x20001>;
 
 	aliases {
 		serial1 = &uart6;
diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts
index 63cf879a7a297e161c57ba5256d52c9d6cfe9767..ebbd550130137504db75c9337f2867b462cfe888 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts
@@ -38,7 +38,7 @@ / {
 	chassis-type = "handset";
 
 	/* required for bootloader to select correct board */
-	qcom,msm-id = <0x141 0x20001>;
+	qcom,msm-id = <QCOM_ID_SDM845 0x20001>;
 	qcom,board-id = <0x2a 0x0>;
 
 	aliases {

-- 
2.50.1

