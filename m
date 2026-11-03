From: =?utf-8?q?Stanis=C5=82aw_Titenko?= <kernel@resetko.pl>
Date: Tue, 03 Nov 2026 17:10:21 +0100
Subject: [PATCH v2 2/2] usb: typec: ucsi: acpi: Assume UCSI 1.2 on Lenovo
 ThinkPad T14 Gen 2a
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261103-ucsi-lenovo-t14g2a-v2-2-e85c659b56a2@resetko.pl>
References: <20261103-ucsi-lenovo-t14g2a-v2-0-e85c659b56a2@resetko.pl>
In-Reply-To: <20261103-ucsi-lenovo-t14g2a-v2-0-e85c659b56a2@resetko.pl>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mark Pearson <mpearson-lenovo@squebb.ca>, 
 =?utf-8?q?Stanis=C5=82aw_Titenko?= <kernel@resetko.pl>, 
 Daniel Dev <daniel.dev@noex.uk>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793722249; l=2188;
 i=kernel@resetko.pl; s=20261031; h=from:subject:message-id;
 bh=jjGiVB1nMAe7D4TjN2PjVOhC/GWz1UPlwi3CJzOvb4k=;
 b=asEjd+7x9CJ1PCslYbBSMhWJ/Z1ERXVGhdud4cn4QiHV1jTD3NvQ5WwoWmg5QK7K608JJdqhy
 phaq7auHn8VBTZvqnAn4h/9HXCRTmkdQFU2DR/0O1efWQbfyMyPxwvJ
X-Developer-Key: i=kernel@resetko.pl; a=ed25519;
 pk=xMhqzbyPNWfeOgdmzSHsSlr5qjH779F5SD6BBHXixlY=
X-Endpoint-Received: by B4 Relay for kernel@resetko.pl/20261031 with auth_id=1372
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Lenovo ThinkPad T14 Gen 2a exposes a functional UCSI ACPI PPM but
the firmware leaves the VERSION field of the UCSI mailbox at zero.

ucsi_register() rejects a zero version with -ENODEV, leaving the
system without registered USB Type-C connectors. Without an OPM, the
embedded controller does not complete DisplayPort Alternate Mode setup
when a USB-C dock or monitor that supplies power is connected after
boot, so the display stays dark while USB and charging work.

Use the zero version quirk for the ThinkPad T14 Gen 2a, matching the
two board names of this model (20XK and 20XL).

Tested on a ThinkPad T14 Gen 2a (20XK) with BIOS 1.33 (R1MET63W):
both Type-C connectors register, and plugging and replugging a USB-C
monitor with an integrated hub and power delivery brings up
DisplayPort Alternate Mode each time.

Reported-by: Daniel Dev <daniel.dev@noex.uk>
Closes: https://lore.kernel.org/linux-usb/b1Wn_eFvTFShGbd970WWl4CWhge_6P2x7Wb6rab3QHNlE4OJ4p__O-QN3B6I-308ftr5oV5Zr7vywA0vdvmtNw6E0YJnVM2ek_5DcFnkXB0=@noex.uk/
Fixes: c1b0bc2dabfa ("usb: typec: Add support for UCSI interface")
Cc: stable@vger.kernel.org
Assisted-by: pi:claude-opus-5-5
Signed-off-by: Stanisław Titenko <kernel@resetko.pl>
---
 drivers/usb/typec/ucsi/ucsi_acpi.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/drivers/usb/typec/ucsi/ucsi_acpi.c b/drivers/usb/typec/ucsi/ucsi_acpi.c
index 47ba0e15b8ba..d752fc7b61ec 100644
--- a/drivers/usb/typec/ucsi/ucsi_acpi.c
+++ b/drivers/usb/typec/ucsi/ucsi_acpi.c
@@ -196,6 +196,22 @@ static const struct dmi_system_id ucsi_acpi_quirks[] = {
 		},
 		.driver_data = (void *)&ucsi_zero_version_ops,
 	},
+	{
+		/* Lenovo ThinkPad T14 Gen 2a */
+		.matches = {
+			DMI_MATCH(DMI_BOARD_VENDOR, "LENOVO"),
+			DMI_MATCH(DMI_BOARD_NAME, "20XK"),
+		},
+		.driver_data = (void *)&ucsi_zero_version_ops,
+	},
+	{
+		/* Lenovo ThinkPad T14 Gen 2a */
+		.matches = {
+			DMI_MATCH(DMI_BOARD_VENDOR, "LENOVO"),
+			DMI_MATCH(DMI_BOARD_NAME, "20XL"),
+		},
+		.driver_data = (void *)&ucsi_zero_version_ops,
+	},
 	{
 		.matches = {
 			DMI_MATCH(DMI_SYS_VENDOR, "LG Electronics"),

-- 
2.56.0

