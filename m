From: Joseph Breihan <linux@josephbreihan.com>
Date: Sun, 05 Jul 2026 01:10:43 -0400
Subject: [PATCH] media: au0828: add support for Monoprice 106456 USB
 ATSC/QAM tuner
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260705-au0828-monoprice-v1-1-4b7bbfc2c7fe@josephbreihan.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ7CIBBA0auQWZeEYpHaqxgXOB10mggEbNOk4
 e6iLt/i/wMKZaYCkzgg08aFY2joOwH4dOFBkudm0EqflVVGulWNepSvGGLKjCRnMm7A0wXt4KF
 lKZPn/be83v4u630hfH8/UOsHTHICeXQAAAA=
X-Change-ID: 20260705-au0828-monoprice-de5a4c39c74f
To: Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Breihan <linux@josephbreihan.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783228260; l=3949;
 i=linux@josephbreihan.com; s=20260705; h=from:subject:message-id;
 bh=qzsjNKPfiuPaYgKyTwT9vKQKC+FWy25TYC/pfFwf62M=;
 b=tkJMuRdeJ0JBMz0r30KXKdMAMPRU4ZKAxSz0UXkjv8/AO6lBX8FGag+r7Q5gzeJfrqkBzRaEc
 WATF4fFYvYYBhzkyna+vQ3hLmFjIAqePTlcW/JnikLDvDDuw1jaEiTn
X-Developer-Key: i=linux@josephbreihan.com; a=ed25519;
 pk=EHopwlApUikmTLRFGCwX5XX8xai+qKAP4wXj4X4xXKM=
X-Endpoint-Received: by B4 Relay for linux@josephbreihan.com/20260705 with auth_id=851
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Monoprice 106456 (board rev TV22AD-A, also sold as the AnyTV
AUTV002) is a USB ATSC/QAM tuner that enumerates as 05e1:0400 and
reports itself as a "Syntek Semiconductor USB 2.0 Video Capture
Controller". The hardware is an Auvitek AU0828A bridge with an AU8522
demodulator and an NXP TDA18271HDC2 tuner at I2C address 0x60 -- the
same demod/tuner combination as the existing Hauppauge Woodbury board.

Adds board profile and the USB ID so the device binds. The digital
frontend is electrically identical to the Woodbury, so share that
board's au8522/tda18271 configuration and attach path rather than
duplicating it. Tested with over-the-air 8VSB ATSC: it locks and
streams a live 720p transport stream.

Some 05e1:0400 units reportedly ship a Microtune MT2131 tuner with an
AU8502 demodulator instead. This patch does not handle that variant,
but it can't regress it either: 05e1:0400 matches no driver today, and
on the MT2131 units tda18271_attach() just fails, so no frontend is
registered.

Signed-off-by: Joseph Breihan <linux@josephbreihan.com>
---
 drivers/media/usb/au0828/au0828-cards.c | 14 ++++++++++++++
 drivers/media/usb/au0828/au0828-cards.h |  1 +
 drivers/media/usb/au0828/au0828-dvb.c   |  1 +
 3 files changed, 16 insertions(+)

diff --git a/drivers/media/usb/au0828/au0828-cards.c b/drivers/media/usb/au0828/au0828-cards.c
index 9929ce5dcdc..8ab100db01a 100644
--- a/drivers/media/usb/au0828/au0828-cards.c
+++ b/drivers/media/usb/au0828/au0828-cards.c
@@ -124,6 +124,17 @@ struct au0828_board au0828_boards[] = {
 			},
 		},
 	},
+	[AU0828_BOARD_MONOPRICE_106456] = {
+		/*
+		 * Monoprice 106456 USB ATSC/QAM tuner (board rev TV22AD-A),
+		 * a.k.a. AnyTV AUTV002, USB ID 05e1:0400. Same AU8522 demod +
+		 * NXP TDA18271HDC2 tuner @ 0x60 as the Hauppauge Woodbury.
+		 */
+		.name	= "Monoprice 106456 USB ATSC/QAM (TV22AD-A)",
+		.tuner_type = TUNER_NXP_TDA18271,
+		.tuner_addr = 0x60,
+		.i2c_clk_divider = AU0828_I2C_CLK_250KHZ,
+	},
 	[AU0828_BOARD_HAUPPAUGE_HVR1265] = {
 		.name	= "Hauppauge HVR1265",
 		.tuner_type = TUNER_XC5000,
@@ -294,6 +305,7 @@ void au0828_gpio_setup(struct au0828_dev *dev)
 	case AU0828_BOARD_HAUPPAUGE_WOODBURY:
 	case AU0828_BOARD_HAUPPAUGE_HVR1265:
 	case AU0828_BOARD_HAUPPAUGE_IMPACTVCBE:
+	case AU0828_BOARD_MONOPRICE_106456:
 		/* GPIO's
 		 * 4 - CS5340
 		 * 5 - AU8522 Demodulator
@@ -378,6 +390,8 @@ struct usb_device_id au0828_usb_id_table[] = {
 		.driver_info = AU0828_BOARD_HAUPPAUGE_HVR950Q_MXL },
 	{ USB_DEVICE(0x05e1, 0x0480),
 		.driver_info = AU0828_BOARD_HAUPPAUGE_WOODBURY },
+	{ USB_DEVICE(0x05e1, 0x0400),
+		.driver_info = AU0828_BOARD_MONOPRICE_106456 },
 	{ USB_DEVICE(0x2040, 0x8200),
 		.driver_info = AU0828_BOARD_HAUPPAUGE_WOODBURY },
 	{ USB_DEVICE(0x2040, 0x7260),
diff --git a/drivers/media/usb/au0828/au0828-cards.h b/drivers/media/usb/au0828/au0828-cards.h
index a438aeb334a..a4a283731f7 100644
--- a/drivers/media/usb/au0828/au0828-cards.h
+++ b/drivers/media/usb/au0828/au0828-cards.h
@@ -13,3 +13,4 @@
 #define AU0828_BOARD_HAUPPAUGE_WOODBURY	5
 #define AU0828_BOARD_HAUPPAUGE_IMPACTVCBE	6
 #define AU0828_BOARD_HAUPPAUGE_HVR1265		7
+#define AU0828_BOARD_MONOPRICE_106456		8
diff --git a/drivers/media/usb/au0828/au0828-dvb.c b/drivers/media/usb/au0828/au0828-dvb.c
index 31123e6f9fc..9c95b7ceaec 100644
--- a/drivers/media/usb/au0828/au0828-dvb.c
+++ b/drivers/media/usb/au0828/au0828-dvb.c
@@ -600,6 +600,7 @@ int au0828_dvb_register(struct au0828_dev *dev)
 				   &mxl5007t_hvr950q_config);
 		break;
 	case AU0828_BOARD_HAUPPAUGE_WOODBURY:
+	case AU0828_BOARD_MONOPRICE_106456:
 		dvb->frontend = dvb_attach(au8522_attach,
 				&hauppauge_woodbury_config,
 				&dev->i2c_adap);

---
base-commit: 8dac27bfa2f994ecb11f01a63641527d17d48fc1
change-id: 20260705-au0828-monoprice-de5a4c39c74f

Best regards,
--  
Joseph Breihan <linux@josephbreihan.com>

