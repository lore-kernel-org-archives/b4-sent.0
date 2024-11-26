From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:22:18 -0800
Subject: [PATCH 28/36] xen/console: simplify console owner switch hint
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-28-87b9a8375b7a@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=881;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=IPN7McCx2GMasxWXQvc4fWV7JKmlK0HvFSHLV2y3YOg=;
 b=oN+IviwIRCqEG8bugGFvwedgL4OLnk6vPm6uROZKAImjHwOcHtL8C/RatenQWqO7uSxuLu4gJ
 ZT0mRsqa0qjA91V6VY/0iAfAWAnoxW6FR+klTt83UV5rUFCDfvYqK8S
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update the hint w/ the combination of keys to press to switch physical console
to the next owner.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/drivers/char/console.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index 3d8d3c852e69d8fddd1d978fdd8932eb75551f25..9f67ecb26f5ab1183d17c83631a17b45cfefd5ab 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -526,8 +526,8 @@ int console_set_owner(domid_t domid)
     console_owner = domid;
 
     if ( switch_code )
-        printk(" (type 'CTRL-%c' three times to switch input)",
-               opt_conswitch[0]);
+        printk(" (type 'CTRL-%c%c%c' to switch input)",
+               opt_conswitch[0], opt_conswitch[0], opt_conswitch[0]);
     printk("\n");
 
     return 0;

-- 
2.34.1

