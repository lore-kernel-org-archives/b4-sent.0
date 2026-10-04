From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sun, 04 Oct 2026 21:22:36 +0200
Subject: [PATCH u-boot 4/8] ufs: add CONFIG_UFS_RESTRICT_TX_LANES
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261004-b4-ufs-sony-v1-4-54e71c95ba62@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791141780; l=2153;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=FTI5xYw1z/BewAVGIYfLfALDiWPTsnJhZaaKA4sllzY=;
 b=O/YEMpqMSysfNs3B88QX1ZmllpqFahoApTXj+hxJBbtBmAFH9OeaICcWC6NMbKRhCYaLTLO75
 N2hMWUUTuYxCo0xpxwJnxXwSVKP640NvHle0T6CZd5t4ymGU1nBNRX1
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add CONFIG_UFS_RESTRICT_TX_LANES, to restrict the amount
PA_AVAILTXDATALANES = 1 at the start of ufshcd_link_startup().

Some platforms (notably the Sony Yoshino/Tama families on MSM8998 /
SDM845) have only a single reliably-usable UFS TX lane.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 drivers/ufs/Kconfig      | 14 ++++++++++++++
 drivers/ufs/ufs-uclass.c | 13 +++++++++++++
 2 files changed, 27 insertions(+)

diff --git a/drivers/ufs/Kconfig b/drivers/ufs/Kconfig
index 49472933de3..266e7180152 100644
--- a/drivers/ufs/Kconfig
+++ b/drivers/ufs/Kconfig
@@ -8,6 +8,20 @@ config UFS
 	  This selects support for Universal Flash Subsystem (UFS).
 	  Say Y here if you want UFS Support.
 
+config UFS_RESTRICT_TX_LANES
+	bool "Restrict the number of UFS TX lanes to 1"
+	depends on UFS
+	default n
+	help
+	  Say Y here to restrict the number of UFS TX lanes to 1. This saves
+	  power at the cost of write performance.
+
+	  This is useful (and on some devices required) for platforms such as
+	  the Sony Yoshino/Tama families where only a single TX lane is
+	  reliably usable.
+
+	  If unsure, say N.
+
 config UFS_AMD_VERSAL2
 	bool "AMD Versal Gen 2 UFS controller platform driver"
 	depends on UFS && ZYNQMP_FIRMWARE
diff --git a/drivers/ufs/ufs-uclass.c b/drivers/ufs/ufs-uclass.c
index fdf62a69c02..977ffebc21f 100644
--- a/drivers/ufs/ufs-uclass.c
+++ b/drivers/ufs/ufs-uclass.c
@@ -508,6 +508,19 @@ static int ufshcd_link_startup(struct ufs_hba *hba)
 	int ret;
 	int retries = DME_LINKSTARTUP_RETRIES;
 
+	if (IS_ENABLED(CONFIG_UFS_RESTRICT_TX_LANES)) {
+		/*
+		 * Restrict the number of available TX lanes to 1. This saves
+		 * power at the cost of write performance and is required on
+		 * some platforms (e.g. Sony Yoshino/Tama) where only a single
+		 * TX lane is reliably usable.
+		 */
+		ret = ufshcd_dme_set(hba, UIC_ARG_MIB(PA_AVAILTXDATALANES), 1);
+		if (ret)
+			dev_warn(hba->dev, "%s: failed to restrict TX lanes: %d\n",
+				 __func__, ret);
+	}
+
 	do {
 		ret = ufshcd_ops_link_startup_notify(hba, PRE_CHANGE);
 		if (ret)

-- 
2.55.0

