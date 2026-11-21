From: Michael Reeves <michael.reeves077@gmail.com>
Date: Sat, 21 Nov 2026 08:34:18 +0000
Subject: [PATCH 4/4] arm64: dts: apple: t8122: Add SMC and its mailbox
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-t8122-smc-dt-v1-4-898f3f5d6228@gmail.com>
References: <20261121-t8122-smc-dt-v1-0-898f3f5d6228@gmail.com>
In-Reply-To: <20261121-t8122-smc-dt-v1-0-898f3f5d6228@gmail.com>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Stephen Boyd <sboyd@kernel.org>, 
 Abel Vesa <abelvesa@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sasha Finkelstein <k@chaosmail.tech>, 
 Lee Jones <lee@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 mfd@lists.linux.dev, Michael Reeves <michael.reeves077@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795250077; l=2295;
 i=michael.reeves077@gmail.com; s=20261107; h=from:subject:message-id;
 bh=tpqBT90IBSHnW53MpijwPnOkQrD4pV6ieL92p27Jfk8=;
 b=5YdoFcdoEGZzUWkidC4DWFjfIUFCfEhG23e0BOT0uEjv56GNE+fiE/672LMAcMunjlGLJDlkk
 pEuX7BYpeZrCflBtA5dXomDOoX2COWI+Djr+5F0HQF5FSFdDpOvVMnr
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=ykwkLcuByJYb/cdLc2UuoYP03pIzwrscEZg30+4tJL8=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20261107 with auth_id=1442
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the System Management Controller node, its ASC mailbox, and GPIO,
hwmon, reboot, and RTC child nodes for the Apple M3 (T8122) SoC.

Co-developed-by: Sasha Finkelstein <k@chaosmail.tech>
Signed-off-by: Sasha Finkelstein <k@chaosmail.tech>
Co-developed-by: Janne Grunau <j@jannau.net>
Signed-off-by: Janne Grunau <j@jannau.net>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 arch/arm64/boot/dts/apple/t8122.dtsi | 45 ++++++++++++++++++++++++++++++++++++
 1 file changed, 45 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t8122.dtsi b/arch/arm64/boot/dts/apple/t8122.dtsi
index 3766da3c7b18..c585634250fc 100644
--- a/arch/arm64/boot/dts/apple/t8122.dtsi
+++ b/arch/arm64/boot/dts/apple/t8122.dtsi
@@ -468,6 +468,51 @@ rtc_offset: rtc-offset@f900 {
 			};
 		};
 
+		smc: smc@2ec400000 {
+			compatible = "apple,t8122-smc", "apple,t8103-smc";
+			reg = <0x2 0xec400000 0x0 0x4000>,
+			      <0x2 0xede00000 0x0 0x100000>;
+			reg-names = "smc", "sram";
+			mboxes = <&smc_mbox>;
+
+			smc_gpio: gpio {
+				compatible = "apple,smc-gpio";
+				gpio-controller;
+				#gpio-cells = <2>;
+			};
+
+			smc_hwmon: hwmon {
+				compatible = "apple,smc-hwmon";
+			};
+
+			smc_reboot: reboot {
+				compatible = "apple,smc-reboot";
+				nvmem-cells = <&shutdown_flag>, <&boot_stage>,
+					      <&boot_error_count>, <&panic_count>;
+				nvmem-cell-names = "shutdown_flag", "boot_stage",
+						   "boot_error_count", "panic_count";
+			};
+
+			rtc {
+				compatible = "apple,smc-rtc";
+				nvmem-cells = <&rtc_offset>;
+				nvmem-cell-names = "rtc_offset";
+			};
+		};
+
+		smc_mbox: mbox@2ec408000 {
+			compatible = "apple,t8122-asc-mailbox", "apple,asc-mailbox-v4";
+			reg = <0x2 0xec408000 0x0 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 502 IRQ_TYPE_LEVEL_HIGH>,
+				     <AIC_IRQ 503 IRQ_TYPE_LEVEL_HIGH>,
+				     <AIC_IRQ 504 IRQ_TYPE_LEVEL_HIGH>,
+				     <AIC_IRQ 505 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "send-empty", "send-not-empty",
+					  "recv-empty", "recv-not-empty";
+			#mbox-cells = <0>;
+		};
+
 		pinctrl_smc: pinctrl@2ec820000 {
 			compatible = "apple,t8122-pinctrl", "apple,t8103-pinctrl";
 			reg = <0x2 0xec820000 0x0 0x4000>;

-- 
2.56.0

