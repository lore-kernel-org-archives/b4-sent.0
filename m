From: Han Gao <gaohan@iscas.ac.cn>
Date: Thu, 22 Oct 2026 03:53:36 +0800
Subject: [PATCH 16/18] riscv: dts: zhihe: add Melon Pi V1 and V2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-a210-init-v1-16-5e438f972d24@iscas.ac.cn>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792612403; l=3373;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=d7EQ/ktNo91zzKNFOZe9hjNhsdudvjM2D+e3uwJCWhM=;
 b=oVD0qw8r10190p6klC89dQf262fZpx98MsZZcYGgbrQzTu/FkSzcf0OaLgBMMnCg7PaKELHL8
 LomIEnurCukDKe419PE11+euyzvZkqE+Vpn9G+AmN4pioudra1vlMcj
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Melon Pi V1 and V2 with the UART4 console on GPIO2_0 and GPIO2_1.
Use serial aliases to preserve physical UART numbering.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 arch/riscv/boot/dts/Makefile                       |  1 +
 arch/riscv/boot/dts/zhihe/Makefile                 |  2 +
 arch/riscv/boot/dts/zhihe/a210-melonpi-common.dtsi | 55 ++++++++++++++++++++++
 arch/riscv/boot/dts/zhihe/a210-melonpi-v1.dts      |  9 ++++
 arch/riscv/boot/dts/zhihe/a210-melonpi-v2.dts      |  9 ++++
 5 files changed, 76 insertions(+)

diff --git a/arch/riscv/boot/dts/Makefile b/arch/riscv/boot/dts/Makefile
index 69d8751fb17c..445edde8f107 100644
--- a/arch/riscv/boot/dts/Makefile
+++ b/arch/riscv/boot/dts/Makefile
@@ -12,3 +12,4 @@ subdir-y += spacemit
 subdir-y += starfive
 subdir-y += tenstorrent
 subdir-y += thead
+subdir-y += zhihe
diff --git a/arch/riscv/boot/dts/zhihe/Makefile b/arch/riscv/boot/dts/zhihe/Makefile
new file mode 100644
index 000000000000..553102091d4f
--- /dev/null
+++ b/arch/riscv/boot/dts/zhihe/Makefile
@@ -0,0 +1,2 @@
+# SPDX-License-Identifier: GPL-2.0
+dtb-$(CONFIG_ARCH_ZHIHE) += a210-melonpi-v1.dtb a210-melonpi-v2.dtb
diff --git a/arch/riscv/boot/dts/zhihe/a210-melonpi-common.dtsi b/arch/riscv/boot/dts/zhihe/a210-melonpi-common.dtsi
new file mode 100644
index 000000000000..7a6e6af0aa1f
--- /dev/null
+++ b/arch/riscv/boot/dts/zhihe/a210-melonpi-common.dtsi
@@ -0,0 +1,55 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+
+#include "a210-som.dtsi"
+
+/ {
+	aliases {
+		serial0 = &uart0;
+		serial1 = &uart1;
+		serial2 = &uart2;
+		serial3 = &uart3;
+		serial4 = &uart4;
+		serial5 = &uart5;
+		serial6 = &uart6;
+		serial7 = &uart7;
+		serial8 = &uart8;
+		serial9 = &uart9;
+	};
+
+	chosen {
+		stdout-path = "serial4:115200n8";
+	};
+};
+
+&peri2_padctrl {
+	status = "okay";
+
+	uart4_pins: uart4-0 {
+		rx-pins {
+			bias-disable;
+			drive-strength = <1>;
+			function = "uart4";
+			input-enable;
+			input-schmitt-enable;
+			pins = "GPIO2_1";
+			slew-rate = <0>;
+		};
+
+		tx-pins {
+			bias-disable;
+			drive-strength = <3>;
+			function = "uart4";
+			input-disable;
+			input-schmitt-disable;
+			pins = "GPIO2_0";
+			slew-rate = <0>;
+		};
+	};
+};
+
+&uart4 {
+	pinctrl-0 = <&uart4_pins>;
+	pinctrl-names = "default";
+
+	status = "okay";
+};
diff --git a/arch/riscv/boot/dts/zhihe/a210-melonpi-v1.dts b/arch/riscv/boot/dts/zhihe/a210-melonpi-v1.dts
new file mode 100644
index 000000000000..a88e9b949c4a
--- /dev/null
+++ b/arch/riscv/boot/dts/zhihe/a210-melonpi-v1.dts
@@ -0,0 +1,9 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+/dts-v1/;
+
+#include "a210-melonpi-common.dtsi"
+
+/ {
+	compatible = "zhihe,a210-melonpi-v1", "zhihe,a210-som", "zhihe,a210";
+	model = "Melon Pi V1";
+};
diff --git a/arch/riscv/boot/dts/zhihe/a210-melonpi-v2.dts b/arch/riscv/boot/dts/zhihe/a210-melonpi-v2.dts
new file mode 100644
index 000000000000..71752471c5fb
--- /dev/null
+++ b/arch/riscv/boot/dts/zhihe/a210-melonpi-v2.dts
@@ -0,0 +1,9 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+/dts-v1/;
+
+#include "a210-melonpi-common.dtsi"
+
+/ {
+	compatible = "zhihe,a210-melonpi-v2", "zhihe,a210-som", "zhihe,a210";
+	model = "Melon Pi V2";
+};

-- 
2.55.0

