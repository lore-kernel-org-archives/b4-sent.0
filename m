From: Vincent Jardin <vjardin@free.fr>
Date: Thu, 30 Jul 2026 17:44:01 +0200
Subject: [PATCH v7 3/4] hwmon: pmbus: add MPQ8646 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-mpq8646_v0-v7-3-e7c7ad768d5d@free.fr>
References: <20260730-mpq8646_v0-v7-0-e7c7ad768d5d@free.fr>
In-Reply-To: <20260730-mpq8646_v0-v7-0-e7c7ad768d5d@free.fr>
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Charles Hsu <ythsu0511@gmail.com>
Cc: Markus Elfring <Markus.Elfring@web.de>, linux-hwmon@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-doc@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785426244; l=33829;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=SZRZYLlbCcsbY5P9py8HdWZV0UbRpwJQIzJMvJRr8KI=;
 b=QIwXtex1STPInHpjSMQivdUGgBGY+zJg/RWjFRkyZWpm/ilthue/tenOaRNH6koVYjbKuouXt
 xYRjcCEAeZJD+/XPLgn8BmwI+fKV1ETMKg/YWf/Ybwnrq50kr1+dd/Y
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a new driver for the MPS MPQ8646 that is a PMBus device.

Beyond basic PMBus telemetry, the driver adds:
  - alarm acknowledge via inX_reset_history.
  - STATUS_WORD MPS-extended bit decode and the NVM-backed
    PROTECTION_LAST post-mortem, exposed as a read-only debugfs
    decoder.
  - In-driver alarm-poll fallback work item (thanks lm90) for
    boards without SMBALERT

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 Documentation/hwmon/index.rst   |   1 +
 Documentation/hwmon/mpq8646.rst | 261 +++++++++++++++
 MAINTAINERS                     |   7 +
 drivers/hwmon/pmbus/Kconfig     |  11 +
 drivers/hwmon/pmbus/Makefile    |   1 +
 drivers/hwmon/pmbus/mpq8646.c   | 688 ++++++++++++++++++++++++++++++++++++++++
 6 files changed, 969 insertions(+)

diff --git a/Documentation/hwmon/index.rst b/Documentation/hwmon/index.rst
index 29130df44d12..be52f9f4dc70 100644
--- a/Documentation/hwmon/index.rst
+++ b/Documentation/hwmon/index.rst
@@ -201,6 +201,7 @@ Hardware Monitoring Kernel Drivers
    mp5990
    mp9941
    mp9945
+   mpq8646
    mpq8785
    nct6683
    nct6775
