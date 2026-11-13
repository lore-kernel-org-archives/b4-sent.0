From: Han Gao <gaohan@iscas.ac.cn>
Date: Sat, 14 Nov 2026 06:33:44 +0800
Subject: [PATCH 18/19] riscv: dts: allwinner: add the YuzukiHD Avaota F2
 board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-v861-v1-18-eb71ec3ee523@iscas.ac.cn>
References: <20261114-v861-v1-0-eb71ec3ee523@iscas.ac.cn>
In-Reply-To: <20261114-v861-v1-0-eb71ec3ee523@iscas.ac.cn>
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Guo Ren <guoren@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, Han Gao <gaohan@iscas.ac.cn>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Maxime Ripard <mripard@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: Han Gao <rabenda.cn@gmail.com>, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 devicetree@vger.kernel.org, linux-csky@vger.kernel.org, 
 linux-sunxi@lists.linux.dev, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rtc@vger.kernel.org, 
 linux-gpio@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794609209; l=2024;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=KqCPsLCb1dJ4aF8ZRP+gwHxIPe0+kCAp6k+KqhGB/tU=;
 b=JAcotxw+M6j30G6Y+hS6IIthgJBH9a0dFcYqiLwL8VfrQYXbseALNWB7FyvsQlLFdrq1ifsfd
 XTqr4BlvW/tAFUhX0NaT1c1hZjH3ZcIUsvJ3w2wYbmlHtGbMZ+QCYs9
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the YuzukiHD Avaota F2, a V861 board, with its memory and serial
console.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 arch/riscv/boot/dts/allwinner/Makefile             |  1 +
 .../boot/dts/allwinner/sun252i-v861-avaota-f2.dts  | 43 ++++++++++++++++++++++
 2 files changed, 44 insertions(+)

diff --git a/arch/riscv/boot/dts/allwinner/Makefile b/arch/riscv/boot/dts/allwinner/Makefile
index 1c91be38ea16..725919d9a4af 100644
--- a/arch/riscv/boot/dts/allwinner/Makefile
+++ b/arch/riscv/boot/dts/allwinner/Makefile
@@ -9,3 +9,4 @@ dtb-$(CONFIG_ARCH_SUNXI) += sun20i-d1-lichee-rv.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun20i-d1-mangopi-mq-pro.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun20i-d1-nezha.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun20i-d1s-mangopi-mq.dtb
+dtb-$(CONFIG_ARCH_SUNXI) += sun252i-v861-avaota-f2.dtb
diff --git a/arch/riscv/boot/dts/allwinner/sun252i-v861-avaota-f2.dts b/arch/riscv/boot/dts/allwinner/sun252i-v861-avaota-f2.dts
new file mode 100644
index 000000000000..e3f5e6c8d350
--- /dev/null
+++ b/arch/riscv/boot/dts/allwinner/sun252i-v861-avaota-f2.dts
@@ -0,0 +1,43 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR MIT)
+/* Copyright (c) 2026 Han Gao <gaohan@iscas.ac.cn> */
+
+/dts-v1/;
+
+#include "sun252i-v861.dtsi"
+
+/ {
+	model = "Avaota F2";
+	compatible = "yuzukihd,avaota-f2", "allwinner,sun252i-v861";
+
+	aliases {
+		serial0 = &uart0;
+	};
+
+	chosen {
+		stdout-path = "serial0:115200n8";
+	};
+
+	/* U-Boot updates this node with the detected DRAM capacity. */
+	memory@40000000 {
+		device_type = "memory";
+		reg = <0 0x40000000 0 0x08000000>;
+	};
+
+	reg_vcc3v3: regulator-vcc3v3 {
+		compatible = "regulator-fixed";
+		regulator-name = "vcc-3v3";
+		regulator-min-microvolt = <3300000>;
+		regulator-max-microvolt = <3300000>;
+		regulator-always-on;
+	};
+};
+
+&pio {
+	vcc-ph-supply = <&reg_vcc3v3>;
+};
+
+&uart0 {
+	pinctrl-names = "default";
+	pinctrl-0 = <&uart0_ph_pins>;
+	status = "okay";
+};

-- 
2.55.0

