From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sun, 04 Oct 2026 21:22:34 +0200
Subject: [PATCH u-boot 2/8] ufs: add device-quirk infrastructure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261004-b4-ufs-sony-v1-2-54e71c95ba62@protonmail.com>
References: <20261004-b4-ufs-sony-v1-0-54e71c95ba62@protonmail.com>
In-Reply-To: <20261004-b4-ufs-sony-v1-0-54e71c95ba62@protonmail.com>
To: u-boot@lists.u-boot-project.org, Sumit Garg <sumit.garg@kernel.org>, 
 u-boot-qcom@groups.io
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Casey Connolly <casey.connolly@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Angelo Gioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 David Heidelberg <david@ixit.cz>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Padmarao Begari <padmarao.begari@amd.com>, 
 Macpaul Lin <macpaul.lin@mediatek.com>, 
 Julien Stephan <jstephan@baylibre.com>, 
 Kunihiko Hayashi <hayashi.kunihiko@socionext.com>, 
 Shawn Lin <shawn.lin@rock-chips.com>, Jared McArthur <j-mcarthur@ti.com>, 
 Michal Simek <michal.simek@amd.com>, Udit Kumar <u-kumar1@ti.com>, 
 Igor Belwon <igor.belwon@mentallysanemainliners.org>, 
 Tuyen Dang <tuyen.dang.xa@renesas.com>, Alexey Charkov <alchark@gmail.com>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Simon Glass <sjg@chromium.org>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Bin Meng <bmeng.cn@gmail.com>, Marek Vasut <marek.vasut@mailbox.org>, 
 David Lechner <dlechner@baylibre.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Kory Maincent <kory.maincent@bootlin.com>, Peng Fan <peng.fan@nxp.com>, 
 Kuan-Wei Chiu <visitorckw@gmail.com>, Janne Grunau <j@jannau.net>, 
 Julien Masson <jmasson@baylibre.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Philip Molloy <philip.molloy@analog.com>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Markus Niebel <Markus.Niebel@ew.tq-group.com>, Petr Pavlata <petr@acrux.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791141780; l=6445;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=1Lha72qJKrT8yi3f7UMplATT3CjbB55Lsc65hh24lgs=;
 b=uu+dq7vpUwSeeBFeuYjTMQPHfOegDQSNGyE+IcVr/iGxTQdm96gI9FCWv2UmDVdVdT84vSTxd
 cgPw6kOtpkvAVVUXNwjMRfr16ZUX/QJEhV6CRPZuhSib8tAm3qIlcbx
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Infrastructure (ufs_quirks.h):
 - struct ufs_dev_quirk plus UFS_FIX()/UFS_FIX_REVISION() helpers.
 - ufshcd_fixup_dev_quirks() applies the table (and sets NO_PURGE for
   devices older than UFS_PURGE_SPEC_VER) from ufs_start(), before power
   mode negotiation so link quirks take effect.
 - hba gains a dev_quirks field, distinct from the host controller
   quirks (hba->quirks).

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 drivers/ufs/ufs-uclass.c | 52 +++++++++++++++++++++++++++++
 drivers/ufs/ufs.h        |  2 ++
 drivers/ufs/ufs_quirks.h | 87 ++++++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 141 insertions(+)

diff --git a/drivers/ufs/ufs-uclass.c b/drivers/ufs/ufs-uclass.c
index 56118a0ee46..05b95c510b4 100644
--- a/drivers/ufs/ufs-uclass.c
+++ b/drivers/ufs/ufs-uclass.c
@@ -29,6 +29,7 @@
 #include <linux/dma-mapping.h>
 
 #include "ufs.h"
+#include "ufs_quirks.h"
 
 #define UFSHCD_ENABLE_INTRS	(UTP_TRANSFER_REQ_COMPL |\
 				 UTP_TASK_REQ_COMPL |\
