From: Dang Huynh <dang.huynh@mainlining.org>
Date: Wed, 17 Sep 2025 03:25:11 +0700
Subject: [PATCH 14/25] dt-bindings: power: reset: Add RDA Micro Modem Reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250917-rda8810pl-drivers-v1-14-9ca9184ca977@mainlining.org>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758054322; l=1439;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=Qx3A0YEz2hiOBr1X7Hx7B2Yur/VncHTnIWLD5/fTYjI=;
 b=ZgRTCdZsa4zMPNeOMmGFLo6ICngX1GwmdnktW4A702PqmzxT6psP5W8kdNHEKlVW88+WFP8Gv
 ElMMuGq68W5A4Nx++rKEmZFCTm3eK1x3SrQ1TYSmUBZhC4BLDLaBhGC
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add documentation describing the RDA Micro modem reset controller

Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
 .../bindings/power/reset/rda,md-reset.yaml         | 36 ++++++++++++++++++++++
 1 file changed, 36 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/reset/rda,md-reset.yaml b/Documentation/devicetree/bindings/power/reset/rda,md-reset.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..6d09bc8ee6b257aec9d2c4738d285490044003ea
--- /dev/null
+++ b/Documentation/devicetree/bindings/power/reset/rda,md-reset.yaml
@@ -0,0 +1,36 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/power/reset/rda,md-reset.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: RDA Micro Modem Reset
+
+maintainers:
+  - Dang Huynh <dang.huynh@mainlining.org>
+
+description:
+  The modem has a reset register that can be used to fully reset the board.
+
+  To do that, a magic value needs to be written to unprotect the register,
+  then the soft reset register can be used.
+
+properties:
+  compatible:
+    const: rda,md-reset
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
+    reset-controller@1a00000 {
+      compatible = "rda,md-reset";
+      reg = <0x1a00000 0x4>;
+    };

-- 
2.51.0

