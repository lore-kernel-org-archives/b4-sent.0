From: Max Shevchenko <wctrl@proton.me>
Date: Wed, 02 Jul 2025 13:50:48 +0300
Subject: [PATCH v4 11/11] ARM: dts: mediatek: add basic support for Lenovo
 A369i board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250702-mt6572-v4-11-bde75b7ed445@proton.me>
References: <20250702-mt6572-v4-0-bde75b7ed445@proton.me>
In-Reply-To: <20250702-mt6572-v4-0-bde75b7ed445@proton.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751453439; l=2286;
 i=wctrl@proton.me; s=20250603; h=from:subject:message-id;
 bh=cSF9eZIt0ahAcZ8kbC8s+MIavsF7xQD8XUFp0/jFhXo=;
 b=/UEsSb1IOhetvvsPFiJD6SfiHCFEL5djSc+n11Xf9gq2rvx8j5dJmu1ik2vqtj1UdXXa8DQAn
 g9TCyjSOuNqD1AI+7FERwQAMV0ja031hm52qk8N5Q4BSid9bsMLWMPn
X-Developer-Key: i=wctrl@proton.me; a=ed25519;
 pk=JXUx3mL/OrnRvbK57HXgugBjEBKq4QgDKJqp7BALm74=
X-Endpoint-Received: by B4 Relay for wctrl@proton.me/20250603 with auth_id=421
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This smartphone uses a MediaTek MT6572 system-on-chip with 512MB of RAM.
It can currently boot into initramfs with a working UART and
Simple Framebuffer using already initialized panel by the bootloader.

Signed-off-by: Max Shevchenko <wctrl@proton.me>
---
 arch/arm/boot/dts/mediatek/Makefile                |  1 +
 arch/arm/boot/dts/mediatek/mt6572-lenovo-a369i.dts | 56 ++++++++++++++++++++++
 2 files changed, 57 insertions(+)

diff --git a/arch/arm/boot/dts/mediatek/Makefile b/arch/arm/boot/dts/mediatek/Makefile
index cb869a1aaec21a1d99f7f2a829b84672a3f52726..e48de3efeb3b9ab00108cc28afa8da525d0ec14a 100644
--- a/arch/arm/boot/dts/mediatek/Makefile
+++ b/arch/arm/boot/dts/mediatek/Makefile
@@ -2,6 +2,7 @@
 dtb-$(CONFIG_ARCH_MEDIATEK) += \
 	mt2701-evb.dtb \
 	mt6572-jty-d101.dtb \
+	mt6572-lenovo-a369i.dtb \
 	mt6580-evbp1.dtb \
 	mt6582-prestigio-pmt5008-3g.dtb \
 	mt6589-aquaris5.dtb \
diff --git a/arch/arm/boot/dts/mediatek/mt6572-lenovo-a369i.dts b/arch/arm/boot/dts/mediatek/mt6572-lenovo-a369i.dts
new file mode 100644
index 0000000000000000000000000000000000000000..c2f0c60ea777432f19d51ec7d0038bfa05d7170f
--- /dev/null
+++ b/arch/arm/boot/dts/mediatek/mt6572-lenovo-a369i.dts
@@ -0,0 +1,56 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2025 Max Shevchenko <wctrl@proton.me>
+ */
+
+/dts-v1/;
+#include "mt6572.dtsi"
+
+/ {
+	model = "Lenovo A369i";
+	compatible = "lenovo,a369i", "mediatek,mt6572";
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
+		framebuffer: framebuffer@9fa00000 {
+			compatible = "simple-framebuffer";
+			memory-region = <&framebuffer_reserved>;
+			width = <480>;
+			height = <800>;
+			stride = <(480 * 2)>;
+			format = "r5g6b5";
+		};
+	};
+
+	memory@80000000 {
+		device_type = "memory";
+		reg = <0x80000000 0x20000000>;
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
+		framebuffer_reserved: framebuffer@9fa00000 {
+			reg = <0x9fa00000 0x600000>;
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

