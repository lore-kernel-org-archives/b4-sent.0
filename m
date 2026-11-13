From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 16:40:40 +0000
Subject: [PATCH v3 09/12] dt-bindings: iommu: verisilicon: Add the reset
 lines
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-hantro-robust-v3-9-82383c722ad2@gmail.com>
References: <20261113-hantro-robust-v3-0-82383c722ad2@gmail.com>
In-Reply-To: <20261113-hantro-robust-v3-0-82383c722ad2@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Nicolas Frattaroli <frattaroli.nicolas@gmail.com>, 
 Andrzej Pietrasiewicz <andrzej.p@collabora.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>
Cc: linux-media@vger.kernel.org, iommu@lists.linux.dev, 
 linux-rockchip@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Sergei Khomenkov <shomenkow@gmail.com>, 
 Tharit Tangkijwanichakul <tharitt97@gmail.com>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794588032; l=1642;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=a+eZKtwV8FPJqeLafXDDZfyk/cG+VGlzjpq9Qo8/bY8=;
 b=L1wozRVp2YsBLp3pnvZOk6Asi0zgyaASac5q4LLSW86i3YR69JPYnHiVkoLFTnbNW5SGSsSLt
 1z+C7LIT1weBo0dAv6on114npHG1f0hH7gdwj0HY9/mqbqP+VVsAHTz
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RK3588 AV1 IOMMU is part of the AV1 block and has no reset lines
of its own: the four AV1 resets also cover it. Its registers can't be
accessed while they are asserted. Describe them.

Suggested-by: Philipp Zabel <p.zabel@pengutronix.de>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 Documentation/devicetree/bindings/iommu/verisilicon,iommu.yaml | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/Documentation/devicetree/bindings/iommu/verisilicon,iommu.yaml b/Documentation/devicetree/bindings/iommu/verisilicon,iommu.yaml
index d3ce9e603b61..70df03102015 100644
--- a/Documentation/devicetree/bindings/iommu/verisilicon,iommu.yaml
+++ b/Documentation/devicetree/bindings/iommu/verisilicon,iommu.yaml
@@ -41,6 +41,13 @@ properties:
   power-domains:
     maxItems: 1
 
+  resets:
+    items:
+      - description: AXI reset line
+      - description: AXI bus interface unit reset line
+      - description: APB reset line
+      - description: APB bus interface unit reset line
+
 required:
   - compatible
   - reg
@@ -55,6 +62,7 @@ examples:
   - |
     #include <dt-bindings/clock/rockchip,rk3588-cru.h>
     #include <dt-bindings/interrupt-controller/arm-gic.h>
+    #include <dt-bindings/reset/rockchip,rk3588-cru.h>
 
     bus {
       #address-cells = <2>;
@@ -67,5 +75,7 @@ examples:
         clocks = <&cru ACLK_AV1>, <&cru PCLK_AV1>;
         clock-names = "core", "iface";
         #iommu-cells = <0>;
+        resets = <&cru SRST_A_AV1>, <&cru SRST_A_AV1_BIU>,
+                 <&cru SRST_P_AV1>, <&cru SRST_P_AV1_BIU>;
       };
     };

-- 
2.55.0

