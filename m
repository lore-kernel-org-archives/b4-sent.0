From: Denis Mukhin <dmukhin@ford.com>
Date: Fri, 03 Jan 2025 17:58:18 -0800
Subject: [PATCH v3 12/24] xen/console: introduce console_{get,set}_owner()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250103-vuart-ns8250-v3-v1-12-c5d36b31d66c@ford.com>
References: <20250103-vuart-ns8250-v3-v1-0-c5d36b31d66c@ford.com>
In-Reply-To: <20250103-vuart-ns8250-v3-v1-0-c5d36b31d66c@ford.com>
To: xen-devel@lists.xenproject.org
Cc: Stefano Stabellini <sstabellini@kernel.org>, 
 Julien Grall <julien@xen.org>, Michal Orzel <michal.orzel@amd.com>, 
 Andrew Cooper <andrew.cooper3@citrix.com>, 
 Anthony PERARD <anthony.perard@vates.tech>, Jan Beulich <jbeulich@suse.com>, 
 =?utf-8?q?Roger_Pau_Monn=C3=A9?= <roger.pau@citrix.com>, 
 Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735955892; l=7114;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=dr4GoJ7mVh1JpOj1gtOyvwWAVMZqjbpSzztsCiE4+kM=;
 b=NnZnovgXXftfgxnQ8N3SMkVR+YZGMDuiEyNDqeNhX+V6VEW4Rut+uGiOeM4I+9pLYD39Hew8k
 qhwTi5Hgm+ID3jXYVkTApbFFLLhx6yrBx7PQS8JOF7VMJcO1ml6LApw
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Switch console_owner address spaces from integers mapped to domain IDs to
straight domain IDs, which simplifies console focus handling code.

console_set_owner() is introduced for setting the new console owner. This is a
public API to Xen console driver (it will be used in the follow on code
change).

console_get_owner() is another public API used for retrieving current console
owner domain ID.

After the change, console_{get,put}_domain() do not need to be public console
APIs.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/arch/arm/vpl011.c      |   5 +--
 xen/drivers/char/console.c | 101 +++++++++++++++++++++------------------------
 xen/include/xen/console.h  |   4 +-
 3 files changed, 51 insertions(+), 59 deletions(-)

diff --git a/xen/arch/arm/vpl011.c b/xen/arch/arm/vpl011.c
index 236fd70d0847f375070dfff314bb8dd08d6ad166..efe77c13007716d0e0d70ab5ccf5f94268d5b693 100644
--- a/xen/arch/arm/vpl011.c
+++ b/xen/arch/arm/vpl011.c
@@ -81,12 +81,11 @@ static void vpl011_write_data_xen(struct domain *d, uint8_t data)
     unsigned long flags;
     struct vpl011 *vpl011 = &d->arch.vpl011;
     struct vpl011_xen_backend *intf = vpl011->backend.xen;
-    struct domain *input = console_get_domain();
 
     VPL011_LOCK(d, flags);
 
     intf->out[intf->out_prod++] = data;
