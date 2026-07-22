From: Rohan Joshi <rohan1sj@cadence.com>
Date: Wed, 22 Jul 2026 16:18:37 +0530
Subject: [PATCH v3 1/2] dt-bindings: mmc: cdns,sdhci: Add CQE support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260722-cdns_sdhci_cqe-support-v3-1-4412856a4488@cadence.com>
References: <20260722-cdns_sdhci_cqe-support-v3-0-4412856a4488@cadence.com>
In-Reply-To: <20260722-cdns_sdhci_cqe-support-v3-0-4412856a4488@cadence.com>
To: Ulf Hansson <ulfh@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Masahiro Yamada <yamada.masahiro@socionext.com>, 
 Adrian Hunter <adrian.hunter@intel.com>
Cc: linux-mmc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, mparab@cadence.com, pawell@cadence.com, 
 sjakhade@cadence.com, mpillai@cadence.com, rohan1sj@cadence.com, 
 razb@mobileye.com
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784717318; l=2038;
 i=rohan1sj@cadence.com; s=20260406; h=from:subject:message-id;
 bh=3c4jIiul3k4zOJgiOZdmt+aBj0CmrIVw3EVAdwc6Stk=;
 b=MYgedew6o5O7v6rUVirmKdMriCt+0bB5jHkLEnZR/9EHtik//mWoif6u1aVN8T5mMV0AwNBSn
 6uM+N2g7UgxCymSTyym4j1KPeSgWhiOvkNdB1a/nFVKp8f8gsLdD3HA
X-Developer-Key: i=rohan1sj@cadence.com; a=ed25519;
 pk=YuwylizMVlVj8I4+VPMZ6xrFR2wyqJAWZyj90OVZgD0=
X-Endpoint-Received: by B4 Relay for rohan1sj@cadence.com/20260406 with auth_id=723
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Cadence host controller can optionally support CQE.
Add optional CQE register space to cdns sdhci bindings.

Signed-off-by: Rohan Joshi <rohan1sj@cadence.com>
---
 .../devicetree/bindings/mmc/cdns,sdhci.yaml        | 28 +++++++++++++++++++---
 1 file changed, 25 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/mmc/cdns,sdhci.yaml b/Documentation/devicetree/bindings/mmc/cdns,sdhci.yaml
index 6c7317d13aa6..10bc9ac2073a 100644
--- a/Documentation/devicetree/bindings/mmc/cdns,sdhci.yaml
+++ b/Documentation/devicetree/bindings/mmc/cdns,sdhci.yaml
@@ -22,7 +22,14 @@ properties:
 
   reg:
     minItems: 1
-    maxItems: 2
+    maxItems: 3
+
+  reg-names:
+    minItems: 1
+    items:
+      - const: hc
+      - enum: [bctl, cqhci]
+      - const: cqhci
 
   interrupts:
     maxItems: 1
@@ -131,13 +138,27 @@ allOf:
     then:
       properties:
         reg:
+          minItems: 2
           items:
             - description: Host controller registers
             - description: Elba byte-lane enable register for writes
+            - description: CQE (Command Queuing Engine) registers (optional)
+        reg-names:
+          minItems: 2
+          items:
+            - const: hc
+            - const: bctl
+            - const: cqhci
     else:
       properties:
         reg:
-          maxItems: 1
+          items:
+            - description: Host Controller registers
+            - description: CQE (Command Queuing Engine) registers (optional)
+        reg-names:
+          items:
+            - const: hc
+            - const: cqhci
 
 unevaluatedProperties: false
 
@@ -145,7 +166,8 @@ examples:
   - |
     emmc: mmc@5a000000 {
         compatible = "socionext,uniphier-sd4hc", "cdns,sd4hc";
-        reg = <0x5a000000 0x400>;
+        reg = <0x5a000000 0x400>, <0x5a000400 0x060>;
+        reg-names = "hc", "cqhci";
         interrupts = <0 78 4>;
         clocks = <&clk 4>;
         bus-width = <8>;

-- 
2.43.0

