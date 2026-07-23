From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Thu, 23 Jul 2026 18:27:11 +0700
Subject: [PATCH 4/4] Input: edt-ft5x06 - poll while a contact is down to
 recover dropped releases
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-b4-ft5426-v1-4-d4b4e32be042@gmail.com>
References: <20260723-b4-ft5426-v1-0-d4b4e32be042@gmail.com>
In-Reply-To: <20260723-b4-ft5426-v1-0-d4b4e32be042@gmail.com>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Henrik Rydberg <rydberg@bitmath.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Alexandre Hamamdjian <azkali.limited@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784806028; l=10202;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=yaHIDDdKuKyw2nsbkxWJtOZ/A0eSGr3eWe261NjiyQE=;
 b=T6SY2d0DjXAzZSw785Jshbz8BI1LNpFgkHDPoW+gd2hdfEKYphOaAJ5/mdIJDGx/sYKvpKa0w
 PydLL2S35ESBt48QR9am11oLAd2vpJBl4pt2oFaHPploX3LYivBk6I+
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver is purely interrupt driven: a touch-up is only reported when
the controller raises an edge for the release frame and that frame is
read successfully. On a marginal i2c bus a read can fail or be dropped,
and if the read that carried the release is the one lost there is no
further edge to re-read it, so the contact stays held down forever - the
pointer sticks mid-drag. This is readily reproducible on the AYANEO
Pocket DS, whose FT5426 hangs off an unreliable Qualcomm GENI bus.

Stop trusting a single edge to deliver the release. Track which slots are
held down in a mask and, while any contact is down, re-read the frame on
a short timer. A contact missing from the frame is released only after a
few consecutive misses so a lone glitchy read cannot cut a still-present
tap or drag; conversely, once the finger is really gone the polled reads
stop listing it and it is released regardless of whether an explicit
touch-up frame ever arrives. The timer stops as soon as the last contact
is released, so an idle panel is still fully interrupt driven.

The read path also gains a bounded retry over the transient bus errors
and, when reads keep failing for over a second, a reset-line pulse to
recover a wedged controller, dropping any held contacts afterwards since
the post-reset finger state is unknown. The poll worker is cancelled on
suspend and, via a devm action registered before the IRQ, on removal, so
it can never touch i2c after the device is powered down or the IRQ freed.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
 drivers/input/touchscreen/edt-ft5x06.c | 173 ++++++++++++++++++++++++++++++---
 1 file changed, 157 insertions(+), 16 deletions(-)

diff --git a/drivers/input/touchscreen/edt-ft5x06.c b/drivers/input/touchscreen/edt-ft5x06.c
index ac61ac44fd64..794c0650f5cb 100644
--- a/drivers/input/touchscreen/edt-ft5x06.c
+++ b/drivers/input/touchscreen/edt-ft5x06.c
@@ -19,6 +19,7 @@
 #include <linux/gpio/consumer.h>
 #include <linux/i2c.h>
 #include <linux/interrupt.h>
+#include <linux/workqueue.h>
 #include <linux/input.h>
 #include <linux/input/mt.h>
 #include <linux/input/touchscreen.h>
@@ -147,8 +148,19 @@ struct edt_ft5x06_ts_data {
 	unsigned int crc_errors;
 	unsigned int header_errors;
 	bool no_regmap_bulk_read;
+	unsigned long last_reset;
+	unsigned long last_success;
+	struct delayed_work poll_work;
+	/* io_lock serialises the frame read between the IRQ and the poll work */
+	struct mutex io_lock;
+	u16 down_mask;
+	u8 miss[16];
 };
 
+/* poll cadence and release debounce for the poll-while-touched recovery */
+#define EDT_POLL_INTERVAL_MS	15
+#define EDT_RELEASE_MISSES	3
+
 struct edt_i2c_chip_data {
 	int  max_support_points;
 };
@@ -321,26 +333,83 @@ static int edt_ft5x06_bulk_read(struct regmap *map, unsigned int start,
 	return 0;
 }
 
