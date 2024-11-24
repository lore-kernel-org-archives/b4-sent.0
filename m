From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Sun, 24 Nov 2024 23:29:27 +0100
Subject: [PATCH 4/5] arm64: dts: apple: Add touchbar screen nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241124-adpdrm-v1-4-3191d8e6e49a@gmail.com>
References: <20241124-adpdrm-v1-0-3191d8e6e49a@gmail.com>
In-Reply-To: <20241124-adpdrm-v1-0-3191d8e6e49a@gmail.com>
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, asahi@lists.linux.dev
Cc: linux-arm-kernel@lists.infradead.org, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732487379; l=4465;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=/Z/q4ZVJ4fsMdrr5uOJvHeSbqY42cSj9gitq980wGIU=;
 b=tMPX18T+Mc2Zftsm6YNPtbIp7sj8XBd/laV55C6OqIyQbFNCv8yOKB07ihqOE/mUKeuTEPcAo
 UYK3LuUFhH2AYZpUGQAd6RLHTXqRFj9AWsBY7pvWa+P4xIN7mOx608+
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds device tree entries for the touchbar screen

Co-developed-by: Janne Grunau <j@jannau.net>
Signed-off-by: Janne Grunau <j@jannau.net>
Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 arch/arm64/boot/dts/apple/t8103-j293.dts |  8 ++++++++
 arch/arm64/boot/dts/apple/t8103.dtsi     | 26 ++++++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t8112-j493.dts | 15 +++++++++++++++
 arch/arm64/boot/dts/apple/t8112.dtsi     | 25 +++++++++++++++++++++++++
 4 files changed, 74 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t8103-j293.dts b/arch/arm64/boot/dts/apple/t8103-j293.dts
index 56b0c67bfcda321b60c621de092643017693ff91..349a8fce6b0b8ccf3305f940ba7242e2c1a67754 100644
--- a/arch/arm64/boot/dts/apple/t8103-j293.dts
+++ b/arch/arm64/boot/dts/apple/t8103-j293.dts
@@ -49,3 +49,11 @@ &i2c4 {
 &fpwm1 {
 	status = "okay";
 };
+
+&display_dfr {
+	status = "okay";
+	dfr_panel: panel@0 {
+		compatible = "apple,summit";
+		reg = <0>;
+	};
+};
diff --git a/arch/arm64/boot/dts/apple/t8103.dtsi b/arch/arm64/boot/dts/apple/t8103.dtsi
index 9b0dad6b618444ac6b1c9735c50cccfc3965f947..b377c92c5db3cb4fea53ae2c5dd85acf038429a3 100644
--- a/arch/arm64/boot/dts/apple/t8103.dtsi
+++ b/arch/arm64/boot/dts/apple/t8103.dtsi
@@ -356,6 +356,32 @@ cpufreq_p: performance-controller@211e20000 {
 			#performance-domain-cells = <0>;
 		};
 
+		display_dfr: display-pipe@228200000 {
+			compatible = "apple,t8103-display-pipe", "apple,h7-display-pipe";
+			reg-names = "be", "fe", "mipi";
+			reg = <0x2 0x28200000 0x0 0xc000>,
+				<0x2 0x28400000 0x0 0x4000>,
+				<0x2 0x28600000 0x0 0x100000>;
+			power-domains = <&ps_dispdfr_fe>, <&ps_dispdfr_be>, <&ps_mipi_dsi>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 502 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ 506 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "be", "fe";
+			status = "disabled";
+			iommus = <&displaydfr_dart 0>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+		};
+
+		displaydfr_dart: iommu@228304000 {
+			compatible = "apple,t8103-dart";
+			reg = <0x2 0x28304000 0x0 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 504 IRQ_TYPE_LEVEL_HIGH>;
+			#iommu-cells = <1>;
+			power-domains = <&ps_dispdfr_fe>;
+		};
+
 		sio_dart: iommu@235004000 {
 			compatible = "apple,t8103-dart";
 			reg = <0x2 0x35004000 0x0 0x4000>;
diff --git a/arch/arm64/boot/dts/apple/t8112-j493.dts b/arch/arm64/boot/dts/apple/t8112-j493.dts
index 0ad908349f55406783942735a2e9dad54cda00ec..80e371495f3e097f91e94549c7ac2949609f566f 100644
--- a/arch/arm64/boot/dts/apple/t8112-j493.dts
+++ b/arch/arm64/boot/dts/apple/t8112-j493.dts
@@ -35,6 +35,21 @@ led-0 {
 	};
 };
 
+&display_dfr {
+	status = "okay";
+	#address-cells = <1>;
+	#size-cells = <0>;
+
+	dfr_panel: panel@0 {
+		compatible = "apple,summit";
+		reg = <0>;
+	};
+};
+
+&displaydfr_dart {
+	status = "okay";
+};
+
 /*
  * Force the bus number assignments so that we can declare some of the
  * on-board devices and properties that are populated by the bootloader
diff --git a/arch/arm64/boot/dts/apple/t8112.dtsi b/arch/arm64/boot/dts/apple/t8112.dtsi
index 1666e6ab250bc0be9b8318e3c8fc903ccd3f3760..726b11376692580abb129b9be35107bee1550a93 100644
--- a/arch/arm64/boot/dts/apple/t8112.dtsi
+++ b/arch/arm64/boot/dts/apple/t8112.dtsi
@@ -379,6 +379,31 @@ cpufreq_p: cpufreq@211e20000 {
 			#performance-domain-cells = <0>;
 		};
 
+		display_dfr: display-pipe@228200000 {
+			compatible = "apple,t8112-display-pipe", "apple,h7-display-pipe";
+			reg-names = "be", "fe", "mipi";
+			reg = <0x2 0x28200000 0x0 0xc000>,
+				<0x2 0x28400000 0x0 0x4000>,
+				<0x2 0x28600000 0x0 0x100000>;
+			power-domains = <&ps_dispdfr_fe>, <&ps_dispdfr_be>, <&ps_mipi_dsi>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 614 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ 618 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "be", "fe";
+			status = "disabled";
+			iommus = <&displaydfr_dart 0>;
+		};
+
+		displaydfr_dart: iommu@228304000 {
+			compatible = "apple,t8110-dart";
+			reg = <0x2 0x28304000 0x0 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 616 IRQ_TYPE_LEVEL_HIGH>;
+			#iommu-cells = <1>;
+			power-domains = <&ps_dispdfr_fe>;
+			status = "disabled";
+		};
+
 		sio_dart: iommu@235004000 {
 			compatible = "apple,t8110-dart";
 			reg = <0x2 0x35004000 0x0 0x4000>;

-- 
2.47.0

