From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Thu, 23 Apr 2026 18:07:17 +0200
Subject: [PATCH v4 2/8] firmware: meson: sm: Thermal calibration read via
 secure monitor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260423-add-thermal-t7-vim4-v4-2-d4c1528d5044@aliel.fr>
References: <20260423-add-thermal-t7-vim4-v4-0-d4c1528d5044@aliel.fr>
In-Reply-To: <20260423-add-thermal-t7-vim4-v4-0-d4c1528d5044@aliel.fr>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1177;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=z46M+rsMVvol/Iu/vuO1m+rAUYrJ82iMmifq0EnDoU0=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ+Yr5wd19ruFs27aWU42aw5k55HewVi6/0sc32XtCv4O5
 WO1ZRs6SlkYxLgYZMUUWfrnWp54d/noma971FNg5rAygQxh4OIUgIlktTMyHPfQWLq7ha3QvZPl
 ZtAshjNGEyW09nUqnta2/+7sW6zmx/CHm00zOkon53rbO3H+9GSjI+ahpcZbnlbccH+13fOhwyI
 mAA==
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SM_THERMAL_CALIB_READ to the secure monitor command enum and
introduce meson_sm_get_thermal_calib() to allow drivers to retrieve
thermal sensor calibration data through the firmware interface.

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 include/linux/firmware/meson/meson_sm.h | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/include/linux/firmware/meson/meson_sm.h b/include/linux/firmware/meson/meson_sm.h
index 8eaf8922ab020..3ebc2bd9a9760 100644
--- a/include/linux/firmware/meson/meson_sm.h
+++ b/include/linux/firmware/meson/meson_sm.h
@@ -12,6 +12,7 @@ enum {
 	SM_EFUSE_WRITE,
 	SM_EFUSE_USER_MAX,
 	SM_GET_CHIP_ID,
+	SM_THERMAL_CALIB_READ,
 	SM_A1_PWRC_SET,
 	SM_A1_PWRC_GET,
 };
@@ -27,5 +28,7 @@ int meson_sm_call_read(struct meson_sm_firmware *fw, void *buffer,
 		       unsigned int bsize, unsigned int cmd_index, u32 arg0,
 		       u32 arg1, u32 arg2, u32 arg3, u32 arg4);
 struct meson_sm_firmware *meson_sm_get(struct device_node *firmware_node);
+int meson_sm_get_thermal_calib(struct meson_sm_firmware *fw, u32 *trim_info,
+			       u32 tsensor_id);
 
 #endif /* _MESON_SM_FW_H_ */

-- 
2.49.0

