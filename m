From: Ben Grisdale <bengris32@protonmail.ch>
Date: Thu, 05 Nov 2026 14:28:46 +0000
Subject: [PATCH v2 1/6] dt-bindings: arm: mediatek: Add MT8163 Amazon Echo
 Dot (2016)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-arm64-initial-support-for-mediatek-mt8163-soc-v2-1-e68d7d428f99@protonmail.ch>
References: <20261105-arm64-initial-support-for-mediatek-mt8163-soc-v2-0-e68d7d428f99@protonmail.ch>
In-Reply-To: <20261105-arm64-initial-support-for-mediatek-mt8163-soc-v2-0-e68d7d428f99@protonmail.ch>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@mediatek.com>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-serial@vger.kernel.org, Ben Grisdale <bengris32@protonmail.ch>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793888941; l=964;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=68O/KFoEd8IiZ5hJEtL4JTCzMFkMQ0kQN5eapp9a42s=;
 b=wcE3Nn99jWzv7w1Dm9Rw94NFLpd/08GdQen1Di6JhiiMKBMGhEhqLbZz5u/In/9+1LTkJhft+
 0JHPerJVhL2AGcHe9vgNkx/oB0AJh3go+C+huLixrbfd7m2PN+ysRIj
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible strings for the MediaTek MT8163 SoC and the Amazon Echo
Dot (2nd generation, 2016), codenamed "biscuit".

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Ben Grisdale <bengris32@protonmail.ch>
---
 Documentation/devicetree/bindings/arm/mediatek.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/mediatek.yaml b/Documentation/devicetree/bindings/arm/mediatek.yaml
index 180e6e4948e7..15db402552c1 100644
--- a/Documentation/devicetree/bindings/arm/mediatek.yaml
+++ b/Documentation/devicetree/bindings/arm/mediatek.yaml
@@ -129,6 +129,10 @@ properties:
           - enum:
               - mediatek,mt8135-evbp1
           - const: mediatek,mt8135
+      - items:
+          - enum:
+              - amazon,biscuit
+          - const: mediatek,mt8163
       - items:
           - enum:
               - mediatek,mt8167-pumpkin

-- 
2.56.0

