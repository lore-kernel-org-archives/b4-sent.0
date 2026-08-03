From: "Pawel Zalewski (The Capable Hub)" <pzalewski@thegoodpenguin.co.uk>
Date: Mon, 03 Aug 2026 16:03:50 +0100
Subject: [PATCH 1/2] ata: use named initializers for acpi_device_id
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-ata-acpi-v1-1-f606afaacad1@thegoodpenguin.co.uk>
References: <20260803-ata-acpi-v1-0-f606afaacad1@thegoodpenguin.co.uk>
In-Reply-To: <20260803-ata-acpi-v1-0-f606afaacad1@thegoodpenguin.co.uk>
To: Hans de Goede <hansg@kernel.org>, Damien Le Moal <dlemoal@kernel.org>, 
 Niklas Cassel <cassel@kernel.org>
Cc: linux-ide@vger.kernel.org, linux-kernel@vger.kernel.org, 
 "Pawel Zalewski (The Capable Hub)" <pzalewski@thegoodpenguin.co.uk>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785769441; l=2352;
 i=pzalewski@thegoodpenguin.co.uk; s=20260803; h=from:subject:message-id;
 bh=WMyRqpKRasvtDzYDnFf0+c4OYkQwjZjb+uf6e+s2Npo=;
 b=PbTHyx1WSZfMEhOhxM9hmNcXZFILmH388MaASnrWgAbeuHMoifugHG966KQFhmtyx3di43las
 Owk2gLaALFrC4gvY+NrEhNq/wh1SqD/c8X2pr7LWnikpN0sfOa6oJuP
X-Developer-Key: i=pzalewski@thegoodpenguin.co.uk; a=ed25519;
 pk=W3zk1cb/wRnj6pNGbl3/2Zf3GmPA6IBpNHpDPyJ05k8=
X-Endpoint-Received: by B4 Relay for pzalewski@thegoodpenguin.co.uk/20260803 with auth_id=913
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use a named initializer for the acpi_device_id fields which
makes the code more readable and consistent with how lists
are initialized in the rest of the kernel code base.

While we are at it - unify the list terminator to have
a single space between the brackets and no trailing
comma.

Signed-off-by: Pawel Zalewski (The Capable Hub) <pzalewski@thegoodpenguin.co.uk>
---
 drivers/ata/ahci_platform.c | 4 ++--
 drivers/ata/ahci_qoriq.c    | 2 +-
 drivers/ata/ahci_xgene.c    | 6 +++---
 3 files changed, 6 insertions(+), 6 deletions(-)

diff --git a/drivers/ata/ahci_platform.c b/drivers/ata/ahci_platform.c
index c18054333f7c..d97f0ad3b4cd 100644
--- a/drivers/ata/ahci_platform.c
+++ b/drivers/ata/ahci_platform.c
@@ -88,9 +88,9 @@ static const struct of_device_id ahci_of_match[] = {
 MODULE_DEVICE_TABLE(of, ahci_of_match);
 
 static const struct acpi_device_id ahci_acpi_match[] = {
-	{ "APMC0D33", (unsigned long)&ahci_port_info_nolpm },
+	{ .id = "APMC0D33", .driver_data = (unsigned long)&ahci_port_info_nolpm },
 	{ ACPI_DEVICE_CLASS(PCI_CLASS_STORAGE_SATA_AHCI, 0xffffff) },
-	{},
+	{ }
 };
 MODULE_DEVICE_TABLE(acpi, ahci_acpi_match);
 
diff --git a/drivers/ata/ahci_qoriq.c b/drivers/ata/ahci_qoriq.c
index 0dec1a17e5b1..96492159fa7c 100644
--- a/drivers/ata/ahci_qoriq.c
+++ b/drivers/ata/ahci_qoriq.c
@@ -80,7 +80,7 @@ static const struct of_device_id ahci_qoriq_of_match[] = {
 MODULE_DEVICE_TABLE(of, ahci_qoriq_of_match);
 
 static const struct acpi_device_id ahci_qoriq_acpi_match[] = {
-	{"NXP0004", .driver_data = (kernel_ulong_t)AHCI_LX2160A},
+	{ .id = "NXP0004", .driver_data = (kernel_ulong_t)AHCI_LX2160A },
 	{ }
 };
 MODULE_DEVICE_TABLE(acpi, ahci_qoriq_acpi_match);
diff --git a/drivers/ata/ahci_xgene.c b/drivers/ata/ahci_xgene.c
index 98c99b5a8242..2ebfe86e429b 100644
--- a/drivers/ata/ahci_xgene.c
+++ b/drivers/ata/ahci_xgene.c
@@ -710,9 +710,9 @@ static const struct scsi_host_template ahci_platform_sht = {
 
 #ifdef CONFIG_ACPI
 static const struct acpi_device_id xgene_ahci_acpi_match[] = {
-	{ "APMC0D0D", XGENE_AHCI_V1},
-	{ "APMC0D32", XGENE_AHCI_V2},
-	{},
+	{ .id = "APMC0D0D", .driver_data = XGENE_AHCI_V1 },
+	{ .id = "APMC0D32", .driver_data = XGENE_AHCI_V2 },
+	{ }
 };
 MODULE_DEVICE_TABLE(acpi, xgene_ahci_acpi_match);
 #endif

-- 
2.54.0

