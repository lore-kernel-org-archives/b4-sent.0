From: Denis Mukhin <dmukhin@ford.com>
Date: Fri, 03 Jan 2025 17:58:16 -0800
Subject: [PATCH v3 10/24] xen/console: introduce use of 'is_console' flag
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250103-vuart-ns8250-v3-v1-10-c5d36b31d66c@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735955892; l=6019;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=HwgHil59vq9EKv+z5DPAShRIPOKHguO2oiS7uAA2fgM=;
 b=THBoqR6cFXYEpRta1DnD8ynIu+e0N3IIpv1WCUSL8mxTJf0v4ahgyFVw22S7EsevQiO/aNfdQ
 gTOEUQZPWe1AgSSXG5v76XgncIw7A76rvEW6HZzdSMPo6zNHBbixHgu
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The code inspects d->is_console flag to decide whether the console focus
should move to the domain with console after administrator uses <Ctrl+aaa>
key combination to switch the console focus.

Console owner switch logic updated accordingly.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/arch/arm/dom0less-build.c |  1 -
 xen/arch/x86/pv/shim.c        |  2 ++
 xen/common/domain.c           |  2 ++
 xen/drivers/char/console.c    | 53 +++++++++++++++++++++++++++++++++++--------
 xen/drivers/virtdev-uart.c    |  2 ++
 5 files changed, 49 insertions(+), 11 deletions(-)

diff --git a/xen/arch/arm/dom0less-build.c b/xen/arch/arm/dom0less-build.c
index 78fba18b6aa80278207f920145c5aab4fecc6d18..818e693222059a5e99a44831be62644ac442392b 100644
--- a/xen/arch/arm/dom0less-build.c
+++ b/xen/arch/arm/dom0less-build.c
@@ -985,7 +985,6 @@ void __init create_domUs(void)
             panic("Error initializing LLC coloring for domain %s (rc = %d)\n",
                   dt_node_name(node), rc);
 
-        d->is_console = true;
         dt_device_set_used_by(node, d->domain_id);
 
         rc = construct_domU(d, node);
diff --git a/xen/arch/x86/pv/shim.c b/xen/arch/x86/pv/shim.c
index 81e4a0516d18b359561f471f1d96e38977661ca7..9eb120258aeaf7068eae88d1e7d1b95ea7a00f31 100644
--- a/xen/arch/x86/pv/shim.c
+++ b/xen/arch/x86/pv/shim.c
@@ -238,6 +238,8 @@ void __init pv_shim_setup_dom(struct domain *d, l4_pgentry_t *l4start,
      * guest from depleting the shim memory pool.
      */
     d->max_pages = domain_tot_pages(d);
+
+    d->is_console = true;
 }
 
 static void write_start_info(struct domain *d)
diff --git a/xen/common/domain.c b/xen/common/domain.c
index 0c4cc771115509afe3bb457b8002961a73f5a8e7..711ec3bf3b7845a6c295575421c252193ccbc0ae 100644
--- a/xen/common/domain.c
+++ b/xen/common/domain.c
@@ -706,6 +706,8 @@ struct domain *domain_create(domid_t domid,
 
         old_hwdom = hardware_domain;
         hardware_domain = d;
+
+        d->is_console = true;
     }
 
     TRACE_TIME(TRC_DOM0_DOM_ADD, d->domain_id);
diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index 33da5ff7933ea2186245763e07940c17d74bf40f..8d68116991ba9e2c5a36840b4d973f8cafe95488 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -1,8 +1,8 @@
 /******************************************************************************
  * console.c
- * 
+ *
  * Emergency console I/O for Xen and the domain-0 guest OS.
- * 
+ *
  * Copyright (c) 2002-2004, K A Fraser.
  *
  * Added printf_ratelimit
@@ -473,11 +473,26 @@ static unsigned int __read_mostly console_owner = 0;
 
 #define max_console_rx (max_init_domid + 1)
 
+static struct domain *console_get_domain_by_id(domid_t domid)
+{
+    struct domain *d = rcu_lock_domain_by_id(domid);
+
+    if ( !d )
+        return NULL;
+
+    if ( d->is_console )
+        return d;
+
+    rcu_unlock_domain(d);
+
+    return NULL;
+}
+
 struct domain *console_get_domain(void)
 {
     if ( console_owner == 0 )
             return NULL;
-    return rcu_lock_domain_by_id(console_owner - 1);
+    return console_get_domain_by_id(console_owner - 1);
 }
 
 void console_put_domain(struct domain *d)
@@ -486,6 +501,15 @@ void console_put_domain(struct domain *d)
         rcu_unlock_domain(d);
 }
 
+static bool console_owner_possible(domid_t domid)
+{
+    struct domain *d = console_get_domain_by_id(domid);
+
+    console_put_domain(d);
+
+    return !!d;
+}
+
 static void console_switch_input(void)
 {
     unsigned int next_rx = console_owner;
@@ -497,7 +521,6 @@ static void console_switch_input(void)
     for ( ; ; )
     {
         domid_t domid;
-        struct domain *d;
 
         if ( next_rx++ >= max_console_rx )
         {
@@ -510,10 +533,9 @@ static void console_switch_input(void)
             domid = get_initial_domain_id();
         else
             domid = next_rx - 1;
-        d = rcu_lock_domain_by_id(domid);
-        if ( d )
+
+        if ( console_owner_possible(domid) )
         {
-            rcu_unlock_domain(d);
             console_owner = next_rx;
             printk("*** Serial input to DOM%u", domid);
             break;
@@ -562,8 +584,19 @@ static void __serial_rx(char c)
         /* Deliver input to the PV shim console. */
         rc = consoled_guest_tx(c);
 
-    if ( rc )
-        printk(KERN_ERR "d%pd: failed to process console input: %d\n", d, rc);
+    switch ( rc )
+    {
+    case 0:
+        break;
+    case -EBUSY:    /* Loopback mode */
+    case -ENOSPC:   /* FIFO is full */
+        printk(KERN_WARNING "d%pd: failed to process console input: %d\n", d, rc);
+        break;
+    default:
+        d->is_console = false;
+        printk(KERN_ERR "d%pd: disabled console forwarding: %d\n", d, rc);
+        break;
+    }
 
     console_put_domain(d);
 }
@@ -807,7 +840,7 @@ static int printk_prefix_check(char *p, char **pp)
     return ((atomic_read(&print_everything) != 0) ||
             (loglvl < lower_thresh) ||
             ((loglvl < upper_thresh) && printk_ratelimit()));
-} 
+}
 
 static int cf_check parse_console_timestamps(const char *s)
 {
diff --git a/xen/drivers/virtdev-uart.c b/xen/drivers/virtdev-uart.c
index d238ef369c6b94429eaad9f33c79b63ba325b7c6..fe119e3e6e938957613b182cbef0a29bf67230d2 100644
--- a/xen/drivers/virtdev-uart.c
+++ b/xen/drivers/virtdev-uart.c
@@ -20,6 +20,7 @@ int virtdev_uart_init(struct domain *d, struct virtdev_uart_params *params)
 #if !defined(__i386__) && !defined(__x86_64__)
     d->arch.emulation_flags |= VIRTDEV_UART;
 #endif
+    d->is_console = true;
 
     return 0;
 }
@@ -33,6 +34,7 @@ void virtdev_uart_exit(struct domain *d)
 #if !defined(__i386__) && !defined(__x86_64__)
     d->arch.emulation_flags &= ~VIRTDEV_UART;
 #endif
+    d->is_console = false;
 }
 
 int virtdev_uart_putchar(struct domain *d, char c)

-- 
2.34.1

