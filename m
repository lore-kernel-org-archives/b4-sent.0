From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 16 Feb 2024 23:21:04 +0800
Subject: [PATCH RFC 4/4] dt-binding: phy: hisi-inno-usb2: add compatible of
 hisilicon,hi3798mv200-usb2-phy
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240216-inno-phy-v1-4-1ab912f0533f@outlook.com>
References: <20240216-inno-phy-v1-0-1ab912f0533f@outlook.com>
In-Reply-To: <20240216-inno-phy-v1-0-1ab912f0533f@outlook.com>
To: Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Jiancheng Xue <xuejiancheng@hisilicon.com>, 
 Pengcheng Li <lpc.li@hisilicon.com>, Shawn Guo <shawn.guo@linaro.org>
Cc: linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kishon Vijay Abraham I <kishon@ti.com>, 
 David Yang <mmyangfl@gmail.com>, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708096886; l=1106;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=rtHmhLoIl6mBEauH6cAKAA937JKk+tiYVqJ8GZyksSY=;
 b=CgorBV2nYcl95Vm5KnS8MREH8rEe9KkH0P/N7GKmgaLXjwaD3aDCrLwkQ6JOuju+7zmYqBWr0
 3U5xWGbglDxAsFtxFZYVxT810mAEkzarmD0QzBM6T5DwTQUoJwGkI5Y
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It is accessed by direct MMIO, making "ranges" property mandatory for
it.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 .../devicetree/bindings/phy/hisilicon,inno-usb2-phy.yaml       | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/Documentation/devicetree/bindings/phy/hisilicon,inno-usb2-phy.yaml b/Documentation/devicetree/bindings/phy/hisilicon,inno-usb2-phy.yaml
index 73256eee10f9..d702878b8e6e 100644
--- a/Documentation/devicetree/bindings/phy/hisilicon,inno-usb2-phy.yaml
+++ b/Documentation/devicetree/bindings/phy/hisilicon,inno-usb2-phy.yaml
@@ -16,6 +16,7 @@ properties:
       - enum:
           - hisilicon,hi3798cv200-usb2-phy
           - hisilicon,hi3798mv100-usb2-phy
+          - hisilicon,hi3798mv200-usb2-phy
       - const: hisilicon,inno-usb2-phy
 
   reg:
@@ -64,6 +65,15 @@ required:
   - '#size-cells'
   - resets
 
+if:
+  properties:
+    compatible:
+      contains:
+        const: hisilicon,hi3798mv200-inno-usb2-phy
+then:
+  required:
+    - ranges
+
 additionalProperties: false
 
 examples:

-- 
2.43.0

