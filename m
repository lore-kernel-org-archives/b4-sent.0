From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 04:28:13 +0000
Subject: [PATCH] usb: typec: tcpm: Cancel the timers before destroying the
 worker too
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-tcpm-unregister-timers-v1-1-7230fda5612b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCQAxG4auUrA00g4rjVcRFnf6tETqWZCpC6
 d0ddfkt3lvJYQqnc7OS4aWuz1whu4bSvcsjWPtqCm04ikjgkuaJl2wY1QuMi04w5zD0coj7Uxt
 jpBrPhkHfv/Hl+rcvtwdS+d5o2z4PaLCIegAAAA==
X-Change-ID: 20261112-tcpm-unregister-timers-2fd159480999
To: Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Guenter Roeck <linux@roeck-us.net>, Xu Yang <xu.yang_2@nxp.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794457692; l=3576;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=uO7oLFJ9U2ade7oBvcd7yir9nsFmvPybpTlJOuoRoAM=;
 b=12OwEeV8fEQtCgyW1E7aRWtRJbppNwN/xgiR2qmXBfUwQldX0xlNfYjZAL3iuCnkAOaajjTJV
 gO/caxTbEwSBO/Und6USQU0+xqw8TQo1001UkPihPbgv2oWHVqWPt23
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tcpm_unregister_port() clears port->registered, destroys the kthread
worker and only then cancels the hrtimers. A timer handler running on
another CPU that has already seen port->registered set can still call
kthread_queue_work() once the worker is freed, or with port->wq
already NULL:

  CPU0                           CPU1
  tcpm_unregister_port()         state_machine_timer_handler()
                                   if (port->registered)
    port->registered = false;
    kthread_destroy_worker(port->wq);
    port->wq = NULL;
                                   kthread_queue_work(port->wq, ...);

The timers are cancelled after the worker is destroyed on purpose:
works that run while the worker is flushed can start a timer again
(see the commit in Fixes). Cancelling only before would bring that
back, so cancel them on both sides. hrtimer_cancel() waits for a
handler that is running, so after the first round no handler that
missed the cleared flag is left; the second round removes a timer that
a work started during the flush. tcpm_reset_port(), called later, only
cancels.

Fixes: ca4d8344a72b ("usb: typec: tcpm: fix tcpm unregister port but leave a pending timer")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/sashiko-outbox-206898@kernel.org/
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Sashiko found this while reviewing an unrelated tcpm patch of mine:
https://lore.kernel.org/all/sashiko-outbox-206898@kernel.org/
Its suggestion was to cancel the timers before destroying the worker
instead of after; that would undo the commit in Fixes, hence both.

Compile-tested only (arm64 W=1): the window is a few instructions in
the unbind path and I have no reproducer.

This patch was developed with Claude (Anthropic) as a coding assistant:
it wrote the change and the commit message, and I reviewed it.
---
 drivers/usb/typec/tcpm/tcpm.c | 21 ++++++++++++++++-----
 1 file changed, 16 insertions(+), 5 deletions(-)

diff --git a/drivers/usb/typec/tcpm/tcpm.c b/drivers/usb/typec/tcpm/tcpm.c
index d721baef5210..c7e0e09b1cbe 100644
--- a/drivers/usb/typec/tcpm/tcpm.c
+++ b/drivers/usb/typec/tcpm/tcpm.c
@@ -8987,18 +8987,29 @@ struct tcpm_port *tcpm_register_port(struct device *dev, struct tcpc_dev *tcpc)
 }
 EXPORT_SYMBOL_GPL(tcpm_register_port);
 
+static void tcpm_cancel_timers(struct tcpm_port *port)
+{
+	hrtimer_cancel(&port->vdm_discovery_timer);
+	hrtimer_cancel(&port->enable_frs_timer);
+	hrtimer_cancel(&port->vdm_state_machine_timer);
+	hrtimer_cancel(&port->state_machine_timer);
+}
+
 void tcpm_unregister_port(struct tcpm_port *port)
 {
 	int i;
 
 	port->registered = false;
+	/*
+	 * A timer handler that saw port->registered still set may queue
+	 * work: wait for it before the worker goes away. Works that run
+	 * while the worker is flushed may start a timer again, so cancel
+	 * the timers once more afterwards.
+	 */
+	tcpm_cancel_timers(port);
 	kthread_destroy_worker(port->wq);
 	port->wq = NULL;
-
-	hrtimer_cancel(&port->vdm_discovery_timer);
-	hrtimer_cancel(&port->enable_frs_timer);
-	hrtimer_cancel(&port->vdm_state_machine_timer);
-	hrtimer_cancel(&port->state_machine_timer);
+	tcpm_cancel_timers(port);
 
 	power_supply_put_system_batteries(port->fixed_batt, port->fixed_batt_cnt);
 	tcpm_reset_port(port);

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261112-tcpm-unregister-timers-2fd159480999

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

