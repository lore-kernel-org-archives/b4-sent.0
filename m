From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Date: Sat, 21 Nov 2026 16:10:33 +0100
Subject: [PATCH] dt-bindings: serial: pl011: Reference rs485.yaml
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261121-pl011-rs485-v1-1-0d18008f4a12@gmail.com>
X-B4-Tracking: v=1; b=H4sIAGi0AWsC/yXMQQ5AMBBA0avIrDXplIq4ilgUgxFBOohE3F2xf
 Iv/LxDyTAJFdIGng4WXOQDjCJrBzT0pboPBaJMhGlTrpBGVlzS3KiOLmLi8c66FUKyeOj6/W1n
 9lr0eqdneBdz3A/wxiwNvAAAA
X-Change-ID: 20261121-pl011-rs485-6e5113a8faad
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Lino Sanfilippo <LinoSanfilippo@gmx.de>
Cc: Matous Hybl <hyblmatous@gmail.com>, Miroslav Ondra <ondra@faster.cz>, 
 linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795273968; l=1427;
 i=cleverline1mc@gmail.com; s=20261121; h=from:subject:message-id;
 bh=WApAvtSzKPrLcGtYRifdtaAM+A81CWvw2/q5/+yJ1kQ=;
 b=h4uA8WUuBALQ2FRUKebfcFwq8+kH6St6F99HGuzVqUBLVZi6RYzrHHpm7mrEAIj97L3HiW+RY
 piRUPmrx7E7A5u7n19NLpQaIpyAesSY/gzGw0POSiqG4zftrx9QumKD
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=2UEUVmQyfsiFZkNS7dkgFg0rUmhbcMIytM6NYhxFt/Y=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20261121 with auth_id=1594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The amba-pl011 driver supports RS-485 and parses the generic RS-485
properties with uart_get_rs485_mode(), but the binding does not allow
them. Reference rs485.yaml.

Fixes: 8d479237727c ("serial: amba-pl011: add RS485 support")

Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
The PL011 driver has supported RS-485 since v5.15, added in
https://git.kernel.org/torvalds/c/8d479237727c, but dtbs_check rejects
properties such as linux,rs485-enabled-at-boot-time on PL011 nodes.
We hit this on a BCM2711 (CM4) board using two PL011 UARTs for RS-485.

An AI assistant (Claude) helped check the driver and write commit message.
---
 Documentation/devicetree/bindings/serial/pl011.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/serial/pl011.yaml b/Documentation/devicetree/bindings/serial/pl011.yaml
index 3fcf2d042372..3c5f35eed04a 100644
--- a/Documentation/devicetree/bindings/serial/pl011.yaml
+++ b/Documentation/devicetree/bindings/serial/pl011.yaml
@@ -12,6 +12,7 @@ maintainers:
 allOf:
   - $ref: /schemas/arm/primecell.yaml#
   - $ref: serial.yaml#
+  - $ref: rs485.yaml#
 
 # Need a custom select here or 'arm,primecell' will match on lots of nodes
 select:

---
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20261121-pl011-rs485-6e5113a8faad

Best regards,
--  
Kryštof Černý <cleverline1mc@gmail.com>

