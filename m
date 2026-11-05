From: Ben Grisdale <bengris32@protonmail.ch>
Date: Thu, 05 Nov 2026 14:28:49 +0000
Subject: [PATCH v2 4/6] dt-bindings: serial: mediatek,uart: Add MT8163
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-arm64-initial-support-for-mediatek-mt8163-soc-v2-4-e68d7d428f99@protonmail.ch>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793888941; l=987;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=NhECQjtErCffD7Hrf6rEzEREzak9GzWgJW4fU0Mkz9c=;
 b=Sagi85f7uqdQx0Lk0jaevhCGFN6sjUpjC6RXRjngoy5jOckdLEJRPF7vSMWs8fxmdinu/7upi
 rcmByZmoZx3CLsBhfgZQbnienY9E6Gz1Al2eDJmZcD54tkytNttO8LU
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible string for the UART controllers on the MediaTek MT8163
SoC, which are compatible with the MT6577 UART.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
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

