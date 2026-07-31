From: David Heidelberg <david@ixit.cz>
Date: Fri, 31 Jul 2026 22:34:16 +0200
Subject: [PATCH v9 5/5] Input: synaptics-rmi4 - support fallback values for
 PDT descriptor bytes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-synaptics-rmi4-v9-5-f088c47af6c5@ixit.cz>
References: <20260731-synaptics-rmi4-v9-0-f088c47af6c5@ixit.cz>
In-Reply-To: <20260731-synaptics-rmi4-v9-0-f088c47af6c5@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>, 
 Marcus Ramberg <marcus@means.no>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: David Heidelberg <david@ixit.cz>, linux-input@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=8394; i=david@ixit.cz;
 h=from:subject:message-id; bh=VT8TqHstCB13MOIEZKScbmgMfHxX/aBtoMoj8AVgz1U=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqbQbLYCH85x470qignNeRtHqHSpeLX1zBIYo36
 HtaEIOvm1yJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCam0GywAKCRBgAj/E00kg
 chbiEACi51t1O1LIBouUqUYMob8colomKQr/xm30fx4f/7e5otQT2Y3oBMv0CTJTWNzuEtDmzbc
 DWC3Bba9q44387xMuUrOCv/IQj+Yzb3ltVGvkQzLCuyGKSCphw88n3C8fq65utK5kiLAE5+pYqd
 h6L6EbTxmkDARYXjnW7/dp/lryGa0BY9tb/+YPykQPlIW0YDND9j+4pkHTnhh/1mAqKE9XFjloW
 3OWG4SgrZ8QXZM14n+qwI5G2b5QOisLqeio8CpPPkjRIIyr+P2e5lfAzPxOkNVhq7juwhOdNhYF
 8Uiy8hqtxmEGsYjcUyFH99lYudIXYcRp24mJ0b9To23O/Ie34dXrLfycsr/zdgVyTpvhPeYsMBX
 7pVwYLg0ucg55shSCQF1QAs+9fTXygBAtELStH9ofOx/gnAXp3pcvSUJ0pvPLhyTSaIJZlDnj+0
 kJj/j9cEvr+ytKBejGCI3OhiEaUjE28F9TYaLjCOyqKMTQEqHrZCana6ypJStqP21IEPadMw6gt
 rGmPiJRqdzdiSHv1cZ7A9PAFdF0OHBwtXyZwwf+cbflfSb3+tyiD2zlEuXDNesn0dNC1e/oaBmw
 rz07wSTQBleaAnQQffhWmBVL9IPIVqXUxLjEq9yDcLl0yQ6WKOIwjrIS9OFXXlzScsycmP4ABxc
 mQNnBCFHf2hs8kA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Kaustabh Chakraborty <kauschluss@disroot.org>

Some replacement displays include third-party touch ICs which do not
expose the function number and the interrupt status in its PDT entries.

OnePlus 6 (original touch IC)
  rmi4_i2c 12-0020: read 6 bytes at 0x00e3: 0 (2b 22 0d 06 01 01)

OnePlus 6 (aftermarket touch IC)
  rmi4_i2c 12-0020: read 6 bytes at 0x00e3: 0 (2c 23 0d 06 00 00)

Signed-off-by: Kaustabh Chakraborty <kauschluss@disroot.org>
[codeflow adjustments, checkpatch fixes, wording]
Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Co-developed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/rmi4/rmi_driver.c | 64 +++++++++++++++++++++++++++++++++++------
 drivers/input/rmi4/rmi_driver.h |  3 ++
 include/linux/rmi.h             |  3 ++
 3 files changed, 62 insertions(+), 8 deletions(-)

diff --git a/drivers/input/rmi4/rmi_driver.c b/drivers/input/rmi4/rmi_driver.c
index 5e7766363aa23..dac26458f0937 100644
--- a/drivers/input/rmi4/rmi_driver.c
+++ b/drivers/input/rmi4/rmi_driver.c
@@ -461,29 +461,45 @@ static int rmi_driver_reset_handler(struct rmi_device *rmi_dev)
 
 	error = rmi_driver_process_config_requests(rmi_dev);
 	if (error < 0)
 		return error;
 
 	return 0;
 }
 
