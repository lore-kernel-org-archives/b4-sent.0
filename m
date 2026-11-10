From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:11:48 +0000
Subject: [PATCH 1/5] dt-bindings: iommu: arm,smmu-v3: allow a power domain
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-smmu-v3-pcie-pd-v1-1-628819ca44b9@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794294708; l=1167;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=TdWoGoQsKnyrm8b9EIEgWSxDN/b5wPqWn8RNCU7PWLE=;
 b=x3WlakvjrJB7bBweyNuurbxFx6ml1Crbe9R1B+W78YkdTZqbMT4BjFaIlFUU2Yq28U85BBqQ7
 QAh2R2KDz6TCenOiDzdDdC3EJcC6NonWmsjPmdZ8tgjZohMcMJXI9Pl
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An SMMUv3 instance can sit in a switchable power domain of the SoC, for
example the MMU-600 in front of the PCIe controllers on the Rockchip
RK3588, which is part of the PCIe power domain. If the domain is not
described, nothing keeps it powered while the SMMU is bound, and any
register access after it has been turned off as unused stalls the
interconnect.

Allow a single power-domains entry, as arm,smmu.yaml already does for
the earlier SMMU architectures.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 Documentation/devicetree/bindings/iommu/arm,smmu-v3.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/iommu/arm,smmu-v3.yaml b/Documentation/devicetree/bindings/iommu/arm,smmu-v3.yaml
index 3c044e4f03d4..c8f22dfdb1db 100644
--- a/Documentation/devicetree/bindings/iommu/arm,smmu-v3.yaml
+++ b/Documentation/devicetree/bindings/iommu/arm,smmu-v3.yaml
@@ -63,6 +63,9 @@ properties:
 
   msi-parent: true
 
+  power-domains:
+    maxItems: 1
+
   nvidia,cmdqv:
     description: |
       A phandle to its pairing CMDQV extension for an implementation on NVIDIA

-- 
2.55.0

