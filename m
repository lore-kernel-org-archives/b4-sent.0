From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:21:13 -0400
Subject: [PATCH] serial: xilinx_uartps: publish console_port with release
 semantics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-uartps-v1-1-9fc2f3d4b1a5@vt.edu>
X-B4-Tracking: v=1; b=H4sIAAjYsWoC/yXM0Q6CMAyF4VchvbaGDaLiqxgvulJlJk7SAjEhv
 LsbXn4nJ/8KJhrF4FqtoLJEi5+U4Q4V8EDpKRj7bPC1P9Wdd/gOOJNOoyGLC47Jd3RpIP9HlUf
 87q3b/W+bw0t4KoHyCGSCQSnxUKady/nYoHIL2/YDZzaMOY0AAAA=
X-Change-ID: 20260921-mb-uartps-ce1b1ca29a83
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Michal Simek <michal.simek@amd.com>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790040075; l=2025;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=+qMMTlUnAlo5wMcrO/0fIIBY+h1Jroi7pkVqcuiqtuM=;
 b=Jh8+BFE5Ah6Lj6zvIelxnqC4MWlNXWoUGsODf6eaUwkm2e5X7Q9/8eLbZR4lYiM+l6uTGR6ms
 cUuaLI+lyEqAVStd+mqyXzmD5TpCCIAFT2Ay4mSDu9KTEZvMDEG4puJ
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cdns_uart_probe() assigns the first probed port to console_port with a
plain store once the port is set up. cdns_uart_console_write() and
cdns_uart_console_setup() read it with plain loads.

Store it with smp_store_release() and read it with smp_load_acquire().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/tty/serial/xilinx_uartps.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/drivers/tty/serial/xilinx_uartps.c b/drivers/tty/serial/xilinx_uartps.c
index a072b75db..59e0d388d 100644
--- a/drivers/tty/serial/xilinx_uartps.c
+++ b/drivers/tty/serial/xilinx_uartps.c
@@ -1371,7 +1371,8 @@ static struct uart_port *console_port;
 static void cdns_uart_console_write(struct console *co, const char *s,
 				unsigned int count)
 {
-	struct uart_port *port = console_port;
+	/* Pairs with the smp_store_release() in cdns_uart_probe(). */
+	struct uart_port *port = smp_load_acquire(&console_port);
 	unsigned long flags;
 	unsigned int imr, ctrl;
 	int locked = 1;
@@ -1414,7 +1415,8 @@ static void cdns_uart_console_write(struct console *co, const char *s,
  */
 static int cdns_uart_console_setup(struct console *co, char *options)
 {
-	struct uart_port *port = console_port;
+	/* Pairs with the smp_store_release() in cdns_uart_probe(). */
+	struct uart_port *port = smp_load_acquire(&console_port);
 
 	int baud = 9600;
 	int bits = 8;
@@ -1812,7 +1814,8 @@ static int cdns_uart_probe(struct platform_device *pdev)
 	 */
 	if (!console_port) {
 		cdns_uart_console.index = id;
-		console_port = port;
+		/* Pairs with the smp_load_acquire() in the console callbacks. */
+		smp_store_release(&console_port, port);
 	}
 #endif
 	if (cdns_uart_data->port->rs485.flags & SER_RS485_ENABLED)

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-uartps-ce1b1ca29a83

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

