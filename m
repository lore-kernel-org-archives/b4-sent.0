From: =?utf-8?q?Stanis=C5=82aw_Titenko?= <kernel@resetko.pl>
Date: Tue, 03 Nov 2026 17:10:20 +0100
Subject: [PATCH v2 1/2] usb: typec: ucsi: acpi: Rename the Acer zero
 version quirk
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261103-ucsi-lenovo-t14g2a-v2-1-e85c659b56a2@resetko.pl>
References: <20261103-ucsi-lenovo-t14g2a-v2-0-e85c659b56a2@resetko.pl>
In-Reply-To: <20261103-ucsi-lenovo-t14g2a-v2-0-e85c659b56a2@resetko.pl>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mark Pearson <mpearson-lenovo@squebb.ca>, 
 =?utf-8?q?Stanis=C5=82aw_Titenko?= <kernel@resetko.pl>, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793722249; l=1953;
 i=kernel@resetko.pl; s=20261031; h=from:subject:message-id;
 bh=hms0PyZfM1RQtj2hb1BMKNKwDG72eddmepQmTG3Iwkk=;
 b=SXh+GYE6jmmiLlCwzeK7yARMsPdhKVRsKaLPWKFCOm6u8piuqXcSsDvLfWtoUHPvIZWNacrZ9
 zcEXgJRCq3fCqXSNSXzgWQ+vzMac+5kVXovEqBQoRNWSWT3AMAFNLjz
X-Developer-Key: i=kernel@resetko.pl; a=ed25519;
 pk=xMhqzbyPNWfeOgdmzSHsSlr5qjH779F5SD6BBHXixlY=
X-Endpoint-Received: by B4 Relay for kernel@resetko.pl/20261031 with auth_id=1372
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The quirk added for the Acer Nitro ANV15-41 is not specific to that
machine: it substitutes UCSI 1.2 when the firmware reports a zero
version, which other platforms with the same firmware bug need too.

Rename ucsi_acer_read_version() and ucsi_acer_ops to
ucsi_zero_version_read_version() and ucsi_zero_version_ops, so that
they can be shared with other machines.

No functional change.

Cc: stable@vger.kernel.org # needed by the next patch
Assisted-by: pi:claude-opus-5-5
Signed-off-by: Stanisław Titenko <kernel@resetko.pl>
---
 drivers/usb/typec/ucsi/ucsi_acpi.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/usb/typec/ucsi/ucsi_acpi.c b/drivers/usb/typec/ucsi/ucsi_acpi.c
index 5697ccc24ec3..47ba0e15b8ba 100644
--- a/drivers/usb/typec/ucsi/ucsi_acpi.c
+++ b/drivers/usb/typec/ucsi/ucsi_acpi.c
@@ -121,7 +121,7 @@ static const struct ucsi_operations ucsi_acpi_ops = {
 	.async_control = ucsi_acpi_async_control
 };
 
-static int ucsi_acer_read_version(struct ucsi *ucsi, u16 *version)
+static int ucsi_zero_version_read_version(struct ucsi *ucsi, u16 *version)
 {
 	struct ucsi_acpi *ua = ucsi_get_drvdata(ucsi);
 	int ret;
@@ -138,8 +138,8 @@ static int ucsi_acer_read_version(struct ucsi *ucsi, u16 *version)
 	return 0;
 }
 
-static const struct ucsi_operations ucsi_acer_ops = {
-	.read_version = ucsi_acer_read_version,
+static const struct ucsi_operations ucsi_zero_version_ops = {
+	.read_version = ucsi_zero_version_read_version,
 	.read_cci = ucsi_acpi_read_cci,
 	.poll_cci = ucsi_acpi_poll_cci,
 	.read_message_in = ucsi_acpi_read_message_in,
@@ -194,7 +194,7 @@ static const struct dmi_system_id ucsi_acpi_quirks[] = {
 			DMI_MATCH(DMI_SYS_VENDOR, "Acer"),
 			DMI_MATCH(DMI_PRODUCT_NAME, "Nitro ANV15-41"),
 		},
-		.driver_data = (void *)&ucsi_acer_ops,
+		.driver_data = (void *)&ucsi_zero_version_ops,
 	},
 	{
 		.matches = {

-- 
2.56.0

