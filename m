From: Vincent Jardin <vjardin@free.fr>
Date: Wed, 29 Jul 2026 23:51:46 +0200
Subject: [PATCH v6 4/4] hwmon: pmbus: mpq8646: gate the writes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-mpq8646_v0-v6-4-98848151cdb4@free.fr>
References: <20260729-mpq8646_v0-v6-0-98848151cdb4@free.fr>
In-Reply-To: <20260729-mpq8646_v0-v6-0-98848151cdb4@free.fr>
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Charles Hsu <ythsu0511@gmail.com>
Cc: Markus Elfring <Markus.Elfring@web.de>, linux-hwmon@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-doc@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785361913; l=14054;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=B9nUIW1YjHjCj0R+AqGfGRn5IVSmKLo8D1gselGgDDU=;
 b=tMJm+SrnM/dYkTqld56+lrpsEU0vQkjrwZ758bPXuJRuLw4+yMfx3UngvEHsY1UPfnasWkrdd
 uW2WR3TFDojCApSXDRjRbqXBTHfJb0YqpNK1NY8LVImI/nZAXK09yMm
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The write cases of debugfs entries are provisioning and bench
helpers. By designs the MPQ8646 powers the CPU cores rail,
so a wrong write can brown out the board or persist a bad
setpoint into finite-cycle NVM.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 Documentation/hwmon/mpq8646.rst |  37 ++++++
 drivers/hwmon/pmbus/Kconfig     |  17 +++
 drivers/hwmon/pmbus/mpq8646.c   | 269 ++++++++++++++++++++++++++++++++++++++++
 3 files changed, 323 insertions(+)

diff --git a/Documentation/hwmon/mpq8646.rst b/Documentation/hwmon/mpq8646.rst
index d3ede656ea15..6207cfd89f7f 100644
--- a/Documentation/hwmon/mpq8646.rst
+++ b/Documentation/hwmon/mpq8646.rst
@@ -246,6 +246,43 @@ The only writable entry is ``alarm_poll_interval_ms`` (the alarm-poll
 worker cadence, see above), it is driver-local and never touches the
 chip.
 
+Unsafe provisioning
+-------------------
+
+Available only when ``CONFIG_SENSORS_MPQ8646_DEBUG_UNSAFE=y``
+(``default n``, it is for boards bring up only). They WRITE to the regulator.
+On many designs the MPQ8646 powers the main CPU core rail, so a wrong write can
+brown out the board or persist a bad setpoint into finite-cycle NVM. The first
+gated write logs a one-shot warning.
+
+===============================  ===============  =========================================================
+File                             PMBus / MFR cmd  Description
+===============================  ===============  =========================================================
+``store_all``                    0x15             STORE_USER_ALL Send-Byte (commit RAM config to NVM)
+``restore_all``                  0x16             RESTORE_USER_ALL Send-Byte (revert RAM to last-NVM image)
+``clear_protection_last``        0x08             CLEAR_LAST_FAULT Send-Byte
+``clear_protection_last_force``  --               gated CLEAR_LAST_FAULT, see below
+``on_off_config``                0x02 (byte)      PMBus vs CTRL-pin on/off source + active polarity
+``vout_margin_high``             0x25 (word)      margin-high VOUT setpoint
+``vout_margin_low``              0x26 (word)      margin-low VOUT setpoint
+``mfr_pmbus_lock``               0xEE (word)      programmable PMBus write-lock
+``mfr_product_rev_user``         0xC2 (word)      user-programmable product revision
+===============================  ===============  =========================================================
+
+``clear_protection_last`` writes ``CLEAR_LAST_FAULT`` (0x08) Send-Byte.
+The chip silently no-ops unless ``MFR_CFG_EXT`` (0xF5) bit[6] is set.
+
+``clear_protection_last_force`` performs the unlock with the following
+six-step dancing:
+
+1. read ``WRITE_PROTECT`` (0x10) and ``MFR_CFG_EXT`` (0xF5) for restore
+2. clear ``WRITE_PROTECT`` if set
+3. set ``MFR_CFG_EXT`` bit[6] = 1, preserving other bits
+4. send ``CLEAR_LAST_FAULT`` (0x08)
+5. restore ``MFR_CFG_EXT`` (with retry to handle the chip's
+   undocumented post-NVM-write busy window)
+6. restore ``WRITE_PROTECT``
+
 Devicetree
 ----------
 
