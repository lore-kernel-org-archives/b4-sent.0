From: John Bauer <johnebgood@securitylive.com>
Subject: [PATCH 0/2] media: uvcvideo: UVC minimum relative pan/tilt/zoom
 speed fix
Date: Fri, 05 Apr 2024 02:06:25 -0500
Message-Id: <20240405-uvc-fix-relative-ptz-speed-v1-0-c32cdb2a899d@securitylive.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPGiD2YC/x3MQQqDMBBG4avIrDsQ7ajYq5Qugv7RAbEh0VAqu
 bvB5QePd1JEUER6VScFJI363QrqR0XjYrcZrFMxNaYRI6blI43s9McBq901gf3+5+iBidH1tRv
 sU0QGKgMfUMp7/v7kfAHS7EJsbAAAAA==
To: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linh.tp.vu@gmail.com, ribalda@chromium.org, soyer@irl.hu, 
 John Bauer <johnebgood@securitylive.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712300828; l=799;
 i=johnebgood@securitylive.com; s=20240325; h=from:subject:message-id;
 bh=vWdDvQvrENGQo9KBPUCLq8na6ixMNl29inEeYMGCOec=;
 b=MrcgdX8BLXzN1cCZJQbgDOPiYx5DkwRkQp6jOO/LD12fHWhxmBMlwFZ19UrHVUR78lMNwYgMZ
 ojDA5+mlrvLBipCuVGZaq4OLLJal72cBzXGZ1DNIZPf21YA+IlB00jQ
X-Developer-Key: i=johnebgood@securitylive.com; a=ed25519;
 pk=RN31Fmrxbidp1TwtZGNmQwTDjUWMPnewQJfA/ug2P9E=
X-Endpoint-Received: by B4 Relay for johnebgood@securitylive.com/20240325 with auth_id=143
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Thanks for the help Ricardo, still figuring out this whole workflow.

Signed-off-by: John Bauer <johnebgood@securitylive.com>
---
Changes in v2:
- Made recommended changes, moved control check to helper function and removed dead code.
- Link to v1: https://lore.kernel.org/all/20240326-uvc-relative-ptz-speed-fix-v1-1-453fd5ccfd37@securitylive.com/

---
John Bauer (2):
      media: uvcvideo: UVC minimum relative pan/tilt/zoom speed fix.
      Made recommended changes

 drivers/media/usb/uvc/uvc_ctrl.c | 38 +++++++++++++++++++++++++++++++++-----
 1 file changed, 33 insertions(+), 5 deletions(-)
---
base-commit: e8f897f4afef0031fe618a8e94127a0934896aba
change-id: 20240405-uvc-fix-relative-ptz-speed-e671f9a34449

Best regards,
-- 
John Bauer <johnebgood@securitylive.com>

