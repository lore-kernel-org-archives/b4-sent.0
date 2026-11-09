From: Kohei Otsuka <kohei@spacemachines.com>
Date: Tue, 10 Nov 2026 09:06:48 +1100
Subject: [PATCH v3 1/2] dt-bindings: serial: 8250: add Microchip Core16550
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-core16550-rs485-v3-1-4294334243fa@spacemachines.com>
References: <20261110-core16550-rs485-v3-0-4294334243fa@spacemachines.com>
In-Reply-To: <20261110-core16550-rs485-v3-0-4294334243fa@spacemachines.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Lubomir Rintel <lkundrak@v3.sk>, 
 devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 conor.dooley@microchip.com, Kohei Otsuka <kohei@spacemachines.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794262008; l=1343;
 i=kohei@spacemachines.com; s=20261103; h=from:subject:message-id;
 bh=P6b5LxeKt44ojzycxPDqJDbVsMSKh3hqrwdQXDsuWEE=;
 b=k6lG0Qy6LBCfz+oi7oN+A5oALoJbZx3rHkGblMRYxCm8+e3WyPVuBZDEAPekRPIXGqbeuvZsK
 EypjAYHP0ScBw4S4rsHrjjQB6oexiF650YMx2tCuBtrTH5mMHT36tGK
X-Developer-Key: i=kohei@spacemachines.com; a=ed25519;
 pk=1kit/vmX5JiLGH9NPcqlvT55ISWaLmNipdL5VrriRt0=
X-Endpoint-Received: by B4 Relay for kohei@spacemachines.com/20261103 with auth_id=1385
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Core16550 is a 16550-compatible UART soft IP core for Microchip FPGAs,
including the fabric of PolarFire SoC. Its registers follow the 16550A,
but it raises no interrupt on TEMT. A driver that knows only ns16550a
waits for one in software RS-485 mode (em485), so RTS stays asserted
after the first frame and the port stops receiving. ns16550a is
therefore not a valid fallback.

Add microchip,core16550-rtl-v3 as a compatible of its own. As for
Microchip's other FPGA fabric cores, the -rtl-v3 suffix is the major
RTL version of the IP, Core16550 3.x.

Link: https://github.com/linux4microchip/meta-mchp/issues/5
Signed-off-by: Kohei Otsuka <kohei@spacemachines.com>
---
 Documentation/devicetree/bindings/serial/8250.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/serial/8250.yaml b/Documentation/devicetree/bindings/serial/8250.yaml
index 50d5c977afa3..d9ee14f7b694 100644
--- a/Documentation/devicetree/bindings/serial/8250.yaml
+++ b/Documentation/devicetree/bindings/serial/8250.yaml
@@ -111,6 +111,7 @@ properties:
           - aspeed,ast2400-vuart
           - aspeed,ast2500-vuart
           - intel,xscale-uart
+          - microchip,core16550-rtl-v3
           - mrvl,pxa-uart
           - nuvoton,npcm750-uart
           - nuvoton,wpcm450-uart

-- 
2.53.0

