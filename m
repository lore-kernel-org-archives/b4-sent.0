From: Jia Wang <wangjia@ultrarisc.com>
Date: Mon, 06 Jul 2026 17:58:49 +0800
Subject: [PATCH v2 1/3] dt-bindings: pci: ultrarisc: add required DP1000
 PCIe clocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260706-ultrarisc-pci-clk-v2-1-2f3fb6fba66b@ultrarisc.com>
References: <20260706-ultrarisc-pci-clk-v2-0-2f3fb6fba66b@ultrarisc.com>
In-Reply-To: <20260706-ultrarisc-pci-clk-v2-0-2f3fb6fba66b@ultrarisc.com>
To: Xincheng Zhang <zhangxincheng@ultrarisc.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783331975; l=1883;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=MadaMzsEQt3m33Yn04ygfcyKkX6JurLuStxQ8qHRs6U=;
 b=bEFugdScOKe825UCHTbWbXTeXm1m7URDjoD1eWjcFim0uNMQs/Gd8eUEpT2Hdmix3YnD2H+RD
 bFJfeCVGp33CRIdk1h2c38sLXJIN2HlFqqK3nj2uhJ7L8g7Xbx1IySN
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Require the DP1000 PCIe controller nodes to provide clocks and
clock-names, using the standard DesignWare clock names "core",
"dbi", and "aux".

Fixes: d9ff07f45955 ("dt-bindings: PCI: Add UltraRISC DP1000 PCIe controller")
Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
Acked-by: Conor Dooley <conor.dooley@microchip.com>
---
 .../devicetree/bindings/pci/ultrarisc,dp1000-pcie.yaml   | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/Documentation/devicetree/bindings/pci/ultrarisc,dp1000-pcie.yaml b/Documentation/devicetree/bindings/pci/ultrarisc,dp1000-pcie.yaml
index 512b935bf5d1..d9d1488e915a 100644
--- a/Documentation/devicetree/bindings/pci/ultrarisc,dp1000-pcie.yaml
+++ b/Documentation/devicetree/bindings/pci/ultrarisc,dp1000-pcie.yaml
@@ -43,6 +43,18 @@ properties:
       - description: Legacy INTC interrupt
       - description: Legacy INTD interrupt
 
+  clocks:
+    items:
+      - description: PCIe core clock
+      - description: Data Bus Interface (DBI) clock
+      - description: Auxiliary clock
+
+  clock-names:
+    items:
+      - const: core
+      - const: dbi
+      - const: aux
+
   interrupt-names:
     items:
       - const: msi
@@ -55,6 +67,8 @@ required:
   - compatible
   - reg
   - reg-names
+  - clocks
+  - clock-names
   - interrupts
   - interrupt-names
 
@@ -71,6 +85,8 @@ examples:
         reg = <0x0 0x21000000 0x0 0x01000000>,
               <0x0 0x4fff0000 0x0 0x00010000>;
         reg-names = "dbi", "config";
+        clocks = <&clkc 9>, <&clkc 7>, <&clkc 10>;
+        clock-names = "core", "dbi", "aux";
         ranges = <0x81000000 0x0 0x4fbf0000 0x0 0x4fbf0000 0x0 0x00400000>,
                  <0x82000000 0x0 0x40000000 0x0 0x40000000 0x0 0x0fbf0000>,
                  <0xc3000000 0x40 0x00000000 0x40 0x00000000 0xd 0x00000000>;

-- 
2.34.1

