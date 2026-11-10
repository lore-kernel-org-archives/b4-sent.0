From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Subject: [PATCH 0/2] can: esd_usb: validate data received from the device
Date: Tue, 10 Nov 2026 03:56:27 +0000
Message-Id: <20261110-esd-usb-validate-v1-0-7ee499b4926d@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOuV8moC/x3MMQqAMAxA0atIZgNNqYJeRRxaGzUgKo2KIN7d4
 viG/x9QTsIKbfFA4ktUtjWDygKG2a8To8RssMbWRGSQNeKpAS+/SPQHIzlbu9AYrkKAnO2JR7n
 /Zde/7wfkG2JqYgAAAA==
To: mkl@pengutronix.de, mailhol@kernel.org, frank.jungclaus@esd.eu, 
 socketcan@esd.eu, joasantonio108@gmail.com
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794282987; l=1242;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=NrnaLsUdLYntN7kCE3mY47RXA863esuDVw8vT5S2pSI=;
 b=l5YWgTSBNmD5y5+OG7ciWxSr/DGlFJJO4JiGeGn0JyeVpi1AhNsSvNO57ZSpK5QajBm2IWBRf
 fIdDy92OrWsABLFuxxVK9rcsj5bax3v4kHfwn0WXsqEnCfP/smls3Go
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two fixes for values that esd_usb takes from the USB device without
checking them.

Patch 1 limits the number of nets reported in the version reply to
ESD_USB_MAX_NETS.  Marc Kleine-Budde asked for this clamp during the
review of the esd_usb cleanup series in August 2025; as far as I can
tell it never landed.

Patch 2 validates the message length in the rx path, so that a zero
length cannot stall the URB completion handler and a message is not
handled before checking that it fits in the received data.

These issues were found with the help of an LLM-based code review tool
(Claude).  I checked the code paths by hand against v7.4-rc3 and
reviewed the fixes myself.  They are build-tested only (W=1, arm64); I
do not have the hardware to test them at runtime.

---
Joas Antonio dos Santos (2):
      can: esd_usb: limit the number of nets reported by the device
      can: esd_usb: validate the message length in the rx path

 drivers/net/can/usb/esd_usb.c | 16 +++++++++-------
 1 file changed, 9 insertions(+), 7 deletions(-)
---
base-commit: b3dfbde62cf1981c4638939c159dfd087b7a72e9
change-id: 20261110-esd-usb-validate-14264b90e5bb

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

