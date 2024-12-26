From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 26 Dec 2024 15:57:42 +0800
Subject: [PATCH v2 2/5] pinctrl: pinconf-generic: Add API for pinmux
 propertity in DTS file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241226-amlogic-pinctrl-v2-2-cdae42a67b76@amlogic.com>
References: <20241226-amlogic-pinctrl-v2-0-cdae42a67b76@amlogic.com>
In-Reply-To: <20241226-amlogic-pinctrl-v2-0-cdae42a67b76@amlogic.com>
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735199863; l=5888;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=9WW//dUOTdBjl9f7lCFon2tYsUfLouYXGzujcRPmHJc=;
 b=CgBSVVEtUaDNo/6QLDsQtGoQBwNAlgYidsVJG13UjGuHA5KxAdCM4jRt7ku9uELOVX28xcfwJ
 Tb5PszdzVt6BBKIIM0aoCsfAmCm+QBs8uGh0pEMt02XevIoaS7Dilrb
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When describing pin mux func through pinmux propertity,
a standard API is added for support. The pinmux contains pin
identification and mux values, which can include multiple
pins. And groups configuration use other word. DTS such as:

func-name {
	group_alias: group-name{
		pinmux= <pin_id << 8 | mux_value)>,
			<pin_id << 8 | mux_value)>;
		bias-pull-up;
		drive-strength-microamp = <4000>;
	};
};

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/pinctrl/pinconf-generic.c       | 130 ++++++++++++++++++++++++++++++++
 drivers/pinctrl/pinconf.h               |   4 +
 include/linux/pinctrl/pinconf-generic.h |   4 +
 3 files changed, 138 insertions(+)

diff --git a/drivers/pinctrl/pinconf-generic.c b/drivers/pinctrl/pinconf-generic.c
index 0b13d7f17b32..a4d3c12a80c4 100644
--- a/drivers/pinctrl/pinconf-generic.c
+++ b/drivers/pinctrl/pinconf-generic.c
@@ -233,6 +233,67 @@ static void parse_dt_cfg(struct device_node *np,
 	}
 }
 