-    if ( d == input )
+    if ( d->domain_id == console_get_owner() )
     {
         if ( intf->out_prod == 1 )
         {
@@ -126,8 +125,6 @@ static void vpl011_write_data_xen(struct domain *d, uint8_t data)
     vpl011_update_interrupt_status(d);
 
     VPL011_UNLOCK(d, flags);
-
-    console_put_domain(input);
 }
 
 /*
diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index 8d68116991ba9e2c5a36840b4d973f8cafe95488..f5ff3ebd830d631fa5d8fb5db1cf68adafcd02b4 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -461,17 +461,15 @@ static void cf_check dump_console_ring_key(unsigned char key)
 
 /*
  * CTRL-<switch_char> changes input direction, rotating among Xen, Dom0,
- * and the DomUs started from Xen at boot.
+ * and the DomUs.
  */
 #define switch_code (opt_conswitch[0]-'a'+1)
-/*
- * console_owner=0 => input to xen
- * console_owner=1 => input to dom0 (or the sole shim domain)
- * console_owner=N => input to dom(N-1)
- */
-static unsigned int __read_mostly console_owner = 0;
 
-#define max_console_rx (max_init_domid + 1)
+/*
+ * Current console owner domain ID: either Xen or domain w/ d->is_console ==
+ * true.
+ */
+static domid_t __read_mostly console_owner = DOMID_XEN;
 
 static struct domain *console_get_domain_by_id(domid_t domid)
 {
@@ -488,14 +486,12 @@ static struct domain *console_get_domain_by_id(domid_t domid)
     return NULL;
 }
 
-struct domain *console_get_domain(void)
+static struct domain *console_get_domain(void)
 {
-    if ( console_owner == 0 )
-            return NULL;
-    return console_get_domain_by_id(console_owner - 1);
+    return console_get_domain_by_id(console_owner);
 }
 
-void console_put_domain(struct domain *d)
+static void console_put_domain(struct domain *d)
 {
     if ( d )
         rcu_unlock_domain(d);
@@ -510,42 +506,49 @@ static bool console_owner_possible(domid_t domid)
     return !!d;
 }
 
-static void console_switch_input(void)
+int console_set_owner(domid_t domid)
 {
-    unsigned int next_rx = console_owner;
+    if ( domid == DOMID_XEN )
+        printk("*** Serial input to Xen");
+    else if ( console_owner_possible(domid) )
+        printk("*** Serial input to DOM%u", domid);
+    else
+        return -ENOENT;
 
-    /*
-     * Rotate among Xen, dom0 and boot-time created domUs while skipping
-     * switching serial input to non existing domains.
-     */
-    for ( ; ; )
-    {
-        domid_t domid;
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
-        if ( console_owner_possible(domid) )
-        {
-            console_owner = next_rx;
-            printk("*** Serial input to DOM%u", domid);
-            break;
-        }
-    }
+    console_owner = domid;
 
     if ( switch_code )
         printk(" (type 'CTRL-%c' three times to switch input)",
                opt_conswitch[0]);
     printk("\n");
+
+    return 0;
+}
+
+domid_t console_get_owner(void)
+{
+    return console_owner;
+}
+
+/*
+ * Switch console input focus.
+ * Rotates input focus among Xen, dom0 and boot-time created domUs while
+ * skipping switching serial input to non existing domains.
+ */
+static void console_switch_input(void)
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
@@ -553,7 +556,7 @@ static void __serial_rx(char c)
     struct domain *d;
     int rc = 0;
 
-    if ( console_owner == 0 )
+    if ( console_owner == DOMID_XEN )
         return handle_keypress(c, false);
 
     d = console_get_domain();
@@ -1132,14 +1135,6 @@ void __init console_endboot(void)
 
     video_endboot();
 
-    /*
-     * If user specifies so, we fool the switch routine to redirect input
-     * straight back to Xen. I use this convoluted method so we still print
-     * a useful 'how to switch' message.
-     */
-    if ( opt_conswitch[1] == 'x' )
-        console_owner = max_console_rx;
-
     register_keyhandler('w', dump_console_ring_key,
                         "synchronously dump console ring buffer (dmesg)", 0);
     register_irq_keyhandler('+', &do_inc_thresh,
@@ -1149,8 +1144,8 @@ void __init console_endboot(void)
     register_irq_keyhandler('G', &do_toggle_guest,
                             "toggle host/guest log level adjustment", 0);
 
-    /* Serial input is directed to DOM0 by default. */
-    console_switch_input();
+    if ( opt_conswitch[1] != 'x' )
+        console_set_owner( get_initial_domain_id() );
 }
 
 int __init console_has(const char *device)
diff --git a/xen/include/xen/console.h b/xen/include/xen/console.h
index 8631fd279bfe1aba42b61d76fbdb45016c2859f9..c03028ad690fa6359105a174ecc77a30f2731948 100644
--- a/xen/include/xen/console.h
+++ b/xen/include/xen/console.h
@@ -31,8 +31,8 @@ void console_end_sync(void);
 void console_start_log_everything(void);
 void console_end_log_everything(void);
 
-struct domain *console_get_domain(void);
-void console_put_domain(struct domain *d);
+int console_set_owner(domid_t domid);
+domid_t console_get_owner(void);
 
 /*
  * Steal output from the console. Returns +ve identifier, else -ve error.

-- 
2.34.1

