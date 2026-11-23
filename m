From: Fabricio Akio <fabricioakio@gmail.com>
Date: Sun, 22 Nov 2026 22:48:35 -0300
Subject: [PATCH v2 2/2] usb: gadget: u_serial: Free the console request
 only once it is back
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-u-serial-console-dequeue-v2-2-820f355827e6@gmail.com>
References: <20261122-u-serial-console-dequeue-v2-0-820f355827e6@gmail.com>
In-Reply-To: <20261122-u-serial-console-dequeue-v2-0-820f355827e6@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Neill Kapron <nkapron@google.com>
Cc: Krystian Kaniewski <krystianmkaniewski@gmail.com>, 
 Brian Ellis <brianellis@gotenna.com>, Ai Chao <aichao@kylinos.cn>, 
 =?utf-8?q?Micha=C5=82_Miros=C5=82aw?= <mirq-linux@rere.qmqm.pl>, 
 Prashanth K <prashanth.k@oss.qualcomm.com>, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795398515; l=8468;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=69hjgYfN3tBwZsKHKKPp7YLsWXixOc43fSHobPp3dys=;
 b=9TB1ZrOHQI41zFbMz7PD2SiwXmeqNvxMw6zSZ1UBW7lYmxJ7dVIcUKmtjlqgylMImlM3Ox9qT
 eUooItT6HNPAvldYUe0koUjUlUn4ZubWzQriaIJbMtXGXS0pbG/QIt6
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gs_console_disconnect() frees the console request right after
usb_ep_dequeue(), which is asynchronous: the controller, dwc3 here,
gives a queued request back from usb_ep_disable() in
gserial_disconnect(), after it was freed. __gs_console_push() also
queues the request with cons->lock dropped, so a disconnect in that
window frees a request still being queued. An idle request is dequeued
too, which dwc3 reports as "request ... was not queued" at each
disconnect.

Track whether the request is out in a console flag, cons->busy, under
cons->lock, instead of in req->length, which the driver may not examine
while the request is queued. On disconnect, the console gives the
request up and frees it only if idle. A busy request, now orphaned, is
freed when it comes back: by its completion, or by gs_console_work()
when usb_ep_queue() fails. Until then it holds a reference on the
console, so that the console outlives it after gs_console_exit().
__gs_console_push() is folded into gs_console_work(), its only caller,
so that a failed queue takes cons->lock only for as long as it needs.

The disconnect no longer dequeues: in gserial_disconnect(),
usb_ep_disable() follows and gives the request back. gs_console_exit(),
where nothing follows, drops the unsent output and dequeues a request
still queued itself.

Fixes: fe1ea63ad806 ("usb: gadget: u_serial: reimplement console support")
Fixes: e5990469943c ("usb: gadget: u_serial: Avoid spinlock recursion in __gs_console_push")
Cc: stable@vger.kernel.org
Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
 drivers/usb/gadget/function/u_serial.c | 130 +++++++++++++++++++++++++--------
 1 file changed, 101 insertions(+), 29 deletions(-)

diff --git a/drivers/usb/gadget/function/u_serial.c b/drivers/usb/gadget/function/u_serial.c
index 1f0110ea7f6a..fd511327c083 100644
--- a/drivers/usb/gadget/function/u_serial.c
+++ b/drivers/usb/gadget/function/u_serial.c
@@ -29,6 +29,7 @@
 #include <linux/kthread.h>
 #include <linux/workqueue.h>
 #include <linux/kfifo.h>
+#include <linux/kref.h>
 #include <linux/serial.h>
 
 #include "u_serial.h"
@@ -111,8 +112,10 @@ struct gs_console {
 	struct work_struct	work;
 	spinlock_t		lock;
 	struct usb_request	*req;
+	bool			busy;
 	struct kfifo		buf;
 	size_t			missed;
+	struct kref		kref;
 };
 
 /*
@@ -998,46 +1001,81 @@ static struct tty_driver *gs_tty_driver;
 
 #ifdef CONFIG_U_SERIAL_CONSOLE
 
+static void gs_console_release(struct kref *kref)
+{
+	struct gs_console *cons = container_of(kref, struct gs_console, kref);
+
+	kfifo_free(&cons->buf);
+	kfree(cons);
+}
+
+/*
+ * Free a request that gs_console_disconnect() orphaned while it was busy,
+ * and drop the reference it took for it. Called without cons->lock.
+ */
+static void gs_console_free_orphaned(struct gs_console *cons,
+				     struct usb_ep *ep, struct usb_request *req)
+{
+	gs_free_req(ep, req);
+	kref_put(&cons->kref, gs_console_release);
+}
+
 static void gs_console_complete_out(struct usb_ep *ep, struct usb_request *req)
 {
 	struct gs_console *cons = req->context;
+	bool push = true;
+	bool orphaned;
 
 	switch (req->status) {
 	default:
 		pr_warn("%s: unexpected %s status %d\n",
 			__func__, ep->name, req->status);
-		fallthrough;
+		break;
 	case 0:
 		/* normal completion */
-		spin_lock(&cons->lock);
-		req->length = 0;
-		schedule_work(&cons->work);
-		spin_unlock(&cons->lock);
 		break;
 	case -ECONNRESET:
 	case -ESHUTDOWN:
 		/* disconnect */
 		pr_vdebug("%s: %s shutdown\n", __func__, ep->name);
+		push = false;
 		break;
 	}
+
+	spin_lock(&cons->lock);
+	orphaned = req != cons->req;
+	if (!orphaned) {
+		cons->busy = false;
+		if (push)
+			schedule_work(&cons->work);
+	}
+	spin_unlock(&cons->lock);
+
+	if (orphaned)
+		gs_console_free_orphaned(cons, ep, req);
 }
 
