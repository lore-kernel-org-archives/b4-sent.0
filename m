From: Denis Mukhin <dmukhin@ford.com>
Date: Thu, 05 Dec 2024 20:41:51 -0800
Subject: [PATCH v2 21/35] xen/console: introduce console_init_owner()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241205-vuart-ns8250-v1-21-e9aa923127eb@ford.com>
References: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
In-Reply-To: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
To: xen-devel@lists.xenproject.org
Cc: Andrew Cooper <andrew.cooper3@citrix.com>, 
 Jan Beulich <jbeulich@suse.com>, Julien Grall <julien@xen.org>, 
 Stefano Stabellini <sstabellini@kernel.org>, 
 Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733460094; l=1949;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=9IHMF1BdeViUoT1r1xwy88EM2J39hJxCdMpf6FUj+oc=;
 b=rkPuVSjKM6PdcjQpqYx04yf5XSLLo6WwLxCVOm3Xp526geyD7FoALVxOn/SqrCa9cjSfLb+QZ
 qW8+QGL4+VvD3kA/ow2AsW8esC9XvQRMDoI/h0TfmZ1MW76KHXfU+fc
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

console_init_owner() is introduced for selecting the boot-time console owner.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/drivers/char/console.c | 27 +++++++++++++++++----------
 1 file changed, 17 insertions(+), 10 deletions(-)

diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index a8ab5c2bcb98e4cadf9ad2c9ad28d297977d0557..6261bdb5a2ac1075bc89fa408c0fd6cfef380ae6 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -554,6 +554,22 @@ static void console_find_owner(void)
         console_set_owner(DOMID_XEN);
 }
 
+static void console_init_owner(void)
+{
+    domid_t domid;
+
+    /*
+     * If user specifies so, we fool the switch routine to redirect input
+     * straight back to Xen.
+     */
+    if ( opt_conswitch[1] == 'x' )
+        domid = DOMID_XEN;
+    else
+        domid = get_initial_domain_id();
+
+    console_set_owner(domid);
+}
+
 static void __serial_rx(char c)
 {
     switch ( console_owner )
@@ -1143,14 +1159,6 @@ void __init console_endboot(void)
 
     video_endboot();
 
-    /*
-     * If user specifies so, we fool the switch routine to redirect input
-     * straight back to Xen. I use this convoluted method so we still print
-     * a useful 'how to switch' message.
-     */
-    if ( opt_conswitch[1] == 'x' )
-        console_owner = DOMID_XEN;
-
     register_keyhandler('w', dump_console_ring_key,
                         "synchronously dump console ring buffer (dmesg)", 0);
     register_irq_keyhandler('+', &do_inc_thresh,
@@ -1160,8 +1168,7 @@ void __init console_endboot(void)
     register_irq_keyhandler('G', &do_toggle_guest,
                             "toggle host/guest log level adjustment", 0);
 
-    /* Serial input is directed to DOM0 by default. */
-    console_find_owner();
+    console_init_owner();
 }
 
 int __init console_has(const char *device)

-- 
2.34.1

