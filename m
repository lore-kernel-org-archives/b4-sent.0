From: Roman Vivchar <rva333@protonmail.com>
Date: Thu, 26 Nov 2026 14:40:01 +0200
Subject: [PATCH 8/8] arm64: dts: mediatek: mt6768: add Xiaomi Redmi Note 9
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-6768-init-v1-8-abc364a2447e@protonmail.com>
References: <20261126-6768-init-v1-0-abc364a2447e@protonmail.com>
In-Reply-To: <20261126-6768-init-v1-0-abc364a2447e@protonmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@mediatek.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-serial@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795696875; l=2173;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=ZShCzvXiUl5hDnYMk19Pl4AsLIEnkMmW90NbhX636XU=;
 b=ViSO2Xd7qbcrP7tQ7Atr+iYYMlaWMHJsqTCykJzxr0uCF8iTh/kzta/JBbCKByfGXu/q+i76N
 xu7CAp2Bv25AX3wx/KMpUMiLnMgY9UoN/v3UswcgIon89zN6d1xOCN9
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Xiaomi Redmi Note 9 is a budget phone released in 2020. It features up to
6 GB of LPDDR4X memory and 128 GB eMMC, powered by the MediaTek Helio G85
SoC.

Add initial devicetree support for this device. It can currently boot to
a UART shell and use the simple-framebuffer provided by U-Boot for
display output.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 arch/arm64/boot/dts/mediatek/Makefile              |  1 +
 .../boot/dts/mediatek/mt6768-xiaomi-merlin.dts     | 42 ++++++++++++++++++++++
 2 files changed, 43 insertions(+)

diff --git a/arch/arm64/boot/dts/mediatek/Makefile b/arch/arm64/boot/dts/mediatek/Makefile
index a86fb313b1a9..4fe50c95321f 100644
--- a/arch/arm64/boot/dts/mediatek/Makefile
+++ b/arch/arm64/boot/dts/mediatek/Makefile
@@ -1,6 +1,7 @@
 # SPDX-License-Identifier: GPL-2.0
 dtb-$(CONFIG_ARCH_MEDIATEK) += mt2712-evb.dtb
 dtb-$(CONFIG_ARCH_MEDIATEK) += mt6755-evb.dtb
+dtb-$(CONFIG_ARCH_MEDIATEK) += mt6768-xiaomi-merlin.dtb
 dtb-$(CONFIG_ARCH_MEDIATEK) += mt6779-evb.dtb
 dtb-$(CONFIG_ARCH_MEDIATEK) += mt6795-evb.dtb
 dtb-$(CONFIG_ARCH_MEDIATEK) += mt6795-sony-xperia-m5.dtb
diff --git a/arch/arm64/boot/dts/mediatek/mt6768-xiaomi-merlin.dts b/arch/arm64/boot/dts/mediatek/mt6768-xiaomi-merlin.dts
new file mode 100644
index 000000000000..f95bac31caf3
--- /dev/null
+++ b/arch/arm64/boot/dts/mediatek/mt6768-xiaomi-merlin.dts
@@ -0,0 +1,42 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (c) 2025-2026 Roman Vivchar <rva333@protonmail.com>
+ */
+
+/dts-v1/;
+#include "mt6768.dtsi"
+
+/ {
+	model = "Xiaomi Redmi Note 9";
+	compatible = "xiaomi,merlin", "mediatek,mt6768";
+	chassis-type = "handset";
+
+	aliases {
+		serial0 = &uart0;
+	};
+
+	chosen {
+		stdout-path = "serial0:921600n8";
+	};
+
+	memory@40000000 {
+		device_type = "memory";
+		reg = <0 0x40000000 0 0>;
+	};
+
+	reserved-memory {
+		ranges;
+		#address-cells = <2>;
+		#size-cells = <2>;
+
+		/* 384 KiB reserved for ARM Trusted Firmware */
+		secmon@4ce00000 {
+			reg = <0 0x4ce00000 0 0x60000>;
+			no-map;
+		};
+	};
+};
+
+&uart0 {
+	status = "okay";
+};

-- 
2.56.1

