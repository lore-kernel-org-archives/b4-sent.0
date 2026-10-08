From: Aleksei Berezin <8967858b87@gmail.com>
Date: Fri, 09 Oct 2026 02:41:19 +0400
Subject: [PATCH] usb: typec: ucsi: acpi: Add quirk for ASUS ROG Zephyrus
 Duo 16 GX650PI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-usb-next-v1-1-95a2288ad9b2@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5AMBCF4avIrDVpuyh1FbHQdjAWJR1EIu6uW
 H7J/94FjImQoSkuSHgQ0xIzVFmAn/o4oqCQDVpqo6S0YmcnIp6bsHWllPMmmFpDzteEA53fVdv
 95t3N6Ld3D/f9AGN/umRsAAAA
X-Change-ID: 20261009-usb-next-98711bc6d682
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aleksei Berezin <8967858b87@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791499288; l=1846;
 i=8967858b87@gmail.com; s=20261008; h=from:subject:message-id;
 bh=ZUe/15qN0Mxppoewg6G+nswhtqP0+uFLTWd6xRy/srQ=;
 b=aFGDFPYr/q9xe/9xPwSfFaRdQg99nHoip7c4m6WlX0hbAwKQubuYB6n+t/UGnYeLj6fARomJb
 oE9OETqmDJZDEArjhlb/kBmG49xbG0nPBWUoXYm+DL6Kjzgf5GKM8z7
X-Developer-Key: i=8967858b87@gmail.com; a=ed25519;
 pk=njtzBWPS2xf9KvwkMcmThxWGBoNdXiBOrAswIsycbXg=
X-Endpoint-Received: by B4 Relay for 8967858b87@gmail.com/20261008 with auth_id=1137
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the ASUS ROG Zephyrus Duo 16 (GX650PI, BIOS GX650PI.314) the firmware
loads the EC-based variant of the AMD CPM UCSI SSDT ("CPMUCSI"). Its _DSM
read function only copies MESSAGE_IN and CCI from the EC into the shared
mailbox and never fills in the VERSION field. The only code that sets the
version (M31F) lives in the "UCSIPLT" SSDT of the I2C-based variant, which
is present in the firmware image but not loaded on this machine.

As a result ucsi_register() reads a zero version and the probe fails
silently with -ENODEV, so neither Type-C port is registered and no
typec, usb_power_delivery or ucsi-source-psy devices are created.

Reuse the existing zero-version workaround from the Acer Nitro ANV15-41
quirk and assume UCSI 1.2 on this machine. With this change both ports,
the PD partner and the UCSI power supplies are registered and report the
connected USB PD charger correctly.

Assisted-by: Claude Opus 5.5 iasl
Signed-off-by: Aleksei Berezin <8967858b87@gmail.com>
---
 drivers/usb/typec/ucsi/ucsi_acpi.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/usb/typec/ucsi/ucsi_acpi.c b/drivers/usb/typec/ucsi/ucsi_acpi.c
index 5697ccc24..c8e6efdba 100644
--- a/drivers/usb/typec/ucsi/ucsi_acpi.c
+++ b/drivers/usb/typec/ucsi/ucsi_acpi.c
@@ -196,6 +196,13 @@ static const struct dmi_system_id ucsi_acpi_quirks[] = {
 		},
 		.driver_data = (void *)&ucsi_acer_ops,
 	},
+	{
+		.matches = {
+			DMI_MATCH(DMI_SYS_VENDOR, "ASUSTeK COMPUTER INC."),
+			DMI_MATCH(DMI_BOARD_NAME, "GX650PI"),
+		},
+		.driver_data = (void *)&ucsi_acer_ops,
+	},
 	{
 		.matches = {
 			DMI_MATCH(DMI_SYS_VENDOR, "LG Electronics"),

---
base-commit: 42bcac323cc3b16566fed8c5b250318ad02a0de0
change-id: 20261009-usb-next-98711bc6d682

Best regards,
--  
Aleksei Berezin <8967858b87@gmail.com>

