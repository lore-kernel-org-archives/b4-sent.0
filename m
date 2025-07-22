From: Mahesh Rao <mahesh.rao@altera.com>
Date: Tue, 22 Jul 2025 23:07:52 +0800
Subject: [PATCH 2/4] dts: stratix10: Add support for SDM mailbox interrupt
 for Intel Stratix10 SoC FPGA.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250722-sip_svc_irq-v1-2-c5b9e02c1ce6@altera.com>
References: <20250722-sip_svc_irq-v1-0-c5b9e02c1ce6@altera.com>
In-Reply-To: <20250722-sip_svc_irq-v1-0-c5b9e02c1ce6@altera.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dinh Nguyen <dinguyen@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mahesh Rao <mahesh.rao@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753196946; l=1326;
 i=mahesh.rao@altera.com; s=20250107; h=from:subject:message-id;
 bh=EyWFuPMqdroUgCXWZr6rl+Afig+2qBq3MLf9ty0RfNw=;
 b=hPx+iNGCXFxdYOfVUDxINu9LBG9KDVYy8r+6gnqauneL9xWveBSxoby7xpa16PvXLQedrMGJU
 IazOx9B17ItDm1Hb2CVlX7YpjU/noFyTdjsje6zN2wZq5e6X1NL5GfQ
X-Developer-Key: i=mahesh.rao@altera.com; a=ed25519;
 pk=tQiFUzoKxHrQLDtWeEeaeTeJTl/UfclUHWZy1fjSiyg=
X-Endpoint-Received: by B4 Relay for mahesh.rao@altera.com/20250107 with auth_id=337
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for Secure Device Manager (SDM) mailbox
doorbell interrupt on Stratix10 SoC FPGA for
supporting asynchronous transactions.

Signed-off-by: Mahesh Rao <mahesh.rao@altera.com>
---
 arch/arm64/boot/dts/altera/socfpga_stratix10.dtsi | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/arm64/boot/dts/altera/socfpga_stratix10.dtsi b/arch/arm64/boot/dts/altera/socfpga_stratix10.dtsi
index 0def0b0daaf73101362eb13e0db5901c6ade06e1..9699b3fe79c89c0af0d00e8f1a5548707d01539d 100644
--- a/arch/arm64/boot/dts/altera/socfpga_stratix10.dtsi
+++ b/arch/arm64/boot/dts/altera/socfpga_stratix10.dtsi
@@ -1,11 +1,13 @@
 // SPDX-License-Identifier: GPL-2.0-only
 /*
  * Copyright Altera Corporation (C) 2015. All rights reserved.
+ * Copyright (C) 2025, Altera Corporation
  */
 
 /dts-v1/;
 #include <dt-bindings/reset/altr,rst-mgr-s10.h>
 #include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/interrupt-controller/arm-gic.h>
 #include <dt-bindings/clock/stratix10-clock.h>
 
 / {
@@ -74,6 +76,8 @@ svc {
 			compatible = "intel,stratix10-svc";
 			method = "smc";
 			memory-region = <&service_reserved>;
+			interrupts = <GIC_SPI 0 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-parent = <&intc>;
 
 			fpga_mgr: fpga-mgr {
 				compatible = "intel,stratix10-soc-fpga-mgr";

-- 
2.35.3

