From: rohan1sj <rohan1sj@cadence.com>
Date: Tue, 07 Apr 2026 16:48:20 +0530
Subject: [PATCH 1/2] mmc: cqe: Add CQE DT support for cadence controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260407-cdns_sdhci_cqe-support-v1-1-13efc0810631@cadence.com>
References: <20260407-cdns_sdhci_cqe-support-v1-0-13efc0810631@cadence.com>
In-Reply-To: <20260407-cdns_sdhci_cqe-support-v1-0-13efc0810631@cadence.com>
To: Ulf Hansson <ulf.hansson@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Masahiro Yamada <yamada.masahiro@socionext.com>, 
 Adrian Hunter <adrian.hunter@intel.com>
Cc: linux-mmc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Milind Parab <mparab@cadence.com>, 
 Swapnil Jakhade <sjakhade@cadence.com>, 
 Manikandan Pillai <mpillai@cadence.com>, rohan1sj <rohan1sj@cadence.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775560710; l=1838;
 i=rohan1sj@cadence.com; s=20260406; h=from:subject:message-id;
 bh=2Nj43iUADBM6GdTZZUu58CP25EFDyw5xiqmEYK92Vd0=;
 b=nkSD9fkbW9vT4GqqWqXoFMbK5JQFU/fqX4Xm9VfD4l2exop9Us/vV5je4LEJrlWRnzxc/GpjC
 HDyWZUi/5W0BjyCFmIddTaO8zl07qhjNZW0WIC7jeGoetIA0SevFhFy
X-Developer-Key: i=rohan1sj@cadence.com; a=ed25519;
 pk=YuwylizMVlVj8I4+VPMZ6xrFR2wyqJAWZyj90OVZgD0=
X-Endpoint-Received: by B4 Relay for rohan1sj@cadence.com/20260406 with auth_id=723
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add DT config required to support CQE as present in
cadence eMMC host controller

Signed-off-by: rohan1sj <rohan1sj@cadence.com>
---
 .../devicetree/bindings/mmc/cdns,sdhci.yaml        | 32 +++++++++++++++++++++-
 1 file changed, 31 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/mmc/cdns,sdhci.yaml b/Documentation/devicetree/bindings/mmc/cdns,sdhci.yaml
index ac75d694611a..c0d8aefe20c2 100644
--- a/Documentation/devicetree/bindings/mmc/cdns,sdhci.yaml
+++ b/Documentation/devicetree/bindings/mmc/cdns,sdhci.yaml
@@ -24,6 +24,10 @@ properties:
     minItems: 1
     maxItems: 2
 
+  reg-names:
+    minItems: 1
+    maxItems: 2
+
   interrupts:
     maxItems: 1
 
@@ -139,7 +143,19 @@ allOf:
     else:
       properties:
         reg:
-          maxItems: 1
+          oneOf:
+            - items:
+                - description: Host controller registers
+            - items:
+                - description: Host controller registers
+                - description: CQE (Command Queue Engine) registers
+        reg-names:
+          oneOf:
+            - items:
+                - const: sdhci
+            - items:
+                - const: sdhci
+                - const: cqhci
 
 unevaluatedProperties: false
 
@@ -156,3 +172,17 @@ examples:
         mmc-hs400-1_8v;
         cdns,phy-dll-delay-sdclk = <0>;
     };
+
+  - |
+    emmc_cqe: mmc@5b000000 {
+        compatible = "socionext,uniphier-sd4hc", "cdns,sd4hc";
+        reg = <0x5b000000 0x400>, <0x5b000400 0x060>;
+        reg-names = "sdhci", "cqhci";
+        interrupts = <0 79 4>;
+        clocks = <&clk 4>;
+        bus-width = <8>;
+        mmc-ddr-1_8v;
+        mmc-hs200-1_8v;
+        mmc-hs400-1_8v;
+        cdns,phy-dll-delay-sdclk = <0>;
+    };

-- 
2.34.1