-static void __gs_console_push(struct gs_console *cons)
+static void gs_console_work(struct work_struct *work)
 {
-	struct usb_request *req = cons->req;
+	struct gs_console *cons = container_of(work, struct gs_console, work);
+	struct usb_request *req;
 	struct usb_ep *ep;
+	bool orphaned;
 	size_t size;
 
-	if (!req)
-		return;	/* disconnected */
+	spin_lock_irq(&cons->lock);
 
-	if (req->length)
-		return;	/* busy */
+	req = cons->req;
+	if (!req)
+		goto unlock;	/* disconnected */
+
+	if (cons->busy)
+		goto unlock;	/* busy */
 
 	ep = cons->console.data;
 	size = kfifo_out(&cons->buf, req->buf, ep->maxpacket);
 	if (!size)
-		return;
+		goto unlock;
 
 	if (cons->missed && ep->maxpacket >= 64) {
 		char buf[64];
@@ -1049,21 +1087,24 @@ static void __gs_console_push(struct gs_console *cons)
 	}
 
 	req->length = size;
+	cons->busy = true;
 
 	spin_unlock_irq(&cons->lock);
-	if (usb_ep_queue(ep, req, GFP_ATOMIC))
-		req->length = 0;
-	spin_lock_irq(&cons->lock);
-}
 
-static void gs_console_work(struct work_struct *work)
-{
-	struct gs_console *cons = container_of(work, struct gs_console, work);
+	if (!usb_ep_queue(ep, req, GFP_ATOMIC))
+		return;
 
 	spin_lock_irq(&cons->lock);
+	orphaned = req != cons->req;
+	if (!orphaned)
+		cons->busy = false;
+	spin_unlock_irq(&cons->lock);
 
-	__gs_console_push(cons);
+	if (orphaned)
+		gs_console_free_orphaned(cons, ep, req);
+	return;
 
+unlock:
 	spin_unlock_irq(&cons->lock);
 }
 
@@ -1080,7 +1121,7 @@ static void gs_console_write(struct console *co,
 	if (n < count)
 		cons->missed += count - n;
 
-	if (cons->req && !cons->req->length)
+	if (cons->req && !cons->busy)
 		schedule_work(&cons->work);
 
 	spin_unlock_irqrestore(&cons->lock, flags);
@@ -1107,7 +1148,6 @@ static int gs_console_connect(struct gs_port *port)
 		return -ENOMEM;
 	req->complete = gs_console_complete_out;
 	req->context = cons;
-	req->length = 0;
 
 	spin_lock(&cons->lock);
 	cons->req = req;
@@ -1126,6 +1166,7 @@ static void gs_console_disconnect(struct gs_port *port)
 	struct gs_console *cons = port->console;
 	struct usb_request *req;
 	struct usb_ep *ep;
+	bool busy;
 
 	if (!cons)
 		return;
@@ -1134,15 +1175,22 @@ static void gs_console_disconnect(struct gs_port *port)
 
 	req = cons->req;
 	ep = cons->console.data;
+	busy = cons->busy;
 	cons->req = NULL;
+	cons->busy = false;
+	/*
+	 * A busy request is queued, or being queued by gs_console_work(). The
+	 * console gives it up here, and the orphaned request is freed when it
+	 * comes back: by its completion, or by gs_console_work() if
+	 * usb_ep_queue() fails. It holds a reference on the console until then.
+	 */
+	if (busy)
+		kref_get(&cons->kref);
 
 	spin_unlock(&cons->lock);
 
-	if (!req)
-		return;
-
-	usb_ep_dequeue(ep, req);
-	gs_free_req(ep, req);
+	if (req && !busy)
+		gs_free_req(ep, req);
 }
 
 static int gs_console_init(struct gs_port *port)
@@ -1165,6 +1213,7 @@ static int gs_console_init(struct gs_port *port)
 
 	INIT_WORK(&cons->work, gs_console_work);
 	spin_lock_init(&cons->lock);
+	kref_init(&cons->kref);
 
 	err = kfifo_alloc(&cons->buf, GS_CONSOLE_BUF_SIZE, GFP_KERNEL);
 	if (err) {
@@ -1187,21 +1236,44 @@ static int gs_console_init(struct gs_port *port)
 static void gs_console_exit(struct gs_port *port)
 {
 	struct gs_console *cons = port->console;
+	struct usb_request *req;
+	struct usb_ep *ep;
 
 	if (!cons)
 		return;
 
 	unregister_console(&cons->console);
 
+	/*
+	 * Drop the unsent output and wait for a push in progress, so that the
+	 * request is busy below only if it is queued.
+	 */
+	spin_lock_irq(&cons->lock);
+	kfifo_reset(&cons->buf);
+	spin_unlock_irq(&cons->lock);
+	cancel_work_sync(&cons->work);
+
 	spin_lock_irq(&port->port_lock);
+
+	/*
+	 * Nothing gives a queued request back here, so cancel it. Holding
+	 * port_lock keeps a disconnect from orphaning it, so it cannot be
+	 * freed under usb_ep_dequeue().
+	 */
+	spin_lock(&cons->lock);
+	req = cons->busy ? cons->req : NULL;
+	ep = cons->console.data;
+	spin_unlock(&cons->lock);
+	if (req)
+		usb_ep_dequeue(ep, req);
+
 	if (cons->req)
 		gs_console_disconnect(port);
 	port->console = NULL;
 	spin_unlock_irq(&port->port_lock);
 
 	cancel_work_sync(&cons->work);
-	kfifo_free(&cons->buf);
-	kfree(cons);
+	kref_put(&cons->kref, gs_console_release);
 }
 
 ssize_t gserial_set_console(unsigned char port_num, const char *page, size_t count)

-- 
2.56.1

