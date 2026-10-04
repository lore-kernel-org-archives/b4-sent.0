From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sun, 04 Oct 2026 21:22:35 +0200
Subject: [PATCH u-boot 3/8] ufs: program extended HS sync length for SK
 Hynix devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261004-b4-ufs-sony-v1-3-54e71c95ba62@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791141780; l=2751;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=+Ga7wnGJh3+7X1gT9+waTxAF3OMEBshDXzDZErbQz4g=;
 b=oX5AGAFhQmEhQ0p3R0VPx14L7h0507nFTUQXiq26KoalvcC0E2xcH71eThgvMacydnFgBnmqJ
 R5KEQu1E43fBUcRvxguLk9kp8jWk3ty4TXDUF35VYeJDAjixMymgDDa
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the UFS_DEVICE_QUIRK_EXTEND_SYNC_LENGTH bit. SK Hynix UFS devices
on the Sony Yoshino/Tama (MSM8998 / SDM845) family need
PA_TxHsG{1,2,3}SyncLength programmed to 0x48 before the power-mode
change for a reliable HS link; without it link bring-up fails or the
device falls back to a slow PWM mode.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 drivers/ufs/ufs-uclass.c | 9 +++++++++
 drivers/ufs/ufs_quirks.h | 7 +++++++
 drivers/ufs/unipro.h     | 3 +++
 3 files changed, 19 insertions(+)

diff --git a/drivers/ufs/ufs-uclass.c b/drivers/ufs/ufs-uclass.c
index 05b95c510b4..fdf62a69c02 100644
--- a/drivers/ufs/ufs-uclass.c
+++ b/drivers/ufs/ufs-uclass.c
@@ -1872,6 +1872,9 @@ out:
  * fw revision; UFS_ANY_VENDOR / UFS_ANY_MODEL / UFS_ANY_VER act as wildcards.
  */
 static const struct ufs_dev_quirk ufs_fixups[] = {
+	/* SK Hynix devices need an extended HS sync length */
+	UFS_FIX(UFS_VENDOR_SKHYNIX, UFS_ANY_MODEL,
+		UFS_DEVICE_QUIRK_EXTEND_SYNC_LENGTH),
 	/* Sony Yoshino/Tama: block PURGE/UNMAP to avoid bricking */
 	UFS_FIX_REVISION(UFS_VENDOR_SKHYNIX, UFS_MODEL_HYNIX_32GB,
 			 UFS_REVISION_HYNIX, UFS_DEVICE_QUIRK_NO_PURGE),
@@ -2108,6 +2111,12 @@ static int ufshcd_change_power_mode(struct ufs_hba *hba,
 		ufshcd_dme_set(hba, UIC_ARG_MIB(PA_HSSERIES),
 			       pwr_mode->hs_rate);
 
+	if (hba->dev_quirks & UFS_DEVICE_QUIRK_EXTEND_SYNC_LENGTH) {
+		ufshcd_dme_set(hba, UIC_ARG_MIB(PA_TxHsG1SyncLength), 0x48);
+		ufshcd_dme_set(hba, UIC_ARG_MIB(PA_TxHsG2SyncLength), 0x48);
+		ufshcd_dme_set(hba, UIC_ARG_MIB(PA_TxHsG3SyncLength), 0x48);
+	}
+
 	ret = ufshcd_uic_change_pwr_mode(hba, pwr_mode->pwr_rx << 4 |
 					 pwr_mode->pwr_tx);
 
diff --git a/drivers/ufs/ufs_quirks.h b/drivers/ufs/ufs_quirks.h
index f5aa47722db..822315cb06d 100644
--- a/drivers/ufs/ufs_quirks.h
+++ b/drivers/ufs/ufs_quirks.h
@@ -84,4 +84,11 @@ struct ufs_dev_quirk {
  */
 #define UFS_DEVICE_QUIRK_NO_PURGE		BIT(0)
 
+/*
+ * Some SK Hynix devices on Sony Yoshino/Tama need an extended HS sync length
+ * (PA_TxHsG{1,2,3}SyncLength) programmed before the power-mode change for a
+ * reliable HS link.
+ */
+#define UFS_DEVICE_QUIRK_EXTEND_SYNC_LENGTH	BIT(1)
+
 #endif /* _UFS_QUIRKS_H */
diff --git a/drivers/ufs/unipro.h b/drivers/ufs/unipro.h
index bde1490397c..4e163da0736 100644
--- a/drivers/ufs/unipro.h
+++ b/drivers/ufs/unipro.h
@@ -118,6 +118,9 @@
 #define PA_TXGEAR		0x1568
 #define PA_TXTERMINATION	0x1569
 #define PA_HSSERIES		0x156A
+#define PA_TxHsG1SyncLength	0x1552
+#define PA_TxHsG2SyncLength	0x1554
+#define PA_TxHsG3SyncLength	0x1556
 #define PA_LEGACYDPHYESCDL	0x1570
 #define PA_PWRMODE		0x1571
 #define PA_ACTIVERXDATALANES	0x1580

-- 
2.55.0

