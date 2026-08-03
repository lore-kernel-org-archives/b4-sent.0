From: "Pawel Zalewski (The Capable Hub)" <pzalewski@thegoodpenguin.co.uk>
Date: Mon, 03 Aug 2026 16:03:51 +0100
Subject: [PATCH 2/2] ata: ahci_seattle: drop unused
 acpi_device_id::driver_data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-ata-acpi-v1-2-f606afaacad1@thegoodpenguin.co.uk>
References: <20260803-ata-acpi-v1-0-f606afaacad1@thegoodpenguin.co.uk>
In-Reply-To: <20260803-ata-acpi-v1-0-f606afaacad1@thegoodpenguin.co.uk>
To: Hans de Goede <hansg@kernel.org>, Damien Le Moal <dlemoal@kernel.org>, 
 Niklas Cassel <cassel@kernel.org>
Cc: linux-ide@vger.kernel.org, linux-kernel@vger.kernel.org, 
 "Pawel Zalewski (The Capable Hub)" <pzalewski@thegoodpenguin.co.uk>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785769441; l=991;
 i=pzalewski@thegoodpenguin.co.uk; s=20260803; h=from:subject:message-id;
 bh=NTXTlwoJq1lj+SCnk1cP3pBirwDRzp26Eqhz/VVpz7g=;
 b=hHVIY0FHG/LCgvw64RMEFNmMBpCnkPqpMqMd6efOPU7QrZ1NAtnXzGy3uFJjdGguQ9l7vQCEH
 fPUT++WnuooByct+CmewiYse55NReJ8kyyscIC9owlzfOrgnPhB8n0z
X-Developer-Key: i=pzalewski@thegoodpenguin.co.uk; a=ed25519;
 pk=W3zk1cb/wRnj6pNGbl3/2Zf3GmPA6IBpNHpDPyJ05k8=
X-Endpoint-Received: by B4 Relay for pzalewski@thegoodpenguin.co.uk/20260803 with auth_id=913
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This module sets the acpi_device_id::driver_data to 0 but
the id is not actually used within the module, we can
just drop it from the list.

While we are at it - used a named initializer for the
acpi_device_id::id field to increase readability and
modify the list terminator to have a single space in
between the brackets.

Signed-off-by: Pawel Zalewski (The Capable Hub) <pzalewski@thegoodpenguin.co.uk>
---
 drivers/ata/ahci_seattle.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/ata/ahci_seattle.c b/drivers/ata/ahci_seattle.c
index 3f16c1678402..9758fa0260ac 100644
--- a/drivers/ata/ahci_seattle.c
+++ b/drivers/ata/ahci_seattle.c
@@ -178,8 +178,8 @@ static SIMPLE_DEV_PM_OPS(ahci_pm_ops, ahci_platform_suspend,
 			 ahci_platform_resume);
 
 static const struct acpi_device_id ahci_acpi_match[] = {
-	{ "AMDI0600", 0 },
-	{}
+	{ .id = "AMDI0600" },
+	{ }
 };
 MODULE_DEVICE_TABLE(acpi, ahci_acpi_match);
 

-- 
2.54.0

