From: Martin Oberleiter <martin.oberleiter@netixx.it>
Date: Fri, 30 Oct 2026 07:37:24 +0100
Subject: [PATCH 1/2] HID: steelseries: Select POWER_SUPPLY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-rival3-battery-v1-1-6b1feeaf1f52@netixx.it>
References: <20261030-rival3-battery-v1-0-6b1feeaf1f52@netixx.it>
In-Reply-To: <20261030-rival3-battery-v1-0-6b1feeaf1f52@netixx.it>
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Martin Oberleiter <martin.oberleiter@netixx.it>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793342246; l=945;
 i=martin.oberleiter@netixx.it; s=20261029; h=from:subject:message-id;
 bh=mD34hfkgljPtL0ztTPCZwhP7a85OFYLVEn7tOj4h2oE=;
 b=yiFVCIo61O3xYrYicW6dd217F11YOIYGxEqo+4RVAoRFxPVQWvhFSMLj4XvWRGo1Ut6/2keSD
 xEypVyi/rnqDKE/zRcgl7ky9sw+eQhx0HzQgLGy/jE/XQG+4Q4WWryM
X-Developer-Key: i=martin.oberleiter@netixx.it; a=ed25519;
 pk=yZvkAuAsIiJ76LEGGTR3TI7+Xjw7lGN1dK6jcv72XZo=
X-Endpoint-Received: by B4 Relay for martin.oberleiter@netixx.it/20261029 with auth_id=1358
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Arctis headset support registers a power supply for the headset
battery, but HID_STEELSERIES does not select POWER_SUPPLY, and
power_supply_register() has no stub, so a build with POWER_SUPPLY=n
fails to link. Select it, like the other HID drivers that report a
battery.

Fixes: a0c76896c3fb ("HID: steelseries: Add support for Arctis 1 XBox")
Signed-off-by: Martin Oberleiter <martin.oberleiter@netixx.it>
---
 drivers/hid/Kconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/hid/Kconfig b/drivers/hid/Kconfig
index 2481bc01c..4d48da4f5 100644
--- a/drivers/hid/Kconfig
+++ b/drivers/hid/Kconfig
@@ -1214,6 +1214,7 @@ config STEAM_FF
 config HID_STEELSERIES
 	tristate "Steelseries devices support"
 	depends on USB_HID
+	select POWER_SUPPLY
 	help
 	Support for Steelseries SRW-S1 steering wheel, and the Steelseries
 	Arctis 1 Wireless for XBox, Arctis 7 (2018), Arctis 9, and Arctis

-- 
2.56.0

