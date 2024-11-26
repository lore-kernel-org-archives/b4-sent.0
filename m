From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:22:08 -0800
Subject: [PATCH 18/36] xen/console: rename console_rx to console_owner
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-18-87b9a8375b7a@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=3503;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=adx3ttDq9DGxs5v/iNqFG/t0SkuLKBWjA23PcHLO1+c=;
 b=IGxjWhFAg7XglUWziOn324G97nMmVYuDMsHVRirzfW0FLmtntUSWMQ0+UUZF6Y5jWsWkcWmKg
 K0SKJ9oAAGaAf7mlgCU66d5Ocl+sy3UFeBq8D1SW6JucgTfyS4RY07A
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Preparation for the follow on change to switch console_owner to
domid_t address space.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/drivers/char/console.c | 26 +++++++++++++-------------
 1 file changed, 13 insertions(+), 13 deletions(-)

diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index f8a7db385c9525cabc69ceb1a84d73f57863aa45..86bf899ada8f8221ffc77bcffb1f58777a22198e 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -467,11 +467,11 @@ static void cf_check dump_console_ring_key(unsigned char key)
  */
 #define switch_code (opt_conswitch[0]-'a'+1)
 /*
- * console_rx=0 => input to xen
- * console_rx=1 => input to dom0 (or the sole shim domain)
- * console_rx=N => input to dom(N-1)
+ * console_owner=0 => input to xen
+ * console_owner=1 => input to dom0 (or the sole shim domain)
+ * console_owner=N => input to dom(N-1)
  */
-static unsigned int __read_mostly console_rx = 0;
+static unsigned int __read_mostly console_owner = 0;
 
 #define max_console_rx (max_init_domid + 1)
 
@@ -479,15 +479,15 @@ static unsigned int __read_mostly console_rx = 0;
 /* Make sure to rcu_unlock_domain after use */
 struct domain *rcu_lock_domain_console_owner(void)
 {
-    if ( console_rx == 0 )
+    if ( console_owner == 0 )
             return NULL;
-    return rcu_lock_domain_by_id(console_rx - 1);
+    return rcu_lock_domain_by_id(console_owner - 1);
 }
 #endif
 
 static void console_find_owner(void)
 {
-    unsigned int next_rx = console_rx;
+    unsigned int next_rx = console_owner;
 
     /*
      * Rotate among Xen, dom0 and boot-time created domUs while skipping
@@ -500,7 +500,7 @@ static void console_find_owner(void)
 
         if ( next_rx++ >= max_console_rx )
         {
-            console_rx = 0;
+            console_owner = 0;
             printk("*** Serial input to Xen");
             break;
         }
@@ -515,7 +515,7 @@ static void console_find_owner(void)
         if ( d )
         {
             rcu_unlock_domain(d);
-            console_rx = next_rx;
+            console_owner = next_rx;
             printk("*** Serial input to DOM%u", domid);
             break;
         }
@@ -529,7 +529,7 @@ static void console_find_owner(void)
 
 static void __serial_rx(char c)
 {
-    switch ( console_rx )
+    switch ( console_owner )
     {
     case 0:
         return handle_keypress(c, false);
@@ -552,7 +552,7 @@ static void __serial_rx(char c)
 #ifdef CONFIG_SBSA_VUART_CONSOLE
     default:
     {
-        struct domain *d = rcu_lock_domain_by_id(console_rx - 1);
+        struct domain *d = rcu_lock_domain_by_id(console_owner - 1);
 
         /*
          * If we have a properly initialized vpl011 console for the
@@ -563,7 +563,7 @@ static void __serial_rx(char c)
             vpl011_rx_char_xen(d, c);
         else
             printk("Cannot send chars to Dom%d: no UART available\n",
-                   console_rx - 1);
+                   console_owner - 1);
 
         if ( d != NULL )
             rcu_unlock_domain(d);
@@ -1116,7 +1116,7 @@ void __init console_endboot(void)
      * a useful 'how to switch' message.
      */
     if ( opt_conswitch[1] == 'x' )
-        console_rx = max_console_rx;
+        console_owner = max_console_rx;
 
     register_keyhandler('w', dump_console_ring_key,
                         "synchronously dump console ring buffer (dmesg)", 0);

-- 
2.34.1

