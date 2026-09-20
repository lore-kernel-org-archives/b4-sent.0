From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Sun, 20 Sep 2026 08:13:28 +0000
Subject: [PATCH 1/3] spi: dt-bindings: amlogic,meson-gx-spicc: add T7
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260920-t7-node-new-v1-1-e6e0840c1b0b@amlogic.com>
References: <20260920-t7-node-new-v1-0-e6e0840c1b0b@amlogic.com>
In-Reply-To: <20260920-t7-node-new-v1-0-e6e0840c1b0b@amlogic.com>
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-spi@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789892012; l=1575;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=Cr+H2n7PINWdLBG8TQcHVSgRz7Rd2HsUY6kC9/oqBVw=;
 b=tvbgHwq2gJbM4TNfbjMX2pQyDPUy7YneptKtaRKwB+1ToDgPQfn2smAZdxJQlQTmvbLiyZ26l
 5k6PyShz8JiAVIWTe2aD7LDqHucFpEQa9OIFmg0XQui91Nck4YQpAmm
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Amlogic T7 SPICC compatible to the device tree binding.

The T7 controller is compatible with the existing G12A SPICC
implementation, so require amlogic,meson-g12a-spicc as a fallback
compatible for T7 devices.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../devicetree/bindings/spi/amlogic,meson-gx-spicc.yaml     | 13 +++++++++----
 1 file changed, 9 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/spi/amlogic,meson-gx-spicc.yaml b/Documentation/devicetree/bindings/spi/amlogic,meson-gx-spicc.yaml
index 4e28e6e9d8e0..f0ba15402a4c 100644
--- a/Documentation/devicetree/bindings/spi/amlogic,meson-gx-spicc.yaml
+++ b/Documentation/devicetree/bindings/spi/amlogic,meson-gx-spicc.yaml
@@ -16,10 +16,15 @@ description: |
 
 properties:
   compatible:
-    enum:
-      - amlogic,meson-gx-spicc # SPICC controller on Amlogic GX and compatible SoCs
-      - amlogic,meson-axg-spicc # SPICC controller on Amlogic AXG and compatible SoCs
-      - amlogic,meson-g12a-spicc # SPICC controller on Amlogic G12A and compatible SoCs
+    oneOf:
+      - items:
+          - enum:
+              - amlogic,t7-spicc
+          - const: amlogic,meson-g12a-spicc
+      - enum:
+          - amlogic,meson-gx-spicc # SPICC controller on Amlogic GX and compatible SoCs
+          - amlogic,meson-axg-spicc # SPICC controller on Amlogic AXG and compatible SoCs
+          - amlogic,meson-g12a-spicc # SPICC controller on Amlogic G12A and compatible SoCs
 
   interrupts:
     maxItems: 1

-- 
2.52.0

