From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:11:49 +0000
Subject: [PATCH 2/5] dt-bindings: iommu: arm,smmu-v3: allow clocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-smmu-v3-pcie-pd-v1-2-628819ca44b9@gmail.com>
References: <20261110-smmu-v3-pcie-pd-v1-0-628819ca44b9@gmail.com>
In-Reply-To: <20261110-smmu-v3-pcie-pd-v1-0-628819ca44b9@gmail.com>
To: Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Niklas Cassel <cassel@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, iommu@lists.linux.dev, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-rockchip@lists.infradead.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794294708; l=1190;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=e3I86t0a2cKOracDfZB99pIl0HZ6AOgZkYX+gUkTyuk=;
 b=tBT8b/4LYX8rdPkNdY6YZ3Uugf78rotGYU+jpwCP66IokWm6Ao3oFELzJCwqsK6jWIT6zWrVg
 dmmp2igf4A2AJylfNxi90PXlJSKrdARCH+fF/ti/lPJg2lEF2QR0zEj
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some SoCs feed the SMMUv3 from a clock that the OS controls. On the
Rockchip RK3588 the MMU-600 for PCIe runs from ACLK_MMU_PCIE, whose only
other consumers are the PCIe controllers. When no PCIe controller is
enabled, the clock framework gates it as unused, and the SMMU can no
longer be accessed.

Allow up to four clocks, so that such a clock can be described and held
by the SMMU driver.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 Documentation/devicetree/bindings/iommu/arm,smmu-v3.yaml | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/Documentation/devicetree/bindings/iommu/arm,smmu-v3.yaml b/Documentation/devicetree/bindings/iommu/arm,smmu-v3.yaml
index c8f22dfdb1db..f8a74730667c 100644
--- a/Documentation/devicetree/bindings/iommu/arm,smmu-v3.yaml
+++ b/Documentation/devicetree/bindings/iommu/arm,smmu-v3.yaml
@@ -63,6 +63,13 @@ properties:
 
   msi-parent: true
 
+  clocks:
+    minItems: 1
+    maxItems: 4
+    description:
+      Clocks needed to access the SMMU registers and to keep its translation
+      units running, if they are not managed by firmware.
+
   power-domains:
     maxItems: 1
 

-- 
2.55.0

