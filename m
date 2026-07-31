From: David Heidelberg <david@ixit.cz>
Date: Fri, 31 Jul 2026 22:34:12 +0200
Subject: [PATCH v9 1/5] Input: synaptics-rmi4 - handle duplicate/unknown
 PDT entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-synaptics-rmi4-v9-1-f088c47af6c5@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4835; i=david@ixit.cz;
 h=from:subject:message-id; bh=QMmRp8KVD1VgRiH9r3c9vC9t2faLPigCXSGNEqMux4o=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqbQbLdbwhgLM+vUDHssT065RleIOK4kdKZsiWP
 /hyFkkNeMyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCam0GywAKCRBgAj/E00kg
 cqBND/wJMxsTYkoG+1yN8r2lL0YR57M6mu13XPU2KVd9e8M7Tro17L2KLqcibf7/4XKoZI2jPuu
 ny5AE7B9fvtxdvrhPhnaUlQ8s4hn1OEq+GHfXT7PqhGxqjpimFNy6Ic7qC4HA/YeXl3YMBZQl7j
 h7loBfNoqZU8/bHhwFyzxur+rQx4ib3KEP8iITXNV9xijlKIy39OwFJ0eYZSQoznqiU/q+6nhso
 E39rVd9Ptkx2sBh49Ybk0d5aBiNFKEGnqL4MDZQ33MXJR+/WomJFbJFXaIQyLnmtlAMyA7B+Mir
 ze550DrD1IYatrWYV7wB3N/ld2nPLxyzj6pp160saV0A5aDy9XHNg8Ll0dl22ILq6JJhjI7jbWa
 nxYjfEKLbMhFjmZ4xo+pPPeLJvw5widNjkuFSxmCEcf3hpTPY/rX/x1kCY+rVemzgSw70lGONHJ
 6+4KVz+XCncbJ1Yd3ijwSjVHDcqn5lmbEysKF9ydogfdMUdzzoxA2fX7lvmkz+diFLOl1FwQdbr
 h0SugZDpiSY54gnGCs6+djCFTs/M9zn4ymn00byaINHQ3WT7u++4PZx/0Uc89e47GGMvuJ9t3BJ
 cUrND48duKOU5cg0DOB5xlqqWMVkfZE8CbXveewYaZmHltvNRXRkhjlEGVR1MZBbyrJhzlnnfhv
 mVUIxy77bd6U5hg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

Some third party rmi4-compatible ICs don't expose their PDT entries
very well. Add a few checks to skip duplicate entries as well as entries
for unsupported functions.

This is required to support some phones with third party displays.

Validated on a stock OnePlus 6T (original parts):
manufacturer: Synaptics, product: S3706B, fw id: 2852315

Co-developed-by: Kaustabh Chakraborty <kauschluss@disroot.org>
Signed-off-by: Kaustabh Chakraborty <kauschluss@disroot.org>
Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Co-developed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/rmi4/rmi_driver.c | 41 +++++++++++++++++++++++++++++++++++------
 drivers/input/rmi4/rmi_driver.h |  7 +++++++
 2 files changed, 42 insertions(+), 6 deletions(-)

diff --git a/drivers/input/rmi4/rmi_driver.c b/drivers/input/rmi4/rmi_driver.c
index 5d49a9021c7d0..3edec5ae1f8c9 100644
--- a/drivers/input/rmi4/rmi_driver.c
+++ b/drivers/input/rmi4/rmi_driver.c
@@ -493,22 +493,48 @@ static void rmi_driver_copy_pdt_to_fd(const struct pdt_entry *pdt,
 	fd->command_base_addr = pdt->command_base_addr + pdt->page_start;
 	fd->control_base_addr = pdt->control_base_addr + pdt->page_start;
 	fd->data_base_addr = pdt->data_base_addr + pdt->page_start;
 	fd->function_number = pdt->function_number;
 	fd->interrupt_source_count = pdt->interrupt_source_count;
 	fd->function_version = pdt->function_version;
 }
 
