From: Angel Gabriel Crispin Valdivia <angelcrispinvaldivia@gmail.com>
Date: Thu, 05 Nov 2026 21:34:33 -0500
Subject: [PATCH RFC 1/4] drm/fl2000: Add USB driver with register and I2C
 access
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-fl2000-upstream-v1-1-bb163ecb2309@gmail.com>
References: <20261105-fl2000-upstream-v1-0-bb163ecb2309@gmail.com>
In-Reply-To: <20261105-fl2000-upstream-v1-0-bb163ecb2309@gmail.com>
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Angel Gabriel Crispin Valdivia <angelcrispinvaldivia@gmail.com>
Cc: linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793932482; l=40703;
 i=angelcrispinvaldivia@gmail.com; s=20261106; h=from:subject:message-id;
 bh=JTHGCKQj0/0JHjDIQpllttA/ez67tTJv7hDjXfwm/sg=;
 b=fye7SSyc/0HDj5ds4k6ywum5Aaz0yF6moB5OAQdo0dKvxzwKtbx6YyhNGOQekPsy7m0u8ALA7
 wzVzwbS8mnKABGrB0z/H7vKPD7mEPZC5mqRCtBntgzgHc9CeaQHVKt9
X-Developer-Key: i=angelcrispinvaldivia@gmail.com; a=ed25519;
 pk=80bQU/p2R0pLIfdfJaB5I/2obI+RxQHondq5DEM0tbg=
X-Endpoint-Received: by B4 Relay for angelcrispinvaldivia@gmail.com/20261106 with auth_id=1425
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Fresco Logic FL2000DX is a USB 3.0 display controller used in
inexpensive USB to VGA and USB to HDMI adapters (USB ID 1d5c:2000). The
FL2000 itself outputs parallel RGB/VGA; HDMI adapters pair it with an
ITE IT66121 HDMI transmitter that sits on the FL2000's I2C bus.

This first patch adds the USB side of the driver: it binds the three
FL2000 interfaces, describes the FL2000 registers, provides a regmap on
top of the vendor control transfers that access them, and registers an
I2C adapter backed by the FL2000 I2C engine. The engine only transfers
aligned 32-bit words, so byte accesses are done as read-modify-write of
the containing word and the adapter advertises the matching quirks.

State shared by the interfaces is attached to the usb_device so that it
survives the unbind/rebind cycles of usb_reset_device().

The driver is based on the out-of-tree fl2000_drm driver by Artem
Mygaiev, which carries code from the Fresco Logic reference driver.

Signed-off-by: Angel Gabriel Crispin Valdivia <angelcrispinvaldivia@gmail.com>
---
 MAINTAINERS                               |   7 +
 drivers/gpu/drm/Kconfig                   |   1 +
 drivers/gpu/drm/Makefile                  |   1 +
 drivers/gpu/drm/fl2000/Kconfig            |  19 ++
 drivers/gpu/drm/fl2000/Makefile           |   8 +
 drivers/gpu/drm/fl2000/fl2000.h           |  88 ++++++++
 drivers/gpu/drm/fl2000/fl2000_drv.c       | 150 ++++++++++++++
 drivers/gpu/drm/fl2000/fl2000_i2c.c       | 182 +++++++++++++++++
 drivers/gpu/drm/fl2000/fl2000_registers.c | 320 ++++++++++++++++++++++++++++++
 drivers/gpu/drm/fl2000/fl2000_registers.h | 272 +++++++++++++++++++++++++
 10 files changed, 1048 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index c10342aa3..6e74cb478 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -8324,6 +8324,13 @@ F:	include/linux/aperture.h
 F:	include/linux/sysfb.h
 F:	include/video/nomodeset.h
 
+DRM DRIVER FOR FRESCO LOGIC FL2000 USB DISPLAY ADAPTERS
+M:	Angel Gabriel Crispin Valdivia <angelcrispinvaldivia@gmail.com>
+L:	dri-devel@lists.freedesktop.org
+S:	Maintained
+T:	git https://gitlab.freedesktop.org/drm/misc/kernel.git
+F:	drivers/gpu/drm/fl2000/
+
 DRM DRIVER FOR GENERIC EDP PANELS
 R:	Douglas Anderson <dianders@chromium.org>
 F:	Documentation/devicetree/bindings/display/panel/panel-edp.yaml
diff --git a/drivers/gpu/drm/Kconfig b/drivers/gpu/drm/Kconfig
index 61111d50b..6ff093830 100644
--- a/drivers/gpu/drm/Kconfig
+++ b/drivers/gpu/drm/Kconfig
@@ -313,6 +313,7 @@ source "drivers/gpu/drm/atmel-hlcdc/Kconfig"
 source "drivers/gpu/drm/bridge/Kconfig"
 source "drivers/gpu/drm/etnaviv/Kconfig"
 source "drivers/gpu/drm/exynos/Kconfig"
+source "drivers/gpu/drm/fl2000/Kconfig"
 source "drivers/gpu/drm/fsl-dcu/Kconfig"
 source "drivers/gpu/drm/gma500/Kconfig"
 source "drivers/gpu/drm/gud/Kconfig"
diff --git a/drivers/gpu/drm/Makefile b/drivers/gpu/drm/Makefile
index 2c6bc093a..a4a8a958a 100644
--- a/drivers/gpu/drm/Makefile
+++ b/drivers/gpu/drm/Makefile
@@ -190,6 +190,7 @@ obj-$(CONFIG_DRM_NOUVEAU) +=nouveau/
 obj-$(CONFIG_DRM_EXYNOS) +=exynos/
 obj-$(CONFIG_DRM_ROCKCHIP) +=rockchip/
 obj-$(CONFIG_DRM_GMA500) += gma500/
+obj-$(CONFIG_DRM_FL2000) += fl2000/
 obj-$(CONFIG_DRM_UDL) += udl/
 obj-$(CONFIG_DRM_AST) += ast/
 obj-$(CONFIG_DRM_ARMADA) += armada/
