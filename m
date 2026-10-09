From: Fabricio Akio <fabricioakio@gmail.com>
Date: Fri, 09 Oct 2026 17:49:30 -0300
Subject: [PATCH] arm64: dts: qcom: sdm630: Add interconnect paths to the
 BLSP I2C and SPI controllers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-sdm630-blsp-paths-v1-1-6a86ba193e8e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrB0YE1TsVYoLE0cdaW3IaCmId
 zfW5Vv8v4NyFFZ4ZDtE/orKZ0ko8gz81C0jo/TJYMhUBVGD2r8rS+heGjB066TonC3r0lsiayB
 1IfIgv//z2d7Wzc3s12sEx3EC1O244HUAAAA=
X-Change-ID: 20261009-sdm630-blsp-paths-bb3575c30032
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Abel Vesa <abelvesa@kernel.org>, 
 Alexey Minnekhanov <alexeymin@postmarketos.org>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Martin Botka <martin.botka@somainline.org>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791578991; l=4078;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=98XWULvFlrGsaywNs2+4EVpHMKg2rfljbJphpWqR6lo=;
 b=Ism90WRgddmgiwZX1UP/7b5dUo0Qz3uuoN+deMvUbCRxczEXZlwEOeo9NinTMHkSZmrKjOPsA
 3z8GX6YneovCXnJ8EKrhHQvVc9zpkkyIBx65quj2KnEXVB4wvl7MJAx
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QUP I2C and SPI controllers move their data through the BLSP BAM
DMA engines, which reach DDR as the aggregation NoC masters BLSP_1 and
BLSP_2. No path is described for them, so nothing requests bandwidth for
those masters while a transfer runs.

Describe the path from each controller's BLSP master to DDR, as the
vendor kernel votes it. On a Motorola Moto X4 (SDM630), with the
boot-time interconnect votes released and system-level sleep enabled,
an I2C transfer running as the SoC entered that sleep hung the SoC
without these paths; with them, 5,000 transfers ran through about 3,000
sleep entries.

Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
Tested on a Motorola Moto X4 (SDM630), whose board file is not in
mainline yet, on the sdm660-mainline tree. System-level sleep there
comes from changes not yet posted. The UART nodes get no path: their
driver requests no bandwidth.
---
 arch/arm64/boot/dts/qcom/sdm630.dtsi | 18 ++++++++++++++++++
 1 file changed, 18 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm630.dtsi b/arch/arm64/boot/dts/qcom/sdm630.dtsi
index 3a1014804fb0..20225732e4a8 100644
--- a/arch/arm64/boot/dts/qcom/sdm630.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm630.dtsi
@@ -1811,6 +1811,8 @@ blsp_i2c1: i2c@c175000 {
 			dmas = <&blsp1_dma 4>, <&blsp1_dma 5>;
 			dma-names = "tx", "rx";
 
+			interconnects = <&a2noc MASTER_BLSP_1 &bimc SLAVE_EBI>;
+
 			pinctrl-names = "default", "sleep";
 			pinctrl-0 = <&i2c1_default>;
 			pinctrl-1 = <&i2c1_sleep>;
@@ -1831,6 +1833,8 @@ blsp_i2c2: i2c@c176000 {
 			dmas = <&blsp1_dma 6>, <&blsp1_dma 7>;
 			dma-names = "tx", "rx";
 
+			interconnects = <&a2noc MASTER_BLSP_1 &bimc SLAVE_EBI>;
+
 			pinctrl-names = "default", "sleep";
 			pinctrl-0 = <&i2c2_default>;
 			pinctrl-1 = <&i2c2_sleep>;
@@ -1851,6 +1855,8 @@ blsp_i2c3: i2c@c177000 {
 			dmas = <&blsp1_dma 8>, <&blsp1_dma 9>;
 			dma-names = "tx", "rx";
 
+			interconnects = <&a2noc MASTER_BLSP_1 &bimc SLAVE_EBI>;
+
 			pinctrl-names = "default", "sleep";
 			pinctrl-0 = <&i2c3_default>;
 			pinctrl-1 = <&i2c3_sleep>;
@@ -1871,6 +1877,8 @@ blsp_i2c4: i2c@c178000 {
 			dmas = <&blsp1_dma 10>, <&blsp1_dma 11>;
 			dma-names = "tx", "rx";
 
+			interconnects = <&a2noc MASTER_BLSP_1 &bimc SLAVE_EBI>;
+
 			pinctrl-names = "default", "sleep";
 			pinctrl-0 = <&i2c4_default>;
 			pinctrl-1 = <&i2c4_sleep>;
@@ -1919,6 +1927,8 @@ blsp_i2c5: i2c@c1b5000 {
 			dmas = <&blsp2_dma 4>, <&blsp2_dma 5>;
 			dma-names = "tx", "rx";
 
+			interconnects = <&a2noc MASTER_BLSP_2 &bimc SLAVE_EBI>;
+
 			pinctrl-names = "default", "sleep";
 			pinctrl-0 = <&i2c5_default>;
 			pinctrl-1 = <&i2c5_sleep>;
@@ -1939,6 +1949,8 @@ blsp_i2c6: i2c@c1b6000 {
 			dmas = <&blsp2_dma 6>, <&blsp2_dma 7>;
 			dma-names = "tx", "rx";
 
+			interconnects = <&a2noc MASTER_BLSP_2 &bimc SLAVE_EBI>;
+
 			pinctrl-names = "default", "sleep";
 			pinctrl-0 = <&i2c6_default>;
 			pinctrl-1 = <&i2c6_sleep>;
@@ -1959,6 +1971,8 @@ blsp_i2c7: i2c@c1b7000 {
 			dmas = <&blsp2_dma 8>, <&blsp2_dma 9>;
 			dma-names = "tx", "rx";
 
+			interconnects = <&a2noc MASTER_BLSP_2 &bimc SLAVE_EBI>;
+
 			pinctrl-names = "default", "sleep";
 			pinctrl-0 = <&i2c7_default>;
 			pinctrl-1 = <&i2c7_sleep>;
@@ -1979,6 +1993,8 @@ blsp_spi7: spi@c1b7000 {
 			dmas = <&blsp2_dma 8>, <&blsp2_dma 9>;
 			dma-names = "tx", "rx";
 
+			interconnects = <&a2noc MASTER_BLSP_2 &bimc SLAVE_EBI>;
+
 			pinctrl-names = "default", "sleep";
 			pinctrl-0 = <&spi7_default>;
 			pinctrl-1 = <&spi7_sleep>;
@@ -1999,6 +2015,8 @@ blsp_i2c8: i2c@c1b8000 {
 			dmas = <&blsp2_dma 10>, <&blsp2_dma 11>;
 			dma-names = "tx", "rx";
 
+			interconnects = <&a2noc MASTER_BLSP_2 &bimc SLAVE_EBI>;
+
 			pinctrl-names = "default", "sleep";
 			pinctrl-0 = <&i2c8_default>;
 			pinctrl-1 = <&i2c8_sleep>;

---
base-commit: aac26bee2287c88af5be5a5ff96d783b19a28790
change-id: 20261009-sdm630-blsp-paths-bb3575c30032

Best regards,
--  
Fabricio Akio <fabricioakio@gmail.com>

