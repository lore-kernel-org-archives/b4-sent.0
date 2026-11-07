From: Rui Cao <i@udp0.com>
Date: Sat, 07 Nov 2026 20:21:58 +0800
Subject: [PATCH 1/4] dt-bindings: arm: mediatek: Add MT6833 and the Xiaomi
 Redmi Note 13 5G
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-mt6833-base-v1-1-bda21083e9f3@udp0.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794054121; l=875;
 i=i@udp0.com; s=20261107; h=from:subject:message-id;
 bh=uNRP9WqNOZ9uVaqNn9d41dwM2xyX/yc6xIzymdwBqLg=;
 b=0UOOOfIfHwIQKYbayAqLFyPCAGDYBveCla4WK1KIfCJ9GeX3M+2VuO9cJQCJ0xAXcyRe522MB
 qiM+rDqx3wiDC/m8t3Uq+lQWZbO/Bhd7KZPE0pYxz38Xt6ebC7l7Uoi
X-Developer-Key: i=i@udp0.com; a=ed25519;
 pk=XZJKcKgnUUjjyw8KuKy7u2QeIX0JLY/L1Fxzwwje41w=
X-Endpoint-Received: by B4 Relay for i@udp0.com/20261107 with auth_id=1443
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add MediaTek's MT6833 (Dimensity 700) and the Xiaomi Redmi Note 13 5G,
codenamed gold, which is built on it.

Signed-off-by: Rui Cao <i@udp0.com>
---
 Documentation/devicetree/bindings/arm/mediatek.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/mediatek.yaml b/Documentation/devicetree/bindings/arm/mediatek.yaml
index 180e6e4948e..900f16b57dc 100644
--- a/Documentation/devicetree/bindings/arm/mediatek.yaml
+++ b/Documentation/devicetree/bindings/arm/mediatek.yaml
@@ -72,6 +72,10 @@ properties:
               - archermind,mt6797-x20-dev
               - mediatek,mt6797-evb
           - const: mediatek,mt6797
+      - items:
+          - enum:
+              - xiaomi,gold
+          - const: mediatek,mt6833
       - items:
           - enum:
               - bananapi,bpi-r64

-- 
Git-157)

