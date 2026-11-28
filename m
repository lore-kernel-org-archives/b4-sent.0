From: Dickson Wu <dickson.wu@certik.com>
Date: Sat, 28 Nov 2026 01:50:59 +0000
Subject: [PATCH 6.12.y] iio: light: apds9306: fix PM reference leak in
 apds9306_read_data()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-apds9306-612-v1-1-5df62a3d7a6c@certik.com>
X-B4-Tracking: v=1; b=H4sIAIMzCmsC/02NwQ6CMBBEf4Xs2UV2G6vyK8ZDKavUmEK6aDSEf
 7fVi8d5mXmzgEoKotBWCyR5Bg1jzIE2FfjBxatg6HMGbtgS8QHd1OvRNBYtMRIbb9x+17AQ5Mm
 U5BJeX90JbE1cv+H84/robuLn4irNzqlgl1z0Q0EqsZ/H8Y6Fb/8/YF0/wjJeSaUAAAA=
X-Change-ID: 20261128-apds9306-612-123c3a7502e1
In-Reply-To: <2026090952-mollusk-copilot-9a29@gregkh>
References: <2026090952-mollusk-copilot-9a29@gregkh>
To: stable@vger.kernel.org
Cc: Moksh Panicker <mokshpanicker.7@gmail.com>, 
 Jonathan Cameron <jonathan.cameron@oss.qualcomm.com>, 
 linux-iio@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795830659; l=3521;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=HfdZuZUT/oANR7K0kvtpBU+UQ7vFuvHHZoUCp54GJF8=;
 b=5RY8Nlg/feb+3jdI/0axfX6UCV/hO35CSV2CkenZT1FpK2QgU062XPZFXxfwHfTwBsnW6Dugt
 lBhUJLqo9n8Cy/toau9bAC45Jkn0ilufeOSy/naWT/2zVgYNVtuzgUM
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Moksh Panicker <mokshpanicker.7@gmail.com>

commit d378fceaafd79e0dc59d3546bda251a3058062c0 upstream.

apds9306_read_data() calls pm_runtime_resume_and_get() but several
error paths return directly without calling pm_runtime_put_autosuspend(),
leaking the runtime PM reference and preventing the device from
autosuspending.

Use PM_RUNTIME_ACQUIRE_AUTOSUSPEND() and PM_RUNTIME_ACQUIRE_ERR() to
automatically handle runtime PM reference release on all return paths.

Fixes: 620d1e6c7a3f ("iio: light: Add support for APDS9306 Light Sensor")
Signed-off-by: Moksh Panicker <mokshpanicker.7@gmail.com>
Cc: stable@vger.kernel.org
Signed-off-by: Jonathan Cameron <jonathan.cameron@oss.qualcomm.com>
[ adapted to 6.12.y: no PM_RUNTIME_ACQUIRE helpers, goto the put ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
This failed to apply to 6.12.y, which doesn't have the
PM_RUNTIME_ACQUIRE_AUTOSUSPEND() helpers. Instead every error return
after pm_runtime_resume_and_get() now jumps to the existing
mark_last_busy()/put_autosuspend() at the end, so the usage count is
dropped on all exits.

Tested on 6.12.119: W=1 build of apds9306.o, base vs patched, no new
warnings, and the patched kernel boots under QEMU. No sensor here, so
the read paths were checked in the source.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.
---
 drivers/iio/light/apds9306.c | 19 +++++++++++--------
 1 file changed, 11 insertions(+), 8 deletions(-)

diff --git a/drivers/iio/light/apds9306.c b/drivers/iio/light/apds9306.c
index db648e2cb520..5e483cf4dc15 100644
--- a/drivers/iio/light/apds9306.c
+++ b/drivers/iio/light/apds9306.c
@@ -477,19 +477,21 @@ static int apds9306_read_data(struct apds9306_data *data, int *val, int reg)
 
 	ret = regmap_field_read(rf->intg_time, &intg_time_idx);
 	if (ret)
-		return ret;
+		goto out_pm;
 
 	ret = regmap_field_read(rf->repeat_rate, &repeat_rate_idx);
 	if (ret)
-		return ret;
+		goto out_pm;
 
 	ret = regmap_field_read(rf->int_src, &int_src);
 	if (ret)
-		return ret;
+		goto out_pm;
 
 	intg_time = iio_gts_find_int_time_by_sel(&data->gts, intg_time_idx);
-	if (intg_time < 0)
-		return intg_time;
+	if (intg_time < 0) {
+		ret = intg_time;
+		goto out_pm;
+	}
 
 	/* Whichever is greater - integration time period or sampling period. */
 	delay = max(intg_time, apds9306_repeat_rate_period[repeat_rate_idx]);
@@ -512,7 +514,7 @@ static int apds9306_read_data(struct apds9306_data *data, int *val, int reg)
 						  APDS9306_ALS_INT_STAT_MASK)),
 				       APDS9306_ALS_READ_DATA_DELAY_US, delay * 2);
 	if (ret)
-		return ret;
+		goto out_pm;
 
 	/* If we reach here before the interrupt handler we push an event */
 	if ((status & APDS9306_ALS_INT_STAT_MASK)) {
@@ -532,15 +534,16 @@ static int apds9306_read_data(struct apds9306_data *data, int *val, int reg)
 	ret = regmap_bulk_read(data->regmap, reg, buff, sizeof(buff));
 	if (ret) {
 		dev_err_ratelimited(dev, "read data failed\n");
-		return ret;
+		goto out_pm;
 	}
 
 	*val = get_unaligned_le24(&buff);
 
+out_pm:
 	pm_runtime_mark_last_busy(data->dev);
 	pm_runtime_put_autosuspend(data->dev);
 
-	return 0;
+	return ret;
 }
 
 static int apds9306_intg_time_get(struct apds9306_data *data, int *val2)

---
base-commit: e2e4b92c2b2a3ae78423cb343951cb5d2241b405
change-id: 20261128-apds9306-612-123c3a7502e1

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

