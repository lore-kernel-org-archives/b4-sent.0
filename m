From: Max Shevchenko <wctrl@proton.me>
Date: Fri, 20 Jun 2025 18:40:49 +0300
Subject: [PATCH 10/11] ARM: dts: mediatek: add basic support for JTY D101
 board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250620-mt6572-v1-10-e2d47820f042@proton.me>
References: <20250620-mt6572-v1-0-e2d47820f042@proton.me>
In-Reply-To: <20250620-mt6572-v1-0-e2d47820f042@proton.me>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Thomas Gleixner <tglx@linutronix.de>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Sean Wang <sean.wang@mediatek.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, linux-watchdog@vger.kernel.org, 
 Max Shevchenko <wctrl@proton.me>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750434231; l=2358;
 i=wctrl@proton.me; s=20250603; h=from:subject:message-id;
 bh=okQp4pzksQbwAVarYxmDvovk3WSeUiFA8NPTsCwIRQ0=;
 b=fy95bpb/Xfh299fxSxNw8c1epXw9BD3oGxi84uIgIUG+mRzRw4pvGhKR1ZNV7Fz/xBLHtN265
 qO6IJAcAL/+AYjI8b3yFJW3xVHFJVFrQz+znwamwN1vv0l6wwSrCsUQ
X-Developer-Key: i=wctrl@proton.me; a=ed25519;
 pk=JXUx3mL/OrnRvbK57HXgugBjEBKq4QgDKJqp7BALm74=
X-Endpoint-Received: by B4 Relay for wctrl@proton.me/20250603 with auth_id=421
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This tablet uses a MediaTek MT6572 system-on-chip with 1GB of RAM.
It can currently boot into initramfs with a working UART and
Simple Framebuffer using already initialized panel by the bootloader.

Signed-off-by: Max Shevchenko <wctrl@proton.me>
---
 arch/arm/boot/dts/mediatek/Makefile            |  1 +
 arch/arm/boot/dts/mediatek/mt6572-jty-d101.dts | 62 ++++++++++++++++++++++++++
 2 files changed, 63 insertions(+)

diff --git a/arch/arm/boot/dts/mediatek/Makefile b/arch/arm/boot/dts/mediatek/Makefile
index 1957947cb41ce86ed101466bf822d4e2dfdfbb61..cb869a1aaec21a1d99f7f2a829b84672a3f52726 100644
--- a/arch/arm/boot/dts/mediatek/Makefile
+++ b/arch/arm/boot/dts/mediatek/Makefile
@@ -1,6 +1,7 @@
 # SPDX-License-Identifier: GPL-2.0
 dtb-$(CONFIG_ARCH_MEDIATEK) += \
 	mt2701-evb.dtb \
+	mt6572-jty-d101.dtb \
 	mt6580-evbp1.dtb \
 	mt6582-prestigio-pmt5008-3g.dtb \
 	mt6589-aquaris5.dtb \
diff --git a/arch/arm/boot/dts/mediatek/mt6572-jty-d101.dts b/arch/arm/boot/dts/mediatek/mt6572-jty-d101.dts
new file mode 100644
index 0000000000000000000000000000000000000000..5c3b9833073e43fb42e28719c1f206e8884b5f6a
--- /dev/null
+++ b/arch/arm/boot/dts/mediatek/mt6572-jty-d101.dts
@@ -0,0 +1,62 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2025 Max Shevchenko <wctrl@proton.me>
+ */
+
+/dts-v1/;
+#include "mt6572.dtsi"
+
+/ {
+	model = "JTY D101";
+	compatible = "jty,d101", "mediatek,mt6572";
+
+	aliases {
+		serial0 = &uart0;
+	};
+
+	chosen {
+		#address-cells = <1>;
+		#size-cells = <1>;
+		stdout-path = "serial0:921600n8";
+
+		framebuffer: framebuffer@bf400000 {
+			compatible = "simple-framebuffer";
+			memory-region = <&framebuffer_reserved>;
+			width = <1024>;
+			height = <600>;
+			stride = <(1024 * 2)>;
+			format = "r5g6b5";
+			status = "okay";
+		};
+	};
+
+	memory {
+		device_type = "memory";
+		reg = <0x80000000 0x40000000>;
+	};
+
+	reserved-memory {
+		#address-cells = <1>;
+		#size-cells = <1>;
+		ranges;
+
+		connsys@80000000 {
+			reg = <0x80000000 0x100000>;
+			no-map;
+		};
+
+		modem@be000000 {
+			reg = <0xbe000000 0x1400000>;
+			no-map;
+		};
+
+		framebuffer_reserved: framebuffer@bf400000 {
+			reg = <0xbf400000 0xc00000>;
+			no-map;
+		};
+	};
+};
+
+&uart0 {
+	status = "okay";
+};

-- 
2.50.0

