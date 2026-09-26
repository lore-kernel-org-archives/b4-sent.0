From: Alexei Solcanu <alexei.solcanu@pm.me>
Date: Sat, 26 Sep 2026 16:11:20 -0400
Subject: [PATCH v2 1/2] hwmon: (gpd-fan) Reset both fans to automatic on
 duo boards
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260926-gpd-fan-duo-auto-v2-1-0a2ea41ee3b5@pm.me>
References: <20260926-gpd-fan-duo-auto-v2-0-0a2ea41ee3b5@pm.me>
In-Reply-To: <20260926-gpd-fan-duo-auto-v2-0-0a2ea41ee3b5@pm.me>
To: Guenter Roeck <linux@roeck-us.net>, 
 Cryolitia PukNgae <cryolitia@uniontech.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org, Antheas Kapenekakis <lkml@antheas.dev>, 
 Alexei Solcanu <alexei.solcanu@pm.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790453516; l=1200;
 i=alexei.solcanu@pm.me; s=20260925; h=from:subject:message-id;
 bh=+nlB/lxvtjXsfgj7z4lKurSGOTzHgxp5QbIYzM1esmM=;
 b=BhXSljpP2xwOAsQEnbESNsa5OZQFvdnSpt1nURScxoiYUMOe5KmDAtno8YRgIpFc2L8lq1iH9
 +nhY+MRZYzVCK7aAyvsBSRjBHY7mvkjiHEUc7ohh/dNsykIBTmygVUH
X-Developer-Key: i=alexei.solcanu@pm.me; a=ed25519;
 pk=iK6ervbccknflfirBb6E4x7TaOyCpnoGd33gzfiNEeo=
X-Endpoint-Received: by B4 Relay for alexei.solcanu@pm.me/20260925 with auth_id=1064
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On boards using gpd_duo_drvdata (GPD Duo, GPD Win 5), writing
pwm1_enable=2 only returns the first fan to EC control. The second fan
keeps its last manual duty cycle, e.g. full speed after pwm1=255, so a
fan control tool that exits leaves it running at that speed.

gpd_duo_write_pwm() writes both fan registers (pwm_write and
pwm_write + 1), but switching to automatic only clears pwm_write.
Also clear pwm_write + 1, so both fans return to EC control.

Tested on a GPD Win 5 (G1618-05). Not tested on the GPD Duo.

Fixes: 0ab88e239439 ("hwmon: add GPD devices sensor driver")
Assisted-by: LLM
Signed-off-by: Alexei Solcanu <alexei.solcanu@pm.me>
---
 drivers/hwmon/gpd-fan.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/hwmon/gpd-fan.c b/drivers/hwmon/gpd-fan.c
index ed212615b2f..b3b75f99f58 100644
--- a/drivers/hwmon/gpd-fan.c
+++ b/drivers/hwmon/gpd-fan.c
@@ -444,6 +444,7 @@ static void gpd_duo_set_pwm_enable(struct gpd_fan_data *data, enum FAN_PWM_ENABL
 		break;
 	case AUTOMATIC:
 		gpd_ecram_write(data->drvdata, data->drvdata->pwm_write, 0);
+		gpd_ecram_write(data->drvdata, data->drvdata->pwm_write + 1, 0);
 		break;
 	}
 }

-- 
2.55.0

