From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sun, 04 Oct 2026 21:22:37 +0200
Subject: [PATCH u-boot 5/8] scsi: ufs: refuse erase/UNMAP on NO_PURGE
 devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261004-b4-ufs-sony-v1-5-54e71c95ba62@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791141780; l=2283;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=6DAUFUAuX1kh2EGKP1zZL/kXMWnZ7K3mF+wCJzqM3dU=;
 b=Ut927M9BiT1NPo6Nh2l1okrMvskxdhzJMVL35MAcgfIyhwmuwG+cruu4TVWm1yBKApEJ+adE1
 SWVhUXsQT9HBtikSNFSeBYALm289PVEJUAExxBGyYMkKYl1LCTLlR8p
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enforce the UFS_DEVICE_QUIRK_NO_PURGE quirk on U-Boot's only path that
can reach a UFS device with a destructive UNMAP: the block-device erase
op (scsi_erase() -> SCSI_UNMAP). On Sony Yoshino/Tama a PURGE/UNMAP
erases the bootloader and permanently bricks the device.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 drivers/scsi/scsi.c      |  5 +++++
 drivers/ufs/ufs-uclass.c | 12 ++++++++++++
 include/scsi.h           |  5 +++++
 3 files changed, 22 insertions(+)

diff --git a/drivers/scsi/scsi.c b/drivers/scsi/scsi.c
index 50e7d749921..ba7834ea035 100644
--- a/drivers/scsi/scsi.c
+++ b/drivers/scsi/scsi.c
@@ -300,6 +300,11 @@ static ulong scsi_erase(struct udevice *dev, lbaint_t blknr, lbaint_t blkcnt)
 	lbaint_t start, blks, max_blks, blocks;
 	struct scsi_cmd *pccb = (struct scsi_cmd *)&tempccb;
 
+	if (uc_plat->no_erase) {
+		printf("%s: erase not supported on this device\n", __func__);
+		return 0;
+	}
+
 	/* Setup device */
 	pccb->target = block_dev->target;
 	pccb->lun = block_dev->lun;
diff --git a/drivers/ufs/ufs-uclass.c b/drivers/ufs/ufs-uclass.c
index 977ffebc21f..7dfba3ac1ac 100644
--- a/drivers/ufs/ufs-uclass.c
+++ b/drivers/ufs/ufs-uclass.c
@@ -2366,6 +2366,18 @@ int ufshcd_probe(struct udevice *ufs_dev, struct ufs_hba_ops *hba_ops)
 	if (err)
 		return err;
 
+	/*
+	 * Some devices must never receive a PURGE / UNMAP (secure erase): on
+	 * the affected platforms it erases the bootloader and permanently
+	 * bricks the device. Disable the SCSI erase op for the whole UFS
+	 * device in that case.
+	 */
+	if (hba->dev_quirks & UFS_DEVICE_QUIRK_NO_PURGE) {
+		scsi_plat->no_erase = true;
+		dev_info(hba->dev,
+			 "NO_PURGE quirk active: SCSI erase/UNMAP disabled\n");
+	}
+
 	return 0;
 }
 
diff --git a/include/scsi.h b/include/scsi.h
index 2520a8b8fe6..fc296285dd5 100644
--- a/include/scsi.h
+++ b/include/scsi.h
@@ -275,6 +275,11 @@ struct scsi_plat {
 	unsigned long max_lun;
 	unsigned long max_id;
 	unsigned long max_bytes_per_req;
+	/*
+	 * Set by the controller driver to forbid the erase (UNMAP) operation,
+	 * e.g. for UFS devices whose PURGE/UNMAP would erase the bootloader.
+	 */
+	bool no_erase;
 };
 
 /* Operations for SCSI */

-- 
2.55.0

