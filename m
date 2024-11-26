From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:22:11 -0800
Subject: [PATCH 21/36] xen/console: introduce use of 'is_console' flag
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-21-87b9a8375b7a@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=3376;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=ly2NKmV1rm1k90TAwD4huxu/gpF7eMHcF04jNDfnH2A=;
 b=Adf9/uDabysbO97VQCxegMuFHWIbw+k/X5FX4Vsxz0Y+j/VcL+5URcPHM/jpc4NJZyL8kTyY4
 yGmxTV2nxksDqRPybSI7d7nPcT9HN8BKUfsx8LBkoVWN5+6Gsr2vfOd
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The code now inspects d->is_console flag to decide whether the console focus
should move to the domain w/ console after administrator presses <Ctrl+aaa>.

To do that max_init_domid is updated in domain_create().

Console owner domain switch logic updated accordingly.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/arch/x86/pv/shim.c     |  2 ++
 xen/common/domain.c        | 14 ++++++++++++++
 xen/drivers/char/console.c | 14 ++++++++++----
 3 files changed, 26 insertions(+), 4 deletions(-)

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
index d8f6829db50dabba7464004b39eea39f6970f800..56f5d3b2031c52d567bfcf839740600320d952e9 100644
--- a/xen/common/domain.c
+++ b/xen/common/domain.c
@@ -682,6 +682,8 @@ struct domain *domain_create(domid_t domid,
 
         old_hwdom = hardware_domain;
         hardware_domain = d;
+
+        d->is_console = true;
     }
 
     TRACE_TIME(TRC_DOM0_DOM_ADD, d->domain_id);
@@ -818,6 +820,18 @@ struct domain *domain_create(domid_t domid,
 
     memcpy(d->handle, config->handle, sizeof(d->handle));
 
+    /*
+     * Housekeeping for physical console forwarding to the domain.
+     */
+    if ( !is_system_domain(d) && max_init_domid < domid )
+        max_init_domid = domid;
+
+    /*
+     * NB: flag is already set for PV shim and hardware domain, check whether
+     * virtual UART is present.
+     */
+    d->is_console |= domain_has_vuart(d);
+
     return d;
 
  fail:
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

