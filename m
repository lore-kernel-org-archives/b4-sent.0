From: Sven Peter <sven@kernel.org>
Date: Thu, 21 Aug 2025 15:39:12 +0000
Subject: [PATCH RFC 20/22] soc: apple: Add hardware tunable support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250821-atcphy-6-17-v1-20-172beda182b8@kernel.org>
References: <20250821-atcphy-6-17-v1-0-172beda182b8@kernel.org>
In-Reply-To: <20250821-atcphy-6-17-v1-0-172beda182b8@kernel.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Felipe Balbi <balbi@kernel.org>, 
 Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6361; i=sven@kernel.org;
 h=from:subject:message-id; bh=vklN4/w2hbW7rNLgTYVlAI33wbeeVkY8FZwbhVtsJVg=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8Zy21PV4iZzXpfc0TPWYvT0/nIx9ueWn9s2MSiGzV+wq
 3PZic03OkpYGMQ4GGTFFFm277c3ffLwjeDSTZfew8xhZQIZwsDFKQATKb7CyPCkcbqJ7JuLEkmz
 GQsYm1WZ/gfP4DiiZfVrhvfthdsfbv/J8OP35dRP5QF28fv/v5s9keVIj4O/1YYbfVMs/nf/tnu
 9hAcA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Various hardware, like the Type-C PHY or the Thunderbolt/USB4 NHI,
present on Apple SoCs need machine-specific tunables passed from our
bootloader m1n1 to the device tree. Add generic helpers so that we
don't have to duplicate this across multiple drivers.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/soc/apple/Kconfig         |  4 ++
 drivers/soc/apple/Makefile        |  3 ++
 drivers/soc/apple/tunable.c       | 77 +++++++++++++++++++++++++++++++++++++++
 include/linux/soc/apple/tunable.h | 64 ++++++++++++++++++++++++++++++++
 4 files changed, 148 insertions(+)

diff --git a/drivers/soc/apple/Kconfig b/drivers/soc/apple/Kconfig
index 6388cbe1e56b5a9d90acad3ee2377ed6ac0d207d..f266b70fd9620cc940dc685f7eb2972c21a361df 100644
--- a/drivers/soc/apple/Kconfig
+++ b/drivers/soc/apple/Kconfig
@@ -41,6 +41,10 @@ config APPLE_SART
 
 	  Say 'y' here if you have an Apple SoC.
 
+config APPLE_TUNABLE
+	tristate
+	depends on ARCH_APPLE || COMPILE_TEST
+
 endmenu
 
 endif
diff --git a/drivers/soc/apple/Makefile b/drivers/soc/apple/Makefile
index 4d9ab8f3037b7159771d8817fa507ba29f99ae10..0b85ab61aefe131349a67d0aa80204edd8e89925 100644
--- a/drivers/soc/apple/Makefile
+++ b/drivers/soc/apple/Makefile
@@ -8,3 +8,6 @@ apple-rtkit-y = rtkit.o rtkit-crashlog.o
 
 obj-$(CONFIG_APPLE_SART) += apple-sart.o
 apple-sart-y = sart.o
