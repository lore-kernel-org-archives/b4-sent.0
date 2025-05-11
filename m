From: Sven Peter <sven@svenpeter.dev>
Date: Sun, 11 May 2025 08:18:45 +0000
Subject: [PATCH v5 10/10] arm64: dts: apple: t600x: Add SMC node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250511-smc-6-15-v5-10-f5980bdb18bd@svenpeter.dev>
References: <20250511-smc-6-15-v5-0-f5980bdb18bd@svenpeter.dev>
In-Reply-To: <20250511-smc-6-15-v5-0-f5980bdb18bd@svenpeter.dev>
To: Sven Peter <sven@svenpeter.dev>, Janne Grunau <j@jannau.net>, 
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1906; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=92m9tjkE/9fmIrwCKyHzSWjjFycxwyBc2n6Mji86KpA=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4ZCbNX/meHWDVVVucqnriznUl5kzrDinn9/j4zdasbNl
 5StDaQ6SlkYxDgYZMUUWbbvtzd98vCN4NJNl97DzGFlAhnCwMUpABN5f4aR4VbwjPpv98IVwjZx
 xW91NTbNb2deJLmmYrZR537FUyf5jRj+WT94s3fJVpc0j91Wy6+fnKv7uvbFFsOPahw3ls4Lkuv
 XZQEA
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

Signed-off-by: Hector Martin <marcan@marcan.st>
Reviewed-by: Alyssa Rosenzweig <alyssa@rosenzweig.io>
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 arch/arm64/boot/dts/apple/t600x-die0.dtsi | 35 +++++++++++++++++++++++++++++++
 1 file changed, 35 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t600x-die0.dtsi b/arch/arm64/boot/dts/apple/t600x-die0.dtsi
index 110bc6719512e334e04b496fb157cb4368679957..4993a8ace87b2fc7e645b08c19fcd9b0c21896aa 100644
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
+				<&boot_error_count>, <&panic_count>, <&pm_setting>;
+			nvmem-cell-names = "shutdown_flag", "boot_stage",
+				"boot_error_count", "panic_count", "pm_setting";
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