diff --git a/drivers/gpu/drm/fl2000/Kconfig b/drivers/gpu/drm/fl2000/Kconfig
new file mode 100644
index 000000000..bf1badc3e
--- /dev/null
+++ b/drivers/gpu/drm/fl2000/Kconfig
@@ -0,0 +1,19 @@
+# SPDX-License-Identifier: GPL-2.0-only
+config DRM_FL2000
+	tristate "Fresco Logic FL2000 USB display adapters"
+	depends on DRM && USB && MMU
+	depends on USB_ARCH_HAS_HCD
+	select DRM_BRIDGE_CONNECTOR
+	select DRM_CLIENT_SELECTION
+	select DRM_DISPLAY_HELPER
+	select DRM_GEM_SHMEM_HELPER
+	select DRM_KMS_HELPER
+	select I2C
+	select REGMAP
+	select REGMAP_I2C
+	help
+	  This is a KMS driver for USB display adapters based on the
+	  Fresco Logic FL2000DX USB 3.0 to VGA controller, paired with an
+	  ITE IT66121 HDMI transmitter (USB ID 1d5c:2000).
+
+	  If M is selected the module will be called fl2000.
diff --git a/drivers/gpu/drm/fl2000/Makefile b/drivers/gpu/drm/fl2000/Makefile
new file mode 100644
index 000000000..2b3a2f151
--- /dev/null
+++ b/drivers/gpu/drm/fl2000/Makefile
@@ -0,0 +1,8 @@
+# SPDX-License-Identifier: GPL-2.0-only
+
+fl2000-y := \
+	fl2000_drv.o \
+	fl2000_i2c.o \
+	fl2000_registers.o
+
+obj-$(CONFIG_DRM_FL2000) += fl2000.o
diff --git a/drivers/gpu/drm/fl2000/fl2000.h b/drivers/gpu/drm/fl2000/fl2000.h
new file mode 100644
index 000000000..956032479
--- /dev/null
+++ b/drivers/gpu/drm/fl2000/fl2000.h
@@ -0,0 +1,88 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * (C) Copyright 2017, Fresco Logic, Incorporated.
+ * (C) Copyright 2018-2020, Artem Mygaiev
+ */
+
+#ifndef FL2000_H
+#define FL2000_H
+
+#include <linux/component.h>
+#include <linux/device.h>
+#include <linux/i2c.h>
+#include <linux/module.h>
+#include <linux/regmap.h>
+#include <linux/types.h>
+#include <linux/usb.h>
+
+#include <drm/drm_atomic_helper.h>
+#include <drm/drm_bridge.h>
+#include <drm/drm_crtc.h>
+#include <drm/drm_damage_helper.h>
+#include <drm/drm_device.h>
+#include <drm/drm_drv.h>
+#include <drm/drm_fourcc.h>
+#include <drm/drm_framebuffer.h>
+#include <drm/drm_gem_framebuffer_helper.h>
+#include <drm/drm_gem_shmem_helper.h>
+#include <drm/drm_print.h>
+#include <drm/drm_probe_helper.h>
+#include <drm/drm_crtc_helper.h>
+#include <drm/drm_plane.h>
+#include <drm/drm_encoder.h>
+#include <drm/drm_modeset_helper_vtables.h>
+#include <drm/drm_vblank.h>
+
+#include "fl2000_registers.h"
+
+/* Known USB interfaces of FL2000 */
+enum fl2000_interface {
+	FL2000_USBIF_AVCONTROL = 0,
+	FL2000_USBIF_STREAMING = 1,
+	FL2000_USBIF_INTERRUPT = 2,
+};
+
+struct fl2000_timings {
+	u32 hactive;
+	u32 htotal;
+	u32 hsync_width;
+	u32 hstart;
+	u32 vactive;
+	u32 vtotal;
+	u32 vsync_width;
+	u32 vstart;
+};
+
+struct fl2000_pll {
+	u32 prescaler;
+	u32 multiplier;
+	u32 divisor;
+	u32 function;
+};
+
+/* Polling interval and timeout in us for I2C read/write operations */
+#define I2C_RDWR_INTERVAL 200
+#define I2C_RDWR_TIMEOUT  (256 * 1000)
+
+/* I2C adapter interface creation */
+struct i2c_adapter *fl2000_i2c_init(struct usb_device *usb_dev);
+int fl2000_ddc_read_block(struct i2c_adapter *adapter, u8 *buf, unsigned int block, size_t len);
+
+/* Register map creation */
+struct regmap *fl2000_regmap_init(struct usb_device *usb_dev);
+void fl2000_regmap_drop_cache(struct usb_device *usb_dev);
+
+/* Registers interface */
+int fl2000_reset(struct usb_device *usb_dev);
+int fl2000_usb_magic(struct usb_device *usb_dev);
+int fl2000_afe_magic(struct usb_device *usb_dev);
+int fl2000_set_transfers(struct usb_device *usb_dev);
+int fl2000_set_pixfmt(struct usb_device *usb_dev, u32 bytes_pix);
+int fl2000_set_timings(struct usb_device *usb_dev, struct fl2000_timings *timings);
+int fl2000_set_pll(struct usb_device *usb_dev, struct fl2000_pll *pll);
+int fl2000_force_connect(struct usb_device *usb_dev, bool force);
+int fl2000_enable_interrupts(struct usb_device *usb_dev);
+int fl2000_read_status(struct usb_device *usb_dev, u32 *status);
+int fl2000_i2c_dword(struct usb_device *usb_dev, bool read, u16 addr, u8 offset, u32 *data);
+
+#endif /* FL2000_H */
diff --git a/drivers/gpu/drm/fl2000/fl2000_drv.c b/drivers/gpu/drm/fl2000/fl2000_drv.c
new file mode 100644
index 000000000..ea089d3c1
--- /dev/null
+++ b/drivers/gpu/drm/fl2000/fl2000_drv.c
@@ -0,0 +1,150 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * (C) Copyright 2017, Fresco Logic, Incorporated.
+ * (C) Copyright 2018-2020, Artem Mygaiev
+ */
+
+#include "fl2000.h"
+
+#define USB_CLASS_AV		0x10
+#define USB_SUBCLASS_AV_CONTROL 0x01
+#define USB_SUBCLASS_AV_VIDEO	0x02
+#define USB_SUBCLASS_AV_AUDIO	0x03
+
+#define USB_VENDOR_FRESCO_LOGIC 0x1D5C
+#define USB_PRODUCT_FL2000	0x2000
+
+static const struct usb_device_id fl2000_id_table[] = {
+	{ USB_DEVICE_INTERFACE_CLASS(USB_VENDOR_FRESCO_LOGIC, USB_PRODUCT_FL2000, USB_CLASS_AV) },
+	{},
+};
+MODULE_DEVICE_TABLE(usb, fl2000_id_table);
+
+/* Devices that are independent of interfaces, created for the lifetime of the USB device */
+struct fl2000_devs {
+	struct regmap *regmap;
+	struct i2c_adapter *adapter;
+	int active_if;
+};
+
+static struct fl2000_devs *fl2000_get_devices(struct usb_device *usb_dev)
+{
+	struct fl2000_devs *devs;
+
+	devs = devm_kzalloc(&usb_dev->dev, sizeof(*devs), GFP_KERNEL);
+	if (!devs)
+		return ERR_PTR(-ENOMEM);
+
+	devs->regmap = fl2000_regmap_init(usb_dev);
+	if (IS_ERR(devs->regmap)) {
+		dev_err(&usb_dev->dev, "Cannot initialize regmap (%pe)\n", devs->regmap);
+		return ERR_CAST(devs->regmap);
+	}
+
+	devs->adapter = fl2000_i2c_init(usb_dev);
+	if (IS_ERR(devs->adapter)) {
+		dev_err(&usb_dev->dev, "Cannot initialize I2C adapter (%pe)\n", devs->adapter);
+		return ERR_CAST(devs->adapter);
+	}
+
+	dev_set_drvdata(&usb_dev->dev, devs);
+
+	return devs;
+}
+
+static int fl2000_probe(struct usb_interface *interface, const struct usb_device_id *usb_dev_id)
+{
+	int ret = 0;
+	u8 iface_num = interface->cur_altsetting->desc.bInterfaceNumber;
+	struct usb_device *usb_dev = interface_to_usbdev(interface);
+	struct fl2000_devs *devs = dev_get_drvdata(&usb_dev->dev);
+
+	if (usb_dev->speed < USB_SPEED_HIGH) {
+		dev_err(&usb_dev->dev, "USB 1.1 is not supported\n");
+		return -ENODEV;
+	}
+
+	if (!devs) {
+		devs = fl2000_get_devices(usb_dev);
+		if (IS_ERR(devs))
+			return PTR_ERR(devs);
+	}
+
+	switch (iface_num) {
+	case FL2000_USBIF_AVCONTROL:
+	case FL2000_USBIF_STREAMING:
+	case FL2000_USBIF_INTERRUPT:
+		devs->active_if |= BIT(iface_num);
+		break;
+
+	default:
+		/* Device does not have any other interfaces */
+		dev_warn(&interface->dev, "Unexpected interface %d\n", iface_num);
+		ret = -ENODEV;
+		break;
+	}
+
+	return ret;
+}
+
+static void fl2000_disconnect(struct usb_interface *interface)
+{
+	u8 iface_num = interface->cur_altsetting->desc.bInterfaceNumber;
+	struct usb_device *usb_dev = interface_to_usbdev(interface);
+	struct fl2000_devs *devs = dev_get_drvdata(&usb_dev->dev);
+
+	if (!devs)
+		return;
+
+	switch (iface_num) {
+	case FL2000_USBIF_AVCONTROL:
+	case FL2000_USBIF_STREAMING:
+	case FL2000_USBIF_INTERRUPT:
+		devs->active_if &= ~BIT(iface_num);
+		break;
+
+	default:
+		/* Device does not have any other interfaces */
+		dev_warn(&interface->dev, "Unexpected interface %d\n", iface_num);
+		break;
+	}
+}
+
+static int fl2000_suspend(struct usb_interface *interface, pm_message_t message)
+{
+	struct usb_device *usb_dev = interface_to_usbdev(interface);
+
+	/*
+	 * Nothing to save yet. Providing the callback keeps the USB core from
+	 * unbinding the driver across system sleep.
+	 */
+	dev_dbg(&usb_dev->dev, "suspend\n");
+
+	return 0;
+}
+
+static int fl2000_resume(struct usb_interface *interface)
+{
+	struct usb_device *usb_dev = interface_to_usbdev(interface);
+
+	dev_dbg(&usb_dev->dev, "resume\n");
+
+	return 0;
+}
+
+static struct usb_driver fl2000_driver = {
+	.name = KBUILD_MODNAME,
+	.probe = fl2000_probe,
+	.disconnect = fl2000_disconnect,
+	.suspend = fl2000_suspend,
+	.resume = fl2000_resume,
+	.id_table = fl2000_id_table,
+	.supports_autosuspend = false,
+	.disable_hub_initiated_lpm = true,
+};
+
+module_usb_driver(fl2000_driver);
+
+MODULE_AUTHOR("Artem Mygaiev");
+MODULE_DESCRIPTION("FL2000 USB display driver");
+MODULE_LICENSE("GPL");
diff --git a/drivers/gpu/drm/fl2000/fl2000_i2c.c b/drivers/gpu/drm/fl2000/fl2000_i2c.c
new file mode 100644
index 000000000..eadbe0f67
--- /dev/null
+++ b/drivers/gpu/drm/fl2000/fl2000_i2c.c
@@ -0,0 +1,182 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * (C) Copyright 2017, Fresco Logic, Incorporated.
+ * (C) Copyright 2018-2019, Artem Mygaiev
+ */
+
+#include <linux/unaligned.h>
+
+#include <drm/drm_edid.h>
+
+#include "fl2000.h"
+
+/*
+ * The I2C controller requires a mandatory 8-bit sub-address for any read/write operation. Each
+ * read or write operates on 8-bit data. Every exchange shall consist of 2 messages (sub-address +
+ * data) combined. The USB transfer always aligns the address to a 4-byte boundary.
+ */
+#define I2C_CMESSAGES_NUM  2
+#define I2C_REG_ADDR_SIZE  (sizeof(u8))
+#define I2C_REG_DATA_SIZE  (sizeof(u8))
+#define I2C_XFER_ADDR_MASK (~0x3ul)
+
+static inline int fl2000_i2c_read_dword(struct usb_device *usb_dev, u16 addr, u8 offset, u32 *data)
+{
+	return fl2000_i2c_dword(usb_dev, true, addr, offset, data);
+}
+
+static inline int fl2000_i2c_write_dword(struct usb_device *usb_dev, u16 addr, u8 offset, u32 *data)
+{
+	return fl2000_i2c_dword(usb_dev, false, addr, offset, data);
+}
+
+static int fl2000_i2c_xfer(struct i2c_adapter *adapter, struct i2c_msg *msgs, int num)
+{
+	int ret;
+	bool read;
+	u16 addr;
+	u8 idx;
+	u8 offset;
+	u32 data;
+
+	addr = msgs[0].addr;
+	offset = msgs[0].buf[0] & I2C_XFER_ADDR_MASK;
+	idx = msgs[0].buf[0] - offset;
+
+	/*
+	 * We expect the following:
+	 * - 2 messages, each 1 byte, first write then read
+	 * - 1 message, 2 bytes, write
+	 */
+	if (num == 2) {
+		read = true;
+	} else if (num == 1) {
+		if (msgs[0].len == 2 && !(msgs[0].flags & I2C_M_RD))
+			read = false;
+		else
+			return -EOPNOTSUPP;
+	} else {
+		return -EOPNOTSUPP;
+	}
+
+	/*
+	 * The FL2000 I2C engine only transfers aligned dwords, so the offset is aligned down to a
+	 * 4-byte boundary and the requested byte is picked out of (or merged into) the dword.
+	 */
+	if (read) {
+		ret = fl2000_i2c_read_dword(adapter->algo_data, addr, offset, &data);
+		if (ret)
+			return ret;
+
+		msgs[1].buf[0] = data >> (idx * 8);
+	} else {
+		/*
+		 * Since the FL2000 I2C engine always operates on 4-byte messages, we need to read
+		 * before write in order not to corrupt the unrelated registers of the same dword.
+		 */
+		ret = fl2000_i2c_read_dword(adapter->algo_data, addr, offset, &data);
+		if (ret)
+			return ret;
+
+		data &= ~(0xffU << (idx * 8));
+		data |= (u32)msgs[0].buf[1] << (idx * 8);
+
+		ret = fl2000_i2c_write_dword(adapter->algo_data, addr, offset, &data);
+		if (ret)
+			return ret;
+	}
+
+	return num;
+}
+
+/*
+ * Monitor DDC on the FL2000 bus. The bridge's own EDID FIFO does not work on the tested boards, and
+ * the VGA connector has no bridge at all, so EDID is read with the FL2000 I2C engine at address
+ * 0x50, 4 bytes per operation with an 8-bit offset, which covers EDID blocks 0 and 1.
+ */
+#define FL2000_DDC_ADDR 0x50
+
+/**
+ * fl2000_ddc_read_block() - read one EDID block through the FL2000 I2C engine
+ * @adapter: the FL2000 I2C adapter
+ * @buf: destination, @len bytes
+ * @block: EDID block number (0 or 1)
+ * @len: bytes to read, at most EDID_LENGTH
+ *
+ * The signature matches what drm_edid_read_custom() expects, with the adapter as context.
+ *
+ * Return: 0 on success, a negative error code otherwise
+ */
+int fl2000_ddc_read_block(struct i2c_adapter *adapter, u8 *buf, unsigned int block, size_t len)
+{
+	struct usb_device *usb_dev = adapter->algo_data;
+	unsigned int start = block * EDID_LENGTH;
+	int ret = 0;
+
+	if (block > 1 || len > EDID_LENGTH)
+		return -EOPNOTSUPP;
+
+	/* One operation of the engine is a sequence of register accesses: keep others out */
+	i2c_lock_bus(adapter, I2C_LOCK_SEGMENT);
+	for (unsigned int i = 0; i < len; i += 4) {
+		u32 data;
+
+		ret = fl2000_i2c_dword(usb_dev, true, FL2000_DDC_ADDR, start + i, &data);
+		if (ret)
+			break;
+
+		put_unaligned_le32(data, buf + i);
+	}
+	i2c_unlock_bus(adapter, I2C_LOCK_SEGMENT);
+
+	return ret;
+}
+
+static u32 fl2000_i2c_func(struct i2c_adapter *adap)
+{
+	return I2C_FUNC_I2C | I2C_FUNC_NOSTART;
+}
+
+static const struct i2c_algorithm fl2000_i2c_algorithm = {
+	.xfer = fl2000_i2c_xfer,
+	.functionality = fl2000_i2c_func,
+};
+
+static const struct i2c_adapter_quirks fl2000_i2c_quirks = {
+	/* Combined transfers only: an address write, then data, on the same address */
+	.flags = I2C_AQ_COMB | I2C_AQ_COMB_WRITE_FIRST | I2C_AQ_COMB_SAME_ADDR,
+	.max_num_msgs = I2C_CMESSAGES_NUM,
+	.max_write_len = 2 * I2C_REG_DATA_SIZE,
+	.max_read_len = I2C_REG_DATA_SIZE,
+	.max_comb_1st_msg_len = I2C_REG_ADDR_SIZE,
+	.max_comb_2nd_msg_len = I2C_REG_DATA_SIZE,
+};
+
+struct i2c_adapter *fl2000_i2c_init(struct usb_device *usb_dev)
+{
+	int ret;
+	struct i2c_adapter *adapter;
+	u8 usb_path[32];
+
+	/* Adapter must be allocated before anything else */
+	adapter = devm_kzalloc(&usb_dev->dev, sizeof(*adapter), GFP_KERNEL);
+	if (!adapter)
+		return ERR_PTR(-ENOMEM);
+
+	adapter->owner = THIS_MODULE;
+	adapter->algo = &fl2000_i2c_algorithm;
+	adapter->quirks = &fl2000_i2c_quirks;
+	adapter->algo_data = usb_dev;
+	adapter->dev.parent = &usb_dev->dev;
+	strscpy(adapter->name, "FL2000 bridge I2C bus", sizeof(adapter->name));
+
+	ret = devm_i2c_add_adapter(&usb_dev->dev, adapter);
+	if (ret)
+		return ERR_PTR(ret);
+
+	usb_make_path(usb_dev, usb_path, sizeof(usb_path));
+	dev_dbg(&usb_dev->dev, "Created FL2000 bridge I2C bus %d at interface %s\n",
+		i2c_adapter_id(adapter), usb_path);
+
+	return adapter;
+}
diff --git a/drivers/gpu/drm/fl2000/fl2000_registers.c b/drivers/gpu/drm/fl2000/fl2000_registers.c
new file mode 100644
index 000000000..231814471
--- /dev/null
+++ b/drivers/gpu/drm/fl2000/fl2000_registers.c
@@ -0,0 +1,320 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * (C) Copyright 2017, Fresco Logic, Incorporated.
+ * (C) Copyright 2018-2019, Artem Mygaiev
+ */
+
+#include <linux/bitfield.h>
+#include <linux/delay.h>
+
+#include "fl2000.h"
+
+#define CONTROL_MSG_READ  64
+#define CONTROL_MSG_WRITE 65
+
+#define FL2000_HW_RST_MDELAY 10
+
+static bool fl2000_reg_precious(struct device *dev, unsigned int reg)
+{
+	return FL2000_REG_PRECIOUS(reg);
+}
+
+static bool fl2000_reg_volatile(struct device *dev, unsigned int reg)
+{
+	return FL2000_REG_VOLATILE(reg);
+}
+
+/* Protected by internal regmap mutex */
+static int fl2000_reg_read(void *context, unsigned int reg, unsigned int *val)
+{
+	struct usb_device *usb_dev = context;
+	__le32 data;
+	int ret;
+
+	ret = usb_control_msg_recv(usb_dev, 0, CONTROL_MSG_READ, USB_DIR_IN | USB_TYPE_VENDOR, 0,
+				   reg, &data, sizeof(data), USB_CTRL_GET_TIMEOUT, GFP_KERNEL);
+	if (ret)
+		return ret;
+
+	*val = le32_to_cpu(data);
+
+	return 0;
+}
+
+/* Protected by internal regmap mutex */
+static int fl2000_reg_write(void *context, unsigned int reg, unsigned int val)
+{
+	struct usb_device *usb_dev = context;
+	__le32 data = cpu_to_le32(val);
+
+	return usb_control_msg_send(usb_dev, 0, CONTROL_MSG_WRITE, USB_DIR_OUT | USB_TYPE_VENDOR, 0,
+				    reg, &data, sizeof(data), USB_CTRL_SET_TIMEOUT, GFP_KERNEL);
+}
+
+/*
+ * We do not use default values as per documentation because:
+ *  a) somehow they differ from real HW
+ *  b) on SW reset not all of them are cleared
+ */
+static const struct regmap_config fl2000_regmap_config = {
+	.val_bits = 32,
+	.reg_bits = 16,
+	.reg_stride = 4,
+	.max_register = 0xFFFF,
+
+	.cache_type = REGCACHE_MAPLE,
+
+	.precious_reg = fl2000_reg_precious,
+	.volatile_reg = fl2000_reg_volatile,
+
+	.reg_format_endian = REGMAP_ENDIAN_BIG,
+	.val_format_endian = REGMAP_ENDIAN_BIG,
+
+	.reg_read = fl2000_reg_read,
+	.reg_write = fl2000_reg_write,
+
+	.use_single_read = true,
+	.use_single_write = true,
+};
+
+int fl2000_set_pll(struct usb_device *usb_dev, struct fl2000_pll *pll)
+{
+	struct regmap *regmap = dev_get_regmap(&usb_dev->dev, NULL);
+	u32 val;
+
+	val = FIELD_PREP(FL2000_VGA_PLL_PRESCALER, pll->prescaler) |
+	      FIELD_PREP(FL2000_VGA_PLL_MULTIPLIER, pll->multiplier) |
+	      FIELD_PREP(FL2000_VGA_PLL_DIVISOR, pll->divisor) |
+	      FIELD_PREP(FL2000_VGA_PLL_FUNCTION, pll->function);
+	regmap_write(regmap, FL2000_VGA_PLL_REG, val);
+
+	val = FL2000_VGA_CTRL_ACLK_FORCE_PLL_UP;
+	regmap_write_bits(regmap, FL2000_VGA_CTRL_REG_ACLK, val, val);
+
+	return 0;
+}
+
+/*
+ * Make the chip believe a monitor is connected whatever its own sense says. The HDMI path has
+ * always run with this set, so it stays set while HDMI is driven. It must be clear while only VGA
+ * is driven: it hides the cable being unplugged, and with it clear the chip powers its DAC and PLL
+ * by itself whenever it senses a monitor.
+ */
+int fl2000_force_connect(struct usb_device *usb_dev, bool force)
+{
+	struct regmap *regmap = dev_get_regmap(&usb_dev->dev, NULL);
+
+	return regmap_write_bits(regmap, FL2000_VGA_CTRL_REG_ACLK,
+				 FL2000_VGA_CTRL_ACLK_FORCE_VGA_CONNECT,
+				 force ? FL2000_VGA_CTRL_ACLK_FORCE_VGA_CONNECT : 0);
+}
+
+int fl2000_set_timings(struct usb_device *usb_dev, struct fl2000_timings *timings)
+{
+	struct regmap *regmap = dev_get_regmap(&usb_dev->dev, NULL);
+
+	regmap_write(regmap, FL2000_VGA_HSYNC_REG1,
+		     FIELD_PREP(FL2000_VGA_HSYNC1_HACTIVE, timings->hactive) |
+		     FIELD_PREP(FL2000_VGA_HSYNC1_HTOTAL, timings->htotal));
+
+	regmap_write(regmap, FL2000_VGA_HSYNC_REG2,
+		     FIELD_PREP(FL2000_VGA_HSYNC2_HSYNC_WIDTH, timings->hsync_width) |
+		     FIELD_PREP(FL2000_VGA_HSYNC2_HSTART, timings->hstart));
+
+	regmap_write(regmap, FL2000_VGA_VSYNC_REG1,
+		     FIELD_PREP(FL2000_VGA_VSYNC1_VACTIVE, timings->vactive) |
+		     FIELD_PREP(FL2000_VGA_VSYNC1_VTOTAL, timings->vtotal));
+
+	regmap_write(regmap, FL2000_VGA_VSYNC_REG2,
+		     FIELD_PREP(FL2000_VGA_VSYNC2_VSYNC_WIDTH, timings->vsync_width) |
+		     FIELD_PREP(FL2000_VGA_VSYNC2_VSTART, timings->vstart) |
+		     FIELD_PREP(FL2000_VGA_VSYNC2_START_LATENCY, timings->vstart));
+
+	return 0;
+}
+
+int fl2000_set_pixfmt(struct usb_device *usb_dev, u32 bytes_pix)
+{
+	struct regmap *regmap = dev_get_regmap(&usb_dev->dev, NULL);
+	u32 mask, val;
+
+	mask = FL2000_VGA_CTRL_PXCLK_DAC_OUTPUT_EN | FL2000_VGA_CTRL_PXCLK_DROP_CNT |
+	       FL2000_VGA_CTRL_PXCLK_VGA565_MODE | FL2000_VGA_CTRL_PXCLK_VGA332_MODE |
+	       FL2000_VGA_CTRL_PXCLK_VGA555_MODE | FL2000_VGA_CTRL_PXCLK_VGA_COMPRESS |
+	       FL2000_VGA_CTRL_PXCLK_CLEAR_WATERMARK;
+	val = FL2000_VGA_CTRL_PXCLK_DAC_OUTPUT_EN | FL2000_VGA_CTRL_PXCLK_CLEAR_WATERMARK;
+	if (bytes_pix == 2)
+		val |= FL2000_VGA_CTRL_PXCLK_VGA565_MODE;
+	regmap_write_bits(regmap, FL2000_VGA_CTRL_REG_PXCLK, mask, val);
+
+	return 0;
+}
+
+int fl2000_set_transfers(struct usb_device *usb_dev)
+{
+	struct regmap *regmap = dev_get_regmap(&usb_dev->dev, NULL);
+	u32 mask;
+
+	mask = FL2000_VGA_CTRL_ACLK_USE_PKT_PENDING | FL2000_VGA_CTRL_ACLK_USE_ZERO_TD |
+	       FL2000_VGA_CTRL_ACLK_USE_ZERO_PKT_LEN;
+	regmap_write_bits(regmap, FL2000_VGA_CTRL_REG_ACLK, mask,
+			  FL2000_VGA_CTRL_ACLK_USE_ZERO_PKT_LEN);
+
+	regmap_write_bits(regmap, FL2000_VGA_ISOCH_REG, FL2000_VGA_ISOCH_MFRAME_CNT, 0);
+
+	return 0;
+}
+
+int fl2000_reset(struct usb_device *usb_dev)
+{
+	struct regmap *regmap = dev_get_regmap(&usb_dev->dev, NULL);
+
+	regmap_write_bits(regmap, FL2000_RST_CTRL_REG, FL2000_RST_CTRL_SW_RESET,
+			  FL2000_RST_CTRL_SW_RESET);
+
+	msleep(FL2000_HW_RST_MDELAY);
+
+	return 0;
+}
+
+int fl2000_afe_magic(struct usb_device *usb_dev)
+{
+	struct regmap *regmap = dev_get_regmap(&usb_dev->dev, NULL);
+
+	regmap_write_bits(regmap, FL2000_USB_LPM_REG, FL2000_USB_LPM_MAGIC, FL2000_USB_LPM_MAGIC);
+
+	return 0;
+}
+
+int fl2000_usb_magic(struct usb_device *usb_dev)
+{
+	struct regmap *regmap = dev_get_regmap(&usb_dev->dev, NULL);
+	u32 val;
+
+	val = FL2000_VGA_I2C_SC_MONITOR_DETECT | FL2000_VGA_I2C_SC_EDID_DETECT;
+	regmap_write_bits(regmap, FL2000_VGA_I2C_SC_REG, val, val);
+
+	regmap_write_bits(regmap, FL2000_VGA_CTRL_REG_3, FL2000_VGA_CTRL3_WAKEUP_CLR_EN, 0);
+
+	val = FL2000_USB_LPM_U1_REJECT | FL2000_USB_LPM_U2_REJECT;
+	regmap_write_bits(regmap, FL2000_USB_LPM_REG, val, val);
+
+	regmap_write_bits(regmap, FL2000_USB_CTRL_REG, FL2000_USB_CTRL_WAKE_NRDY, 0);
+
+	return 0;
+}
+
+int fl2000_enable_interrupts(struct usb_device *usb_dev)
+{
+	struct regmap *regmap = dev_get_regmap(&usb_dev->dev, NULL);
+	u32 mask, val;
+
+	val = FL2000_VGA_CTRL_ACLK_VGA_ERR_INT_EN | FL2000_VGA_CTRL_ACLK_LBUF_ERR_INT_EN |
+	      FL2000_VGA_CTRL_ACLK_EDID_MON_INT_EN;
+	mask = val | FL2000_VGA_CTRL_ACLK_FEEDBACK_INT_EN;
+	regmap_write_bits(regmap, FL2000_VGA_CTRL_REG_ACLK, mask, val);
+
+	regmap_write_bits(regmap, FL2000_VGA_CTRL2_REG_ACLK, FL2000_VGA_CTRL2_ACLK_HDMI_INT_EN,
+			  FL2000_VGA_CTRL2_ACLK_HDMI_INT_EN);
+
+	return 0;
+}
+
+/*
+ * Read the status register. Its event bits clear on read, so whoever reads it owns the events it
+ * returns: callers must not drop them.
+ */
+int fl2000_read_status(struct usb_device *usb_dev, u32 *status)
+{
+	struct regmap *regmap = dev_get_regmap(&usb_dev->dev, NULL);
+	unsigned int val;
+	u32 mask;
+	int ret;
+
+	ret = regmap_read(regmap, FL2000_VGA_STATUS_REG, &val);
+	if (ret)
+		return ret;
+
+	/* LBUF issues are recoverable */
+	mask = val & (FL2000_VGA_STATUS_LBUF_OVERFLOW | FL2000_VGA_STATUS_LBUF_UNDERFLOW);
+	if (mask)
+		regmap_write_bits(regmap, FL2000_VGA_STATUS_REG, mask, val);
+
+	/* lbuf_halt and vga_error are not handled: no recovery sequence is known */
+
+	*status = val;
+
+	return 0;
+}
+
+int fl2000_i2c_dword(struct usb_device *usb_dev, bool read, u16 addr, u8 offset, u32 *data)
+{
+	int ret;
+	unsigned int val;
+	u32 mask;
+	struct regmap *regmap = dev_get_regmap(&usb_dev->dev, NULL);
+
+	if (!read) {
+		ret = regmap_write(regmap, FL2000_VGA_I2C_WR_REG, *data);
+		if (ret)
+			return -EIO;
+	}
+
+	/*
+	 * The detection bits always read back as 0, so they need to be set again on every write.
+	 * It is not clear whether the monitor detection circuit is needed at all for the HDMI use
+	 * case.
+	 */
+	mask = FL2000_VGA_I2C_SC_MONITOR_DETECT | FL2000_VGA_I2C_SC_EDID_DETECT |
+	       FL2000_VGA_I2C_SC_STATUS | FL2000_VGA_I2C_SC_ADDR | FL2000_VGA_I2C_SC_CMD |
+	       FL2000_VGA_I2C_SC_OFFSET | FL2000_VGA_I2C_SC_DONE;
+	val = FL2000_VGA_I2C_SC_MONITOR_DETECT | FL2000_VGA_I2C_SC_EDID_DETECT |
+	      FIELD_PREP(FL2000_VGA_I2C_SC_ADDR, addr) |
+	      FIELD_PREP(FL2000_VGA_I2C_SC_CMD, read) |
+	      FIELD_PREP(FL2000_VGA_I2C_SC_OFFSET, offset);
+
+	ret = regmap_write_bits(regmap, FL2000_VGA_I2C_SC_REG, mask, val);
+	if (ret)
+		return -EIO;
+
+	ret = regmap_read_poll_timeout(regmap, FL2000_VGA_I2C_SC_REG, val,
+				       val & FL2000_VGA_I2C_SC_DONE, I2C_RDWR_INTERVAL,
+				       I2C_RDWR_TIMEOUT);
+	/*
+	 * This shouldn't normally happen: there's internal 256ms HW timeout on I2C operations and
+	 * USB must be always available so no I/O errors. But if it happens we are probably facing
+	 * an irreversible HW issue.
+	 */
+	if (ret || FIELD_GET(FL2000_VGA_I2C_SC_STATUS, val))
+		return -EIO;
+
+	if (read) {
+		ret = regmap_read(regmap, FL2000_VGA_I2C_RD_REG, data);
+		if (ret)
+			return -EIO;
+	}
+
+	return 0;
+}
+
+/*
+ * The chip may have lost power (system sleep): forget the cached registers, so that the
+ * read-modify-write updates that follow read the chip instead of skipping writes it still needs.
+ */
+void fl2000_regmap_drop_cache(struct usb_device *usb_dev)
+{
+	struct regmap *regmap = dev_get_regmap(&usb_dev->dev, NULL);
+
+	regcache_drop_region(regmap, 0, fl2000_regmap_config.max_register);
+}
+
+struct regmap *fl2000_regmap_init(struct usb_device *usb_dev)
+{
+	struct regmap *regmap;
+
+	regmap = devm_regmap_init(&usb_dev->dev, NULL, usb_dev, &fl2000_regmap_config);
+	if (IS_ERR(regmap))
+		dev_err(&usb_dev->dev, "Registers map failed (%pe)\n", regmap);
+
+	return regmap;
+}
diff --git a/drivers/gpu/drm/fl2000/fl2000_registers.h b/drivers/gpu/drm/fl2000/fl2000_registers.h
new file mode 100644
index 000000000..7ca977f1d
--- /dev/null
+++ b/drivers/gpu/drm/fl2000/fl2000_registers.h
@@ -0,0 +1,272 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Based on the official registers description from Fresco Logic
+ *
+ * (C) Copyright 2019, Artem Mygaiev
+ */
+
+#ifndef FL2000_REGISTERS_H
+#define FL2000_REGISTERS_H
+
+#include <linux/bits.h>
+#include <linux/types.h>
+
+/* #### USB Control Registers Bank #### */
+/* Some unknown & undocumented FL2000 USB settings */
+
+#define FL2000_USB_CONTROL_OFFSET 0x0000
+
+#define FL2000_USB_LPM_REG (FL2000_USB_CONTROL_OFFSET + 0x70)
+#define  FL2000_USB_LPM_MAGIC				BIT(13)
+#define  FL2000_USB_LPM_U2_REJECT			BIT(19)
+#define  FL2000_USB_LPM_U1_REJECT			BIT(20)
+
+#define FL2000_USB_CTRL_REG (FL2000_USB_CONTROL_OFFSET + 0x78)
+#define  FL2000_USB_CTRL_WAKE_NRDY			BIT(17)
+
+/* #### VGA Control Registers Bank #### */
+/* Taken from the 'FL200DX Memory Mapped Address Space Registers' spec */
+
+#define FL2000_VGA_CONTROL_OFFSET 0x8000
+
+#define FL2000_VGA_STATUS_REG (FL2000_VGA_CONTROL_OFFSET + 0x00)
+#define  FL2000_VGA_STATUS_VGA_STATUS			BIT(0)
+#define  FL2000_VGA_STATUS_VGA_ERROR			BIT(1) /* read self clear */
+#define  FL2000_VGA_STATUS_LBUF_HALT			BIT(2)
+#define  FL2000_VGA_STATUS_ISO_ACK			BIT(3) /* read self clear */
+#define  FL2000_VGA_STATUS_TD_DROP			BIT(4) /* read self clear */
+#define  FL2000_VGA_STATUS_IRQ_PENDING			BIT(5) /* read self clear */
+#define  FL2000_VGA_STATUS_PLL_STATUS			BIT(6)
+#define  FL2000_VGA_STATUS_DAC_STATUS			BIT(7)
+#define  FL2000_VGA_STATUS_LBUF_OVERFLOW		BIT(8)
+#define  FL2000_VGA_STATUS_LBUF_UNDERFLOW		BIT(9)
+#define  FL2000_VGA_STATUS_FRAME_CNT			GENMASK(25, 10)
+#define  FL2000_VGA_STATUS_HDMI_EVENT			BIT(26) /* read self clear */
+#define  FL2000_VGA_STATUS_HDMI_STATUS			BIT(27)
+#define  FL2000_VGA_STATUS_EDID_STATUS			BIT(28)
+#define  FL2000_VGA_STATUS_MONITOR_STATUS		BIT(29)
+#define  FL2000_VGA_STATUS_MONITOR_EVENT		BIT(30) /* read self clear */
+#define  FL2000_VGA_STATUS_EDID_EVENT			BIT(31) /* read self clear */
+
+#define FL2000_VGA_CTRL_REG_PXCLK (FL2000_VGA_CONTROL_OFFSET + 0x04)
+#define  FL2000_VGA_CTRL_PXCLK_CLEAR_WATERMARK		BIT(0)
+#define  FL2000_VGA_CTRL_PXCLK_FRAME_SYNC		BIT(1)
+#define  FL2000_VGA_CTRL_PXCLK_HSYNC_POLARITY		BIT(2)
+#define  FL2000_VGA_CTRL_PXCLK_VSYNC_POLARITY		BIT(3)
+#define  FL2000_VGA_CTRL_PXCLK_DE_POLARITY		BIT(4)
+#define  FL2000_VGA_CTRL_PXCLK_MIRROR_MODE		BIT(5)
+#define  FL2000_VGA_CTRL_PXCLK_VGA565_MODE		BIT(6)
+#define  FL2000_VGA_CTRL_PXCLK_DAC_OUTPUT_EN		BIT(7)
+#define  FL2000_VGA_CTRL_PXCLK_VGA_TIMING_EN		BIT(8)
+#define  FL2000_VGA_CTRL_PXCLK_USE_NEW_PKT_RETRY	BIT(9)
+#define  FL2000_VGA_CTRL_PXCLK_REF_SELECT		BIT(10)
+#define  FL2000_VGA_CTRL_PXCLK_DAC_PX_CLK_INVERT	BIT(11)
+#define  FL2000_VGA_CTRL_PXCLK_CLEAR_LBUF_STATUS	BIT(12)
+#define  FL2000_VGA_CTRL_PXCLK_DROP_CNT			BIT(13)
+#define  FL2000_VGA_CTRL_PXCLK_USE_VDI_ITP_CNT		BIT(14)
+#define  FL2000_VGA_CTRL_PXCLK_VGA_COMPRESS		BIT(24)
+#define  FL2000_VGA_CTRL_PXCLK_VGA332_MODE		BIT(25)
+#define  FL2000_VGA_CTRL_PXCLK_VGA_COLOR_PALETTE_EN	BIT(26)
+#define  FL2000_VGA_CTRL_PXCLK_VGA_FIRST_BT_ENC_EN	BIT(27)
+#define  FL2000_VGA_CTRL_PXCLK_CLEAR_125US_CNT		BIT(28)
+#define  FL2000_VGA_CTRL_PXCLK_DISABLE_HALT		BIT(29)
+#define  FL2000_VGA_CTRL_PXCLK_FORCE_DE_EN		BIT(30)
+#define  FL2000_VGA_CTRL_PXCLK_VGA555_MODE		BIT(31)
+
+#define FL2000_VGA_HSYNC_REG1 (FL2000_VGA_CONTROL_OFFSET + 0x08)
+#define  FL2000_VGA_HSYNC1_HTOTAL			GENMASK(11, 0)
+#define  FL2000_VGA_HSYNC1_HACTIVE			GENMASK(27, 16)
+
+#define FL2000_VGA_HSYNC_REG2 (FL2000_VGA_CONTROL_OFFSET + 0x0C)
+#define  FL2000_VGA_HSYNC2_HSTART			GENMASK(11, 0)
+#define  FL2000_VGA_HSYNC2_HSYNC_WIDTH			GENMASK(23, 16)
+
+#define FL2000_VGA_VSYNC_REG1 (FL2000_VGA_CONTROL_OFFSET + 0x10)
+#define  FL2000_VGA_VSYNC1_VTOTAL			GENMASK(11, 0)
+#define  FL2000_VGA_VSYNC1_VACTIVE			GENMASK(27, 16)
+
+#define FL2000_VGA_VSYNC_REG2 (FL2000_VGA_CONTROL_OFFSET + 0x14)
+#define  FL2000_VGA_VSYNC2_VSTART			GENMASK(11, 0)
+#define  FL2000_VGA_VSYNC2_VSYNC_WIDTH			GENMASK(18, 16)
+#define  FL2000_VGA_VSYNC2_START_LATENCY		GENMASK(29, 20)
+#define  FL2000_VGA_VSYNC2_BUF_ERROR_EN			BIT(31)
+
+#define FL2000_VGA_TEST_REG  (FL2000_VGA_CONTROL_OFFSET + 0x18)
+#define FL2000_VGA_ISOCH_REG (FL2000_VGA_CONTROL_OFFSET + 0x1C)
+#define  FL2000_VGA_ISOCH_START_MFRAME_CNT		GENMASK(13, 0)
+#define  FL2000_VGA_ISOCH_USE_MFRAME_MATCH		BIT(14)
+#define  FL2000_VGA_ISOCH_USE_ZERO_LEN_FRAME		BIT(15)
+#define  FL2000_VGA_ISOCH_MFRAME_CNT			GENMASK(29, 16)
+#define  FL2000_VGA_ISOCH_MFRAME_CNT_UPDATE		BIT(30)
+
+#define FL2000_VGA_I2C_SC_REG (FL2000_VGA_CONTROL_OFFSET + 0x20)
+#define  FL2000_VGA_I2C_SC_ADDR				GENMASK(6, 0)
+#define  FL2000_VGA_I2C_SC_CMD				BIT(7)
+#define  FL2000_VGA_I2C_SC_OFFSET			GENMASK(15, 8)
+#define  FL2000_VGA_I2C_SC_VGA_STATUS			GENMASK(23, 16)
+#define  FL2000_VGA_I2C_SC_STATUS			GENMASK(27, 24)
+#define  FL2000_VGA_I2C_SC_MONITOR_DETECT		BIT(28)
+#define  FL2000_VGA_I2C_SC_READY			BIT(29)
+#define  FL2000_VGA_I2C_SC_EDID_DETECT			BIT(30)
+#define  FL2000_VGA_I2C_SC_DONE				BIT(31)
+
+#define FL2000_VGA_I2C_RD_REG (FL2000_VGA_CONTROL_OFFSET + 0x24)
+#define FL2000_VGA_I2C_WR_REG (FL2000_VGA_CONTROL_OFFSET + 0x28)
+
+#define FL2000_VGA_PLL_REG (FL2000_VGA_CONTROL_OFFSET + 0x2C)
+#define  FL2000_VGA_PLL_DIVISOR				GENMASK(7, 0)
+#define  FL2000_VGA_PLL_PRESCALER			GENMASK(9, 8)
+#define  FL2000_VGA_PLL_FUNCTION			GENMASK(14, 13)
+#define  FL2000_VGA_PLL_MULTIPLIER			GENMASK(23, 16)
+#define  FL2000_VGA_PLL_TEST_IO				BIT(24)
+#define  FL2000_VGA_PLL_CFG_DAC_PWRDOWN			BIT(25)
+#define  FL2000_VGA_PLL_FORCE_DAC_PWRUP			BIT(26)
+
+#define FL2000_VGA_LBUF_REG (FL2000_VGA_CONTROL_OFFSET + 0x30)
+#define  FL2000_VGA_LBUF_WATERMARK_ASSERT_RDY		GENMASK(14, 0)
+
+#define FL2000_VGA_HI_MARK (FL2000_VGA_CONTROL_OFFSET + 0x34)
+#define  FL2000_VGA_HI_MARK_HIGH_WATERMARK		GENMASK(16, 0)
+
+#define FL2000_VGA_LO_MARK (FL2000_VGA_CONTROL_OFFSET + 0x38)
+#define  FL2000_VGA_LO_MARK_LOW_WATERMARK		GENMASK(16, 0)
+
+#define FL2000_VGA_CTRL_REG_ACLK (FL2000_VGA_CONTROL_OFFSET + 0x3C)
+#define  FL2000_VGA_CTRL_ACLK_CFG_TIMING_RESET_N	BIT(0)
+#define  FL2000_VGA_CTRL_ACLK_PLH_BLOCK_EN		BIT(1)
+#define  FL2000_VGA_CTRL_ACLK_EDID_MON_INT_EN		BIT(2)
+#define  FL2000_VGA_CTRL_ACLK_EXT_MON_INT_EN		BIT(3)
+#define  FL2000_VGA_CTRL_ACLK_VGA_STATUS_SELF_CLEAR	BIT(4)
+#define  FL2000_VGA_CTRL_ACLK_PLL_LOCK_TIME		GENMASK(9, 5)
+#define  FL2000_VGA_CTRL_ACLK_PLL_FAST_TIMEOUT_EN	BIT(10)
+#define  FL2000_VGA_CTRL_ACLK_PPE_BLOCK_EM		BIT(11)
+#define  FL2000_VGA_CTRL_ACLK_PLL_TIMER_EN		BIT(12)
+#define  FL2000_VGA_CTRL_ACLK_FEEDBACK_INT_EN		BIT(13)
+#define  FL2000_VGA_CTRL_ACLK_CLR_125US_COUNTER		BIT(14)
+#define  FL2000_VGA_CTRL_ACLK_CCS_PD_DIS		BIT(15)
+#define  FL2000_VGA_CTRL_ACLK_STANDBY_EN		BIT(16)
+#define  FL2000_VGA_CTRL_ACLK_FORCE_LOOPBACK		BIT(17)
+#define  FL2000_VGA_CTRL_ACLK_LBUF_DROP_FRAME_EN	BIT(18)
+#define  FL2000_VGA_CTRL_ACLK_LBUF_VDE_RST_EN		BIT(19)
+#define  FL2000_VGA_CTRL_ACLK_LBUF_SW_RST		BIT(20)
+#define  FL2000_VGA_CTRL_ACLK_LBUF_ERR_INT_EN		BIT(21)
+#define  FL2000_VGA_CTRL_ACLK_BIAC_EN			BIT(22)
+#define  FL2000_VGA_CTRL_ACLK_PXCLK_IN_EN		BIT(23)
+#define  FL2000_VGA_CTRL_ACLK_VGA_ERR_INT_EN		BIT(24)
+#define  FL2000_VGA_CTRL_ACLK_FORCE_VGA_CONNECT		BIT(25)
+#define  FL2000_VGA_CTRL_ACLK_FORCE_PLL_UP		BIT(26)
+#define  FL2000_VGA_CTRL_ACLK_USE_ZERO_TD		BIT(27)
+#define  FL2000_VGA_CTRL_ACLK_USE_ZERO_PKT_LEN		BIT(28)
+#define  FL2000_VGA_CTRL_ACLK_USE_PKT_PENDING		BIT(29)
+#define  FL2000_VGA_CTRL_ACLK_PLL_DAC_PD_USBP3_EN	BIT(30)
+#define  FL2000_VGA_CTRL_ACLK_PLL_DAC_PD_NOVGA_EN	BIT(31)
+
+#define FL2000_VGA_PXCLK_CNT_REG (FL2000_VGA_CONTROL_OFFSET + 0x40)
+#define  FL2000_VGA_PXCLK_CNT_PIX_CLOCK_COUNT		GENMASK(27, 0)
+
+#define FL2000_VGA_VCNT_REG (FL2000_VGA_CONTROL_OFFSET + 0x44)
+#define  FL2000_VGA_VCNT_MAX_ACLK_COUNT			GENMASK(14, 0)
+#define  FL2000_VGA_VCNT_MAX_ACLK_COUNT_HIT		BIT(15)
+#define  FL2000_VGA_VCNT_MAX_LBUF_ACCUMULATE		GENMASK(31, 16)
+
+#define FL2000_RST_CTRL_REG (FL2000_VGA_CONTROL_OFFSET + 0x48)
+#define  FL2000_RST_CTRL_DIS_HOT_RST2_PORT		BIT(0)
+#define  FL2000_RST_CTRL_DIS_WARM_RST2_PORT		BIT(1)
+#define  FL2000_RST_CTRL_DIS_HOT_RESET_PIPE		BIT(2)
+#define  FL2000_RST_CTRL_DIS_WARM_RESET_PIPE		BIT(3)
+#define  FL2000_RST_CTRL_DIS_HOT_RESET_PIX		BIT(4)
+#define  FL2000_RST_CTRL_DIS_WARM_RESET_PIX		BIT(5)
+#define  FL2000_RST_CTRL_DIS_USB2_RESET_PIX		BIT(6)
+#define  FL2000_RST_CTRL_DIS_PLL_RESET_PIX		BIT(7)
+#define  FL2000_RST_CTRL_DIS_SW_RESET_PIX		BIT(8)
+#define  FL2000_RST_CTRL_DIS_USB2_RESET_BUF		BIT(9)
+#define  FL2000_RST_CTRL_DIS_SW_RESET_BUF		BIT(10)
+#define  FL2000_RST_CTRL_DIS_LBUF_RESET_PIX		BIT(11)
+#define  FL2000_RST_CTRL_DIS_HOT_RESET_PORT		BIT(12)
+#define  FL2000_RST_CTRL_DIS_WARM_RESET_PORT		BIT(13)
+#define  FL2000_RST_CTRL_SET_SLOW_CLK_PREDFT		BIT(14)
+#define  FL2000_RST_CTRL_SW_RESET			BIT(15)
+#define  FL2000_RST_CTRL_FRAME_FIRST_ITP_WL		GENMASK(31, 16)
+
+#define FL2000_BIAC_CTRL1_REG (FL2000_VGA_CONTROL_OFFSET + 0x4C)
+#define  FL2000_BIAC_CTRL1_CTRL_LO8			GENMASK(7, 0)
+#define  FL2000_BIAC_CTRL1_FRAME_MULT			GENMASK(15, 8)
+#define  FL2000_BIAC_CTRL1_125US_MULT			GENMASK(31, 16)
+
+#define FL2000_BIAC_CTRL2_REG (FL2000_VGA_CONTROL_OFFSET + 0x50)
+#define  FL2000_BIAC_CTRL2_CTRL_HI16			GENMASK(15, 0)
+
+#define FL2000_BIAC_STATUS_REG (FL2000_VGA_CONTROL_OFFSET + 0x54)
+#define  FL2000_BIAC_STATUS_CURRENT_STATUS		GENMASK(15, 0)
+#define  FL2000_BIAC_STATUS_CURRENT_VALUE		GENMASK(31, 16)
+
+/* undefined				(FL2000_VGA_CONTROL_OFFSET + 0x58) */
+
+#define FL2000_VGA_PLT_REG_PXCLK (FL2000_VGA_CONTROL_OFFSET + 0x5C)
+#define  FL2000_VGA_PLT_PXCLK_PALETTE_RAM_WR_DATA	GENMASK(23, 0)
+
+#define FL2000_VGA_PLT_RADDR_REG_PXCLK (FL2000_VGA_CONTROL_OFFSET + 0x60)
+#define  FL2000_VGA_PLT_RADDR_PALETTE_RAM_RD_ADDR	GENMASK(7, 0)
+#define  FL2000_VGA_PLT_RADDR_LAST_FRAME_LBUF_WATERMARK	GENMASK(23, 8)
+
+#define FL2000_VGA_CTRL2_REG_ACLK (FL2000_VGA_CONTROL_OFFSET + 0x64)
+#define  FL2000_VGA_CTRL2_ACLK_PLL_POWERDOWN_DETECT_EN	BIT(0)
+#define  FL2000_VGA_CTRL2_ACLK_MSTOR_BLKSIZE_PTR_WIDTH	GENMASK(3, 1)
+#define  FL2000_VGA_CTRL2_ACLK_MSTOR_BLK_COUNT		GENMASK(15, 4)
+#define  FL2000_VGA_CTRL2_ACLK_SPI_WR_EN		BIT(16)
+#define  FL2000_VGA_CTRL2_ACLK_DETECT_PINS_DEBOUNCE_EN	BIT(17)
+#define  FL2000_VGA_CTRL2_ACLK_HDMI_INT_EN		BIT(18)
+#define  FL2000_VGA_CTRL2_ACLK_HDMI_INT_ACTIVE_HIGH	BIT(19)
+#define  FL2000_VGA_CTRL2_ACLK_SPI_EN			BIT(20)
+#define  FL2000_VGA_CTRL2_ACLK_SW_PROD_REV		GENMASK(30, 23)
+
+/* undefined				(FL2000_VGA_CONTROL_OFFSET + 0x68) */
+/* undefined				(FL2000_VGA_CONTROL_OFFSET + 0x6C) */
+
+#define FL2000_TEST_CNTL_REG1 (FL2000_VGA_CONTROL_OFFSET + 0x70)
+#define FL2000_TEST_CNTL_REG2 (FL2000_VGA_CONTROL_OFFSET + 0x74)
+#define FL2000_TEST_CNTL_REG3 (FL2000_VGA_CONTROL_OFFSET + 0x78)
+#define FL2000_TEST_STAT1     (FL2000_VGA_CONTROL_OFFSET + 0x7C)
+#define FL2000_TEST_STAT2     (FL2000_VGA_CONTROL_OFFSET + 0x80)
+#define FL2000_TEST_STAT3     (FL2000_VGA_CONTROL_OFFSET + 0x84)
+
+#define FL2000_VGA_CTRL_REG_3 (FL2000_VGA_CONTROL_OFFSET + 0x88)
+#define  FL2000_VGA_CTRL3_WAKEUP_CLR_EN			BIT(10)
+
+/* undefined				(FL2000_VGA_CONTROL_OFFSET + 0x8C) */
+
+/*
+ * List of registers that shall not be read automatically (e.g. for cache update) due to presence
+ * of self-clear bits
+ */
+static inline bool FL2000_REG_PRECIOUS(u32 reg)
+{
+	return reg == FL2000_VGA_STATUS_REG;
+}
+
+/* List of volatile registers that shall not be cached */
+static inline bool FL2000_REG_VOLATILE(u32 reg)
+{
+	switch (reg) {
+	case FL2000_VGA_STATUS_REG:
+	case FL2000_VGA_CTRL_REG_PXCLK:
+	case FL2000_VGA_ISOCH_REG:
+	case FL2000_VGA_I2C_SC_REG:
+	case FL2000_VGA_I2C_RD_REG:
+	case FL2000_VGA_PXCLK_CNT_REG:
+	case FL2000_VGA_VCNT_REG:
+	case FL2000_RST_CTRL_REG:
+	case FL2000_BIAC_STATUS_REG:
+	case FL2000_VGA_PLT_RADDR_REG_PXCLK:
+	case FL2000_TEST_CNTL_REG1:
+	case FL2000_TEST_CNTL_REG2:
+	case FL2000_TEST_STAT1:
+	case FL2000_TEST_STAT2:
+	case FL2000_TEST_STAT3:
+		return true;
+	default:
+		return false;
+	}
+}
+
+#endif /* FL2000_REGISTERS_H */

-- 
2.56.0

