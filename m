From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:22:10 -0800
Subject: [PATCH 20/36] xen/console: introduce consoled_is_enabled()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-20-87b9a8375b7a@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=4384;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=dmfspZvPgoI4EGX+YrlzVMe2EpWEao1fcT911zaxlEE=;
 b=b8yT+vorsOT/zpMXLcXELRcjbP8A5xks6ATDBkx57XKFIDY+aHn3Ylyvhm4Z3AH3+ZRx1C8qL
 Jwel3yfp81XClJATR0JRkeqv+Ek2LpNbnP2Vh/Z/EibO0x25KL5xBeT
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There are few places which check pv_shim console under CONFIG_PV_SHIM in xen
console driver. Instead of #ifdef-ing, use new consoled_is_enabled() to
customize the logic.

Header file now can be included w/o CONFIG_X86.

Signature of consoled_guest_{rx,tx} has changed to account for follow-on
console switch logic cleanup.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/drivers/char/console.c  | 10 +++-------
 xen/drivers/char/consoled.c | 18 ++++++++++++++----
 xen/include/xen/consoled.h  | 35 +++++++++++++++++++++++++++++++++--
 3 files changed, 50 insertions(+), 13 deletions(-)

diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index f034ce5aab3f3bf59b0df9fa583ee9ce32dbf665..60c055396b697869b04b9132b0dcfa832fabe932 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -33,9 +33,9 @@
 #include <xen/pv_console.h>
 #include <asm/setup.h>
 #include <xen/sections.h>
+#include <xen/consoled.h>
 
 #ifdef CONFIG_X86
-#include <xen/consoled.h>
 #include <asm/guest.h>
 #endif
 #ifdef CONFIG_SBSA_VUART_CONSOLE
@@ -505,11 +505,9 @@ static void console_find_owner(void)
             break;
         }
 
-#ifdef CONFIG_PV_SHIM
-        if ( next_rx == 1 )
+        if ( consoled_is_enabled() && next_rx == 1 )
             domid = get_initial_domain_id();
         else
-#endif
             domid = next_rx - 1;
         d = rcu_lock_domain_by_id(domid);
         if ( d )
@@ -573,10 +571,8 @@ static void __serial_rx(char c)
 #endif
     }
 
-#ifdef CONFIG_X86
-    if ( pv_shim && pv_console )
+    if ( consoled_is_enabled() )
         consoled_guest_tx(c);
-#endif
 }
 
 static void cf_check serial_rx(char c)
diff --git a/xen/drivers/char/consoled.c b/xen/drivers/char/consoled.c
index b415b632cecc0a80e161b701d7b70ba4f3cc5fb8..d6624e7697f56e1a1959b0efa5dca104f34af002 100644
--- a/xen/drivers/char/consoled.c
+++ b/xen/drivers/char/consoled.c
@@ -43,13 +43,13 @@ struct xencons_interface *consoled_get_ring_addr(void)
 static char buf[BUF_SZ + 1];
 
 /* Receives characters from a domain's PV console */
-void consoled_guest_rx(void)
+int consoled_guest_rx(void)
 {
     size_t idx = 0;
     XENCONS_RING_IDX cons, prod;
 
     if ( !cons_ring )
-        return;
+        return 0;
 
     spin_lock(&rx_lock);
 
@@ -91,15 +91,17 @@ void consoled_guest_rx(void)
 
  out:
     spin_unlock(&rx_lock);
+
+    return 0;
 }
 
 /* Sends a character into a domain's PV console */
-void consoled_guest_tx(char c)
+int consoled_guest_tx(char c)
 {
     XENCONS_RING_IDX cons, prod;
 
     if ( !cons_ring )
-        return;
+        return 0;
 
     cons = ACCESS_ONCE(cons_ring->in_cons);
     prod = cons_ring->in_prod;
@@ -118,6 +120,7 @@ void consoled_guest_tx(char c)
 
     cons_ring->in[MASK_XENCONS_IDX(prod++, cons_ring->in)] = c;
 
+
     /* Write to the ring before updating the pointer */
     smp_wmb();
     ACCESS_ONCE(cons_ring->in_prod) = prod;
@@ -125,6 +128,13 @@ void consoled_guest_tx(char c)
  notify:
     /* Always notify the guest: prevents receive path from getting stuck. */
     pv_shim_inject_evtchn(pv_console_evtchn());
+
+    return 0;
+}
+
+bool consoled_is_enabled(void)
+{
+    return pv_shim && pv_console;
 }
 
 /*
diff --git a/xen/include/xen/consoled.h b/xen/include/xen/consoled.h
index bd7ab6329ee8a7c466484021247241ded8ed03c7..b88e3025fde84a52d7027b785b0a51ada8493832 100644
--- a/xen/include/xen/consoled.h
+++ b/xen/include/xen/consoled.h
@@ -3,10 +3,41 @@
 
 #include <public/io/console.h>
 
+#if defined(CONFIG_PV_SHIM)
+
 void consoled_set_ring_addr(struct xencons_interface *ring);
 struct xencons_interface *consoled_get_ring_addr(void);
-void consoled_guest_rx(void);
-void consoled_guest_tx(char c);
+int consoled_guest_rx(void);
+int consoled_guest_tx(char c);
+bool consoled_is_enabled(void);
+
+#else
+
+void consoled_set_ring_addr(struct xencons_interface *ring)
+{
+}
+
+struct xencons_interface *consoled_get_ring_addr(void)
+{
+    return NULL;
+}
+
+int consoled_guest_rx(void)
+{
+    return 0;
+}
+
+int consoled_guest_tx(char c)
+{
+    return 0;
+}
+
+bool consoled_is_enabled(void)
+{
+    return false;
+}
+
+#endif /* #if defined(CONFIG_PV_SHIM) */
 
 #endif /* __XEN_CONSOLED_H__ */
 /*

-- 
2.34.1

