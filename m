From: Zakariya Hadrami <zkh@mailbox.org>
Date: Wed, 09 Sep 2026 21:38:01 +0200
Subject: [PATCH v4 2/4] dt-bindings: arm: mediatek: Add MT8127 Amazon ford
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260909-mt8127-amazon-ford-basic-v4-2-e9af5c420ab1@mailbox.org>
References: <20260909-mt8127-amazon-ford-basic-v4-0-e9af5c420ab1@mailbox.org>
In-Reply-To: <20260909-mt8127-amazon-ford-basic-v4-0-e9af5c420ab1@mailbox.org>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788982689; l=801;
 i=zkh@mailbox.org; s=20260908; h=from:subject:message-id;
 bh=6yb/XWefb2wuZDPOBmfMPSdJsXYrkjPox9GtsLygo8Q=;
 b=5LffDZHmyNBAclDIcnlkhY1WJo3bKSUx98Ij5Kr3xlAwsWWLtksy5ZX/y2KUMOhsuNjLVaCPJ
 XyeIZo04YroDql575Ijfy+wvDgQN8yZLKhQoYzBtHaMhTPJ/WrBflL+
X-Developer-Key: i=zkh@mailbox.org; a=ed25519;
 pk=up24Xn4ScFKugfT4EJru/UQAS7JOIN+DSQqro+a05T4=
X-Endpoint-Received: by B4 Relay for zkh@mailbox.org/20260908 with auth_id=1015
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add entry for the MT8127 based Amazon ford tablet.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Zakariya Hadrami <zkh@mailbox.org>
---
 Documentation/devicetree/bindings/arm/mediatek.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/mediatek.yaml b/Documentation/devicetree/bindings/arm/mediatek.yaml
index cd4040ad3437..180e6e4948e7 100644
--- a/Documentation/devicetree/bindings/arm/mediatek.yaml
+++ b/Documentation/devicetree/bindings/arm/mediatek.yaml
@@ -122,6 +122,7 @@ properties:
           - const: mediatek,mt7988a
       - items:
           - enum:
+              - amazon,ford
               - mediatek,mt8127-moose
           - const: mediatek,mt8127
       - items:

-- 
2.54.0

