From: Fabricio Akio <fabricioakio@gmail.com>
Date: Mon, 28 Sep 2026 15:18:18 -0300
Subject: [PATCH] usb: gadget: u_serial: Dequeue the console request only
 when queued
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-u-serial-console-dequeue-v1-1-b44d68585632@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ7CIBBG4as0s3YSZNGCVzEukP7VMQ0oU4xJ0
 7tLdfkt3ltJUQRKp26lgreo5NRwPHQU7yHdwDI2kzW2N946rrwXYeaYk+YZPOJVUcGTH7wJDm6
 IPbX8WTDJ57c+X/7Wen0gLvuPtu0LxLjKyXwAAAA=
X-Change-ID: 20260928-u-serial-console-dequeue-f9790a8e87c6
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790619498; l=1876;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=fYSSKxWo4cvdv0GSj8x4J42jvlxzYa8GyKyi29GrCkU=;
 b=bsDc+1HXYM3ECxb7lUwL+CDe3HmLJcVOsd+vimHG3xgpT2UNF7fb/WVAeAgGqpYRM1JydtKYs
 WbqqLlNxybsCe2iL9BGQ5A1AmrZp+6j0B3bu+ETSpCvbd1uAlG6EEcF
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gs_console_disconnect() dequeues the console request even when it is
idle, which dwc3 reports as "request ... was not queued" on every
disconnect. Dequeue it only while req->length marks it as queued.

Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
Tested on a Motorola Moto X4 (XT1900-6, SDM630) with the sdm660-mainline
7.2.3 tree and the gadget serial console in use: "request ... was not
queued to ep3in" is logged on every system suspend without this patch,
and not over three consecutive cycles with it. The path where the
request is still queued at disconnect was not exercised. Applies
unchanged to next-20260928.
---
 drivers/usb/gadget/function/u_serial.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/usb/gadget/function/u_serial.c b/drivers/usb/gadget/function/u_serial.c
index cdd1dfc666c4..53a56ddec08a 100644
--- a/drivers/usb/gadget/function/u_serial.c
+++ b/drivers/usb/gadget/function/u_serial.c
@@ -1055,6 +1055,7 @@ static void gs_console_disconnect(struct gs_port *port)
 	struct gs_console *cons = port->console;
 	struct usb_request *req;
 	struct usb_ep *ep;
+	bool was_queued;
 
 	if (!cons)
 		return;
@@ -1063,6 +1064,8 @@ static void gs_console_disconnect(struct gs_port *port)
 
 	req = cons->req;
 	ep = cons->console.data;
+	/* A non-zero length marks the request as queued. */
+	was_queued = req && req->length;
 	cons->req = NULL;
 
 	spin_unlock(&cons->lock);
@@ -1070,7 +1073,8 @@ static void gs_console_disconnect(struct gs_port *port)
 	if (!req)
 		return;
 
-	usb_ep_dequeue(ep, req);
+	if (was_queued)
+		usb_ep_dequeue(ep, req);
 	gs_free_req(ep, req);
 }
 

---
base-commit: 6375e61c01e93e35ee7acd336a689ac1fae4b509
change-id: 20260928-u-serial-console-dequeue-f9790a8e87c6

Best regards,
--  
Fabricio Akio <fabricioakio@gmail.com>

