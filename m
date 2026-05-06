From: Rohan Joshi <rohan1sj@cadence.com>
Date: Wed, 06 May 2026 14:34:46 +0530
Subject: [PATCH v2 1/2] dt-bindings: mmc: cdns,sdhci: Add CQE support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260506-cdns_sdhci_cqe-support-v2-1-754fe4de8b65@cadence.com>
References: <20260506-cdns_sdhci_cqe-support-v2-0-754fe4de8b65@cadence.com>
In-Reply-To: <20260506-cdns_sdhci_cqe-support-v2-0-754fe4de8b65@cadence.com>
To: Ulf Hansson <ulfh@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Masahiro Yamada <yamada.masahiro@socionext.com>, 
 Adrian Hunter <adrian.hunter@intel.com>
Cc: linux-mmc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, mparab@cadence.com, pawell@cadence.com, 
 sjakhade@cadence.com, mpillai@cadence.com, rohan1sj@cadence.com
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778058298; l=2597;
 i=rohan1sj@cadence.com; s=20260406; h=from:subject:message-id;
 bh=n42mGGYkYpXMehcfhaVeXxEx7pSGijf2DNwxK2oxS9s=;
 b=GKz4pe8SMh6qxwCXXVRDN5JrBWPaHMDpss+m+X9LNk/1mDplxtcIKPzZcJwL0fv9FZb+Lz0Jl
 ZS9U0jZTv1cBgytWtKJwC+qriyvq4JuMKxHNuH1apF1s4fRaSYQsd2J
X-Developer-Key: i=rohan1sj@cadence.com; a=ed25519;
 pk=YuwylizMVlVj8I4+VPMZ6xrFR2wyqJAWZyj90OVZgD0=
X-Endpoint-Received: by B4 Relay for rohan1sj@cadence.com/20260406 with auth_id=723
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Cadence host controller can support CQE. Add optional CQE
register space and reg-names property to cdns sdhci binding

Signed-off-by: Rohan Joshi <rohan1sj@cadence.com>
---
 .../devicetree/bindings/mmc/cdns,sdhci.yaml        | 41 +++++++---------------
 1 file changed, 12 insertions(+), 29 deletions(-)

diff --git a/Documentation/devicetree/bindings/mmc/cdns,sdhci.yaml b/Documentation/devicetree/bindings/mmc/cdns,sdhci.yaml
index 8902e7925eab..79064282fabc 100644
--- a/Documentation/devicetree/bindings/mmc/cdns,sdhci.yaml
+++ b/Documentation/devicetree/bindings/mmc/cdns,sdhci.yaml
@@ -26,7 +26,9 @@ properties:
 
   reg-names:
     minItems: 1
-    maxItems: 2
+    items:
+      - const: hc
+      - const: cqhci
 
   interrupts:
     maxItems: 1
@@ -138,22 +140,16 @@ allOf:
           items:
             - description: Host controller registers
             - description: Elba byte-lane enable register for writes
+        reg-names: false
+      required:
+        - resets
     else:
       properties:
         reg:
-          oneOf:
-            - items:
-                - description: Host controller registers
-            - items:
-                - description: Host controller registers
-                - description: CQE (Command Queue Engine) registers
-        reg-names:
-          oneOf:
-            - items:
-                - const: sdhci
-            - items:
-                - const: sdhci
-                - const: cqhci
+          minItems: 1
+          items:
+            - description: Host Controller registers
+            - description: CQE (Command Queuing Engine) registers
 
 unevaluatedProperties: false
 
@@ -161,7 +157,8 @@ examples:
   - |
     emmc: mmc@5a000000 {
         compatible = "socionext,uniphier-sd4hc", "cdns,sd4hc";
-        reg = <0x5a000000 0x400>;
+        reg = <0x5a000000 0x400>, <0x5a000400 0x060>;
+        reg-names = "hc", "cqhci";
         interrupts = <0 78 4>;
         clocks = <&clk 4>;
         bus-width = <8>;
@@ -170,17 +167,3 @@ examples:
         mmc-hs400-1_8v;
         cdns,phy-dll-delay-sdclk = <0>;
     };
-
-  - |
-    emmc_cqe: mmc@5b000000 {
-        compatible = "socionext,uniphier-sd4hc", "cdns,sd4hc";
-        reg = <0x5b000000 0x400>, <0x5b000400 0x060>;
-        reg-names = "sdhci", "cqhci";
-        interrupts = <0 79 4>;
-        clocks = <&clk 4>;
-        bus-width = <8>;
-        mmc-ddr-1_8v;
-        mmc-hs200-1_8v;
-        mmc-hs400-1_8v;
-        cdns,phy-dll-delay-sdclk = <0>;
-    };

-- 
2.34.1