@@ -1866,6 +1867,54 @@ out:
 	return err;
 }
 
+/*
+ * UFS device quirk table. Entries are matched by manufacturer id, model and
+ * fw revision; UFS_ANY_VENDOR / UFS_ANY_MODEL / UFS_ANY_VER act as wildcards.
+ */
+static const struct ufs_dev_quirk ufs_fixups[] = {
+	/* Sony Yoshino/Tama: block PURGE/UNMAP to avoid bricking */
+	UFS_FIX_REVISION(UFS_VENDOR_SKHYNIX, UFS_MODEL_HYNIX_32GB,
+			 UFS_REVISION_HYNIX, UFS_DEVICE_QUIRK_NO_PURGE),
+	UFS_FIX_REVISION(UFS_VENDOR_SKHYNIX, UFS_MODEL_HYNIX_64GB,
+			 UFS_REVISION_HYNIX, UFS_DEVICE_QUIRK_NO_PURGE),
+	UFS_FIX_REVISION(UFS_VENDOR_SAMSUNG, UFS_MODEL_SAMSUNG_64GB,
+			 UFS_REVISION_SAMSUNG, UFS_DEVICE_QUIRK_NO_PURGE),
+	END_FIX
+};
+
+/**
+ * ufshcd_fixup_dev_quirks - apply device-specific quirks
+ *
+ * Sets hba->dev_quirks based on the UFS spec version and the per-device
+ * fixup table above.
+ */
+static void ufshcd_fixup_dev_quirks(struct ufs_hba *hba,
+				    struct ufs_dev_desc *dev_desc)
+{
+	const struct ufs_dev_quirk *f;
+
+	/*
+	 * Devices implementing an older UFS spec must not be issued PURGE /
+	 * UNMAP, doing so erases the bootloader on affected platforms.
+	 */
+	if (dev_desc->wspecversion < UFS_PURGE_SPEC_VER)
+		hba->dev_quirks |= UFS_DEVICE_QUIRK_NO_PURGE;
+
+	for (f = ufs_fixups; f->quirk; f++) {
+		if ((f->wmanufacturerid == dev_desc->wmanufacturerid ||
+		     f->wmanufacturerid == UFS_ANY_VENDOR) &&
+		    (str_prfx_equal(f->model, dev_desc->model) ||
+		     !strcmp(f->model, UFS_ANY_MODEL)) &&
+		    (str_prfx_equal(f->revision, dev_desc->revision) ||
+		     !strcmp(f->revision, UFS_ANY_VER)))
+			hba->dev_quirks |= f->quirk;
+	}
+
+	if (hba->dev_quirks)
+		dev_dbg(hba->dev, "%s: applied device quirks 0x%08x\n",
+			__func__, hba->dev_quirks);
+}
+
 struct ufs_ref_clk {
 	unsigned long freq_hz;
 	enum ufs_ref_clk_freq val;
@@ -2175,6 +2224,9 @@ static int ufs_start(struct ufs_hba *hba)
 		return ret;
 	}
 
