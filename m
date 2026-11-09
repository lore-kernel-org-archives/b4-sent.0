From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Date: Mon, 09 Nov 2026 15:40:59 +0100
Subject: [PATCH 1/2] serial: 8250: Add RX trigger levels for U6_16550A
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261109-8250-select-u6-64bit-v1-1-04bc8332fa34@gmail.com>
References: <20261109-8250-select-u6-64bit-v1-0-04bc8332fa34@gmail.com>
In-Reply-To: <20261109-8250-select-u6-64bit-v1-0-04bc8332fa34@gmail.com>
To: Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>, 
 Miroslav Ondra <ondra@faster.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794235482; l=1531;
 i=cleverline1mc@gmail.com; s=20241112; h=from:subject:message-id;
 bh=E2kYgvRVI0V5zzIOIvpSYf52Ap3eD6IiSUx3X0nJA5k=;
 b=jsgvGiHnVICw6dgfxc/096xFpMKcmxhqMsvH9BwAP3EVWtbpO5GUy+crvHVGKALOOIYISpI9w
 hq3zVeDbMF4CkXIGBTXJcdjmPkBQtjxz4/02QofLJS/6QYbDfkcwUuJ
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=EJoEbw03UiRORQuCiEyNA8gH1Q6fIpEWnn/MyaWOWX0=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20241112 with auth_id=275
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

PORT_U6_16550A has a 64-byte FIFO but no rxtrig_bytes table, so the
rx_trig_bytes sysfs attribute is not registered for ports of this type
and the RX trigger level cannot be read or changed from userspace.

Add a table with 1, 16, 32 and 62 bytes, i.e. 1 character, FIFO 1/4
full, FIFO 1/2 full and FIFO 2 less than full. These are the levels the
Synopsys DesignWare UART uses for a 64-byte FIFO, and they match the
existing PORT_ALTR_16550_F64 table.

The default FCR value of the type is unchanged, so the trigger level a
port starts with stays at 1/2 full. The only visible change for ports
already detected as U6_16550A by autoconfig is the new sysfs attribute.

This prepares for 8250_dw selecting PORT_U6_16550A for DesignWare UARTs
with a 64-byte FIFO.

Co-developed-by: Miroslav Ondra <ondra@faster.cz>
Signed-off-by: Miroslav Ondra <ondra@faster.cz>
Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
 drivers/tty/serial/8250/8250_port.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/tty/serial/8250/8250_port.c b/drivers/tty/serial/8250/8250_port.c
index 36b2b0a2c05c..a7acede62f40 100644
--- a/drivers/tty/serial/8250/8250_port.c
+++ b/drivers/tty/serial/8250/8250_port.c
@@ -163,6 +163,7 @@ static const struct serial8250_config uart_config[] = {
 		.fifo_size	= 64,
 		.tx_loadsz	= 64,
 		.fcr		= UART_FCR_ENABLE_FIFO | UART_FCR_R_TRIG_10,
+		.rxtrig_bytes	= {1, 16, 32, 62},
 		.flags		= UART_CAP_FIFO | UART_CAP_AFE,
 	},
 	[PORT_TEGRA] = {

-- 
2.47.3

