From: Mahesh Rao <mahesh.rao@altera.com>
Date: Tue, 12 Aug 2025 20:59:24 +0800
Subject: [PATCH RESEND v2 1/4] dt-bindings: firmware: Add interrupt
 specification for Intel Stratix 10 Service Layer.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250812-sip_svc_irq-v2-1-53098e11705a@altera.com>
References: <20250812-sip_svc_irq-v2-0-53098e11705a@altera.com>
In-Reply-To: <20250812-sip_svc_irq-v2-0-53098e11705a@altera.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dinh Nguyen <dinguyen@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mahesh Rao <mahesh.rao@altera.com>, 
 Matthew Gerlach <matthew.gerlach@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755003637; l=1851;
 i=mahesh.rao@altera.com; s=20250107; h=from:subject:message-id;
 bh=AOemBCgdL+N65O4/Not6GZwfFLWHmbGOTOms8z2w2Jo=;
 b=8S0XDud7rGHq5nBFQ8JWiz7ndCiGBA16NH2g3aA2nzxZLjooQTJ6gmSdIAd+o++rn8nS4hQGw
 eaxZtK7NPAYDdJu+vNaAqdulhgQA/H6DRbYbMKyjmD7jk6oaMVER+3d
X-Developer-Key: i=mahesh.rao@altera.com; a=ed25519;
 pk=tQiFUzoKxHrQLDtWeEeaeTeJTl/UfclUHWZy1fjSiyg=
X-Endpoint-Received: by B4 Relay for mahesh.rao@altera.com/20250107 with auth_id=337
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add interrupt specification for Intel Stratix10 Service
layer for asynchronous communication.

Reviewed-by: Matthew Gerlach <matthew.gerlach@altera.com>
Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Mahesh Rao <mahesh.rao@altera.com>
---
 .../devicetree/bindings/firmware/intel,stratix10-svc.yaml      | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/Documentation/devicetree/bindings/firmware/intel,stratix10-svc.yaml b/Documentation/devicetree/bindings/firmware/intel,stratix10-svc.yaml
index fac1e955852e4f9b966c991dcfac56222c5f7315..656cc50fd08217f270f95ae39010152423315ed1 100644
--- a/Documentation/devicetree/bindings/firmware/intel,stratix10-svc.yaml
+++ b/Documentation/devicetree/bindings/firmware/intel,stratix10-svc.yaml
@@ -54,6 +54,12 @@ properties:
       reserved memory region for the service layer driver to
       communicate with the secure device manager.
 
+  interrupts:
+    maxItems: 1
+    description:
+      This interrupt is used by the Secure Device Manager (SDM) to signal
+      completion of an asynchronous operation to service layer driver.
+
   fpga-mgr:
     $ref: /schemas/fpga/intel,stratix10-soc-fpga-mgr.yaml
     description: Optional child node for fpga manager to perform fabric configuration.
@@ -67,6 +73,8 @@ additionalProperties: false
 
 examples:
   - |
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+
     reserved-memory {
       #address-cells = <2>;
       #size-cells = <2>;
@@ -84,6 +92,8 @@ examples:
         compatible = "intel,stratix10-svc";
         method = "smc";
         memory-region = <&service_reserved>;
+        interrupts = <GIC_SPI 0 IRQ_TYPE_LEVEL_HIGH>;
+        interrupt-parent = <&intc0>;
 
         fpga-mgr {
           compatible = "intel,stratix10-soc-fpga-mgr";

-- 
2.35.3