diff --git a/drivers/hwmon/pmbus/Kconfig b/drivers/hwmon/pmbus/Kconfig
index 9f44e76b0b64..9c6d3de61a75 100644
--- a/drivers/hwmon/pmbus/Kconfig
+++ b/drivers/hwmon/pmbus/Kconfig
@@ -627,6 +627,23 @@ config SENSORS_MPQ8646
 	  This driver can also be built as a module. If so, the module
 	  will be called mpq8646.
 
+config SENSORS_MPQ8646_DEBUG_UNSAFE
+	bool "MPQ8646 unsafe write/provisioning debugfs (DANGEROUS)"
+	depends on SENSORS_MPQ8646 && DEBUG_FS
+	default n
+	help
+	  Expose additional WRITE-able debugfs files in the client's
+	  pmbus debugfs directory,
+	  /sys/kernel/debug/i2c/i2c-<bus>/<bus>-<addr>/
+
+	  These are provisioning and bring-up aids. On many designs the
+	  MPQ8646 powers the SoC core rail, so a wrong write can brown out
+	  or permanently mis-provision the board.
+
+	  It shall never be set in a production, shipping, or default configuration.
+
+	  If unsure, say N.
+
 config SENSORS_PIM4328
 	tristate "Flex PIM4328 and compatibles"
 	help
diff --git a/drivers/hwmon/pmbus/mpq8646.c b/drivers/hwmon/pmbus/mpq8646.c
index 1fd41d89e5be..0034cf591934 100644
--- a/drivers/hwmon/pmbus/mpq8646.c
+++ b/drivers/hwmon/pmbus/mpq8646.c
@@ -7,6 +7,7 @@
 
 #include <linux/bitops.h>
 #include <linux/debugfs.h>
+#include <linux/delay.h>
 #include <linux/i2c.h>
 #include <linux/module.h>
 #include <linux/mutex.h>
@@ -23,8 +24,18 @@
 #define MPQ8646_ALARM_POLL_MS_DEFAULT	1000
 
 /* MPS vendor-extended command codes (NOT in PMBus 1.3 Part II) */
+#define MPS_CLEAR_LAST_FAULT		0x08
+#define MPS_MFR_CFG_EXT			0xF5
+#define MPS_MFR_CFG_EXT_CLR_LAST_EN	BIT(6)
 #define MPS_PROTECTION_LAST		0xFB
 
+/*
+ * PMBus 1.3 NVM commit / revert commands. MPS equivalent of
+ * STORE_ALL (15h) and RESTORE_ALL (16h).
+ */
+#define PMBUS_STORE_USER_ALL		0x15
+#define PMBUS_RESTORE_USER_ALL		0x16
+
 /* PMBus 1.3 timing / UVLO command codes */
 #define PMBUS_VIN_ON			0x35
 #define PMBUS_VIN_OFF			0x36
@@ -36,10 +47,32 @@
 /* MPS vendor-extended observability / identity registers */
 #define MPS_MFR_CONFIG_ID		0xC0
 #define MPS_MFR_CONFIG_CODE_REV		0xC1
+#define MPS_MFR_PRODUCT_REV_USER	0xC2
 #define MPS_MFR_SILICON_REV		0xC3
 #define MPS_MFR_RETRY_TIMES		0xF4
 #define MPS_MFR_VBOOT_CFG		0xFC
 
