From: =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>
Date: Thu, 26 Nov 2026 10:01:15 +0100
Subject: [PATCH v9 14/14] can: peak_usb: don't send uninitialized heap
 bytes in restart commands
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261126-canfd_check_channel_idx-v9-14-abe0099b4585@peak-system.fr>
References: <20261126-canfd_check_channel_idx-v9-0-abe0099b4585@peak-system.fr>
In-Reply-To: <20261126-canfd_check_channel_idx-v9-0-abe0099b4585@peak-system.fr>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Wolfgang Grandegger <wg@grandegger.com>, 
 =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>, 
 Dan Carpenter <error27@gmail.com>, Lukas Magel <lukas.magel@posteo.net>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Tristan Madani <tristmd@gmail.com>, 
 Joas Antonio dos Santos <joasantonio108@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795683678; l=1833;
 i=s.grosjean@peak-system.fr; s=20261020; h=from:subject:message-id;
 bh=QXT/myCDgJ3otLPXVyU9P9OwS7Dydow3hlp0UZ9UAWc=;
 b=ZrLWYIdrwODw7nIJisgT/tWxly52e8XlAajpO7d/mC1R4en39Z6cVT1KgX3EOJSpySbwBI47y
 Bg9LYp3tt0SDD1xgIsukeOGLzC1ey7NQcGdaA5B8pHYapXusMwxhEmW
X-Developer-Key: i=s.grosjean@peak-system.fr; a=ed25519;
 pk=bP7QV2zvvAKAfConZlUOGKGEcXL64SNUpVUm++Ai+/c=
X-Endpoint-Received: by B4 Relay for s.grosjean@peak-system.fr/20261020 with auth_id=1250
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

peak_usb_restart() allocates the buffer of the asynchronous restart
command with kmalloc(), and lets the dev_restart_async() callback of
the adapter build the command in it. None of these callbacks fills the
whole part of the buffer that it sends to the device:

- pcan_usb_restart_async() sets 3 of the PCAN_USB_CMD_LEN (16) bytes
  that it sends;
- pcan_usb_pro_restart_async() builds an 8-byte message, but sends the
  whole PCAN_USB_MAX_CMD_LEN (32) bytes buffer;
- pcan_usb_fd_build_restart_cmd() leaves the unused field of
  struct pucan_wr_err_cnt and the args of the final struct
  pucan_command unset.

Uninitialized heap bytes are thus sent to the device each time a
channel is restarted after bus off.

Allocate the buffer with kzalloc(), so that the unset bytes are zero,
as for the other command buffers of the driver.

Found while checking the other adapters for the uninitialized command
bytes reported by Sashiko AI review.

Fixes: bb4785551f64 ("can: usb: PEAK-System Technik USB adapters driver core")
Cc: stable@vger.kernel.org
Signed-off-by: Stéphane Grosjean <s.grosjean@peak-system.fr>
---
 drivers/net/can/usb/peak_usb/pcan_usb_core.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/can/usb/peak_usb/pcan_usb_core.c b/drivers/net/can/usb/peak_usb/pcan_usb_core.c
index 1d306160fa35..95c1454b4116 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb_core.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb_core.c
@@ -702,7 +702,7 @@ static int peak_usb_restart(struct peak_usb_device *dev)
 		return -ENOMEM;
 
 	/* also allocate enough space for the commands to send */
-	buf = kmalloc(PCAN_USB_MAX_CMD_LEN, GFP_ATOMIC);
+	buf = kzalloc(PCAN_USB_MAX_CMD_LEN, GFP_ATOMIC);
 	if (!buf) {
 		usb_free_urb(urb);
 		return -ENOMEM;

-- 
2.53.0

