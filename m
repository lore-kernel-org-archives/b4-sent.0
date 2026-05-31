From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Sun, 31 May 2026 09:51:37 +0200
Subject: [PATCH v2] firmware: meson: sm: add stub functions when
 CONFIG_MESON_SM is disabled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260531-fix-missing-meson_sm-symbol-v2-1-1def8c3c169f@aliel.fr>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NQQ6CMBCF4auQrh1TiraWlfcwxIAdYBLamo4hE
 sLdrcS1y/9l8s0qGBMhi7pYRcKZmGLIoQ6FeIxtGBDI5RZKKi3PykJPb/DETGEAjxzDnT3w4rs
 4gTFGO+msM1qKLDwT5vNdvzW5R+JXTMv+bC6/68+t5F93LqGEqu+0UZ29WHe6thPhdOyTaLZt+
 wCBrsjqxQAAAA==
X-Change-ID: 20260529-fix-missing-meson_sm-symbol-7776d0d9d760
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Lukasz Luba <lukasz.luba@arm.com>
Cc: Guillaume La Roque <glaroque@baylibre.com>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Mark Brown <broonie@kernel.org>, kernel test robot <lkp@intel.com>, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2615;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=hEwMqxJxqL8pmXwuK2Rbg6Zwob3G2YZuQoVdSnhBZ2c=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ5b0i3XB5h02Cw6Y3pgkHHfyzGFhl3fztiUxBPeWH5r30
 CLKPetCRykLgxgXg6yYIkv/XMsT7y4fPfN1j3oKzBxWJpAhDFycAjCRrqcMfzgrHT9ffPPcmu/H
 hmld96/JJZh8u2HYyzx5ncaLE1/XaCsw/DMTqImcw1hssnHSpd3n5F7NYTM9H8dle0Vka0DmhTZ
 ZQ04A
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After merging the thermal tree, linux-next build (arm_multi_v7
defconfig) failed like this:

arm-linux-gnueabihf-ld: drivers/thermal/amlogic_thermal.o: in function `amlogic_thermal_probe_sm':
/tmp/next/build/drivers/thermal/amlogic_thermal.c:196:(.text+0x2f4): undefined reference to `meson_sm_get'
arm-linux-gnueabihf-ld: /tmp/next/build/drivers/thermal/amlogic_thermal.c:205:(.text+0x320): undefined reference to `meson_sm_get_thermal_calib'

Add inline stub implementations of meson_sm_get() and
meson_sm_get_thermal_calib() behind an #else guard so that drivers
including this header can be compiled without CONFIG_MESON_SM .

Fixes: b21d88de6918 ("thermal/drivers/amlogic: Add support for secure monitor calibration readout")
Closes: https://lore.kernel.org/oe-kbuild-all/202605291530.en7aGn7w-lkp@intel.com/
Reported-by: Mark Brown <broonie@kernel.org>
Reported-by: kernel test robot <lkp@intel.com>
Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
Changes in v2:
- Replace #ifdef CONFIG_MESON_SM by #if IS_ENABLED(CONFIG_MESON_SM)
  to cover builtin and module in config.
- Add missing trailers for kernel test robot.
- Link to v1: https://lore.kernel.org/r/20260530-fix-missing-meson_sm-symbol-v1-1-3fb672b989d4@aliel.fr
---
 include/linux/firmware/meson/meson_sm.h | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/include/linux/firmware/meson/meson_sm.h b/include/linux/firmware/meson/meson_sm.h
index 3ebc2bd9a9760..baecdaf263f41 100644
--- a/include/linux/firmware/meson/meson_sm.h
+++ b/include/linux/firmware/meson/meson_sm.h
@@ -27,8 +27,25 @@ int meson_sm_call_write(struct meson_sm_firmware *fw, void *buffer,
 int meson_sm_call_read(struct meson_sm_firmware *fw, void *buffer,
 		       unsigned int bsize, unsigned int cmd_index, u32 arg0,
 		       u32 arg1, u32 arg2, u32 arg3, u32 arg4);
+
+#if IS_ENABLED(CONFIG_MESON_SM)
+
 struct meson_sm_firmware *meson_sm_get(struct device_node *firmware_node);
 int meson_sm_get_thermal_calib(struct meson_sm_firmware *fw, u32 *trim_info,
 			       u32 tsensor_id);
 
+#else
+
+static inline struct meson_sm_firmware *meson_sm_get(struct device_node *firmware_node)
+{
+	return NULL;
+}
+static inline int meson_sm_get_thermal_calib(struct meson_sm_firmware *fw,
+					     u32 *trim_info, u32 tsensor_id)
+{
+	return -EINVAL;
+}
+
+#endif
+
 #endif /* _MESON_SM_FW_H_ */

---
base-commit: 3929405c64376a8a54c794e8a4485023b108a97e
change-id: 20260529-fix-missing-meson_sm-symbol-7776d0d9d760

Best regards,
-- 
Ronald Claveau <linux-kernel-dev@aliel.fr>

