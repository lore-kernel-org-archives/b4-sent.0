From: Felix Huang <akafelixab@gmail.com>
Date: Fri, 27 Nov 2026 20:58:51 -0500
Subject: [PATCH] usb: phy: fsl-usb: use NULL instead of plain integer 0
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-fsl-usb-null-pointer-v1-1-1d10607f9f39@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrB1I0qKlVykuHDvRkRAlY0pBv
 HtTXb7F/zsoJ2GFZ7VD4o+oLLHA1hUMUx9HRnkXgzOusda16DVgVsKYQ8B1kbhxQk9k7w/T9Dc
 yUNI1sZfvuX11lzXTzMP2f8Fx/AAoLyv+eAAAAA==
X-Change-ID: 20261127-fsl-usb-null-pointer-fbb14806a3b0
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 Felix Huang <akafelixab@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795831131; l=1057;
 i=akafelixab@gmail.com; s=20261128; h=from:subject:message-id;
 bh=F90+UAhf/qFwjlJxTZbrRIrGBJm8qNw2VciNz2TFR6I=;
 b=dq/U0Wmrsv/58/mA0pLYFqm6ys7ncWjOkCfRqzTVV8Txb6bluBYA5ekaFRD5GiaKD6V4ywLdq
 ANp9UlLeWzUAFIiUhqdxB7L2tlZm+sX3zVh3S1nB6g6UhG0Fk3jZQzE
X-Developer-Key: i=akafelixab@gmail.com; a=ed25519;
 pk=Axl3BM1UWa+m0/AWcEhRIdIk/WY9FnY4wZkyQn64uVY=
X-Endpoint-Received: by B4 Relay for akafelixab@gmail.com/20261128 with auth_id=1670
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the following sparse warning in fsl_otg_set_peripheral():

  drivers/usb/phy/phy-fsl-usb.c:618:31: warning: Using plain integer as NULL pointer

Assign NULL instead of 0 to the struct usb_gadget pointer otg->gadget.

Signed-off-by: Felix Huang <akafelixab@gmail.com>
---
 drivers/usb/phy/phy-fsl-usb.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/usb/phy/phy-fsl-usb.c b/drivers/usb/phy/phy-fsl-usb.c
index 1986f7e9d..110b277aa 100644
--- a/drivers/usb/phy/phy-fsl-usb.c
+++ b/drivers/usb/phy/phy-fsl-usb.c
@@ -615,7 +615,7 @@ static int fsl_otg_set_peripheral(struct usb_otg *otg,
 		if (!otg->default_a)
 			otg->gadget->ops->vbus_draw(otg->gadget, 0);
 		usb_gadget_vbus_disconnect(otg->gadget);
-		otg->gadget = 0;
+		otg->gadget = NULL;
 		otg_dev->fsm.b_bus_req = 0;
 		otg_statemachine(&otg_dev->fsm);
 		return 0;

---
base-commit: f4585067150b85e33f60876149a6e742928da75e
change-id: 20261127-fsl-usb-null-pointer-fbb14806a3b0

Best regards,
--  
Felix Huang <akafelixab@gmail.com>

