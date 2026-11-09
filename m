From: Kohei Otsuka <kohei@spacemachines.com>
Date: Mon, 09 Nov 2026 13:55:06 +1100
Subject: [PATCH v2 2/2] serial: 8250_of: drop RS-485 RTS on Microchip
 Core16550
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-core16550-rs485-v2-2-a15933c7b907@spacemachines.com>
References: <20261109-core16550-rs485-v2-0-a15933c7b907@spacemachines.com>
In-Reply-To: <20261109-core16550-rs485-v2-0-a15933c7b907@spacemachines.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Lubomir Rintel <lkundrak@v3.sk>, 
 devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 conor.dooley@microchip.com, Kohei Otsuka <kohei@spacemachines.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794192905; l=2135;
 i=kohei@spacemachines.com; s=20261103; h=from:subject:message-id;
 bh=zB2zzCjY5jGdBW3bz8SbL+SIiy1mkD1eN/4HcK9U8ig=;
 b=ikHWkWqXRfD6U4iTaFAtEZY2wJSVCDiHhxCGbkCs0FjWMkuRay/J+3i1gyFsThiAEzWWoDevG
 ZTYnB7S2hdYCfgm7NuIAq/SiYzTjpYUqggc+E3W/3EEnjZKWRiG6v6C
X-Developer-Key: i=kohei@spacemachines.com; a=ed25519;
 pk=1kit/vmX5JiLGH9NPcqlvT55ISWaLmNipdL5VrriRt0=
X-Endpoint-Received: by B4 Relay for kohei@spacemachines.com/20261103 with auth_id=1385
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Core16550, a 16550-compatible UART for Microchip FPGAs, interrupts on
THRE but not on TEMT. When the last character moves from the FIFO into
the shift register, the THRE interrupt calls __stop_tx(), which finds
TEMT clear and, without UART_CAP_NOTEMT, returns to wait for a TEMT
interrupt that never comes. RTS, and with it the RS-485 driver enable,
then stays asserted after the frame, and receive interrupts, disabled
for the half-duplex transmission, stay off.

Set UART_CAP_NOTEMT for nodes compatible with
"microchip,core16550-rtl-v3", so em485 drops RTS from its stop timer
one frame time (plus 1/7) after THRE, as it does for DesignWare UARTs.

Set UART_CAP_FIFO as well: with the capabilities already non-zero,
serial8250_do_startup() no longer fills in the PORT_16550A default,
and without UART_CAP_FIFO serial8250_clear_fifos() does nothing, so
the RX FIFO is not flushed at the end of a half-duplex transmission.

Link: https://github.com/linux4microchip/meta-mchp/issues/5
Signed-off-by: Kohei Otsuka <kohei@spacemachines.com>
---
 drivers/tty/serial/8250/8250_of.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/tty/serial/8250/8250_of.c b/drivers/tty/serial/8250/8250_of.c
index b41ca604083f..e23539b2fda3 100644
--- a/drivers/tty/serial/8250/8250_of.c
+++ b/drivers/tty/serial/8250/8250_of.c
@@ -278,6 +278,16 @@ static int of_platform_serial_probe(struct platform_device *ofdev)
 	if (port8250.port.fifosize)
 		port8250.capabilities = UART_CAP_FIFO;
 
+	/*
+	 * Core16550 has no TEMT interrupt: without UART_CAP_NOTEMT the em485
+	 * code waits for one after the last THRE interrupt and never drops RTS.
+	 * Set UART_CAP_FIFO too, because a non-zero value stops
+	 * serial8250_do_startup() filling in the PORT_16550A default.
+	 */
+	if (of_device_is_compatible(ofdev->dev.of_node,
+				    "microchip,core16550-rtl-v3"))
+		port8250.capabilities |= UART_CAP_FIFO | UART_CAP_NOTEMT;
+
 	/* Check for TX FIFO threshold & set tx_loadsz */
 	if ((of_property_read_u32(ofdev->dev.of_node, "tx-threshold",
 				  &tx_threshold) == 0) &&

-- 
2.53.0

