From: Roman Vivchar <rva333@protonmail.com>
Date: Wed, 09 Sep 2026 17:14:05 +0300
Subject: [PATCH 1/3] dt-bindings: iommu: mediatek: add mt6572
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260909-6572-iommu-v1-1-de261da09fb2@protonmail.com>
References: <20260909-6572-iommu-v1-0-de261da09fb2@protonmail.com>
In-Reply-To: <20260909-6572-iommu-v1-0-de261da09fb2@protonmail.com>
To: Yong Wu <yong.wu@mediatek.com>, "Joerg Roedel (AMD)" <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: iommu@lists.linux.dev, linux-mediatek@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788963261; l=2837;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=dwxNgLWUiyagGRngvUTXF8Q3mn0Z/8Gp90+ec/HbfQE=;
 b=8zBKc+fTvUi9pPpdPzfAzxaZDGX72EAiENZ4TSMrwd7adwi6lVA7T1qT0eczdmcib3XGbCsMi
 +DXU9U7VFidBMcOTDMSr/H823ERdWDuT6q9iwd0tD/LuitQr5U+vqO4
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible string and header file for mt6572 IOMMU support.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 .../devicetree/bindings/iommu/mediatek,iommu.yaml  |  3 +++
 .../memory/mediatek,mt6572-memory-port.h           | 26 ++++++++++++++++++++++
 2 files changed, 29 insertions(+)

diff --git a/Documentation/devicetree/bindings/iommu/mediatek,iommu.yaml b/Documentation/devicetree/bindings/iommu/mediatek,iommu.yaml
index 79c573c47b08..d0ac4bd71911 100644
--- a/Documentation/devicetree/bindings/iommu/mediatek,iommu.yaml
+++ b/Documentation/devicetree/bindings/iommu/mediatek,iommu.yaml
@@ -72,6 +72,7 @@ properties:
       - enum:
           - mediatek,mt2701-m4u  # generation one
           - mediatek,mt2712-m4u  # generation two
+          - mediatek,mt6572-m4u  # generation one
           - mediatek,mt6779-m4u  # generation two
           - mediatek,mt6795-m4u  # generation two
           - mediatek,mt6893-iommu-mm         # generation two
@@ -134,6 +135,7 @@ properties:
       dt-binding/memory/mediatek,mt8189-memory-port.h for mt8189,
       dt-binding/memory/mt2701-larb-port.h for mt2701 and mt7623,
       dt-binding/memory/mt2712-larb-port.h for mt2712,
+      dt-binding/memory/mediatek,mt6572-memory-port.h for mt6572,
       dt-binding/memory/mt6779-larb-port.h for mt6779,
       dt-binding/memory/mt6795-larb-port.h for mt6795,
       dt-binding/memory/mediatek,mt6893-memory-port.h for mt6893,
@@ -162,6 +164,7 @@ allOf:
             enum:
               - mediatek,mt2701-m4u
               - mediatek,mt2712-m4u
+              - mediatek,mt6572-m4u
               - mediatek,mt6795-m4u
               - mediatek,mt6893-iommu-mm
               - mediatek,mt8173-m4u
diff --git a/include/dt-bindings/memory/mediatek,mt6572-memory-port.h b/include/dt-bindings/memory/mediatek,mt6572-memory-port.h
new file mode 100644
index 000000000000..6f8ddc98f1b1
--- /dev/null
+++ b/include/dt-bindings/memory/mediatek,mt6572-memory-port.h
@@ -0,0 +1,26 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+/*
+ * Copyright (c) 2026 Roman Vivchar <rva333@protonmail.com>
+ */
+
+#ifndef _DT_BINDINGS_MEMORY_MT6572_MEMORY_PORT_H_
+#define _DT_BINDINGS_MEMORY_MT6572_MEMORY_PORT_H_
+
+#define M4U_PORT_DISP_OVL		0
+#define M4U_PORT_DISP_RDMA		1
+#define M4U_PORT_DISP_WDMA		2
+#define M4U_PORT_DISP_DBI		3
+#define M4U_PORT_CAM_WDMA		4
+#define M4U_PORT_CMDQ			5
+#define M4U_PORT_VENC_BSDMA_VDEC_POST0	6
+#define M4U_PORT_MDP_RDMA		7
+#define M4U_PORT_MDP_WDMA		8
+#define M4U_PORT_MDP_ROTO		9
+#define M4U_PORT_MDP_ROTCO		10
+#define M4U_PORT_MDP_ROTVO		11
+#define M4U_PORT_VENC_MVQP		12
+#define M4U_PORT_VENC_MC		13
+#define M4U_PORT_VENC_CDMA_VDEC_CDMA	14
+#define M4U_PORT_VENC_REC_VDEC_WDMA	15
+
+#endif

-- 
2.55.0

