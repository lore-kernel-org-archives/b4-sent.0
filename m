From: Mahesh Rao <mahesh.rao@altera.com>
Date: Tue, 22 Apr 2025 12:07:11 +0800
Subject: [PATCH 4/7] dt-bindings: firmware: Add interrupt specification for
 Intel Stratix 10 Service Layer.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250422-sip_svc_upstream-v1-4-088059190f31@altera.com>
References: <20250422-sip_svc_upstream-v1-0-088059190f31@altera.com>
In-Reply-To: <20250422-sip_svc_upstream-v1-0-088059190f31@altera.com>
To: Dinh Nguyen <dinguyen@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Mahesh Rao <mahesh.rao@altera.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Matthew Gerlach <matthew.gerlach@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745294834; l=1801;
 i=mahesh.rao@altera.com; s=20250107; h=from:subject:message-id;
 bh=SNGxaxaQ7O8Am109rLMAgnrv4HKXic5pX5a15IoblFE=;
 b=AEZm/9bzNBzTC4xWUbctZ/8jIPwHlWZ1T3vBKor/RQDuT0sRxBLQeLLDFh643g9l2gfD5KaaJ
 vOgCQ/4m/QIDnqMv8JxPG4QVNQByd6+OC+bxgash1bBAQ0XAcGYOgw9
X-Developer-Key: i=mahesh.rao@altera.com; a=ed25519;
 pk=tQiFUzoKxHrQLDtWeEeaeTeJTl/UfclUHWZy1fjSiyg=
X-Endpoint-Received: by B4 Relay for mahesh.rao@altera.com/20250107 with auth_id=337
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add interrupt specification for Intel Stratix10 Service
layer for asynchronous communication.

Signed-off-by: Mahesh Rao <mahesh.rao@altera.com>
Reviewed-by: Matthew Gerlach <matthew.gerlach@altera.com>
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