diff --git a/Documentation/hwmon/mpq8646.rst b/Documentation/hwmon/mpq8646.rst
new file mode 100644
index 000000000000..d3ede656ea15
--- /dev/null
+++ b/Documentation/hwmon/mpq8646.rst
@@ -0,0 +1,261 @@
+.. SPDX-License-Identifier: GPL-2.0-only
+.. Copyright (c) 2026 Free Mobile - Vincent Jardin <vjardin@free.fr>
+
+Kernel driver mpq8646
+=====================
+
+Supported chips:
+
+  * MPS MPQ8646
+
+    Prefix: 'mpq8646'
+
+Author:
+  - Vincent Jardin <vjardin@free.fr>
+
+Chip-identity
+-------------
+
+Support the boards that are designed with the MPS MPQ8646 probed thanks
+to``MFR_MODEL`` register.
+
+This driver targets the MPQ8646 silicon specifically.
+
+Description
+-----------
+
+The MPQ8646 is a fully integrated, PMBus-compatible, high-frequency,
+synchronous buck converter. It offers a compact solution that
+achieves up high Amps output current per phase, with excellent load
+and line regulation over a wide input supply range. The chip
+operates at high efficiency over a wide output current load range.
+
+The PMBus interface provides converter configurations and key
+parameters monitoring.
+
+The device adopts MPS's proprietary multi-phase digital
+constant-on-time (MCOT) control, which provides fast transient
+response and eases loop stabilization. The MCOT scheme also allows
+multiple devices or channels to be connected in parallel with
+excellent current sharing and phase interleaving for high-current
+applications.
+
+Fully integrated protection features include over-current
+protection (OCP), over-voltage protection (OVP), under-voltage
+protection (UVP), and over-temperature protection (OTP).
+
+This device is compliant with:
+
+- PMBus rev 1.3 interface.
+
+The driver exports the following attributes via the 'sysfs' files
+for input voltage:
+
+- in1_input
+- in1_label
+- in1_max
+- in1_max_alarm
+- in1_min
+- in1_min_alarm
+- in1_crit
+- in1_crit_alarm
+
+The driver provides the following attributes for output voltage:
+
+- in2_input
+- in2_label
+- in2_alarm
+- in2_max
+- in2_max_alarm
+- in2_min
+- in2_min_alarm
+- in2_crit
+- in2_crit_alarm
+- in2_lcrit
+- in2_lcrit_alarm
+
+The driver provides the following attributes for output current:
+
+- curr1_input
+- curr1_label
+- curr1_max
+- curr1_max_alarm
+- curr1_crit
+- curr1_crit_alarm
+
+The driver provides the following attributes for temperature:
+
+- temp1_input
+- temp1_max
+- temp1_max_alarm
+- temp1_crit
+- temp1_crit_alarm
+
+Alarm acknowledgment
+---------------------
+
+The hwmon-class ``inX_alarm``/``currX_alarm``/``tempX_alarm`` files are
+read-only in pmbus_core. The driver exposes the standard
+``PMBUS_VIRT_RESET_*_HISTORY`` virtual-register channel for fault
+acknowledgment: writing ``1`` to ``inX_reset_history`` /
+``currX_reset_history`` / ``tempX_reset_history`` sends the chip a
+``CLEAR_FAULTS`` (0x03) Send-Byte, which clears the latched
+``STATUS_WORD`` / ``STATUS_VOUT`` / ``STATUS_IOUT`` /
+``STATUS_INPUT`` / ``STATUS_TEMPERATURE`` bits the chip is currently
+exposing.
+
+The MPS-specific NVM post-mortem register
+``PROTECTION_LAST`` (0xFB) is not cleared by this path; it can be read
+(decoded) via the ``protection_last`` debugfs entry described below.
+
+Regulator framework integration
+-------------------------------
+
+When ``CONFIG_REGULATOR=y`` is set, the chip is
+exposed under ``/sys/class/regulator/`` and accepts the standard
+regulator framework operations:
+
+- ``regulator_enable()`` / ``regulator_disable()`` -> ``OPERATION`` (0x01)
+- ``regulator_set_voltage()`` -> ``VOUT_COMMAND`` (0x21)
+- ``regulator_get_voltage()`` -> ``READ_VOUT`` (0x8B)
+- ``regulator_is_enabled()`` -> ``OPERATION`` bit-decode
+
+The single regulator descriptor is named ``"vout"`` (page 0). For a
+multi-page configuration the descriptor table can be extended in
+the driver.
+
+In-driver alarm-poll fallback
+-----------------------------
+
+On boards where the chip's ``SMBALERT#`` pin is unavailable to the
+SoC, ``pmbus_core::pmbus_irq_setup`` cannot deliver SMBALERT-driven
+``poll(POLLPRI)`` wakes or ``udev change@...`` events on the
+``inX_alarm`` files. The driver provides a ``delayed_work``-based
+polling fallback that
+periodically invokes the pmbus core fault check,
+``pmbus_check_and_notify_faults()``, which sends the notifications and
+then clears the latched faults, exactly like the ``SMBALERT#``
+interrupt path. The frequency of polling is tunable:
+
+::
+
+  /sys/kernel/debug/i2c/i2c-<bus>/<bus>-<addr>/alarm_poll_interval_ms
+
+The default is 1000 ms.
+
+Set it to 0 to disable. The worker self-suppresses
+when ``client->irq != 0`` (i.e. when DT supplies an
+``interrupts = <...>``  property on the regulator node), so adding
+``SMBALERT#`` wiring is a zero-driver-change uplift on a future
+board rev.
+
+MPS post-mortem (PROTECTION_LAST)
+---------------------------------
+
+The MPQ8646 silicon keeps a single 16-bit NVM-backed record of the
+last protection event in ``PROTECTION_LAST`` (0xFB). It survives
+chip power/reset. The following debugfs entries expose it:
+
+::
+
+  /sys/kernel/debug/i2c/i2c-<bus>/<bus>-<addr>/protection_last     (RO)
+  /sys/kernel/debug/i2c/i2c-<bus>/<bus>-<addr>/status_decoded      (RO)
+
+``protection_last`` decodes the 16-bit value based on the datasheet
+fault names (``INIT_FAULT``, ``NVM_CRC_ERROR``, ``NVM_FAULT``,
+``OC_PHASE_FAULT``, ``OTP_SELF_FAULT``, ``SWITCH_PRD_FAULT``,
+``VIN_OV_FAULT``, ``VOUT_OV_FAULT``, ``VOUT_UV_FAULT``,
+``OC_TOT_FAULT``, ``VIN_UVLO_FAULT``, ``DRMOS_OTP``).
+
+``status_decoded`` reads ``STATUS_WORD`` (0x79) and renders the
+16 bits with MPS-extension labels (bit12 = ``NVM_SUMMARY``,
+bit8 = ``WATCH_DOG``, bit0 = ``DRMOS_FAULT``) instead of the
+PMBus 1.3 spec generic names.
+
+NVMEM snapshot
+--------------
+
+When ``CONFIG_NVMEM=y`` is set, the chip's NVM-backed
+observability registers are exposed as a single 16-byte read-only
+``nvmem_device`` at ``/sys/bus/nvmem/devices/<i2c-name>/nvmem``.
+Layout (little-endian for 16-bit fields, zero-fill on per-entry read
+failure and for the reserved tail):
+
+::
+
+  offset 0..1   PROTECTION_LAST  (0xFB)  word
+  offset 2..3   MFR_RETRY_TIMES  (0xF4)  word
+  offset 4..5   MFR_CONFIG_ID    (0xC0)  word
+  offset 6..7   MFR_VBOOT_CFG    (0xFC)  word
+  offset 8      MFR_SILICON_REV  (0xC3)  byte
+  offset 9..15  reserved (zero)
+
+Suitable for single-``cat`` post-mortem capture by a fleet daemon.
+
+Diagnostics and introspection
+-----------------------------
+
+When ``CONFIG_DEBUG_FS=y`` is set, the driver adds a read-only
+decode surface to the client's pmbus debugfs directory,
+``/sys/kernel/debug/i2c/i2c-<bus>/<bus>-<addr>/``.
+The driver intentionally exposes no raw register poke/peek debugfs;
+use i2c-dev (``i2cget``/``i2cset``/``i2ctransfer``) for that.
+
+Identity / observability (read-only):
+
+==========================  ==================  =================================
+File                        PMBus / MFR cmd     Description
+==========================  ==================  =================================
+``mfr_config_id``           0xC0 (word)         board / SKU NVM identifier
+``mfr_config_code_rev``     0xC1 (word)         NVM image revision (PART_RECOG +
+                                                config code rev fields)
+``mfr_silicon_rev``         0xC3 (byte)         die revision
+``mfr_retry_times``         0xF4 (word)         per-fault-class recovery-mode
+                                                configuration (NOT a retry
+                                                count). Four 4-bit fields
+                                                [15:12]=OTP, [11:8]=VOUT_OV,
+                                                [7:4]=VOUT_UV, [3:0]=OCP.
+                                                Each field: 0x0=latch-off,
+                                                0x1..0xE=retry N times then
+                                                latch off, 0xF=hiccup
+                                                (retry indefinitely). The
+                                                chip exposes no in-NVM
+                                                retry-event counter; track
+                                                transitions externally if
+                                                needed (poll
+                                                ``protection_last`` or watch
+                                                ``inX_alarm`` / ``temp1_alarm``
+                                                ``poll(POLLPRI)`` wakes).
+``mfr_vboot_cfg``           0xFC (word)         ADDR/VBOOT latched at POR
+==========================  ==================  =================================
+
+Timing / UVLO knobs (read-only):
+
+==========================  ==================  =================================
+File                        PMBus cmd           Description
+==========================  ==================  =================================
+``vin_on``                  0x35 (word)         UVLO turn-on threshold
+``vin_off``                 0x36 (word)         UVLO turn-off threshold
+``ton_delay``               0x60 (word)         soft-start delay
+``ton_rise``                0x61 (word)         soft-start ramp time
+``toff_delay``              0x64 (word)         soft-stop delay
+``toff_fall``               0x65 (word)         soft-stop ramp time
+==========================  ==================  =================================
+
+The only writable entry is ``alarm_poll_interval_ms`` (the alarm-poll
+worker cadence, see above), it is driver-local and never touches the
+chip.
+
+Devicetree
+----------
+
+The driver uses ``compatible = "mps,mpq8646"``. There are some few optional
+properties:
+
+- ``mps,vout-fb-divider-ratio-permille`` : it writes ``VOUT_SCALE_LOOP``
+  (0x29) at probe to compensate for an external resistor divider in
+  the VOUT feedback path. The valid range is 11-bit.
+- ``interrupts = <...>`` : if the board routes the chip's
+  ``SMBALERT#`` pin to a SoC GPIO, declaring it here lights up
+  ``pmbus_core::pmbus_irq_setup`` and disables the in-driver
+  alarm-poll fallback
diff --git a/MAINTAINERS b/MAINTAINERS
index 1ab8736850ea..88dc83d98896 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -18328,6 +18328,13 @@ S:	Maintained
 F:	Documentation/hwmon/mp9945.rst
 F:	drivers/hwmon/pmbus/mp9945.c
 
