From: Aiden Isik <aidenisik@member.fsf.org>
Date: Mon, 19 Oct 2026 11:23:50 +0100
Subject: [PATCH v2 4/5] arm64: dts: exynos: Add initial support for
 Exynos5515 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-for-next-lucky7-v2-4-c4ecab4b1c4c@member.fsf.org>
References: <20261019-for-next-lucky7-v2-0-c4ecab4b1c4c@member.fsf.org>
In-Reply-To: <20261019-for-next-lucky7-v2-0-c4ecab4b1c4c@member.fsf.org>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6189;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=pASwubJHFvW3MAEHlbZcTMjHS7aYU3sKpBSvWxJR3+k=;
 b=owEBiQJ2/ZANAwAIAUknAbLEetfrAcsmYgBq1e+7ZIyarByefmJ3m8z7F32OtpibXbAzErQfA
 0xi2aou0gOJAk8EAAEIADkWIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCatXvuxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQSScBssR61+tzJxAArvxYkZJ6mFZH3iaMde30Lu9e/Qp83c1
 8RdN9ejqbbgojBPBDkBsmhP35jOh4i+hrMrRKbriW6+eoEQKvJJX39wah+FOqnCa80n+CgVRhax
 4DkcngRvl5wnkXzhl54cavUsF6Tvim5kMy27+rkH2Z1XQb9pe7a9bWhJ9z5GhcVzGneqdUaH1VZ
 r8aGVwUyIzU1TVJmjO1R6vk7y/ax8tONNYbOFVMNiUXkuKkJWGCkyBsrM6ec+yCHFXjsulkaYfK
 I+EOQYxIcLW1NhHTIYWgYf4Rj46tH3NRNk8QkVywz5yIVWKj+0Ozq+SDzGqe0XFMcfKweCUdknW
 2LON4pyB/MJS0hkvWruT3rk7DraReCPpK46Kg0xz2ipbS8wArX1mu8B0IYd3CR0Z1uJS46zWXVL
 5xJE5rbTpdhfd13d71MvmSWhVQaD2f/nqvOGtfXgFdkmzKoepVXxmYHjvGX0iFO6IIHLj4nCA6C
 e8Z0Kd+oRLtH03r6zaZkDihxXs5R0C3LZaD1zTK8LYnA2qZM4XL6FNV95Wz9rSJbVa0wWiv6tgf
 SfqF3zvzNxhn0c9U8T3cQY5+FRo5B9qzMj0vGckKqwZ/GUSWh4nbga0ySHPz5BR0cll9NPx+jkT
 ymEsuVJl10c3N103c/rQVk4W3gZHM8ccknJXi+y+uVLtFJ7ktt24=
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Exynos5515 is an ARMv8 wearable SoC, used in the following devices:
- Samsung Galaxy Watch 4 (SM-R860/SM-R865/SM-R870/SM-R875)
- Samsung Galaxy Watch 4 Classic (SM-R880/SM-R885/SM-R890/SM-R895)
- Samsung Galaxy Watch FE (SM-R861/SM-R866)
- Samsung Galaxy Watch 5 (SM-R900/SM-R905/SM-R910/SM-R915)
- Samsung Galaxy Watch 5 Pro (SM-R920/SM-R925)
- Samsung Galaxy Watch 6 (SM-R930/SM-R935/SM-R940/SM-R945)
- Samsung Galaxy Watch 6 Classic (SM-R950/SM-R955/SM-R960/SM-R965)

Add the following support for this SoC:
- Both Cortex-A55 cores
- ChipID
- Generic timer
- Watchdog timer
- CMU_TOP, CMU_PERI, and CMU_FSYS clock management units

The devices using this SoC suffer from the same issue as many other
Samsung devices, where the stock bootloader does not configure CNTFRQ_EL0.
To mitigate this, the correct frequency is hardcoded in the timer node.

The VGIC maintenance interrupt on this SoC is also unavailable.

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
 arch/arm64/boot/dts/exynos/exynos5515.dtsi | 189 +++++++++++++++++++++++++++++
 1 file changed, 189 insertions(+)

