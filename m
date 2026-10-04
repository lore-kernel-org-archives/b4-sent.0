From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sun, 04 Oct 2026 21:22:38 +0200
Subject: [PATCH u-boot 6/8] ufs: print device information at probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261004-b4-ufs-sony-v1-6-54e71c95ba62@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791141780; l=2712;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=QupSv/OYoIZpSqpoakOWBMqt+riZ+H1acPCcpQ7fYWU=;
 b=8TDvnoydVNdNrlVekS+dkYI73k3h6e08pzwHj3ozFFdFGngrUHAEyZbLVaB4gyppVQNcA/jQA
 +y+wAf6zCmeAd7BnTvYuPw5EF28WIkxo+rAwJwkJQLKBG8Em0ljoxDS
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Dump the key UFS device properties (manufacturer, model, fw revision,
spec version, negotiated gear/lane/power, and the applied device quirks)
at the end of ufs_start().

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 drivers/ufs/ufs-uclass.c | 54 ++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 54 insertions(+)

diff --git a/drivers/ufs/ufs-uclass.c b/drivers/ufs/ufs-uclass.c
index 7dfba3ac1ac..3cc4fd6bde3 100644
--- a/drivers/ufs/ufs-uclass.c
+++ b/drivers/ufs/ufs-uclass.c
@@ -2218,6 +2218,58 @@ static void ufshcd_def_desc_sizes(struct ufs_hba *hba)
 	hba->desc_size.hlth_desc = QUERY_DESC_HEALTH_DEF_SIZE;
 }
 
+/* Map a JEDEC UFS manufacturer id to a human-readable vendor name */
+static const char *ufshcd_vendor_name(u16 mid)
+{
+	switch (mid) {
+	case UFS_VENDOR_TOSHIBA:	return "Toshiba/Kioxia";
+	case UFS_VENDOR_SAMSUNG:	return "Samsung";
+	case UFS_VENDOR_SKHYNIX:	return "SK Hynix";
+	case UFS_VENDOR_MICRON:		return "Micron";
+	case UFS_VENDOR_WDC:		return "Western Digital";
+	default:			return NULL;
+	}
+}
+
+static void ufshcd_rtrim(char *s)
+{
+	size_t n = strlen(s);
+
+	while (n && s[n - 1] == ' ')
+		s[--n] = '\0';
+}
+
+static void ufshcd_print_dev_info(struct ufs_hba *hba,
+				  struct ufs_dev_desc *card)
+{
+	const char *vendor = ufshcd_vendor_name(card->wmanufacturerid);
+
+	ufshcd_rtrim(card->model);
+	ufshcd_rtrim(card->revision);
+
+	printf("UFS Device Information (%s)\n", hba->dev->name);
+	if (vendor)
+		printf("  Manufacturer:    %s (0x%04x)\n", vendor,
+		       card->wmanufacturerid);
+	else
+		printf("  Manufacturer ID: 0x%04x\n", card->wmanufacturerid);
+	printf("  Model:           %s\n",
+	       card->model[0] ? card->model : "(unset)");
+	printf("  Revision:        %s\n",
+	       card->revision[0] ? card->revision : "(unset)");
+	printf("  Spec Version:    0x%04x\n", card->wspecversion);
+	printf("  Gear  - RX: %u, TX: %u\n",
+	       hba->pwr_info.gear_rx, hba->pwr_info.gear_tx);
+	printf("  Lane  - RX: %u, TX: %u\n",
+	       hba->pwr_info.lane_rx, hba->pwr_info.lane_tx);
+	printf("  Power - RX: %u, TX: %u, HS rate: %u\n",
+	       hba->pwr_info.pwr_rx, hba->pwr_info.pwr_tx,
+	       hba->pwr_info.hs_rate);
+	printf("  Device Quirks:   0x%08x\n", hba->dev_quirks);
+	printf("  NO_PURGE Quirk:  %s\n",
+	       (hba->dev_quirks & UFS_DEVICE_QUIRK_NO_PURGE) ? "Yes" : "No");
+}
+
 static int ufs_start(struct ufs_hba *hba)
 {
 	struct ufs_dev_desc card = {0};
@@ -2268,6 +2320,8 @@ static int ufs_start(struct ufs_hba *hba)
 		ufshcd_print_pwr_info(hba);
 	}
 
+	ufshcd_print_dev_info(hba, &card);
+
 	return 0;
 }
 

-- 
2.55.0