+/**
+ * pinconf_generic_parse_dt_pinmux()
+ * parse the pinmux properties into generic pin mux values.
+ * @np: node containing the pinmux properties
+ * @pctldev: pincontrol device
+ * @pid: array with pin identity entries
+ * @pmux: array with pin mux value entries
+ * @npins: number of pins
+ *
+ * pinmux propertity: mux value [0,7]bits and pin identity [8,31]bits.
+ */
+int pinconf_generic_parse_dt_pinmux(struct device_node *np, struct device *dev,
+				    unsigned int **pid, unsigned int **pmux,
+				    unsigned int *npins)
+{
+	unsigned int *pid_t;
+	unsigned int *pmux_t;
+	struct property *prop;
+	unsigned int npins_t, i;
+	u32 value;
+	int ret;
+
+	prop = of_find_property(np, "pinmux", NULL);
+	if (!prop) {
+		dev_info(dev, "Missing pinmux property\n");
+		return -ENOENT;
+	}
+
+	if (!pid || !pmux || !npins) {
+		dev_err(dev, "paramers error\n");
+		return -EINVAL;
+	}
+
+	npins_t = prop->length / sizeof(u32);
+	pid_t = devm_kcalloc(dev, npins_t, sizeof(*pid_t), GFP_KERNEL);
+	pmux_t = devm_kcalloc(dev, npins_t, sizeof(*pmux_t), GFP_KERNEL);
+	if (!pid_t || !pmux_t) {
+		dev_err(dev, "kalloc memory fail\n");
+		return -ENOMEM;
+	}
+	for (i = 0; i < npins_t; i++) {
+		ret = of_property_read_u32_index(np, "pinmux", i, &value);
+		if (ret) {
+			dev_err(dev, "get pinmux value fail\n");
+			goto exit;
+		}
+		pmux_t[i] = value & 0xff;
+		pid_t[i] = (value >> 8) & 0xffffff;
+	}
+	*pid = pid_t;
+	*pmux = pmux_t;
+	*npins = npins_t;
+
+	return 0;
+exit:
+	devm_kfree(dev, pid_t);
+	devm_kfree(dev, pmux_t);
+	return ret;
+}
+EXPORT_SYMBOL_GPL(pinconf_generic_parse_dt_pinmux);
+
 /**
  * pinconf_generic_parse_dt_config()
  * parse the config properties into generic pinconfig values.
@@ -295,6 +356,75 @@ int pinconf_generic_parse_dt_config(struct device_node *np,
 }
 EXPORT_SYMBOL_GPL(pinconf_generic_parse_dt_config);
 
+int pinconf_generic_dt_node_to_map_pinmux(struct pinctrl_dev *pctldev,
+					  struct device_node *np,
+					  struct pinctrl_map **map,
+					  unsigned int *num_maps)
+{
+	struct device *dev = pctldev->dev;
+	struct device_node *pnode;
+	unsigned long *configs = NULL;
+	unsigned int num_configs = 0;
+	struct property *prop;
+	unsigned int reserved_maps;
+	int reserve;
+	int ret;
+
+	prop = of_find_property(np, "pinmux", NULL);
+	if (!prop) {
+		dev_info(dev, "Missing pinmux property\n");
+		return -ENOENT;
+	}
+
+	pnode = of_get_parent(np);
+	if (!pnode) {
+		dev_info(dev, "Missing function node\n");
+		return -EINVAL;
+	}
+
+	reserved_maps = 0;
+	*map = NULL;
+	*num_maps = 0;
+
+	ret = pinconf_generic_parse_dt_config(np, pctldev, &configs,
+					      &num_configs);
+	if (ret < 0) {
+		dev_err(dev, "%pOF: could not parse node property\n", np);
+		return ret;
+	}
+
+	reserve = 1;
+	if (num_configs)
+		reserve++;
+
+	ret = pinctrl_utils_reserve_map(pctldev, map, &reserved_maps,
+					num_maps, reserve);
+	if (ret < 0)
+		goto exit;
+
+	ret = pinctrl_utils_add_map_mux(pctldev, map,
+					&reserved_maps, num_maps, np->name,
+					pnode->name);
+	if (ret < 0)
+		goto exit;
+
+	if (num_configs) {
+		ret = pinctrl_utils_add_map_configs(pctldev, map, &reserved_maps,
+						    num_maps, np->name, configs,
+						    num_configs, PIN_MAP_TYPE_CONFIGS_GROUP);
+		if (ret < 0)
+			goto exit;
+	}
+
+exit:
+	kfree(configs);
+	if (ret)
+		pinctrl_utils_free_map(pctldev, *map, *num_maps);
+
+	return ret;
+}
+EXPORT_SYMBOL_GPL(pinconf_generic_dt_node_to_map_pinmux);
+
 int pinconf_generic_dt_subnode_to_map(struct pinctrl_dev *pctldev,
 		struct device_node *np, struct pinctrl_map **map,
 		unsigned int *reserved_maps, unsigned int *num_maps,
diff --git a/drivers/pinctrl/pinconf.h b/drivers/pinctrl/pinconf.h
index a14c950bc700..a171195b3615 100644
--- a/drivers/pinctrl/pinconf.h
+++ b/drivers/pinctrl/pinconf.h
@@ -138,4 +138,8 @@ int pinconf_generic_parse_dt_config(struct device_node *np,
 				    struct pinctrl_dev *pctldev,
 				    unsigned long **configs,
 				    unsigned int *nconfigs);
+
+int pinconf_generic_parse_dt_pinmux(struct device_node *np, struct device *dev,
+				    unsigned int **pid, unsigned int **pmux,
+				    unsigned int *npins);
 #endif
diff --git a/include/linux/pinctrl/pinconf-generic.h b/include/linux/pinctrl/pinconf-generic.h
index 53cfde98433d..1bcf071b860e 100644
--- a/include/linux/pinctrl/pinconf-generic.h
+++ b/include/linux/pinctrl/pinconf-generic.h
@@ -232,4 +232,8 @@ static inline int pinconf_generic_dt_node_to_map_all(struct pinctrl_dev *pctldev
 			PIN_MAP_TYPE_INVALID);
 }
 
+int pinconf_generic_dt_node_to_map_pinmux(struct pinctrl_dev *pctldev,
+					  struct device_node *np,
+					  struct pinctrl_map **map,
+					  unsigned int *num_maps);
 #endif /* __LINUX_PINCTRL_PINCONF_GENERIC_H */

-- 
2.37.1

