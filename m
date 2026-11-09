From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Date: Mon, 09 Nov 2026 15:41:00 +0100
Subject: [PATCH 2/2] serial: 8250_dw: Select U6_16550A for 64-byte FIFO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261109-8250-select-u6-64bit-v1-2-04bc8332fa34@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794235482; l=1747;
 i=cleverline1mc@gmail.com; s=20241112; h=from:subject:message-id;
 bh=tbchbKgf4kvxbU+PFwpYUbA6/5DTF0wZIBoRBHeTq0o=;
 b=orLP3TrrB5XbdCVxNkTqhcupcoB3GSd2j6ojGBCGcI5BM8ZlnWV2XkvAZBQ9gF2MXQEi7dB93
 bzVu4JHI50IDYkkU6Rog+KjlWtj92H5Gl/jhz+nmPZdLGYmi7SZsbtx
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=EJoEbw03UiRORQuCiEyNA8gH1Q6fIpEWnn/MyaWOWX0=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20241112 with auth_id=275
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DesignWare 8250 ports that describe their FIFO in the CPR register are
always configured as PORT_16550A, regardless of the FIFO depth. On
UARTs with a 64-byte FIFO, such as those on the Rockchip RK3328, this
selects the 16-byte rxtrig_bytes table {1, 4, 8, 14}. The rx_trig_bytes
sysfs attribute then reports 8 bytes while the hardware triggers at 32,
and writes to it program the wrong trigger level.

Select PORT_U6_16550A when the CPR reports a 64-byte FIFO. Generic
autoconfig already assigns this type to a 16550A with a 64-byte FIFO,
and its rxtrig_bytes table matches the DesignWare FCR RT encoding.

The FIFO size, TX load size and capabilities are still taken from the
CPR, and the default FCR value is the same for both types, so the
hardware is programmed exactly as before. The port type reported to
userspace changes from 16550A to U6_16550A.

Co-developed-by: Miroslav Ondra <ondra@faster.cz>
Signed-off-by: Miroslav Ondra <ondra@faster.cz>
Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
 drivers/tty/serial/8250/8250_dwlib.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/tty/serial/8250/8250_dwlib.c b/drivers/tty/serial/8250/8250_dwlib.c
index 9bb02a4ab11f..ae556b06b03a 100644
--- a/drivers/tty/serial/8250/8250_dwlib.c
+++ b/drivers/tty/serial/8250/8250_dwlib.c
@@ -236,9 +236,9 @@ void dw8250_setup_port(struct uart_port *p)
 
 	/* Select the type based on FIFO */
 	if (reg & DW_UART_CPR_FIFO_MODE) {
-		p->type = PORT_16550A;
 		p->flags |= UPF_FIXED_TYPE;
 		p->fifosize = DW_UART_CPR_FIFO_SIZE(reg);
+		p->type = (p->fifosize == 64) ? PORT_U6_16550A : PORT_16550A;
 		up->capabilities = UART_CAP_FIFO | UART_CAP_NOTEMT;
 	}
 

-- 
2.47.3

