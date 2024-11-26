From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:21:57 -0800
Subject: [PATCH 07/36] arm/vuart: use guest_printk()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-7-87b9a8375b7a@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=1513;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=6dwRL08Xk+9xlKPfi6ImA8lNmAhhTdKU8a+CgXv8hC0=;
 b=qZPve2qjLwadK8wGOIbj7Nd8nbym1+viKPOUXFNAuXOLAB6VxWO9OyEzQ4wvq/o0cAjeApBl8
 nHNN9lxCnELAb4T5ICI1vgTq6DKGkT2jX3/kAZwDT0rQ5syNYVP7mm8
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use guest_printk() in all current in-hypervisor UART emulators.

That slightly improves the logging as guest_printk() already prints the
domain ID.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/arch/arm/vpl011.c | 2 +-
 xen/arch/arm/vuart.c  | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)

diff --git a/xen/arch/arm/vpl011.c b/xen/arch/arm/vpl011.c
index 1fc3114cce9ddb48cf199834c8e9abe8cfba92b5..8ade6f2588b8bbcc58fb0f9edc324502a1992ce7 100644
--- a/xen/arch/arm/vpl011.c
+++ b/xen/arch/arm/vpl011.c
@@ -107,7 +107,7 @@ static void vpl011_write_data_xen(struct domain *d, uint8_t data)
             if ( data != '\n' )
                 intf->out[intf->out_prod++] = '\n';
             intf->out[intf->out_prod++] = '\0';
-            printk("DOM%u: %s", d->domain_id, intf->out);
+            guest_printk(d, "%s", intf->out);
             intf->out_prod = 0;
         }
     }
diff --git a/xen/arch/arm/vuart.c b/xen/arch/arm/vuart.c
index ac76e2327bb84f05ea5716c6f5550f94812d2827..38ce8cc14fac4132578059b696be952b29fab809 100644
--- a/xen/arch/arm/vuart.c
+++ b/xen/arch/arm/vuart.c
@@ -89,7 +89,7 @@ static void vuart_print_char(struct vcpu *v, char c)
         if ( c != '\n' )
             uart->buf[uart->idx++] = '\n';
         uart->buf[uart->idx] = '\0';
-        printk(XENLOG_G_DEBUG "DOM%u: %s", d->domain_id, uart->buf);
+        guest_printk(d, "%s", uart->buf);
         uart->idx = 0;
     }
     spin_unlock(&uart->lock);

-- 
2.34.1

