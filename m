From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:22:07 -0800
Subject: [PATCH 17/36] xen/console: rename switch_serial_input() to
 console_find_owner()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-17-87b9a8375b7a@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=1478;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=kkv+AJB+iT69SEANPtdQ4jOx6o8Fe+p28DiGHObsMCE=;
 b=34yyRPfAwR5Xa4Xuz4/BOFOrcATMDRQQnnZ5y9UsR0hdVr18qx/Zq/l4GCrf/HFvgLYIzpxwv
 YVD7bNrxNZHCYCzTZGhZp5eE+8zkM7+FIcjsbE+IX79uUTZFrdW6EHP
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Updated the name to highlight the logic of selection the physical console
owner: existing code does not switch only serial console, it also switches
video console and debugging console (debug I/O port and console hypercall).

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/drivers/char/console.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index 01fcbd5581d11f8f4f2b23592255b5c744430a3e..f8a7db385c9525cabc69ceb1a84d73f57863aa45 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -485,7 +485,7 @@ struct domain *rcu_lock_domain_console_owner(void)
 }
 #endif
 
-static void switch_serial_input(void)
+static void console_find_owner(void)
 {
     unsigned int next_rx = console_rx;
 
@@ -588,7 +588,7 @@ static void cf_check serial_rx(char c)
         /* We eat CTRL-<switch_char> in groups of 3 to switch console input. */
         if ( ++switch_code_count == 3 )
         {
-            switch_serial_input();
+            console_find_owner();
             switch_code_count = 0;
         }
         return;
@@ -1128,7 +1128,7 @@ void __init console_endboot(void)
                             "toggle host/guest log level adjustment", 0);
 
     /* Serial input is directed to DOM0 by default. */
-    switch_serial_input();
+    console_find_owner();
 }
 
 int __init console_has(const char *device)

-- 
2.34.1

