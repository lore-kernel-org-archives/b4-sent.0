From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:23:33 +0000
Subject: [PATCH v2 1/2] usb: typec: tcpm: Don't cut a pending state delay
 short on a re-queue
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-tcpm-attach-reboot-v2-1-b4bc6ca83490@gmail.com>
References: <20261112-tcpm-attach-reboot-v2-0-b4bc6ca83490@gmail.com>
In-Reply-To: <20261112-tcpm-attach-reboot-v2-0-b4bc6ca83490@gmail.com>
To: Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Guenter Roeck <linux@roeck-us.net>, Heiko Stuebner <heiko@sntech.de>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Arun Iyengar <aiyengar1990@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794471812; l=2363;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=f9cETtbmuMeuYvGKqDaJesYJ7nf3lLCpDNSETJ6OO1Q=;
 b=8LeYYkVSV9H3DvqyT645JP9izzuqYaWIgQ1uDLbfjiBRX8POMf/uQ34dp9ygJq6VmUe61ARjI
 B8WrR2TZDkLClcHrFvxrxbeZrGee24mdnZzilLL+3t+VslFG/oqOok8
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tcpm_state_machine_work() applies port->delayed_state as soon as it
runs, assuming it only runs when the state machine timer fired. The
work can also run because it was queued for another reason while it was
already running.

This happens at every port registration: tcpm_init() runs with the port
lock held and calls tcpm_set_state() twice with no delay (default state,
then PORT_RESET). The first call queues the work, which starts and
blocks on the lock; the second call queues it again. The first run
handles PORT_RESET and schedules PORT_RESET_WAIT_OFF after
PD_T_ERROR_RECOVERY; the second run then applies it at once. On an
Orange Pi 5 (FUSB302) the log shows the 100 ms ErrorRecovery taking
6 us:

  pending state change PORT_RESET -> PORT_RESET_WAIT_OFF @ 100 ms
  state change PORT_RESET -> PORT_RESET_WAIT_OFF [delayed 100 ms]

so the "clean slate" that tcpm_init() asks for never happens.

If the delay has not expired yet, re-arm the timer for the time left
and return, as tcpm_send_queued_message() already does.

Fixes: 3ed8e1c2ac99 ("usb: typec: tcpm: Migrate workqueue to RT priority for processing events")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/usb/typec/tcpm/tcpm.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/drivers/usb/typec/tcpm/tcpm.c b/drivers/usb/typec/tcpm/tcpm.c
index d721baef5210..0a19b7665555 100644
--- a/drivers/usb/typec/tcpm/tcpm.c
+++ b/drivers/usb/typec/tcpm/tcpm.c
@@ -6569,6 +6569,18 @@ static void tcpm_state_machine_work(struct kthread_work *work)
 
 	/* If we were queued due to a delayed state change, update it now */
 	if (port->delayed_state) {
+		/*
+		 * The work may have been queued again for another reason
+		 * while it was running, for instance by tcpm_init() at port
+		 * registration, which sets two states in a row with the
+		 * port lock held. Do not cut a pending delay short; re-arm
+		 * the timer for the time that is left.
+		 */
+		if (ktime_after(port->delayed_runtime, ktime_get())) {
+			hrtimer_start(&port->state_machine_timer,
+				      port->delayed_runtime, HRTIMER_MODE_ABS);
+			goto done;
+		}
 		tcpm_log(port, "state change %s -> %s [delayed %ld ms]",
 			 tcpm_states[port->state],
 			 tcpm_states[port->delayed_state], port->delay_ms);

-- 
2.55.0