diff --git a/arch/arm64/boot/dts/exynos/exynos5515.dtsi b/arch/arm64/boot/dts/exynos/exynos5515.dtsi
new file mode 100644
index 000000000000..ce6fcbfffdb2
--- /dev/null
+++ b/arch/arm64/boot/dts/exynos/exynos5515.dtsi
@@ -0,0 +1,189 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Samsung Exynos 5515 SoC device tree source
+ *
+ * Copyright (c) 2026 Aiden Isik <aidenisik+git@member.fsf.org>
+ */
+
+#include <dt-bindings/clock/samsung,exynos5515-cmu.h>
+#include <dt-bindings/interrupt-controller/arm-gic.h>
+
+/ {
+	compatible = "samsung,exynos5515";
+	#address-cells = <2>;
+	interrupt-parent = <&gic>;
+	#size-cells = <1>;
+
+	cpus {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		cpu-map {
+			cluster0 {
+				core0 {
+					cpu = <&cpu0>;
+				};
+
+				core1 {
+					cpu = <&cpu1>;
+				};
+			};
+		};
+
+		cpu0: cpu@0 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a55";
+			reg = <0x0>;
+			enable-method = "psci";
+		};
+
+		cpu1: cpu@100 {
+			device_type = "cpu";
+			compatible = "arm,cortex-a55";
+			reg = <0x100>;
+			enable-method = "psci";
+		};
+	};
+
+	oscclk: osc-clock {
+		compatible = "fixed-clock";
+		#clock-cells = <0>;
+		clock-output-names = "oscclk";
+	};
+
+	pmu {
+		compatible = "arm,armv8-pmuv3";
+		interrupt-affinity = <&cpu0>,
+				     <&cpu1>;
+		interrupts = <GIC_SPI 99 IRQ_TYPE_LEVEL_HIGH>,
+			     <GIC_SPI 100 IRQ_TYPE_LEVEL_HIGH>;
+	};
+
+	psci {
+		compatible = "arm,psci-1.0";
+		method = "smc";
+	};
+
+	soc: soc@0 {
+		compatible = "simple-bus";
+		ranges = <0x0 0x0 0x0 0x20000000>;
+
+		#address-cells = <1>;
+		#size-cells = <1>;
+
+		chipid@10000000 {
+			compatible = "samsung,exynos5515-chipid",
+				     "samsung,exynos850-chipid";
+			reg = <0x10000000 0x100>;
+		};
+
+		sysreg_peri: syscon@10020000 {
+			compatible = "samsung,exynos5515-peri-sysreg", "syscon";
+			reg = <0x10020000 0x10000>;
+		};
+
+		cmu_peri: clock-controller@10030000 {
+			compatible = "samsung,exynos5515-cmu-peri";
+			reg = <0x10030000 0x10000>;
+			#clock-cells = <1>;
+			clocks = <&oscclk>,
+				 <&cmu_top CLK_DOUT_CMU_PERI_BUS>,
+				 <&cmu_top CLK_DOUT_CMU_PERI_IP>,
+				 <&cmu_top CLK_DOUT_CMU_PERI_UART>;
+			clock-names = "oscclk",
+				      "bus",
+				      "ip",
+				      "uart";
+			samsung,sysreg = <&sysreg_peri>;
+		};
+
+		watchdog: watchdog@10050000 {
+			compatible = "samsung,exynos5515-wdt";
+			reg = <0x10050000 0x100>;
+			clocks = <&cmu_peri CLK_GOUT_PERI_WDT0_PCLK>,
+				 <&oscclk>;
+			clock-names = "watchdog",
+				      "watchdog_src";
+			interrupts = <GIC_SPI 185 IRQ_TYPE_LEVEL_HIGH>;
+			samsung,syscon-phandle = <&pmu_system_controller>;
+
+			status = "disabled";
+		};
+
+		cmu_fsys: clock-controller@10400000 {
+			compatible = "samsung,exynos5515-cmu-fsys";
+			reg = <0x10400000 0x10000>;
+			#clock-cells = <1>;
+			clocks = <&oscclk>,
+				 <&cmu_top CLK_DOUT_CMU_FSYS_BUS>,
+				 <&cmu_top CLK_DOUT_CMU_FSYS_MMC_CARD>,
+				 <&cmu_top CLK_DOUT_CMU_FSYS_MMC_EMBD>,
+				 <&cmu_top CLK_DOUT_CMU_FSYS_USB20DRD>;
+			clock-names = "oscclk",
+				      "bus",
+				      "mmc_card",
+				      "mmc_embd",
+				      "usb20drd";
+			samsung,sysreg = <&sysreg_fsys>;
+		};
+
+		sysreg_fsys: syscon@10420000 {
+			compatible = "samsung,exynos5515-fsys-sysreg", "syscon";
+			reg = <0x10420000 0x10000>;
+		};
+
+		pmu_system_controller: system-controller@12860000 {
+			compatible = "samsung,exynos5515-pmu",
+				     "samsung,exynos7-pmu",
+				     "syscon";
+			reg = <0x12860000 0x10000>;
+		};
+
+		cmu_top: clock-controller@15410000 {
+			compatible = "samsung,exynos5515-cmu-top";
+			reg = <0x15410000 0x10000>;
+			#clock-cells = <1>;
+			clocks = <&oscclk>;
+			clock-names = "oscclk";
+			samsung,sysreg = <&sysreg_top>;
+		};
+
+		sysreg_top: syscon@15430000 {
+			compatible = "samsung,exynos5515-top-sysreg", "syscon";
+			reg = <0x15430000 0x10000>;
+		};
+
+		gic: interrupt-controller@15601000 {
+			compatible = "arm,gic-400";
+			reg = <0x15601000 0x1000>,
+			      <0x15602000 0x2000>,
+			      <0x15604000 0x2000>,
+			      <0x15606000 0x2000>;
+			#address-cells = <0>;
+			#interrupt-cells = <3>;
+			interrupt-controller;
+			/* VGIC maintenance interrupt is not available */
+		};
+	};
+
+	timer {
+		compatible = "arm,armv8-timer";
+		/*
+		 * Non-updatable, broken stock Samsung bootloader does not
+		 * configure CNTFRQ_EL0
+		 */
+		clock-frequency = <26000000>;
+		interrupts = <GIC_PPI 13
+			     (GIC_CPU_MASK_SIMPLE(8) | IRQ_TYPE_LEVEL_LOW)>,
+			     <GIC_PPI 14
+			     (GIC_CPU_MASK_SIMPLE(8) | IRQ_TYPE_LEVEL_LOW)>,
+			     <GIC_PPI 11
+			     (GIC_CPU_MASK_SIMPLE(8) | IRQ_TYPE_LEVEL_LOW)>,
+			     <GIC_PPI 10
+			     (GIC_CPU_MASK_SIMPLE(8) | IRQ_TYPE_LEVEL_LOW)>,
+			     <GIC_PPI 12
+			     (GIC_CPU_MASK_SIMPLE(8) | IRQ_TYPE_LEVEL_LOW)>;
+	};
+};
+
+#include "arm/samsung/exynos-syscon-restart.dtsi"

-- 
2.54.0

