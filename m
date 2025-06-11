From: Sven Peter <sven@kernel.org>
Date: Wed, 11 Jun 2025 15:18:53 +0000
Subject: [PATCH] arm64: dts: apple: Move touchbar mipi {address,size}-cells
 from dtsi to dts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250611-display-pipe-mipi-warning-v1-1-bd80ba2c0eea@kernel.org>
X-B4-Tracking: v=1; b=H4sIAFyeSWgC/x3MQQqDMBBG4avIrB1ILEnRq4iLoKP+UOOQgG0R7
 25w+S3eOylLgmTqqpOSHMjYY4GtKxrXEBdhTMXUmMYZby1PyPoJf1ao8AYFf0OKiAt7b1pnX0H
 c+KbSa5IZv+fdD9d1A4feWKhrAAAA
X-Change-ID: 20250611-display-pipe-mipi-warning-6609513ae5c7
To: Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>, 
 Nick Chan <towinchenmi@gmail.com>, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3299; i=sven@kernel.org;
 h=from:subject:message-id; bh=wB4gN/vQqwxjlQjrCtsB7lnBgH7W5zGItspRFqPIMtc=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4bnvHjGqnmsFYtcpfM3uQiaifDP/CVvzX/vUirjh5e1L
 UVTP/R0lLIwiHEwyIopsmzfb2/65OEbwaWbLr2HmcPKBDKEgYtTACZywJKRYW3m9ZkZebyHPeMX
 BE6M03PdX7svdr3TLqOjuR4/T3Sk1zD8Mz4VtmI+z/eIP3X7vOt8prbqaVSFcPxylD7B6tTSsCK
 MAQA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the {address,size}-cells property from the (disabled) touchbar screen
mipi node inside the dtsi file to the model-specific dts file where it's
enabled to fix the following W=1 warnings:

t8103.dtsi:404.34-433.5: Warning (avoid_unnecessary_addr_size): /soc/dsi@228600000: unnecessary #address-cells/#size-cells without "ranges", "dma-ranges" or child "reg" property
t8112.dtsi:419.34-448.5: Warning (avoid_unnecessary_addr_size): /soc/dsi@228600000: unnecessary #address-cells/#size-cells without "ranges", "dma-ranges" or child "reg" property

Fixes: 7275e795e520 ("arm64: dts: apple: Add touchbar screen nodes")
Signed-off-by: Sven Peter <sven@kernel.org>
---
 arch/arm64/boot/dts/apple/t8103-j293.dts | 2 ++
 arch/arm64/boot/dts/apple/t8103.dtsi     | 2 --
 arch/arm64/boot/dts/apple/t8112-j493.dts | 2 ++
 arch/arm64/boot/dts/apple/t8112.dtsi     | 2 --
 4 files changed, 4 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/apple/t8103-j293.dts b/arch/arm64/boot/dts/apple/t8103-j293.dts
index e2d9439397f71a93c28b75a7eea589f4bcb3e374..5b3c42e9f0e6776241bf746d3458766e44e3639a 100644
--- a/arch/arm64/boot/dts/apple/t8103-j293.dts
+++ b/arch/arm64/boot/dts/apple/t8103-j293.dts
@@ -100,6 +100,8 @@ dfr_mipi_out_panel: endpoint@0 {
 
 &displaydfr_mipi {
 	status = "okay";
+	#address-cells = <1>;
+	#size-cells = <0>;
 
 	dfr_panel: panel@0 {
 		compatible = "apple,j293-summit", "apple,summit";
diff --git a/arch/arm64/boot/dts/apple/t8103.dtsi b/arch/arm64/boot/dts/apple/t8103.dtsi
index 20faf0c0d80927b2e18dd966a61b5507b322c72f..3a204845b85befb093dd470b4280e778c2894b09 100644
--- a/arch/arm64/boot/dts/apple/t8103.dtsi
+++ b/arch/arm64/boot/dts/apple/t8103.dtsi
@@ -405,8 +405,6 @@ displaydfr_mipi: dsi@228600000 {
 			compatible = "apple,t8103-display-pipe-mipi", "apple,h7-display-pipe-mipi";
 			reg = <0x2 0x28600000 0x0 0x100000>;
 			power-domains = <&ps_mipi_dsi>;
-			#address-cells = <1>;
-			#size-cells = <0>;
 			status = "disabled";
 
 			ports {
diff --git a/arch/arm64/boot/dts/apple/t8112-j493.dts b/arch/arm64/boot/dts/apple/t8112-j493.dts
index be86d34c6696cb47d31696541266e504cee8ce10..fb8ad7d4c65a8fe7966f5541f24f03a379143cfb 100644
--- a/arch/arm64/boot/dts/apple/t8112-j493.dts
+++ b/arch/arm64/boot/dts/apple/t8112-j493.dts
@@ -63,6 +63,8 @@ dfr_mipi_out_panel: endpoint@0 {
 
 &displaydfr_mipi {
 	status = "okay";
+	#address-cells = <1>;
+	#size-cells = <0>;
 
 	dfr_panel: panel@0 {
 		compatible = "apple,j493-summit", "apple,summit";
diff --git a/arch/arm64/boot/dts/apple/t8112.dtsi b/arch/arm64/boot/dts/apple/t8112.dtsi
index e95711d8337f6cea898e88a3d564caf2c4f94404..f68354194355807dae9b5922bb8aff74da3c29e6 100644
--- a/arch/arm64/boot/dts/apple/t8112.dtsi
+++ b/arch/arm64/boot/dts/apple/t8112.dtsi
@@ -420,8 +420,6 @@ displaydfr_mipi: dsi@228600000 {
 			compatible = "apple,t8112-display-pipe-mipi", "apple,h7-display-pipe-mipi";
 			reg = <0x2 0x28600000 0x0 0x100000>;
 			power-domains = <&ps_mipi_dsi>;
-			#address-cells = <1>;
-			#size-cells = <0>;
 			status = "disabled";
 
 			ports {

---
base-commit: 19272b37aa4f83ca52bdf9c16d5d81bdd1354494
change-id: 20250611-display-pipe-mipi-warning-6609513ae5c7

Best regards,
-- 
Sven Peter <sven@kernel.org>

