From: Luca Lauro <famlauro93l@gmail.com>
Date: Sun, 02 Aug 2026 15:16:30 +0200
Subject: [PATCH v3 14/15] ata: ahci: add shutdown helpers for AHCI
 controllers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-rn102-rn104-series-v3-14-f7685a279fb5@gmail.com>
References: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
In-Reply-To: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785676614; l=2392;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=BMPMiscMovgAgnONTNzG4eiPp/a1cSuATP636hFCgHQ=;
 b=7r1BPPOcIB8vegNh/e3KWFQbk+RuqlmKS1PzXEZXX1nzgevJy14y+c18jHtXKxBNVfyWf9KL+
 9PLm31seOLKAuJamxGNSUcGB65UhMHSYxh+x/Dnl/6OQfoFNgUOFzME
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce helper functions to stop the DMA engine and FIS receive engine
before shutdown. These helpers mirror the libata shutdown sequence and
ensure that no AHCI activity is in progress when the system powers off.

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 drivers/ata/ahci.c | 60 ++++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 60 insertions(+)

diff --git a/drivers/ata/ahci.c b/drivers/ata/ahci.c
index a9a3f43f21..e9e73069c1 100644
--- a/drivers/ata/ahci.c
+++ b/drivers/ata/ahci.c
@@ -21,6 +21,7 @@
 #include <linux/sizes.h>
 #include <linux/pci.h>
 #include <clock.h>
+#include <poweroff.h>
 
 #include "ahci.h"
 
@@ -683,6 +684,65 @@ static int ahci_probe(struct device *dev)
 	return ret;
 }
 
+/* -------------------------------- */
+/*		AHCI shutdown helpers		*/
+/* -------------------------------- */
+
+/* Stop DMA engine (clear START, wait LIST_ON=0) */
+static int ahci_stop_engine(struct ahci_port *port)
+{
+	u32 cmd;
+
+	cmd = ahci_port_read(port, PORT_CMD);
+
+	/* Already stopped? */
+	if (!(cmd & (PORT_CMD_START | PORT_CMD_LIST_ON)))
+		return 0;
+
+	/* Clear START */
+	cmd &= ~PORT_CMD_START;
+	ahci_port_write_f(port, PORT_CMD, cmd);
+
+	/* Wait for LIST_ON to clear */
+	return wait_on_timeout(500 * MSECOND,
+		!(ahci_port_read(port, PORT_CMD) & PORT_CMD_LIST_ON));
+}
+
+/* Stop FIS receive engine (clear FIS_RX, wait FIS_ON=0) */
+static int ahci_stop_fis_rx(struct ahci_port *port)
+{
+	u32 cmd;
+
+	cmd = ahci_port_read(port, PORT_CMD);
+	cmd &= ~PORT_CMD_FIS_RX;
+	ahci_port_write_f(port, PORT_CMD, cmd);
+
+	/* Wait for FIS_ON to clear */
+	return wait_on_timeout(1000 * MSECOND,
+		!(ahci_port_read(port, PORT_CMD) & PORT_CMD_FIS_ON));
+}
+
+/* Stop all ports (libata_pci_shutdown_one equivalent) */
+static void __maybe_unused ahci_shutdown_host(struct ahci_device *ahci)
+{
+	int i, n_ports;
+
+	n_ports = max_t(int, ahci->n_ports, fls(ahci->port_map));
+
+	for (i = 0; i < n_ports; i++) {
+		struct ahci_port *port = &ahci->ports[i];
+
+		if (!(ahci->port_map & (1 << i)))
+			continue;
+
+		/* Stop DMA engine */
+		ahci_stop_engine(port);
+
+		/* Stop FIS receive engine */
+		ahci_stop_fis_rx(port);
+	}
+}
+
 /* Issue FLUSH EXT + STANDBY IMMEDIATE */
 static void ahci_port_shutdown(struct ahci_port *port)
 {

-- 
2.47.3

