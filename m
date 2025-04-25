From: Kurt Borja <kuurtb@gmail.com>
Date: Fri, 25 Apr 2025 12:45:07 -0300
Subject: [PATCH 2/2] platform/x86: alienware-wmi-wmax: Fix
 awcc_hwmon_fans_init() label logic
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250425-temp-id-fix-v1-2-372d71f732bf@gmail.com>
References: <20250425-temp-id-fix-v1-0-372d71f732bf@gmail.com>
In-Reply-To: <20250425-temp-id-fix-v1-0-372d71f732bf@gmail.com>
To: =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Hans de Goede <hdegoede@redhat.com>, Armin Wolf <W_Armin@gmx.de>
Cc: platform-driver-x86@vger.kernel.org, Dell.Client.Kernel@dell.com, 
 linux-kernel@vger.kernel.org, Kurt Borja <kuurtb@gmail.com>, 
 kernel test robot <lkp@intel.com>, Dan Carpenter <dan.carpenter@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2435; i=kuurtb@gmail.com;
 h=from:subject:message-id; bh=hl7NOezBX65uzKnMSgj3738hCgwWWjttXsdb5CJ1YU4=;
 b=owGbwMvMwCUmluBs8WX+lTTG02pJDBnc6wRc2D68PZlfxXZuvmjk/DnC3xlunnWc5PU6ddHEz
 u4Dr++xdpSyMIhxMciKKbK0Jyz69igq763fgdD7MHNYmUCGMHBxCsBEHDwYGZq4Wc2SFLNXfNll
 FzrfOHLaf9PlJ7enx5891/xnoZ1d8kOG//kPMh9e/7G7iPnXzKV8flZlGscWupsqGa/KXqfGPbu
 zmBEA
X-Developer-Key: i=kuurtb@gmail.com; a=openpgp;
 fpr=54D3BE170AEF777983C3C63B57E3B6585920A69A
X-Endpoint-Received: by B4 Relay for kuurtb@gmail.com/default with auth_id=387
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To avoid passing an uninitialized `temp_id` to awcc_get_fan_label(),
pass the `fan_temps` bitmap instead, to work only on set bits.

Additionally, awcc_get_fan_label() leaves `dev` unused, so remove it
from it's signature and it does not fail, so remove error handling.

Reported-by: kernel test robot <lkp@intel.com>
Reported-by: Dan Carpenter <dan.carpenter@linaro.org>
Closes: https://lore.kernel.org/r/202504250521.HEkFK1Jy-lkp@intel.com/
Fixes: d69990783495 ("platform/x86: alienware-wmi-wmax: Add HWMON support")
Signed-off-by: Kurt Borja <kuurtb@gmail.com>
---
 drivers/platform/x86/dell/alienware-wmi-wmax.c | 13 ++++++-------
 1 file changed, 6 insertions(+), 7 deletions(-)

diff --git a/drivers/platform/x86/dell/alienware-wmi-wmax.c b/drivers/platform/x86/dell/alienware-wmi-wmax.c
index 27e5b0b23c27356cd5d72dbc5d3b5b4bdb03e8af..f3ad47c9edfac47fae181046acae2190e388306c 100644
--- a/drivers/platform/x86/dell/alienware-wmi-wmax.c
+++ b/drivers/platform/x86/dell/alienware-wmi-wmax.c
@@ -958,15 +958,19 @@ static int awcc_hwmon_temps_init(struct wmi_device *wdev)
 	return 0;
 }
 
-static char *awcc_get_fan_label(struct device *dev, u32 temp_count, u8 temp_id)
+static char *awcc_get_fan_label(unsigned long *fan_temps)
 {
+	unsigned int temp_count = bitmap_weight(fan_temps, AWCC_ID_BITMAP_SIZE);
 	char *label;
+	u8 temp_id;
 
 	switch (temp_count) {
 	case 0:
 		label = "Independent Fan";
 		break;
 	case 1:
+		temp_id = find_first_bit(fan_temps, AWCC_ID_BITMAP_SIZE);
+
 		switch (temp_id) {
 		case AWCC_TEMP_SENSOR_CPU:
 			label = "Processor Fan";
@@ -996,7 +1000,6 @@ static int awcc_hwmon_fans_init(struct wmi_device *wdev)
 	u32 min_rpm, max_rpm, temp_count, temp_id;
 	struct awcc_fan_data *fan_data;
 	unsigned int i, j;
-	char *label;
 	int ret;
 	u8 id;
 
@@ -1039,14 +1042,10 @@ static int awcc_hwmon_fans_init(struct wmi_device *wdev)
 			__set_bit(temp_id, fan_temps);
 		}
 
-		label = awcc_get_fan_label(&wdev->dev, temp_count, temp_id);
-		if (!label)
-			return -ENOMEM;
-
 		fan_data->id = id;
 		fan_data->min_rpm = min_rpm;
 		fan_data->max_rpm = max_rpm;
-		fan_data->label = label;
+		fan_data->label = awcc_get_fan_label(fan_temps);
 		bitmap_gather(gather, fan_temps, priv->temp_sensors, AWCC_ID_BITMAP_SIZE);
 		bitmap_copy(&fan_data->auto_channels_temp, gather, BITS_PER_LONG);
 		priv->fan_data[i] = fan_data;

-- 
2.49.0