+
+obj-$(CONFIG_APPLE_TUNABLE) += apple-tunable.o
+apple-tunable-y = tunable.o
diff --git a/drivers/soc/apple/tunable.c b/drivers/soc/apple/tunable.c
new file mode 100644
index 0000000000000000000000000000000000000000..3d9d47b3861f6fea637a3c82f270e5d321b1a48e
--- /dev/null
+++ b/drivers/soc/apple/tunable.c
@@ -0,0 +1,77 @@
+// SPDX-License-Identifier: GPL-2.0-only OR MIT
+/*
+ * Apple Silicon hardware tunable support
+ *
+ * Each tunable is a list with each entry containing a offset into the MMIO
+ * region, a mask of bits to be cleared and a set of bits to be set. These
+ * tunables are passed along by the previous boot stages and vary from device
+ * to device such that they cannot be hardcoded in the individual drivers.
+ *
+ * Copyright (C) The Asahi Linux Contributors
+ */
+
+#include <linux/io.h>
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/soc/apple/tunable.h>
+
+int devm_apple_parse_tunable(struct device *dev, struct device_node *np,
+			     struct apple_tunable *tunable, const char *name)
+{
+	struct property *prop;
+	const __le32 *p = NULL;
+	int i;
+
+	prop = of_find_property(np, name, NULL);
+	if (!prop) {
+		dev_err(dev, "tunable %s not found\n", name);
+		return -ENOENT;
+	}
+
+	if (prop->length % (3 * sizeof(u32)))
+		return -EINVAL;
+
+	tunable->sz = prop->length / (3 * sizeof(u32));
+	tunable->values = devm_kcalloc(dev, tunable->sz,
+				       sizeof(*tunable->values), GFP_KERNEL);
+	if (!tunable->values) {
+		tunable->sz = 0;
+		return -ENOMEM;
+	}
+
+	for (i = 0; i < tunable->sz; ++i) {
+		p = of_prop_next_u32(prop, p, &tunable->values[i].offset);
+		p = of_prop_next_u32(prop, p, &tunable->values[i].mask);
+		p = of_prop_next_u32(prop, p, &tunable->values[i].value);
+	}
+
+	return 0;
+}
+EXPORT_SYMBOL(devm_apple_parse_tunable);
+
+void devm_apple_free_tunable(struct device *dev, struct apple_tunable *tunable)
+{
+	devm_kfree(dev, tunable->values);
+	tunable->sz = 0;
+}
+EXPORT_SYMBOL(devm_apple_free_tunable);
+
+void apple_apply_tunable(void __iomem *regs, struct apple_tunable *tunable)
+{
+	size_t i;
+
+	for (i = 0; i < tunable->sz; ++i) {
+		u32 val, old_val;
+
+		val = old_val = readl_relaxed(regs + tunable->values[i].offset);
+		val &= ~tunable->values[i].mask;
+		val |= tunable->values[i].value;
+		if (val != old_val)
+			writel_relaxed(val, regs + tunable->values[i].offset);
+	}
+}
+EXPORT_SYMBOL(apple_apply_tunable);
+
+MODULE_LICENSE("Dual MIT/GPL");
+MODULE_AUTHOR("Sven Peter <sven@svenpeter.dev>");
+MODULE_DESCRIPTION("Apple Silicon hardware tunable support");
diff --git a/include/linux/soc/apple/tunable.h b/include/linux/soc/apple/tunable.h
new file mode 100644
index 0000000000000000000000000000000000000000..4a149f0f210d0b4b9e17c213f0482e8fbe02355f
--- /dev/null
+++ b/include/linux/soc/apple/tunable.h
@@ -0,0 +1,64 @@
+/* SPDX-License-Identifier: GPL-2.0-only OR MIT */
+/*
+ * Apple Silicon hardware tunable support
+ *
+ * Each tunable is a list with each entry containing a offset into the MMIO
+ * region, a mask of bits to be cleared and a set of bits to be set. These
+ * tunables are passed along by the previous boot stages and vary from device
+ * to device such that they cannot be hardcoded in the individual drivers.
+ *
+ * Copyright (C) The Asahi Linux Contributors
+ */
+
+#ifndef _LINUX_SOC_APPLE_TUNABLE_H_
+#define _LINUX_SOC_APPLE_TUNABLE_H_
+
+#include <linux/device.h>
+#include <linux/types.h>
+
+/*
+ * Struct to store a Apple Silicon hardware tunable.
+ *
+ * sz: number of [offset, mask, value] tuples stored in values.
+ * values: array containing the hardware tunables.
+ */
+struct apple_tunable {
+	size_t sz;
+	struct {
+		u32 offset;
+		u32 mask;
+		u32 value;
+	} *values;
+};
+
+/*
+ * Parse an array of hardware tunables from the device tree.
+ *
+ * Return 0 on success, -ENOMEM if the allocation failed and -ENOENT if the
+ * tunable could not be found or was in an invalid format.
+ *
+ * dev: Device node used for devm_kzalloc internally.
+ * np: Device node which contains the tunable array.
+ * tunable: Pointer to where the parsed tunables will be stored.
+ * name: Name of the device tree property which contains the tunables.
+ */
+int devm_apple_parse_tunable(struct device *dev, struct device_node *np,
+			     struct apple_tunable *tunable, const char *name);
+
+/*
+ * Apply a previously loaded hardware tunable.
+ *
+ * regs: MMIO to which the tunable will be applied.
+ * tunable: Pointer to the tunable.
+ */
+void apple_apply_tunable(void __iomem *regs, struct apple_tunable *tunable);
+
+/*
+ * Manually frees a previous allocated tunable.
+ *
+ * dev: Device node used for devm_apple_parse_tunable
+ * tunable: Tunable allocaated by devm_apple_parse_tunable
+ */
+void devm_apple_free_tunable(struct device *dev, struct apple_tunable *tunable);
+
+#endif

-- 
2.34.1

