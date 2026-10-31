From: =?utf-8?q?Stanis=C5=82aw_Titenko?= <kernel@resetko.pl>
Date: Sat, 31 Oct 2026 22:40:15 +0100
Subject: [PATCH] usb: typec: ucsi: acpi: Assume UCSI 1.0 on Lenovo ThinkPad
 T14 Gen 2a
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261031-ucsi-lenovo-t14g2a-v1-1-183751e63c02@resetko.pl>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrDtgomjtVYqLNJnoFElKRkUQ7
 96oy7f4fwehxCTwKnZItLJwDBnqUYAdTRgI2WWDLnWjykrhYoVxohDXiLOqB23QOEOt86313RN
 y+Evkebum7/62LJ8v2fk8wXH8AVRi7SV2AAAA
X-Change-ID: 20261031-ucsi-lenovo-t14g2a-adae7df7cf98
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mark Pearson <mpearson-lenovo@squebb.ca>, Daniel Dev <daniel.dev@noex.uk>, 
 stable@vger.kernel.org, 
 =?utf-8?q?Stanis=C5=82aw_Titenko?= <kernel@resetko.pl>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793482825; l=3304;
 i=kernel@resetko.pl; s=20261031; h=from:subject:message-id;
 bh=p95Jlz0L7Maeo6S23F9A5uV32hXuG2XEilhjG+4iteE=;
 b=CJVzqOB2QyLwtfq1dMaLkgblbKND58j8M5qXBZC2kN1CjY990raZUSbjvlijsEqgUuCOnCkak
 lRFLLh29W+JBI+/OT6O76jtSQQVnqYmwV39EtBUqnCLNxt1CBq1zxQq
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

The mailbox uses the 48-byte UCSI 1.x layout, and the PPM works
correctly when UCSI 1.0 is assumed.

Add a DMI-specific UCSI operation for the ThinkPad T14 Gen 2a that
substitutes UCSI 1.0 only when firmware reports a zero version.
Preserve any valid non-zero firmware version.

Tested on a ThinkPad T14 Gen 2a with BIOS 1.33 (R1MET63W): both
Type-C connectors register, and plugging and replugging a USB-C
monitor with an integrated hub and power delivery brings up
DisplayPort Alternate Mode each time.

Reported-by: Daniel Dev <daniel.dev@noex.uk>
Closes: https://lore.kernel.org/linux-usb/b1Wn_eFvTFShGbd970WWl4CWhge_6P2x7Wb6rab3QHNlE4OJ4p__O-QN3B6I-308ftr5oV5Zr7vywA0vdvmtNw6E0YJnVM2ek_5DcFnkXB0=@noex.uk/
Fixes: c1b0bc2dabfa ("usb: typec: Add support for UCSI interface")
Cc: stable@vger.kernel.org
Assisted-by: pi:claude-opus-5-5
Signed-off-by: Stanisław Titenko <kernel@resetko.pl>
---
 drivers/usb/typec/ucsi/ucsi_acpi.c | 34 ++++++++++++++++++++++++++++++++++
 1 file changed, 34 insertions(+)

diff --git a/drivers/usb/typec/ucsi/ucsi_acpi.c b/drivers/usb/typec/ucsi/ucsi_acpi.c
index 5697ccc24ec3..33747e24353f 100644
--- a/drivers/usb/typec/ucsi/ucsi_acpi.c
+++ b/drivers/usb/typec/ucsi/ucsi_acpi.c
@@ -148,6 +148,33 @@ static const struct ucsi_operations ucsi_acer_ops = {
 	.async_control = ucsi_acpi_async_control
 };
 
+static int ucsi_lenovo_read_version(struct ucsi *ucsi, u16 *version)
+{
+	struct ucsi_acpi *ua = ucsi_get_drvdata(ucsi);
+	int ret;
+
+	ret = ucsi_acpi_read_version(ucsi, version);
+	if (ret)
+		return ret;
+
+	if (!*version) {
+		dev_warn(ua->dev, "UCSI version is zero, assuming 1.0\n");
+		*version = UCSI_VERSION_1_0;
+	}
+
+	return 0;
+}
+
+static const struct ucsi_operations ucsi_lenovo_ops = {
+	.read_version = ucsi_lenovo_read_version,
+	.read_cci = ucsi_acpi_read_cci,
+	.poll_cci = ucsi_acpi_poll_cci,
+	.read_message_in = ucsi_acpi_read_message_in,
+	.write_message_out = ucsi_acpi_write_message_out,
+	.sync_control = ucsi_sync_control_common,
+	.async_control = ucsi_acpi_async_control
+};
+
 static int ucsi_gram_sync_control(struct ucsi *ucsi, u64 command, u32 *cci,
 				  void *val, size_t len, void *msg_out,
 				  size_t msg_out_size)
@@ -196,6 +223,13 @@ static const struct dmi_system_id ucsi_acpi_quirks[] = {
 		},
 		.driver_data = (void *)&ucsi_acer_ops,
 	},
+	{
+		.matches = {
+			DMI_MATCH(DMI_SYS_VENDOR, "LENOVO"),
+			DMI_MATCH(DMI_PRODUCT_VERSION, "ThinkPad T14 Gen 2a"),
+		},
+		.driver_data = (void *)&ucsi_lenovo_ops,
+	},
 	{
 		.matches = {
 			DMI_MATCH(DMI_SYS_VENDOR, "LG Electronics"),

---
base-commit: e9954f3fbddd25e1a01b7e5a0b72fb8b564204e0
change-id: 20261031-ucsi-lenovo-t14g2a-adae7df7cf98

Best regards,
--  
Stanisław Titenko <kernel@resetko.pl>

