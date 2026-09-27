From: Daniel Drake <dan@reactivated.net>
Date: Sun, 27 Sep 2026 14:09:01 +0100
Subject: [PATCH v7 2/6] dt-bindings: iommu: Add Broadcom BCM2712 IOMMU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260927-bcm2712-iommu-submit-v7-2-dfa2b975cbc9@reactivated.net>
References: <20260927-bcm2712-iommu-submit-v7-0-dfa2b975cbc9@reactivated.net>
In-Reply-To: <20260927-bcm2712-iommu-submit-v7-0-dfa2b975cbc9@reactivated.net>
To: "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>, 
 Daniel Drake <dan@reactivated.net>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-rpi-kernel@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, nick.hollinghurst@raspberrypi.com, 
 james.quinlan@broadcom.com, Jason Gunthorpe <jgg@ziepe.ca>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3762; i=dan@reactivated.net;
 h=from:subject:message-id; bh=u7rJyBVNS3KWB72oeww+xedcyOSO1pu/9F/9FnMv+ZQ=;
 b=owEBbQKS/ZANAwAKAcPmj7FTFEe7AcsmYgBquRWECYGMBQdbsB2gNcq4Q1xw08k/ntG52bF+4
 YfovzXHOCmJAjMEAAEKAB0WIQQ6Rf0sUP1iEhXfVfjD5o+xUxRHuwUCarkVhAAKCRDD5o+xUxRH
 uz1vD/9RzIY4deEi9rxCqIEQK+m3BFJjbNwrYh9IwwYJz+EHxf89OOM264wn+CJUzAPPbqV43n2
 SmfKViwwEJYbvExYXpnjxRtgEIS4hgZgExlnqgE84A/AkDwt/E9uUjxoQNKoFMnxtJ2lnBKeB6P
 Zx66frOS88cW0uoE1cUZWWKkIDn3fcbWs+k8vRn9LDseE0UxdnWVQ8C33sDL7MfGLRX4JL+mVzf
 813lDls0iT7z8RwJGrZ6sFhrspX2djUhZj3bjpl1v7PqGBSytg3FKlBNyR3q46NL4AH/8CMrxWL
 f/WwCq8dxf1nVOl8cscVmK26vOcOWFxLn5Pxb2LnSF/PXwBvh+aVbnpEGSzkH4IkVPbKj2wJL9I
 RP43SGlDUoQqh5Dj6TUEraokfxMQnyzL8eq14NmzX5H0L3TlQIQoqgxa/LyXnBf95bWpLSXz1SJ
 XmrbVegWr+yaVlv0vA6RFuNoMffqyVY6rMNPXYUrMllxkOwIvRLyFRiRi5duTP8o9CJ417Z4YeR
 QnXExCgxAZcNag56OzPVtH/LFq+RPmzQ7L1cim5rh8nXtNU0Jc2px5GxEvGrRTiwlaDQsdEDwpI
 HRNT+7FETDlfGC3nJEasqUNFDIknYTlv2z3nJ7Jw3J05++DdE7Ege8LKAyMOTXY4MTfq50UlVA0
 Ernq3x7tIicu0Yw==
X-Developer-Key: i=dan@reactivated.net; a=openpgp;
 fpr=3A45FD2C50FD621215DF55F8C3E68FB1531447BB
X-Endpoint-Received: by B4 Relay for dan@reactivated.net/default with auth_id=1070
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for the Broadcom BCM2712 IOMMUs and their shared TLB cache.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Daniel Drake <dan@reactivated.net>
---
 .../bindings/iommu/brcm,bcm2712-iommu.yaml         | 54 ++++++++++++++++++++++
 .../bindings/iommu/brcm,bcm2712-iommuc.yaml        | 40 ++++++++++++++++
 2 files changed, 94 insertions(+)

diff --git a/Documentation/devicetree/bindings/iommu/brcm,bcm2712-iommu.yaml b/Documentation/devicetree/bindings/iommu/brcm,bcm2712-iommu.yaml
new file mode 100644
index 000000000000..5ca8ce469ec3
--- /dev/null
+++ b/Documentation/devicetree/bindings/iommu/brcm,bcm2712-iommu.yaml
@@ -0,0 +1,54 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iommu/brcm,bcm2712-iommu.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Broadcom BCM2712 IOMMU
+
+maintainers:
+  - Daniel Drake <dan@reactivated.net>
+  - Florian Fainelli <florian.fainelli@broadcom.com>
+  - Jim Quinlan <james.quinlan@broadcom.com>
+
+description:
+  The BCM2712 SoC features multiple independent IOMMU instances providing
+  address translation for multimedia hardware blocks, such as the VC6 display
+  pipeline, camera receivers, and ISP. Each IOMMU has its own page tables,
+  control registers, and local TLB, and is additionally linked to a centralized
+  L2 TLB (IOMMUC).
+
+properties:
+  compatible:
+    const: brcm,bcm2712-iommu
+
+  reg:
+    maxItems: 1
+
+  '#iommu-cells':
+    const: 0
+
+  brcm,iommu-cache:
+    $ref: /schemas/types.yaml#/definitions/phandle
+    description:
+      Phandle to the shared IOMMU cache (IOMMUC). Each IOMMU instance caches
+      translated descriptors in this centralized L2 TLB cache block and must
+      trigger cache invalidation commands on it when updating or unmapping page
+      table entries.
+
+required:
+  - compatible
+  - reg
+  - '#iommu-cells'
+  - brcm,iommu-cache
+
+additionalProperties: false
+
+examples:
+  - |
+    iommu@5200 {
+        compatible = "brcm,bcm2712-iommu";
+        reg = <0x5200 0x80>;
+        brcm,iommu-cache = <&iommuc>;
+        #iommu-cells = <0>;
+    };
diff --git a/Documentation/devicetree/bindings/iommu/brcm,bcm2712-iommuc.yaml b/Documentation/devicetree/bindings/iommu/brcm,bcm2712-iommuc.yaml
new file mode 100644
index 000000000000..47c584ad667a
--- /dev/null
+++ b/Documentation/devicetree/bindings/iommu/brcm,bcm2712-iommuc.yaml
@@ -0,0 +1,40 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iommu/brcm,bcm2712-iommuc.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Broadcom BCM2712 Shared IOMMU Cache (IOMMUC)
+
+maintainers:
+  - Daniel Drake <dan@reactivated.net>
+  - Florian Fainelli <florian.fainelli@broadcom.com>
+  - Jim Quinlan <james.quinlan@broadcom.com>
+
+description:
+  The BCM2712 IOMMUC is a centralized Translation Lookaside Buffer (TLB) cache
+  which accelerates address translation across the SoC's IOMMU devices. If an
+  address mapping is not found in the IOMMU's local TLB cache, then this
+  IOMMUC is consulted as a L2 TLB. The SoC includes a single IOMMUC which is
+  shared between all IOMMUs, and it must be explicitly invalidated when
+  modifying or unmapping IOMMU page tables.
+
+properties:
+  compatible:
+    const: brcm,bcm2712-iommuc
+
+  reg:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+
+additionalProperties: false
+
+examples:
+  - |
+    iommuc@5b00 {
+        compatible = "brcm,bcm2712-iommuc";
+        reg = <0x5b00 0x80>;
+    };

-- 
2.55.0

