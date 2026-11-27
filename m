From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: broonie@kernel.org, robh@kernel.org, krzk+dt@kernel.org, 
 conor+dt@kernel.org
Cc: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 leilk.liu@mediatek.com, me@adomerle.pw, 
 Roman Vivchar <rva333@protonmail.com>, devicetree@vger.kernel.org, 
 linux-spi@vger.kernel.org, linux-mediatek@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
Subject: [PATCH v4] spi: dt-bindings: mediatek,spi-mt65xx: Add compatible
 for MT6789
Date: Fri, 27 Nov 2026 03:05:42 +0000
Message-Id: <20261127030542.11696-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795748742; l=1611;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=sl67F/NTDPcA/UZxNAmRnJaGzbkAwbuNN2+Fz3m685o=;
 b=Hy2FnvqAyjz44CTPE4b1DcOaO/n2DUIuTQY/BcngfHKgXNEVNbvB0xCQPBkIfYHpR827nRR2h
 aUl2X33T4xcAXuxt7RPmgmphV2WGxgaMxUVCZc1yb9VSOSqmb5NeLy6
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Arseniy Velikanov <me@adomerle.pw>

Add the SPI controller compatible for the MediaTek MT6789 SoC using
mediatek,mt6893-spi as its fallback compatible, as MT6789 SPI is
programming-model compatible with MT6893 and needs no driver change.

Signed-off-by: Arseniy Velikanov <me@adomerle.pw>
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
Changes in v4:
- Split out from the MT6789 pwrap series into its own standalone patch
  (suggested by Roman Vivchar).
- Use spi: dt-bindings: subject prefix (Mark Brown).
- Remove review-history wording from commit message body.
- Add sender Signed-off-by.
- Link to v1: https://lore.kernel.org/linux-mediatek/20250715231921.4527-1-me@adomerle.pw/
- Link to v3: https://lore.kernel.org/r/20261126031001.27288-1-iasnezhkov@gmail.com

Rebased onto mainline with an AI coding assistant.

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


