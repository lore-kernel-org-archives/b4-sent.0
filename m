From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Date: Sun, 18 Oct 2026 22:41:50 +0100
Subject: [PATCH 1/2] staging: iio: addac: adt7316: propagate bus error
 codes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-adt7316-error-codes-v1-1-1970b7e242ac@gmail.com>
References: <20261018-adt7316-error-codes-v1-0-1970b7e242ac@gmail.com>
In-Reply-To: <20261018-adt7316-error-codes-v1-0-1970b7e242ac@gmail.com>
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux@analog.com, linux-iio@vger.kernel.org, 
 linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792359739; l=10560;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=ofLh5PtlND7epJjJY6nK2QBdXEJEnRZ1Kp7d1bQ6yCk=;
 b=7Fwn+2AWYRwynTPA2KFn0lz1Y//Ckt6F28dHN8gI6aoKlVMAUCdNohhyu5q6EOLBrNu+QJ9Zo
 vb5ol6E2bEXDkyTyVeyQhD+mp66nBh7oLQuRSsJqKDk4ltbrN08rlZs
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Many register accesses replace the error returned by the bus read and
write helpers with -EIO, hiding the actual cause of a failure such as
-ENXIO or -ETIMEDOUT from the I2C or SPI core.

The bus helpers already return a negative errno on failure and 0 on
success, so return their error code unchanged instead. Do the same
for the result of _adt7316_store_enabled() in adt7316_store_enabled().

Assisted-by: LLM
Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
---
 drivers/staging/iio/addac/adt7316.c | 84 +++++++++++++++++++------------------
 1 file changed, 43 insertions(+), 41 deletions(-)

