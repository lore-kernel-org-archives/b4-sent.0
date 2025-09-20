From: Cristian Cozzolino <cristian_ci@protonmail.com>
Date: Sat, 20 Sep 2025 20:23:34 +0200
Subject: [PATCH 09/10] dt-bindings: arm: mediatek: Add MT6582 yarisxl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250920-mt6582-v1-9-b887720f577d@protonmail.com>
References: <20250920-mt6582-v1-0-b887720f577d@protonmail.com>
In-Reply-To: <20250920-mt6582-v1-0-b887720f577d@protonmail.com>
To: Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Russell King <linux@armlinux.org.uk>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sean Wang <sean.wang@mediatek.com>
Cc: linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, 
 Cristian Cozzolino <cristian_ci@protonmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758392693; l=847;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=8QNDDRlIA0pWOB1+uvCR+bTE1fSSumhUEQ1GcGuja2s=;
 b=ecd6hSS6PNAV3+HGWu4LFm6ykdQjzGl4ilAIbSH3jsNcyh3dQc/hX/W9+goC+OpIwSEe4pPnm
 1wQFm/810XYBviG/VAjn3Fo3MgoMSoj7QP1agb12YM4DYkdCN2SAd7z
X-Developer-Key: i=cristian_ci@protonmail.com; a=ed25519;
 pk=xH5IvIPUNHV1Q8R0/pq2CfuVFR/wTiAyuyi6IwedjZY=
X-Endpoint-Received: by B4 Relay for cristian_ci@protonmail.com/20250620 with auth_id=438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an entry for Alcatel Pop C7 (OT-7041D) smartphone board, named
yarisxl, based on MT6582 SoC.

Signed-off-by: Cristian Cozzolino <cristian_ci@protonmail.com>
---
 Documentation/devicetree/bindings/arm/mediatek.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/mediatek.yaml b/Documentation/devicetree/bindings/arm/mediatek.yaml
index f04277873694880d14d78acd39b6c9725394c2f2..5dce019cc998fb7498d7ce60afedb46011fff345 100644
--- a/Documentation/devicetree/bindings/arm/mediatek.yaml
+++ b/Documentation/devicetree/bindings/arm/mediatek.yaml
@@ -38,6 +38,7 @@ properties:
           - const: mediatek,mt6580
       - items:
           - enum:
+              - alcatel,yarisxl
               - prestigio,pmt5008-3g
           - const: mediatek,mt6582
       - items:

-- 
2.49.0

