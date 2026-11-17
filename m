From: Ben Grisdale <bengris32@protonmail.ch>
Date: Tue, 17 Nov 2026 13:28:08 +0000
Subject: [PATCH 1/2] dt-bindings: soc: mediatek: pwrap: Add MT8163
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-mt8163-pwrap-support-v1-1-b00fa10035a5@protonmail.ch>
References: <20261117-mt8163-pwrap-support-v1-0-b00fa10035a5@protonmail.ch>
In-Reply-To: <20261117-mt8163-pwrap-support-v1-0-b00fa10035a5@protonmail.ch>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Flora Fu <flora.fu@mediatek.com>, Alexandre Mergnat <amergnat@baylibre.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794922196; l=910;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=GV/5pX+NzfGhR+iyJ7t6HyhLHCTD5LtZGFKHPoKfPAs=;
 b=vrAvGCB+XLv7UU8TZgokSN8oR/McBruaGO/aTnggVHhcFbKi3spHbdqO6nBuZq1ibA3RXMjb/
 r+51jspJwILAHWnlW+yW0UoOEGCyRKPrEmCM03E65L9iGyywp+0sx0z
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible for the PMIC wrapper found on the MediaTek MT8163 SoC.

Signed-off-by: Ben Grisdale <bengris32@protonmail.ch>
---
 Documentation/devicetree/bindings/soc/mediatek/mediatek,pwrap.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/soc/mediatek/mediatek,pwrap.yaml b/Documentation/devicetree/bindings/soc/mediatek/mediatek,pwrap.yaml
index 79b755858bad..de739a8ab75c 100644
--- a/Documentation/devicetree/bindings/soc/mediatek/mediatek,pwrap.yaml
+++ b/Documentation/devicetree/bindings/soc/mediatek/mediatek,pwrap.yaml
@@ -38,6 +38,7 @@ properties:
               - mediatek,mt6873-pwrap
               - mediatek,mt7622-pwrap
               - mediatek,mt8135-pwrap
+              - mediatek,mt8163-pwrap
               - mediatek,mt8173-pwrap
               - mediatek,mt8183-pwrap
               - mediatek,mt8186-pwrap

-- 
2.56.0

