From: Federico Amedeo Izzo <federico@izzo.pro>
Date: Thu, 21 May 2026 22:16:20 +0200
Subject: [PATCH v2] ufs: qcom: Add UFS host regulator support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260521-qcom-ufs-regulator-support-v2-1-d3ec82ae5dbc@izzo.pro>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1XNQQ6CMBCF4auQrh0DBZG48h7GRe1MoUZpnbbEQ
 Li7RVcu/+Tle4sIxJaCOBWLYJpssG7MIXeF0IMaewKLuYUsZVseZAUv7Z6QTACmPj1UdAwhee8
 4QtO2pFqFeatEBjyTse8vfrn+OqTbnXTcxG1hOGNxYFL/J+gTKETA4D30GpDtRAxTBRV0dX2UT
 ddp1OZs59ntPTuxrh9Iw7PsywAAAA==
X-Change-ID: 20260521-qcom-ufs-regulator-support-466ea6ad202a
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Casey Connolly <casey.connolly@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Federico Amedeo Izzo <federico@izzo.pro>, 
 Julien Stephan <jstephan@baylibre.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779394603; l=3997;
 i=federico@izzo.pro; s=20251017; h=from:subject:message-id;
 bh=n9zA7PH5eaQbumdqEdR81CJMKEo9ct0tpo7AFozb5FQ=;
 b=JR13+nqniBMYkd6FprOTgDcjTqqHB3MBuTHWKLozMaWUjUOGS3H7eCGcNY5DFEO5Mq5Wdv8jO
 ZmjSLXDuNcfA/kKlFqghBHHHXuX9cVxwzs3Ch8DbF3x+FeZexnsBcII
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
Add support to qcom-ufs driver for vcc-supply and vccq-supply
regulators to enable UFS support on SC7280 devices with UFS3.1.
SC7280 devices with UFS2.2 were already working.

The root cause was ABL leaving vcc-supply regulator disabled on UFS3.1
devices, and enabled on UFS2.2 devices that worked fine without
regulator support.

The tricky part was enabling the regulator in HPM mode (3), which required
setting LPM mode (1) first, otherwise reg would stay in LPM mode.
I discovered this by changing the regulator settings from U-Boot
console. Enabling the regulator in LPM mode resets the phone.
---
Changes in v2:
- Add vccq2-supply for UFS2.2 devices without internal eLDO regulator
- Fix wrong topic
- Link to v1: https://patch.msgid.link/20260521-dpu-add-dspp-gc-driver-v1-1-83372488cdcf@izzo.pro
---
 drivers/ufs/ufs-qcom.c | 29 ++++++++++++++++++++++++++++-
 drivers/ufs/ufs-qcom.h |  4 ++++
 2 files changed, 32 insertions(+), 1 deletion(-)

diff --git a/drivers/ufs/ufs-qcom.c b/drivers/ufs/ufs-qcom.c
index dc40ee62daf..f21b8945e46 100644
--- a/drivers/ufs/ufs-qcom.c
+++ b/drivers/ufs/ufs-qcom.c
@@ -16,6 +16,7 @@
 #include <generic-phy.h>
 #include <asm/gpio.h>
 #include <interconnect.h>
+#include <power/regulator.h>
 
 #include <linux/bitops.h>
 #include <linux/delay.h>
@@ -557,10 +558,25 @@ static void ufs_qcom_dev_ref_clk_ctrl(struct ufs_hba *hba, bool enable)
 static int ufs_qcom_init(struct ufs_hba *hba)
 {
 	struct ufs_qcom_priv *priv = dev_get_priv(hba->dev);
-	int err;
+	int ret, err;
 
 	priv->hba = hba;
 
+	/* Set regulator to LPM mode first otherwise HPM does not get applied */
+	ret = regulator_set_mode(priv->vcc, 1);
+	ret = regulator_set_mode(priv->vcc, 3);
+	ret = regulator_set_enable(priv->vcc, true);
+	if (ret && ret != -ENOSYS)
+		dev_warn(hba->dev, "failed to enable regulator vcc-supply:%d\n", ret);
+
+	ret = regulator_set_enable(priv->vccq, true);
+	if (ret && ret != -ENOSYS)
+		dev_warn(hba->dev, "failed to enable regulator vccq-supply:%d\n", ret);
+
+	ret = regulator_set_enable(priv->vccq2, true);
+	if (ret && ret != -ENOSYS)
+		dev_warn(hba->dev, "failed to enable regulator vccq2-supply:%d\n", ret);
+
 	/* setup clocks */
 	ufs_qcom_setup_clocks(hba, true, PRE_CHANGE);
 
@@ -651,6 +667,17 @@ static int ufs_qcom_probe(struct udevice *dev)
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

---
base-commit: 744cf5d4e398c5f657e5c3eeb44d00fa5175dc85
change-id: 20260521-qcom-ufs-regulator-support-466ea6ad202a

Best regards,
--  
Federico Amedeo Izzo <federico@izzo.pro>