+	/* Apply device-specific quirks before negotiating the power mode */
+	ufshcd_fixup_dev_quirks(hba, &card);
+
 	ufshcd_set_dev_ref_clk(hba);
 
 	if (ufshcd_get_max_pwr_mode(hba)) {
diff --git a/drivers/ufs/ufs.h b/drivers/ufs/ufs.h
index e3368a516e4..d4bcb7a1773 100644
--- a/drivers/ufs/ufs.h
+++ b/drivers/ufs/ufs.h
@@ -707,6 +707,8 @@ struct ufs_hba {
 	u32			version;
 	u32			intr_mask;
 	enum ufshcd_quirks	quirks;
+	/* UFS device (not host controller) quirks, see ufs_quirks.h */
+	u32			dev_quirks;
 
 	/* Virtual memory reference */
 	struct utp_transfer_cmd_desc *ucdl;
diff --git a/drivers/ufs/ufs_quirks.h b/drivers/ufs/ufs_quirks.h
new file mode 100644
index 00000000000..f5aa47722db
--- /dev/null
+++ b/drivers/ufs/ufs_quirks.h
@@ -0,0 +1,87 @@
+/* SPDX-License-Identifier: GPL-2.0+ */
+/*
+ * UFS device quirks
+ *
+ * Ported from the Linux kernel (include/ufs/ufs_quirks.h) and the
+ * Sony Yoshino/Tama downstream UFS quirks/hacks.
+ */
+#ifndef _UFS_QUIRKS_H
+#define _UFS_QUIRKS_H
+
+#include <linux/bitops.h>
+#include <linux/string.h>
+
+/* true if s1 (the fixup pattern) is a prefix of s2 (the device value) */
+static inline bool str_prfx_equal(const char *s1, const char *s2)
+{
+	return strncmp(s1, s2, strlen(s1)) == 0;
+}
+
+#define UFS_ANY_VENDOR		0xFFFF
+#define UFS_ANY_MODEL		"ANY_MODEL"
+#define UFS_ANY_VER		"ANY_VER"
+
+#define UFS_VENDOR_TOSHIBA	0x198
+#define UFS_VENDOR_SAMSUNG	0x1CE
+#define UFS_VENDOR_SKHYNIX	0x1AD
+#define UFS_VENDOR_MICRON	0x12C
+#define UFS_VENDOR_WDC		0x145
+
+/* UFS Samsung models */
+#define UFS_MODEL_SAMSUNG_64GB	"KLUDG4U1EA-B0C1"
+#define UFS_REVISION_SAMSUNG	"0100"
+
+/* UFS SK Hynix models */
+#define UFS_MODEL_HYNIX_32GB	"hB8aL1"
+#define UFS_MODEL_HYNIX_64GB	"hC8aL1"
+#define UFS_REVISION_HYNIX	"D001"
+
+/*
+ * Devices with a UFS spec version older than this must not be issued PURGE /
+ * UNMAP (secure erase) operations: on the Sony Yoshino/Tama platforms doing so
+ * erases the bootloader and permanently bricks the device.
+ */
+#define UFS_PURGE_SPEC_VER	0x210
+
+/**
+ * struct ufs_dev_quirk - ufs device quirk info
+ * @wmanufacturerid: card details (UFS_ANY_VENDOR matches any vendor)
+ * @model: card model (UFS_ANY_MODEL matches any model)
+ * @revision: card fw revision (UFS_ANY_VER matches any revision)
+ * @quirk: device quirk bitmask
+ */
+struct ufs_dev_quirk {
+	u16 wmanufacturerid;
+	const char *model;
+	const char *revision;
+	unsigned int quirk;
+};
+
+/* terminator for the fixup table */
+#define END_FIX { 0, NULL, NULL, 0 }
+
+/* add a quirk for any revision of a specific model */
+#define UFS_FIX(_vendor, _model, _quirk) {	\
+	.wmanufacturerid = (_vendor),		\
+	.model = (_model),			\
+	.revision = (UFS_ANY_VER),		\
+	.quirk = (_quirk),			\
+}
+
+/* add a quirk for a specific model and fw revision */
+#define UFS_FIX_REVISION(_vendor, _model, _revision, _quirk) {	\
+	.wmanufacturerid = (_vendor),				\
+	.model = (_model),					\
+	.revision = (_revision),				\
+	.quirk = (_quirk),					\
+}
+
+/*
+ * Some Sony UFS devices must not use the PURGE / UNMAP (secure erase)
+ * operation as it would erase the bootloader and permanently brick the
+ * device. This quirk disables PURGE-related functionality for affected
+ * devices.
+ */
+#define UFS_DEVICE_QUIRK_NO_PURGE		BIT(0)
+
+#endif /* _UFS_QUIRKS_H */

-- 
2.55.0

