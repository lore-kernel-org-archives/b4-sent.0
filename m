From: Han Gao <gaohan@iscas.ac.cn>
Date: Tue, 03 Nov 2026 03:45:16 +0800
Subject: [PATCH RFC v3 13/17] riscv: dts: zhihe: add A210 UARTs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-a210-scmi-v3-13-ee6b31580808@iscas.ac.cn>
References: <20261103-a210-scmi-v3-0-ee6b31580808@iscas.ac.cn>
In-Reply-To: <20261103-a210-scmi-v3-0-ee6b31580808@iscas.ac.cn>
To: Sudeep Holla <sudeep.holla@kernel.org>, 
 Cristian Marussi <cristian.marussi@arm.com>, 
 Michal Simek <michal.simek@amd.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>, 
 Jassi Brar <jassisinghbrar@gmail.com>, Linus Walleij <linusw@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Drew Fustini <fustini@kernel.org>, 
 Icenowy Zheng <uwu@icenowy.me>, Inochi Amaoto <inochiama@gmail.com>, 
 Vivian Wang <wangruikang@iscas.ac.cn>, Yao Zi <me@ziyao.cc>, 
 Jiaxun Yang <jiaxun.yang@flygoat.com>
Cc: arm-scmi@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-riscv@lists.infradead.org, linux-gpio@vger.kernel.org, 
 Paul Walmsley <paul.walmsley@sifive.com>, linux-clk@vger.kernel.org, 
 linux-serial@vger.kernel.org, Han Gao <rabenda.cn@gmail.com>, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793648705; l=6182;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=B6tm2OM7jOdMucw1zXohh3+kCm1z/YVGQ/Bj++2MOGQ=;
 b=MdU04rFHtyT7xgYvIzJMTtd38JmLDv+MB5iQiT2A5YpllXnQHclLizyhh+Zdkkg+ee/VrTV+r
 5KfV/TFl7h7BGdSKk48dZvSz+COQF6fQbB5vlVk/iSCwzu3kGLi2Wn0
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>

Describe the ten DW APB UARTs with SCMI clocks and their separate APB
and serial resets.

Signed-off-by: Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 arch/riscv/boot/dts/zhihe/a210.dtsi | 160 ++++++++++++++++++++++++++++++++++++
 1 file changed, 160 insertions(+)

diff --git a/arch/riscv/boot/dts/zhihe/a210.dtsi b/arch/riscv/boot/dts/zhihe/a210.dtsi
index 6d85d94f0af1..caa3005830ca 100644
--- a/arch/riscv/boot/dts/zhihe/a210.dtsi
+++ b/arch/riscv/boot/dts/zhihe/a210.dtsi
@@ -353,6 +353,70 @@ mbox_e902: mailbox@320000 {
 			#mbox-cells = <1>;
 		};
 
