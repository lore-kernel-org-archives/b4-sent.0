From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:22:15 -0800
Subject: [PATCH 25/36] xen/console: introduce handle_keypress_in_domain()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-25-87b9a8375b7a@ford.com>
References: <20241126-vuart-ns8250-v1-v1-0-87b9a8375b7a@ford.com>
In-Reply-To: <20241126-vuart-ns8250-v1-v1-0-87b9a8375b7a@ford.com>
To: Jan Beulich <jbeulich@suse.com>, 
 Andrew Cooper <andrew.cooper3@citrix.com>, 
 =?utf-8?q?Roger_Pau_Monn=C3=A9?= <roger.pau@citrix.com>, 
 "Daniel P. Smith" <dpsmith@apertussolutions.com>, 
 Stefano Stabellini <sstabellini@kernel.org>, Julien Grall <julien@xen.org>, 
 Bertrand Marquis <bertrand.marquis@arm.com>, 
 Michal Orzel <michal.orzel@amd.com>, Rahul Singh <rahul.singh@arm.com>, 
 Volodymyr Babchuk <Volodymyr_Babchuk@epam.com>, 
 Alistair Francis <alistair.francis@wdc.com>, 
 Bob Eshleman <bobbyeshleman@gmail.com>, 
 Connor Davis <connojdavis@gmail.com>, 
 Oleksii Kurochko <oleksii.kurochko@gmail.com>, 
 Shawn Anastasio <sanastasio@raptorengineering.com>, 
 Anthony PERARD <anthony.perard@vates.tech>, Juergen Gross <jgross@suse.com>, 
 Christian Lindig <christian.lindig@citrix.com>, 
 David Scott <dave@recoil.org>, 
 =?utf-8?q?Marek_Marczykowski-G=C3=B3recki?= <marmarek@invisiblethingslab.com>
Cc: xen-devel@lists.xenproject.org, Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=4030;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=WFmMQGLVJ0pT89tmxZ0ESYKHXHYqZV3StRB9Oqc56Go=;
 b=GoTkJnk83G9LUzBwpX7Aka4GbqCU17s/CyNsDUtmb57uNiKM4uuDJ+oKcwJiPDwset63x3jYN
 YB7yk8Qun2gBof4pKaDDjOz1+GkUp1ER7gJzYPIEFEAEe0lcgNWckUO
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With introduction of NS8250 emulator for x86, the logic of switching console
focus gets more convoluted: HVM domain w/ NS8205 must be able to receive the
physical console input for guest VM debugging.

Also, existing code does not honor `hardware_dom=` xen command line parameter
(hardware domain ID does _not_ necessarily starts from 0).

Introduce handle_keypress_in_domain() to account for all scenarios of console
input forwarding.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/drivers/char/console.c | 102 ++++++++++++++++++++++++++-------------------
 1 file changed, 59 insertions(+), 43 deletions(-)

diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index 6261bdb5a2ac1075bc89fa408c0fd6cfef380ae6..4439e00763631969767719053cdc81e67c2cda2c 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -570,54 +570,70 @@ static void console_init_owner(void)
     console_set_owner(domid);
 }
 
-static void __serial_rx(char c)
+static void handle_keypress_in_domain(struct domain *d, char c)
 {
-    switch ( console_owner )
+    int rc = 0;
+
+    /*
+     * Deliver input to the emulated UART.
+     */
+    if ( domain_has_vuart(d) )
     {
-    case DOMID_XEN:
-        return handle_keypress(c, false);
-
-    case 0:
-        /*
-         * Deliver input to the hardware domain buffer, unless it is
-         * already full.
-         */
-        if ( (serial_rx_prod - serial_rx_cons) != SERIAL_RX_SIZE )
-            serial_rx_ring[SERIAL_RX_MASK(serial_rx_prod++)] = c;
-
-        /*
-         * Always notify the hardware domain: prevents receive path from
-         * getting stuck.
-         */
-        send_global_virq(VIRQ_CONSOLE);
-        break;
-
-#ifdef CONFIG_SBSA_VUART_CONSOLE
-    default:
-    {
-        struct domain *d = rcu_lock_domain_by_id(console_owner);
-
-        /*
-         * If we have a properly initialized vpl011 console for the
-         * domain, without a full PV ring to Dom0 (in that case input
-         * comes from the PV ring), then send the character to it.
-         */
-        if ( d != NULL )
-            vpl011_rx_char_xen(d, c);
-        else
-            printk("Cannot send chars to Dom%d: no UART available\n",
-                   console_owner);
-
-        if ( d != NULL )
-            rcu_unlock_domain(d);
-
-        break;
-    }
+#if defined(CONFIG_SBSA_VUART_CONSOLE)
+        rc = vpl011_rx_char_xen(d, c);
 #endif
     }
+    /*
+     * Deliver input to the hardware domain buffer.
+     */
+    else if ( d == hardware_domain )
+    {
+        /*
+         * Deliver input to the PV shim console.
+         */
+        if ( consoled_is_enabled() )
+            rc = consoled_guest_tx(c);
+        else
+        {
+            /*
+             * Deliver input to the hardware domain buffer, unless it is
+             * already full.
+             */
+            if ( (serial_rx_prod - serial_rx_cons) != SERIAL_RX_SIZE )
+                serial_rx_ring[SERIAL_RX_MASK(serial_rx_prod++)] = c;
 
-    if ( consoled_is_enabled() )
-        consoled_guest_tx(c);
+            /*
+             * Always notify the hardware domain: prevents receive path from
+             * getting stuck.
+             */
+            send_global_virq(VIRQ_CONSOLE);
+            rc = 0;
+        }
+    }
+    /*
+     * Deliver input to the PV shim console.
+     */
+    else if ( consoled_is_enabled() )
+        rc = consoled_guest_tx(c);
+
+    if ( rc )
+        printk(KERN_WARNING "console input domain %d: not ready: %d\n",
+               d->domain_id, rc);
+
+}
+
+static void __serial_rx(char c)
+{
+    struct domain *d;
+
+    d = rcu_lock_domain_console_owner();
+    if ( d != NULL )
+    {
+        handle_keypress_in_domain(d, c);
+        rcu_unlock_domain(d);
+    }
+    else
+        handle_keypress(c, false);
 }
 
 static void cf_check serial_rx(char c)

-- 
2.34.1

