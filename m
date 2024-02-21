From: Yang Xiwen <forbidden405@outlook.com>
Date: Wed, 21 Feb 2024 19:56:42 +0800
Subject: [PATCH v3 2/2] dt-bindings: watchdog: arm,sp805: document the
 reset signal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-hisi-wdt-v3-2-9642613dc2e6@outlook.com>
References: <20240221-hisi-wdt-v3-0-9642613dc2e6@outlook.com>
In-Reply-To: <20240221-hisi-wdt-v3-0-9642613dc2e6@outlook.com>
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Viresh Kumar <vireshk@kernel.org>
Cc: linux-watchdog@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708516604; l=1096;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=Y/0S+rlwzPt8yQv5SlX93rhiayW10MfuG7cp9vIgSlo=;
 b=WAnlEEfrbRpjG0jx4dwCj49jhQD2lZrFbD3WokV1xI133SJv8xB8yB1Uuj9KnDAItIC1doRVQ
 9vHJ8rPx4xxCsm/Luh0VWWK67UJNNnBQt3vx7aQ200E8AxkIRcXKH1Q
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The reset signal needs to be deasserted before operation of sp805
module. Document in the binding.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 Documentation/devicetree/bindings/watchdog/arm,sp805.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/watchdog/arm,sp805.yaml b/Documentation/devicetree/bindings/watchdog/arm,sp805.yaml
index 7aea255b301b..bd7c09ed1938 100644
--- a/Documentation/devicetree/bindings/watchdog/arm,sp805.yaml
+++ b/Documentation/devicetree/bindings/watchdog/arm,sp805.yaml
@@ -50,6 +50,10 @@ properties:
       - const: wdog_clk
       - const: apb_pclk
 
+  resets:
+    maxItems: 1
+    description: WDOGRESn input reset signal for sp805 module.
+
 required:
   - compatible
   - reg
@@ -67,4 +71,5 @@ examples:
         interrupts = <GIC_SPI 406 IRQ_TYPE_LEVEL_HIGH>;
         clocks = <&wdt_clk>, <&apb_pclk>;
         clock-names = "wdog_clk", "apb_pclk";
+        resets = <&wdt_rst>;
     };

-- 
2.43.0

