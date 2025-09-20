From: Cristian Cozzolino <cristian_ci@protonmail.com>
Date: Sat, 20 Sep 2025 20:23:35 +0200
Subject: [PATCH 10/10] ARM: dts: mediatek: add basic support for Alcatel
 yarisxl board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250920-mt6582-v1-10-b887720f577d@protonmail.com>
References: <20250920-mt6582-v1-0-b887720f577d@protonmail.com>
In-Reply-To: <20250920-mt6582-v1-0-b887720f577d@protonmail.com>
To: Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Russell King <linux@armlinux.org.uk>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sean Wang <sean.wang@mediatek.com>
Cc: linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, 
 Cristian Cozzolino <cristian_ci@protonmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758392693; l=2470;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=iyYcAwIUuKoaf3t5Jk0wP9oO6VHUo1cct77WwDYuJAM=;
 b=42iTG8Igz4PcR3ipNH7H+GmAzf51vDO+8qD+UElOPoElp7HJMwL0bq4MpcxPzJCGvRv2LIHbF
 2nbdRJ2sa3LBtNJhUSvcN5kR9O7qmc/NFrxPCjYJ+ya/hTKaMKjRVbh
X-Developer-Key: i=cristian_ci@protonmail.com; a=ed25519;
 pk=xH5IvIPUNHV1Q8R0/pq2CfuVFR/wTiAyuyi6IwedjZY=
X-Endpoint-Received: by B4 Relay for cristian_ci@protonmail.com/20250620 with auth_id=438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This smartphone uses a MediaTek MT6582 system-on-chip with 512MB of RAM.
It can currently boot into initramfs with a working UART and
Simple Framebuffer using already initialized panel by the bootloader.

Signed-off-by: Cristian Cozzolino <cristian_ci@protonmail.com>
---
 arch/arm/boot/dts/mediatek/Makefile                |  1 +
 .../boot/dts/mediatek/mt6582-alcatel-yarisxl.dts   | 61 ++++++++++++++++++++++
 2 files changed, 62 insertions(+)

diff --git a/arch/arm/boot/dts/mediatek/Makefile b/arch/arm/boot/dts/mediatek/Makefile
index e48de3efeb3b9ab00108cc28afa8da525d0ec14a..37c4cded0eae8cfcdc61c58fd1d986ae14c3de93 100644
--- a/arch/arm/boot/dts/mediatek/Makefile
+++ b/arch/arm/boot/dts/mediatek/Makefile
@@ -4,6 +4,7 @@ dtb-$(CONFIG_ARCH_MEDIATEK) += \
 	mt6572-jty-d101.dtb \
 	mt6572-lenovo-a369i.dtb \
 	mt6580-evbp1.dtb \
+	mt6582-alcatel-yarisxl.dtb \
 	mt6582-prestigio-pmt5008-3g.dtb \
 	mt6589-aquaris5.dtb \
 	mt6589-fairphone-fp1.dtb \
diff --git a/arch/arm/boot/dts/mediatek/mt6582-alcatel-yarisxl.dts b/arch/arm/boot/dts/mediatek/mt6582-alcatel-yarisxl.dts
new file mode 100644
index 0000000000000000000000000000000000000000..f55d8edad1acfe316ea139e76858833dcdae24fe
--- /dev/null
+++ b/arch/arm/boot/dts/mediatek/mt6582-alcatel-yarisxl.dts
@@ -0,0 +1,61 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2025 Cristian Cozzolino <cristian_ci@protonmail.com>
+ */
+
+/dts-v1/;
+#include "mt6582.dtsi"
+
+/ {
+	model = "Alcatel One Touch Pop C7 (OT-7041D)";
+	compatible = "alcatel,yarisxl", "mediatek,mt6582";
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
+			height = <854>;
+			stride = <(480 * 4)>;
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
+		connsys@9f900000 {
+			reg = <0x9f900000 0x100000>;
+			no-map;
+		};
+
+		modem@9e000000 {
+			reg = <0x9e000000 0x1800000>;
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
2.49.0

