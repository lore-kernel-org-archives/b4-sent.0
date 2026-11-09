From: Brian Ellis <brianellis@gotenna.com>
Date: Mon, 09 Nov 2026 11:22:57 -0700
Subject: [PATCH] usb: ulpi: warn when a PHY with no DT node cannot be read
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-ulpi-warn-unidentified-phy-v1-1-64537f455dd8@gotenna.com>
X-B4-Tracking: v=1; b=H4sIAIAP8moC/x3MQQqDMBAF0KvIrDtgokjjVUoXYib6oYwhqbYi3
 t3g8m3eQVkSJFNfHZRkQ8aiBeZR0TgPOgnDF5OtbWdM7Xj9RPBvSMqrwot+ESCe47zzc3Stt9I
 2wTgqQUwS8L/z1/s8L9VeJTpsAAAA
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Brian Ellis <brianellis@gotenna.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794248576; l=3957;
 i=brianellis@gotenna.com; s=20260910; h=from:subject:message-id;
 bh=sscEEhH87QAvvEcPEryzTnpnZF0PX9iRncrq3sU3Y20=;
 b=I0MGMqjf1Gn5H4rXazQv8NRzmLpcuqiZ3wLtwT42iSm5FxysSlfQwWyvi2OW+ugKOno8MBwjJ
 BHufruxBfMZCLMZ7zYgU4Ic1ZaK1wLoxoJClFuC36tS7PNFnu/pAAbE
X-Developer-Key: i=brianellis@gotenna.com; a=ed25519;
 pk=JciDR8ctfMqvKeRCDP8VPwNLUDULxCAqDum6H+/ByBY=
X-Endpoint-Received: by B4 Relay for brianellis@gotenna.com/20260910 with auth_id=1022
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ulpi_read_id() checks that the PHY's registers can be reached by writing
ULPI_SCRATCH and reading it back.  If the write fails or the value does
not come back, it falls back to OF matching and returns success, with
nothing logged and ulpi->id left at 0000:0000.

Commit ef6a7bcfb01c ("usb: ulpi: Support device discovery via DT") added
that fallback for PHYs described in DT, which may not be powered yet when
the ID is read.  For a PHY with no DT node it does nothing:
of_request_module() returns -ENODEV for a NULL node, and ulpi_match() can
only match a zero vendor ID through OF.  The PHY is never identified and
nothing says why, so code that keys off ulpi->id, such as dwc3's USB3340
detection, silently does not apply.

Commit 8a7b31d545d3 ("usb: ulpi: defer ulpi_register on ulpi_read_id
timeout") made the failed write an error for this reason.  It was
reverted by commit b659b613cea2 ("Revert "usb: ulpi: defer
ulpi_register on ulpi_read_id timeout"") because QEMU's Zynq machines,
where this write times out, then could not boot from USB.  So keep the
behaviour and only report it.

We hit this on a ZynqMP board whose USB3340 takes its PLL supply from
VBUS, so its ULPI clock only runs with a cable attached.  Booted without
one, the scratch write times out, the PHY reads as 0000:0000, and dwc3
never enables the USB3340 transceiver delay, all without a message.

Warn when register access fails and there is no DT node to fall back on.
PHYs described in DT, and PHYs whose registers work but report no vendor
ID, stay silent as before.

Signed-off-by: Brian Ellis <brianellis@gotenna.com>
---
How this was tested: the failure was observed on our board, on AMD's
6.6-based vendor kernel, where an earlier version of this patch warned on
every fallback and printed

  dwc3 fe200000.usb: ULPI id read failed or unavailable (0000:0000); relying on OF match

on a boot without a cable.  That version would also have warned for
DT-described PHYs and for PHYs with no vendor ID, which is why it was
narrowed to this one.  This version has not been run on hardware.  On
usb-next it is compile-tested only (x86_64 allmodconfig, W=1, no
warnings).

On QEMU's Zynq machines, where the scratch write times out (see
b659b613cea2), this prints one line at boot.  That is accurate there too:
the PHY is not identified.

Tool use: an LLM coding assistant (Claude) helped investigate this, wrote
the code change, and drafted this changelog and these notes.  The
observation above was made on our hardware.
---
 drivers/usb/common/ulpi.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/drivers/usb/common/ulpi.c b/drivers/usb/common/ulpi.c
index dec4baca1c..9d94d51726 100644
--- a/drivers/usb/common/ulpi.c
+++ b/drivers/usb/common/ulpi.c
@@ -209,14 +209,14 @@ static int ulpi_read_id(struct ulpi *ulpi)
 	/* Test the interface */
 	ret = ulpi_write(ulpi, ULPI_SCRATCH, 0xaa);
 	if (ret < 0)
-		goto err;
+		goto err_access;
 
 	ret = ulpi_read(ulpi, ULPI_SCRATCH);
 	if (ret < 0)
 		return ret;
 
 	if (ret != 0xaa)
-		goto err;
+		goto err_access;
 
 	ulpi->id.vendor = ulpi_read(ulpi, ULPI_VENDOR_ID_LOW);
 	ulpi->id.vendor |= ulpi_read(ulpi, ULPI_VENDOR_ID_HIGH) << 8;
@@ -230,6 +230,13 @@ static int ulpi_read_id(struct ulpi *ulpi)
 
 	request_module("ulpi:v%04xp%04x", ulpi->id.vendor, ulpi->id.product);
 	return 0;
+err_access:
+	/*
+	 * A PHY described in DT may not be powered yet and is matched via OF
+	 * instead.  Without a DT node nothing else can identify it, so say so.
+	 */
+	if (!ulpi->dev.of_node)
+		dev_warn(&ulpi->dev, "PHY registers not accessible, PHY not identified\n");
 err:
 	of_request_module(ulpi->dev.of_node);
 	return 0;

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261109-ulpi-warn-unidentified-phy-8c94d2e43f19

Best regards,
-- 
Brian Ellis <brianellis@gotenna.com>

