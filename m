From: Kohei Otsuka <kohei@spacemachines.com>
Date: Tue, 03 Nov 2026 11:11:31 +1100
Subject: [PATCH 1/2] dt-bindings: serial: 8250: add Microchip Core16550
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-core16550-rs485-v1-1-6d15ebe1e5b9@spacemachines.com>
References: <20261103-core16550-rs485-v1-0-6d15ebe1e5b9@spacemachines.com>
In-Reply-To: <20261103-core16550-rs485-v1-0-6d15ebe1e5b9@spacemachines.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Lubomir Rintel <lkundrak@v3.sk>, 
 devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 conor.dooley@microchip.com, Kohei Otsuka <kohei@spacemachines.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793664697; l=1092;
 i=kohei@spacemachines.com; s=20261103; h=from:subject:message-id;
 bh=5TXl591/YzqcOSELFalYpXwEI+0DMkNWmIZ4V551fL0=;
 b=+enBIazHpUREEwhYKyIiaqaWTCMaO/lY47NrchaLaXzIBuAE3LAU2vQfh1AfMT3mPZf1nj+ca
 2hEZDtprBBrDgOn5xu5WykMIW1bk9zf6IiZc8/qpqOI0hqZXAOTVGMM
X-Developer-Key: i=kohei@spacemachines.com; a=ed25519;
 pk=1kit/vmX5JiLGH9NPcqlvT55ISWaLmNipdL5VrriRt0=
X-Endpoint-Received: by B4 Relay for kohei@spacemachines.com/20261103 with auth_id=1385
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Core16550 is a 16550-compatible UART soft IP core for Microchip FPGAs,
including the fabric of PolarFire SoC. Its registers follow the 16550A,
so ns16550a stays the fallback, but it raises no interrupt on TEMT,
which the driver has to know about to support RS-485 on it.

Add microchip,core16550 with ns16550a as the fallback.

Link: https://github.com/linux4microchip/meta-mchp/issues/5
Signed-off-by: Kohei Otsuka <kohei@spacemachines.com>
---
 Documentation/devicetree/bindings/serial/8250.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/serial/8250.yaml b/Documentation/devicetree/bindings/serial/8250.yaml
index 50d5c977afa3..33a5929bdaa6 100644
--- a/Documentation/devicetree/bindings/serial/8250.yaml
+++ b/Documentation/devicetree/bindings/serial/8250.yaml
@@ -137,6 +137,7 @@ properties:
               - ti,da830-uart
               - loongson,ls2k0500-uart
               - loongson,ls2k1500-uart
+              - microchip,core16550
           - const: ns16550a
       - items:
           - enum:

-- 
2.53.0

