From: =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>
Date: Tue, 03 Nov 2026 13:30:30 +0100
Subject: [PATCH v8 14/14] can: peak_usb: don't send uninitialized heap
 bytes in restart commands
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261103-canfd_check_channel_idx-v8-14-4e8b2c0a8806@peak-system.fr>
References: <20261103-canfd_check_channel_idx-v8-0-4e8b2c0a8806@peak-system.fr>
In-Reply-To: <20261103-canfd_check_channel_idx-v8-0-4e8b2c0a8806@peak-system.fr>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Wolfgang Grandegger <wg@grandegger.com>, 
 =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>, 
 Dan Carpenter <error27@gmail.com>, Lukas Magel <lukas.magel@posteo.net>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Tristan Madani <tristmd@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793709024; l=1851;
 i=s.grosjean@peak-system.fr; s=20261020; h=from:subject:message-id;
 bh=BmOW8lChZGURgW2vetFo/+vllV7479yRxKErjv3sv+I=;
 b=eeludRq+npkmP51bhyvxC1ZW2Yx+qhLLi1Nl8a4ioUq8yG9gi4yKk2Y9p6jKHnJJvpKcFX87j
 lIBR9nzV9d5Aty5Kbtzpv+VNDBrzjuGXvGwI2OO9Tu2otTE1GJ6K24Q
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
Assisted-by: LLM
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

