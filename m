From: Enzo Adriano <enzo.adriano.code@gmail.com>
Date: Sat, 13 Jun 2026 05:42:16 -0400
Subject: [PATCH 4/4] arm64: dts: allwinner: add Radxa Cubie A7S
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260613-a733-dts-v1-public-ready-v1-4-7787c94681db@gmail.com>
References: <20260613-a733-dts-v1-public-ready-v1-0-7787c94681db@gmail.com>
In-Reply-To: <20260613-a733-dts-v1-public-ready-v1-0-7787c94681db@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>, 
 Ulf Hansson <ulfh@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-mmc@vger.kernel.org, Enzo Adriano <enzo.adriano.code@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781343732; l=2364;
 i=enzo.adriano.code@gmail.com; s=a733-cubie-a7s; h=from:subject:message-id;
 bh=WglawFMrtY9x8pOjuPdnu6SXc40mYnW0SaPFITAFqtE=;
 b=GbPhqn66Lz40aOjXStKHF233v3bsLzM1ml6LsXpvkrLn92HN/jl3uoeOECLYFwLIOOTvAKgWs
 elncJREMxH/DYHkJnIGC2PGIqP1I/hQiHA0jjrPTsST7XrK6bualNwq
X-Developer-Key: i=enzo.adriano.code@gmail.com; a=ed25519;
 pk=5S3Wmdqa4XfCdeZF/HfeYqnQF8GN9JGt3SE1cxqSX8E=
X-Endpoint-Received: by B4 Relay for enzo.adriano.code@gmail.com/a733-cubie-a7s with auth_id=820
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Radxa Cubie A7S board description with serial console and SD card
boot support.

Ethernet remains disabled until the GMAC210 wrapper, clocks, resets,
MDIO, PHY reset, PHY power, and link behavior are proven.

Signed-off-by: Enzo Adriano <enzo.adriano.code@gmail.com>
---
 arch/arm64/boot/dts/allwinner/Makefile             |  1 +
 .../boot/dts/allwinner/sun60i-a733-cubie-a7s.dts   | 48 ++++++++++++++++++++++
 2 files changed, 49 insertions(+)

diff --git a/arch/arm64/boot/dts/allwinner/Makefile b/arch/arm64/boot/dts/allwinner/Makefile
index d116864b6c2b..824cc35152db 100644
--- a/arch/arm64/boot/dts/allwinner/Makefile
+++ b/arch/arm64/boot/dts/allwinner/Makefile
@@ -56,6 +56,7 @@ dtb-$(CONFIG_ARCH_SUNXI) += sun50i-h700-anbernic-rg35xx-2024.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun50i-h700-anbernic-rg35xx-h.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun50i-h700-anbernic-rg35xx-plus.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun50i-h700-anbernic-rg35xx-sp.dtb
+dtb-$(CONFIG_ARCH_SUNXI) += sun60i-a733-cubie-a7s.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun55i-a527-cubie-a5e.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun55i-h728-x96qpro+.dtb
 dtb-$(CONFIG_ARCH_SUNXI) += sun55i-t527-avaota-a1.dtb
diff --git a/arch/arm64/boot/dts/allwinner/sun60i-a733-cubie-a7s.dts b/arch/arm64/boot/dts/allwinner/sun60i-a733-cubie-a7s.dts
new file mode 100644
index 000000000000..453761a96323
--- /dev/null
+++ b/arch/arm64/boot/dts/allwinner/sun60i-a733-cubie-a7s.dts
@@ -0,0 +1,48 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR MIT)
+
+/dts-v1/;
+
+#include "sun60i-a733.dtsi"
+
+/ {
+	model = "Radxa Cubie A7S";
+	compatible = "radxa,cubie-a7s", "allwinner,sun60i-a733";
+
+	aliases {
+		serial0 = &uart0;
+		mmc0 = &mmc0;
+	};
+
+	chosen {
+		stdout-path = "serial0:115200n8";
+	};
+
+	reg_vcc3v3: vcc3v3 {
+		compatible = "regulator-fixed";
+		regulator-name = "vcc-3v3";
+		regulator-min-microvolt = <3300000>;
+		regulator-max-microvolt = <3300000>;
+		regulator-always-on;
+	};
+};
+
+&mmc0 {
+	vmmc-supply = <&reg_vcc3v3>;
+	bus-width = <4>;
+	no-mmc;
+	no-sdio;
+	status = "okay";
+};
+
+&pio {
+	uart0_pb9_pb10_pins: uart0-pb9-pb10-pins {
+		pins = "PB9", "PB10";
+		function = "uart0";
+	};
+};
+
+&uart0 {
+	pinctrl-names = "default";
+	pinctrl-0 = <&uart0_pb9_pb10_pins>;
+	status = "okay";
+};

-- 
2.53.0

