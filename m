From: Max Shevchenko <wctrl@proton.me>
Date: Thu, 26 Jun 2025 11:53:55 +0300
Subject: [PATCH v2 02/11] dt-bindings: interrupt-controller:
 mediatek,mt6577-sysirq: add MT6572
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250626-mt6572-v2-2-f7f842196986@proton.me>
References: <20250626-mt6572-v2-0-f7f842196986@proton.me>
In-Reply-To: <20250626-mt6572-v2-0-f7f842196986@proton.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750928035; l=1081;
 i=wctrl@proton.me; s=20250603; h=from:subject:message-id;
 bh=ta3ujqr64pHbaGSlqm/Z8V+hlQFPt/BKX+PtFYGGo7c=;
 b=N7WTUdWGPF56DU0xKHYlV34F+JsC61gaqGOETMQ/cWPTeHSJpWFwZ0sT8FgqTbNhOMlTH8ukC
 tbzCPLf5dCoDQiqRY4nhQVb9Xv9wiKvGRZ9NUDILa9z5KakOldtmVE5
X-Developer-Key: i=wctrl@proton.me; a=ed25519;
 pk=JXUx3mL/OrnRvbK57HXgugBjEBKq4QgDKJqp7BALm74=
X-Endpoint-Received: by B4 Relay for wctrl@proton.me/20250603 with auth_id=421
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible string for sysirq on the MT6572 SoC.

Reviewed-by: AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Signed-off-by: Max Shevchenko <wctrl@proton.me>
---
 .../devicetree/bindings/interrupt-controller/mediatek,mt6577-sysirq.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/interrupt-controller/mediatek,mt6577-sysirq.yaml b/Documentation/devicetree/bindings/interrupt-controller/mediatek,mt6577-sysirq.yaml
index 123d24b05556c67374fbb87abe5e16c65031d2ed..30d76692ca87b507900076cd2f7d2e7ed2605b33 100644
--- a/Documentation/devicetree/bindings/interrupt-controller/mediatek,mt6577-sysirq.yaml
+++ b/Documentation/devicetree/bindings/interrupt-controller/mediatek,mt6577-sysirq.yaml
@@ -21,6 +21,7 @@ properties:
           - enum:
               - mediatek,mt2701-sysirq
               - mediatek,mt2712-sysirq
+              - mediatek,mt6572-sysirq
               - mediatek,mt6580-sysirq
               - mediatek,mt6582-sysirq
               - mediatek,mt6589-sysirq

-- 
2.50.0

