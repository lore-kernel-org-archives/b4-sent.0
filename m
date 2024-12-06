From: Denis Mukhin <dmukhin@ford.com>
Date: Thu, 05 Dec 2024 20:41:55 -0800
Subject: [PATCH v2 25/35] xen/console: simplify console owner switch hint
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241205-vuart-ns8250-v1-25-e9aa923127eb@ford.com>
References: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
In-Reply-To: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
To: xen-devel@lists.xenproject.org
Cc: Andrew Cooper <andrew.cooper3@citrix.com>, 
 Jan Beulich <jbeulich@suse.com>, Julien Grall <julien@xen.org>, 
 Stefano Stabellini <sstabellini@kernel.org>, 
 Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733460094; l=881;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=8rbmvBVON7AxnVLWZe4TyiZNfaP+ce1iMVhidiuAaeA=;
 b=ngSX/Bjan55Yf6HbhjCcVyH1MRrm+rX6fCLNvoL2CELYqurZ5AMRgsHmNbAjVstU/zeZv2WRK
 t2fk6SQ9SZpC3ILMTDGon5ON0+OcpvIJPkVFDh3uiDU0ZPaGM8EUHGk
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
index 115967d179998cba4a81578caba09db4e4aca7f7..d22fb4a253af26f9b51d91bd408e1dbf4bb5a7c1 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -528,8 +528,8 @@ int console_set_owner(domid_t domid)
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

