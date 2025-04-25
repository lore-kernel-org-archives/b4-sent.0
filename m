From: Kurt Borja <kuurtb@gmail.com>
Date: Fri, 25 Apr 2025 12:45:06 -0300
Subject: [PATCH 1/2] platform/x86: alienware-wmi-wmax: Fix uninitialized
 bitmap in awcc_hwmon_fans_init()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250425-temp-id-fix-v1-1-372d71f732bf@gmail.com>
References: <20250425-temp-id-fix-v1-0-372d71f732bf@gmail.com>
In-Reply-To: <20250425-temp-id-fix-v1-0-372d71f732bf@gmail.com>
To: =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Hans de Goede <hdegoede@redhat.com>, Armin Wolf <W_Armin@gmx.de>
Cc: platform-driver-x86@vger.kernel.org, Dell.Client.Kernel@dell.com, 
 linux-kernel@vger.kernel.org, Kurt Borja <kuurtb@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1295; i=kuurtb@gmail.com;
 h=from:subject:message-id; bh=g/Dk2JpTbYSEVwfZMItolcD7wZ6KOPVE70YJFfQTbXY=;
 b=owGbwMvMwCUmluBs8WX+lTTG02pJDBnc6wR23FvxjPv7lsB6jq+tLVcs33P/PK+0l0comK3OK
 VIqv7+5o5SFQYyLQVZMkaU9YdG3R1F5b/0OhN6HmcPKBDKEgYtTACZy4B3Df5+gtodLub/pfVIR
 XM+w4Dd/sViQ7xIpHjmh6aeeflKfvofhv//ND522DctXJl+SWL9WZ93VDW3P3rnb6p5TD5XsNJ+
 fygEA
X-Developer-Key: i=kuurtb@gmail.com; a=openpgp;
 fpr=54D3BE170AEF777983C3C63B57E3B6585920A69A
X-Endpoint-Received: by B4 Relay for kuurtb@gmail.com/default with auth_id=387
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Initialize fan_temps bitmap to zero before using it for the first time
in each iteration.

Fixes: d69990783495 ("platform/x86: alienware-wmi-wmax: Add HWMON support")
Signed-off-by: Kurt Borja <kuurtb@gmail.com>
---
 drivers/platform/x86/dell/alienware-wmi-wmax.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/platform/x86/dell/alienware-wmi-wmax.c b/drivers/platform/x86/dell/alienware-wmi-wmax.c
index faeddfe3b79e0aa51e7c8c6b23aa4ac5c7218706..27e5b0b23c27356cd5d72dbc5d3b5b4bdb03e8af 100644
--- a/drivers/platform/x86/dell/alienware-wmi-wmax.c
+++ b/drivers/platform/x86/dell/alienware-wmi-wmax.c
@@ -1027,6 +1027,8 @@ static int awcc_hwmon_fans_init(struct wmi_device *wdev)
 		if (ret)
 			return ret;
 
+		bitmap_zero(fan_temps, AWCC_ID_BITMAP_SIZE);
+
 		for (j = 0; j < temp_count; j++) {
 			ret = awcc_get_fan_sensors(wdev, AWCC_OP_GET_FAN_TEMP_ID,
 						   id, j, &temp_id);
@@ -1048,8 +1050,6 @@ static int awcc_hwmon_fans_init(struct wmi_device *wdev)
 		bitmap_gather(gather, fan_temps, priv->temp_sensors, AWCC_ID_BITMAP_SIZE);
 		bitmap_copy(&fan_data->auto_channels_temp, gather, BITS_PER_LONG);
 		priv->fan_data[i] = fan_data;
-
-		bitmap_zero(fan_temps, AWCC_ID_BITMAP_SIZE);
 	}
 
 	return 0;

-- 
2.49.0

