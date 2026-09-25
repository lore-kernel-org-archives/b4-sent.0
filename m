From: Michael Reeves <michael.reeves077@gmail.com>
Date: Fri, 25 Sep 2026 23:43:41 +1000
Subject: [PATCH 06/13] wifi: brcmfmac: Load signed PCIe firmware images
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-brcm4388-submit-v1-6-b5cbc2cde2fb@gmail.com>
References: <20260925-brcm4388-submit-v1-0-b5cbc2cde2fb@gmail.com>
In-Reply-To: <20260925-brcm4388-submit-v1-0-b5cbc2cde2fb@gmail.com>
To: Arend van Spriel <arend.vanspriel@broadcom.com>, 
 Pieter-Paul Giesberts <pieterpg@broadcom.com>, 
 "Franky Lin (Zhenhui)" <frankyl@broadcom.com>, 
 Mathy Vanhoef <vanhoefm@gmail.com>, Kalle Valo <kvalo@kernel.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-wireless@vger.kernel.org, brcm80211@lists.linux.dev, 
 brcm80211-dev-list.pdl@broadcom.com, asahi@lists.linux.dev, 
 Hector Martin <marcan@marcan.st>, Daniel Berlin <dberlin@dberlin.org>, 
 Janne Grunau <j@jannau.net>, linux-kernel@vger.kernel.org, 
 Hante Meuleman <meuleman@broadcom.com>, linux-hardening@vger.kernel.org, 
 Michael Reeves <michael.reeves077@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790343821; l=15304;
 i=michael.reeves077@gmail.com; s=fedora-20260918; h=from:subject:message-id;
 bh=wHOqU/qvNOb3HEkBRHU3f00di/B3js3jPhlUWu1N82w=;
 b=/s+lCIdYv3CQTucs5miJC7t09ICG2/0N3RkQAsT+GxhHQ4MbWKcvDJWY0WjSW7GoLPMshZ44f
 g8BUW+tcdI6A1fOSbeH8bunnt6EeNBdMNOAL0GQyEoDWdLOJ4H2+Tr8
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=VJ0TvyQ9TvfzYZa908YSE9kpkjFLLD5luv0bERu+boc=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/fedora-20260918 with auth_id=1035
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

Signed PCIe firmware needs a signature and a memory map describing the
image, signature, verification status, and bootloader heap.

Request an optional .sig file and write the signature and reverse-TLV
metadata to device memory. Describe an aligned heap after the firmware
image, keeping the metadata and end footer outside it. Require NVRAM for
signed images and preserve their reset vector.

Request the IRQ before starting firmware on chips that use signatures,
while keeping ring processing disabled until initialization completes.

Signed-off-by: Hector Martin <marcan@marcan.st>
Co-developed-by: Daniel Berlin <dberlin@dberlin.org>
Signed-off-by: Daniel Berlin <dberlin@dberlin.org>
Co-developed-by: Michael Reeves <michael.reeves077@gmail.com>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 .../wireless/broadcom/brcm80211/brcmfmac/pcie.c    | 267 ++++++++++++++++++---
 1 file changed, 233 insertions(+), 34 deletions(-)

diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pcie.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pcie.c
index ad8567e2b9..48402eb2ef 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pcie.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pcie.c
@@ -80,6 +80,7 @@ MODULE_FIRMWARE(BRCMF_FW_DEFAULT_PATH "brcmfmac*-pcie.*.txt");
 /* per-board firmware binaries */
 MODULE_FIRMWARE(BRCMF_FW_DEFAULT_PATH "brcmfmac*-pcie.*.bin");
 MODULE_FIRMWARE(BRCMF_FW_DEFAULT_PATH "brcmfmac*-pcie.*.clm_blob");
