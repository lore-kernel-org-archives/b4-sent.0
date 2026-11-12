From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:20:22 +0000
Subject: [PATCH v2 1/4] dt-bindings: iommu: arm,smmu-v3: Allow a clock and
 a reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-smmu-v3-pcie-pd-v2-1-3a77bbb6b2c4@gmail.com>
References: <20261112-smmu-v3-pcie-pd-v2-0-3a77bbb6b2c4@gmail.com>
In-Reply-To: <20261112-smmu-v3-pcie-pd-v2-0-3a77bbb6b2c4@gmail.com>
To: Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Niklas Cassel <cassel@kernel.org>
Cc: Pranjal Shrivastava <praan@google.com>, 
 linux-arm-kernel@lists.infradead.org, iommu@lists.linux.dev, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-rockchip@lists.infradead.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Shawn Lin <shawn.lin@rock-chips.com>, Simon Xue <xxm@rock-chips.com>, 
 Finley Xiao <finley.xiao@rock-chips.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794471621; l=1761;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=JzTX29/TpR9nxeGBdiZSgKclV4i70sBR/P9CmAq8ikE=;
 b=meanwe78j5XeCWZ+lc3cXV+gk13lyQBfIrhT/Usf6uvGl6Qs3NxLqmQXwoOl4CPLYS3YZIBO6
 bAOb6gHoUQuA6jkHrGNmy7DV00xKs/7FY55AnihnTg3kBZxeuBP4R/9
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some SoCs feed the SMMUv3 from a clock that the OS controls. On the
Rockchip RK3588 the MMU-600 for PCIe runs from ACLK_MMU_PCIE, whose only
other consumers are the PCIe controllers. When no PCIe controller is
enabled, the clock framework gates it as unused, and the SMMU can no
longer be accessed. The same SMMU also has a reset line in the CRU,
SRST_A_MMU_PCIE.

Allow a single clock and a single reset, so that both can be described.
The architecture defines no clock or reset inputs; the MMU-600 TRM lists
one clock and one reset signal, and the one integration that needs this
has one of each. An implementation with more clocks or resets can add
them with names and a specific compatible.

Link: https://support.arm.com/documentation/100310/0202/Signal-descriptions/Clock-and-reset-signals
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 Documentation/devicetree/bindings/iommu/arm,smmu-v3.yaml | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/Documentation/devicetree/bindings/iommu/arm,smmu-v3.yaml b/Documentation/devicetree/bindings/iommu/arm,smmu-v3.yaml
index 3c044e4f03d4..29b81b4fb650 100644
--- a/Documentation/devicetree/bindings/iommu/arm,smmu-v3.yaml
+++ b/Documentation/devicetree/bindings/iommu/arm,smmu-v3.yaml
@@ -63,6 +63,17 @@ properties:
 
   msi-parent: true
 
+  clocks:
+    maxItems: 1
+    description:
+      Clock of the SMMU's register and memory interfaces, on SoCs where the
+      OS has to keep it running.
+
+  resets:
+    maxItems: 1
+    description:
+      Reset of the SMMU, on SoCs where it is controlled by the OS.
+
   nvidia,cmdqv:
     description: |
       A phandle to its pairing CMDQV extension for an implementation on NVIDIA

-- 
2.55.0

