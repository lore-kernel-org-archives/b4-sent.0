From: Roman Vivchar <rva333@protonmail.com>
Date: Fri, 14 Aug 2026 16:13:52 +0300
Subject: [PATCH] dt-bindings: input: mediatek,mt6779-keypad: add mt6572
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260814-6572-dt-keypad-v1-1-2ceff2373211@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDC0MTXTNTcyPdlBLd7NTKgsQUXaM0QwNDS4NUA4skAyWgpoKi1LTMCrC
 B0bEQfnFpUlZqcgnIFKXaWgCOtcbzcgAAAA==
X-Change-ID: 20260814-6572-dt-keypad-2f10190e08b0
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786713259; l=1041;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=dnFCakk4vuGhlPYs5js9z6YmW0GnQtXr03hvBnhKxc0=;
 b=n5oqb/qqHWnBuYOLTPzQm8tLKvcunF+q145rv7u6gZq2JHxvdLiDZCezeD+FxS7AWq7o+O9F0
 jNVhnoo38TAD3bJqDh5TZBqVx6BwcorClnTnwfd24kRG74EOJNUf32w
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible string for the mt6572 keypad, that is compatible with
mt6779.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 Documentation/devicetree/bindings/input/mediatek,mt6779-keypad.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/input/mediatek,mt6779-keypad.yaml b/Documentation/devicetree/bindings/input/mediatek,mt6779-keypad.yaml
index 914dd3283df3..20fa41f691ed 100644
--- a/Documentation/devicetree/bindings/input/mediatek,mt6779-keypad.yaml
+++ b/Documentation/devicetree/bindings/input/mediatek,mt6779-keypad.yaml
@@ -26,6 +26,7 @@ properties:
       - const: mediatek,mt6779-keypad
       - items:
           - enum:
+              - mediatek,mt6572-keypad
               - mediatek,mt6873-keypad
               - mediatek,mt8183-keypad
               - mediatek,mt8365-keypad

---
base-commit: 8cd9520d35a6c38db6567e97dd93b1f11f185dc6
change-id: 20260814-6572-dt-keypad-2f10190e08b0

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

