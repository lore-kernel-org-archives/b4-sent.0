From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:17:31 +0000
Subject: [PATCH 1/5] dt-bindings: media: rockchip,rk3568-vepu: Add the
 reset lines
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-hantro-robust-v1-1-6b6269c05bfa@gmail.com>
References: <20261110-hantro-robust-v1-0-6b6269c05bfa@gmail.com>
In-Reply-To: <20261110-hantro-robust-v1-0-6b6269c05bfa@gmail.com>
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
 Jernej Skrabec <jernej.skrabec@gmail.com>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295050; l=1139;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=ugbiMmzavaBp42/wsrF8NeFbBYCV92Ge5prcqLnmtpY=;
 b=+9fz2/3wGBnPFV8f0UkHTfdqh2NhGskFForb8xFWq6PP+8OsHBmC22wvyPsEXzicgB+a8locc
 r5PxOzmt8YzBcujcPrRYHo0lo2XyiDoJHlI5/rJQI0aTvshFNe/pdX5
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The VEPU121 encoder cores of the RK3588 each have their own AXI and AHB
reset lines in the CRU (SRST_A_JPEG_ENCODERx and SRST_H_JPEG_ENCODERx).
They are needed to recover a core that is stuck on the bus, which its
registers can't stop.

Describe them as optional, so that existing device trees stay valid.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../devicetree/bindings/media/rockchip,rk3568-vepu.yaml        | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/rockchip,rk3568-vepu.yaml b/Documentation/devicetree/bindings/media/rockchip,rk3568-vepu.yaml
index d246f5d38427..e9fda4373f0f 100644
--- a/Documentation/devicetree/bindings/media/rockchip,rk3568-vepu.yaml
+++ b/Documentation/devicetree/bindings/media/rockchip,rk3568-vepu.yaml
@@ -32,6 +32,16 @@ properties:
       - const: aclk
       - const: hclk
 
+  resets:
+    items:
+      - description: AXI reset line
+      - description: AHB reset line
+
+  reset-names:
+    items:
+      - const: axi
+      - const: ahb
+
   power-domains:
     maxItems: 1
 

-- 
2.55.0