+/*
+ * MPS_MFR_PMBUS_LOCK (EEh): 16-bit WORD whose low two bits gate
+ * subsequent PMBus writes
+ *   bits[1:0] = 00  -- unlocked (POR default)
+ *               01  -- lock all writes EXCEPT VOUT_COMMAND (0x21)
+ *                      so the operator can still DVFS the rail
+ *               11  -- lock all writes
+ * A negative-going PG edge resets these bits to 00, the lock
+ * is operationally reversible without a full chip POR.
+ */
+#define MPS_MFR_PMBUS_LOCK		0xEE
+
+/*
+ * Retry parameters for the MFR_CFG_EXT gate-close write after
+ * CLEAR_LAST_FAULT. Bench-observed NVM-busy NACK window on this
+ * silicon is about 1 ms; the datasheet does not have information.
+ */
+#define MPQ8646_NVM_RETRY_MAX		5
+#define MPQ8646_NVM_RETRY_DELAY_US_MIN	2000
+#define MPQ8646_NVM_RETRY_DELAY_US_MAX	4000
+
 #define MPQ8646_DEBUG(client, fmt, ...) \
 	dev_dbg(&(client)->dev, fmt, ##__VA_ARGS__)
 
@@ -498,6 +531,240 @@ static int mpq8646_dbg_reg_show(struct seq_file *s, void *unused)
 }
 DEFINE_SHOW_ATTRIBUTE(mpq8646_dbg_reg);
 
