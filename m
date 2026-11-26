From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 09:19:21 +0000
Subject: [PATCH v3 1/2] usb: typec: tcpm: Don't cut a pending state delay
 short on a re-queue
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-tcpm-attach-reboot-v3-1-1c97dfa5024a@gmail.com>
References: <20261126-tcpm-attach-reboot-v3-0-1c97dfa5024a@gmail.com>
In-Reply-To: <20261126-tcpm-attach-reboot-v3-0-1c97dfa5024a@gmail.com>
To: Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Guenter Roeck <linux@roeck-us.net>, Heiko Stuebner <heiko@sntech.de>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Arun Iyengar <aiyengar1990@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795684760; l=1142;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=uRI6n9WLfQFTf9uBDH1fL/OJxtYBcAOG2OjFxQdaQts=;
 b=NkH4qJkT+AMAaxrPOBGiovFNH7jct+8g2JzBVxp56LysuMRjGVe6wqtQDrdB3gYHC+HthIXhX
 fIfiEMAHuY+BzLLqF9C9SEpY6HUIdHNf9pgWvc1do5Wt+2S7rO4QaAg
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A re-queue while the work runs applies a pending delayed state at once
(the 100 ms ErrorRecovery took 6 us). Re-arm the timer for the time left.

Fixes: 3ed8e1c2ac99 ("usb: typec: tcpm: Migrate workqueue to RT priority for processing events")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/usb/typec/tcpm/tcpm.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/usb/typec/tcpm/tcpm.c b/drivers/usb/typec/tcpm/tcpm.c
index 51e5c72799f2..565073b4ca93 100644
--- a/drivers/usb/typec/tcpm/tcpm.c
+++ b/drivers/usb/typec/tcpm/tcpm.c
@@ -6572,6 +6572,11 @@ static void tcpm_state_machine_work(struct kthread_work *work)
 
 	/* If we were queued due to a delayed state change, update it now */
 	if (port->delayed_state) {
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

