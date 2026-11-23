From: Fabricio Akio <fabricioakio@gmail.com>
Date: Sun, 22 Nov 2026 22:48:34 -0300
Subject: [PATCH v2 1/2] usb: gadget: u_serial: Publish the console only
 under port_lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-u-serial-console-dequeue-v2-1-820f355827e6@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795398515; l=1827;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=bQFCDRqy5e6noIavX7zwxVbe546YTjkWtU7/BccXBn0=;
 b=ssdBs0Iy02dHW2KVUSBVWEgz/5+XUebgNuEDZbyhVBJiUefFtf0Ca0q7+w5UHASea6BwgTivd
 DwITeE8fg8QDKW+ep2b3EGAP+BhvIKaJrhds/GB1tzEJWgsITKq9AeP
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gserial_connect() and gserial_disconnect() find the console through
port->console under port_lock, but gs_console_init() sets it before
taking the lock, and gs_console_exit() clears it after dropping it.
A host connect while the console is being turned on through configfs
can then connect it twice, leaking the first request. While it is
being turned off, a connect can attach a request to the console being
freed and schedule its work after cancel_work_sync().

Set and clear port->console under port_lock, together with connecting
and disconnecting the console.

Fixes: d7cb8fb7aa7d ("usb: gadget: u_serial: allow more console gadget ports")
Cc: stable@vger.kernel.org
Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
 drivers/usb/gadget/function/u_serial.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/usb/gadget/function/u_serial.c b/drivers/usb/gadget/function/u_serial.c
index 0a304f508bc3..1f0110ea7f6a 100644
--- a/drivers/usb/gadget/function/u_serial.c
+++ b/drivers/usb/gadget/function/u_serial.c
@@ -1173,10 +1173,10 @@ static int gs_console_init(struct gs_port *port)
 		return err;
 	}
 
-	port->console = cons;
 	register_console(&cons->console);
 
 	spin_lock_irq(&port->port_lock);
+	port->console = cons;
 	if (port->port_usb)
 		gs_console_connect(port);
 	spin_unlock_irq(&port->port_lock);
@@ -1196,12 +1196,12 @@ static void gs_console_exit(struct gs_port *port)
 	spin_lock_irq(&port->port_lock);
 	if (cons->req)
 		gs_console_disconnect(port);
+	port->console = NULL;
 	spin_unlock_irq(&port->port_lock);
 
 	cancel_work_sync(&cons->work);
 	kfifo_free(&cons->buf);
 	kfree(cons);
-	port->console = NULL;
 }
 
 ssize_t gserial_set_console(unsigned char port_num, const char *page, size_t count)

-- 
2.56.1

