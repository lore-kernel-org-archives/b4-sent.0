From: Denis Mukhin <dmukhin@ford.com>
Date: Fri, 03 Jan 2025 17:58:23 -0800
Subject: [PATCH v3 17/24] xen/console: flush console ring to physical
 console
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250103-vuart-ns8250-v3-v1-17-c5d36b31d66c@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735955892; l=3242;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=HNsOcWLWQbY0cAiixdwe0nN3gebiJS/e1uoFMNrsBDM=;
 b=Xv6GoU4z4xrDCRW2Ui109tIiHZ591VBeCDEtWzc4OIBnOqGgb9g8t7eqHfMNJFf2HQfO9eUm7
 +pxGVDJPNseDBbL6hz7cc71DJfD4v3daXwBkgrVfs/J93tGqVYRXDfK
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Internal console ring is used to hold Xen messages before external consoles
(serial, VGA) consoles are fully initialized.

Ensure all messages are sent to all external consoles after their
initialization is completed.

Link: https://gitlab.com/xen-project/xen/-/issues/184
Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/drivers/char/console.c | 56 +++++++++++++++++++++++++++++++++-------------
 1 file changed, 41 insertions(+), 15 deletions(-)

diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index 2f776b2f07cb15fae8060f3574db73234a38727a..96375067164980a138b1a93161712c0758f4f7fe 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -430,23 +430,36 @@ void console_serial_puts(const char *s, size_t nr)
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
+
+    nrspin_lock(&console_lock);
 
     c = conringc;
     sofar = 0;
@@ -461,10 +474,23 @@ static void cf_check dump_console_ring_key(unsigned char key)
         c += len;
     }
 
-    console_serial_puts(buf, sofar);
-    video_puts(buf, sofar);
+    console_puts(buf, sofar);
+
+    nrspin_unlock(&console_lock);
 
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
@@ -681,10 +707,7 @@ static void xen_console_write(const char *str, size_t len)
  */
 static void console_write(const char *str, size_t len, unsigned int flags)
 {
-    ASSERT(rspin_is_locked(&console_lock));
-
-    console_serial_puts(str, len);
-    video_puts(str, len);
+    console_puts(str, len);
 
 #ifdef CONFIG_X86
     if ( opt_console_xen )
@@ -1061,6 +1084,9 @@ void __init console_init_preirq(void)
     serial_set_rx_handler(sercon_handle, serial_rx);
     pv_console_set_rx_handler(serial_rx);
 
+    /* NB: send conring contents to all enabled physical consoles, if any */
+    console_flush();
+
     /* HELLO WORLD --- start-of-day banner text. */
     nrspin_lock(&console_lock);
     __putstr(xen_banner());

-- 
2.34.1

