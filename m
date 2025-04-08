From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Tue, 08 Apr 2025 21:13:13 +0200
Subject: [PATCH v2 2/2] usb: misc: onboard_dev: Add Realtek RTL8188ETV WiFi
 (0bda:0179)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250408-rtl-onboard-v2-2-0b6730b90e31@posteo.net>
References: <20250408-rtl-onboard-v2-0-0b6730b90e31@posteo.net>
In-Reply-To: <20250408-rtl-onboard-v2-0-0b6730b90e31@posteo.net>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Matthias Kaehlcke <mka@chromium.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jes Sorensen <Jes.Sorensen@gmail.com>, linux-wireless@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, Bitterblue Smith <rtl8821cerfe2@gmail.com>, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744139638; l=2744;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=QAwW/fIZM1Msvyl7HFFGS2WH+QP1UgWq6wvZq+BYZTg=;
 b=y9Q6G/o77lodCmXWcuYBq9RWABkFEcolT/FoGziqDsMP8XZrz51PCYjy0q4F0xA2X5IU90gQD
 9A4kJYwfHMUDqtlUe+2Fb4EWRwCf+tRGXOOts/DPGv4r7F28U8p67qI
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Realtek RTL8188ETV 2.4 GHz WiFi modules (detected as RTL8188EU by the
RTL8XXXXU driver) are found soldered into some embedded devices, such as
the Fernsehfee 3.0 set-top box.

They require a 3.3V power supply.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---

checkpatch.pl flags the "usbbda" prefix as undocumented because it isn't
in vendor-prefixes.yaml. It is, however, an established pattern:

$ git grep -E 'usb[0-9a-f]{1,4},[0-9a-f]{1,4}' | wc -l
213


V2:
- Refer to RTL8188ETV in the title and description
---
 drivers/usb/misc/onboard_usb_dev.c | 1 +
 drivers/usb/misc/onboard_usb_dev.h | 8 ++++++++
 2 files changed, 9 insertions(+)

diff --git a/drivers/usb/misc/onboard_usb_dev.c b/drivers/usb/misc/onboard_usb_dev.c
index 75ac3c6aa92d0d925bb9488d1e6295548446bf98..2f9e8f8108d8c36403b02f3e66db55757d4808ef 100644
--- a/drivers/usb/misc/onboard_usb_dev.c
+++ b/drivers/usb/misc/onboard_usb_dev.c
@@ -584,6 +584,7 @@ static const struct usb_device_id onboard_dev_id_table[] = {
 	{ USB_DEVICE(VENDOR_ID_REALTEK, 0x5411) }, /* RTS5411 USB 2.1 HUB */
 	{ USB_DEVICE(VENDOR_ID_REALTEK, 0x0414) }, /* RTS5414 USB 3.2 HUB */
 	{ USB_DEVICE(VENDOR_ID_REALTEK, 0x5414) }, /* RTS5414 USB 2.1 HUB */
+	{ USB_DEVICE(VENDOR_ID_REALTEK, 0x0179) }, /* RTL8188ETV 2.4GHz WiFi */
 	{ USB_DEVICE(VENDOR_ID_TI, 0x8025) }, /* TI USB8020B 3.0 HUB */
 	{ USB_DEVICE(VENDOR_ID_TI, 0x8027) }, /* TI USB8020B 2.0 HUB */
 	{ USB_DEVICE(VENDOR_ID_TI, 0x8140) }, /* TI USB8041 3.0 HUB */
diff --git a/drivers/usb/misc/onboard_usb_dev.h b/drivers/usb/misc/onboard_usb_dev.h
index 933797a7e0841ceee655b80ee1c8d21bc2eaaa04..4b023ddfbdd61efbc41c039cafbd0c85971563ee 100644
--- a/drivers/usb/misc/onboard_usb_dev.h
+++ b/drivers/usb/misc/onboard_usb_dev.h
@@ -45,6 +45,13 @@ static const struct onboard_dev_pdata realtek_rts5411_data = {
 	.is_hub = true,
 };
 
+static const struct onboard_dev_pdata realtek_rtl8188etv_data = {
+	.reset_us = 0,
+	.num_supplies = 1,
+	.supply_names = { "vdd" },
+	.is_hub = false,
+};
+
 static const struct onboard_dev_pdata ti_tusb8020b_data = {
 	.reset_us = 3000,
 	.num_supplies = 1,
@@ -118,6 +125,7 @@ static const struct of_device_id onboard_dev_match[] = {
 	{ .compatible = "usb5e3,610", .data = &genesys_gl852g_data, },
 	{ .compatible = "usb5e3,620", .data = &genesys_gl852g_data, },
 	{ .compatible = "usb5e3,626", .data = &genesys_gl852g_data, },
+	{ .compatible = "usbbda,179", .data = &realtek_rtl8188etv_data, },
 	{ .compatible = "usbbda,411", .data = &realtek_rts5411_data, },
 	{ .compatible = "usbbda,5411", .data = &realtek_rts5411_data, },
 	{ .compatible = "usbbda,414", .data = &realtek_rts5411_data, },

-- 
2.48.0.rc1.219.gb6b6757d772

