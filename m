From: Denis Mukhin <dmukhin@ford.com>
Date: Fri, 03 Jan 2025 17:58:08 -0800
Subject: [PATCH v3 02/24] arm/vuart: move vpl011-related code to vpl011
 emulator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250103-vuart-ns8250-v3-v1-2-c5d36b31d66c@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735955892; l=4317;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=WBvO8bA+8Nj2y5g4Kr43LtifU20Luw0hJhjCrT4qixs=;
 b=HFI194W9aVN9+Fxa7KERSNI5ADEY+BH7XLcU4u6tM3rnmm0dWvu6LsM9uIa17987zZ2YYl9bn
 F+CVVTwcpKgDkOE0n0HGlCmYRbIhuuvizU+fBvDJOd7E/Zi9Ocism8K
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Xen console driver has vpl011-related logic which shall belong vpl011 emulator
code (Arm port). Move vpl011-related code from arch-independent console driver
to Arm's vpl011.c.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/arch/arm/include/asm/vpl011.h |  2 +-
 xen/arch/arm/vpl011.c             | 15 +++++++++++----
 xen/drivers/char/console.c        | 23 +++++++++--------------
 3 files changed, 21 insertions(+), 19 deletions(-)

diff --git a/xen/arch/arm/include/asm/vpl011.h b/xen/arch/arm/include/asm/vpl011.h
index c09abcd7a9b3356d0809743517934adae00087f5..cc838682815c0d049ba33d3bf9966a64b2e527dd 100644
--- a/xen/arch/arm/include/asm/vpl011.h
+++ b/xen/arch/arm/include/asm/vpl011.h
@@ -69,7 +69,7 @@ struct vpl011_init_info {
 int domain_vpl011_init(struct domain *d,
                        struct vpl011_init_info *info);
 void domain_vpl011_deinit(struct domain *d);
-void vpl011_rx_char_xen(struct domain *d, char c);
+int vpl011_rx_char_xen(struct domain *d, char c);
 #else
 static inline int domain_vpl011_init(struct domain *d,
                                      struct vpl011_init_info *info)
diff --git a/xen/arch/arm/vpl011.c b/xen/arch/arm/vpl011.c
index 1fc3114cce9ddb48cf199834c8e9abe8cfba92b5..c72f3778bfedf9434f9d1a0cd7fa33852563112d 100644
--- a/xen/arch/arm/vpl011.c
+++ b/xen/arch/arm/vpl011.c
@@ -567,16 +567,21 @@ static void vpl011_data_avail(struct domain *d,
 
 /*
  * vpl011_rx_char_xen adds a char to a domain's vpl011 receive buffer.
- * It is only used when the vpl011 backend is in Xen.
  */
-void vpl011_rx_char_xen(struct domain *d, char c)
+int vpl011_rx_char_xen(struct domain *d, char c)
 {
     unsigned long flags;
     struct vpl011 *vpl011 = &d->arch.vpl011;
     struct vpl011_xen_backend *intf = vpl011->backend.xen;
     XENCONS_RING_IDX in_cons, in_prod, in_fifo_level;
 
-    ASSERT(!vpl011->backend_in_domain);
+    /* Forward input iff the vpl011 backend is in Xen. */
+    if ( vpl011->backend_in_domain )
+        return -ENODEV;
+
+    if ( intf == NULL )
+        return -ENODEV;
+
     VPL011_LOCK(d, flags);
 
     in_cons = intf->in_cons;
@@ -584,7 +589,7 @@ void vpl011_rx_char_xen(struct domain *d, char c)
     if ( xencons_queued(in_prod, in_cons, sizeof(intf->in)) == sizeof(intf->in) )
     {
         VPL011_UNLOCK(d, flags);
-        return;
+        return -ENOSPC;
     }
 
     intf->in[xencons_mask(in_prod, sizeof(intf->in))] = c;
@@ -596,6 +601,8 @@ void vpl011_rx_char_xen(struct domain *d, char c)
 
     vpl011_data_avail(d, in_fifo_level, sizeof(intf->in), 0, SBSA_UART_FIFO_SIZE);
     VPL011_UNLOCK(d, flags);
+
+    return 0;
 }
 
 static void vpl011_notification(struct vcpu *v, unsigned int port)
diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index 4cb397116b44935214801c496b30e44c9399c59a..1411c991977b5fb26ee5709e523b7bc32b612808 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -529,6 +529,8 @@ static void switch_serial_input(void)
 
 static void __serial_rx(char c)
 {
+    int rc = 0;
+
     switch ( console_rx )
     {
     case 0:
@@ -554,21 +556,11 @@ static void __serial_rx(char c)
     {
         struct domain *d = rcu_lock_domain_by_id(console_rx - 1);
 
-        /*
-         * If we have a properly initialized vpl011 console for the
-         * domain, without a full PV ring to Dom0 (in that case input
-         * comes from the PV ring), then send the character to it.
-         */
-        if ( d != NULL &&
-             !d->arch.vpl011.backend_in_domain &&
-             d->arch.vpl011.backend.xen != NULL )
-            vpl011_rx_char_xen(d, c);
-        else
-            printk("Cannot send chars to Dom%d: no UART available\n",
-                   console_rx - 1);
-
-        if ( d != NULL )
+        if ( d )
+        {
+            rc = vpl011_rx_char_xen(d, c);
             rcu_unlock_domain(d);
+        }
 
         break;
     }
@@ -579,6 +571,9 @@ static void __serial_rx(char c)
     if ( pv_shim && pv_console )
         consoled_guest_tx(c);
 #endif
+
+    if ( rc )
+        printk(KERN_ERR "d%pd: failed to process console input: %d\n", d, rc);
 }
 
 static void cf_check serial_rx(char c)

-- 
2.34.1

