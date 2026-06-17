From: Zakariya Hadrami <zkh1@proton.me>
Date: Wed, 17 Jun 2026 22:37:03 +0900
Subject: [PATCH v2 5/5] ARM: dts: mediatek: Add basic support for Amazon
 ford board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260617-mt8127-amazon-ford-basic-v2-5-6859e29e72a8@proton.me>
References: <20260617-mt8127-amazon-ford-basic-v2-0-6859e29e72a8@proton.me>
In-Reply-To: <20260617-mt8127-amazon-ford-basic-v2-0-6859e29e72a8@proton.me>
To: Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sean Wang <sean.wang@mediatek.com>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-watchdog@vger.kernel.org, Zakariya Hadrami <zkh1@proton.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781703437; l=1963;
 i=zkh1@proton.me; s=20260616; h=from:subject:message-id;
 bh=ER3ARswagh7xs80gDU1m6FCsuRFGAreidBmq7cULkdo=;
 b=knrHaSV8cyIhI6j/4ugY3/Y9fieSarHylXmpVc6ygFKsdiQ4KwXfanhfpgRV+kpn/hdia5xyq
 bDT9Q0r/3dMCGrvC55esWdqeKnD0voKHhtsnqGuX5IGgc9T8EevY/vS
X-Developer-Key: i=zkh1@proton.me; a=ed25519;
 pk=9DiJwhINAERP95fbFofXSP77GEnvfO/rMIRRRFDhaoc=
X-Endpoint-Received: by B4 Relay for zkh1@proton.me/20260616 with auth_id=824
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This tablet uses a MediaTek MT8127 system-on-chip with 1GB of RAM.
It can currently boot into initramfs with a working UART and
Simple Framebuffer using already initialized panel by the bootloader.

Signed-off-by: Zakariya Hadrami <zkh1@proton.me>
---
 arch/arm/boot/dts/mediatek/Makefile               |  1 +
 arch/arm/boot/dts/mediatek/mt8127-amazon-ford.dts | 46 +++++++++++++++++++++++
 2 files changed, 47 insertions(+)

diff --git a/arch/arm/boot/dts/mediatek/Makefile b/arch/arm/boot/dts/mediatek/Makefile
index 37c4cded0eae..a610bc75c7d9 100644
--- a/arch/arm/boot/dts/mediatek/Makefile
+++ b/arch/arm/boot/dts/mediatek/Makefile
@@ -14,5 +14,6 @@ dtb-$(CONFIG_ARCH_MEDIATEK) += \
 	mt7623n-rfb-emmc.dtb \
 	mt7623n-bananapi-bpi-r2.dtb \
 	mt7629-rfb.dtb \
+	mt8127-amazon-ford.dtb \
 	mt8127-moose.dtb \
 	mt8135-evbp1.dtb
diff --git a/arch/arm/boot/dts/mediatek/mt8127-amazon-ford.dts b/arch/arm/boot/dts/mediatek/mt8127-amazon-ford.dts
new file mode 100644
index 000000000000..21bdab0e43f8
--- /dev/null
+++ b/arch/arm/boot/dts/mediatek/mt8127-amazon-ford.dts
@@ -0,0 +1,46 @@
+// SPDX-License-Identifier: GPL-2.0
+
+/dts-v1/;
+#include "mt8127.dtsi"
+
+/ {
+	model = "MediaTek MT8127 Amazon Ford";
+	compatible = "amazon,ford", "mediatek,mt8127";
+
+	aliases {
+		serial0 = &uart0;
+	};
+
+	chosen {
+		stdout-path = "serial0:921600n8";
+
+		framebuffer0: framebuffer@b7a00000 {
+			compatible = "simple-framebuffer";
+			memory-region = <&framebuffer_reserved>;
+			width = <1024>;
+			height = <600>;
+			stride = <(1024 * 2)>;
+			format = "r5g6b5";
+		};
+	};
+
+	memory@80000000 {
+		device_type = "memory";
+		reg = <0 0x80000000 0 0x40000000>;
+	};
+
+	reserved-memory {
+		framebuffer_reserved: framebuffer@b7a00000 {
+			reg = <0 0xb7a00000 0 0x1000000>;
+			no-map;
+		};
+	};
+};
+
+&uart0 {
+	status = "okay";
+};
+
+&watchdog {
+	status = "okay";
+};

-- 
2.54.0