+#ifdef CONFIG_SENSORS_MPQ8646_DEBUG_UNSAFE
+/*
+ * Write/provisioning data, disabled by default: NVM commit and
+ * revert, the CLEAR_LAST_FAULT sequences and a small set of named
+ * writable registers.
+ */
+
+static void mpq8646_unsafe_warn_once(struct mpq8646_priv *priv)
+{
+	dev_warn_once(&priv->client->dev,
+		      "UNSAFE debugfs write to core-rail regulator; board integrity not guaranteed (CONFIG_SENSORS_MPQ8646_DEBUG_UNSAFE)\n");
+}
+
+static int mpq8646_dbg_clear_protection_last(void *data, u64 val)
+{
+	struct mpq8646_priv *priv = data;
+	int rc;
+
+	if (!val)
+		return 0;
+
+	mpq8646_unsafe_warn_once(priv);
+	scoped_guard(mutex, &priv->mps_lock)
+		rc = i2c_smbus_write_byte(priv->client, MPS_CLEAR_LAST_FAULT);
+	if (rc < 0)
+		dev_warn(&priv->client->dev,
+			 "clear_protection_last: CLEAR_LAST_FAULT write failed (%d)\n",
+			 rc);
+	return 0;
+}
+DEFINE_DEBUGFS_ATTRIBUTE(mpq8646_dbg_clear_protection_last_fops,
+			 NULL, mpq8646_dbg_clear_protection_last, "%llu\n");
+
+static int mpq8646_dbg_clear_protection_last_force(void *data, u64 val)
+{
+	struct mpq8646_priv *priv = data;
+	int rc, last_rc;
+	int wp_orig, cfg_orig;
+
+	if (!val)
+		return 0;
+
+	mpq8646_unsafe_warn_once(priv);
+	guard(pmbus_lock)(priv->client);
+	guard(mutex)(&priv->mps_lock);
+
+	wp_orig = i2c_smbus_read_byte_data(priv->client, PMBUS_WRITE_PROTECT);
+	if (wp_orig < 0) {
+		dev_warn(&priv->client->dev,
+			 "clear_protection_last_force: WRITE_PROTECT read failed (%d), aborting\n",
+			 wp_orig);
+		return 0;
+	}
+	cfg_orig = i2c_smbus_read_word_data(priv->client, MPS_MFR_CFG_EXT);
+	if (cfg_orig < 0) {
+		dev_warn(&priv->client->dev,
+			 "clear_protection_last_force: MFR_CFG_EXT read failed (%d), aborting\n",
+			 cfg_orig);
+		return 0;
+	}
+
+	if (wp_orig != 0) {
+		rc = i2c_smbus_write_byte_data(priv->client,
+					       PMBUS_WRITE_PROTECT, 0);
+		if (rc < 0) {
+			dev_warn(&priv->client->dev,
+				 "clear_protection_last_force: WP clear failed (%d), aborting\n",
+				 rc);
+			return 0;
+		}
+	}
+
+	rc = i2c_smbus_write_word_data(priv->client, MPS_MFR_CFG_EXT,
+				       (u16)cfg_orig | MPS_MFR_CFG_EXT_CLR_LAST_EN);
+	if (rc < 0) {
+		dev_warn(&priv->client->dev,
+			 "clear_protection_last_force: gate open failed (%d)\n",
+			 rc);
+		goto restore_wp;
+	}
+
+	last_rc = i2c_smbus_write_byte(priv->client, MPS_CLEAR_LAST_FAULT);
+	if (last_rc < 0)
+		dev_warn(&priv->client->dev,
+			 "clear_protection_last_force: CLEAR_LAST_FAULT failed (%d) even with gate open\n",
+			 last_rc);
+
+	for (int attempt = 0; attempt < MPQ8646_NVM_RETRY_MAX; attempt++) {
+		rc = i2c_smbus_write_word_data(priv->client, MPS_MFR_CFG_EXT,
+					       (u16)cfg_orig);
+		if (rc >= 0)
+			break;
+		usleep_range(MPQ8646_NVM_RETRY_DELAY_US_MIN,
+			     MPQ8646_NVM_RETRY_DELAY_US_MAX);
+	}
+	if (rc < 0)
+		dev_warn(&priv->client->dev,
+			 "clear_protection_last_force: MFR_CFG_EXT restore failed after retries (%d) -- gate may stay open until POR\n",
+			 rc);
+
+restore_wp:
+	if (wp_orig != 0) {
+		rc = i2c_smbus_write_byte_data(priv->client,
+					       PMBUS_WRITE_PROTECT,
+					       (u8)wp_orig);
+		if (rc < 0)
+			dev_warn(&priv->client->dev,
+				 "clear_protection_last_force: WP restore failed (%d)\n",
+				 rc);
+	}
+	return 0;
+}
+DEFINE_DEBUGFS_ATTRIBUTE(mpq8646_dbg_clear_protection_last_force_fops,
+			 NULL, mpq8646_dbg_clear_protection_last_force, "%llu\n");
+
+static int mpq8646_dbg_store_all(void *data, u64 val)
+{
+	struct mpq8646_priv *priv = data;
+	int rc;
+
+	if (!val)
+		return 0;
+
+	mpq8646_unsafe_warn_once(priv);
+	scoped_guard(mutex, &priv->mps_lock)
+		rc = i2c_smbus_write_byte(priv->client, PMBUS_STORE_USER_ALL);
+	if (rc < 0)
+		dev_warn(&priv->client->dev,
+			 "store_all: STORE_USER_ALL (0x15) write failed (%d)\n",
+			 rc);
+	return 0;
+}
+DEFINE_DEBUGFS_ATTRIBUTE(mpq8646_dbg_store_all_fops,
+			 NULL, mpq8646_dbg_store_all, "%llu\n");
+
+static int mpq8646_dbg_restore_all(void *data, u64 val)
+{
+	struct mpq8646_priv *priv = data;
+	int rc;
+
+	if (!val)
+		return 0;
+
+	mpq8646_unsafe_warn_once(priv);
+	scoped_guard(mutex, &priv->mps_lock)
+		rc = i2c_smbus_write_byte(priv->client, PMBUS_RESTORE_USER_ALL);
+	if (rc < 0)
+		dev_warn(&priv->client->dev,
+			 "restore_all: RESTORE_USER_ALL (0x16) write failed (%d)\n",
+			 rc);
+	return 0;
+}
+DEFINE_DEBUGFS_ATTRIBUTE(mpq8646_dbg_restore_all_fops,
+			 NULL, mpq8646_dbg_restore_all, "%llu\n");
+
+static const struct mpq8646_dbg_reg mpq8646_dbg_regs_unsafe[] = {
+	/* PMBus 1.3 control / margin */
+	{ PMBUS_ON_OFF_CONFIG,      false, "on_off_config" },
+	{ PMBUS_VOUT_MARGIN_HIGH,   true,  "vout_margin_high" },
+	{ PMBUS_VOUT_MARGIN_LOW,    true,  "vout_margin_low" },
+	/* MPS PMBus-level write-protect */
+	{ MPS_MFR_PMBUS_LOCK,       true,  "mfr_pmbus_lock" },
+	/* MPS user-writable product revision */
+	{ MPS_MFR_PRODUCT_REV_USER, true,  "mfr_product_rev_user" },
+};
+
+static int mpq8646_dbg_reg_get(void *data, u64 *val)
+{
+	struct mpq8646_dbg_reg_ctx *ctx = data;
+	int rc;
+
+	if (ctx->desc->is_word)
+		rc = i2c_smbus_read_word_data(ctx->priv->client,
+					      ctx->desc->reg);
+	else
+		rc = i2c_smbus_read_byte_data(ctx->priv->client,
+					      ctx->desc->reg);
+	if (rc < 0)
+		return rc;
+	*val = rc;
+	return 0;
+}
+
+static int mpq8646_dbg_reg_set(void *data, u64 val)
+{
+	struct mpq8646_dbg_reg_ctx *ctx = data;
+	int rc;
+
+	mpq8646_unsafe_warn_once(ctx->priv);
+	if (ctx->desc->is_word)
+		rc = i2c_smbus_write_word_data(ctx->priv->client,
+					       ctx->desc->reg, (u16)val);
+	else
+		rc = i2c_smbus_write_byte_data(ctx->priv->client,
+					       ctx->desc->reg, (u8)val);
+	return rc < 0 ? rc : 0;
+}
+DEFINE_DEBUGFS_ATTRIBUTE(mpq8646_dbg_reg_rw_fops,
+			 mpq8646_dbg_reg_get, mpq8646_dbg_reg_set, "0x%llx\n");
+
+static void mpq8646_debugfs_register_unsafe(struct mpq8646_priv *priv,
+					    struct dentry *root)
+{
+	struct mpq8646_dbg_reg_ctx *ctx;
+	size_t i;
+
+	debugfs_create_file_unsafe("clear_protection_last", 0200, root, priv,
+				   &mpq8646_dbg_clear_protection_last_fops);
+	debugfs_create_file_unsafe("clear_protection_last_force", 0200, root,
+				   priv,
+				   &mpq8646_dbg_clear_protection_last_force_fops);
+	debugfs_create_file_unsafe("store_all", 0200, root, priv,
+				   &mpq8646_dbg_store_all_fops);
+	debugfs_create_file_unsafe("restore_all", 0200, root, priv,
+				   &mpq8646_dbg_restore_all_fops);
+
+	ctx = devm_kcalloc(&priv->client->dev,
+			   ARRAY_SIZE(mpq8646_dbg_regs_unsafe),
+			   sizeof(*ctx), GFP_KERNEL);
+	if (!ctx)
+		return;
+	for (i = 0; i < ARRAY_SIZE(mpq8646_dbg_regs_unsafe); i++) {
+		ctx[i].priv = priv;
+		ctx[i].desc = &mpq8646_dbg_regs_unsafe[i];
+		debugfs_create_file_unsafe(mpq8646_dbg_regs_unsafe[i].name,
+					   0600, root, &ctx[i],
+					   &mpq8646_dbg_reg_rw_fops);
+	}
+}
+#else
+static inline void mpq8646_debugfs_register_unsafe(struct mpq8646_priv *priv,
+						   struct dentry *root) {}
+#endif /* CONFIG_SENSORS_MPQ8646_DEBUG_UNSAFE */
+
 static int mpq8646_dbg_poll_interval_get(void *data, u64 *val)
 {
 	struct mpq8646_priv *priv = data;
@@ -554,6 +821,8 @@ static void mpq8646_debugfs_register(struct mpq8646_priv *priv)
 				    root, &priv->dbg_reg_ctx[i],
 				    &mpq8646_dbg_reg_fops);
 	}
+
+	mpq8646_debugfs_register_unsafe(priv, root);
 }
 
 static void mpq8646_debugfs_unregister(struct mpq8646_priv *priv)

-- 
2.43.0

