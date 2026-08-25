From: Rohan Joshi <rohan1sj@cadence.com>
Date: Tue, 25 Aug 2026 16:40:57 +0530
Subject: [PATCH v4 1/2] dt-bindings: mmc: cdns,sdhci: Add CQE support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-cdns_sdhci_cqe-support-v4-1-e9f72e338373@cadence.com>
References: <20260825-cdns_sdhci_cqe-support-v4-0-e9f72e338373@cadence.com>
In-Reply-To: <20260825-cdns_sdhci_cqe-support-v4-0-e9f72e338373@cadence.com>
To: Ulf Hansson <ulfh@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Masahiro Yamada <yamada.masahiro@socionext.com>, 
 Adrian Hunter <adrian.hunter@intel.com>
Cc: Rohan Joshi <rohan1sj@cadence.com>, linux-mmc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 mparab@cadence.com, pawell@cadence.com, sjakhade@cadence.com, 
 mpillai@cadence.com, razb@mobileye.com, blarson@amd.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787656261; l=2483;
 i=rohan1sj@cadence.com; s=20260406; h=from:subject:message-id;
 bh=tnxL6P/kgvSIMtCk+Ymrqyu224na2jvLAY8/B+g5f2g=;
 b=hxGduSniPK0Ou//Q34vXOH5FohiuZGGh6AbxKHkphdv3d7T4+J9rperQnanY5J8R2XvQRTftb
 h9nPjVbKuJ7Ac3Z9wUST+0qOdx/JVCvyTa6w1OUwEmIgjQp6wFciuzp
X-Developer-Key: i=rohan1sj@cadence.com; a=ed25519;
 pk=YuwylizMVlVj8I4+VPMZ6xrFR2wyqJAWZyj90OVZgD0=
X-Endpoint-Received: by B4 Relay for rohan1sj@cadence.com/20260406 with auth_id=723
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add optional named resource "cqhci" to map the CQE
register space. When present, it is used for CQHCI
initialization and enable Command Queue Engine for eMMC.

The "cqhci" space is optional to maintain compatibility
for platforms that don't have CQE block. When absent, the
controller can operate without the CQE block as routined.

Update amd,pensando-elba platform to include this resource
since Elba does have hardware block required for CQE! The
original author for Elba, Brad Larson (blarson@amd.com)
was able to confirm the CQE support.

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

