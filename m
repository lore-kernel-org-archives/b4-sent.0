From: Cody Kang <codykang.hk@gmail.com>
Date: Sat, 25 Jul 2026 00:51:11 -0400
Subject: [PATCH RESEND 02/17] dt-bindings: phy: add SpacemiT K3 Innosilicon
 DP PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260725-k3-display-v1-2-6de34d80e86c@gmail.com>
References: <20260725-k3-display-v1-0-6de34d80e86c@gmail.com>
In-Reply-To: <20260725-k3-display-v1-0-6de34d80e86c@gmail.com>
To: David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Yixun Lan <dlan@kernel.org>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Haylen Chu <heylenay@4d2.org>, Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: dri-devel@lists.freedesktop.org, linux-riscv@lists.infradead.org, 
 devicetree@vger.kernel.org, spacemit@lists.linux.dev, 
 linux-kernel@vger.kernel.org, linux-phy@lists.infradead.org, 
 linux-clk@vger.kernel.org, Cody Kang <codykang.hk@gmail.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784955080; l=2331;
 i=codykang.hk@gmail.com; s=codykang; h=from:subject:message-id;
 bh=xr0oQcfFPCJzaAeEJhH42CRWzbYWKnP3e2i7y0AjEKQ=;
 b=5SvNVVr58XiRYnVJORW96i5uRgcBnJtyJxdzAgLmdpTlgOoI4aHgXlZ/gGLz1ej06AA6XrI4E
 Rhnuba+0KFGD2QOWi+v4UrsLzPVvHeTHKjWsn/RZ8PasuwLQLQFcrIm
X-Developer-Key: i=codykang.hk@gmail.com; a=ed25519;
 pk=Osn6/cs9Su/mHHw4P19cmVc3v2FMQfiWahjsN0vEkuk=
X-Endpoint-Received: by B4 Relay for codykang.hk@gmail.com/codykang with auth_id=895
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SpacemiT K3 DisplayPort controller drives its four transmit lanes
through an integrated Innosilicon DP PHY, one PHY per controller. Add a
binding so the controller can reference its transmit PHY and the pixel
clock the PHY's PLL sources.

The PHY's registers are interleaved with its parent controller's inside
one MMIO window, so it owns neither a reg nor a reset and is modelled as
a child of the controller.

It exposes its PLL-generated pixel clock through #clock-cells, so the
APMU pixel-clock mux can select it as a parent through the clock
framework.

Signed-off-by: Cody Kang <codykang.hk@gmail.com>
---
 .../bindings/phy/spacemit,k3-inno-dp-phy.yaml      | 48 ++++++++++++++++++++++
 1 file changed, 48 insertions(+)

diff --git a/Documentation/devicetree/bindings/phy/spacemit,k3-inno-dp-phy.yaml b/Documentation/devicetree/bindings/phy/spacemit,k3-inno-dp-phy.yaml
new file mode 100644
index 000000000000..f8f1ef372951
--- /dev/null
+++ b/Documentation/devicetree/bindings/phy/spacemit,k3-inno-dp-phy.yaml
@@ -0,0 +1,48 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/phy/spacemit,k3-inno-dp-phy.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: SpacemiT K3 Innosilicon DisplayPort PHY
+
+maintainers:
+  - Cody Kang <codykang.hk@gmail.com>
+
+description:
+  Innosilicon four-lane DisplayPort transmit PHY integrated in the SpacemiT
+  K3 SoC, one per DisplayPort controller. Its registers are interleaved with
+  the controller's own inside a single register window, so it is described as
+  a child of the controller and owns neither a reg nor a reset.
+
+  The PHY provides the pixel clock its PLL generates, which the APMU
+  pixel-clock mux takes as one of its inputs.
+
+properties:
+  compatible:
+    const: spacemit,k3-inno-dp-phy
+
+  "#phy-cells":
+    const: 0
+
+  "#clock-cells":
+    const: 0
+
+  clock-output-names:
+    maxItems: 1
+
+required:
+  - compatible
+  - "#phy-cells"
+  - "#clock-cells"
+
+additionalProperties: false
+
+examples:
+  - |
+    phy {
+        compatible = "spacemit,k3-inno-dp-phy";
+        #phy-cells = <0>;
+        #clock-cells = <0>;
+        clock-output-names = "edp0_pll_pxclk";
+    };

-- 
2.43.0

