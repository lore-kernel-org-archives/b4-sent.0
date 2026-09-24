From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 24 Sep 2026 05:51:09 +0000
Subject: [PATCH v2 2/3] dt-bindings: net: meson-dwmac: add T7 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-t7-node-new-v2-2-319d3c19b4b2@amlogic.com>
References: <20260924-t7-node-new-v2-0-319d3c19b4b2@amlogic.com>
In-Reply-To: <20260924-t7-node-new-v2-0-319d3c19b4b2@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790229071; l=2194;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=OuWtCvG4zrP01yJiFjTkY4chxxarHmWUIHB1zdrvrrw=;
 b=uOsEnSyIlN8J9zL2lHAk+qTRy4/RCF3TeOmRM09rdTe4uQU0D49uiM6TE1HvbeeTvVGRUoVG1
 mGboAlM++RIA2XI3U47qg+ULRzkuiibd1WI5B66c3AlVk/+ne+Kisgr
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the T7 compatible to the Meson DWMAC binding.

The T7 DWMAC controller requires the following compatible combination:

amlogic,t7-dwmac
amlogic,meson-axg-dwmac
snps,dwmac-4.00

Add a conditional schema check to enforce this compatible combination
when amlogic,t7-dwmac is used.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../devicetree/bindings/net/amlogic,meson-dwmac.yaml    | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/amlogic,meson-dwmac.yaml b/Documentation/devicetree/bindings/net/amlogic,meson-dwmac.yaml
index 5c91716d1f21..b529ca5577a9 100644
--- a/Documentation/devicetree/bindings/net/amlogic,meson-dwmac.yaml
+++ b/Documentation/devicetree/bindings/net/amlogic,meson-dwmac.yaml
@@ -23,11 +23,24 @@ select:
           - amlogic,meson-gxbb-dwmac
           - amlogic,meson-axg-dwmac
           - amlogic,meson-g12a-dwmac
+          - amlogic,t7-dwmac
   required:
     - compatible
 
 allOf:
   - $ref: snps,dwmac.yaml#
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: amlogic,t7-dwmac
+    then:
+      properties:
+        compatible:
+          items:
+            - const: amlogic,t7-dwmac
+            - const: amlogic,meson-axg-dwmac
+            - const: snps,dwmac-4.00
   - if:
       properties:
         compatible:
@@ -38,6 +51,7 @@ allOf:
               - amlogic,meson-gxbb-dwmac
               - amlogic,meson-axg-dwmac
               - amlogic,meson-g12a-dwmac
+              - amlogic,t7-dwmac
 
     then:
       properties:
@@ -93,6 +107,7 @@ allOf:
               - amlogic,meson8m2-dwmac
               - amlogic,meson-gxbb-dwmac
               - amlogic,meson-axg-dwmac
+              - amlogic,t7-dwmac
     then:
       properties:
         rx-internal-delay-ps:
@@ -139,8 +154,10 @@ properties:
           - amlogic,meson-gxbb-dwmac
           - amlogic,meson-axg-dwmac
           - amlogic,meson-g12a-dwmac
+          - amlogic,t7-dwmac
     contains:
       enum:
+        - snps,dwmac-4.00
         - snps,dwmac-3.70a
         - snps,dwmac
 

-- 
2.52.0

