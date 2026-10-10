From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 10 Oct 2026 23:07:54 +0200
Subject: [PATCH 06/11] cmd: phonemenu: read the A/B slot on Snapdragon
 without "misc"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-phonemenu-series-v1-6-bfa23de6eb0b@protonmail.com>
References: <20261010-b4-phonemenu-series-v1-0-bfa23de6eb0b@protonmail.com>
In-Reply-To: <20261010-b4-phonemenu-series-v1-0-bfa23de6eb0b@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, 
 "Kory Maincent (TI.com)" <kory.maincent@bootlin.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Michael Trimarchi <michael@amarulasolutions.com>, 
 Mikhail Kshevetskiy <mikhail.kshevetskiy@iopsys.eu>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Frank Wunderlich <frank-w@public-files.de>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Heiko Schocher <hs@nabladev.com>, 
 Andrew Goodbody <andrew.goodbody@linaro.org>, 
 Julien Stephan <jstephan@baylibre.com>, 
 Peter Robinson <pbrobinson@gmail.com>, Brian Sune <briansune@gmail.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Anatolij Gustschin <ag.dev.uboot@gmail.com>, Petr Pavlata <petr@acrux.cz>, 
 David Heidelberg <david@ixit.cz>, 
 =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791666485; l=2210;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=cCQTs89iJndVMQmPdK8pwsF9GljpgofHT26OXllY6lI=;
 b=+739HSpKLV8UKpSy7KMnYpX1O2S5PBZTxQ/mHHwiXUzxt8/ssqELItCeRprsm037cxxHAniwJ
 R51AEke2zfCC9IQjZhja4vc+t6B/8zkLs5vxR4Lhwd2knDmsVL4nBVd
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Snapdragon keeps the slot state in the boot_a/boot_b GPT attribute
flags, handled by ab_select_slot(), so no "misc" partition is needed.
Override phonemenu_ab_slot() in a new Qualcomm specific file so the
generic code does not require one.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 MAINTAINERS          |  1 +
 cmd/Makefile         |  2 +-
 cmd/phonemenu_qcom.c | 28 ++++++++++++++++++++++++++++
 3 files changed, 30 insertions(+), 1 deletion(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 8734a683221..e4c108a0412 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -689,6 +689,7 @@ S:	Maintained
 T:	git https://source.denx.de/u-boot/custodians/u-boot-snapdragon.git
 F:	cmd/phone_util.c
 F:	cmd/phonemenu.c
+F:	cmd/phonemenu_qcom.c
 F:	include/phonemenu.h
 F:	configs/qcm6490_defconfig
 F:	configs/qcs9100_defconfig
diff --git a/cmd/Makefile b/cmd/Makefile
index 913d94abdb2..2fb613228f6 100644
--- a/cmd/Makefile
+++ b/cmd/Makefile
@@ -36,7 +36,7 @@ obj-$(CONFIG_CMD_BMP) += bmp.o
 obj-$(CONFIG_CMD_BOOTCOUNT) += bootcount.o
 obj-$(CONFIG_CMD_BOOTEFI) += bootefi.o
 obj-$(CONFIG_CMD_BOOTMENU) += bootmenu.o
-obj-$(CONFIG_CMD_PHONEMENU) += phone_util.o phonemenu.o
+obj-$(CONFIG_CMD_PHONEMENU) += phone_util.o phonemenu.o phonemenu_qcom.o
 obj-$(CONFIG_CMD_BOOTSTAGE) += bootstage.o
 obj-$(CONFIG_CMD_BOOTZ) += bootz.o
 obj-$(CONFIG_CMD_BOOTI) += booti.o
diff --git a/cmd/phonemenu_qcom.c b/cmd/phonemenu_qcom.c
new file mode 100644
index 00000000000..d8a295c10dc
--- /dev/null
+++ b/cmd/phonemenu_qcom.c
@@ -0,0 +1,28 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Qualcomm specific header information for phonemenu.
+ */
+
+#include <android_ab.h>
+#include <blk.h>
+#include <part.h>
+#include <phonemenu.h>
+#include <linux/errno.h>
+
+#if IS_ENABLED(CONFIG_ARCH_SNAPDRAGON)
+
+/*
+ * Slot state comes from the boot_a/boot_b GPT attribute flags
+ */
+int phonemenu_ab_slot(void)
+{
+	struct blk_desc *desc = phonemenu_storage_desc();
+	struct disk_partition unused = { 0 };
+
+	if (!desc)
+		return -ENODEV;
+
+	return ab_select_slot(desc, &unused, false);
+}
+
+#endif /* CONFIG_ARCH_SNAPDRAGON */

-- 
2.55.0

