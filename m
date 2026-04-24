From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Fri, 24 Apr 2026 17:45:11 +0200
Subject: [PATCH v5 3/8] firmware: meson: sm: Add thermal calibration SMC
 call
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260424-add-thermal-t7-vim4-v5-3-9040ca36afe2@aliel.fr>
References: <20260424-add-thermal-t7-vim4-v5-0-9040ca36afe2@aliel.fr>
In-Reply-To: <20260424-add-thermal-t7-vim4-v5-0-9040ca36afe2@aliel.fr>
To: Guillaume La Roque <glaroque@baylibre.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-pm@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2230;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=RboCfSHgRjly95YryQzSIFxNo4U3Gmip5nVqLI2kBVY=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ+brCb39+xXWvBRoN724JWn9M+Yq+1T7lPQCKa7zpWYac
 orZ7zd2lLIwiHExyIopsvTPtTzx7vLRM1/3qKfAzGFlAhnCwMUpABMxOMnI8HiaCpPSvq5FhXwO
 /kbKTcIHwtxPhxQkC1dmSO3gerJvKiPDEimXlqdSP2qnufzbvTYg4uvq6DkbebYv3MXGJbRs7o9
 OJgA=
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SM_THERMAL_CALIB_READ at SMC ID 0x82000047 in the command
table and implement meson_sm_get_thermal_calib(), which forwards the
tsensor_id argument to the secure monitor and returns the calibration data.

Also realign the CMD() column to improve readability.

Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 drivers/firmware/meson/meson_sm.c | 29 ++++++++++++++++++++++++-----
 1 file changed, 24 insertions(+), 5 deletions(-)

diff --git a/drivers/firmware/meson/meson_sm.c b/drivers/firmware/meson/meson_sm.c
index 3ab67aaa9e5da..4e57986724212 100644
--- a/drivers/firmware/meson/meson_sm.c
+++ b/drivers/firmware/meson/meson_sm.c
@@ -41,12 +41,13 @@ static const struct meson_sm_chip gxbb_chip = {
 	.cmd_shmem_in_base	= 0x82000020,
 	.cmd_shmem_out_base	= 0x82000021,
 	.cmd = {
-		CMD(SM_EFUSE_READ,	0x82000030),
-		CMD(SM_EFUSE_WRITE,	0x82000031),
+		CMD(SM_EFUSE_READ,		0x82000030),
+		CMD(SM_EFUSE_WRITE,		0x82000031),
 		CMD(SM_EFUSE_USER_MAX,	0x82000033),
-		CMD(SM_GET_CHIP_ID,	0x82000044),
-		CMD(SM_A1_PWRC_SET,	0x82000093),
-		CMD(SM_A1_PWRC_GET,	0x82000095),
+		CMD(SM_GET_CHIP_ID,		0x82000044),
+		CMD(SM_THERMAL_CALIB_READ,	0x82000047),
+		CMD(SM_A1_PWRC_SET,		0x82000093),
+		CMD(SM_A1_PWRC_GET,		0x82000095),
 		{ /* sentinel */ },
 	},
 };
@@ -245,6 +246,24 @@ struct meson_sm_firmware *meson_sm_get(struct device_node *sm_node)
 }
 EXPORT_SYMBOL_GPL(meson_sm_get);
 
+/**
+ *
+ * meson_sm_get_thermal_calib - Read thermal sensor calibration data.
+ * @fw:		Pointer to secure-monitor firmware.
+ * @trim_info:	Pointer to store the returned calibration data.
+ * @tsensor_id:	Sensor index to identify which sensor's calibration data
+ *		to retrieve
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+int meson_sm_get_thermal_calib(struct meson_sm_firmware *fw, u32 *trim_info,
+			       u32 tsensor_id)
+{
+	return meson_sm_call(fw, SM_THERMAL_CALIB_READ, trim_info, tsensor_id,
+			     0, 0, 0, 0);
+}
+EXPORT_SYMBOL_GPL(meson_sm_get_thermal_calib);
+
 #define SM_CHIP_ID_LENGTH	119
 #define SM_CHIP_ID_OFFSET	4
 #define SM_CHIP_ID_SIZE		12

-- 
2.49.0