+		uart0: serial@2014000 {
+			compatible = "zhihe,a210-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x02014000 0x0 0x1000>;
+			clocks = <&scmi_clk A210_CLK_UART_SCLK(0)>,
+				 <&scmi_clk A210_CLK_UART_PCLK(0)>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupt-parent = <&intc>;
+			interrupts = <321 IRQ_TYPE_LEVEL_HIGH>;
+			reg-io-width = <4>;
+			reg-shift = <2>;
+			resets = <&scmi_reset A210_RESET_UART_PRST(0)>,
+				 <&scmi_reset A210_RESET_UART_SRST(0)>;
+
+			status = "disabled";
+		};
+
+		uart1: serial@2015000 {
+			compatible = "zhihe,a210-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x02015000 0x0 0x1000>;
+			clocks = <&scmi_clk A210_CLK_UART_SCLK(1)>,
+				 <&scmi_clk A210_CLK_UART_PCLK(1)>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupt-parent = <&intc>;
+			interrupts = <322 IRQ_TYPE_LEVEL_HIGH>;
+			reg-io-width = <4>;
+			reg-shift = <2>;
+			resets = <&scmi_reset A210_RESET_UART_PRST(1)>,
+				 <&scmi_reset A210_RESET_UART_SRST(1)>;
+
+			status = "disabled";
+		};
+
+		uart2: serial@2016000 {
+			compatible = "zhihe,a210-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x02016000 0x0 0x1000>;
+			clocks = <&scmi_clk A210_CLK_UART_SCLK(2)>,
+				 <&scmi_clk A210_CLK_UART_PCLK(2)>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupt-parent = <&intc>;
+			interrupts = <323 IRQ_TYPE_LEVEL_HIGH>;
+			reg-io-width = <4>;
+			reg-shift = <2>;
+			resets = <&scmi_reset A210_RESET_UART_PRST(2)>,
+				 <&scmi_reset A210_RESET_UART_SRST(2)>;
+
+			status = "disabled";
+		};
+
+		uart3: serial@2017000 {
+			compatible = "zhihe,a210-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x02017000 0x0 0x1000>;
+			clocks = <&scmi_clk A210_CLK_UART_SCLK(3)>,
+				 <&scmi_clk A210_CLK_UART_PCLK(3)>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupt-parent = <&intc>;
+			interrupts = <324 IRQ_TYPE_LEVEL_HIGH>;
+			reg-io-width = <4>;
+			reg-shift = <2>;
+			resets = <&scmi_reset A210_RESET_UART_PRST(3)>,
+				 <&scmi_reset A210_RESET_UART_SRST(3)>;
+
+			status = "disabled";
+		};
+
 		peri1_padctrl: pinctrl@2026000 {
 			compatible = "zhihe,a210-peri1-pinctrl";
 			reg = <0x0 0x02026000 0x0 0x1000>;
@@ -363,6 +427,102 @@ peri1_padctrl: pinctrl@2026000 {
 			status = "disabled";
 		};
 
+		uart4: serial@8401000 {
+			compatible = "zhihe,a210-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x08401000 0x0 0x1000>;
+			clocks = <&scmi_clk A210_CLK_UART_SCLK(4)>,
+				 <&scmi_clk A210_CLK_UART_PCLK(4)>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupt-parent = <&intc>;
+			interrupts = <325 IRQ_TYPE_LEVEL_HIGH>;
+			reg-io-width = <4>;
+			reg-shift = <2>;
+			resets = <&scmi_reset A210_RESET_UART_PRST(4)>,
+				 <&scmi_reset A210_RESET_UART_SRST(4)>;
+
+			status = "disabled";
+		};
+
+		uart5: serial@8402000 {
+			compatible = "zhihe,a210-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x08402000 0x0 0x1000>;
+			clocks = <&scmi_clk A210_CLK_UART_SCLK(5)>,
+				 <&scmi_clk A210_CLK_UART_PCLK(5)>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupt-parent = <&intc>;
+			interrupts = <326 IRQ_TYPE_LEVEL_HIGH>;
+			reg-io-width = <4>;
+			reg-shift = <2>;
+			resets = <&scmi_reset A210_RESET_UART_PRST(5)>,
+				 <&scmi_reset A210_RESET_UART_SRST(5)>;
+
+			status = "disabled";
+		};
+
+		uart6: serial@8403000 {
+			compatible = "zhihe,a210-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x08403000 0x0 0x1000>;
+			clocks = <&scmi_clk A210_CLK_UART_SCLK(6)>,
+				 <&scmi_clk A210_CLK_UART_PCLK(6)>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupt-parent = <&intc>;
+			interrupts = <327 IRQ_TYPE_LEVEL_HIGH>;
+			reg-io-width = <4>;
+			reg-shift = <2>;
+			resets = <&scmi_reset A210_RESET_UART_PRST(6)>,
+				 <&scmi_reset A210_RESET_UART_SRST(6)>;
+
+			status = "disabled";
+		};
+
+		uart7: serial@8404000 {
+			compatible = "zhihe,a210-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x08404000 0x0 0x1000>;
+			clocks = <&scmi_clk A210_CLK_UART_SCLK(7)>,
+				 <&scmi_clk A210_CLK_UART_PCLK(7)>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupt-parent = <&intc>;
+			interrupts = <328 IRQ_TYPE_LEVEL_HIGH>;
+			reg-io-width = <4>;
+			reg-shift = <2>;
+			resets = <&scmi_reset A210_RESET_UART_PRST(7)>,
+				 <&scmi_reset A210_RESET_UART_SRST(7)>;
+
+			status = "disabled";
+		};
+
+		uart8: serial@8405000 {
+			compatible = "zhihe,a210-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x08405000 0x0 0x1000>;
+			clocks = <&scmi_clk A210_CLK_UART_SCLK(8)>,
+				 <&scmi_clk A210_CLK_UART_PCLK(8)>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupt-parent = <&intc>;
+			interrupts = <329 IRQ_TYPE_LEVEL_HIGH>;
+			reg-io-width = <4>;
+			reg-shift = <2>;
+			resets = <&scmi_reset A210_RESET_UART_PRST(8)>,
+				 <&scmi_reset A210_RESET_UART_SRST(8)>;
+
+			status = "disabled";
+		};
+
+		uart9: serial@8406000 {
+			compatible = "zhihe,a210-uart", "snps,dw-apb-uart";
+			reg = <0x0 0x08406000 0x0 0x1000>;
+			clocks = <&scmi_clk A210_CLK_UART_SCLK(9)>,
+				 <&scmi_clk A210_CLK_UART_PCLK(9)>;
+			clock-names = "baudclk", "apb_pclk";
+			interrupt-parent = <&intc>;
+			interrupts = <330 IRQ_TYPE_LEVEL_HIGH>;
+			reg-io-width = <4>;
+			reg-shift = <2>;
+			resets = <&scmi_reset A210_RESET_UART_PRST(9)>,
+				 <&scmi_reset A210_RESET_UART_SRST(9)>;
+
+			status = "disabled";
+		};
+
 		peri2_padctrl: pinctrl@8411000 {
 			compatible = "zhihe,a210-peri2-pinctrl";
 			reg = <0x0 0x08411000 0x0 0x1000>;

-- 
2.55.0

