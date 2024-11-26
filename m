From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:22:06 -0800
Subject: [PATCH 16/36] xen/console: rename console_input_domain
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-16-87b9a8375b7a@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=2162;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=//8B6RWBIW7SNgnF2T6+HEA2/O3wgsD0ciOR+76PaLM=;
 b=F6KU38cCC+uW7VC+/FDMuTylh4u51qK5IZuAVjuLIRIwoAHjJEwX1ZcwPeWYsBp7Jcz2UZs+H
 m3VQ/gQTRhgDEAbVrKlIKpMw6P5C7JIWDqUAjxReSCvMICF7iavKNUM
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
index 3e1487b101053891c9c0fb7fb50af1c547d4cbf3..07ef872d72b7881a70f4a938dcd6bea4c30198d9 100644
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

