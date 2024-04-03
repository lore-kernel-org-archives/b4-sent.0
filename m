From: John Bauer <johnebgood@securitylive.com>
Subject: [PATCH 0/3] media: uvcvideo: UVC minimum relative pan/tilt/zoom
 speed fix
Date: Wed, 03 Apr 2024 14:58:06 -0500
Message-Id: <20240403-uvc-fix-relative-ptz-speed-v1-0-624c9267f745@securitylive.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAM60DWYC/x3MQQqDMBBG4avIrB1IdaytVxEXIf5tB8SGRIMo3
 t3g8oPHOygiKCJ1xUEBSaP+54xHWZD72fkL1jGbKlOJEVPzmhx/dOOAyS6awH7ZOXpgZLEveTu
 xzdO1lAc+IJf3vB/O8wJibrxTbAAAAA==
To: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linh.tp.vu@gmail.com, ribalda@chromium.org, soyer@irl.hu, 
 John Bauer <johnebgood@securitylive.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712174305; l=598;
 i=johnebgood@securitylive.com; s=20240325; h=from:subject:message-id;
 bh=IqIPQIciSC+G8wbu2TOoXnNswwUlzqvDJu3guik3ipY=;
 b=YqSH99VMGYHqSaakMU0dMXr+sPWcobjWxzwD7W7pwM7ZSnRVX7rZ9y0gZPiPZzDPaEWb4Jlyz
 upcBbjTBMRDAsPhUQ7WETDyM75pN50qx1URw8zh92VxqbXn6aJVqvNQ
X-Developer-Key: i=johnebgood@securitylive.com; a=ed25519;
 pk=RN31Fmrxbidp1TwtZGNmQwTDjUWMPnewQJfA/ug2P9E=
X-Endpoint-Received: by B4 Relay for johnebgood@securitylive.com/20240325 with auth_id=143
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: John Bauer <johnebgood@securitylive.com>
---
John Bauer (3):
      media: uvcvideo: UVC minimum relative pan/tilt/zoom speed fix
      media: uvcvideo: UVC minimum relative pan/tilt/zoom speed fix
      media: uvcvideo: Moved control checks to helper function

 drivers/media/usb/uvc/uvc_ctrl.c | 38 +++++++++++++++++++++++++++++++++-----
 1 file changed, 33 insertions(+), 5 deletions(-)
---
base-commit: e8f897f4afef0031fe618a8e94127a0934896aba
change-id: 20240403-uvc-fix-relative-ptz-speed-4a849c4a56c7

Best regards,
-- 
John Bauer <johnebgood@securitylive.com>

