From: Zakariya Hadrami <zkh1@proton.me>
Date: Wed, 17 Jun 2026 11:20:13 +0900
Subject: [PATCH 4/5] dt-bindings: arm: mediatek: Add MT8127 Amazon ford
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260617-mt8127-amazon-ford-basic-v1-4-d02ad15ac359@proton.me>
References: <20260617-mt8127-amazon-ford-basic-v1-0-d02ad15ac359@proton.me>
In-Reply-To: <20260617-mt8127-amazon-ford-basic-v1-0-d02ad15ac359@proton.me>
To: Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sean Wang <sean.wang@mediatek.com>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-watchdog@vger.kernel.org, Zakariya Hadrami <zkh1@proton.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781662870; l=814;
 i=zkh1@proton.me; s=20260616; h=from:subject:message-id;
 bh=CteuquPMK3ekAPrSrikG9MTiPrJ2S6hY2cdfoA37n5Y=;
 b=QvALVdl1TyvRHk4IbG6e8/iH3V6MqHh3AVd8EW+tQXxk/ZkC7U92/MSbTx1juqnWNb4PxHErv
 mxOxymgs/kyDPvoRRdhunQYznwxiVCPOYX2uHPy6LmUWEZoNykVaRJ6
X-Developer-Key: i=zkh1@proton.me; a=ed25519;
 pk=9DiJwhINAERP95fbFofXSP77GEnvfO/rMIRRRFDhaoc=
X-Endpoint-Received: by B4 Relay for zkh1@proton.me/20260616 with auth_id=824
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add entry for the MT8127 based Amazon ford tablet.

Signed-off-by: Zakariya Hadrami <zkh1@proton.me>
---
 Documentation/devicetree/bindings/arm/mediatek.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/mediatek.yaml b/Documentation/devicetree/bindings/arm/mediatek.yaml
index 382d0eb4d0af..5ddc79689df9 100644
--- a/Documentation/devicetree/bindings/arm/mediatek.yaml
+++ b/Documentation/devicetree/bindings/arm/mediatek.yaml
@@ -124,6 +124,10 @@ properties:
           - enum:
               - mediatek,mt8127-moose
           - const: mediatek,mt8127
+      - items:
+          - enum:
+              - amazon,ford
+          - const: mediatek,mt8127
       - items:
           - enum:
               - mediatek,mt8135-evbp1

-- 
2.54.0

