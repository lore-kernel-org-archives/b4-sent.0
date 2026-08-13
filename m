From: Luca Lauro <famlauro93l@gmail.com>
Date: Thu, 13 Aug 2026 17:26:33 +0200
Subject: [PATCH v4 13/14] ata: ahci: add FLUSH EXT and STANDBY IMMEDIATE
 support during shutdown
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-rn102-rn104-series-v4-13-f932ac63efa0@gmail.com>
References: <20260813-rn102-rn104-series-v4-0-f932ac63efa0@gmail.com>
In-Reply-To: <20260813-rn102-rn104-series-v4-0-f932ac63efa0@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786634824; l=2131;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=NB/lGclEWIk7DTAmZIt8R54Cyh8dwOTIdS/Q1rcI78U=;
 b=2aQJfCKEgF34dQuW3LWZyIUpkZQwOhOu4dSxnyeZjexYznFMVPI3CTHkqlc12Y/VFn83yLFRY
 tO9oFZNF1nSC8Kgi6XnWy2QIc1f61/oyInZZ29BUX9IpTl1dlZAUS2G
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some AHCI controllers require ATA FLUSH EXT and STANDBY IMMEDIATE to be
issued before poweroff to ensure data integrity and proper device
shutdown. This patch introduces ahci_port_shutdown(), which sends these
commands using ahci_ata_nodata().

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 drivers/ata/ahci.c | 46 +++++-----------------------------------------
 1 file changed, 5 insertions(+), 41 deletions(-)

diff --git a/drivers/ata/ahci.c b/drivers/ata/ahci.c
index c78d1953e4..9ac34b15fe 100644
--- a/drivers/ata/ahci.c
+++ b/drivers/ata/ahci.c
@@ -49,6 +49,11 @@
 #define ahci_debug(ahci, fmt, arg...) \
 	dev_dbg(ahci->dev, fmt, ##arg)
 
+#define ATA_CMD_FLUSH_EXT 0xEA
+#define ATA_CMD_STANDBYNOW1 0xE0
+
+static LIST_HEAD(ahci_devices);
+
 static const struct pci_device_id ahci_pci_tbl[] = {
 	{ PCI_DEVICE(PCI_VENDOR_ID_MARVELL_EXT, 0x9170) },
 	{ 0, }
@@ -691,47 +696,6 @@ static void ahci_port_shutdown(struct ahci_port *port)
 		ahci_port_info(port, "STANDBY IMMEDIATE failed\n");
 }
 
-/* Full poweroff sequence */
-static void ahci_poweroff(struct poweroff_handler *handler, unsigned long flags)
-{
-	struct ahci_device *ahci;
-	int i, n_ports;
-
-	list_for_each_entry(ahci, &ahci_devices, list) {
-
-		if (!ahci->mmio_base)
-			continue;
-
-		/* FLUSH + STANDBY on all active ports */
-		n_ports = max_t(int, ahci->n_ports, fls(ahci->port_map));
-
-		for (i = 0; i < n_ports; i++) {
-			struct ahci_port *port = &ahci->ports[i];
-
-			if (!(ahci->port_map & (1 << i)))
-				continue;
-
-			ahci_port_shutdown(port);
-		}
-
-		/* (optional) shutsown controller after commands
-		* ahci_shutdown_host(ahci);
-		*/
-	}
-}
-
-static struct poweroff_handler ahci_po_handler = {
-	.poweroff = ahci_poweroff,
-	.priority = 200,   /* higher than gpio-poweroff */
-};
-
-static int ahci_register_poweroff(void)
-{
-	poweroff_handler_register(&ahci_po_handler);
-	return 0;
-}
-postcore_initcall(ahci_register_poweroff);
-
 static __maybe_unused struct of_device_id ahci_dt_ids[] = {
 	{
 		.compatible = "calxeda,hb-ahci",

-- 
2.47.3

