From: Denis Mukhin <dmukhin@ford.com>
Date: Thu, 05 Dec 2024 20:41:43 -0800
Subject: [PATCH v2 13/35] xen/console: rename console_input_domain
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241205-vuart-ns8250-v1-13-e9aa923127eb@ford.com>
References: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
In-Reply-To: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
To: xen-devel@lists.xenproject.org
Cc: Andrew Cooper <andrew.cooper3@citrix.com>, 
 Jan Beulich <jbeulich@suse.com>, Julien Grall <julien@xen.org>, 
 Stefano Stabellini <sstabellini@kernel.org>, 
 Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733460094; l=2162;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=TjvkwSY30h8BpopVytXRbdfBD9IC9WbY4nf7jp2MPFs=;
 b=zeaE1xdzcz1rmGEWkbbULiMYNpdF8vIKM2kxIXRGbDkvs9GB3XLoGOpOKjhPDnOFynaL6G94y
 BDNF2sVTre6A39d5KuhX2puYeT9E2Bn+u1uXzBcSjf+s9GgIpAmb6ZQ
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

console_input_domain() takes an RCU lock to protect domain structure.
That implies call to rcu_unlock_domain() after use.

Rename console_input_domain() to rcu_lock_domain_console_owner() to
highlight the need of calling rcu_unlock_domain().

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/arch/arm/vpl011.c      | 2 +-
 xen/drivers/char/console.c | 2 +-
 xen/include/xen/console.h  | 2 +-
 3 files changed, 3 insertions(+), 3 deletions(-)

diff --git a/xen/arch/arm/vpl011.c b/xen/arch/arm/vpl011.c
index fe36fe2bd1529a4114884580ded6d6fa55a22f0e..4d682e98553303b4a12f5cd7e5e67ab096cd7cc2 100644
--- a/xen/arch/arm/vpl011.c
+++ b/xen/arch/arm/vpl011.c
@@ -78,7 +78,7 @@ static void vpl011_write_data_xen(struct domain *d, uint8_t data)
     unsigned long flags;
     struct vpl011 *vpl011 = &d->arch.vpl011;
     struct vpl011_xen_backend *intf = vpl011->backend.xen;
-    struct domain *input = console_input_domain();
+    struct domain *input = rcu_lock_domain_console_owner();
 
     VPL011_LOCK(d, flags);
 
diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index 0af4b551801356f242f1770b3826608136d65653..01fcbd5581d11f8f4f2b23592255b5c744430a3e 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -477,7 +477,7 @@ static unsigned int __read_mostly console_rx = 0;
 
 #ifdef CONFIG_SBSA_VUART_CONSOLE
 /* Make sure to rcu_unlock_domain after use */
-struct domain *console_input_domain(void)
+struct domain *rcu_lock_domain_console_owner(void)
 {
     if ( console_rx == 0 )
             return NULL;
diff --git a/xen/include/xen/console.h b/xen/include/xen/console.h
index 6dfbade3ece36352c74f1124305da945b210f2a7..0e211e44d9703c804e18f52c9743916f8d2a9d4e 100644
--- a/xen/include/xen/console.h
+++ b/xen/include/xen/console.h
@@ -31,7 +31,7 @@ void console_end_sync(void);
 void console_start_log_everything(void);
 void console_end_log_everything(void);
 
-struct domain *console_input_domain(void);
+struct domain *rcu_lock_domain_console_owner(void);
 
 /*
  * Steal output from the console. Returns +ve identifier, else -ve error.

-- 
2.34.1