+MODULE_FIRMWARE(BRCMF_FW_DEFAULT_PATH "brcmfmac*-pcie.*.sig");
 MODULE_FIRMWARE(BRCMF_FW_DEFAULT_PATH "brcmfmac*-pcie.*.txcap_blob");
 
 static const struct brcmf_firmware_mapping brcmf_pcie_fwnames[] = {
@@ -369,6 +370,9 @@ struct brcmf_pciedev_info {
 	struct brcmf_mp_device *settings;
 	struct brcmf_otp_params otp;
 	bool fwseed;
+	char sig_name[BRCMF_FW_NAME_LEN];
+	u32 fw_size;
+	bool skip_reset_vector;
 #ifdef DEBUG
 	u32 console_interval;
 	bool console_active;
@@ -468,6 +472,7 @@ static void brcmf_pcie_setup(struct device *dev, int ret,
 			     struct brcmf_fw_request *fwreq);
 static struct brcmf_fw_request *
 brcmf_pcie_prepare_fw_request(struct brcmf_pciedev_info *devinfo);
+static bool brcmf_pcie_request_fw_signature(struct brcmf_pciedev_info *devinfo);
 static void
 brcmf_pcie_fwcon_timer(struct brcmf_pciedev_info *devinfo, bool active);
 static void brcmf_pcie_debugfs_create(struct device *dev);
@@ -1828,26 +1833,174 @@ brcmf_pcie_init_share_ram_info(struct brcmf_pciedev_info *devinfo,
 	return 0;
 }
 
-struct brcmf_random_seed_footer {
+struct brcmf_rtlv_footer {
 	__le32 length;
 	__le32 magic;
 };
 
+struct brcmf_fw_memmap_region {
+	__le32 start;
+	__le32 end;
+};
+
+struct brcmf_fw_memmap {
+	struct brcmf_fw_memmap_region reset_vec;
+	struct brcmf_fw_memmap_region int_vec;
+	struct brcmf_fw_memmap_region rom;
+	struct brcmf_fw_memmap_region mmap;
+	struct brcmf_fw_memmap_region vstatus;
+	struct brcmf_fw_memmap_region fw;
+	struct brcmf_fw_memmap_region sig;
+	struct brcmf_fw_memmap_region heap;
+	struct brcmf_fw_memmap_region stack;
+	struct brcmf_fw_memmap_region prng;
+	struct brcmf_fw_memmap_region nvram;
+};
+
+#define BRCMF_BL_HEAP_START_GAP		0x1000
+#define BRCMF_BL_HEAP_SIZE		0x10000
 #define BRCMF_RANDOM_SEED_MAGIC		0xfeedc0de
 #define BRCMF_RANDOM_SEED_LENGTH	0x100
+#define BRCMF_FW_SIG_MAGIC		0xfeedfe51
+#define BRCMF_MEMMAP_MAGIC		0xfeedfe53
+#define BRCMF_VSTATUS_MAGIC		0xfeedfe54
+#define BRCMF_VSTATUS_SIZE		0x28
+#define BRCMF_END_MAGIC			0xfeed0e2d
+
+static int brcmf_pcie_alloc_rtlv(struct brcmf_pciedev_info *devinfo,
+				 u32 *address, u32 type, size_t length)
+{
+	struct brcmf_bus *bus = dev_get_drvdata(&devinfo->pdev->dev);
+	u32 fw_top = devinfo->ci->rambase + devinfo->fw_size;
+	u32 start_addr;
+	u32 length_field;
+	struct brcmf_rtlv_footer footer = {
+		.magic = cpu_to_le32(type),
+	};
+
+	if (length > 0xfffc)
+		return -E2BIG;
+
+	length = ALIGN(length, 4);
+	if (*address < length + sizeof(footer))
+		return -ENOMEM;
+
+	start_addr = *address - length - sizeof(footer);
+	if (start_addr < fw_top) {
+		brcmf_err(bus, "failed to allocate rTLV type 0x%x len 0x%zx\n",
+			  type, length);
+		return -ENOMEM;
+	}
+
+	if (type == BRCMF_RANDOM_SEED_MAGIC)
+		length_field = length;
+	else
+		length_field = length | ((length ^ 0xffff) << 16);
+
+	footer.length = cpu_to_le32(length_field);
+	memcpy_toio(devinfo->tcm + *address - sizeof(footer), &footer,
+		    sizeof(footer));
+	*address = start_addr;
+
+	return 0;
+}
 
-static noinline_for_stack void
-brcmf_pcie_provide_random_bytes(struct brcmf_pciedev_info *devinfo, u32 address)
+static noinline_for_stack int
+brcmf_pcie_add_random_seed(struct brcmf_pciedev_info *devinfo, u32 *address)
 {
 	u8 randbuf[BRCMF_RANDOM_SEED_LENGTH];
+	int err;
+
+	err = brcmf_pcie_alloc_rtlv(devinfo, address,
+				    BRCMF_RANDOM_SEED_MAGIC,
+				    BRCMF_RANDOM_SEED_LENGTH);
+	if (err)
+		return err;
 
+	brcmf_dbg(PCIE, "Download random seed\n");
 	get_random_bytes(randbuf, BRCMF_RANDOM_SEED_LENGTH);
-	memcpy_toio(devinfo->tcm + address, randbuf, BRCMF_RANDOM_SEED_LENGTH);
+	memcpy_toio(devinfo->tcm + *address, randbuf, BRCMF_RANDOM_SEED_LENGTH);
+
+	return 0;
+}
+
+static int brcmf_pcie_add_signature(struct brcmf_pciedev_info *devinfo,
+				    u32 *address,
+				    const struct firmware *fwsig)
+{
+	struct brcmf_fw_memmap memmap = {};
+	u32 sig_start, vstatus_start, fw_end, heap_start, heap_end;
+	int err;
+
+	brcmf_dbg(PCIE, "Download firmware signature\n");
+
+	memmap.sig.end = cpu_to_le32(*address);
+	err = brcmf_pcie_alloc_rtlv(devinfo, address, BRCMF_FW_SIG_MAGIC,
+				    fwsig->size);
+	if (err)
+		return err;
+	sig_start = *address;
+	memmap.sig.start = cpu_to_le32(sig_start);
+
+	memmap.vstatus.end = cpu_to_le32(*address);
+	err = brcmf_pcie_alloc_rtlv(devinfo, address, BRCMF_VSTATUS_MAGIC,
+				    BRCMF_VSTATUS_SIZE);
+	if (err)
+		return err;
+	vstatus_start = *address;
+	memmap.vstatus.start = cpu_to_le32(vstatus_start);
+
+	err = brcmf_pcie_alloc_rtlv(devinfo, address, BRCMF_MEMMAP_MAGIC,
+				    sizeof(memmap));
+	if (err)
+		return err;
+
+	fw_end = devinfo->ci->rambase + devinfo->fw_size;
+	heap_start = ALIGN(fw_end + BRCMF_BL_HEAP_START_GAP, 4);
+	heap_end = heap_start + BRCMF_BL_HEAP_SIZE;
+	if (heap_end > *address ||
+	    *address - heap_end < sizeof(struct brcmf_rtlv_footer))
+		return -ENOMEM;
+
+	memmap.fw.start = cpu_to_le32(devinfo->ci->rambase);
+	memmap.fw.end = cpu_to_le32(fw_end);
+	memmap.heap.start = cpu_to_le32(heap_start);
+	memmap.heap.end = cpu_to_le32(heap_end);
+
+	memcpy_toio(devinfo->tcm + sig_start, fwsig->data, fwsig->size);
+	memset_io(devinfo->tcm + vstatus_start, 0, BRCMF_VSTATUS_SIZE);
+	memcpy_toio(devinfo->tcm + *address, &memmap, sizeof(memmap));
+
+	err = brcmf_pcie_alloc_rtlv(devinfo, address, BRCMF_END_MAGIC, 0);
+	if (err)
+		return err;
+
+	devinfo->skip_reset_vector = true;
+	return 0;
+}
+
+static int brcmf_pcie_populate_footers(struct brcmf_pciedev_info *devinfo,
+				       u32 *address,
+				       const struct firmware *fwsig)
+{
+	int err;
+
+	if (devinfo->fwseed) {
+		err = brcmf_pcie_add_random_seed(devinfo, address);
+		if (err)
+			return err;
+	}
+
+	if (fwsig)
+		return brcmf_pcie_add_signature(devinfo, address, fwsig);
+
+	return 0;
 }
 
 static int brcmf_pcie_download_fw_nvram(struct brcmf_pciedev_info *devinfo,
-					const struct firmware *fw, void *nvram,
-					u32 nvram_len)
+					const struct firmware *fw,
+					const struct firmware *fwsig,
+					void *nvram, u32 nvram_len)
 {
 	struct brcmf_bus *bus = dev_get_drvdata(&devinfo->pdev->dev);
 	u32 sharedram_addr;
@@ -1855,19 +2008,30 @@ static int brcmf_pcie_download_fw_nvram(struct brcmf_pciedev_info *devinfo,
 	u32 loop_counter;
 	int err;
 	u32 address;
+	u32 free_start;
 	u32 resetintr;
 
+	devinfo->skip_reset_vector = false;
+
+	if (fwsig && !nvram) {
+		brcmf_err(bus, "NVRAM required for signed firmware\n");
+		err = -ENOENT;
+		goto fail;
+	}
+
 	brcmf_dbg(PCIE, "Halt ARM.\n");
 	err = brcmf_pcie_enter_download_state(devinfo);
 	if (err)
-		return err;
+		goto fail;
 
 	brcmf_dbg(PCIE, "Download FW %s\n", devinfo->fw_name);
 	memcpy_toio(devinfo->tcm + devinfo->ci->rambase,
 		    (void *)fw->data, fw->size);
 
 	resetintr = get_unaligned_le32(fw->data);
+	devinfo->fw_size = fw->size;
 	release_firmware(fw);
+	fw = NULL;
 
 	/* reset last 4 bytes of RAM address. to be used for shared
 	 * area. This identifies when FW is running
@@ -1880,30 +2044,22 @@ static int brcmf_pcie_download_fw_nvram(struct brcmf_pciedev_info *devinfo,
 			  nvram_len;
 		memcpy_toio(devinfo->tcm + address, nvram, nvram_len);
 		brcmf_fw_nvram_free(nvram);
+		nvram = NULL;
 
-		if (devinfo->fwseed) {
-			size_t rand_len = BRCMF_RANDOM_SEED_LENGTH;
-			struct brcmf_random_seed_footer footer = {
-				.length = cpu_to_le32(rand_len),
-				.magic = cpu_to_le32(BRCMF_RANDOM_SEED_MAGIC),
-			};
-
-			/* Some chips/firmwares expect a buffer of random
-			 * data to be present before NVRAM
-			 */
-			brcmf_dbg(PCIE, "Download random seed\n");
-
-			address -= sizeof(footer);
-			memcpy_toio(devinfo->tcm + address, &footer,
-				    sizeof(footer));
+		err = brcmf_pcie_populate_footers(devinfo, &address, fwsig);
+		if (err)
+			goto fail;
 
-			address -= rand_len;
-			brcmf_pcie_provide_random_bytes(devinfo, address);
-		}
+		free_start = devinfo->ci->rambase + devinfo->fw_size;
+		if ((devinfo->fwseed || fwsig) && address > free_start)
+			memset_io(devinfo->tcm + free_start, 0,
+				  address - free_start);
 	} else {
 		brcmf_dbg(PCIE, "No matching NVRAM file found %s\n",
 			  devinfo->nvram_name);
 	}
+	release_firmware(fwsig);
+	fwsig = NULL;
 
 	sharedram_addr_written = brcmf_pcie_read_ram32(devinfo,
 						       devinfo->ci->ramsize -
@@ -1911,7 +2067,7 @@ static int brcmf_pcie_download_fw_nvram(struct brcmf_pciedev_info *devinfo,
 	brcmf_dbg(PCIE, "Bring ARM in running state\n");
 	err = brcmf_pcie_exit_download_state(devinfo, resetintr);
 	if (err)
-		return err;
+		goto fail;
 
 	brcmf_dbg(PCIE, "Wait for FW init\n");
 	sharedram_addr = sharedram_addr_written;
@@ -1925,17 +2081,25 @@ static int brcmf_pcie_download_fw_nvram(struct brcmf_pciedev_info *devinfo,
 	}
 	if (sharedram_addr == sharedram_addr_written) {
 		brcmf_err(bus, "FW failed to initialize\n");
-		return -ENODEV;
+		err = -ENODEV;
+		goto fail;
 	}
 	if (sharedram_addr < devinfo->ci->rambase ||
 	    sharedram_addr >= devinfo->ci->rambase + devinfo->ci->ramsize) {
 		brcmf_err(bus, "Invalid shared RAM address 0x%08x\n",
 			  sharedram_addr);
-		return -ENODEV;
+		err = -ENODEV;
+		goto fail;
 	}
 	brcmf_dbg(PCIE, "Shared RAM addr: 0x%08x\n", sharedram_addr);
 
 	return (brcmf_pcie_init_share_ram_info(devinfo, sharedram_addr));
+
+fail:
+	release_firmware(fw);
+	release_firmware(fwsig);
+	brcmf_fw_nvram_free(nvram);
+	return err;
 }
 
 
@@ -2061,7 +2225,8 @@ static void brcmf_pcie_buscore_activate(void *ctx, struct brcmf_chip *chip,
 {
 	struct brcmf_pciedev_info *devinfo = (struct brcmf_pciedev_info *)ctx;
 
-	brcmf_pcie_write_tcm32(devinfo, 0, rstvec);
+	if (!devinfo->skip_reset_vector)
+		brcmf_pcie_write_tcm32(devinfo, 0, rstvec);
 }
 
 
@@ -2290,11 +2455,18 @@ static int brcmf_pcie_read_otp(struct brcmf_pciedev_info *devinfo)
 #define BRCMF_PCIE_FW_NVRAM	1
 #define BRCMF_PCIE_FW_CLM	2
 #define BRCMF_PCIE_FW_TXCAP	3
+#define BRCMF_PCIE_FW_SIG	4
+
+static bool brcmf_pcie_request_fw_signature(struct brcmf_pciedev_info *devinfo)
+{
+	return false;
+}
 
 static void brcmf_pcie_setup(struct device *dev, int ret,
 			     struct brcmf_fw_request *fwreq)
 {
 	const struct firmware *fw;
+	const struct firmware *fwsig = NULL;
 	void *nvram;
 	struct brcmf_bus *bus;
 	struct brcmf_pciedev *pcie_bus_dev;
@@ -2313,6 +2485,8 @@ static void brcmf_pcie_setup(struct device *dev, int ret,
 	brcmf_pcie_attach(devinfo);
 
 	fw = fwreq->items[BRCMF_PCIE_FW_CODE].binary;
+	if (fwreq->n_items > BRCMF_PCIE_FW_SIG)
+		fwsig = fwreq->items[BRCMF_PCIE_FW_SIG].binary;
 	nvram = fwreq->items[BRCMF_PCIE_FW_NVRAM].nv_data.data;
 	nvram_len = fwreq->items[BRCMF_PCIE_FW_NVRAM].nv_data.len;
 	devinfo->clm_fw = fwreq->items[BRCMF_PCIE_FW_CLM].binary;
@@ -2323,6 +2497,7 @@ static void brcmf_pcie_setup(struct device *dev, int ret,
 	if (ret) {
 		brcmf_err(bus, "Failed to get RAM info\n");
 		release_firmware(fw);
+		release_firmware(fwsig);
 		brcmf_fw_nvram_free(nvram);
 		goto fail;
 	}
@@ -2334,7 +2509,19 @@ static void brcmf_pcie_setup(struct device *dev, int ret,
 	 */
 	brcmf_pcie_adjust_ramsize(devinfo, (u8 *)fw->data, fw->size);
 
-	ret = brcmf_pcie_download_fw_nvram(devinfo, fw, nvram, nvram_len);
+	if (brcmf_pcie_request_fw_signature(devinfo)) {
+		brcmf_pcie_select_core(devinfo, BCMA_CORE_PCIE2);
+		ret = brcmf_pcie_request_irq(devinfo);
+		if (ret) {
+			release_firmware(fw);
+			release_firmware(fwsig);
+			brcmf_fw_nvram_free(nvram);
+			goto fail;
+		}
+	}
+
+	ret = brcmf_pcie_download_fw_nvram(devinfo, fw, fwsig, nvram,
+					   nvram_len);
 	if (ret)
 		goto fail;
 
@@ -2349,9 +2536,11 @@ static void brcmf_pcie_setup(struct device *dev, int ret,
 		goto fail;
 
 	brcmf_pcie_select_core(devinfo, BCMA_CORE_PCIE2);
-	ret = brcmf_pcie_request_irq(devinfo);
-	if (ret)
-		goto fail;
+	if (!devinfo->irq_allocated) {
+		ret = brcmf_pcie_request_irq(devinfo);
+		if (ret)
+			goto fail;
+	}
 
 	/* hook the commonrings in the bus structure. */
 	for (i = 0; i < BRCMF_NROF_COMMON_MSGRINGS; i++)
@@ -2393,17 +2582,23 @@ static struct brcmf_fw_request *
 brcmf_pcie_prepare_fw_request(struct brcmf_pciedev_info *devinfo)
 {
 	struct brcmf_fw_request *fwreq;
+	u32 n_fwnames;
 	struct brcmf_fw_name fwnames[] = {
 		{ ".bin", devinfo->fw_name },
 		{ ".txt", devinfo->nvram_name },
 		{ ".clm_blob", devinfo->clm_name },
 		{ ".txcap_blob", devinfo->txcap_name },
+		{ ".sig", devinfo->sig_name },
 	};
 
+	n_fwnames = ARRAY_SIZE(fwnames);
+	if (!brcmf_pcie_request_fw_signature(devinfo))
+		n_fwnames--;
+
 	fwreq = brcmf_fw_alloc_request(devinfo->ci->chip, devinfo->ci->chiprev,
 				       brcmf_pcie_fwnames,
 				       ARRAY_SIZE(brcmf_pcie_fwnames),
-				       fwnames, ARRAY_SIZE(fwnames));
+				       fwnames, n_fwnames);
 	if (!fwreq)
 		return NULL;
 
@@ -2414,6 +2609,10 @@ brcmf_pcie_prepare_fw_request(struct brcmf_pciedev_info *devinfo)
 	fwreq->items[BRCMF_PCIE_FW_CLM].flags = BRCMF_FW_REQF_OPTIONAL;
 	fwreq->items[BRCMF_PCIE_FW_TXCAP].type = BRCMF_FW_TYPE_BINARY;
 	fwreq->items[BRCMF_PCIE_FW_TXCAP].flags = BRCMF_FW_REQF_OPTIONAL;
+	if (fwreq->n_items > BRCMF_PCIE_FW_SIG) {
+		fwreq->items[BRCMF_PCIE_FW_SIG].type = BRCMF_FW_TYPE_BINARY;
+		fwreq->items[BRCMF_PCIE_FW_SIG].flags = BRCMF_FW_REQF_OPTIONAL;
+	}
 	/* NVRAM reserves PCI domain 0 for Broadcom's SDK faked bus */
 	fwreq->domain_nr = pci_domain_nr(devinfo->pdev->bus) + 1;
 	fwreq->bus_nr = devinfo->pdev->bus->number;

-- 
2.55.0