+static bool rmi_pdt_entry_is_valid(struct rmi_device *rmi_dev,
+				   struct pdt_scan_state *state, u8 fn)
+{
+	switch (fn) {
+	case 0x01:
+	case 0x03:
+	case 0x11:
+	case 0x12:
+	case 0x30:
+	case 0x34:
+	case 0x3a:
+	case 0x54:
+	case 0x55:
+		if (state->pdts[fn] == true)
+			return false;
+		break;
+	default:
+		rmi_dbg(RMI_DEBUG_CORE, &rmi_dev->dev,
+			"PDT has unknown function number %#02x\n", fn);
+		return false;
+	}
+
+	state->pdts[fn] = true;
+	return true;
+}
+
 #define RMI_SCAN_CONTINUE	0
 #define RMI_SCAN_DONE		1
 
 static int rmi_scan_pdt_page(struct rmi_device *rmi_dev,
 			     int page,
-			     int *empty_pages,
+			     struct pdt_scan_state *state,
 			     void *ctx,
 			     int (*callback)(struct rmi_device *rmi_dev,
 					     void *ctx,
 					     const struct pdt_entry *entry))
 {
 	struct rmi_driver_data *data = dev_get_drvdata(&rmi_dev->dev);
 	struct pdt_entry pdt_entry;
 	u16 page_start = RMI4_PAGE_SIZE * page;
@@ -521,44 +547,47 @@ static int rmi_scan_pdt_page(struct rmi_device *rmi_dev,
 	for (addr = pdt_start; addr >= pdt_end; addr -= RMI_PDT_ENTRY_SIZE) {
 		error = rmi_read_pdt_entry(rmi_dev, &pdt_entry, addr);
 		if (error)
 			return error;
 
 		if (RMI4_END_OF_PDT(pdt_entry.function_number))
 			break;
 
+		if (!rmi_pdt_entry_is_valid(rmi_dev, state, pdt_entry.function_number))
+			continue;
+
 		retval = callback(rmi_dev, ctx, &pdt_entry);
 		if (retval != RMI_SCAN_CONTINUE)
 			return retval;
 	}
 
 	/*
 	 * Count number of empty PDT pages. If a gap of two pages
 	 * or more is found, stop scanning.
 	 */
 	if (addr == pdt_start)
-		++*empty_pages;
+		++state->empty_pages;
 	else
-		*empty_pages = 0;
+		state->empty_pages = 0;
 
-	return (data->bootloader_mode || *empty_pages >= 2) ?
+	return (data->bootloader_mode || state->empty_pages >= 2) ?
 					RMI_SCAN_DONE : RMI_SCAN_CONTINUE;
 }
 
 int rmi_scan_pdt(struct rmi_device *rmi_dev, void *ctx,
 		 int (*callback)(struct rmi_device *rmi_dev,
 		 void *ctx, const struct pdt_entry *entry))
 {
 	int page;
-	int empty_pages = 0;
+	struct pdt_scan_state state = {0, 0, {0}};
 	int retval = RMI_SCAN_DONE;
 
 	for (page = 0; page <= RMI4_MAX_PAGE; page++) {
-		retval = rmi_scan_pdt_page(rmi_dev, page, &empty_pages,
+		retval = rmi_scan_pdt_page(rmi_dev, page, &state,
 					   ctx, callback);
 		if (retval != RMI_SCAN_CONTINUE)
 			break;
 	}
 
 	return retval < 0 ? retval : 0;
 }
 
diff --git a/drivers/input/rmi4/rmi_driver.h b/drivers/input/rmi4/rmi_driver.h
index abeafb77a4838..6de8faed08917 100644
--- a/drivers/input/rmi4/rmi_driver.h
+++ b/drivers/input/rmi4/rmi_driver.h
@@ -44,16 +44,23 @@ struct pdt_entry {
 	u8 interrupt_source_count;
 	u8 function_version;
 	u8 function_number;
 };
 
 #define RMI_REG_DESC_PRESENCE_BITS	(32 * BITS_PER_BYTE)
 #define RMI_REG_DESC_PRESENCE_REGS_MAX	(3 + RMI_REG_DESC_PRESENCE_BITS / 8)
 #define RMI_REG_DESC_SUBPACKET_BITS	(37 * BITS_PER_BYTE)
+#define RMI_PDT_MAX 0x55
+
+struct pdt_scan_state {
+	u8 empty_pages;
+	bool pdts[RMI_PDT_MAX + 1];
+};
+
 
 /* describes a single packet register */
 struct rmi_register_desc_item {
 	u32 reg_size;
 	u16 reg;
 	u16 num_subpackets;
 	DECLARE_BITMAP(subpacket_map, RMI_REG_DESC_SUBPACKET_BITS);
 };

-- 
2.53.0