-static irqreturn_t edt_ft5x06_ts_isr(int irq, void *dev_id)
+static void edt_ft5x06_release_all(struct edt_ft5x06_ts_data *tsdata)
+{
+	int id;
+
+	if (!tsdata->down_mask)
+		return;
+
+	for (id = 0; id < tsdata->max_support_points; id++) {
+		if (!(tsdata->down_mask & BIT(id)))
+			continue;
+		input_mt_slot(tsdata->input, id);
+		input_mt_report_slot_state(tsdata->input, MT_TOOL_FINGER, false);
+	}
+	tsdata->down_mask = 0;
+	memset(tsdata->miss, 0, sizeof(tsdata->miss));
+	input_mt_report_pointer_emulation(tsdata->input, true);
+	input_sync(tsdata->input);
+}
+
+static void edt_ft5x06_fetch_and_report(struct edt_ft5x06_ts_data *tsdata)
 {
-	struct edt_ft5x06_ts_data *tsdata = dev_id;
 	struct device *dev = &tsdata->client->dev;
+	u16 new_mask = 0, released = 0;
 	u8 rdbuf[63];
 	int i, type, x, y, id;
-	int error;
+	int error, tries;
 
 	memset(rdbuf, 0, sizeof(rdbuf));
-	if (tsdata->no_regmap_bulk_read)
-		error = edt_ft5x06_bulk_read(tsdata->regmap, tsdata->tdata_cmd,
-					     rdbuf, tsdata->tdata_len);
-	else
-		error = regmap_bulk_read(tsdata->regmap, tsdata->tdata_cmd,
-					 rdbuf, tsdata->tdata_len);
+	for (tries = 0; tries < 4; tries++) {
+		if (tsdata->no_regmap_bulk_read)
+			error = edt_ft5x06_bulk_read(tsdata->regmap,
+						     tsdata->tdata_cmd, rdbuf,
+						     tsdata->tdata_len);
+		else
+			error = regmap_bulk_read(tsdata->regmap,
+						 tsdata->tdata_cmd, rdbuf,
+						 tsdata->tdata_len);
+		if (!error)
+			break;
+		if (error != -EAGAIN && error != -ETIMEDOUT &&
+		    error != -EIO && error != -ENXIO)
+			break;
+		usleep_range(min(1000U << tries, 4000U),
+			     min(2000U << tries, 8000U));
+	}
 	if (error) {
 		dev_err_ratelimited(dev, "Unable to fetch data, error: %d\n",
 				    error);
-		goto out;
+		/*
+		 * A run of failed reads with no success for over a second means
+		 * the controller is wedged rather than just glitching; pulse the
+		 * reset line to recover it and drop any held contacts, since the
+		 * post-reset finger state is unknown.
+		 */
+		if (tsdata->reset_gpio &&
+		    time_after(jiffies, tsdata->last_success + HZ) &&
+		    time_after(jiffies, tsdata->last_reset + 2 * HZ)) {
+			tsdata->last_reset = jiffies;
+			gpiod_set_value_cansleep(tsdata->reset_gpio, 1);
+			usleep_range(5000, 6000);
+			gpiod_set_value_cansleep(tsdata->reset_gpio, 0);
+			msleep(300);
+			tsdata->last_success = jiffies;
+			dev_warn_ratelimited(dev, "reset to recover controller\n");
+			edt_ft5x06_release_all(tsdata);
+		}
+		return;
 	}
+	tsdata->last_success = jiffies;
+
+	/*
+	 * TD_STATUS holds the active-contact count; a value above the panel
+	 * maximum means the frame is corrupt, so keep the previous state.
+	 */
+	if (tsdata->version != EDT_M06 &&
+	    (rdbuf[2] & 0x0f) > tsdata->max_support_points)
+		return;
 
 	for (i = 0; i < tsdata->max_support_points; i++) {
 		u8 *buf = &rdbuf[i * tsdata->point_len + tsdata->tdata_offset];
@@ -349,10 +418,12 @@ static irqreturn_t edt_ft5x06_ts_isr(int irq, void *dev_id)
 		/* ignore Reserved events */
 		if (type == TOUCH_EVENT_RESERVED)
 			continue;
-
 		/* M06 sometimes sends bogus coordinates in TOUCH_DOWN */
 		if (tsdata->version == EDT_M06 && type == TOUCH_EVENT_DOWN)
 			continue;
+		/* releases are derived from the down-mask diff below */
+		if (type == TOUCH_EVENT_UP)
+			continue;
 
 		x = get_unaligned_be16(buf) & 0x0fff;
 		y = get_unaligned_be16(buf + 2) & 0x0fff;
@@ -363,21 +434,75 @@ static irqreturn_t edt_ft5x06_ts_isr(int irq, void *dev_id)
 		id = (buf[2] >> 4) & 0x0f;
 		if (id >= tsdata->max_support_points)
 			continue;
+		if (tsdata->prop.max_x &&
+		    (x > tsdata->prop.max_x || y > tsdata->prop.max_y))
+			continue;
 
 		input_mt_slot(tsdata->input, id);
-		if (input_mt_report_slot_state(tsdata->input, MT_TOOL_FINGER,
-					       type != TOUCH_EVENT_UP))
-			touchscreen_report_pos(tsdata->input, &tsdata->prop,
-					       x, y, true);
+		input_mt_report_slot_state(tsdata->input, MT_TOOL_FINGER, true);
+		touchscreen_report_pos(tsdata->input, &tsdata->prop, x, y, true);
+		new_mask |= BIT(id);
 	}
 
+	/*
+	 * Reconcile held contacts with this frame. A contact absent from the
+	 * frame is released only after EDT_RELEASE_MISSES consecutive misses so
+	 * a single glitchy read cannot cut a still-present tap or drag.
+	 */
+	for (id = 0; id < tsdata->max_support_points; id++) {
+		if (new_mask & BIT(id)) {
+			tsdata->miss[id] = 0;
+			continue;
+		}
+		if (!(tsdata->down_mask & BIT(id)))
+			continue;
+		if (++tsdata->miss[id] >= EDT_RELEASE_MISSES) {
+			input_mt_slot(tsdata->input, id);
+			input_mt_report_slot_state(tsdata->input,
+						   MT_TOOL_FINGER, false);
+			tsdata->miss[id] = 0;
+			released |= BIT(id);
+		}
+	}
+	tsdata->down_mask = (tsdata->down_mask | new_mask) & ~released;
+
 	input_mt_report_pointer_emulation(tsdata->input, true);
 	input_sync(tsdata->input);
+}
+
+static irqreturn_t edt_ft5x06_ts_isr(int irq, void *dev_id)
+{
+	struct edt_ft5x06_ts_data *tsdata = dev_id;
+
+	guard(mutex)(&tsdata->io_lock);
+	edt_ft5x06_fetch_and_report(tsdata);
+	if (tsdata->down_mask)
+		mod_delayed_work(system_wq, &tsdata->poll_work,
+				 msecs_to_jiffies(EDT_POLL_INTERVAL_MS));
 
-out:
 	return IRQ_HANDLED;
 }
 
