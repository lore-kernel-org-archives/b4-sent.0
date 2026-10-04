From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sun, 04 Oct 2026 21:22:33 +0200
Subject: [PATCH u-boot 1/8] ufs: read product revision and spec version
 into ufs_dev_desc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261004-b4-ufs-sony-v1-1-54e71c95ba62@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791141780; l=2821;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=bXB1eDEhUhpzaOstVlaGh6u86QpZlwm7fwB+/VqgIwc=;
 b=vz+B/aqJbKtj4GvcPdlE6Af1kYjWEpPxXVNhlC/8imRFnXLu59uccszJbQ2b0zR95V/rxrtfV
 y+s3xagD4PpBtOd2lvlWVuXeJjUF+pZvKK8XPsV1FKUCX3qmMPiFNAC
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extend ufs_get_device_desc() to also fetch the device's product revision
string (PRDCT_REV) and the UFS spec version (SPEC_VER) into struct
ufs_dev_desc.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 drivers/ufs/ufs-uclass.c | 24 ++++++++++++++++++++++++
 drivers/ufs/ufs.h        |  5 +++++
 2 files changed, 29 insertions(+)

diff --git a/drivers/ufs/ufs-uclass.c b/drivers/ufs/ufs-uclass.c
index 6a51f337e47..56118a0ee46 100644
--- a/drivers/ufs/ufs-uclass.c
+++ b/drivers/ufs/ufs-uclass.c
@@ -1792,6 +1792,7 @@ static int ufs_get_device_desc(struct ufs_hba *hba,
 	int err;
 	size_t buff_len;
 	u8 model_index;
+	u8 revision_index;
 	u8 *desc_buf;
 
 	buff_len = max_t(size_t, hba->desc_size.dev_desc,
@@ -1816,7 +1817,11 @@ static int ufs_get_device_desc(struct ufs_hba *hba,
 	dev_desc->wmanufacturerid = desc_buf[DEVICE_DESC_PARAM_MANF_ID] << 8 |
 				     desc_buf[DEVICE_DESC_PARAM_MANF_ID + 1];
 
+	dev_desc->wspecversion = desc_buf[DEVICE_DESC_PARAM_SPEC_VER] << 8 |
+				  desc_buf[DEVICE_DESC_PARAM_SPEC_VER + 1];
+
 	model_index = desc_buf[DEVICE_DESC_PARAM_PRDCT_NAME];
+	revision_index = desc_buf[DEVICE_DESC_PARAM_PRDCT_REV];
 
 	/* Zero-pad entire buffer for string termination. */
 	memset(desc_buf, 0, buff_len);
@@ -1837,6 +1842,25 @@ static int ufs_get_device_desc(struct ufs_hba *hba,
 	/* Null terminate the model string */
 	dev_desc->model[MAX_MODEL_LEN] = '\0';
 
+	/* Zero-pad entire buffer for string termination. */
+	memset(desc_buf, 0, buff_len);
+
+	err = ufshcd_read_string_desc(hba, revision_index, desc_buf,
+				      QUERY_DESC_MAX_SIZE, true/*ASCII*/);
+	if (err) {
+		dev_err(hba->dev, "%s: Failed reading Product Revision. err = %d\n",
+			__func__, err);
+		goto out;
+	}
+
+	desc_buf[QUERY_DESC_MAX_SIZE] = '\0';
+	strlcpy(dev_desc->revision, (char *)(desc_buf + QUERY_DESC_HDR_SIZE),
+		min_t(u8, desc_buf[QUERY_DESC_LENGTH_OFFSET],
+		      MAX_REVISION_LEN));
+
+	/* Null terminate the revision string */
+	dev_desc->revision[MAX_REVISION_LEN] = '\0';
+
 out:
 	kfree(desc_buf);
 	return err;
diff --git a/drivers/ufs/ufs.h b/drivers/ufs/ufs.h
index 0f6c93fbce7..e3368a516e4 100644
--- a/drivers/ufs/ufs.h
+++ b/drivers/ufs/ufs.h
@@ -346,15 +346,20 @@ struct utp_upiu_rsp {
 };
 
 #define MAX_MODEL_LEN 16
+#define MAX_REVISION_LEN 4
 /**
  * ufs_dev_desc - ufs device details from the device descriptor
  *
  * @wmanufacturerid: card details
+ * @wspecversion: UFS spec version supported by the device
  * @model: card model
+ * @revision: card fw revision
  */
 struct ufs_dev_desc {
 	u16 wmanufacturerid;
+	u16 wspecversion;
 	char model[MAX_MODEL_LEN + 1];
+	char revision[MAX_REVISION_LEN + 1];
 };
 
 /* Device descriptor parameters offsets in bytes*/

-- 
2.55.0

