From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 10 Oct 2026 23:07:52 +0200
Subject: [PATCH 04/11] boot: android_ab: read the A/B slot from the GPT on
 Snapdragon
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-phonemenu-series-v1-4-bfa23de6eb0b@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791666485; l=2142;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=//DmpccicaexghVlCBHa4ZEw776XyWUG38BTdmOwT/c=;
 b=h3jpZxqENsNLkODNvYYzin5PdF1qljqJp5cI93q0YvK/icOhsIiekPzG1fc7O7vxm6rMJktKW
 8AiHekXUXlfCDzL7xycKDJ02ccRMeM97NMLrimSaDY7aGHXHQOPRG+U
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Qualcomm devices don't use the bootloader_control block in "misc". The
slot active/unbootable state lives in the attribute flags (top 16 bits)
of each "boot_a"/"boot_b" GPT partition entry instead.

Make ab_select_slot() read those flags on CONFIG_ARCH_SNAPDRAGON.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 boot/android_ab.c | 42 ++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 42 insertions(+)

diff --git a/boot/android_ab.c b/boot/android_ab.c
index f2b1110aa24..aedeb1edf28 100644
--- a/boot/android_ab.c
+++ b/boot/android_ab.c
@@ -191,9 +191,51 @@ static int ab_compare_slots(const struct slot_metadata *a,
 	return 0;
 }
 
+/*
+ * Qualcomm devices don't use the bootloader_control_block in "misc" at all.
+ * Slot active/successful/unbootable state is stored directly in the top 16
+ * bits of each "boot_a"/"boot_b" GPT partition entry's own attribute flags.
+ */
+#define QCOM_AB_ATTR_SLOT_ACTIVE	(0x1 << 2)
+/* Not queried below, that is SBL's call */
+#define QCOM_AB_ATTR_BOOT_SUCCESSFUL	(0x1 << 6)
+#define QCOM_AB_ATTR_UNBOOTABLE		(0x1 << 7)
+
+static int qcom_gpt_select_slot(struct blk_desc *dev_desc)
+{
+	static const char * const names[] = { "boot_a", "boot_b" };
+	struct disk_partition part;
+	int slot = -1, i;
+
+	for (i = 0; i < ARRAY_SIZE(names); i++) {
+		if (part_get_info_by_name(dev_desc, names[i], &part) < 0)
+			continue;
+		if (part.type_flags & QCOM_AB_ATTR_SLOT_ACTIVE) {
+			slot = i;
+			break;
+		}
+	}
+
+	if (slot < 0) {
+		log_err("qcom A/B: no slot marked active in the GPT\n");
+		return -ENODEV;
+	}
+
+	if (part.type_flags & QCOM_AB_ATTR_UNBOOTABLE) {
+		log_err("qcom A/B: active slot %c is marked unbootable\n",
+			BOOT_SLOT_NAME(slot));
+		return -ENODEV;
+	}
+
+	return slot;
+}
+
 int ab_select_slot(struct blk_desc *dev_desc, struct disk_partition *part_info,
 		   bool dec_tries)
 {
+	if (IS_ENABLED(CONFIG_ARCH_SNAPDRAGON))
+		return qcom_gpt_select_slot(dev_desc);
+
 	struct bootloader_control *abc = NULL;
 	struct bootloader_control *backup_abc = NULL;
 	u32 crc32_le;

-- 
2.55.0

