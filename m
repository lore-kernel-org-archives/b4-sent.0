From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 06:20:27 +0000
Subject: [PATCH] usb: hub: yield while waiting for the port connect
 debounce
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-usb-hub-yield-v1-1-b9a88ff102d1@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrB1IQpHSqxQXJjPWKUUlY8Qiu
 btRl2/x/w7KUVjhVe0QeRWVaSywdQVh6MYPo1AxOOMaa63BpB6H5PEv/CPsn8ExETUmPKA0c+R
 etuv3bm9r8l8OyzmBnA8+FI6VcQAAAA==
X-Change-ID: 20261110-usb-hub-yield-f8c2eddd60c4
To: u-boot@lists.u-boot-project.org
Cc: Marek Vasut <marek.vasut+usb@mailbox.org>, 
 Tom Rini <trini@konsulko.com>, Arun Iyengar <aiyengar1990@gmail.com>, 
 Jerome Forissier <jerome.forissier@arm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794291627; l=3148;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=e+5J4O++x9STxA0gBZBWtuFvWcs5h8+LDLg5VyNifoM=;
 b=b1D3+Yk5EgZwCTvT6CDdP8jq4CndNcqhsBQZDoTup18EUZGFGWVDMGGUiDNsdveY6LH6YPgAm
 HXvE67venmzDEpKyhODvZoFfjG5DJLVlbTrNVQW45bUT93N91aK434p
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With CONFIG_UTHREAD, usb_init() creates one uthread per USB controller
for the bus scan, but the scans never actually overlap: the port scan
loop in usb_device_list_scan() only waits for time to pass (query_delay,
then CONFIG_USB_HUB_DEBOUNCE_TIMEOUT = 1 s for a port with nothing
connected), and for a root hub every port status request is answered
synchronously by the host controller driver, so the loop spins without
ever reaching udelay() or schedule(). The first controller's thread
therefore holds the CPU for the whole debounce, then the next one does
the same, and "usb start" costs about 1.1 s per controller.

Yield once per pass over usb_scan_list. The other controllers' threads
then configure their root hubs and add their ports to the shared list
while the first one is debouncing, and the running loop scans all of
them, so the debounce periods overlap. Without CONFIG_UTHREAD,
schedule() only runs the cyclic functions, as it already does in the
EHCI transfer wait loop.

Tested on an OrangePi Zero2 (H616) with all three EHCI and three OHCI
controllers enabled (the two extra ones go to the expansion header) and
CONFIG_UTHREAD=y, nothing plugged in: "usb start" took 7.0 s before and
1.5 s with this patch (serial console timestamps), and all six root
hubs are still found. On sandbox64 (CONFIG_UTHREAD=y), the test/py
USB tests give the same result with and without the patch (the
dm_test_usb_* tests pass, except usb_flash and usb_keyb, which fail on
main as well).

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
This came up while trying to scan the six USB controllers of an OrangePi
Zero2 in parallel with CONFIG_UTHREAD: the per-controller threads were
there, but "usb start" took as long as a serial scan.

This patch was developed with Claude (Anthropic) as a coding assistant:
it investigated the problem, wrote the code and the commit message. I
reviewed it, and it was tested on an OrangePi Zero2 (H616) and on
sandbox64 as described in the commit message.
---
 common/usb_hub.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/common/usb_hub.c b/common/usb_hub.c
index 6a4bcec00bc..31b5aa7ae04 100644
--- a/common/usb_hub.c
+++ b/common/usb_hub.c
@@ -41,6 +41,7 @@
 #include <asm/unaligned.h>
 
 #include <usb.h>
+#include <u-boot/schedule.h>
 
 #define USB_BUFSIZ	512
 
@@ -592,6 +593,17 @@ static int usb_device_list_scan(void)
 			if (ret)
 				goto out;
 		}
+
+		/*
+		 * Root hub port status requests complete synchronously, so this
+		 * loop never sleeps while it waits for the connect debounce
+		 * (query_delay + CONFIG_USB_HUB_DEBOUNCE_TIMEOUT) to expire.
+		 * Yield so that the uthreads usb_init() created for the other
+		 * controllers can configure their root hubs and add their ports
+		 * to usb_scan_list meanwhile; the debounce periods then overlap
+		 * instead of adding up per controller.
+		 */
+		schedule();
 	}
 
 out:

---
base-commit: ecdcf9e365df6249a57cd8cc946e7026804ff4ae
change-id: 20261110-usb-hub-yield-f8c2eddd60c4

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