+static void edt_ft5x06_poll_work(struct work_struct *work)
+{
+	struct edt_ft5x06_ts_data *tsdata =
+		container_of(to_delayed_work(work),
+			     struct edt_ft5x06_ts_data, poll_work);
+
+	guard(mutex)(&tsdata->io_lock);
+	edt_ft5x06_fetch_and_report(tsdata);
+	if (tsdata->down_mask)
+		mod_delayed_work(system_wq, &tsdata->poll_work,
+				 msecs_to_jiffies(EDT_POLL_INTERVAL_MS));
+}
+
+static void edt_ft5x06_cancel_poll(void *data)
+{
+	struct edt_ft5x06_ts_data *tsdata = data;
+
+	cancel_delayed_work_sync(&tsdata->poll_work);
+}
+
 struct edt_ft5x06_attribute {
 	struct device_attribute dattr;
 	size_t field_offset;
@@ -1244,6 +1369,10 @@ static int edt_ft5x06_ts_probe(struct i2c_client *client)
 
 	tsdata->no_regmap_bulk_read =
 		device_property_read_bool(&client->dev, "no-regmap-bulk-read");
+	tsdata->last_success = jiffies;
+	tsdata->last_reset = jiffies;
+	mutex_init(&tsdata->io_lock);
+	INIT_DELAYED_WORK(&tsdata->poll_work, edt_ft5x06_poll_work);
 
 	/*
 	 * Check which sleep modes we can support. Power-off requires the
@@ -1341,6 +1470,15 @@ static int edt_ft5x06_ts_probe(struct i2c_client *client)
 		return error;
 	}
 
+	/*
+	 * Registered before the IRQ so it unwinds after the IRQ is freed on
+	 * removal: no edge can re-arm the poll worker once it is cancelled.
+	 */
+	error = devm_add_action_or_reset(&client->dev, edt_ft5x06_cancel_poll,
+					 tsdata);
+	if (error)
+		return error;
+
 	irq_flags = irq_get_trigger_type(client->irq);
 	if (irq_flags == IRQF_TRIGGER_NONE)
 		irq_flags = IRQF_TRIGGER_FALLING;
@@ -1383,6 +1521,9 @@ static int edt_ft5x06_ts_suspend(struct device *dev)
 	struct gpio_desc *reset_gpio = tsdata->reset_gpio;
 	int ret;
 
+	/* stop the poll worker so it cannot touch i2c after power-down */
+	cancel_delayed_work_sync(&tsdata->poll_work);
+
 	if (device_may_wakeup(dev))
 		return 0;
 

-- 
2.55.0

