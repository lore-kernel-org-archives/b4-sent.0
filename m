From: Denis Mukhin <dmukhin@ford.com>
Date: Thu, 05 Dec 2024 20:41:49 -0800
Subject: [PATCH v2 19/35] xen/console: introduce console_set_owner()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241205-vuart-ns8250-v1-19-e9aa923127eb@ford.com>
References: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
In-Reply-To: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
To: xen-devel@lists.xenproject.org
Cc: Andrew Cooper <andrew.cooper3@citrix.com>, 
 Jan Beulich <jbeulich@suse.com>, Julien Grall <julien@xen.org>, 
 Stefano Stabellini <sstabellini@kernel.org>, 
 Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733460094; l=6105;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=LaoLtTtPVB803Wx66ywoNWCuGefL+9P7BcXWkOi4Ttw=;
 b=qIUuqjar9jBz7vlbvZO91eK5QZyrPGkyZdxoOW+bK/PhH1tCuhvcar4R2tTKQ6B0C7F6lxM93
 WMCmcpor8byDDi3SZubIYvLxdlI1nk8JsNjv/6WTA/rYizZqV4c2rlQ
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

console_set_owner() is introduced for setting the new console owner.

Switches console owner to domain ID vs range of integer numbers mapped to
domain IDs.

This a public API to console driver, will be used in the follow on code change.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/drivers/char/console.c | 122 ++++++++++++++++++++++++++-------------------
 xen/include/xen/console.h  |   1 +
 2 files changed, 71 insertions(+), 52 deletions(-)

diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index 8cbac54c66044ae8581e486a782102b75c8bfaa9..52cf64dbf6fd18d599cb88835d03501a23b3e3c4 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -463,82 +463,100 @@ static void cf_check dump_console_ring_key(unsigned char key)
 
 /*
  * CTRL-<switch_char> changes input direction, rotating among Xen, Dom0,
- * and the DomUs started from Xen at boot.
+ * and the DomUs.
  */
 #define switch_code (opt_conswitch[0]-'a'+1)
+
 /*
- * console_owner=0 => input to xen
- * console_owner=1 => input to dom0 (or the sole shim domain)
- * console_owner=N => input to dom(N-1)
+ * Current console owner domain ID: either Xen or domain w/ d->is_console ==
+ * true.
+ *
+ * Initialized in console_endboot().
  */
-static unsigned int __read_mostly console_owner = 0;
+static domid_t __read_mostly console_owner;
 
-#define max_console_rx (max_init_domid + 1)
+static struct domain *rcu_lock_domain_console_by_id(domid_t domid)
+{
+    struct domain *d;
+
+    d = rcu_lock_domain_by_id(domid);
+
+    if ( d == NULL )
+        return NULL;
+
+    if ( d->is_console )
+        return d;
+
+    rcu_unlock_domain(d);
+
+    return NULL;
+}
 
-#ifdef CONFIG_SBSA_VUART_CONSOLE
 /* Make sure to rcu_unlock_domain after use */
 struct domain *rcu_lock_domain_console_owner(void)
 {
-    if ( console_owner == 0 )
-            return NULL;
-    return rcu_lock_domain_by_id(console_owner - 1);
+    return rcu_lock_domain_console_by_id(console_owner);
 }
-#endif
 
-static void console_find_owner(void)
+static bool console_owner_possible(domid_t domid)
 {
-    unsigned int next_rx = console_owner;
-
-    /*
-     * Rotate among Xen, dom0 and boot-time created domUs while skipping
-     * switching serial input to non existing domains.
-     */
-    for ( ; ; )
-    {
-        domid_t domid;
-        struct domain *d;
-
-        if ( next_rx++ >= max_console_rx )
-        {
-            console_owner = 0;
-            printk("*** Serial input to Xen");
-            break;
-        }
-
-        if ( consoled_is_enabled() && next_rx == 1 )
-            domid = get_initial_domain_id();
-        else
-            domid = next_rx - 1;
-
-        d = rcu_lock_domain_by_id(domid);
-        if ( d == NULL )
-            continue;
-
-        if ( d->is_console )
-        {
-            rcu_unlock_domain(d);
-            console_owner = next_rx;
-            printk("*** Serial input to DOM%u", domid);
-            break;
-        }
+    struct domain *d;
 
+    d = rcu_lock_domain_console_by_id(domid);
+    if ( d != NULL )
         rcu_unlock_domain(d);
-    }
+
+    return d != NULL;
+}
+
+int console_set_owner(domid_t domid)
+{
+    if ( domid == DOMID_XEN )
+        printk("*** Serial input to Xen");
+    else if ( console_owner_possible(domid) )
+        printk("*** Serial input to DOM%u", domid);
+    else
+        return -ENOENT;
+
+    console_owner = domid;
 
     if ( switch_code )
         printk(" (type 'CTRL-%c' three times to switch input)",
                opt_conswitch[0]);
     printk("\n");
+
+    return 0;
+}
+
+/*
+ * Switch console input focus.
+ * Rotates input focus among Xen, dom0 and boot-time created domUs while
+ * skipping switching serial input to non existing domains.
+ */
+static void console_find_owner(void)
+{
+    domid_t i, n = max_init_domid + 1;
+
+    if ( console_owner == DOMID_XEN )
+        i = get_initial_domain_id();
+    else
+        i = console_owner + 1;
+
+    for ( ; i < n; i++ )
+        if ( !console_set_owner(i) )
+            break;
+    if ( i == n )
+        console_set_owner(DOMID_XEN);
 }
 
 static void __serial_rx(char c)
 {
     switch ( console_owner )
     {
-    case 0:
+    case DOMID_XEN:
         return handle_keypress(c, false);
 
-    case 1:
+    case 0:
         /*
          * Deliver input to the hardware domain buffer, unless it is
          * already full.
@@ -556,7 +574,7 @@ static void __serial_rx(char c)
 #ifdef CONFIG_SBSA_VUART_CONSOLE
     default:
     {
-        struct domain *d = rcu_lock_domain_by_id(console_owner - 1);
+        struct domain *d = rcu_lock_domain_by_id(console_owner);
 
         /*
          * If we have a properly initialized vpl011 console for the
@@ -567,7 +585,7 @@ static void __serial_rx(char c)
             vpl011_rx_char_xen(d, c);
         else
             printk("Cannot send chars to Dom%d: no UART available\n",
-                   console_owner - 1);
+                   console_owner);
 
         if ( d != NULL )
             rcu_unlock_domain(d);
@@ -1126,7 +1144,7 @@ void __init console_endboot(void)
      * a useful 'how to switch' message.
      */
     if ( opt_conswitch[1] == 'x' )
-        console_owner = max_console_rx;
+        console_owner = DOMID_XEN;
 
     register_keyhandler('w', dump_console_ring_key,
                         "synchronously dump console ring buffer (dmesg)", 0);
diff --git a/xen/include/xen/console.h b/xen/include/xen/console.h
index 0e211e44d9703c804e18f52c9743916f8d2a9d4e..57c482cfbf2da15b011e64841ea086e779f4588d 100644
--- a/xen/include/xen/console.h
+++ b/xen/include/xen/console.h
@@ -32,6 +32,7 @@ void console_start_log_everything(void);
 void console_end_log_everything(void);
 
 struct domain *rcu_lock_domain_console_owner(void);
+int console_set_owner(domid_t);
 
 /*
  * Steal output from the console. Returns +ve identifier, else -ve error.

-- 
2.34.1

