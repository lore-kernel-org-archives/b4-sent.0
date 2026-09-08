From: Zakariya Hadrami <zkh@mailbox.org>
Date: Tue, 08 Sep 2026 23:59:14 +0200
Subject: [PATCH v3 1/4] dt-bindings: watchdog: mediatek: Add MT8127
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-mt8127-amazon-ford-basic-v3-1-fc46bf1b6cb2@mailbox.org>
References: <20260908-mt8127-amazon-ford-basic-v3-0-fc46bf1b6cb2@mailbox.org>
In-Reply-To: <20260908-mt8127-amazon-ford-basic-v3-0-fc46bf1b6cb2@mailbox.org>
To: Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sean Wang <sean.wang@mediatek.com>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-watchdog@vger.kernel.org, zkh1@proton.me, 
 Zakariya Hadrami <zkh@mailbox.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788904772; l=1002;
 i=zkh@mailbox.org; s=20260908; h=from:subject:message-id;
 bh=W+fYT6FEZ+BsGX4xaHNPJY7m/vM9qOAG6TkfJVwh8eg=;
 b=PCj7oU1XtdbOT9dwhnGljvOvur9e+ECwW7YUpNX1BodnT9teCU02+9L3pZFFViomE5NyniZw4
 hjGyJVQOETEBuADtfMYhrTrh6Bbtkq6O8PfUV611A1nx2e4QE1UizhY
X-Developer-Key: i=zkh@mailbox.org; a=ed25519;
 pk=up24Xn4ScFKugfT4EJru/UQAS7JOIN+DSQqro+a05T4=
X-Endpoint-Received: by B4 Relay for zkh@mailbox.org/20260908 with auth_id=1015
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add entry for MT8127 SoC's watchdog which is compatible with MT6589's
one.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Acked-by: Guenter Roeck <linux@roeck-us.net>
Signed-off-by: Zakariya Hadrami <zkh@mailbox.org>
---
 Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml b/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml
index 953629cb9558..e6e4546da0aa 100644
--- a/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml
+++ b/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml
@@ -40,6 +40,7 @@ properties:
               - mediatek,mt7622-wdt
               - mediatek,mt7623-wdt
               - mediatek,mt7629-wdt
+              - mediatek,mt8127-wdt
               - mediatek,mt8173-wdt
               - mediatek,mt8188-wdt
               - mediatek,mt8189-wdt

-- 
2.54.0

