From: Denis Mukhin <dmukhin@ford.com>
Date: Thu, 05 Dec 2024 20:42:04 -0800
Subject: [PATCH v2 34/35] xen/console: enable console owners w/ emulated
 NS8250
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241205-vuart-ns8250-v1-34-e9aa923127eb@ford.com>
References: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
In-Reply-To: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
To: xen-devel@lists.xenproject.org
Cc: Andrew Cooper <andrew.cooper3@citrix.com>, 
 Jan Beulich <jbeulich@suse.com>, Julien Grall <julien@xen.org>, 
 Stefano Stabellini <sstabellini@kernel.org>, 
 Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733460095; l=1133;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=m+DZYhBfJNv2KVuFKRvMQy0kCP3iadnxj6rLAihix3M=;
 b=RacSKnwM5fBYuU8iskMZVZ/uehW76whDkeSjA2tP9mNGpXECzUNwGvJga6wsGA/b5LOBbFu5w
 EWu5DcHxADFDmrUml9OkGjTT4S3BA2zE90U1GzOO4ch9aJoZcj+SqBz
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
index a26daee9c4c4b1134d0ae3d105ffdb656340b6df..798dfdf3412a2feef35e72946d6c59bee59a9251 100644
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
@@ -627,6 +630,8 @@ static void handle_keypress_in_domain(struct domain *d, char c)
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

