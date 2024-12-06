From: Denis Mukhin <dmukhin@ford.com>
Date: Thu, 05 Dec 2024 20:41:48 -0800
Subject: [PATCH v2 18/35] xen/console: introduce use of 'is_console' flag
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241205-vuart-ns8250-v1-18-e9aa923127eb@ford.com>
References: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
In-Reply-To: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
To: xen-devel@lists.xenproject.org
Cc: Andrew Cooper <andrew.cooper3@citrix.com>, 
 Jan Beulich <jbeulich@suse.com>, Julien Grall <julien@xen.org>, 
 Stefano Stabellini <sstabellini@kernel.org>, 
 Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733460094; l=4575;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=c1qncLIbvdXkIva3csVS48o24QoMrU3zNKu5KbZwS0s=;
 b=WG1ksIYw4EgMLqSvIv9tHZhu+lH3WcqfWVayi+nfHijfuS+xnIvMui9g5p5iudJvKLVyMnVUq
 PSoDBtHWfQ7CsaFONJoLb62ddxjajRWzEKEVzmeJCrzkAq7eNAreWBp
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The code now inspects d->is_console flag to decide whether the console focus
should move to the domain w/ console after administrator presses <Ctrl+aaa>.

Console owner domain switch logic updated accordingly.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/arch/arm/dom0less-build.c |  2 +-
 xen/arch/arm/domain.c         |  1 +
 xen/arch/arm/domctl.c         |  1 +
 xen/arch/x86/pv/shim.c        |  2 ++
 xen/common/domain.c           |  2 ++
 xen/drivers/char/console.c    | 14 ++++++++++----
 6 files changed, 17 insertions(+), 5 deletions(-)

diff --git a/xen/arch/arm/dom0less-build.c b/xen/arch/arm/dom0less-build.c
index de64ee930fdfe9a1c2842761275641485f69f675..32b5e8e16a28ae9a4951c8b7815638e69b66406a 100644
--- a/xen/arch/arm/dom0less-build.c
+++ b/xen/arch/arm/dom0less-build.c
@@ -833,6 +833,7 @@ static int __init construct_domU(struct domain *d,
             return rc;
 
         d->arch.emulation_flags |= ARM_EMU_VUART;
+        d->is_console = true;
     }
 
     rc = prepare_dtb_domU(d, &kinfo);
@@ -1015,7 +1016,6 @@ void __init create_domUs(void)
             panic("Error creating domain %s (rc = %ld)\n",
                   dt_node_name(node), PTR_ERR(d));
 
-        d->is_console = true;
         dt_device_set_used_by(node, d->domain_id);
 
         rc = construct_domU(d, node);
diff --git a/xen/arch/arm/domain.c b/xen/arch/arm/domain.c
index 02f9d59b38b4b7f6f73d97c421c9948c90e681d5..c52d6e932a9a71b620ecefacc1e884338858e3ea 100644
--- a/xen/arch/arm/domain.c
+++ b/xen/arch/arm/domain.c
@@ -781,6 +781,7 @@ int arch_domain_create(struct domain *d,
             goto fail;
 
         d->arch.emulation_flags |= ARM_EMU_VUART;
+        d->is_console = true;
     }
 
     if ( (rc = domain_vpci_init(d)) != 0 )
diff --git a/xen/arch/arm/domctl.c b/xen/arch/arm/domctl.c
index f80d34bf5f3d323a15db7f032073be52ea1009ae..81b5caf17c4e0badb2eefa90b1522c107f844d06 100644
--- a/xen/arch/arm/domctl.c
+++ b/xen/arch/arm/domctl.c
@@ -46,6 +46,7 @@ static int handle_vuart_init(struct domain *d,
     {
         vuart_op->evtchn = info.evtchn;
         d->arch.emulation_flags |= ARM_EMU_VUART;
+        d->is_console = true;
     }
 
     return rc;
diff --git a/xen/arch/x86/pv/shim.c b/xen/arch/x86/pv/shim.c
index 17cb30620290c76cf42251f70cfa4199c0e165d1..a55c1d2a1e616f8979677a198eb9caabc3afc6bf 100644
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
index 9e57dd4122a726e2fb42efe9c029e775202be0e6..aab546c0a8535e4f007cbbc9c5c552bcf66b5807 100644
--- a/xen/common/domain.c
+++ b/xen/common/domain.c
@@ -682,6 +682,8 @@ struct domain *domain_create(domid_t domid,
 
         old_hwdom = hardware_domain;
         hardware_domain = d;
+
+        d->is_console = true;
     }
 
     TRACE_TIME(TRC_DOM0_DOM_ADD, d->domain_id);
diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index 60c055396b697869b04b9132b0dcfa832fabe932..8cbac54c66044ae8581e486a782102b75c8bfaa9 100644
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
@@ -509,14 +509,20 @@ static void console_find_owner(void)
             domid = get_initial_domain_id();
         else
             domid = next_rx - 1;
+
         d = rcu_lock_domain_by_id(domid);
-        if ( d )
+        if ( d == NULL )
+            continue;
+
+        if ( d->is_console )
         {
             rcu_unlock_domain(d);
             console_owner = next_rx;
             printk("*** Serial input to DOM%u", domid);
             break;
         }
+
+        rcu_unlock_domain(d);
     }
 
     if ( switch_code )
@@ -814,7 +820,7 @@ static int printk_prefix_check(char *p, char **pp)
     return ((atomic_read(&print_everything) != 0) ||
             (loglvl < lower_thresh) ||
             ((loglvl < upper_thresh) && printk_ratelimit()));
-} 
+}
 
 static int cf_check parse_console_timestamps(const char *s)
 {

-- 
2.34.1

