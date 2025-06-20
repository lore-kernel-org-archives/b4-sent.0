From: Max Shevchenko <wctrl@proton.me>
Date: Fri, 20 Jun 2025 18:40:40 +0300
Subject: [PATCH 01/11] dt-bindings: serial: mediatek,uart: add MT6572
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250620-mt6572-v1-1-e2d47820f042@proton.me>
References: <20250620-mt6572-v1-0-e2d47820f042@proton.me>
In-Reply-To: <20250620-mt6572-v1-0-e2d47820f042@proton.me>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Thomas Gleixner <tglx@linutronix.de>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Sean Wang <sean.wang@mediatek.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, linux-watchdog@vger.kernel.org, 
 Max Shevchenko <wctrl@proton.me>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750434231; l=881;
 i=wctrl@proton.me; s=20250603; h=from:subject:message-id;
 bh=V5vXqZRhKe/QPDs6cq0TFRVUVaBGJI2I3Hr9UkPlHFc=;
 b=vQ6ta+L0cSyrNmAT6pH6n2zLB7oXQGEryTst+S7AsWcfCTKZG8qHMy2e8vJCnnwrSNdSGQ89l
 2Gsid+w4Fr/DaCDCS8FA2rfQ6IzGdhG94i/Dl1O9e8ML0+x+9zqmQkF
X-Developer-Key: i=wctrl@proton.me; a=ed25519;
 pk=JXUx3mL/OrnRvbK57HXgugBjEBKq4QgDKJqp7BALm74=
X-Endpoint-Received: by B4 Relay for wctrl@proton.me/20250603 with auth_id=421
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible string for serial on the MT6572 SoC.

Signed-off-by: Max Shevchenko <wctrl@proton.me>
---
 Documentation/devicetree/bindings/serial/mediatek,uart.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/serial/mediatek,uart.yaml b/Documentation/devicetree/bindings/serial/mediatek,uart.yaml
index 1b02f0b197ff46e3530372d1d9303210cca9c2d5..fe283494188dea64bdfdd34a781bf54c8cbc1f05 100644
--- a/Documentation/devicetree/bindings/serial/mediatek,uart.yaml
+++ b/Documentation/devicetree/bindings/serial/mediatek,uart.yaml
@@ -25,6 +25,7 @@ properties:
           - enum:
               - mediatek,mt2701-uart
               - mediatek,mt2712-uart
+              - mediatek,mt6572-uart
               - mediatek,mt6580-uart
               - mediatek,mt6582-uart
               - mediatek,mt6589-uart

-- 
2.50.0

