From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 robh@kernel.org, krzk+dt@kernel.org, conor+dt@kernel.org, 
 broonie@kernel.org
Cc: flora.fu@mediatek.com, amergnat@baylibre.com, leilk.liu@mediatek.com, 
 me@adomerle.pw, devicetree@vger.kernel.org, linux-spi@vger.kernel.org, 
 linux-mediatek@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH v3 4/4] dt-bindings: spi: mediatek,spi-mt65xx: Add
 compatible for MT6789
Date: Thu, 26 Nov 2026 03:10:05 +0000
Message-Id: <20261126031001.27288-5-iasnezhkov@gmail.com>
In-Reply-To: <20261126031001.27288-1-iasnezhkov@gmail.com>
References: <20261126031001.27288-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795662602; l=1154;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=V05m+8yF0Wxx4QXUx+4PM5IgqsffZt/x6aXxrp5Z1ew=;
 b=cyrtbIKhBF62/LrJJ8VXUTpKkPx24CbpfjUK0Apof0fUGKsAQgJ/Iqhvq4HDbPgkaU42WO8Am
 o2A7VFHFbC6AIajM9Sn0kLWapBgjXwKIH4wjbbdvRd7xrR0H9xy+yDU
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Arseniy Velikanov <me@adomerle.pw>

Add the SPI controller compatible for the MediaTek MT6789 SoC with
mediatek,mt6893-spi as its fallback compatible, addressing v1 review
feedback that MT6789 SPI is programming-model compatible with MT6893
without requiring a driver change.

Signed-off-by: Arseniy Velikanov <me@adomerle.pw>
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
 .../devicetree/bindings/spi/mediatek,spi-mt65xx.yaml          | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/spi/mediatek,spi-mt65xx.yaml b/Documentation/devicetree/bindings/spi/mediatek,spi-mt65xx.yaml
index 3bf3eb1..7d82369 100644
--- a/Documentation/devicetree/bindings/spi/mediatek,spi-mt65xx.yaml
+++ b/Documentation/devicetree/bindings/spi/mediatek,spi-mt65xx.yaml
@@ -39,6 +39,10 @@ properties:
               - mediatek,mt7988-spi-single
               - mediatek,mt8188-spi-ipm
           - const: mediatek,spi-ipm
+      - items:
+          - enum:
+              - mediatek,mt6789-spi
+          - const: mediatek,mt6893-spi
       - items:
           - enum:
               - mediatek,mt8196-spi
-- 
2.54.0 (Apple Git-157)


