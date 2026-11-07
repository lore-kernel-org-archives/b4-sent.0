From: Rui Cao <i@udp0.com>
Date: Sat, 07 Nov 2026 20:21:59 +0800
Subject: [PATCH 2/4] dt-bindings: watchdog: mediatek,mtk-wdt: Add MT6833
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-mt6833-base-v1-2-bda21083e9f3@udp0.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794054121; l=892;
 i=i@udp0.com; s=20261107; h=from:subject:message-id;
 bh=BmzvMDSSGsZ+iD74UsWjZpukUgHxSh4ohrYyIUhF5jE=;
 b=F57GxYhOMBYbveCONM116XPFb4pK0L12+SfnY49y8GXm9fBg4NWCDOdE9k9AtF/ZThFPv++p0
 yd0LKdZEn5wCoZw8LDCNADha3POq9r+6aEPlO5YwWRiGrxn6mZG+eXC
X-Developer-Key: i=i@udp0.com; a=ed25519;
 pk=XZJKcKgnUUjjyw8KuKy7u2QeIX0JLY/L1Fxzwwje41w=
X-Endpoint-Received: by B4 Relay for i@udp0.com/20261107 with auth_id=1443
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add MediaTek's MT6833 (Dimensity 700). Its watchdog works as MT6589's,
which it falls back to.

Signed-off-by: Rui Cao <i@udp0.com>
---
 Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml b/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml
index f9b725592c2..dfdc06c758d 100644
--- a/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml
+++ b/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml
@@ -38,6 +38,7 @@ properties:
               - mediatek,mt6572-wdt
               - mediatek,mt6582-wdt
               - mediatek,mt6797-wdt
+              - mediatek,mt6833-wdt
               - mediatek,mt7622-wdt
               - mediatek,mt7623-wdt
               - mediatek,mt7629-wdt

-- 
Git-157)

