From: Federico Amedeo Izzo <federico@izzo.pro>
Date: Sat, 23 May 2026 15:04:25 +0200
Subject: [PATCH v4 2/2] ufs: qcom: add ufs host regulator support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260523-qcom-ufs-regulator-support-v4-2-45639533b06d@izzo.pro>
References: <20260523-qcom-ufs-regulator-support-v4-0-45639533b06d@izzo.pro>
In-Reply-To: <20260523-qcom-ufs-regulator-support-v4-0-45639533b06d@izzo.pro>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Casey Connolly <casey.connolly@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Federico Amedeo Izzo <federico@izzo.pro>, 
 Julien Stephan <jstephan@baylibre.com>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Peng Fan <peng.fan@nxp.com>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779541471; l=2680;
 i=federico@izzo.pro; s=20251017; h=from:subject:message-id;
 bh=J7WFWpRyAfQxDHcsg9NBe0inkMTwOgLG5fNLYDlsgpw=;
 b=RWTo0LBEYhBztKRxCncIYEGrHLQltQpYHv5iZokE39in7iWgBK0OcvKUUEkpAejY7KUoo2g75
 RBlxETpsYwXDQ9J4VAbwOUUhEt+JYMsSOuZNsN60FrDDEja0eJZQesQ
X-Developer-Key: i=federico@izzo.pro; a=ed25519;
 pk=XfmNfpH48k8jLbId5NKrp0yoKoFb/uLjr97qIxBImBw=
X-Endpoint-Received: by B4 Relay for federico@izzo.pro/20251017 with auth_id=544
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The qcom UFS driver works without touching the regulators on most platforms
as ABL leaves them already configured and enabled.
On some SC7280 phones with UFS 3.1 like nothing-spacewar, vcc regulator is
not enabled by ABL, so we need to configure and enable it to use the UFS
storage.

Tested on nothing-spacewar and motorola-dubai using Tauchgang U-Boot.

Signed-off-by: Federico Amedeo Izzo <federico@izzo.pro>
---
 drivers/ufs/ufs-qcom.c | 25 +++++++++++++++++++++++++
 drivers/ufs/ufs-qcom.h |  4 ++++
 2 files changed, 29 insertions(+)

diff --git a/drivers/ufs/ufs-qcom.c b/drivers/ufs/ufs-qcom.c
index dc40ee62daf..0e2e45f1075 100644
--- a/drivers/ufs/ufs-qcom.c
+++ b/drivers/ufs/ufs-qcom.c
@@ -16,6 +16,7 @@
 #include <generic-phy.h>
 #include <asm/gpio.h>
 #include <interconnect.h>
+#include <power/regulator.h>
 
 #include <linux/bitops.h>
 #include <linux/delay.h>
@@ -561,6 +562,19 @@ static int ufs_qcom_init(struct ufs_hba *hba)
 
 	priv->hba = hba;
 
+	/* enable regulators */
+	err = regulator_set_enable(priv->vcc, true);
+	if (err && err != -ENOSYS)
+		dev_warn(hba->dev, "failed to enable regulator vcc-supply:%d\n", err);
+
+	err = regulator_set_enable(priv->vccq, true);
+	if (err && err != -ENOSYS)
+		dev_warn(hba->dev, "failed to enable regulator vccq-supply:%d\n", err);
+
+	err = regulator_set_enable(priv->vccq2, true);
+	if (err && err != -ENOSYS)
+		dev_warn(hba->dev, "failed to enable regulator vccq2-supply:%d\n", err);
+
 	/* setup clocks */
 	ufs_qcom_setup_clocks(hba, true, PRE_CHANGE);
 
@@ -651,6 +665,17 @@ static int ufs_qcom_probe(struct udevice *dev)
 		dev_err(dev, "Warning: cannot get reset GPIO\n");
 	}
 
+	ret = device_get_supply_regulator(dev, "vcc-supply", &priv->vcc);
+	if (ret)
+		dev_warn(dev, "failed to get regulator vcc-supply:%d\n", ret);
+
+	ret = device_get_supply_regulator(dev, "vccq-supply", &priv->vccq);
+	if (ret)
+		dev_warn(dev, "failed to get regulator vccq-supply:%d\n", ret);
+
+	/* vccq2 is optional on UFS2 and missing on UFS3 and later */
+	device_get_supply_regulator(dev, "vccq2-supply", &priv->vccq2);
+
 	ret = ufshcd_probe(dev, &ufs_qcom_hba_ops);
 	if (ret) {
 		dev_err(dev, "ufshcd_probe() failed, ret:%d\n", ret);
diff --git a/drivers/ufs/ufs-qcom.h b/drivers/ufs/ufs-qcom.h
index de957ae60f3..115565db7e9 100644
--- a/drivers/ufs/ufs-qcom.h
+++ b/drivers/ufs/ufs-qcom.h
@@ -134,6 +134,10 @@ struct ufs_qcom_priv {
 	struct clk_bulk clks;
 	bool is_clks_enabled;
 
+	struct udevice *vcc;
+	struct udevice *vccq;
+	struct udevice *vccq2;
+
 	struct ufs_hw_version hw_ver;
 
 	/* Reset control of HCI */

-- 
2.54.0