+MPS MPQ8646 PMBUS DRIVER
+M:	Vincent Jardin <vjardin@free.fr>
+L:	linux-hwmon@vger.kernel.org
+S:	Maintained
+F:	Documentation/hwmon/mpq8646.rst
+F:	drivers/hwmon/pmbus/mpq8646.c
+
 MR800 AVERMEDIA USB FM RADIO DRIVER
 M:	Alexey Klimov <alexey.klimov@linaro.org>
 L:	linux-media@vger.kernel.org
diff --git a/drivers/hwmon/pmbus/Kconfig b/drivers/hwmon/pmbus/Kconfig
index c8cda160b5f8..9f44e76b0b64 100644
--- a/drivers/hwmon/pmbus/Kconfig
+++ b/drivers/hwmon/pmbus/Kconfig
@@ -616,6 +616,17 @@ config SENSORS_MPQ8785
 	  This driver can also be built as a module. If so, the module will
 	  be called mpq8785.
 
+config SENSORS_MPQ8646
+	tristate "MPS MPQ8646"
+	depends on REGULATOR || !REGULATOR
+	depends on NVMEM || !NVMEM
+	help
+	  If you say yes here you get hardware monitoring support for the
+	  Monolithic Power Systems MPQ8646.
+
+	  This driver can also be built as a module. If so, the module
+	  will be called mpq8646.
+
 config SENSORS_PIM4328
 	tristate "Flex PIM4328 and compatibles"
 	help
diff --git a/drivers/hwmon/pmbus/Makefile b/drivers/hwmon/pmbus/Makefile
index ffc05f493213..6f8fda966600 100644
--- a/drivers/hwmon/pmbus/Makefile
+++ b/drivers/hwmon/pmbus/Makefile
@@ -60,6 +60,7 @@ obj-$(CONFIG_SENSORS_MP9941)	+= mp9941.o
 obj-$(CONFIG_SENSORS_MP9945)	+= mp9945.o
 obj-$(CONFIG_SENSORS_MPQ7932)	+= mpq7932.o
 obj-$(CONFIG_SENSORS_MPQ8785)	+= mpq8785.o
+obj-$(CONFIG_SENSORS_MPQ8646)	+= mpq8646.o
 obj-$(CONFIG_SENSORS_PLI1209BC)	+= pli1209bc.o
 obj-$(CONFIG_SENSORS_PM6764TR)	+= pm6764tr.o
 obj-$(CONFIG_SENSORS_PXE1610)	+= pxe1610.o