diff --git a/drivers/staging/iio/addac/adt7316.c b/drivers/staging/iio/addac/adt7316.c
index 8ca6def84584..d495032786db 100644
--- a/drivers/staging/iio/addac/adt7316.c
+++ b/drivers/staging/iio/addac/adt7316.c
@@ -232,7 +232,7 @@ static ssize_t _adt7316_store_enabled(struct adt7316_chip_info *chip,
 
 	ret = chip->bus.write(chip->bus.client, ADT7316_CONFIG1, config1);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	chip->config1 = config1;
 
@@ -247,14 +247,16 @@ static ssize_t adt7316_store_enabled(struct device *dev,
 	struct iio_dev *dev_info = dev_to_iio_dev(dev);
 	struct adt7316_chip_info *chip = iio_priv(dev_info);
 	int enable;
+	int ret;
 
 	if (buf[0] == '1')
 		enable = 1;
 	else
 		enable = 0;
 
-	if (_adt7316_store_enabled(chip, enable) < 0)
-		return -EIO;
+	ret = _adt7316_store_enabled(chip, enable);
+	if (ret < 0)
+		return ret;
 
 	return len;
 }
@@ -296,7 +298,7 @@ static ssize_t adt7316_store_select_ex_temp(struct device *dev,
 
 	ret = chip->bus.write(chip->bus.client, ADT7316_CONFIG1, config1);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	chip->config1 = config1;
 
@@ -337,7 +339,7 @@ static ssize_t adt7316_store_mode(struct device *dev,
 
 	ret = chip->bus.write(chip->bus.client, ADT7316_CONFIG2, config2);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	chip->config2 = config2;
 
@@ -430,7 +432,7 @@ static ssize_t adt7316_store_ad_channel(struct device *dev,
 
 	ret = chip->bus.write(chip->bus.client, ADT7316_CONFIG2, config2);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	chip->config2 = config2;
 
@@ -490,7 +492,7 @@ static ssize_t adt7316_store_disable_averaging(struct device *dev,
 
 	ret = chip->bus.write(chip->bus.client, ADT7316_CONFIG2, config2);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	chip->config2 = config2;
 
@@ -529,7 +531,7 @@ static ssize_t adt7316_store_enable_smbus_timeout(struct device *dev,
 
 	ret = chip->bus.write(chip->bus.client, ADT7316_CONFIG2, config2);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	chip->config2 = config2;
 
@@ -567,7 +569,7 @@ static ssize_t adt7316_store_powerdown(struct device *dev,
 
 	ret = chip->bus.write(chip->bus.client, ADT7316_CONFIG1, config1);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	chip->config1 = config1;
 
@@ -605,7 +607,7 @@ static ssize_t adt7316_store_fast_ad_clock(struct device *dev,
 
 	ret = chip->bus.write(chip->bus.client, ADT7316_CONFIG3, config3);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	chip->config3 = config3;
 
@@ -651,7 +653,7 @@ static ssize_t adt7316_store_da_high_resolution(struct device *dev,
 
 	ret = chip->bus.write(chip->bus.client, ADT7316_CONFIG3, config3);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	chip->config3 = config3;
 
@@ -697,7 +699,7 @@ static ssize_t adt7316_store_AIN_internal_Vref(struct device *dev,
 
 	ret = chip->bus.write(chip->bus.client, ADT7316_CONFIG3, config3);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	chip->config3 = config3;
 
@@ -736,7 +738,7 @@ static ssize_t adt7316_store_enable_prop_DACA(struct device *dev,
 
 	ret = chip->bus.write(chip->bus.client, ADT7316_CONFIG3, config3);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	chip->config3 = config3;
 
@@ -775,7 +777,7 @@ static ssize_t adt7316_store_enable_prop_DACB(struct device *dev,
 
 	ret = chip->bus.write(chip->bus.client, ADT7316_CONFIG3, config3);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	chip->config3 = config3;
 
@@ -818,7 +820,7 @@ static ssize_t adt7316_store_DAC_2Vref_ch_mask(struct device *dev,
 
 	ret = chip->bus.write(chip->bus.client, ADT7316_DAC_CONFIG, dac_config);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	chip->dac_config = dac_config;
 
@@ -878,7 +880,7 @@ static ssize_t adt7316_store_DAC_update_mode(struct device *dev,
 
 	ret = chip->bus.write(chip->bus.client, ADT7316_DAC_CONFIG, dac_config);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	chip->dac_config = dac_config;
 
@@ -934,7 +936,7 @@ static ssize_t adt7316_store_update_DAC(struct device *dev,
 		ret = chip->bus.write(chip->bus.client, ADT7316_LDAC_CONFIG,
 			ldac_config);
 		if (ret)
-			return -EIO;
+			return ret;
 	} else {
 		gpiod_set_value(chip->ldac_pin, 0);
 		gpiod_set_value(chip->ldac_pin, 1);
@@ -975,7 +977,7 @@ static ssize_t adt7316_store_DA_AB_Vref_bypass(struct device *dev,
 
 	ret = chip->bus.write(chip->bus.client, ADT7316_DAC_CONFIG, dac_config);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	chip->dac_config = dac_config;
 
@@ -1014,7 +1016,7 @@ static ssize_t adt7316_store_DA_CD_Vref_bypass(struct device *dev,
 
 	ret = chip->bus.write(chip->bus.client, ADT7316_DAC_CONFIG, dac_config);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	chip->dac_config = dac_config;
 
@@ -1075,7 +1077,7 @@ static ssize_t adt7316_store_DAC_internal_Vref(struct device *dev,
 	ret = chip->bus.write(chip->bus.client, ADT7316_LDAC_CONFIG,
 			ldac_config);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	chip->ldac_config = ldac_config;
 
@@ -1104,12 +1106,12 @@ static ssize_t adt7316_show_ad(struct adt7316_chip_info *chip,
 		ret = chip->bus.read(chip->bus.client,
 			ADT7316_LSB_IN_TEMP_VDD, &lsb);
 		if (ret)
-			return -EIO;
+			return ret;
 
 		ret = chip->bus.read(chip->bus.client,
 			ADT7316_AD_MSB_DATA_BASE + channel, &msb);
 		if (ret)
-			return -EIO;
+			return ret;
 
 		data = msb << ADT7316_T_VALUE_FLOAT_OFFSET;
 		data |= lsb & ADT7316_LSB_IN_TEMP_MASK;
@@ -1118,13 +1120,13 @@ static ssize_t adt7316_show_ad(struct adt7316_chip_info *chip,
 		ret = chip->bus.read(chip->bus.client,
 			ADT7316_LSB_IN_TEMP_VDD, &lsb);
 		if (ret)
-			return -EIO;
+			return ret;
 
 		ret = chip->bus.read(chip->bus.client,
 
 			ADT7316_AD_MSB_DATA_BASE + channel, &msb);
 		if (ret)
-			return -EIO;
+			return ret;
 
 		data = msb << ADT7316_T_VALUE_FLOAT_OFFSET;
 		data |= (lsb & ADT7316_LSB_VDD_MASK) >> ADT7316_LSB_VDD_OFFSET;
@@ -1133,12 +1135,12 @@ static ssize_t adt7316_show_ad(struct adt7316_chip_info *chip,
 		ret = chip->bus.read(chip->bus.client,
 			ADT7316_LSB_EX_TEMP_AIN, &lsb);
 		if (ret)
-			return -EIO;
+			return ret;
 
 		ret = chip->bus.read(chip->bus.client,
 			ADT7316_AD_MSB_DATA_BASE + channel, &msb);
 		if (ret)
-			return -EIO;
+			return ret;
 
 		data = msb << ADT7316_T_VALUE_FLOAT_OFFSET;
 		data |= lsb & (ADT7316_LSB_EX_TEMP_MASK <<
@@ -1241,7 +1243,7 @@ static ssize_t adt7316_show_temp_offset(struct adt7316_chip_info *chip,
 
 	ret = chip->bus.read(chip->bus.client, offset_addr, &val);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	data = (int)val;
 	if (val & 0x80)
@@ -1270,7 +1272,7 @@ static ssize_t adt7316_store_temp_offset(struct adt7316_chip_info *chip,
 
 	ret = chip->bus.write(chip->bus.client, offset_addr, val);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	return len;
 }
@@ -1401,13 +1403,13 @@ static ssize_t adt7316_show_DAC(struct adt7316_chip_info *chip,
 		ret = chip->bus.read(chip->bus.client,
 			ADT7316_DA_DATA_BASE + channel * 2, &lsb);
 		if (ret)
-			return -EIO;
+			return ret;
 	}
 
 	ret = chip->bus.read(chip->bus.client,
 		ADT7316_DA_DATA_BASE + 1 + channel * 2, &msb);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	if (chip->dac_bits == 12)
 		data = lsb >> ADT7316_DA_12_BIT_LSB_SHIFT;
@@ -1447,14 +1449,14 @@ static ssize_t adt7316_store_DAC(struct adt7316_chip_info *chip,
 		ret = chip->bus.write(chip->bus.client,
 			ADT7316_DA_DATA_BASE + channel * 2, lsb_reg);
 		if (ret)
-			return -EIO;
+			return ret;
 	}
 
 	msb = data >> offset;
 	ret = chip->bus.write(chip->bus.client,
 		ADT7316_DA_DATA_BASE + 1 + channel * 2, msb);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	return len;
 }
@@ -1566,7 +1568,7 @@ static ssize_t adt7316_show_device_id(struct device *dev,
 
 	ret = chip->bus.read(chip->bus.client, ADT7316_DEVICE_ID, &id);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	return sysfs_emit(buf, "%d\n", id);
 }
@@ -1584,7 +1586,7 @@ static ssize_t adt7316_show_manufactorer_id(struct device *dev,
 
 	ret = chip->bus.read(chip->bus.client, ADT7316_MANUFACTURE_ID, &id);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	return sysfs_emit(buf, "%d\n", id);
 }
@@ -1603,7 +1605,7 @@ static ssize_t adt7316_show_device_rev(struct device *dev,
 
 	ret = chip->bus.read(chip->bus.client, ADT7316_DEVICE_REV, &rev);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	return sysfs_emit(buf, "%d\n", rev);
 }
@@ -1621,7 +1623,7 @@ static ssize_t adt7316_show_bus_type(struct device *dev,
 
 	ret = chip->bus.read(chip->bus.client, ADT7316_SPI_LOCK_STAT, &stat);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	if (stat)
 		return sysfs_emit(buf, "spi\n");
@@ -1897,7 +1899,7 @@ static inline ssize_t adt7316_show_ad_bound(struct device *dev,
 
 	ret = chip->bus.read(chip->bus.client, this_attr->address, &val);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	data = (int)val;
 
@@ -1946,7 +1948,7 @@ static inline ssize_t adt7316_set_ad_bound(struct device *dev,
 
 	ret = chip->bus.write(chip->bus.client, this_attr->address, val);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	return len;
 }
@@ -1977,7 +1979,7 @@ static ssize_t adt7316_set_int_enabled(struct device *dev,
 
 	ret = chip->bus.write(chip->bus.client, ADT7316_CONFIG1, config1);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	chip->config1 = config1;
 
@@ -2170,11 +2172,11 @@ int adt7316_probe(struct device *dev, struct adt7316_bus *bus,
 
 	ret = chip->bus.write(chip->bus.client, ADT7316_CONFIG1, chip->config1);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	ret = chip->bus.write(chip->bus.client, ADT7316_CONFIG3, chip->config3);
 	if (ret)
-		return -EIO;
+		return ret;
 
 	ret = devm_iio_device_register(dev, indio_dev);
 	if (ret)

-- 
2.56.0

