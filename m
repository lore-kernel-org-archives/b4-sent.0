From: Vincent Jardin <vjardin@free.fr>
Date: Sun, 08 Nov 2026 18:32:17 +0100
Subject: [PATCH] hwmon: (pmbus/core) Add a vout_command debugfs entry
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-for-upstream-pmbus-vout-command-debugfs-v1-v1-1-c7a063efb91c@free.fr>
X-B4-Tracking: v=1; b=H4sIACCy8GoC/x2NSQrDMAwAvxJ0riByIC39SunBi5z64AUpDoWQv
 9f0OHOYOUFZEis8pxOEj6SplgF0m8B/bNkYUxgMZjYr0fzAWAV7013YZmzZdcWj9h19zdmWgIF
 d3+KQhGvkhb1Z7o4sjGATjun7n73e1/UDWSKhhHwAAAA=
To: Guenter Roeck <linux@roeck-us.net>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794159154; l=3250;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=dfNk0v5rH84dOXRM4vSF3mXu/2YsTYVFhl+RaSVniq0=;
 b=2jjtGHQUZBJrA/BT9ZSY4zAJkL7F6wkTkWtgmZkX0UaFri1AsKdo/iiPX4KAP62+8UhCe/Nfe
 4RnFr/UTfemBjeD99mYedkXgjvj0B9/wDryA0XDbCWEgD1EoaqkMvRW
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The vout hwmon attributes and the regulator get_voltage() callback
both report READ_VOUT.

On a regulator whose configuration applies a load line (droop),
READ_VOUT sits below the setpoint under load by design, so user space
cannot see what the regulator was actually set to.

max20730 already exposes a driver-specific vout_command entry. Add
vout<page>_command to the PMBus core debugfs, for every page with VOUT
and a readable VOUT_COMMAND, in millivolts like the in*_input attributes.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 drivers/hwmon/pmbus/pmbus_core.c | 42 ++++++++++++++++++++++++++++++++++++++--
 1 file changed, 40 insertions(+), 2 deletions(-)

diff --git a/drivers/hwmon/pmbus/pmbus_core.c b/drivers/hwmon/pmbus/pmbus_core.c
index 37b650b85d1c..1ad5523a9624 100644
--- a/drivers/hwmon/pmbus/pmbus_core.c
+++ b/drivers/hwmon/pmbus/pmbus_core.c
@@ -3833,6 +3833,33 @@ static int pmbus_debugfs_get_status(void *data, u64 *val)
 DEFINE_DEBUGFS_ATTRIBUTE(pmbus_debugfs_ops_status, pmbus_debugfs_get_status,
 			 NULL, "0x%04llx\n");
 
+static int pmbus_debugfs_get_vout_command(void *data, u64 *val)
+{
+	struct pmbus_debugfs_entry *entry = data;
+	struct i2c_client *client = entry->client;
+	struct pmbus_data *pdata = i2c_get_clientdata(client);
+	struct pmbus_sensor s = {
+		.page = entry->page,
+		.reg = entry->reg,
+		.class = PSC_VOLTAGE_OUT,
+		.convert = true,
+	};
+	int rc;
+
+	guard(pmbus_lock)(client);
+
+	rc = _pmbus_read_word_data(client, entry->page, 0xff, entry->reg);
+	if (rc < 0)
+		return rc;
+
+	s.data = rc;
+	*val = pmbus_reg2data(pdata, &s);
+
+	return 0;
+}
+DEFINE_DEBUGFS_ATTRIBUTE(pmbus_debugfs_ops_vout_command,
+			 pmbus_debugfs_get_vout_command, NULL, "%lld\n");
+
 static ssize_t pmbus_debugfs_block_read(struct file *file, char __user *buf,
 					size_t count, loff_t *ppos)
 {
@@ -3940,11 +3967,11 @@ static void pmbus_init_debugfs(struct i2c_client *client,
 	 * device specific:
 	 *	ARRAY_SIZE(pmbus_debugfs_block_data) + 2
 	 * page specific:
-	 *	ARRAY_SIZE(pmbus_debugfs_status_data) + 1
+	 *	ARRAY_SIZE(pmbus_debugfs_status_data) + 2
 	 */
 	entries = devm_kcalloc(data->dev,
 			       ARRAY_SIZE(pmbus_debugfs_block_data) + 2 +
-			       data->info->pages * (ARRAY_SIZE(pmbus_debugfs_status_data) + 1),
+			       data->info->pages * (ARRAY_SIZE(pmbus_debugfs_status_data) + 2),
 			       sizeof(*entries), GFP_KERNEL);
 	if (!entries)
 		return;
@@ -4013,6 +4040,17 @@ static void pmbus_init_debugfs(struct i2c_client *client,
 						    &pmbus_debugfs_ops);
 			}
 		}
+
+		if ((data->info->func[page] & PMBUS_HAVE_VOUT) &&
+		    pmbus_check_word_register(client, page, PMBUS_VOUT_COMMAND)) {
+			entries[idx].client = client;
+			entries[idx].page = page;
+			entries[idx].reg = PMBUS_VOUT_COMMAND;
+			scnprintf(name, PMBUS_NAME_SIZE, "vout%d_command", page);
+			debugfs_create_file(name, 0444, debugfs,
+					    &entries[idx++],
+					    &pmbus_debugfs_ops_vout_command);
+		}
 	}
 }
 

---
base-commit: d4193d2a0ffa407478bce4a094e1ae085ceb38ec
change-id: 20261108-for-upstream-pmbus-vout-command-debugfs-v1-6fe3ec237b1a

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

