From: Maximilian Pezzullo <maximilianpezzullo@gmail.com>
Date: Tue, 03 Mar 2026 23:52:18 +0100
Subject: [PATCH] ata: libata-core: Disable LPM on ST1000DM010-2EP102
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260303-ata-libata-core-disable-lpm-on-st1000dm010-2ep102-v1-1-40d5db367f67@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2NwQrCMBAFf6Xs2YWXREvxV8RD0qy6kCYlKSKU/
 rvR0zCXmZ2aVJVG12GnKm9tWnIXcxpofvn8FNbYnSzsCAfHfvOcNPwwlyoctfmQhNO6cMncNgM
 gLjBgK6uB5YAwXUZMAnem3l2rPPTzf97ux/EFVFUXiYMAAAA=
X-Change-ID: 20260303-ata-libata-core-disable-lpm-on-st1000dm010-2ep102-b0b85608e034
To: Damien Le Moal <dlemoal@kernel.org>, Niklas Cassel <cassel@kernel.org>
Cc: linux-ide@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Filippo Baiamonte <filippo.ba03@bugzilla.kernel.org>, 
 Copilot <223556219+Copilot@users.noreply.github.com>, 
 Maximilian Pezzullo <maximilianpezzullo@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772578395; l=1306;
 i=maximilianpezzullo@gmail.com; s=20260303; h=from:subject:message-id;
 bh=neTp5ojoaCXWgRDr8G6XNKyq5Sb8kE/WuOHE9oCy1T8=;
 b=YYfgDgi2pZ7QrUybv9YQHXOVhAvFLhRa6EXTya1w0RFX3IlSKLpngNlU2GdhbXNm9K5toZS/d
 tIhxfYTYBRIBba8sJP4Hk5TiV0JcDrfTloCZekqulwguuA38kK6a6HY
X-Developer-Key: i=maximilianpezzullo@gmail.com; a=ed25519;
 pk=TRTR4c2Vb1IfluQvv5OUDPg7EE+pIzdPBND85UU559w=
X-Endpoint-Received: by B4 Relay for maximilianpezzullo@gmail.com/20260303 with auth_id=658
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

According to a user report, the ST1000DM010-2EP102 has problems with LPM,
causing random system freezes since kernel 6.15. The drive belongs to the
same BarraCuda family as the ST2000DM008-2FR102 which has the same issue.

Reported-by: Filippo Baiamonte <filippo.ba03@bugzilla.kernel.org>
Closes: https://bugzilla.kernel.org/show_bug.cgi?id=221163
Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
Signed-off-by: Maximilian Pezzullo <maximilianpezzullo@gmail.com>
---
 drivers/ata/libata-core.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/ata/libata-core.c b/drivers/ata/libata-core.c
index ccbf320524da..76b012f544ea 100644
--- a/drivers/ata/libata-core.c
+++ b/drivers/ata/libata-core.c
@@ -4189,6 +4189,7 @@ static const struct ata_dev_quirks_entry __ata_dev_quirks[] = {
 						ATA_QUIRK_FIRMWARE_WARN },
 
 	/* Seagate disks with LPM issues */
+	{ "ST1000DM010-2EP102",	NULL,		ATA_QUIRK_NOLPM },
 	{ "ST2000DM008-2FR102",	NULL,		ATA_QUIRK_NOLPM },
 
 	/* drives which fail FPDMA_AA activation (some may freeze afterwards)

---
base-commit: af4e9ef3d78420feb8fe58cd9a1ab80c501b3c08
change-id: 20260303-ata-libata-core-disable-lpm-on-st1000dm010-2ep102-b0b85608e034

Best regards,
-- 
Maximilian Pezzullo <maximilianpezzullo@gmail.com>

