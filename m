From: Sven Peter <sven@kernel.org>
Date: Tue, 10 Jun 2025 15:29:51 +0000
Subject: [PATCH v7 10/10] arm64: dts: apple: t600x: Add SMC node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250610-smc-6-15-v7-10-556cafd771d3@kernel.org>
References: <20250610-smc-6-15-v7-0-556cafd771d3@kernel.org>
In-Reply-To: <20250610-smc-6-15-v7-0-556cafd771d3@kernel.org>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Neal Gompa <neal@gompa.dev>, 
 Hector Martin <marcan@marcan.st>, Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sebastian Reichel <sre@kernel.org>, 
 Lee Jones <lee@kernel.org>, Marc Zyngier <maz@kernel.org>, 
 "Russell King (Oracle)" <rmk+kernel@armlinux.org.uk>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1916; i=sven@kernel.org;
 h=from:subject:message-id; bh=d8mVq62H2zbw5gGICFsvhQIy6YecpVCZ77lCLDSqOcw=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4aHf7Xmm8vulmtud8lsO1CmsHu10GnvyYerXR5GJgaz7
 tr5IjWro5SFQYyDQVZMkWX7fnvTJw/fCC7ddOk9zBxWJpAhDFycAjCRRGVGhh8v3rkm6f5/JP3w
 wBO+tq9hKctyLe2M47JVmIxSbrccMmRkWHBy5+cCl4eblr1InP2f7ajs802XfnbeubX0wrV9xTL
 bZ/AAAA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

Signed-off-by: Hector Martin <marcan@marcan.st>
Reviewed-by: Alyssa Rosenzweig <alyssa@rosenzweig.io>
Reviewed-by: Neal Gompa <neal@gompa.dev>
Signed-off-by: Sven Peter <sven@kernel.org>
---
 arch/arm64/boot/dts/apple/t600x-die0.dtsi | 35 +++++++++++++++++++++++++++++++
 1 file changed, 35 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t600x-die0.dtsi b/arch/arm64/boot/dts/apple/t600x-die0.dtsi
index 110bc6719512e334e04b496fb157cb4368679957..9eb9b0656bf9c570983c90e360795b7a7c71cf90 100644
--- a/arch/arm64/boot/dts/apple/t600x-die0.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-die0.dtsi
@@ -24,6 +24,41 @@ aic: interrupt-controller@28e100000 {
 		power-domains = <&ps_aic>;
 	};
 
+	smc: smc@290400000 {
+		compatible = "apple,t6000-smc", "apple,smc";
+		reg = <0x2 0x90400000 0x0 0x4000>,
+			<0x2 0x91e00000 0x0 0x100000>;
+		reg-names = "smc", "sram";
+		mboxes = <&smc_mbox>;
+
+		smc_gpio: gpio {
+			compatible = "apple,smc-gpio";
+			gpio-controller;
+			#gpio-cells = <2>;
+		};
+
+		smc_reboot: reboot {
+			compatible = "apple,smc-reboot";
+			nvmem-cells = <&shutdown_flag>, <&boot_stage>,
+				<&boot_error_count>, <&panic_count>;
+			nvmem-cell-names = "shutdown_flag", "boot_stage",
+				"boot_error_count", "panic_count";
+		};
+	};
+
+	smc_mbox: mbox@290408000 {
+		compatible = "apple,t6000-asc-mailbox", "apple,asc-mailbox-v4";
+		reg = <0x2 0x90408000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ 0 754 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ 0 755 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ 0 756 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ 0 757 IRQ_TYPE_LEVEL_HIGH>;
+		interrupt-names = "send-empty", "send-not-empty",
+			"recv-empty", "recv-not-empty";
+		#mbox-cells = <0>;
+	};
+
 	pinctrl_smc: pinctrl@290820000 {
 		compatible = "apple,t6000-pinctrl", "apple,pinctrl";
 		reg = <0x2 0x90820000 0x0 0x4000>;

-- 
2.34.1

