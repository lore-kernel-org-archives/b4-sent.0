From: Jonas Juffinger <jonas.juffinger@liebherr.com>
Date: Sun, 15 Nov 2026 19:01:56 +0100
Subject: [PATCH 1/2] serial: fsl_lpuart: Enable break detection in 8-bit
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-fsl_lpuart_8_bit_break_detection-v1-1-b7ac2307dd55@liebherr.com>
References: <20261115-fsl_lpuart_8_bit_break_detection-v1-0-b7ac2307dd55@liebherr.com>
In-Reply-To: <20261115-fsl_lpuart_8_bit_break_detection-v1-0-b7ac2307dd55@liebherr.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 michael@walle.cc, sherry.sun@nxp.com, 
 Jonas Juffinger <jonas.juffinger@liebherr.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794765771; l=2586;
 i=jonas.juffinger@liebherr.com; s=20260615; h=from:subject:message-id;
 bh=9aJj61UEVxmT3JSRw0htuxmj1O/fWkXMFbGksUPDyKc=;
 b=HXumKe2sa9UV7ddE4tON6z9c+sWpbqhRtGjHrpF4Xht+CujaERCsMujsFVFvYdlXcWZ+u/DhS
 Hzbd0J63Xp1BC0Xr1E8r3h8cyrUHZ1/8Q7darRnFxhC9QgnV4JZKN/R
X-Developer-Key: i=jonas.juffinger@liebherr.com; a=ed25519;
 pk=57Vzs2aKTP3E7TDrBuZMQibGR+Koattc4oIhiMOs3FI=
X-Endpoint-Received: by B4 Relay for jonas.juffinger@liebherr.com/20260615 with auth_id=821
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add break detection in the code for the 8-bit LPUART.

The driver contains the code for the 8-bit and 32-bit LPUART device
but only the 32-bit part has working break detection. Add break
detection to the 8-bit LPUART driver.

Break detection in the 32-bit part was added with commit 5541a9bacfe5
("serial: fsl_lpuart: handle break and make sysrq work") and later fixed
with commit 707f816f2559 ("tty: serial: fsl_lpuart: correct the count of
break characters"). This patch is practically identical.

Signed-off-by: Jonas Juffinger <jonas.juffinger@liebherr.com>
---
 drivers/tty/serial/fsl_lpuart.c | 32 ++++++++++++++++++++++++--------
 1 file changed, 24 insertions(+), 8 deletions(-)

diff --git a/drivers/tty/serial/fsl_lpuart.c b/drivers/tty/serial/fsl_lpuart.c
index c8575c965203..5817c47e4db3 100644
--- a/drivers/tty/serial/fsl_lpuart.c
+++ b/drivers/tty/serial/fsl_lpuart.c
@@ -885,6 +885,7 @@ static void lpuart_rxint(struct lpuart_port *sport)
 	unsigned int flg, ignored = 0, overrun = 0;
 	struct tty_port *port = &sport->port.state->port;
 	u8 rx, sr;
+	bool is_break;
 
 	uart_port_lock(&sport->port);
 
@@ -898,14 +899,27 @@ static void lpuart_rxint(struct lpuart_port *sport)
 		sr = readb(sport->port.membase + UARTSR1);
 		rx = readb(sport->port.membase + UARTDR);
 
+		/*
+		 * The LPUART can't distinguish between a break and a framing error,
+		 * thus we assume it is a break if the received data is zero.
+		 */
+		is_break = (sr & UARTSR1_FE) && !rx;
+
+		if (is_break && uart_handle_break(&sport->port))
+			continue;
+
 		if (uart_prepare_sysrq_char(&sport->port, rx))
 			continue;
 
 		if (sr & (UARTSR1_PE | UARTSR1_OR | UARTSR1_FE)) {
-			if (sr & UARTSR1_PE)
+			if (sr & UARTSR1_PE) {
 				sport->port.icount.parity++;
-			else if (sr & UARTSR1_FE)
-				sport->port.icount.frame++;
+			} else if (sr & UARTSR1_FE) {
+				if (is_break)
+					sport->port.icount.brk++;
+				else
+					sport->port.icount.frame++;
+			}
 
 			if (sr & UARTSR1_OR)
 				overrun++;
@@ -918,15 +932,17 @@ static void lpuart_rxint(struct lpuart_port *sport)
 
 			sr &= sport->port.read_status_mask;
 
-			if (sr & UARTSR1_PE)
+			if (sr & UARTSR1_PE) {
 				flg = TTY_PARITY;
-			else if (sr & UARTSR1_FE)
-				flg = TTY_FRAME;
+			} else if (sr & UARTSR1_FE) {
+				if (is_break)
+					flg = TTY_BREAK;
+				else
+					flg = TTY_FRAME;
+			}
 
 			if (sr & UARTSR1_OR)
 				flg = TTY_OVERRUN;
-
-			sport->port.sysrq = 0;
 		}
 
 		if (tty_insert_flip_char(port, rx, flg) == 0)

-- 
2.43.0

