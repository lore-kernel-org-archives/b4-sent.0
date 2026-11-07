From: Rui Cao <i@udp0.com>
Date: Sat, 07 Nov 2026 20:22:00 +0800
Subject: [PATCH 3/4] dt-bindings: serial: mediatek,uart: Add MT6833
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-mt6833-base-v1-3-bda21083e9f3@udp0.com>
References: <20261107-mt6833-base-v1-0-bda21083e9f3@udp0.com>
In-Reply-To: <20261107-mt6833-base-v1-0-bda21083e9f3@udp0.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@mediatek.com>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-watchdog@vger.kernel.org, linux-serial@vger.kernel.org, 
 Rui Cao <i@udp0.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794054121; l=922;
 i=i@udp0.com; s=20261107; h=from:subject:message-id;
 bh=MCmYdSBiOIw8bXy+sk2ZwCXWlI1Th2hdoYn0z9IY1kA=;
 b=hH0l5R2xfuIHSQAeZ2qg287lrnJtGDXFTbdBa2A0CTVpFX7/OhuoVWLRyB4Xm6uj09pCJm8Q3
 VbJeoSqz8CyAmk0MIi8pEyzn+nMn53mqGVYuiVNWNUIDDbIRw4dd0YM
X-Developer-Key: i=i@udp0.com; a=ed25519;
 pk=XZJKcKgnUUjjyw8KuKy7u2QeIX0JLY/L1Fxzwwje41w=
X-Endpoint-Received: by B4 Relay for i@udp0.com/20261107 with auth_id=1443
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add MediaTek's MT6833 (Dimensity 700). Its UARTs are MT6577-compatible:
MediaTek's MT6833 device tree gives them "mediatek,mt6577-uart" alone.

Signed-off-by: Rui Cao <i@udp0.com>
---
 Documentation/devicetree/bindings/serial/mediatek,uart.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/serial/mediatek,uart.yaml b/Documentation/devicetree/bindings/serial/mediatek,uart.yaml
index 5bd8a8853ae..8fb793c3408 100644
--- a/Documentation/devicetree/bindings/serial/mediatek,uart.yaml
+++ b/Documentation/devicetree/bindings/serial/mediatek,uart.yaml
@@ -34,6 +34,7 @@ properties:
               - mediatek,mt6779-uart
               - mediatek,mt6795-uart
               - mediatek,mt6797-uart
+              - mediatek,mt6833-uart
               - mediatek,mt6893-uart
               - mediatek,mt7622-uart
               - mediatek,mt7623-uart

-- 
Git-157)