diff --git a/drivers/hwmon/pmbus/mpq8646.c b/drivers/hwmon/pmbus/mpq8646.c
new file mode 100644
index 000000000000..5133a2471873
--- /dev/null
+++ b/drivers/hwmon/pmbus/mpq8646.c
@@ -0,0 +1,688 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Driver for MPS MPQ8646 step-down converter.
+ *
+ * Copyright (c) 2026 Free Mobile - Vincent Jardin <vjardin@free.fr>
+ */
+
+#include <linux/bitops.h>
+#include <linux/debugfs.h>
+#include <linux/i2c.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/nvmem-provider.h>
+#include <linux/of_device.h>
+#include <linux/pmbus.h>
+#include <linux/property.h>
+#include <linux/regulator/driver.h>
+#include <linux/seq_file.h>
+#include <linux/workqueue.h>
+#include "pmbus.h"
+
+/* Default cadence for the in-driver alarm-poll fallback (ms) */
+#define MPQ8646_ALARM_POLL_MS_DEFAULT	1000
+
+/* MPS vendor-extended command codes (NOT in PMBus 1.3 Part II) */
+#define MPS_PROTECTION_LAST		0xFB
+
+/* PMBus 1.3 timing / UVLO command codes */
+#define PMBUS_VIN_ON			0x35
+#define PMBUS_VIN_OFF			0x36
+#define PMBUS_TON_DELAY			0x60
+#define PMBUS_TON_RISE			0x61
+#define PMBUS_TOFF_DELAY		0x64
+#define PMBUS_TOFF_FALL			0x65
+
+/* MPS vendor-extended observability / identity registers */
+#define MPS_MFR_CONFIG_ID		0xC0
+#define MPS_MFR_CONFIG_CODE_REV		0xC1
+#define MPS_MFR_SILICON_REV		0xC3
+#define MPS_MFR_RETRY_TIMES		0xF4
+#define MPS_MFR_VBOOT_CFG		0xFC
+
+#define MPQ8646_DEBUG(client, fmt, ...) \
+	dev_dbg(&(client)->dev, fmt, ##__VA_ARGS__)
+
+/*
+ * Maximum legal value for VOUT_SCALE_LOOP (0x29) on the MPQ8646 silicon
+ * The chip uses an 11-bit VOUT feedback-divider scale register.
+ */
+#define MPQ8646_VOUT_SCALE_LOOP_MAX	GENMASK(10, 0)
+
+/* Forward declaration */
+struct mpq8646_dbg_reg_ctx;
+
+/* Per-instance state */
+struct mpq8646_priv {
+	struct pmbus_driver_info info;	/* must be first, container_of target */
+	struct i2c_client	*client;
+
+	/* Serialises CLEAR_LAST_FAULT sequences and PROTECTION_LAST reads */
+	struct mutex		mps_lock;
+
+	/* Set alarm_poll_interval_ms = 0 to disable. */
+	struct delayed_work	alarm_poll_work;
+	u32			alarm_poll_interval_ms;
+
+#ifdef CONFIG_DEBUG_FS
+	/* the only debugfs file that can re-arm the poll worker */
+	struct dentry		*dbg_poll;
+	struct mpq8646_dbg_reg_ctx	*dbg_reg_ctx;
+#endif
+};
+
+static inline struct mpq8646_priv *mpq8646_priv_from_client(struct i2c_client *client)
+{
+	const struct pmbus_driver_info *info = pmbus_get_driver_info(client);
+
+	return container_of(info, struct mpq8646_priv, info);
+}
+
+/*
+ * VID-mode m/b/R coefficients, same values as the mpq8785 driver for
+ * the MPS VID encoding. Per the PMBus Direct formula used by
+ * pmbus_core, X = (Y * 10^-R - b) / m, so m=64 / b=0 / R=1 yields
+ * 1.5625 mV per LSB.
+ */
+#define MPQ8646_VID_M			64
+#define MPQ8646_VID_B			0
+#define MPQ8646_VID_R			1
+
+static int mpq8646_identify(struct i2c_client *client,
+			    struct pmbus_driver_info *info)
+{
+	int vout_mode;
+
+	vout_mode = pmbus_read_byte_data(client, 0, PMBUS_VOUT_MODE);
+	if (vout_mode < 0)
+		return vout_mode;
+
+	switch (vout_mode & PB_VOUT_MODE_MODE_MASK) {
+	case PB_VOUT_MODE_LINEAR:
+		info->format[PSC_VOLTAGE_OUT] = linear;
+		break;
+	case PB_VOUT_MODE_VID:
+	case PB_VOUT_MODE_DIRECT:
+		info->format[PSC_VOLTAGE_OUT] = direct;
+		info->m[PSC_VOLTAGE_OUT] = MPQ8646_VID_M;
+		info->b[PSC_VOLTAGE_OUT] = MPQ8646_VID_B;
+		info->R[PSC_VOLTAGE_OUT] = MPQ8646_VID_R;
+		break;
+	default:
+		return -ENODEV;
+	}
+
+	return 0;
+};
+
+static int mpq8646_read_byte_data(struct i2c_client *client, int page, int reg)
+{
+	int ret;
+
+	MPQ8646_DEBUG(client, "read_byte_data page=%d reg=0x%02x\n", page, reg);
+
+	switch (reg) {
+	case PMBUS_VOUT_MODE:
+		ret = pmbus_read_byte_data(client, page, reg);
+		MPQ8646_DEBUG(client, "  VOUT_MODE raw=0x%02x ret=%d\n", ret, ret);
+		if (ret < 0)
+			return ret;
+
+		if ((ret & PB_VOUT_MODE_MODE_MASK) == PB_VOUT_MODE_VID)
+			return PB_VOUT_MODE_DIRECT;
+
+		return ret;
+	case PMBUS_STATUS_BYTE:
+	case PMBUS_STATUS_CML:
+	case PMBUS_STATUS_OTHER:
+	case PMBUS_STATUS_MFR_SPECIFIC:
+	case PMBUS_STATUS_FAN_12:
+	case PMBUS_STATUS_FAN_34:
+		return -ENXIO;
+	case PMBUS_MFR_LOCATION:
+	case PMBUS_MFR_DATE:
+	case PMBUS_MFR_SERIAL:
+	case PMBUS_IC_DEVICE_ID:
+	case PMBUS_IC_DEVICE_REV:
+		MPQ8646_DEBUG(client, "  unsupported mfr-info reg 0x%02x -> ENXIO\n", reg);
+		return -ENXIO;
+	default:
+		return -ENODATA;
+	}
+}
+
+/*
+ * Reference: ltc2978.c::ltc2978_write_word_data which uses the
+ * same virtual-register channel for its real chip-side peak reset.
+ */
+static int mpq8646_write_word_data(struct i2c_client *client, int page,
+				   int reg, u16 word)
+{
+	struct mpq8646_priv *priv = mpq8646_priv_from_client(client);
+	int rc;
+
+	switch (reg) {
+	case PMBUS_VIRT_RESET_VIN_HISTORY:
+	case PMBUS_VIRT_RESET_VOUT_HISTORY:
+	case PMBUS_VIRT_RESET_IOUT_HISTORY:
+	case PMBUS_VIRT_RESET_TEMP_HISTORY:
+		MPQ8646_DEBUG(client, "reset_history virt reg=0x%04x -> CLEAR_FAULTS\n",
+			      reg);
+		rc = i2c_smbus_write_byte(priv->client, PMBUS_CLEAR_FAULTS);
+		if (rc < 0)
+			MPQ8646_DEBUG(client, "  CLEAR_FAULTS rc=%d\n", rc);
+		return rc < 0 ? rc : 0;
+	default:
+		return -ENODATA;	/* let pmbus_core do the direct write */
+	}
+}
+
+static int mpq8646_read_word_data(struct i2c_client *client, int page,
+				  int phase, int reg)
+{
+	int rc;
+
+	MPQ8646_DEBUG(client, "read_word_data page=%d phase=%d reg=0x%02x\n",
+		      page, phase, reg);
+
+	switch (reg) {
+	case PMBUS_READ_VIN:
+	case PMBUS_READ_VOUT:
+	case PMBUS_READ_IOUT:
+	case PMBUS_READ_TEMPERATURE_1:
+	case PMBUS_STATUS_WORD:
+	case PMBUS_VOUT_OV_FAULT_LIMIT:
+	case PMBUS_VOUT_OV_WARN_LIMIT:
+	case PMBUS_VOUT_UV_WARN_LIMIT:
+	case PMBUS_VOUT_UV_FAULT_LIMIT:
+	case PMBUS_IOUT_OC_FAULT_LIMIT:
+	case PMBUS_IOUT_OC_WARN_LIMIT:
+	case PMBUS_OT_FAULT_LIMIT:
+	case PMBUS_OT_WARN_LIMIT:
+	case PMBUS_VIN_OV_FAULT_LIMIT:
+	case PMBUS_VIN_OV_WARN_LIMIT:
+	case PMBUS_VIN_UV_WARN_LIMIT:
+	case PMBUS_VIN_UV_FAULT_LIMIT:
+	case PMBUS_MFR_VIN_MAX:
+	case PMBUS_MFR_VOUT_MAX:
+	case PMBUS_MFR_IOUT_MAX:
+	case PMBUS_MFR_MAX_TEMP_1:
+		break;
+	case PMBUS_VIRT_RESET_VIN_HISTORY:
+	case PMBUS_VIRT_RESET_VOUT_HISTORY:
+	case PMBUS_VIRT_RESET_IOUT_HISTORY:
+	case PMBUS_VIRT_RESET_TEMP_HISTORY:
+		return 0;
+	default:
+		return -ENODATA;
+	}
+
+	rc = i2c_smbus_read_word_data(client, reg);
+
+	MPQ8646_DEBUG(client, "  reg=0x%02x rc=%d\n", reg, rc);
+	return rc;
+}
+
+static struct pmbus_driver_info mpq8646_info = {
+	.pages = 1,
+	.format[PSC_VOLTAGE_IN] = direct,
+	.format[PSC_CURRENT_OUT] = direct,
+	.format[PSC_TEMPERATURE] = direct,
+	.m[PSC_VOLTAGE_IN] = 4,
+	.b[PSC_VOLTAGE_IN] = 0,
+	.R[PSC_VOLTAGE_IN] = 1,
+	.m[PSC_CURRENT_OUT] = 16,
+	.b[PSC_CURRENT_OUT] = 0,
+	.R[PSC_CURRENT_OUT] = 0,
+	.m[PSC_TEMPERATURE] = 1,
+	.b[PSC_TEMPERATURE] = 0,
+	.R[PSC_TEMPERATURE] = 0,
+	.func[0] = PMBUS_HAVE_VIN | PMBUS_HAVE_VOUT |
+		   PMBUS_HAVE_IOUT | PMBUS_HAVE_TEMP |
+		   PMBUS_HAVE_STATUS_INPUT | PMBUS_HAVE_STATUS_VOUT |
+		   PMBUS_HAVE_STATUS_IOUT | PMBUS_HAVE_STATUS_TEMP,
+};
+
+#if IS_ENABLED(CONFIG_REGULATOR)
+static const struct regulator_desc mpq8646_reg_desc[] = {
+	PMBUS_REGULATOR("vout", 0),
+};
+#endif /* CONFIG_REGULATOR */
+
+#if IS_ENABLED(CONFIG_NVMEM)
+/*
+ * Expose using
+ *   /sys/bus/nvmem/devices/<i2c-name>/nvmem
+ *
+ * Layout (16 bytes):
+ *   offset 0..1   PROTECTION_LAST (0xFB)    word, LE     -- NVM
+ *   offset 2..3   MFR_RETRY_TIMES (0xF4)    word, LE     -- NVM
+ *   offset 4..5   MFR_CONFIG_ID   (0xC0)    word, LE     -- NVM
+ *   offset 6..7   MFR_VBOOT_CFG   (0xFC)    word, LE     -- NVM
+ *   offset 8      MFR_SILICON_REV (0xC3)    byte         -- NVM
+ *   offset 9..15  reserved (zero-fill, leaves room for additions)
+ */
+#define MPQ8646_NVMEM_SIZE	16
+
+struct mpq8646_nvmem_entry {
+	unsigned int	off;
+	u8		reg;
+	bool		is_word;
+};
+
+static const struct mpq8646_nvmem_entry mpq8646_nvmem_map[] = {
+	{ 0, MPS_PROTECTION_LAST, true  },
+	{ 2, MPS_MFR_RETRY_TIMES, true  },
+	{ 4, MPS_MFR_CONFIG_ID,   true  },
+	{ 6, MPS_MFR_VBOOT_CFG,   true  },
+	{ 8, MPS_MFR_SILICON_REV, false },
+};
+
+static int mpq8646_nvmem_read(void *data, unsigned int offset, void *val,
+			      size_t bytes)
+{
+	struct mpq8646_priv *priv = data;
+	u8 *out = val;
+	size_t i;
+
+	if (offset >= MPQ8646_NVMEM_SIZE)
+		return -EINVAL;
+	if (offset + bytes > MPQ8646_NVMEM_SIZE)
+		bytes = MPQ8646_NVMEM_SIZE - offset;
+
+	memset(out, 0, bytes);
+
+	guard(mutex)(&priv->mps_lock);
+	for (i = 0; i < ARRAY_SIZE(mpq8646_nvmem_map); i++) {
+		const struct mpq8646_nvmem_entry *e = &mpq8646_nvmem_map[i];
+		unsigned int e_start = e->off;
+		unsigned int e_end = e_start + (e->is_word ? 2 : 1);
+		u8 raw[2];
+		int rc;
+		unsigned int j;
+
+		if (e_end <= offset || e_start >= offset + bytes)
+			continue;	/* outside requested slice */
+
+		if (e->is_word)
+			rc = i2c_smbus_read_word_data(priv->client, e->reg);
+		else
+			rc = i2c_smbus_read_byte_data(priv->client, e->reg);
+		if (rc < 0)
+			continue;	/* leave the zero-fill in place */
+
+		raw[0] = rc & 0xff;
+		raw[1] = (rc >> 8) & 0xff;
+
+		for (j = 0; j < e_end - e_start; j++) {
+			unsigned int abs = e_start + j;
+
+			if (abs >= offset && abs < offset + bytes)
+				out[abs - offset] = raw[j];
+		}
+	}
+	return 0;
+}
+#endif /* CONFIG_NVMEM */
+
+static const struct i2c_device_id mpq8646_id[] = {
+	{ .name = "mpq8646" },
+	{ },
+};
+MODULE_DEVICE_TABLE(i2c, mpq8646_id);
+
+static const struct of_device_id __maybe_unused mpq8646_of_match[] = {
+	{ .compatible = "mps,mpq8646" },
+	{}
+};
+MODULE_DEVICE_TABLE(of, mpq8646_of_match);
+
+static struct pmbus_platform_data mpq8646_no_pec_pdata = {
+	.flags = PMBUS_NO_CAPABILITY,
+};
+
+#ifdef CONFIG_DEBUG_FS
+/*
+ * Read-only decode cases in the client's pmbus debugfs directory:
+ * the MPS-specific STATUS_WORD and PROTECTION_LAST bit decode plus the
+ * identity/timing registers.
+ */
+
+struct mpq_status_bit {
+	u16		mask;
+	const char	*name;
+};
+
+static const struct mpq_status_bit mpq8646_status_word_bits[] = {
+	{ PB_STATUS_VOUT,         "VOUT" },
+	{ PB_STATUS_IOUT_POUT,    "IOUT_POUT" },
+	{ PB_STATUS_INPUT,        "INPUT" },
+	{ PB_STATUS_WORD_MFR,     "NVM_SUMMARY" },
+	{ PB_STATUS_POWER_GOOD_N, "POWER_GOOD#" },
+	{ PB_STATUS_FANS,         "FANS" },
+	{ PB_STATUS_OTHER,        "OTHER" },
+	{ PB_STATUS_UNKNOWN,      "WATCH_DOG" },
+	{ PB_STATUS_BUSY,         "BUSY" },
+	{ PB_STATUS_OFF,          "OFF" },
+	{ PB_STATUS_VOUT_OV,      "VOUT_OV_FAULT" },
+	{ PB_STATUS_IOUT_OC,      "IOUT_OC_FAULT" },
+	{ PB_STATUS_VIN_UV,       "VIN_UV_FAULT" },
+	{ PB_STATUS_TEMPERATURE,  "TEMP" },
+	{ PB_STATUS_CML,          "CML" },
+	{ PB_STATUS_NONE_ABOVE,   "DRMOS_FAULT" },
+	{ /* sentinel */ }
+};
+
+/* PROTECTION_LAST (0xFB) bit names, it survives chip POR */
+static const struct mpq_status_bit mpq8646_protection_last_bits[] = {
+	{ BIT(15), "INIT_FAULT" },
+	{ BIT(14), "NVM_CRC_ERROR" },
+	{ BIT(13), "NVM_FAULT" },
+	{ BIT(12), "OC_PHASE_FAULT" },
+	{ BIT(11), "OTP_SELF_FAULT" },
+	{ BIT(9),  "SWITCH_PRD_FAULT" },
+	{ BIT(8),  "VIN_OV_FAULT" },
+	{ BIT(7),  "VOUT_OV_FAULT" },
+	{ BIT(6),  "VOUT_UV_FAULT" },
+	{ BIT(5),  "OC_TOT_FAULT" },
+	{ BIT(4),  "VIN_UVLO_FAULT" },
+	{ BIT(3),  "DRMOS_OTP" },
+	{ /* sentinel */ }
+};
+
+static void mpq8646_print_bits(struct seq_file *s, u16 v,
+			       const struct mpq_status_bit *tab)
+{
+	const struct mpq_status_bit *t;
+	bool first = true;
+
+	seq_printf(s, "0x%04x", v);
+	if (!v) {
+		seq_puts(s, " [clean]\n");
+		return;
+	}
+	seq_puts(s, " [");
+	for (t = tab; t->mask; t++) {
+		if (v & t->mask) {
+			if (!first)
+				seq_putc(s, ' ');
+			seq_puts(s, t->name);
+			first = false;
+		}
+	}
+	seq_puts(s, "]\n");
+}
+
+static int mpq8646_dbg_status_decoded_show(struct seq_file *s, void *unused)
+{
+	struct mpq8646_priv *priv = s->private;
+	int rc;
+
+	scoped_guard(pmbus_lock, priv->client)
+		rc = i2c_smbus_read_word_data(priv->client, PMBUS_STATUS_WORD);
+	if (rc < 0) {
+		seq_printf(s, "ERROR: STATUS_WORD read failed (%d)\n", rc);
+		return 0;
+	}
+	seq_puts(s, "STATUS_WORD: ");
+	mpq8646_print_bits(s, (u16)rc, mpq8646_status_word_bits);
+	seq_puts(s, "(MPS extensions: bit12=NVM_SUMMARY, bit8=WATCH_DOG, bit0=DRMOS_FAULT)\n");
+	return 0;
+}
+DEFINE_SHOW_ATTRIBUTE(mpq8646_dbg_status_decoded);
+
+static int mpq8646_dbg_protection_last_show(struct seq_file *s, void *unused)
+{
+	struct mpq8646_priv *priv = s->private;
+	int rc;
+
+	guard(pmbus_lock)(priv->client);
+	scoped_guard(mutex, &priv->mps_lock)
+		rc = i2c_smbus_read_word_data(priv->client, MPS_PROTECTION_LAST);
+
+	if (rc < 0) {
+		seq_printf(s, "ERROR: PROTECTION_LAST read failed (%d)\n", rc);
+		return 0;
+	}
+	seq_puts(s, "PROTECTION_LAST: ");
+	mpq8646_print_bits(s, (u16)rc, mpq8646_protection_last_bits);
+	seq_puts(s, "(NVM-backed, survives chip POR)\n");
+	return 0;
+}
+DEFINE_SHOW_ATTRIBUTE(mpq8646_dbg_protection_last);
+
+struct mpq8646_dbg_reg {
+	u8		reg;
+	bool		is_word;
+	const char	*name;
+};
+
+static const struct mpq8646_dbg_reg mpq8646_dbg_regs[] = {
+	/* MPS vendor extensions (read-only identity / observability) */
+	{ MPS_MFR_CONFIG_ID,        true,  "mfr_config_id" },
+	{ MPS_MFR_CONFIG_CODE_REV,  true,  "mfr_config_code_rev" },
+	{ MPS_MFR_SILICON_REV,      false, "mfr_silicon_rev" },
+	{ MPS_MFR_RETRY_TIMES,      true,  "mfr_retry_times" },
+	{ MPS_MFR_VBOOT_CFG,        true,  "mfr_vboot_cfg" },
+	/* PMBus 1.3 standard timing / UVLO (read-only introspection) */
+	{ PMBUS_VIN_ON,             true,  "vin_on" },
+	{ PMBUS_VIN_OFF,            true,  "vin_off" },
+	{ PMBUS_TON_DELAY,          true,  "ton_delay" },
+	{ PMBUS_TON_RISE,           true,  "ton_rise" },
+	{ PMBUS_TOFF_DELAY,         true,  "toff_delay" },
+	{ PMBUS_TOFF_FALL,          true,  "toff_fall" },
+};
+
+struct mpq8646_dbg_reg_ctx {
+	struct mpq8646_priv		*priv;
+	const struct mpq8646_dbg_reg	*desc;
+};
+
+static int mpq8646_dbg_reg_show(struct seq_file *s, void *unused)
+{
+	struct mpq8646_dbg_reg_ctx *ctx = s->private;
+	int rc;
+
+	guard(pmbus_lock)(ctx->priv->client);
+	if (ctx->desc->is_word)
+		rc = i2c_smbus_read_word_data(ctx->priv->client,
+					      ctx->desc->reg);
+	else
+		rc = i2c_smbus_read_byte_data(ctx->priv->client,
+					      ctx->desc->reg);
+
+	if (rc < 0) {
+		seq_printf(s, "ERROR: reg 0x%02x (%s) read failed (%d)\n",
+			   ctx->desc->reg, ctx->desc->name, rc);
+		return 0;
+	}
+	seq_printf(s, "0x%0*x\n", ctx->desc->is_word ? 4 : 2, rc);
+	return 0;
+}
+DEFINE_SHOW_ATTRIBUTE(mpq8646_dbg_reg);
+
+static int mpq8646_dbg_poll_interval_get(void *data, u64 *val)
+{
+	struct mpq8646_priv *priv = data;
+
+	*val = priv->alarm_poll_interval_ms;
+	return 0;
+}
+
+static int mpq8646_dbg_poll_interval_set(void *data, u64 val)
+{
+	struct mpq8646_priv *priv = data;
+	bool was_off = !priv->alarm_poll_interval_ms;
+
+	priv->alarm_poll_interval_ms = (u32)val;
+
+	if (val && was_off && !priv->client->irq)
+		schedule_delayed_work(&priv->alarm_poll_work,
+				      msecs_to_jiffies((u32)val));
+	return 0;
+}
+DEFINE_DEBUGFS_ATTRIBUTE(mpq8646_dbg_poll_interval_fops,
+			 mpq8646_dbg_poll_interval_get,
+			 mpq8646_dbg_poll_interval_set, "%llu\n");
+
+static void mpq8646_debugfs_register(struct mpq8646_priv *priv)
+{
+	struct dentry *root;
+	size_t i;
+
+	root = pmbus_get_debugfs_dir(priv->client);
+	if (!root)
+		return;
+
+	/* MPS extensions: status decode + NVM-backed PROTECTION_LAST */
+	debugfs_create_file("status_decoded", 0400, root, priv,
+			    &mpq8646_dbg_status_decoded_fops);
+	debugfs_create_file("protection_last", 0400, root, priv,
+			    &mpq8646_dbg_protection_last_fops);
+	priv->dbg_poll =
+		debugfs_create_file_unsafe("alarm_poll_interval_ms", 0600,
+					   root, priv,
+					   &mpq8646_dbg_poll_interval_fops);
+
+	priv->dbg_reg_ctx = devm_kcalloc(&priv->client->dev,
+					 ARRAY_SIZE(mpq8646_dbg_regs),
+					 sizeof(*priv->dbg_reg_ctx),
+					 GFP_KERNEL);
+	if (!priv->dbg_reg_ctx)
+		return;
+	for (i = 0; i < ARRAY_SIZE(mpq8646_dbg_regs); i++) {
+		priv->dbg_reg_ctx[i].priv = priv;
+		priv->dbg_reg_ctx[i].desc = &mpq8646_dbg_regs[i];
+		debugfs_create_file(mpq8646_dbg_regs[i].name, 0400,
+				    root, &priv->dbg_reg_ctx[i],
+				    &mpq8646_dbg_reg_fops);
+	}
+}
+
+static void mpq8646_debugfs_unregister(struct mpq8646_priv *priv)
+{
+	debugfs_remove(priv->dbg_poll);
+}
+#else
+static inline void mpq8646_debugfs_register(struct mpq8646_priv *priv) {}
+static inline void mpq8646_debugfs_unregister(struct mpq8646_priv *priv) {}
+#endif /* CONFIG_DEBUG_FS */
+
+static void mpq8646_alarm_poll_work(struct work_struct *work)
+{
+	struct mpq8646_priv *priv = container_of(to_delayed_work(work),
+						 struct mpq8646_priv,
+						 alarm_poll_work);
+
+	if (priv->client->irq)
+		return;	/* SMBALERT# wired; polling not needed */
+
+	if (!priv->alarm_poll_interval_ms)
+		return;	/* polling disabled; don't re-arm */
+
+	pmbus_check_and_notify_faults(priv->client);
+
+	schedule_delayed_work(&priv->alarm_poll_work,
+			      msecs_to_jiffies(priv->alarm_poll_interval_ms));
+}
+
+static int mpq8646_probe(struct i2c_client *client)
+{
+	struct device *dev = &client->dev;
+	struct pmbus_driver_info *info;
+	struct mpq8646_priv *priv;
+	u32 voltage_scale;
+	int ret;
+
+	priv = devm_kzalloc(dev, sizeof(*priv), GFP_KERNEL);
+	if (!priv)
+		return -ENOMEM;
+	priv->client = client;
+	mutex_init(&priv->mps_lock);
+	memcpy(&priv->info, &mpq8646_info, sizeof(priv->info));
+	info = &priv->info;
+
+	info->identify = mpq8646_identify;
+	info->read_byte_data = mpq8646_read_byte_data;
+	info->read_word_data = mpq8646_read_word_data;
+	info->write_word_data = mpq8646_write_word_data;
+	dev->platform_data = &mpq8646_no_pec_pdata;
+
+#if IS_ENABLED(CONFIG_REGULATOR)
+	info->reg_desc = mpq8646_reg_desc;
+	info->num_regulators = ARRAY_SIZE(mpq8646_reg_desc);
+#endif
+
+	INIT_DELAYED_WORK(&priv->alarm_poll_work, mpq8646_alarm_poll_work);
+	priv->alarm_poll_interval_ms = MPQ8646_ALARM_POLL_MS_DEFAULT;
+
+	if (!device_property_read_u32(dev, "mps,vout-fb-divider-ratio-permille",
+				      &voltage_scale)) {
+		if (voltage_scale > MPQ8646_VOUT_SCALE_LOOP_MAX)
+			return -EINVAL;
+
+		ret = i2c_smbus_write_word_data(client, PMBUS_VOUT_SCALE_LOOP,
+						voltage_scale);
+		if (ret)
+			return ret;
+	}
+
+	ret = pmbus_do_probe(client, info);
+	if (ret)
+		return ret;
+
+	mpq8646_debugfs_register(priv);
+
+	if (!client->irq)
+		schedule_delayed_work(&priv->alarm_poll_work,
+				      msecs_to_jiffies(priv->alarm_poll_interval_ms));
+
+#if IS_ENABLED(CONFIG_NVMEM)
+	{
+		struct nvmem_config cfg = {
+			.dev		= &client->dev,
+			.name		= dev_name(&client->dev),
+			.owner		= THIS_MODULE,
+			.read_only	= true,
+			.root_only	= true,
+			.word_size	= 1,
+			.stride		= 1,
+			.size		= MPQ8646_NVMEM_SIZE,
+			.reg_read	= mpq8646_nvmem_read,
+			.priv		= priv,
+		};
+		struct nvmem_device *nv = devm_nvmem_register(&client->dev, &cfg);
+
+		if (IS_ERR(nv))
+			dev_warn(&client->dev,
+				 "nvmem snapshot register failed (%pe)\n",
+				 nv);
+	}
+#endif
+	return 0;
+};
+
+static void mpq8646_remove(struct i2c_client *client)
+{
+	struct mpq8646_priv *priv = mpq8646_priv_from_client(client);
+
+	mpq8646_debugfs_unregister(priv);
+	cancel_delayed_work_sync(&priv->alarm_poll_work);
+}
+
+static struct i2c_driver mpq8646_driver = {
+	.driver = {
+		   .name = "mpq8646",
+		   .of_match_table = of_match_ptr(mpq8646_of_match),
+	},
+	.probe = mpq8646_probe,
+	.remove = mpq8646_remove,
+	.id_table = mpq8646_id,
+};
+
+module_i2c_driver(mpq8646_driver);
+
+MODULE_AUTHOR("Vincent Jardin <vjardin@free.fr>");
+MODULE_DESCRIPTION("PMBus driver for MPS MPQ8646 (extended observability)");
+MODULE_LICENSE("GPL");
+MODULE_IMPORT_NS("PMBUS");

-- 
2.43.0

