From: Congcong Yao <congcong.yao@mediatek.com>
Date: Fri, 20 Nov 2026 11:24:55 +0800
Subject: [PATCH v13 1/2] dt-bindings: memory: mediatek: Add SMI reset and
 clamp for MT8188
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-8188-smi-clamp-reset-v13-1-9a9516e81c1d@mediatek.com>
References: <20261120-8188-smi-clamp-reset-v13-0-9a9516e81c1d@mediatek.com>
In-Reply-To: <20261120-8188-smi-clamp-reset-v13-0-9a9516e81c1d@mediatek.com>
To: Yong Wu <yong.wu@mediatek.com>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Rob Herring <robh@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-mediatek@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Friday Yang <friday.yang@mediatek.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795145107; l=4444;
 i=congcong.yao@mediatek.com; s=20260722; h=from:subject:message-id;
 bh=myLx/H8ZE3QU456AZ+2tsE0HkVBhqvt9eD/4HGo/j7c=;
 b=977oJxxJHn924x5I+izxiFab4XsnUxA9DUMiIDZn27azxUnOvD54jXa1t7hCfSrH1Ine7wmvF
 EzR8tW9b7+7DuEnLTYFsPgmjSmBwc7y68ZOnG5+1WxJzhGWiyjFm8kC
X-Developer-Key: i=congcong.yao@mediatek.com; a=ed25519;
 pk=tIrmGxKQQxnfyb48iCCd19063tppPj89U3nupGYAIxg=
X-Endpoint-Received: by B4 Relay for congcong.yao@mediatek.com/20260722 with auth_id=889
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Friday Yang <friday.yang@mediatek.com>

On the MediaTek MT8188 SoC, bus glitches may occur during MTCMOS
on/off transitions. The root cause is a hardware design choice in
the camera subsystem where the SMI LARB and SMI Sub-Common modules
are located in separate power domains and controlled by independent
MTCMOS gates. A timing window exists after the main power domain
is enabled but before the sub-power domain is enabled. During this
window, unstable glitch signals can appear on the bus. Unlike other
subsystems, the camera subsystem lacks a GALs (Globally Asynchronous
Locally Synchronous) hardware module, which would normally handle
cross-domain synchronization and filter out such glitches.
In contrast, other subsystems have their SMI LARB and SMI Sub-Common
within one power domain or could rely on GALs for synchronization.
Thus they are not affected by this issue.

To prevent these glitches from causing bus hang, SMI requires clamp
and reset operations. This change adds the 'resets' and 'reset-names'
properties to SMI LARBs within camera subsystem to support the necessary
reset operations. This reset setting is exclusively required for the
MediaTek MT8188 platform and remains inactive on other SoCs.

We also add 'smi-sub-common' in the smi-common binding for MT8188.
This indicates that some SMI LARBs are connected to the SMI Sub-Common,
which in turn is connected to the SMI Common. The hardware block diagram
can be described as follows.

             SMI-Common(Smart Multimedia Interface Common)
                 |
         +----------------+------------------+
         |                |                  |
         |                |                  |
         |                |                  |
         |                |                  |
         |                |                  |
       larb0       SMI-Sub-Common0     SMI-Sub-Common1
                   |      |     |      |             |
                  larb1  larb2 larb3  larb7       larb9

Signed-off-by: Friday Yang <friday.yang@mediatek.com>
Reviewed-by: AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Acked-by: Rob Herring <robh@kernel.org>
---
 .../memory-controllers/mediatek,smi-common.yaml       |  2 ++
 .../memory-controllers/mediatek,smi-larb.yaml         | 19 +++++++++++++++++++
 2 files changed, 21 insertions(+)

diff --git a/Documentation/devicetree/bindings/memory-controllers/mediatek,smi-common.yaml b/Documentation/devicetree/bindings/memory-controllers/mediatek,smi-common.yaml
index 33c989f7fc33..65931adcc6fc 100644
--- a/Documentation/devicetree/bindings/memory-controllers/mediatek,smi-common.yaml
+++ b/Documentation/devicetree/bindings/memory-controllers/mediatek,smi-common.yaml
@@ -55,6 +55,7 @@ properties:
           - mediatek,mt8186-smi-common
           - mediatek,mt8188-smi-common-vdo
           - mediatek,mt8188-smi-common-vpp
+          - mediatek,mt8188-smi-sub-common
           - mediatek,mt8189-smi-common
           - mediatek,mt8189-smi-sub-common
           - mediatek,mt8192-smi-common
@@ -125,6 +126,7 @@ allOf:
         compatible:
           contains:
             enum:
+              - mediatek,mt8188-smi-sub-common
               - mediatek,mt8189-smi-sub-common
               - mediatek,mt8195-smi-sub-common
     then:
diff --git a/Documentation/devicetree/bindings/memory-controllers/mediatek,smi-larb.yaml b/Documentation/devicetree/bindings/memory-controllers/mediatek,smi-larb.yaml
index 9a5dafd7c07e..79ef73e52c5d 100644
--- a/Documentation/devicetree/bindings/memory-controllers/mediatek,smi-larb.yaml
+++ b/Documentation/devicetree/bindings/memory-controllers/mediatek,smi-larb.yaml
@@ -71,6 +71,12 @@ properties:
     description: the hardware id of this larb. It's only required when this
       hardware id is not consecutive from its M4U point of view.
 
+  resets:
+    maxItems: 1
+
+  reset-names:
+    const: larb
+
 required:
   - compatible
   - reg
@@ -129,6 +135,19 @@ allOf:
       required:
         - mediatek,larb-id
 
+  - if:  # only for image, camera and ipe subsys
+      properties:
+        compatible:
+          const: mediatek,mt8188-smi-larb
+        mediatek,larb-id:
+          enum:
+            [ 9, 10, 11, 12, 13, 16, 17, 18, 19, 20 ]
+
+    then:
+      required:
+        - resets
+        - reset-names
+
 additionalProperties: false
 
 examples:

-- 
2.43.0

