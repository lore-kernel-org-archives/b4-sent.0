From: Massinissa Ghoul <massigh680@gmail.com>
Date: Mon, 07 Sep 2026 00:35:02 +0200
Subject: [PATCH] hwmon: (hih6130) Replace sprintf() with sysfs_emit()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260907-hwmon-hih6130-sysfs-emit-v1-1-a1adb5245d0f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw6CMBBA0V8hs3aSaQlt4FeMCx6DHROK6fDQE
 P7dqsuzuPcA5SSs0BQHJN5EZY4Z5lJAH9p4Z5QhGyxZRzV5DPs0RwwSnCkJ9a2jIk+yIPnKGGd
 tSd5Dzp+JR3n91tfb37p2D+6X7w/O8wPa9ngofAAAAA==
X-Change-ID: 20260907-hwmon-hih6130-sysfs-emit-075116223077
To: Guenter Roeck <linux@roeck-us.net>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Massinissa Ghoul <massigh680@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788734115; l=1351;
 i=massigh680@gmail.com; s=20260906; h=from:subject:message-id;
 bh=MHrNwwTYchzU6LrretLfcd95AXrW/h9RfnDFCAgZNm0=;
 b=unx4Z7I7LuzIi4htsnORzaqD09Y9jKfD2Qo05QcVbmBMf4/DmsUC/HgmJOUS79pQDS9tvVlQx
 fXDHIFG33fJD7ZwoJMqIPXwD5m9utQG/rPwvt28MvN0+yoyCSX8axKR
X-Developer-Key: i=massigh680@gmail.com; a=ed25519;
 pk=0sdDIn8rwwQcfQLT4kpMuP9iTaPw8YMcqI9B3U/GS1k=
X-Endpoint-Received: by B4 Relay for massigh680@gmail.com/20260906 with auth_id=1012
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use sysfs_emit() instead of sprintf() in the sysfs show functions
hih6130_temperature_show() and hih6130_humidity_show() to use the
preferred kernel interface for writing to sysfs buffers.

No functional change intended.

Note: Not runtime tested due to lack of hardware.

Signed-off-by: Massinissa Ghoul <massigh680@gmail.com>
---
 drivers/hwmon/hih6130.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/hwmon/hih6130.c b/drivers/hwmon/hih6130.c
index 7984be1e706d..6a79aab5d128 100644
--- a/drivers/hwmon/hih6130.c
+++ b/drivers/hwmon/hih6130.c
@@ -168,7 +168,7 @@ static ssize_t hih6130_temperature_show(struct device *dev,
 	ret = hih6130_update_measurements(dev);
 	if (ret < 0)
 		return ret;
-	return sprintf(buf, "%d\n", hih6130->temperature);
+	return sysfs_emit(buf, "%d\n", hih6130->temperature);
 }
 
 /**
@@ -189,7 +189,7 @@ static ssize_t hih6130_humidity_show(struct device *dev,
 	ret = hih6130_update_measurements(dev);
 	if (ret < 0)
 		return ret;
-	return sprintf(buf, "%d\n", hih6130->humidity);
+	return sysfs_emit(buf, "%d\n", hih6130->humidity);
 }
 
 /* sysfs attributes */

---
base-commit: ba08432bda66a7889d8f3d1581dabf10f59b25eb
change-id: 20260907-hwmon-hih6130-sysfs-emit-075116223077

Best regards,
--  
Massinissa Ghoul <massigh680@gmail.com>

