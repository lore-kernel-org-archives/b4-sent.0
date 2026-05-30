From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Sat, 30 May 2026 09:05:57 +0200
Subject: [PATCH] firmware: meson: sm: add stub functions when
 CONFIG_MESON_SM is disabled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260530-fix-missing-meson_sm-symbol-v1-1-3fb672b989d4@aliel.fr>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3M0QpAMBSA4VfRuXZqVrZ4FUnYwSnbtFMieXfL5
 Vd//wNCiUmgLR5IdLJwDBlVWcC8jWElZJcNWmmjat3gwhd6FuGwoieJYRCPcvsp7mitNU65xlm
 jIB+ORDn/713/vh+4IbHLbQAAAA==
X-Change-ID: 20260529-fix-missing-meson_sm-symbol-7776d0d9d760
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Lukasz Luba <lukasz.luba@arm.com>
Cc: Guillaume La Roque <glaroque@baylibre.com>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Mark Brown <broonie@kernel.org>, Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2190;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=9bC21YQnPxgGtSXVEFJabEi6tIt8Ai/WeaIfr6J2d/Q=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ5ZUT5nA3z2OrJe9ZwYLTfr6ViGqZJ7CyVPVm2zvevK4T
 4ic5n2go5SFQYyLQVZMkaV/ruWJd5ePnvm6Rz0FZg4rE8gQBi5OAZhIgxgjw/fgkB1dR1beYNyR
 UPFhTUdUUsRmsdIPSyZ8Z1biO7vDrYiRYdaCuRtzbG7OK9J4Ivw0wyDg+KwERsmG8ANcFrd6M4S
 VGQA=
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
Reported-by: Mark Brown <broonie@kernel.org>
Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 include/linux/firmware/meson/meson_sm.h | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/include/linux/firmware/meson/meson_sm.h b/include/linux/firmware/meson/meson_sm.h
index 3ebc2bd9a9760..813166ccedd1d 100644
--- a/include/linux/firmware/meson/meson_sm.h
+++ b/include/linux/firmware/meson/meson_sm.h
@@ -27,8 +27,25 @@ int meson_sm_call_write(struct meson_sm_firmware *fw, void *buffer,
 int meson_sm_call_read(struct meson_sm_firmware *fw, void *buffer,
 		       unsigned int bsize, unsigned int cmd_index, u32 arg0,
 		       u32 arg1, u32 arg2, u32 arg3, u32 arg4);
+
+#ifdef CONFIG_MESON_SM
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

