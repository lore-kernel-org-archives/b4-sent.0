From: Maud Spierings <maudspierings@gocontroll.com>
Date: Tue, 04 Mar 2025 15:10:31 +0100
Subject: [PATCH] hwmon: (ntc_thermistor) return error instead of clipping
 on OOB
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250304-ntc_oob-v1-1-600d8992478d@gocontroll.com>
X-B4-Tracking: v=1; b=H4sIANYJx2cC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDYwMT3byS5Pj8/CRdCyMjkyTTJCNTc4s0JaDqgqLUtMwKsEnRsbW1ADs
 ERUxZAAAA
X-Change-ID: 20250304-ntc_oob-8224b5b2578f
To: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741097433; l=4222;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=RmytwYHysabk9h8JtKUKdTZTREYQi1OmvlBNEp98ZGQ=;
 b=My3ewUjA2boel3PNERKlLCk4c31l8WSk+MPw21rkUcGwvZ9oUwYzyyK0E5/OGB2Exd+t6SDGx
 jhTsGLnVMTYCZlWm8iFjPL6YiqqEGxmKSL0BgcOCogm4/g7UHjz0Yzj
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the ntc is reading Out Of Bounds instead of clipping to the nearest
limit (min/max) return -ENODATA. This prevents malfunctioning sensors
from sending a device into a shutdown loop due to a critical trip.

This implementation will only work for ntc type thermistors if a ptc
type is to be implemented the min/max ohm calculation must be adjusted
to take that into account.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
This patch is a continuation of another discussion [1]. I felt like it
should be a new patch, not a v2 as this is a very different change.

I have left the clamping of n to INT_MAX in the code with a comment, but
it may be possible to find a better solution to it. One I thought of is
to make the ohm field of the ntc_compensation struct a signed int as
well. It would get rid of this weird edge case, but it doesn't make
sense to allow for negative resistances to be entered into the sensor
table.

Currently the only feedback this provides to the user is when they
manually try to read the temperature and it returns the error. I have
added a simple printk to these error points to see how spammy it gets
and this is the result:

dmesg | grep hwmon
[    4.982682] hwmon: sensor out of bounds
[    5.249758] hwmon: sensor out of bounds
[    5.633729] hwmon: sensor out of bounds
[    6.215285] hwmon: sensor out of bounds
[    7.073882] hwmon: sensor out of bounds
[    7.486620] hwmon: sensor out of bounds
[    8.833765] hwmon: sensor out of bounds
[   10.785969] hwmon: sensor out of bounds
[   13.793722] hwmon: sensor out of bounds
[   16.761124] hwmon: sensor out of bounds
[   17.889706] hwmon: sensor out of bounds
[   25.057715] hwmon: sensor out of bounds
[   35.041725] hwmon: sensor out of bounds
[   50.110346] hwmon: sensor out of bounds
[   72.945283] hwmon: sensor out of bounds
[  105.712619] hwmon: sensor out of bounds
[  154.863976] hwmon: sensor out of bounds
[  164.937104] hwmon: sensor out of bounds
[  228.590909] hwmon: sensor out of bounds
[  315.365777] hwmon: sensor out of bounds
[  464.718403] hwmon: sensor out of bounds
[  615.079123] hwmon: sensor out of bounds
[  764.496780] hwmon: sensor out of bounds

This is with polling-delay set to 1000, it seems to rate-limit itself?
But I feel there should be a better way to communicate the potential
sensor failure to the user, but I can't think of anything.

[1]: https://lore.kernel.org/all/20250304-ntc_min_max-v1-1-b08e70e56459@gocontroll.com/
---
 drivers/hwmon/ntc_thermistor.c | 19 +++++++++++++------
 1 file changed, 13 insertions(+), 6 deletions(-)

diff --git a/drivers/hwmon/ntc_thermistor.c b/drivers/hwmon/ntc_thermistor.c
index 0d29c8f97ba7c2f264588b6309b91ca494012ad6..311a60498d409ea068a18590415b2d5b43e73eb1 100644
--- a/drivers/hwmon/ntc_thermistor.c
+++ b/drivers/hwmon/ntc_thermistor.c
@@ -387,12 +387,9 @@ static int get_ohm_of_thermistor(struct ntc_data *data, unsigned int uv)
 	puo = data->pullup_ohm;
 	pdo = data->pulldown_ohm;
 
-	if (uv == 0)
-		return (data->connect == NTC_CONNECTED_POSITIVE) ?
-			INT_MAX : 0;
-	if (uv >= puv)
-		return (data->connect == NTC_CONNECTED_POSITIVE) ?
-			0 : INT_MAX;
+	/* faulty adc value */
+	if (uv == 0 || uv >= puv)
+		return -ENODATA;
 
 	if (data->connect == NTC_CONNECTED_POSITIVE && puo == 0)
 		n = div_u64(pdo * (puv - uv), uv);
@@ -404,6 +401,16 @@ static int get_ohm_of_thermistor(struct ntc_data *data, unsigned int uv)
 	else
 		n = div64_u64_safe(pdo * puo * uv, pdo * (puv - uv) - puo * uv);
 
+	/* sensor out of bounds */
+	if (n > data->comp[0].ohm || n < data->comp[data->n_comp-1].ohm)
+		return -ENODATA;
+
+	/*
+	 * theoretically data->comp[0].ohm can be greater than INT_MAX as it is an
+	 * unsigned integer, but it doesn't make any sense for it to be so as the
+	 * maximum return value of this function is INT_MAX, so it will never be
+	 * able to properly calculate that temperature.
+	 */
 	if (n > INT_MAX)
 		n = INT_MAX;
 	return n;

---
base-commit: 20d5c66e1810e6e8805ec0d01373afb2dba9f51a
change-id: 20250304-ntc_oob-8224b5b2578f

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

