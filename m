From: Denis Mukhin <dmukhin@ford.com>
Date: Fri, 03 Jan 2025 17:58:20 -0800
Subject: [PATCH v3 14/24] xen/console: simplify console owner switch hint
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250103-vuart-ns8250-v3-v1-14-c5d36b31d66c@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735955892; l=896;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=WzdT/Oy8WMU/I7irURWT2SUpInPaVWdH8Z0/y7n+8AQ=;
 b=0j4lA25445KHzzpLVNgHBUI7bv00MN0Fqcvm5irJlwmNd4cGdfAKratJveXfG1O5lhSWXgwHE
 Y4tyt3EKNmYC05cRxLpm0AvVDCaAFO7SHVx7/Fypjcnz0cJJZjLKzPO
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update the hint with the combination of keys to press for the physical console
focus switch between the domains.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/drivers/char/console.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index f5ff3ebd830d631fa5d8fb5db1cf68adafcd02b4..1308236403df8a0f87aeb7e2c00a036c2d8433a7 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -518,8 +518,8 @@ int console_set_owner(domid_t domid)
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

