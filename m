From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:20:12 -0400
Subject: [PATCH] serial: amba-pl011: publish amba_ports[] entries with
 release semantics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-pl011-v1-1-b378bb057d43@vt.edu>
X-B4-Tracking: v=1; b=H4sIAMvXsWoC/yXMzQrCMBAE4Fcpe3YlP0bRVykeku3GRjSWrBah9
 N1N6vEbZmYB4ZJY4NItUHhOkl65Qu86oNHnG2MaqsEoc1Rno/EZcHoordG6GImsGpyLUOtT4Zi
 +21V//Vs+4c70bvvWCF4YQ/GZxhZtnE97i4UOsK4/S1adcYwAAAA=
X-Change-ID: 20260921-mb-pl011-35ffcc30d55f
To: Russell King <linux@armlinux.org.uk>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790040012; l=2804;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=HVyVKJUfeShA9Cl/yJ9Y9hzw2YOBdrEEPbai4gSDMk8=;
 b=Uus3PlpLesgrSLqCkQkUW5L4vrXYNJGcYbo55wSXb1LkDNXlCMzWUUa3MDn9II5WNo+ldABIV
 vOhrLS5voi8BXCPkm/gFc1cd7TDeut2PvYh0k79XPM7pyg5gBDjzLr6
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pl011_setup_port() fills the port structure and then stores its address
into amba_ports[] with a plain store. The console callbacks read the
slot through co->index with plain loads.

Store the slot with smp_store_release() and read it with
smp_load_acquire().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/tty/serial/amba-pl011.c | 15 ++++++++++-----
 1 file changed, 10 insertions(+), 5 deletions(-)

diff --git a/drivers/tty/serial/amba-pl011.c b/drivers/tty/serial/amba-pl011.c
index c4824c201..696c12ca9 100644
--- a/drivers/tty/serial/amba-pl011.c
+++ b/drivers/tty/serial/amba-pl011.c
@@ -2536,7 +2536,8 @@ static int pl011_console_setup(struct console *co, char *options)
 	 */
 	if (co->index >= UART_NR)
 		co->index = 0;
-	uap = amba_ports[co->index];
+	/* Pairs with the smp_store_release() in pl011_setup_port(). */
+	uap = smp_load_acquire(&amba_ports[co->index]);
 	if (!uap)
 		return -ENODEV;
 
@@ -2574,7 +2575,8 @@ static int pl011_console_setup(struct console *co, char *options)
 
 static int pl011_console_exit(struct console *co)
 {
-	struct uart_amba_port *uap = amba_ports[co->index];
+	/* Pairs with the smp_store_release() in pl011_setup_port(). */
+	struct uart_amba_port *uap = smp_load_acquire(&amba_ports[co->index]);
 
 	clk_disable_unprepare(uap->clk);
 
@@ -2644,7 +2646,8 @@ static int pl011_console_match(struct console *co, char *name, int idx,
 static void
 pl011_console_write_atomic(struct console *co, struct nbcon_write_context *wctxt)
 {
-	struct uart_amba_port *uap = amba_ports[co->index];
+	/* Pairs with the smp_store_release() in pl011_setup_port(). */
+	struct uart_amba_port *uap = smp_load_acquire(&amba_ports[co->index]);
 	unsigned int old_cr = 0;
 
 	if (!nbcon_enter_unsafe(wctxt))
@@ -2672,7 +2675,8 @@ pl011_console_write_atomic(struct console *co, struct nbcon_write_context *wctxt
 static void
 pl011_console_write_thread(struct console *co, struct nbcon_write_context *wctxt)
 {
-	struct uart_amba_port *uap = amba_ports[co->index];
+	/* Pairs with the smp_store_release() in pl011_setup_port(). */
+	struct uart_amba_port *uap = smp_load_acquire(&amba_ports[co->index]);
 	unsigned int old_cr = 0;
 
 	if (!nbcon_enter_unsafe(wctxt))
@@ -2983,7 +2987,8 @@ static int pl011_setup_port(struct device *dev, struct uart_amba_port *uap,
 	if (ret)
 		return ret;
 
-	amba_ports[index] = uap;
+	/* Pairs with the smp_load_acquire() in the console callbacks. */
+	smp_store_release(&amba_ports[index], uap);
 
 	return 0;
 }

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-pl011-35ffcc30d55f

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

