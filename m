From: David Heidelberg <david@ixit.cz>
Date: Fri, 20 Mar 2026 17:44:48 +0100
Subject: [PATCH v7 7/7] Input: synaptics-rmi4 - support fallback values for
 PDT descriptor bytes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260320-synaptics-rmi4-v7-7-379360de18d0@ixit.cz>
References: <20260320-synaptics-rmi4-v7-0-379360de18d0@ixit.cz>
In-Reply-To: <20260320-synaptics-rmi4-v7-0-379360de18d0@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: David Heidelberg <david@ixit.cz>, linux-input@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Casey Connolly <casey.connolly@linaro.org>, phone-devel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=5650; i=david@ixit.cz;
 h=from:subject:message-id; bh=QMO1uzX1oG+qWT4REjO5yGwZjOwaRzQblxJ3S0B14zU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpvXl7Q9U4PfdLwey2srzJGevl8h0ui7MAH+72Q
 qcqBZmvDheJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCab15ewAKCRBgAj/E00kg
 clvrD/9diJd5zIoKHMycuW8cwdpYvPIbOPmI1d9P9zCktRm+AoYEdCRGN3rQ8iWb4uS3mh6mLPH
 nd7V1IN2f4shG/5O9nF8qRfn/QAGQn2DQzkWdKnnrbMhB7QNYI1m1VNr+U/FS5jRNrs6fmUSL/M
 YBd2E4od79C9D40X2Jrrr6pSbocRf3aiCov3F0vZo8QGdtPBpeRWPEnc8O2RYDPoOHxEksmi8aw
 tyuxrvlT1EVryWOP1uL06L52h4laLAqoXXX+c0hGK4ZFIlJPHtqFl0kgjWSl5pW5Y88H/RGkMM2
 WEwjmpJdkL4L+QuXX7CkxFjDAbaT4g6j1EltdwYEzAD/OwPr43IXoDVqM+PApKlbzd5Z6R8eabr
 Y32kY3h25vKjEwBUSYiiG7zaXfE4TqE8aBzSl0BlWLNENIGFfBEBnLduP6sWTBugN9e+Br+RdNo
 VtyfxA6SgpbO2qWtXFffbtcRhhS9asc6huLQOrZQ9zdeZmBlvyBUWFqupm503lCAMKoIsJQluxA
 gBclZ0Qukqmy6lM10CCVcswWlX7sv8iVFI8lF7OuVxC8iLUUM48Jl5e4VVPpjNM5r04D5VJ2hpD
 b0c0p8h8NcaLUtKBNi5PHdu7SlnXD/8WNuQyREmGHqtn+nSpaLP7Xenr4UFmNligUY/FjiARsgP
 jOtxnlDdGPMh9lw==
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
 drivers/input/rmi4/rmi_driver.c | 62 +++++++++++++++++++++++++++++++++++------
 drivers/input/rmi4/rmi_driver.h |  2 ++
 include/linux/rmi.h             |  3 ++
 3 files changed, 59 insertions(+), 8 deletions(-)

diff --git a/drivers/input/rmi4/rmi_driver.c b/drivers/input/rmi4/rmi_driver.c
index 93a190e333c66..bb1db5bbb3abb 100644
--- a/drivers/input/rmi4/rmi_driver.c
+++ b/drivers/input/rmi4/rmi_driver.c
@@ -462,9 +462,10 @@ static int rmi_driver_reset_handler(struct rmi_device *rmi_dev)
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
 
@@ -475,6 +476,21 @@ static int rmi_read_pdt_entry(struct rmi_device *rmi_dev,
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
@@ -547,7 +563,7 @@ static int rmi_scan_pdt_page(struct rmi_device *rmi_dev,
 	int retval;
 
 	for (addr = pdt_start; addr >= pdt_end; addr -= RMI_PDT_ENTRY_SIZE) {
-		error = rmi_read_pdt_entry(rmi_dev, &pdt_entry, addr);
+		error = rmi_read_pdt_entry(rmi_dev, &pdt_entry, state, addr);
 		if (error)
 			return error;
 
@@ -1024,9 +1040,13 @@ static int rmi_driver_remove(struct device *dev)
 }
 
 #ifdef CONFIG_OF
-static int rmi_driver_of_probe(struct device *dev,
-				struct rmi_device_platform_data *pdata)
+static const u8 rmi_s3706_fallback_pdt[] = {34, 41, 01, 01, 12, 01};
+
+static int rmi_driver_of_probe(struct rmi_device *rmi_dev,
+			       struct rmi_device_platform_data *pdata)
 {
+	struct device *dev = rmi_dev->xport->dev;
+	u8 buf[RMI_PDT_ENTRY_SIZE];
 	int retval;
 
 	retval = rmi_of_property_read_u32(dev, &pdata->reset_delay_ms,
@@ -1034,11 +1054,37 @@ static int rmi_driver_of_probe(struct device *dev,
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
@@ -1159,7 +1205,7 @@ static int rmi_driver_probe(struct device *dev)
 	pdata = rmi_get_platform_data(rmi_dev);
 
 	if (rmi_dev->xport->dev->of_node) {
-		retval = rmi_driver_of_probe(rmi_dev->xport->dev, pdata);
+		retval = rmi_driver_of_probe(rmi_dev, pdata);
 		if (retval)
 			return retval;
 	}
diff --git a/drivers/input/rmi4/rmi_driver.h b/drivers/input/rmi4/rmi_driver.h
index a4ae2af93ce3a..b931f428713bf 100644
--- a/drivers/input/rmi4/rmi_driver.h
+++ b/drivers/input/rmi4/rmi_driver.h
@@ -31,6 +31,8 @@
 #define RMI_PDT_FUNCTION_VERSION_MASK   0x60
 #define RMI_PDT_INT_SOURCE_COUNT_MASK   0x07
 
+#define RMI_OF_PDT_DESC_CELLS 2
+
 #define PDT_START_SCAN_LOCATION 0x00e9
 #define PDT_END_SCAN_LOCATION	0x0005
 #define RMI4_END_OF_PDT(id) ((id) == 0x00 || (id) == 0xff)
diff --git a/include/linux/rmi.h b/include/linux/rmi.h
index ab7eea01ab427..4ba2cefac8558 100644
--- a/include/linux/rmi.h
+++ b/include/linux/rmi.h
@@ -214,6 +214,9 @@ struct rmi_device_platform_data {
 	int reset_delay_ms;
 	int irq;
 
+	unsigned int pdt_fallback_size;
+	const u8 *pdt_fallback_desc;
+
 	struct rmi_device_platform_data_spi spi_data;
 
 	/* function handler pdata */

-- 
2.53.0

