From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 19 Jun 2026 21:54:02 -0500
Subject: [PATCH] ata: libata-core: Add NOLPM quirk for PNY CS900 1TB SSD
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260619-b4-disp-494070d2-v1-1-0c6d7be96237@proton.me>
X-B4-Tracking: v=1; b=H4sIAMkANmoC/x3MTQqAIBBA4avErBvwD8OuEi1Sp5qNhUIE4t2Tl
 t/ivQqFMlOBeaiQ6eHCV+qQ4wDh3NJByLEblFBWWOnQG4xcbjTOiElEhUFarbXTfnI79OzOtPP
 7L5e1tQ9WBapHYgAAAA==
To: Damien Le Moal <dlemoal@kernel.org>, Niklas Cassel <cassel@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-ide@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781924041; l=2401;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=o1g9RWfDLgEq+zCaJ+RXbfq0Fdywflc/XcToyx0FVEA=;
 b=O/QEYP1k1iBnVvN85QIAIDEqJ5yBp1INLpi6jrpT7DLnpTBIjw3nE50uGZ+h5DeS0L1lhp/UI
 SpOmufUipDqATVbLVk4ViPZwh6loAAOHbYPaCRZIys0dUyciaF7rZYh
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PNY CS900 1TB SSD (Phison PS3111-S11, DRAM-less) drops off the bus
after entering Device-Initiated Slumber during idle. With the default
med_power_with_dipm policy the link goes down (SStatus 1 SControl 300)
and does not recover, forcing the filesystem read-only. Forcing
max_performance keeps the link stable across prolonged idle.

Add a NOLPM quirk so link power management is disabled for this drive
specifically, leaving it intact for other devices on the host.

Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Tested on an Intel Alder Lake AHCI host. With the default
med_power_with_dipm the link drops after prolonged idle (SStatus 1
SControl 300); writes then fail and the filesystem is remounted
read-only, e.g.:

  sd 0:0:0:0: [sda] tag#22 CDB: Write(10) 2a 00 74 38 55 68 00 00 28 00
  EXT4-fs warning (device sda1): ext4_end_bio:368: I/O error 10 writing
    to inode 52429136 (starting block 243731117)
  ata1: EH complete
  ata1.00: detaching (SCSI 0:0:0:0)
  Buffer I/O error on device sda1, logical block 243730861
  sd 0:0:0:0: [sda] Synchronize Cache(10) failed: Result:
    hostbyte=DID_BAD_TARGET driverbyte=DRIVER_OK

Forcing max_performance (which this quirk applies per-device) keeps the
link stable across overnight idle. Drive: model "PNY CS900 1TB SSD", firmware
CS900702. The Phison PS3111-S11 controller is shared across the CS900
line, so other capacities/firmwares may need the same; scoped here to
the unit tested.
---
 drivers/ata/libata-core.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/ata/libata-core.c b/drivers/ata/libata-core.c
index 3d0027ec33c2..e1d05d4c13ba 100644
--- a/drivers/ata/libata-core.c
+++ b/drivers/ata/libata-core.c
@@ -4280,6 +4280,9 @@ static const struct ata_dev_quirks_entry __ata_dev_quirks[] = {
 	/* Apacer models with LPM issues */
 	{ "Apacer AS340*",		NULL,	ATA_QUIRK_NOLPM },
 
+	/* PNY CS900 (Phison PS3111-S11, DRAM-less) drops the link on DIPM */
+	{ "PNY CS900 1TB SSD",		NULL,	ATA_QUIRK_NOLPM },
+
 	/* Silicon Motion models with LPM issues */
 	{ "MD619HXCLDE3TC",		"TCVAID", ATA_QUIRK_NOLPM },
 	{ "MD619GXCLDE3TC",		"TCV35D", ATA_QUIRK_NOLPM },

---
base-commit: 4549871118cf616eecdd2d939f78e3b9e1dddc48
change-id: 20260619-b4-disp-494070d2-c1633393b79f

Best regards,
-- 
bryamzxz <hexlabsecurity@proton.me>

