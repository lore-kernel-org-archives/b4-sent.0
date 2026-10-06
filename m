From: Matt Layher <mdlayher@gmail.com>
Date: Tue, 06 Oct 2026 10:35:37 -0400
Subject: [PATCH v3] hwmon: (asus-ec-sensors) add CPU_Opt fan for ROG STRIX
 X570-E GAMING
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261006-asus-ec-x570e-cpu-opt-v3-1-62672edc18b3@gmail.com>
References: <20261006-asus-ec-x570e-cpu-opt-v3-0-62672edc18b3@gmail.com>
In-Reply-To: <20261006-asus-ec-x570e-cpu-opt-v3-0-62672edc18b3@gmail.com>
To: Eugene Shalygin <eugene.shalygin@gmail.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Matt Layher <mdlayher@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791297407; l=925;
 i=mdlayher@gmail.com; s=linuxdev; h=from:subject:message-id;
 bh=neFRa9yM7J68Bw3LwyksLxTmfSCixK0ZjZK4PIQ+vwQ=;
 b=92bFwaGWqtmre0ZZLPS7D0+Dx/NO02LV9yiDy6orwsV6q0MTns/Kl42E/HO6e3fOVA2Wz9K8x
 +gTyc4ZfC5XCxacY5RmmPsb0Oh3Fq7UW3sDqVk/rh3hX1snRPWh0v9y
X-Developer-Key: i=mdlayher@gmail.com; a=ed25519;
 pk=jO44g3WNw2T0EoKPeB+RUgDmyrZpA5Pmr830ITlwhaA=
X-Endpoint-Received: by B4 Relay for mdlayher@gmail.com/linuxdev with auth_id=1109
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The board has a CPU_OPT fan header, which the EC reports at the same
register (bank 0, 0xb0) as the other AMD 500 series boards. Enable it.

Assisted-by: LLM sparse
Signed-off-by: Matt Layher <mdlayher@gmail.com>
---
 drivers/hwmon/asus-ec-sensors.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/hwmon/asus-ec-sensors.c b/drivers/hwmon/asus-ec-sensors.c
index 19f423e45ce5..8261ddd00653 100644
--- a/drivers/hwmon/asus-ec-sensors.c
+++ b/drivers/hwmon/asus-ec-sensors.c
@@ -721,7 +721,7 @@ static const struct ec_board_info board_info_strix_x470_i_gaming = {
 
 static const struct ec_board_info board_info_strix_x570_e_gaming = {
 	.sensors = SENSOR_SET_TEMP_CHIPSET_CPU_MB |
-		SENSOR_TEMP_T_SENSOR |
+		SENSOR_TEMP_T_SENSOR | SENSOR_FAN_CPU_OPT |
 		SENSOR_FAN_CHIPSET | SENSOR_CURR_CPU |
 		SENSOR_IN_CPU_CORE,
 	.mutex_path = ASUS_HW_ACCESS_MUTEX_ASMX,

-- 
2.54.0

