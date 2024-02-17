From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 17 Feb 2024 12:40:35 +0800
Subject: [PATCH 2/2] dt-binding: watchdog: arm,sp805: document the reset
 signal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240217-hisi-wdt-v1-2-cdb9ddcab968@outlook.com>
References: <20240217-hisi-wdt-v1-0-cdb9ddcab968@outlook.com>
In-Reply-To: <20240217-hisi-wdt-v1-0-cdb9ddcab968@outlook.com>
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Viresh Kumar <vireshk@kernel.org>
Cc: linux-watchdog@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708144834; l=1040;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=HUldbqmBl21KlfOEiljP/y3O1Exgubj2VKDOCZ4vRqw=;
 b=/PKUGGOnHUsZta+uz74jNQ9BXBn4YtiauYN296RUBFBiX1nUzbuQoSFRuQn1heUk1+6JtgNd6
 2wcAhavXQaRAEDph8fHPc0BJADn6Dkns1GG3jF0qjNafC7XnpBEz7EC
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The reset signal needs to be deasserted before operation of sp805
module. Document in the binding.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 Documentation/devicetree/bindings/watchdog/arm,sp805.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/watchdog/arm,sp805.yaml b/Documentation/devicetree/bindings/watchdog/arm,sp805.yaml
index 7aea255b301b..6d4f63f23f1a 100644
--- a/Documentation/devicetree/bindings/watchdog/arm,sp805.yaml
+++ b/Documentation/devicetree/bindings/watchdog/arm,sp805.yaml
@@ -50,6 +50,11 @@ properties:
       - const: wdog_clk
       - const: apb_pclk
 
+  resets:
+    maxItems: 1
+    description: |
+      WDOGRESn input reset signal for sp805 module.
+
 required:
   - compatible
   - reg
@@ -67,4 +72,5 @@ examples:
         interrupts = <GIC_SPI 406 IRQ_TYPE_LEVEL_HIGH>;
         clocks = <&wdt_clk>, <&apb_pclk>;
         clock-names = "wdog_clk", "apb_pclk";
+        resets = <&wdt_rst>;
     };

-- 
2.43.0

