From: Roman Vivchar <rva333@protonmail.com>
Date: Thu, 05 Nov 2026 13:29:12 +0200
Subject: [PATCH] dt-bindings: input: mediatek,mt6779-keypad: add mt6595
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-6595-dt-keypad-v1-1-f0911f40d3ad@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQ5EMBCA4VeROZukLWNjX0UcSgezEistQsS7b
 5fjd/j/EwJ74QDv5ATPmwT5ThE6TaAd7NQziosGo0yhtSIsqCR0C458zNahy5TNDXUv4gxiNHv
 uZL+HVf04rM2H2+V/gev6AR8w/uRyAAAA
X-Change-ID: 20261105-6595-dt-keypad-d30a425f75e3
To: Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793878154; l=1042;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=1ilWPyJZwXIBoX7Ef7K1dJA5qk/q0NQM6AQiVyoSYi0=;
 b=gsl/L1Nidw63mZs0argyawLAon+vgqnunhZ5yy+E3ul11j/wHv6bXMvJ5xrU1xKAHQyY96nB5
 xCtkMOJ53ExAWZQr9KQL1lf3SKp0g2voI0Xnc9l1YvqCV2iz8HIHOOy
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible string for the mt6595 keypad, that is compatible with
mt6779.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 Documentation/devicetree/bindings/input/mediatek,mt6779-keypad.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/input/mediatek,mt6779-keypad.yaml b/Documentation/devicetree/bindings/input/mediatek,mt6779-keypad.yaml
index e0758aac7ffe..9f0da1240187 100644
--- a/Documentation/devicetree/bindings/input/mediatek,mt6779-keypad.yaml
+++ b/Documentation/devicetree/bindings/input/mediatek,mt6779-keypad.yaml
@@ -27,6 +27,7 @@ properties:
       - items:
           - enum:
               - mediatek,mt6572-keypad
+              - mediatek,mt6595-keypad
               - mediatek,mt6873-keypad
               - mediatek,mt8173-keypad
               - mediatek,mt8183-keypad

---
base-commit: 8b7179210b22f8e48a82c5ceacb9d56a9c4cfec4
change-id: 20261105-6595-dt-keypad-d30a425f75e3

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

