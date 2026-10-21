From: Han Gao <gaohan@iscas.ac.cn>
Date: Thu, 22 Oct 2026 03:53:34 +0800
Subject: [PATCH 14/18] riscv: dts: zhihe: add A210 UARTs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-a210-init-v1-14-5e438f972d24@iscas.ac.cn>
References: <20261022-a210-init-v1-0-5e438f972d24@iscas.ac.cn>
In-Reply-To: <20261022-a210-init-v1-0-5e438f972d24@iscas.ac.cn>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, Icenowy Zheng <uwu@icenowy.me>, 
 Drew Fustini <fustini@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-riscv@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, Paul Walmsley <paul.walmsley@sifive.com>, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792612403; l=5486;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=uWP7w6RpNZW/7YfTTpaJ1x8asm0foYPKOs5HYmLXeC4=;
 b=4MLw4y2SX8t/TUDLbdWe6mmoHfaLeT2SlEkYUSrcIbh+6+aie/eOGPiAxesaJaTYjfbMZRnNt
 EDyLpct9HTJBWb0RxunXo1DI63hGw2cTAYjJNaCuiqsLmlFXO3pTunN
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>

Add the ten A210 UARTs with their clocks, resets and interrupts, using
the snps,dw-apb-uart compatible.

Signed-off-by: Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>
Co-developed-by: Han Gao <gaohan@iscas.ac.cn>
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 arch/riscv/boot/dts/zhihe/a210.dtsi | 150 ++++++++++++++++++++++++++++++++++++
 1 file changed, 150 insertions(+)

diff --git a/arch/riscv/boot/dts/zhihe/a210.dtsi b/arch/riscv/boot/dts/zhihe/a210.dtsi
index bbad51a3edb0..a07b67d10633 100644
--- a/arch/riscv/boot/dts/zhihe/a210.dtsi
+++ b/arch/riscv/boot/dts/zhihe/a210.dtsi
@@ -405,6 +405,66 @@ rst_peri1: reset-controller@2010400 {
 			#reset-cells = <1>;
 		};
 
