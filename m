From: Massimo Toscanelli <massimo.toscanelli@leica-geosystems.com>
Date: Fri, 23 Oct 2026 12:15:27 +0000
Subject: [PATCH 1/2] usb: gadget: f_ncm: do not notify from ncm_set_alt()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-ncm-ecm-lpm-v1-1-d01e81fbf460@leica-geosystems.com>
References: <20261023-ncm-ecm-lpm-v1-0-d01e81fbf460@leica-geosystems.com>
In-Reply-To: <20261023-ncm-ecm-lpm-v1-0-d01e81fbf460@leica-geosystems.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Neill Kapron <nkapron@google.com>, Kuen-Han Tsai <khtsai@google.com>, 
 linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Massimo Toscanelli <massimo.toscanelli@leica-geosystems.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1875;
 i=massimo.toscanelli@leica-geosystems.com; h=from:subject:message-id;
 bh=hQVH6VWyCLNHwuW5Htd2QhnoAZtXU6Oc3of/HZbqcLo=;
 b=owGbwMvMwCVmIB2leGXyl1LG02pJDFm3/f/zu3VdWDrD6jX/nPVeKoGmfmu77WfFNXW2hllnH
 ss5wNjbUcrCIMbFICumyHJtS/j3CNvcsB1ZXatg5rAygQxh4OIUgInoL2JkeM7+4frpyfveO+xN
 r7h7tWRid2B9xOGHrD1boyYIrNhqwMrwP31+d7vP86AJ8unNsrfP7P9Y2V62+bGdqmvRNyWuE6s
 6mAA=
X-Developer-Key: i=massimo.toscanelli@leica-geosystems.com; a=openpgp;
 fpr=D6B457F7583D6D56B86A8AAA301B5A21D493F475
X-Endpoint-Received: by B4 Relay for massimo.toscanelli@leica-geosystems.com/default with auth_id=1289
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ncm_set_alt() calls ncm_notify() for both altsettings of the data
interface. So a notification is already queued at SET_CONFIGURATION,
when altsetting 0 is selected, and it waits until the host reads the
interrupt endpoint.

The USB 2.0 LPM ECN (section 2.2.2) lets a device answer NYET to an LPM
request when it has data pending for the host, and DWC3 does so. So
when the host loads no class driver, like the USB-IF test tool, the
device never enters L1 and the LPM L1 test fails.

The CDC NCM spec (version 1.1, section 9.2) [1] asks for the
notifications only when the host selects altsetting 1. There the call
is not needed: gether_connect() already calls ncm_open() or
ncm_close(), and both notify. The extra call only restarts the
sequence while the first notification is in flight, so the host gets
two connection notifications before the speed one.

The old ether.c also notified only for altsetting 1, until commit
da741b8c56d6 ("usb ethernet gadget: split CDC Ethernet function")
moved the call out of that branch in f_ecm. f_ncm copied that
pattern.

Remove the call.

Fixes: 9f6ce4240a2b ("usb: gadget: f_ncm.c added")
Link: https://www.usb.org/sites/default/files/NCM11.pdf # [1]
Signed-off-by: Massimo Toscanelli <massimo.toscanelli@leica-geosystems.com>
---
 drivers/usb/gadget/function/f_ncm.c | 4 ----
 1 file changed, 4 deletions(-)

diff --git a/drivers/usb/gadget/function/f_ncm.c b/drivers/usb/gadget/function/f_ncm.c
index 500c9c19c78..0c7ec74d390 100644
--- a/drivers/usb/gadget/function/f_ncm.c
+++ b/drivers/usb/gadget/function/f_ncm.c
@@ -921,10 +921,6 @@ static int ncm_set_alt(struct usb_function *f, unsigned intf, unsigned alt)
 				return PTR_ERR(net);
 			ncm->netdev = net;
 		}
-
-		spin_lock(&ncm->lock);
-		ncm_notify(ncm);
-		spin_unlock(&ncm->lock);
 	} else
 		goto fail;
 

-- 
2.43.0

