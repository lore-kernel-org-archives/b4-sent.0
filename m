From: Sam Ravnborg <sam@ravnborg.org>
Date: Fri, 23 Feb 2024 20:36:50 +0100
Subject: [PATCH 4/6] usb: host: uhci-grlib.c: Fix build, add
 platform_device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240223-sam-fix-sparc32-all-builds-v1-4-5c60fd5c9250@ravnborg.org>
References: <20240223-sam-fix-sparc32-all-builds-v1-0-5c60fd5c9250@ravnborg.org>
In-Reply-To: <20240223-sam-fix-sparc32-all-builds-v1-0-5c60fd5c9250@ravnborg.org>
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 "Maciej W. Rozycki" <macro@orcam.me.uk>
Cc: sparclinux@vger.kernel.org, linux-parport@lists.infradead.org, 
 "David S. Miller" <davem@davemloft.net>, 
 Andreas Larsson <andreas@gaisler.com>, Randy Dunlap <rdunlap@infradead.org>, 
 Arnd Bergmann <arnd@arndb.de>, linux-kernel@vger.kernel.org, 
 Sam Ravnborg <sam@ravnborg.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708717023; l=843;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=sqg/lm4wXEPuq1ytjSL9tNUQrRYWPLYkbsaS7YxPZOY=;
 b=Yf6oyH4OQPmCCmYgJxW7N28fyQCoMKKSNxs0vlLUK+Lg5W2SRp3H7IsbaZO1i623Y9GP7SuTpFfy
 25H90LSdBlCgPq5t3KXirIB1wjdzTcK3MRLjedm+C9KL9F2qtvOb
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the followig build error:
uhci-grlib.c:92:29: error: invalid use of undefined type 'struct platform_device'

The fix was straightforward, and no attempt was made to understand why
the build failed.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Cc: Andreas Larsson <andreas@gaisler.com>
Cc: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
---
 drivers/usb/host/uhci-grlib.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/usb/host/uhci-grlib.c b/drivers/usb/host/uhci-grlib.c
index ac3fc5970315..cfebb833668e 100644
--- a/drivers/usb/host/uhci-grlib.c
+++ b/drivers/usb/host/uhci-grlib.c
@@ -22,6 +22,7 @@
 #include <linux/of_irq.h>
 #include <linux/of_address.h>
 #include <linux/of_platform.h>
+#include <linux/platform_device.h>
 
 static int uhci_grlib_init(struct usb_hcd *hcd)
 {

-- 
2.34.1

