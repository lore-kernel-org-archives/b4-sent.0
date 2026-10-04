From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sun, 04 Oct 2026 21:22:39 +0200
Subject: [PATCH u-boot 7/8] ufs: gate NO_PURGE on Sony Yoshino/Tama
 platform compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261004-b4-ufs-sony-v1-7-54e71c95ba62@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791141780; l=2690;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=RB+h74HV+WqM4nRvm4AQQuePTYX+eLSW/xgpEIOW0KE=;
 b=Hkv8P2UET3iMnZtpXLd+EXZSqmiysMauD7utCRNOUlq+PURmTtwSs/fL4uCuxTwwWLGA+7R1E
 Ir/zsn/4a/UBmoo7JR0g5sRYtonJlzWOEjYi14LBSd3mH9kN9v9fxaC
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Apply NO_PURGE unconditionally on Sony Yoshino (msm8998) and Tama
(sdm845) phones, regardless of which UFS chip is fitted:

- Units across batches ship with a mix of Samsung, SK Hynix, and
  Toshiba UFS parts, so a single per-model quirk-table row can't
  cover the whole population.
- Those chips consistently leave iProductName and
  iProductRevisionLevel blank in the UFS device descriptor, which
  defeats the model/revision string match the quirk table relies on.
- The spec-version fallback (wspecversion < 0x210) has an off-by-one
  gap for these devices: they report UFS spec version 0x210 (UFS 2.1)
  exactly, which the strict "<" comparison doesn't catch.

Gate NO_PURGE on the DT root compatible instead, which is reliable
regardless of which UFS chip a given unit shipped with.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 drivers/ufs/ufs-uclass.c | 33 +++++++++++++++++++++++++++++++++
 1 file changed, 33 insertions(+)

diff --git a/drivers/ufs/ufs-uclass.c b/drivers/ufs/ufs-uclass.c
index 3cc4fd6bde3..f88949bffd3 100644
--- a/drivers/ufs/ufs-uclass.c
+++ b/drivers/ufs/ufs-uclass.c
@@ -1880,6 +1880,35 @@ out:
 	return err;
 }
 
+/*
+ * Platforms whose bootloader / RPMB layout overlaps the UFS LUN0
+ * provisioning region and cannot tolerate UNMAP/PURGE.
+ * Any erase command issued against the boot LU bricks the device. The quirk
+ * has to apply regardless of which UFS supplier is fitted (Samsung, SK Hynix
+ * or Toshiba)
+ */
+static const char * const ufs_no_purge_platforms[] = {
+	/* Sony Yoshino (msm8998): XZ1 / XZ1 Compact / XZ Premium */
+	"sony,xperia-lilac",
+	"sony,xperia-maple",
+	"sony,xperia-poplar",
+	/* Sony Tama (sdm845): XZ2 / XZ2 Compact / XZ3 */
+	"sony,akari-row",
+	"sony,akatsuki-row",
+	"sony,apollo-row",
+	NULL,
+};
+
+static bool ufshcd_platform_needs_no_purge(void)
+{
+	const char * const *p;
+
+	for (p = ufs_no_purge_platforms; *p; p++)
+		if (of_machine_is_compatible(*p))
+			return true;
+	return false;
+}
+
 /*
  * UFS device quirk table. Entries are matched by manufacturer id, model and
  * fw revision; UFS_ANY_VENDOR / UFS_ANY_MODEL / UFS_ANY_VER act as wildcards.
@@ -1916,6 +1945,10 @@ static void ufshcd_fixup_dev_quirks(struct ufs_hba *hba,
 	if (dev_desc->wspecversion < UFS_PURGE_SPEC_VER)
 		hba->dev_quirks |= UFS_DEVICE_QUIRK_NO_PURGE;
 
+	/* Platform-driven NO_PURGE */
+	if (ufshcd_platform_needs_no_purge())
+		hba->dev_quirks |= UFS_DEVICE_QUIRK_NO_PURGE;
+
 	for (f = ufs_fixups; f->quirk; f++) {
 		if ((f->wmanufacturerid == dev_desc->wmanufacturerid ||
 		     f->wmanufacturerid == UFS_ANY_VENDOR) &&

-- 
2.55.0

