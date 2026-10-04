From: Harinn <prinn.dev@pm.me>
Date: Sun, 04 Oct 2026 17:59:53 +0700
Subject: [PATCH] i2c: acpi: Force ASUE140D touchpads to 100 kHz
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261004-i2c-acpi-asue140d-100khz-v1-1-cc2dbad00470@pm.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM0QqDMAyF4VeRXC/QlkxhryJedDHVbOCkmWNMf
 PdVvfwOnH8Fk6xicKtWyPJR09dU4C8V8BinQVD7Yggu1N45Qg2MkWfFaIt4cj2W+Tn+kKipSTi
 lJlyh3OcsSb9Huu1O23J/CL/3HmzbH8l2jN98AAAA
X-Change-ID: 20261004-i2c-acpi-asue140d-100khz-44764ecff725
To: Andi Shyti <andi.shyti@kernel.org>, 
 Mika Westerberg <westeri@kernel.org>
Cc: linux-i2c@vger.kernel.org, linux-acpi@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Harinn <prinn.dev@pm.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791111594; l=1034;
 i=prinn.dev@pm.me; s=20261004; h=from:subject:message-id;
 bh=CuXYtEQhbQqdDDViBlDQYIFq8WwTJxIz9o0H7TCHD1M=;
 b=adT3U/tce9xAsjL3NVTi1vLNYJ4orkdv3gjXD70QK0+cucyBy8YyVOuHoVzPS/zEjAArKHG9m
 ZudNy/K2OAgCiMfhUcIy1nAWBhJXz0YMKT6tLkY/teQpF9wf2gNe/5E
X-Developer-Key: i=prinn.dev@pm.me; a=ed25519;
 pk=3q9t6SnPdJf3aRWfM5pwBvkSsRbrWSjKlcZ7e9U+UZU=
X-Endpoint-Received: by B4 Relay for prinn.dev@pm.me/20261004 with auth_id=1108
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ASUE140D touchpad on the ASUS Zenbook UX3404VC (BIOS UX3404VC.303)
starts lagging shortly after boot when the bus runs at the 400 kHz the
DSDT asks for, and only recovers after rebinding i2c-hid. Forcing
100 kHz fixes it.

Signed-off-by: Harinn <prinn.dev@pm.me>
---
 drivers/i2c/i2c-core-acpi.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/i2c/i2c-core-acpi.c b/drivers/i2c/i2c-core-acpi.c
index 8f3bdd50186e..e5b27375af31 100644
--- a/drivers/i2c/i2c-core-acpi.c
+++ b/drivers/i2c/i2c-core-acpi.c
@@ -371,6 +371,7 @@ static const struct acpi_device_id i2c_acpi_force_100khz_device_ids[] = {
 	 * the device works without issues on Windows at what is expected to be
 	 * a 400KHz frequency. The root cause of the issue is not known.
 	 */
+	{ "ASUE140D", 0 },
 	{ "DLL0945", 0 },
 	{ "ELAN0678", 0 },
 	{ "ELAN06FA", 0 },

---
base-commit: 6addb4f385570ebc11c4eb499a4f1c149f313e84
change-id: 20261004-i2c-acpi-asue140d-100khz-44764ecff725

Best regards,
--  
Harinn <prinn.dev@pm.me>

