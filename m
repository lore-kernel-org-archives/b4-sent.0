From: Luca Lauro <famlauro93l@gmail.com>
Date: Sun, 02 Aug 2026 15:16:29 +0200
Subject: [PATCH v3 13/15] ata: ahci: add FLUSH EXT and STANDBY IMMEDIATE
 support during shutdown
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-rn102-rn104-series-v3-13-f7685a279fb5@gmail.com>
References: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
In-Reply-To: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785676613; l=2481;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=T34Iau6B1i8z0A6pC6fbqFrYkore0PACx4qG1mlBxKM=;
 b=WqsUhhnpNUC7/4ufNipUfuTgWBywUOcPwZEGVHZJR5LSVT1sDIwcfWOHsDR0JZABte0u5Y6g/
 xODpyVdmKbHDe5uLjVcVDIaRjZAl1pdNwu1jcKkHV6b+IgBzly2j0z0
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some AHCI controllers require ATA FLUSH EXT and STANDBY IMMEDIATE to be
issued before poweroff to ensure data integrity and proper device
shutdown. This patch introduces ahci_port_shutdown(), which sends these
commands using ahci_ata_nodata(), and integrates it into a new AHCI
poweroff handler.

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 drivers/ata/ahci.c | 60 ++++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 60 insertions(+)

diff --git a/drivers/ata/ahci.c b/drivers/ata/ahci.c
index 2504f4d19a..a9a3f43f21 100644
--- a/drivers/ata/ahci.c
+++ b/drivers/ata/ahci.c
@@ -48,6 +48,9 @@
 #define ahci_debug(ahci, fmt, arg...) \
 	dev_dbg(ahci->dev, fmt, ##arg)
 
+#define ATA_CMD_FLUSH_EXT 0xEA
+#define ATA_CMD_STANDBYNOW1 0xE0
+
 #ifndef PCI_VENDOR_ID_MARVELL_EXT
 #define PCI_VENDOR_ID_MARVELL_EXT 0x1b4b
 #endif
@@ -680,6 +683,63 @@ static int ahci_probe(struct device *dev)
 	return ret;
 }
 
+/* Issue FLUSH EXT + STANDBY IMMEDIATE */
+static void ahci_port_shutdown(struct ahci_port *port)
+{
+	if (!port->cmd_tbl || !port->cmd_slot)
+		return;
+
+	if (!ahci_link_ok(port, 0))
+		return;
+
+	if (ahci_ata_nodata(port, ATA_CMD_FLUSH_EXT, 0))
+		ahci_port_info(port, "FLUSH EXT failed\n");
+
+	if (ahci_ata_nodata(port, ATA_CMD_STANDBYNOW1, 0))
+		ahci_port_info(port, "STANDBY IMMEDIATE failed\n");
+}
+
+/* Full poweroff sequence */
+static void ahci_poweroff(struct poweroff_handler *handler, unsigned long flags)
+{
+	struct ahci_device *ahci;
+	int i, n_ports;
+
+	list_for_each_entry(ahci, &ahci_devices, list) {
+
+		if (!ahci->mmio_base)
+			continue;
+
+		/* FLUSH + STANDBY on all active ports */
+		n_ports = max_t(int, ahci->n_ports, fls(ahci->port_map));
+
+		for (i = 0; i < n_ports; i++) {
+			struct ahci_port *port = &ahci->ports[i];
+
+			if (!(ahci->port_map & (1 << i)))
+				continue;
+
+			ahci_port_shutdown(port);
+		}
+
+		/* (optional) shutsown controller after commands
+		* ahci_shutdown_host(ahci);
+		*/
+	}
+}
+
+static struct poweroff_handler ahci_po_handler = {
+	.poweroff = ahci_poweroff,
+	.priority = 200,   /* higher than gpio-poweroff */
+};
+
+static int ahci_register_poweroff(void)
+{
+	poweroff_handler_register(&ahci_po_handler);
+	return 0;
+}
+postcore_initcall(ahci_register_poweroff);
+
 static __maybe_unused struct of_device_id ahci_dt_ids[] = {
 	{
 		.compatible = "calxeda,hb-ahci",

-- 
2.47.3

