From: Ben Grisdale <bengris32@protonmail.ch>
Date: Mon, 19 Oct 2026 01:40:00 +0100
Subject: [PATCH 4/8] dt-bindings: serial: mediatek,uart: Add MT8163
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-arm64-initial-support-for-mediatek-mt8163-soc-v1-4-f2462b2d2437@protonmail.ch>
References: <20261019-arm64-initial-support-for-mediatek-mt8163-soc-v1-0-f2462b2d2437@protonmail.ch>
In-Reply-To: <20261019-arm64-initial-support-for-mediatek-mt8163-soc-v1-0-f2462b2d2437@protonmail.ch>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@mediatek.com>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-serial@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792370441; l=917;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=bqpoWOz5GryrI2HN8kHkj5zmoQrbZs18JhW/gGNozgE=;
 b=pY5JB788jlgfUUPbGOrgKX3YZvvIGTDJ3RA+0cCdLeSM0vOOD6IRRKZ7ZMWU1ekwIniBZqGUR
 68JwQqqUL4DBzLi3I+JzVJMDoFKp35H0ZERWDxmEnKGxMoG/zGXs6Wy
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible string for the UART controllers on the MediaTek MT8163
SoC, which are compatible with the MT6577 UART.

Signed-off-by: Ben Grisdale <bengris32@protonmail.ch>
---
 Documentation/devicetree/bindings/serial/mediatek,uart.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/serial/mediatek,uart.yaml b/Documentation/devicetree/bindings/serial/mediatek,uart.yaml
index 5bd8a8853ae0..11801b58f637 100644
--- a/Documentation/devicetree/bindings/serial/mediatek,uart.yaml
+++ b/Documentation/devicetree/bindings/serial/mediatek,uart.yaml
@@ -43,6 +43,7 @@ properties:
               - mediatek,mt7988-uart
               - mediatek,mt8127-uart
               - mediatek,mt8135-uart
+              - mediatek,mt8163-uart
               - mediatek,mt8173-uart
               - mediatek,mt8183-uart
               - mediatek,mt8186-uart

-- 
2.56.0

