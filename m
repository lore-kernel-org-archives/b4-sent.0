From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Wed, 11 Dec 2024 09:04:39 +0100
Subject: [PATCH net-next v2 1/2] dt-bindings: net: dp83822: Add support for
 GPIO2 clock output
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241211-dp83822-gpio2-clk-out-v2-1-614a54f6acab@liebherr.com>
References: <20241211-dp83822-gpio2-clk-out-v2-0-614a54f6acab@liebherr.com>
In-Reply-To: <20241211-dp83822-gpio2-clk-out-v2-0-614a54f6acab@liebherr.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Davis <afd@ti.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733904292; l=2015;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=UwvludAxxAD5J0tfbp9WDwPSofbmqEDrg/Gfp7I54q8=;
 b=aaFtX/2uzrz07LlMHrp6aXO+OB5NYErym0t0TQvVgO7y0REfZGWQGKft5dOIyd1ABr9fCry/R
 lk/zcVqmv1CCJf1MPRBA4wMFF8JWpMkC0HXXYmoSVVM3u+oAzPubNfD
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The GPIO2 pin on the DP83822 can be configured as clock output. Add
binding to support this feature.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 .../devicetree/bindings/net/ti,dp83822.yaml         |  7 +++++++
 include/dt-bindings/net/ti-dp83822.h                | 21 +++++++++++++++++++++
 2 files changed, 28 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/ti,dp83822.yaml b/Documentation/devicetree/bindings/net/ti,dp83822.yaml
index 784866ea392b2083e93d8dc9aaea93b70dc80934..4a4dc794f21162c6a61c3daeeffa08e666034679 100644
--- a/Documentation/devicetree/bindings/net/ti,dp83822.yaml
+++ b/Documentation/devicetree/bindings/net/ti,dp83822.yaml
@@ -96,6 +96,13 @@ properties:
       - master
       - slave
 
+  ti,gpio2-clk-out:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description: |
+       DP83822 PHY only.
+       Muxing option for GPIO2 pin. See dt-bindings/net/ti-dp83822.h for
+       applicable values. When omitted, the PHY's default will be left as is.
+
 required:
   - reg
 
diff --git a/include/dt-bindings/net/ti-dp83822.h b/include/dt-bindings/net/ti-dp83822.h
new file mode 100644
index 0000000000000000000000000000000000000000..d569c90618b7bcae9ffe44eb041f7dae2e74e5d1
--- /dev/null
+++ b/include/dt-bindings/net/ti-dp83822.h
@@ -0,0 +1,21 @@
+/* SPDX-License-Identifier: GPL-2.0-only OR MIT */
+/*
+ * Device Tree constants for the Texas Instruments DP83822 PHY
+ *
+ * Copyright (C) 2024 Liebherr-Electronics and Drives GmbH
+ *
+ * Author: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
+ */
+
+#ifndef _DT_BINDINGS_TI_DP83822_H
+#define _DT_BINDINGS_TI_DP83822_H
+
+/* IO_MUX_GPIO_CTRL - Clock source selection */
+#define DP83822_CLK_SRC_MAC_IF			0x0
+#define DP83822_CLK_SRC_XI			0x1
+#define DP83822_CLK_SRC_INT_REF			0x2
+#define DP83822_CLK_SRC_RMII_MASTER_MODE_REF	0x4
+#define DP83822_CLK_SRC_FREE_RUNNING		0x6
+#define DP83822_CLK_SRC_RECOVERED		0x7
+
+#endif

-- 
2.39.5

