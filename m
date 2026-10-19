From: Ben Grisdale <bengris32@protonmail.ch>
Date: Mon, 19 Oct 2026 01:40:04 +0100
Subject: [PATCH 8/8] arm64: dts: mediatek: Add Amazon Echo Dot (2016)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-arm64-initial-support-for-mediatek-mt8163-soc-v1-8-f2462b2d2437@protonmail.ch>
References: <20261019-arm64-initial-support-for-mediatek-mt8163-soc-v1-0-f2462b2d2437@protonmail.ch>
In-Reply-To: <20261019-arm64-initial-support-for-mediatek-mt8163-soc-v1-0-f2462b2d2437@protonmail.ch>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@mediatek.com>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-serial@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792370441; l=2808;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=lMdVcco71nADP8HucTPUNLICr3LWil3QPPZ2t6j8t8U=;
 b=p4XX5KEds0C6IcSEby9uWvdCn4txfVKinsxi/2DQ5ZRLYb9RgT70XEdkOHdcYivkPI4/n9b7y
 3p1qPTT6D03AMCILGR/WhFqofuQ/WbM9Q2F+58kZ03UcMaOrEkHGi4P
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a device tree for the Amazon Echo Dot (2nd generation, 2016),
codenamed "biscuit", which is based on the MediaTek MT8163 SoC.

This is enough to boot to a shell over UART0. The UART pins are assumed
to be configured by the bootloader, as there is no pinctrl support yet.

Signed-off-by: Ben Grisdale <bengris32@protonmail.ch>
---
 arch/arm64/boot/dts/mediatek/Makefile              |  1 +
 .../boot/dts/mediatek/mt8163-amazon-biscuit.dts    | 68 ++++++++++++++++++++++
 2 files changed, 69 insertions(+)

diff --git a/arch/arm64/boot/dts/mediatek/Makefile b/arch/arm64/boot/dts/mediatek/Makefile
index a86fb313b1a9..adf02b9f234b 100644
--- a/arch/arm64/boot/dts/mediatek/Makefile
+++ b/arch/arm64/boot/dts/mediatek/Makefile
@@ -92,6 +92,7 @@ mt7988a-bananapi-bpi-r4-pro-8x-sd-cn18-dtbs := \
 	mt7988a-bananapi-bpi-r4-pro-cn13.dtbo \
 	mt7988a-bananapi-bpi-r4-pro-cn18.dtbo
 dtb-$(CONFIG_ARCH_MEDIATEK) += mt7988a-bananapi-bpi-r4-pro-8x-sd-cn18.dtb
+dtb-$(CONFIG_ARCH_MEDIATEK) += mt8163-amazon-biscuit.dtb
 dtb-$(CONFIG_ARCH_MEDIATEK) += mt8167-pumpkin.dtb
 dtb-$(CONFIG_ARCH_MEDIATEK) += mt8173-elm.dtb
 dtb-$(CONFIG_ARCH_MEDIATEK) += mt8173-elm-hana.dtb
diff --git a/arch/arm64/boot/dts/mediatek/mt8163-amazon-biscuit.dts b/arch/arm64/boot/dts/mediatek/mt8163-amazon-biscuit.dts
new file mode 100644
index 000000000000..5fb5d59e4ed2
--- /dev/null
+++ b/arch/arm64/boot/dts/mediatek/mt8163-amazon-biscuit.dts
@@ -0,0 +1,68 @@
+// SPDX-License-Identifier: GPL-2.0-only OR MIT
+/*
+ * Copyright (c) 2026 Ben Grisdale <bengris32@protonmail.ch>
+ */
+
+/dts-v1/;
+#include "mt8163.dtsi"
+
+/ {
+	model = "Amazon Echo Dot (2016)";
+	compatible = "amazon,biscuit", "mediatek,mt8163";
+	chassis-type = "embedded";
+
+	aliases {
+		serial0 = &uart0;
+	};
+
+	chosen {
+		stdout-path = "serial0:921600n8";
+	};
+
+	firmware {
+		optee {
+			compatible = "linaro,optee-tz";
+			method = "smc";
+		};
+	};
+
+	memory@40000000 {
+		device_type = "memory";
+		reg = <0 0x40000000 0 0x20000000>;
+	};
+
+	reserved-memory {
+		ranges;
+		#address-cells = <2>;
+		#size-cells = <2>;
+
+		/* 192 KiB reserved for ARM Trusted Firmware (BL31) */
+		secmon@43000000 {
+			reg = <0 0x43000000 0 0x30000>;
+			no-map;
+		};
+
+		/* 16 KiB reserved for SPM firmware */
+		spm-pcm@43030000 {
+			reg = <0 0x43030000 0 0x4000>;
+			no-map;
+		};
+
+		/*
+		 * 6 MiB reserved for OP-TEE (BL32)
+		 * +-----------------------+ 0x4380_0000
+		 * |      SHMEM 2MiB       |
+		 * +-----------------------+ 0x4360_0000
+		 * |     TZDRAM 4MiB       |
+		 * +-----------------------+ 0x4320_0000
+		 */
+		optee@43200000 {
+			reg = <0 0x43200000 0 0x600000>;
+			no-map;
+		};
+	};
+};
+
+&uart0 {
+	status = "okay";
+};

-- 
2.56.0

