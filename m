From: Denis Mukhin <dmukhin@ford.com>
Date: Thu, 05 Dec 2024 20:41:57 -0800
Subject: [PATCH v2 27/35] xen/console: flush console ring to physical
 console
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241205-vuart-ns8250-v1-27-e9aa923127eb@ford.com>
References: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
In-Reply-To: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
To: xen-devel@lists.xenproject.org
Cc: Andrew Cooper <andrew.cooper3@citrix.com>, 
 Jan Beulich <jbeulich@suse.com>, Julien Grall <julien@xen.org>, 
 Stefano Stabellini <sstabellini@kernel.org>, 
 Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733460095; l=3110;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=9P4Y8stZ3v9veFAxdHp9EFeTfuXrbjGeXMl4yBrDrRM=;
 b=LcDAXG+yR65ns4PDQ7+Ep0c/twONKtCO6FP3OyvFTTqVtifqgbIkwSkeCUfa9psmIj3lFPPnM
 83h3+UYJFZ4D7QPLSxSZewJhQFIyiw2yPpSDbEylErgaWgtM7WS39IF
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Messages printed before the serial and VGA consoles are initialized end up in
the internal console buffer (conring). Flush contents of conring to all
external consoles after external consoles are fully initialied.

Link: https://gitlab.com/xen-project/xen/-/issues/184
Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/drivers/char/console.c | 54 +++++++++++++++++++++++++++++++++-------------
 1 file changed, 39 insertions(+), 15 deletions(-)

diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index 581ee22b85302a54db5b9d5d28e8b2d689d31403..a26daee9c4c4b1134d0ae3d105ffdb656340b6df 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -426,23 +426,35 @@ void console_serial_puts(const char *s, size_t nr)
     pv_console_puts(s, nr);
 }
 
-static void cf_check dump_console_ring_key(unsigned char key)
+/*
+ * Write characters to physical console(s).
+ * That covers:
+ * - serial console;
+ * - video output.
+ */
+static void console_puts(const char *str, size_t len)
+{
+    ASSERT(rspin_is_locked(&console_lock));
+
+    console_serial_puts(str, len);
+    video_puts(str, len);
+}
+
+/*
+ * Flush contents of the conring to the physical console devices.
+ */
+static int console_flush(void)
 {
     uint32_t idx, len, sofar, c;
     unsigned int order;
     char *buf;
 
-    printk("'%c' pressed -> dumping console ring buffer (dmesg)\n", key);
-
-    /* create a buffer in which we'll copy the ring in the correct
-       order and NUL terminate */
     order = get_order_from_bytes(conring_size + 1);
     buf = alloc_xenheap_pages(order, 0);
     if ( buf == NULL )
-    {
-        printk("unable to allocate memory!\n");
-        return;
-    }
+        return -ENOMEM;
+
+    nrspin_lock_irq(&console_lock);
 
     c = conringc;
     sofar = 0;
@@ -457,10 +469,23 @@ static void cf_check dump_console_ring_key(unsigned char key)
         c += len;
     }
 
-    console_serial_puts(buf, sofar);
-    video_puts(buf, sofar);
+    console_puts(buf, sofar);
+
+    nrspin_unlock_irq(&console_lock);
 
     free_xenheap_pages(buf, order);
+
+    return 0;
+}
+
+static void cf_check dump_console_ring_key(unsigned char key)
+{
+    int rc;
+
+    printk("'%c' pressed -> dumping console ring buffer (dmesg)\n", key);
+    rc = console_flush();
+    if ( rc )
+        printk("failed to dump console ring buffer: %d\n", rc);
 }
 
 /*
@@ -707,10 +732,7 @@ static inline void xen_console_write(const char *str, size_t len)
  */
 static void console_write(const char *str, size_t len)
 {
-    ASSERT(rspin_is_locked(&console_lock));
-
-    console_serial_puts(str, len);
-    video_puts(str, len);
+    console_puts(str, len);
 
     if ( opt_console_xen )
         xen_console_write(str, len);
@@ -1177,6 +1199,8 @@ void __init console_endboot(void)
 
     video_endboot();
 
+    /* NB: send conring contents to all enabled physical consoles, if any */
+    console_flush();
     use_conring = opt_console_to_ring;
     smp_wmb();
 

-- 
2.34.1

