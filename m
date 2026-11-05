From: Ben Grisdale <bengris32@protonmail.ch>
Date: Thu, 05 Nov 2026 14:28:48 +0000
Subject: [PATCH v2 3/6] dt-bindings: timer: mediatek,timer: Add MT8163
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-arm64-initial-support-for-mediatek-mt8163-soc-v2-3-e68d7d428f99@protonmail.ch>
References: <20261105-arm64-initial-support-for-mediatek-mt8163-soc-v2-0-e68d7d428f99@protonmail.ch>
In-Reply-To: <20261105-arm64-initial-support-for-mediatek-mt8163-soc-v2-0-e68d7d428f99@protonmail.ch>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@mediatek.com>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-serial@vger.kernel.org, Ben Grisdale <bengris32@protonmail.ch>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793888941; l=1008;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=dyVoGhC2K4A9ebVKVo2WduqTmMX5amrsOD71wWVM2cs=;
 b=OTStIQccVtbXfsOKoJMQUEM6nzxD0nG6K5+Y5Ody2l1HoHMDW8gTHIuZ23PFPnh8pwfRID2rZ
 qXSU98wrc79AoYUMRQONjXK7f+gient4R1vufxCb/2Fq/ryEZmhG9VI
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible string for the general purpose timer (GPT) on the
MediaTek MT8163 SoC, which is compatible with the MT6577 timer.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Ben Grisdale <bengris32@protonmail.ch>
---
 Documentation/devicetree/bindings/timer/mediatek,timer.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/timer/mediatek,timer.yaml b/Documentation/devicetree/bindings/timer/mediatek,timer.yaml
index 337580dc77d8..fcf4303e1426 100644
--- a/Documentation/devicetree/bindings/timer/mediatek,timer.yaml
+++ b/Documentation/devicetree/bindings/timer/mediatek,timer.yaml
@@ -34,6 +34,7 @@ properties:
               - mediatek,mt7623-timer
               - mediatek,mt8127-timer
               - mediatek,mt8135-timer
+              - mediatek,mt8163-timer
               - mediatek,mt8173-timer
               - mediatek,mt8516-timer
           - const: mediatek,mt6577-timer

-- 
2.56.0

