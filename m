From: Denis Mukhin <dmukhin@ford.com>
Date: Fri, 03 Jan 2025 17:58:14 -0800
Subject: [PATCH v3 08/24] xen/console: rename switch_serial_input() to
 console_switch_input()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250103-vuart-ns8250-v3-v1-8-c5d36b31d66c@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735955892; l=1473;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=VlrDmVYSUYYEG2sJ1u5nbMuy01Nt/S2plh2q6DJ+BIw=;
 b=S1s8vEh//WnTsVDQMRNzdQ8IrNEV/vZqF5vI012/k7AeJFUsj7kHlwgXqm6tbP8iH+pQoIZMm
 eh6s4rBUInzDHPPpwvMdJSQgTovGbPH5QGbGKna4mP/7Vse5daRUn15
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Updated the name to highlight the physical console input selection logic:
existing code does not switch only serial console, it also switches debugging
console (debug I/O port and console hypercall).

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/drivers/char/console.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index 0927c0564a67098c70dab576ebeda3825fadfb61..48866cf47beda39e48a7774277238273566382b1 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -486,7 +486,7 @@ void console_put_domain(struct domain *d)
         rcu_unlock_domain(d);
 }
 
-static void switch_serial_input(void)
+static void console_switch_input(void)
 {
     unsigned int next_rx = console_rx;
 
@@ -577,7 +577,7 @@ static void cf_check serial_rx(char c)
         /* We eat CTRL-<switch_char> in groups of 3 to switch console input. */
         if ( ++switch_code_count == 3 )
         {
-            switch_serial_input();
+            console_switch_input();
             switch_code_count = 0;
         }
         return;
@@ -1117,7 +1117,7 @@ void __init console_endboot(void)
                             "toggle host/guest log level adjustment", 0);
 
     /* Serial input is directed to DOM0 by default. */
-    switch_serial_input();
+    console_switch_input();
 }
 
 int __init console_has(const char *device)

-- 
2.34.1

