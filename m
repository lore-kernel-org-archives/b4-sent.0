From: Roman Vivchar <rva333@protonmail.com>
Date: Thu, 26 Nov 2026 14:39:54 +0200
Subject: [PATCH 1/8] dt-bindings: arm: mediatek: add mt6768
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-6768-init-v1-1-abc364a2447e@protonmail.com>
References: <20261126-6768-init-v1-0-abc364a2447e@protonmail.com>
In-Reply-To: <20261126-6768-init-v1-0-abc364a2447e@protonmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@mediatek.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-serial@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795696875; l=832;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=+T3AUDL+O5mAW6RfROgXyiwYY80LTqaNM47Mh38zQfE=;
 b=B3tbwQiqixOoeHwCb3U9Tf7kC2DuxVBpc4FUIiOnR5yoA+i9CgFFALnVOjc8Y0gt+C4pwvigM
 cqJ8Fr+90poDF2gy6Z0RmnHb/WV4NJ0DE9uvhzjEKKIDJJkl/KKvJ1J
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Xiaomi Redmi Note 9 smartphone based on the MediaTek mt6768 SoC.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 Documentation/devicetree/bindings/arm/mediatek.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/mediatek.yaml b/Documentation/devicetree/bindings/arm/mediatek.yaml
index 26f096587631..37189fb177c7 100644
--- a/Documentation/devicetree/bindings/arm/mediatek.yaml
+++ b/Documentation/devicetree/bindings/arm/mediatek.yaml
@@ -58,6 +58,10 @@ properties:
           - enum:
               - mediatek,mt6765-evb
           - const: mediatek,mt6765
+      - items:
+          - enum:
+              - xiaomi,merlin
+          - const: mediatek,mt6768
       - items:
           - enum:
               - mediatek,mt6779-evb

-- 
2.56.1