-static int rmi_read_pdt_entry(struct rmi_device *rmi_dev,
-			      struct pdt_entry *entry, u16 pdt_address)
+static int rmi_read_pdt_entry(struct rmi_device *rmi_dev, struct pdt_entry *entry,
+			      struct pdt_scan_state *state, u16 pdt_address)
 {
+	const struct rmi_device_platform_data *pdata = rmi_get_platform_data(rmi_dev);
 	u8 buf[RMI_PDT_ENTRY_SIZE];
 	int error;
 
 	error = rmi_read_block(rmi_dev, pdt_address, buf, RMI_PDT_ENTRY_SIZE);
 	if (error) {
 		dev_err(&rmi_dev->dev, "Read PDT entry at %#06x failed, code: %d.\n",
 				pdt_address, error);
 		return error;
 	}
 
+	if (pdata->pdt_fallback_size > state->pdt_count * RMI_OF_PDT_DESC_CELLS + 1) {
+		/* Use the description bytes from the driver */
+		buf[5] = pdata->pdt_fallback_desc[state->pdt_count * RMI_OF_PDT_DESC_CELLS];
+		buf[4] = pdata->pdt_fallback_desc[state->pdt_count * RMI_OF_PDT_DESC_CELLS + 1];
+
+		error = rmi_read_block(rmi_dev, pdt_address, buf,
+				RMI_PDT_ENTRY_SIZE - 2);
+		if (error) {
+			dev_err(&rmi_dev->dev,
+					"Read PDT entry at %#06x failed, code: %d.\n",
+					pdt_address, error);
+			return error;
+		}
+	}
+
 	entry->page_start = pdt_address & RMI4_PAGE_MASK;
 	entry->query_base_addr = buf[0];
 	entry->command_base_addr = buf[1];
 	entry->control_base_addr = buf[2];
 	entry->data_base_addr = buf[3];
 	entry->interrupt_source_count = buf[4] & RMI_PDT_INT_SOURCE_COUNT_MASK;
 	entry->function_version = (buf[4] & RMI_PDT_FUNCTION_VERSION_MASK) >> 5;
 	entry->function_number = buf[5];
@@ -521,16 +537,17 @@ static bool rmi_pdt_entry_is_valid(struct rmi_device *rmi_dev,
 		break;
 	default:
 		rmi_dbg(RMI_DEBUG_CORE, &rmi_dev->dev,
 			"PDT has unknown function number %#02x\n", fn);
 		return false;
 	}
 
 	state->pdts[fn] = true;
+	state->pdt_count++;
 	return true;
 }
 
 #define RMI_SCAN_CONTINUE	0
 #define RMI_SCAN_DONE		1
 
 static int rmi_scan_pdt_page(struct rmi_device *rmi_dev,
 			     int page,
@@ -545,17 +562,17 @@ static int rmi_scan_pdt_page(struct rmi_device *rmi_dev,
 	u16 page_start = RMI4_PAGE_SIZE * page;
 	u16 pdt_start = page_start + PDT_START_SCAN_LOCATION;
 	u16 pdt_end = page_start + PDT_END_SCAN_LOCATION;
 	u16 addr;
 	int error;
 	int retval;
 
 	for (addr = pdt_start; addr >= pdt_end; addr -= RMI_PDT_ENTRY_SIZE) {
-		error = rmi_read_pdt_entry(rmi_dev, &pdt_entry, addr);
+		error = rmi_read_pdt_entry(rmi_dev, &pdt_entry, state, addr);
 		if (error)
 			return error;
 
 		if (RMI4_END_OF_PDT(pdt_entry.function_number))
 			break;
 
 		if (!rmi_pdt_entry_is_valid(rmi_dev, state, pdt_entry.function_number))
 			continue;
@@ -1062,31 +1079,62 @@ static int rmi_driver_remove(struct device *dev)
 
 	irq_domain_remove(data->irqdomain);
 	data->irqdomain = NULL;
 
 	return 0;
 }
 
 #ifdef CONFIG_OF
-static int rmi_driver_of_probe(struct device *dev,
-				struct rmi_device_platform_data *pdata)
+static const u8 rmi_s3706_fallback_pdt[] = {0x34, 0x41, 0x01,
+					    0x01, 0x12, 0x01};
+
+static int rmi_driver_of_probe(struct rmi_device *rmi_dev,
+			       struct rmi_device_platform_data *pdata)
 {
+	struct device *dev = rmi_dev->xport->dev;
+	u8 buf[RMI_PDT_ENTRY_SIZE];
 	int retval;
 
 	retval = rmi_of_property_read_u32(dev, &pdata->reset_delay_ms,
 					"syna,reset-delay-ms", 1);
 	if (retval)
 		return retval;
 
+	/*
+	 * In some aftermerket touch ICs, the first PDT entry is empty and
+	 * the function number register is 0. If so, the driver
+	 * may have provide backup PDT entries.
+	 */
+
+	retval = rmi_read_block(rmi_dev, PDT_START_SCAN_LOCATION,
+			buf, RMI_PDT_ENTRY_SIZE);
+	if (retval) {
+		dev_err(dev, "Read PDT entry at %#06x failed, code: %d.\n",
+			PDT_START_SCAN_LOCATION, retval);
+		return retval;
+	}
+
+	if (!RMI4_END_OF_PDT(buf[5]))
+		return 0;
+
+	/* List of known PDT entries per compatible. */
+	if (of_device_is_compatible(dev->of_node, "syna,rmi4-s3706b")) {
+		pdata->pdt_fallback_desc = rmi_s3706_fallback_pdt;
+		pdata->pdt_fallback_size = ARRAY_SIZE(rmi_s3706_fallback_pdt);
+	} else {
+		dev_err(dev, "First PDT entry is empty and no backup values provided.\n");
+		return -EINVAL;
+	}
+
 	return 0;
 }
 #else
-static inline int rmi_driver_of_probe(struct device *dev,
-					struct rmi_device_platform_data *pdata)
+static inline int rmi_driver_of_probe(struct rmi_device *rmi_dev,
+				      struct rmi_device_platform_data *pdata)
 {
 	return -ENODEV;
 }
 #endif
 
 int rmi_probe_interrupts(struct rmi_driver_data *data)
 {
 	struct rmi_device *rmi_dev = data->rmi_dev;
@@ -1197,17 +1245,17 @@ static int rmi_driver_probe(struct device *dev)
 
 	rmi_dev = to_rmi_device(dev);
 	rmi_driver = to_rmi_driver(dev->driver);
 	rmi_dev->driver = rmi_driver;
 
 	pdata = rmi_get_platform_data(rmi_dev);
 
 	if (rmi_dev->xport->dev->of_node) {
-		retval = rmi_driver_of_probe(rmi_dev->xport->dev, pdata);
+		retval = rmi_driver_of_probe(rmi_dev, pdata);
 		if (retval)
 			return retval;
 	}
 
 	data = devm_kzalloc(dev, sizeof(struct rmi_driver_data), GFP_KERNEL);
 	if (!data)
 		return -ENOMEM;
 
diff --git a/drivers/input/rmi4/rmi_driver.h b/drivers/input/rmi4/rmi_driver.h
index 6de8faed08917..f69337510c333 100644
--- a/drivers/input/rmi4/rmi_driver.h
+++ b/drivers/input/rmi4/rmi_driver.h
@@ -26,16 +26,18 @@
 #define RMI_PDT_PROPS_HAS_BSR 0x02
 
 #define NAME_BUFFER_SIZE 256
 
 #define RMI_PDT_ENTRY_SIZE 6
 #define RMI_PDT_FUNCTION_VERSION_MASK   0x60
 #define RMI_PDT_INT_SOURCE_COUNT_MASK   0x07
 
+#define RMI_OF_PDT_DESC_CELLS 2
+
 #define PDT_START_SCAN_LOCATION 0x00e9
 #define PDT_END_SCAN_LOCATION	0x0005
 #define RMI4_END_OF_PDT(id) ((id) == 0x00 || (id) == 0xff)
 
 struct pdt_entry {
 	u16 page_start;
 	u8 query_base_addr;
 	u8 command_base_addr;
@@ -48,16 +50,17 @@ struct pdt_entry {
 
 #define RMI_REG_DESC_PRESENCE_BITS	(32 * BITS_PER_BYTE)
 #define RMI_REG_DESC_PRESENCE_REGS_MAX	(3 + RMI_REG_DESC_PRESENCE_BITS / 8)
 #define RMI_REG_DESC_SUBPACKET_BITS	(37 * BITS_PER_BYTE)
 #define RMI_PDT_MAX 0x55
 
 struct pdt_scan_state {
 	u8 empty_pages;
+	u8 pdt_count;
 	bool pdts[RMI_PDT_MAX + 1];
 };
 
 
 /* describes a single packet register */
 struct rmi_register_desc_item {
 	u32 reg_size;
 	u16 reg;
diff --git a/include/linux/rmi.h b/include/linux/rmi.h
index ab7eea01ab427..4ba2cefac8558 100644
--- a/include/linux/rmi.h
+++ b/include/linux/rmi.h
@@ -209,16 +209,19 @@ struct rmi_device_platform_data_spi {
  * driver waits a few milliseconds to give the firmware a chance to
  * re-initialize.  You can override the default wait period here.
  * @irq: irq associated with the attn gpio line, or negative
  */
 struct rmi_device_platform_data {
 	int reset_delay_ms;
 	int irq;
 
+	unsigned int pdt_fallback_size;
+	const u8 *pdt_fallback_desc;
+
 	struct rmi_device_platform_data_spi spi_data;
 
 	/* function handler pdata */
 	struct rmi_2d_sensor_platform_data sensor_pdata;
 	struct rmi_f01_power_management power_management;
 	struct rmi_gpio_data gpio_data;
 };
 

-- 
2.53.0

