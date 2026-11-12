From: =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>
Date: Thu, 12 Nov 2026 11:35:28 +0100
Subject: [PATCH v2] MAINTAINERS: add entry for PEAK-System CAN drivers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261112-new_maintainers-v2-1-794b73ce8685@peak-system.fr>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNyw6CMBREf4XctTV9hIKu/A9DTIGLVEMhvRUlp
 P9uwbWLWZxk5swKhN4iwTlbweNsyY4ugTxk0PTG3ZHZNjFILrXgvGAO37fBWBdS0BNrZZFLpWr
 NTQ5pNXns7Gc3Xqsf06t+YBM2zdboLYXRL/vlLLbef/ssmGDqVKJGpYUsm8uE5slooYDDsfNQx
 Ri/etExQcUAAAA=
X-Change-ID: 20261007-new_maintainers-d275233b60a5
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, linux-can@vger.kernel.org
Cc: linux-kernel@vger.kernel.org, 
 =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794479737; l=2400;
 i=s.grosjean@peak-system.fr; s=20261020; h=from:subject:message-id;
 bh=OB+db2VoIi21gwz8pTexgzVANUMGkfO2rHGDfSfD5rA=;
 b=BFO1K/zjXKNNQZ6aHOr3bbIhTVShLtYDnzTeYuT2rVQ5psBcW94pwOXAjGVHHUA/1v+JIuw9S
 E90kTVgDzeHAOsIiTS/PijrUphG7FIkUJ2neTdD/ox3hbNVvTtr6VLX
X-Developer-Key: i=s.grosjean@peak-system.fr; a=ed25519;
 pk=bP7QV2zvvAKAfConZlUOGKGEcXL64SNUpVUm++Ai+/c=
X-Endpoint-Received: by B4 Relay for s.grosjean@peak-system.fr/20261020 with auth_id=1250
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PEAK-System CAN drivers (peak_canfd, peak_pci, peak_pcmcia and
peak_usb) are only covered by the generic CAN NETWORK DRIVERS entry, so
get_maintainer.pl doesn't Cc their author on patches and bug reports
touching them.

Add a dedicated entry. I wrote these drivers and maintain them as part
of my work at PEAK-System, where I have the hardware and the firmware
documentation needed to review and test changes. Patches keep going
through the CAN tree, the entry only makes sure they reach me.

Also list the PEAK-System Linux support address as a reviewer, so that
reports keep reaching the company if my own address ever goes stale.

Assisted-by: LLM
Signed-off-by: Stéphane Grosjean <s.grosjean@peak-system.fr>
---
v1 was only sent to LKML, because get_maintainer.pl returns nothing
else for a patch touching MAINTAINERS alone. Sorry for that; this
version is addressed to the CAN maintainers and list.
---
Changes in v2:
- Send to the CAN maintainers and linux-can (v1 only went to LKML).
- List socketcan@peak-system.fr as R: instead of M:, since it is a
  company role address kept for continuity.
- Add the peak_usb sysfs ABI documentation file.
- Reword the commit message to explain why the entry is needed.
- Link to v1: https://patch.msgid.link/20261007-new_maintainers-v1-1-398e6e36128c@peak-system.fr
---
 MAINTAINERS | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 09713dc4c6a7..567358d57d79 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -21780,6 +21780,18 @@ PDS DSC VIRTIO DATA PATH ACCELERATOR
 R:	Brett Creeley <brett.creeley@amd.com>
 F:	drivers/vdpa/pds/
 
+PEAK-SYSTEM CAN DRIVERS
+M:	Stéphane Grosjean <s.grosjean@peak-system.fr>
+R:	PEAK-System Linux support <socketcan@peak-system.fr>
+L:	linux-can@vger.kernel.org
+S:	Supported
+F:	Documentation/ABI/testing/sysfs-class-net-peak_usb
+F:	drivers/net/can/peak_canfd/
+F:	drivers/net/can/sja1000/peak_pci.c
+F:	drivers/net/can/sja1000/peak_pcmcia.c
+F:	drivers/net/can/usb/peak_usb/
+F:	include/linux/can/dev/peak_canfd.h
+
 PECI HARDWARE MONITORING DRIVERS
 M:	Iwona Winiarska <iwona.winiarska@intel.com>
 L:	linux-hwmon@vger.kernel.org

---
base-commit: 647b81ddefc6364290e67bf33c89d54971f8995e
change-id: 20261007-new_maintainers-d275233b60a5

Best regards,
-- 
Stéphane Grosjean <s.grosjean@peak-system.fr>

