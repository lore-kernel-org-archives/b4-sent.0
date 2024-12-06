From: Denis Mukhin <dmukhin@ford.com>
Date: Thu, 05 Dec 2024 20:41:52 -0800
Subject: [PATCH v2 22/35] xen/console: introduce
 handle_keypress_in_domain()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241205-vuart-ns8250-v1-22-e9aa923127eb@ford.com>
References: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
In-Reply-To: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
To: xen-devel@lists.xenproject.org
Cc: Andrew Cooper <andrew.cooper3@citrix.com>, 
 Jan Beulich <jbeulich@suse.com>, Julien Grall <julien@xen.org>, 
 Stefano Stabellini <sstabellini@kernel.org>, 
 Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733460094; l=3261;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=4Oy6tSy4ntedYhToxhGSrQwpwAn7T/tf6/puha/ackI=;
 b=SIjDO2ws3eUPEyBeLQ5QQZasuvP/vMSYzru4/T8IBkGlLwzyl1Bg1uoR7rFhT+sbGwXgUo04+
 zxn9LrrwYdHAnc0oTPGSzkubS8ZnaOVnYA38M7BnDrd3OcReHl/I/5H
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
 xen/drivers/char/console.c | 72 +++++++++++++++++++++++++++-------------------
 1 file changed, 42 insertions(+), 30 deletions(-)

diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index 6261bdb5a2ac1075bc89fa408c0fd6cfef380ae6..ce3639a4cdcda00ea63e3bf119bc3b242cbfdf6a 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -570,14 +570,16 @@ static void console_init_owner(void)
     console_set_owner(domid);
 }
 
-static void __serial_rx(char c)
+static void handle_keypress_in_domain(struct domain *d, char c)
 {
-    switch ( console_owner )
-    {
-    case DOMID_XEN:
-        return handle_keypress(c, false);
+    int rc = 0;
 
-    case 0:
+    /*
+     * Deliver input to the hardware domain buffer.
+     * NB: must be the first check: hardware domain may have emulated UART.
+     */
+    if ( d == hardware_domain )
+    {
         /*
          * Deliver input to the hardware domain buffer, unless it is
          * already full.
@@ -590,34 +592,44 @@ static void __serial_rx(char c)
          * getting stuck.
          */
         send_global_virq(VIRQ_CONSOLE);
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
     }
+    /*
+     * Deliver input to the emulated UART.
+     */
+    else if ( domain_has_vuart(d) )
+    {
+#if defined(CONFIG_SBSA_VUART_CONSOLE)
+        rc = vpl011_rx_char_xen(d, c);
 #endif
     }
-
+    /*
+     * Deliver input to the PV shim console.
+     */
     if ( consoled_is_enabled() )
-        consoled_guest_tx(c);
+        rc = consoled_guest_tx(c);
+
+    if ( rc && rc != -ENODEV )
+        printk(KERN_WARNING "console input domain %d: not ready: %d\n",
+               d->domain_id, rc);
+}
+
+static void __serial_rx(char c)
+{
+    struct domain *d;
+
+    if ( console_owner == DOMID_XEN )
+    {
+        handle_keypress(c, false);
+        return;
+    }
+
+    d = rcu_lock_domain_console_owner();
+    if ( d == NULL )
+        return;
+
+    handle_keypress_in_domain(d, c);
+
+    rcu_unlock_domain(d);
 }
 
 static void cf_check serial_rx(char c)

-- 
2.34.1

