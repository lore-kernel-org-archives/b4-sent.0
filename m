From: Blake Alexander <contact@blakejalexander.com>
Date: Thu, 19 Nov 2026 04:56:59 +0100
Subject: [PATCH] usb: typec: ucsi: log invalid UCSI version of 0
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-log-ucsi-firmware-quirk-v1-1-6d42d70a6158@blakejalexander.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CQAxA0auQrm3CTIygVzEusLRQVNDWURPC3
 R1l+Rb/z+Bsyg6HYgbjl7pOY0bYFEB9M3aM2mZDLOMuhLDH69RhIlcUtdu7McZHUrtgLUJ1RVW
 7jQK5vhuLfv7n42m1p/PA9PztYFm+rNKy2nsAAAA=
X-Change-ID: 20261119-log-ucsi-firmware-quirk-8ffc87c7d42f
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Blake Alexander <contact@blakejalexander.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795060629; l=2922;
 i=contact@blakejalexander.com; s=20261119; h=from:subject:message-id;
 bh=D9QKefTsauXLfG27A3b8IZK8JtUA5DtyqrpmUi8e6cE=;
 b=rdPy/cmFK41OxT4Qx7L+fZtJAtdaWVvzTfGR+7kCCx+VCJ6OKfsJ7/1KcE8tnZk2za6Cy31/q
 z7qoirp65lwAkn8git9jXKQ+qnL4nPc1yP7zKWqyQN0f8Ne2y80yqKp
X-Developer-Key: i=contact@blakejalexander.com; a=ed25519;
 pk=csAgv2qq1q6RTYXyATg9ngFwpSFPE0yWA9R9nSvVxW0=
X-Endpoint-Received: by B4 Relay for contact@blakejalexander.com/20261119 with auth_id=1565
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some devices ship bugged firmware which sets the version of the UCSI
mailbox to zero. In such cases the ucsi_register() will return -ENODEV
and the driver will silently fail to bind. There is otherwise no
indication as to the cause of the probe failure.

While existing (and future) machine-specific workarounds may resolve
this issue by assuming a known-good UCSI version, future devices or
older firmware revisions with this issue will still silently fail.
Both users and developers will benefit from a clear diagnostic message
when troubleshooting this particular bug.

Add a dev_err() log message when a UCSI version of 0 is reported during
ucsi_register() hinting towards a potential firmware bug.

Signed-off-by: Blake Alexander <contact@blakejalexander.com>
---
Hi,

I have a ThinkPad T14 Gen 2a which is failing to negotiate a DisplayPort
Alt-Mode connection to a monitor-hub with a USB-C cable.

I spent quite some time troubleshooting the issue and identified the
root-cause only to find that a patch which fixes this issue was already
submitted:
- "[PATCH v2 0/2] usb: typec: acpi: Zero version quirk for Lenovo ThinkPad T14 Gen 2a" <20261103-ucsi-lenovo-t14g2a-v2-0-e85c659b56a2@resetko.pl>

Similar issues with other laptops have also been recently submitted:
- "[PATCH] usb: typec: ucsi: acpi: Add quirk for ASUS ROG Zephyrus Duo 16 GX650PI" <20261009-usb-next-v1-1-95a2288ad9b2@gmail.com>

And existing quirks are also already handled in mainline:
- Acer Nitro ANV15-41: commit 8c51ea651d04 ("usb: typec: ucsi: acpi:
  Assume UCSI 1.2 on Acer Nitro ANV15-41")

In the hope of saving future developer's time, this patch adds a
dev_err() log message when the UCSI version register reads zero. The
log message hints towards a potential firmware bug and gives an 
explicit cause of the driver's probe failure.

Tested on ThinkPad BIOS R1MET65W (1.35), EC R1MHT65W without the
relevant quirk patches.
---
 drivers/usb/typec/ucsi/ucsi.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/usb/typec/ucsi/ucsi.c b/drivers/usb/typec/ucsi/ucsi.c
index 9e453d216c16..fa79ba6dec02 100644
--- a/drivers/usb/typec/ucsi/ucsi.c
+++ b/drivers/usb/typec/ucsi/ucsi.c
@@ -2396,8 +2396,13 @@ int ucsi_register(struct ucsi *ucsi)
 	if (ret)
 		return ret;
 
-	if (!ucsi->version)
+	/* Version of 0 is not valid but some vendors may report it due to bugged
+	 * FW and there may not already be a workaround quirk to correct it.
+	 */
+	if (!ucsi->version) {
+		dev_err(ucsi->dev, "UCSI interface reported version 0.0.0: possible firmware bug.");
 		return -ENODEV;
+	}
 
 	/*
 	 * Version format is JJ.M.N (JJ = Major version, M = Minor version,

---
base-commit: f11fe7603df07fbb9fa02b0d385c1696c87a6dab
change-id: 20261119-log-ucsi-firmware-quirk-8ffc87c7d42f

Best regards,
--  
Blake Alexander <contact@blakejalexander.com>

