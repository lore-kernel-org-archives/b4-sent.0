From: Han Gao <gaohan@iscas.ac.cn>
Date: Wed, 18 Nov 2026 03:55:32 +0800
Subject: [PATCH 2/2] riscv: dts: eswin: Add Milk-V Megrez board
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-eic7700-megrez-v1-2-af8334b88336@iscas.ac.cn>
References: <20261118-eic7700-megrez-v1-0-af8334b88336@iscas.ac.cn>
In-Reply-To: <20261118-eic7700-megrez-v1-0-af8334b88336@iscas.ac.cn>
To: Min Lin <linmin@eswincomputing.com>, 
 Pinkesh Vaghela <pinkesh.vaghela@einfochips.com>, 
 Pritesh Patel <pritesh.patel@einfochips.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: Han Gao <rabenda.cn@gmail.com>, devicetree@vger.kernel.org, 
 linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794945342; l=1608;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=5UoIVWI3E0hRT2YTxV7p/RQ7wPueg9djF6ac68d/O7I=;
 b=eOiA75gawpPq6IKE0fE092dhk/5ohmTbM2e6yYWxs8B5o12sKpTdTytekzbghUGprexUcXV2/
 kYp9Q3p8HGUCjJyWfM4grO9eA14GhpgsbMN+/u0c2ajp2Fc+MspDRCW
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Milk-V Megrez is a Mini-ITX board based on the ESWIN EIC7700X SoC.

Add a minimal device tree that enables UART0, which is connected to the
USB-C debug port through a CH340 USB-to-UART bridge, and use it as the
serial console.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 arch/riscv/boot/dts/eswin/Makefile                 |  1 +
 arch/riscv/boot/dts/eswin/eic7700-milkv-megrez.dts | 25 ++++++++++++++++++++++
 2 files changed, 26 insertions(+)

diff --git a/arch/riscv/boot/dts/eswin/Makefile b/arch/riscv/boot/dts/eswin/Makefile
index 224101ae471e8d89996f7cbfc616425f704af37e..5daade822e15eda43eee111cbf89bc386bb06f32 100644
--- a/arch/riscv/boot/dts/eswin/Makefile
+++ b/arch/riscv/boot/dts/eswin/Makefile
@@ -1,2 +1,3 @@
 # SPDX-License-Identifier: GPL-2.0
 dtb-$(CONFIG_ARCH_ESWIN) += eic7700-hifive-premier-p550.dtb
+dtb-$(CONFIG_ARCH_ESWIN) += eic7700-milkv-megrez.dtb
diff --git a/arch/riscv/boot/dts/eswin/eic7700-milkv-megrez.dts b/arch/riscv/boot/dts/eswin/eic7700-milkv-megrez.dts
new file mode 100644
index 0000000000000000000000000000000000000000..2ca6d36c5edca271381b677ab14e9a459fdaafce
--- /dev/null
+++ b/arch/riscv/boot/dts/eswin/eic7700-milkv-megrez.dts
@@ -0,0 +1,25 @@
+// SPDX-License-Identifier: (GPL-2.0 OR MIT)
+/*
+ * Copyright (c) 2026 Han Gao
+ */
+
+/dts-v1/;
+
+#include "eic7700.dtsi"
+
+/ {
+	compatible = "milkv,megrez", "eswin,eic7700";
+	model = "Milk-V Megrez";
+
+	aliases {
+		serial0 = &uart0;
+	};
+
+	chosen {
+		stdout-path = "serial0:115200n8";
+	};
+};
+
+&uart0 {
+	status = "okay";
+};

-- 
2.47.3

