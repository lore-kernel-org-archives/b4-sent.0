From: Jia Wang <wangjia@ultrarisc.com>
Date: Mon, 29 Jun 2026 13:59:50 +0800
Subject: [PATCH 1/2] dt-bindings: pci: ultrarisc: add required DP1000 PCIe
 clocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260629-ultrarisc-pci-clk-v1-1-5ea3308fdab3@ultrarisc.com>
References: <20260629-ultrarisc-pci-clk-v1-0-5ea3308fdab3@ultrarisc.com>
In-Reply-To: <20260629-ultrarisc-pci-clk-v1-0-5ea3308fdab3@ultrarisc.com>
To: Xincheng Zhang <zhangxincheng@ultrarisc.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782712801; l=1750;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=lh7Q6BO8G4kaApUfS6DwKL6o9OH0GZihU/1HgX0D1ow=;
 b=OTU8MSd21jrAQoR5SGLTy5x7dZerI6zVRF8OY5qC6pGmdTYaX1TNSpFyGhQU5Y17C2N7GeaOu
 ExRQxhfXgq1Drkxmc86i20qNiSQLX6MT+2J+i3csQd81MNl+8p+lc7q
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Require the DP1000 PCIe controller nodes to provide clocks and
clock-names, using the standard DesignWare clock names "core",
"dbi", and "aux".

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
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

