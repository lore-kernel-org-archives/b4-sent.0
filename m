From: Dang Huynh <dang.huynh@mainlining.org>
Date: Wed, 17 Sep 2025 03:25:02 +0700
Subject: [PATCH 05/25] dt-bindings: rtc: Add RDA Micro RDA8810PL RTC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250917-rda8810pl-drivers-v1-5-9ca9184ca977@mainlining.org>
References: <20250917-rda8810pl-drivers-v1-0-9ca9184ca977@mainlining.org>
In-Reply-To: <20250917-rda8810pl-drivers-v1-0-9ca9184ca977@mainlining.org>
To: Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Sebastian Reichel <sre@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Ulf Hansson <ulf.hansson@linaro.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-unisoc@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-rtc@vger.kernel.org, 
 linux-clk@vger.kernel.org, linux-pm@vger.kernel.org, 
 dmaengine@vger.kernel.org, linux-hardening@vger.kernel.org, 
 linux-mmc@vger.kernel.org, Dang Huynh <dang.huynh@mainlining.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758054322; l=1198;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=WXHBrmFovBDD+aODYzMgHF0ddvJv66eaBAA1wb46O10=;
 b=1AWpjOVHeC7A/fG05V5076Du73/ixlPO3tOlVdOzwByzDZgvNmGQVQIvJBjfRQdO6qHjcr8dk
 nUyBOunSsouDcKxdzeqOCwhm+B7f/3Zy6jwd0Awas0NtAUvq1ASF3OD
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add documentation describing the RTC found in RDA8810PL SoC.

Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
 .../devicetree/bindings/rtc/rda,8810pl-rtc.yaml    | 30 ++++++++++++++++++++++
 1 file changed, 30 insertions(+)

diff --git a/Documentation/devicetree/bindings/rtc/rda,8810pl-rtc.yaml b/Documentation/devicetree/bindings/rtc/rda,8810pl-rtc.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..3ceae294921cc3211cd775d9b3890393196faf82
--- /dev/null
+++ b/Documentation/devicetree/bindings/rtc/rda,8810pl-rtc.yaml
@@ -0,0 +1,30 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/rtc/rda,8810pl-rtc.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: RDA Micro RDA8810PL Real Time Clock
+
+maintainers:
+  - Dang Huynh <dang.huynh@mainlining.org>
+
+properties:
+  compatible:
+    const: rda,8810pl-rtc
+
+  reg:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+
+additionalProperties: false
+
+examples:
+  - |
+    rtc@1a06000 {
+      compatible = "rda,8810pl-rtc";
+      reg = <0x1a06000 0x1000>;
+    };

-- 
2.51.0