+		uart0: serial@2014000 {
+			compatible = "snps,dw-apb-uart";
+			reg = <0x0 0x02014000 0x0 0x400>;
+			clocks = <&clk_peri PERI1_UART0_SCLK_EN>,
+				 <&clk_peri PERI1_UART0_PCLK_EN>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupt-parent = <&intc>;
+			interrupts = <321 IRQ_TYPE_LEVEL_HIGH>;
+			reg-io-width = <4>;
+			reg-shift = <2>;
+			resets = <&rst_peri1 PERI1_UART0_PRST>;
+
+			status = "disabled";
+		};
+
+		uart1: serial@2015000 {
+			compatible = "snps,dw-apb-uart";
+			reg = <0x0 0x02015000 0x0 0x1000>;
+			clocks = <&clk_peri PERI1_UART1_SCLK_EN>,
+				 <&clk_peri PERI1_UART1_PCLK_EN>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupt-parent = <&intc>;
+			interrupts = <322 IRQ_TYPE_LEVEL_HIGH>;
+			reg-io-width = <4>;
+			reg-shift = <2>;
+			resets = <&rst_peri1 PERI1_UART1_PRST>;
+
+			status = "disabled";
+		};
+
+		uart2: serial@2016000 {
+			compatible = "snps,dw-apb-uart";
+			reg = <0x0 0x02016000 0x0 0x1000>;
+			clocks = <&clk_peri PERI1_UART2_SCLK_EN>,
+				 <&clk_peri PERI1_UART2_PCLK_EN>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupt-parent = <&intc>;
+			interrupts = <323 IRQ_TYPE_LEVEL_HIGH>;
+			reg-io-width = <4>;
+			reg-shift = <2>;
+			resets = <&rst_peri1 PERI1_UART2_PRST>;
+
+			status = "disabled";
+		};
+
+		uart3: serial@2017000 {
+			compatible = "snps,dw-apb-uart";
+			reg = <0x0 0x02017000 0x0 0x1000>;
+			clocks = <&clk_peri PERI1_UART3_SCLK_EN>,
+				 <&clk_peri PERI1_UART3_PCLK_EN>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupt-parent = <&intc>;
+			interrupts = <324 IRQ_TYPE_LEVEL_HIGH>;
+			reg-io-width = <4>;
+			reg-shift = <2>;
+			resets = <&rst_peri1 PERI1_UART3_PRST>;
+
+			status = "disabled";
+		};
+
 		peri1_padctrl: pinctrl@2026000 {
 			compatible = "zhihe,a210-peri1-pinctrl";
 			reg = <0x0 0x02026000 0x0 0x1000>;
@@ -420,6 +480,96 @@ rst_peri2: reset-controller@8400400 {
 			#reset-cells = <1>;
 		};
 
+		uart4: serial@8401000 {
+			compatible = "snps,dw-apb-uart";
+			reg = <0x0 0x08401000 0x0 0x400>;
+			clocks = <&clk_peri PERI2_UART4_SCLK_EN>,
+				 <&clk_peri PERI2_UART4_PCLK_EN>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupt-parent = <&intc>;
+			interrupts = <325 IRQ_TYPE_LEVEL_HIGH>;
+			reg-io-width = <4>;
+			reg-shift = <2>;
+			resets = <&rst_peri2 PERI2_UART4_PRST>;
+
+			status = "disabled";
+		};
+
+		uart5: serial@8402000 {
+			compatible = "snps,dw-apb-uart";
+			reg = <0x0 0x08402000 0x0 0x1000>;
+			clocks = <&clk_peri PERI2_UART5_SCLK_EN>,
+				 <&clk_peri PERI2_UART5_PCLK_EN>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupt-parent = <&intc>;
+			interrupts = <326 IRQ_TYPE_LEVEL_HIGH>;
+			reg-io-width = <4>;
+			reg-shift = <2>;
+			resets = <&rst_peri2 PERI2_UART5_PRST>;
+
+			status = "disabled";
+		};
+
+		uart6: serial@8403000 {
+			compatible = "snps,dw-apb-uart";
+			reg = <0x0 0x08403000 0x0 0x1000>;
+			clocks = <&clk_peri PERI2_UART6_SCLK_EN>,
+				 <&clk_peri PERI2_UART6_PCLK_EN>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupt-parent = <&intc>;
+			interrupts = <327 IRQ_TYPE_LEVEL_HIGH>;
+			reg-io-width = <4>;
+			reg-shift = <2>;
+			resets = <&rst_peri2 PERI2_UART6_PRST>;
+
+			status = "disabled";
+		};
+
+		uart7: serial@8404000 {
+			compatible = "snps,dw-apb-uart";
+			reg = <0x0 0x08404000 0x0 0x1000>;
+			clocks = <&clk_peri PERI2_UART7_SCLK_EN>,
+				 <&clk_peri PERI2_UART7_PCLK_EN>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupt-parent = <&intc>;
+			interrupts = <328 IRQ_TYPE_LEVEL_HIGH>;
+			reg-io-width = <4>;
+			reg-shift = <2>;
+			resets = <&rst_peri2 PERI2_UART7_PRST>;
+
+			status = "disabled";
+		};
+
+		uart8: serial@8405000 {
+			compatible = "snps,dw-apb-uart";
+			reg = <0x0 0x08405000 0x0 0x1000>;
+			clocks = <&clk_peri PERI2_UART8_SCLK_EN>,
+				 <&clk_peri PERI2_UART8_PCLK_EN>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupt-parent = <&intc>;
+			interrupts = <329 IRQ_TYPE_LEVEL_HIGH>;
+			reg-io-width = <4>;
+			reg-shift = <2>;
+			resets = <&rst_peri2 PERI2_UART8_PRST>;
+
+			status = "disabled";
+		};
+
+		uart9: serial@8406000 {
+			compatible = "snps,dw-apb-uart";
+			reg = <0x0 0x08406000 0x0 0x1000>;
+			clocks = <&clk_peri PERI2_UART9_SCLK_EN>,
+				 <&clk_peri PERI2_UART9_PCLK_EN>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupt-parent = <&intc>;
+			interrupts = <330 IRQ_TYPE_LEVEL_HIGH>;
+			reg-io-width = <4>;
+			reg-shift = <2>;
+			resets = <&rst_peri2 PERI2_UART9_PRST>;
+
+			status = "disabled";
+		};
+
 		peri2_padctrl: pinctrl@8411000 {
 			compatible = "zhihe,a210-peri2-pinctrl";
 			reg = <0x0 0x08411000 0x0 0x1000>;

-- 
2.55.0

