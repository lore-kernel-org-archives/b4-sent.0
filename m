From: John Bauer <johnebgood@securitylive.com>
Subject: [PATCH 0/2] media: uvcvideo: UVC minimum relative pan/tilt/zoom
 speed fix
Date: Thu, 28 Mar 2024 18:18:05 -0500
Message-Id: <20240328-uvc-fix-relative-ptz-speed-v1-0-17373eb8b2be@securitylive.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAK36BWYC/x3MQQqDMBBG4avIrDsQk6LVqxQXQ/yrA2JDokEU7
 97Q5QePd1FCVCTqq4sisib9rgX1oyI/yzqBdSwma+zTOPviPXv+6MERi2yawWE7OQVg5K6Vzrr
 GGZGGyiBElPI/fw/3/QPi6nT/bAAAAA==
To: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linh.tp.vu@gmail.com, ribalda@chromium.org, soyer@irl.hu, 
 John Bauer <johnebgood@securitylive.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711667891; l=534;
 i=johnebgood@securitylive.com; s=20240325; h=from:subject:message-id;
 bh=f3ER3lZAYli1BTrR2dAmxpU9ysqv5W9r0F8k8nlkK5Q=;
 b=v11UhZCjK2Fzq3kTdttmdGe03+xpcVvouWoO7MkzV1sdmnOvb4rhi0uVTu+uOyWqKH4wyymSd
 4MCUjKTBH65C/s/paT5Hg34iQn5AHtreqgE7wDUze6dMqPYAUzGy/DO
X-Developer-Key: i=johnebgood@securitylive.com; a=ed25519;
 pk=RN31Fmrxbidp1TwtZGNmQwTDjUWMPnewQJfA/ug2P9E=
X-Endpoint-Received: by B4 Relay for johnebgood@securitylive.com/20240325 with auth_id=143
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: John Bauer <johnebgood@securitylive.com>
---
John Bauer (2):
      media: uvcvideo: UVC minimum relative pan/tilt/zoom speed fix
      media: uvcvideo: UVC minimum relative pan/tilt/zoom speed fix

 drivers/media/usb/uvc/uvc_ctrl.c | 38 ++++++++++++++++++++++++++++++++++----
 1 file changed, 34 insertions(+), 4 deletions(-)
---
base-commit: 23956900041d968f9ad0f30db6dede4daccd7aa9
change-id: 20240328-uvc-fix-relative-ptz-speed-97a923630aa6

Best regards,
-- 
John Bauer <johnebgood@securitylive.com>

