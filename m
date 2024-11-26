From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:22:25 -0800
Subject: [PATCH 35/36] xen/console: enable console owners w/ emulated
 NS8250
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-35-87b9a8375b7a@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=1133;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=WQSeR36nIyjmpuQo8H1p9/NbRUrGXqQm6ZbcYesml3s=;
 b=CpDYEchPnsqpvivWMdQylePfQPuJSv0/SjOEWfua7YW9lLt1hgiNJ6VsfmU5JHvY35yc3Ople
 waiIIpFcbLcC2C5el3B47d6MtywojYP1vjZQlm+z48MSNaddZKt8lgp
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable console focus for domains w/ virtual NS8250.

Code change allows to capture the output from the guest OS now and send it to
the physical console device.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/drivers/char/console.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index 24a8263045b0e5ecf901d08e627f34a80edd297d..54595b486b9761d0a17831b95481f2fa9bdcfcc7 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -41,6 +41,9 @@
 #ifdef CONFIG_SBSA_VUART_CONSOLE
 #include <asm/vpl011.h>
 #endif
+#if defined(CONFIG_HAS_VUART_NS8250)
+#include <asm/hvm/vuart_ns8250.h>
+#endif
 
 /* console: comma-separated list of console outputs. */
 static char __initdata opt_console[30] = OPT_CONSOLE_STR;
@@ -581,6 +584,8 @@ static void handle_keypress_in_domain(struct domain *d, char c)
     {
 #if defined(CONFIG_SBSA_VUART_CONSOLE)
         rc = vpl011_rx_char_xen(d, c);
+#elif defined(CONFIG_HAS_VUART_NS8250)
+        rc = vuart_putchar(&d->arch.hvm.vuart, c);
 #endif
     }
     /*

-- 
2.34.1

