From: Alex Ousherovitch <aousherovitch@rambus.com>
Date: Tue, 10 Nov 2026 08:52:30 -0800
Subject: [PATCH v8 4/5] crypto: cmh - add AES skcipher/aead/cmac
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-cmh-b4-a-v8-v8-4-4cea8ebc1d40@rambus.com>
References: <20261110-cmh-b4-a-v8-v8-0-4cea8ebc1d40@rambus.com>
In-Reply-To: <20261110-cmh-b4-a-v8-v8-0-4cea8ebc1d40@rambus.com>
To: Saravanakrishnan Krishnamoorthy <skrishnamoorthy@rambus.com>, 
 Joel Wittenauer <Joel.Wittenauer@cryptography.com>, 
 Thi Nguyen <thin@rambus.com>, Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: linux-crypto@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Alex Ousherovitch <aousherovitch@rambus.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794329557; l=77695;
 i=aousherovitch@rambus.com; s=20261026; h=from:subject:message-id;
 bh=tmxdScHSf/tKL3igM+ankNf/6oQKqkqUFvbMgOCxMFU=;
 b=moCg/AgSF+z4LTuhT980CMEiSHtyHdFbAHxC9/sPO6w1x9pk4Nal7I94PGwSTr/y6xYxQ9ORm
 C9GF8VTnAmzBYt5zJH/JLKxL/YaYGM0u6k/VW+ef5o/EBGSgdEl+8W2
X-Developer-Key: i=aousherovitch@rambus.com; a=ed25519;
 pk=ECFtTdQUPAolK+qGZ6v7Xm3sRf7rnM7wxpTeFzbqpmA=
X-Endpoint-Received: by B4 Relay for aousherovitch@rambus.com/20261026 with auth_id=1330
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Register AES algorithms on the CMH AES core:
- skcipher: ecb(aes), cbc(aes), ctr(aes), xts(aes)
- aead: gcm(aes), ccm(aes)
- ahash: cmac(aes)

The core does not cover everything the crypto API allows, so some
requests take another path:
- CTR: the core increments only the low 64 bits of the counter.  A
  request that would wrap them is split in two submissions, the second
  with the carry applied, so the result matches ctr(aes).
- CCM: the core rejects a 10-byte tag, so those requests go to a
  ccm(aes) software transform.  With no AAD and no payload the tag is
  two block encryptions, computed on the host with the AES library;
  an empty GCM request runs one block encryption on the device and the
  tag is compared on the host.
- The core reports a GCM/CCM tag mismatch with the same error as its
  other failures, so a failed decrypt returns -EBADMSG.
- The hardware path linearises a request into one DMA buffer;
  skcipher requests over 32 MiB and AEAD requests over 1 MiB (AAD plus
  payload) get -EINVAL.

cmac(aes) runs the one-shot .digest() on the hardware, from a
scatterlist or a virtual address.  The incremental operations and
export/import go to a generic cmac(aes) transform, because the hardware
state cannot be exported in the crypto API format.  The generic
cmac(aes) has no export_core, so the core cannot install it as the
crypto_ahash_fb() fallback; the driver sets CRYPTO_ALG_NO_FALLBACK and
allocates the transform itself.  The hashes and HMAC in a later series
use crypto_ahash_fb() and do not set the flag.

The AES core command definitions (cmh_aes_abi.h) are added here.

Co-developed-by: Saravanakrishnan Krishnamoorthy <skrishnamoorthy@rambus.com>
Signed-off-by: Saravanakrishnan Krishnamoorthy <skrishnamoorthy@rambus.com>
Signed-off-by: Alex Ousherovitch <aousherovitch@rambus.com>
---
 Documentation/crypto/device_drivers/cmh.rst |  26 +
 drivers/crypto/cmh/Kconfig                  |  11 +
 drivers/crypto/cmh/Makefile                 |   5 +-
 drivers/crypto/cmh/cmh_aes.c                | 705 +++++++++++++++++++++
 drivers/crypto/cmh/cmh_aes_aead.c           | 934 ++++++++++++++++++++++++++++
 drivers/crypto/cmh/cmh_aes_cmac.c           | 459 ++++++++++++++
 drivers/crypto/cmh/cmh_main.c               |  27 +
 drivers/crypto/cmh/include/cmh_aes.h        |  24 +
 drivers/crypto/cmh/include/cmh_aes_abi.h    |  98 +++
 drivers/crypto/cmh/include/cmh_vcq.h        |   2 +
 10 files changed, 2290 insertions(+), 1 deletion(-)

diff --git a/Documentation/crypto/device_drivers/cmh.rst b/Documentation/crypto/device_drivers/cmh.rst
index ddc44d235541..432c2d12b080 100644
--- a/Documentation/crypto/device_drivers/cmh.rst
+++ b/Documentation/crypto/device_drivers/cmh.rst
@@ -54,6 +54,11 @@ sizes, and curves within each family are those of the underlying CMH
 device; the CMH host-API documentation is authoritative for the
 supported set on a given CMH configuration.
 
+AES
+  skcipher: ECB, CBC, CTR, XTS;
+  AEAD: GCM, CCM;
+  ahash: CMAC(AES)
+
 All algorithm driver names use the ``rambus-cmh-`` prefix (e.g.
 ``rambus-cmh-ecb-aes``, ``rambus-cmh-gcm-aes``).  Names generally follow
 the kernel's hyphenated template name; families that have no kernel
@@ -68,6 +73,10 @@ recently registered one is chosen, so the result depends on load order.
 Callers that require this hardware should allocate by driver name, and
 can check the driver name of an allocated transform.
 
+AES-CCM registers at 301, so that a generic ``ccm_base`` instance built
+from the driver's ``ctr(aes)`` and the AES library's CBC-MAC (both at
+300) cannot shadow it.
+
 Request model
 -------------
 
@@ -117,6 +126,10 @@ The final status is 0 or a negative errno:
 ``-ENOMEM``
   A bounce buffer could not be allocated.
 
+The AES core reports an authentication failure with the same error code
+as its other failures, so an AES-GCM or AES-CCM decryption that fails in
+the device for another reason also returns ``-EBADMSG``.
+
 Driver Architecture
 ===================
 
@@ -270,6 +283,11 @@ with ``-EINVAL``; it is not passed to a software implementation.  Below
 a cap a large request can still fail with ``-ENOMEM`` when the bounce
 buffers cannot be allocated, in particular for ``GFP_ATOMIC`` requests.
 
+- AES skcipher: 32 MiB of data.
+- AES-GCM and AES-CCM: 1 MiB of associated data plus payload.  AES-CCM
+  with a 10-byte tag, which the hardware does not support, is passed
+  whole to the generic implementation and has no such limit.
+
 MAC and hash algorithms offload the one-shot ``.digest()`` only.  The
 hardware's intermediate state is a non-portable internal checkpoint, and
 the keyed MACs cannot save it at all, so the incremental operations
@@ -280,3 +298,11 @@ whole message into one DMA buffer and rejects an input larger than
 the software transform has no such limit.  For keyed algorithms the key
 is programmed into both the hardware and the software transform on
 ``.setkey()``.
+
+``cmac(aes)`` cannot use the Crypto API's automatic fallback, because
+the generic cmac ``crypto_shash`` does not implement ``export_core``: the
+driver allocates and keys a generic software transform itself (and sets
+``CRYPTO_ALG_NO_FALLBACK``).  It accepts virtual-address requests
+(``CRYPTO_ALG_REQ_VIRT``): ``.digest()`` offloads them like scatterlist
+requests, and the incremental operations forward them to the software
+transform.
diff --git a/drivers/crypto/cmh/Kconfig b/drivers/crypto/cmh/Kconfig
index 861fe31ec5fb..fb47e0960f90 100644
--- a/drivers/crypto/cmh/Kconfig
+++ b/drivers/crypto/cmh/Kconfig
@@ -13,6 +13,17 @@ config CRYPTO_DEV_CMH
 	tristate "Rambus CryptoManager Hub (CMH) hardware crypto accelerator"
 	depends on CRYPTO && OF && HAS_IOMEM && (64BIT || COMPILE_TEST)
 	depends on !CPU_BIG_ENDIAN
+	select CRYPTO_SKCIPHER
+	select CRYPTO_AEAD
+	select CRYPTO_HASH
+	# The AES library computes the empty-input CCM tag; the drivers
+	# allocate ccm(aes) for the CCM requests the hardware does not
+	# support, and cmac(aes) for the incremental (.update) and
+	# request-state export/import CMAC operations.
+	select CRYPTO_LIB_AES
+	select CRYPTO_AES
+	select CRYPTO_CCM
+	select CRYPTO_CMAC
 	help
 	  Driver for the Rambus CryptoManager Hub (CMH) hardware crypto
 	  accelerator.  The device is accessed through a mailbox-based VCQ
diff --git a/drivers/crypto/cmh/Makefile b/drivers/crypto/cmh/Makefile
index 485247405cb2..6f47afd004f1 100644
--- a/drivers/crypto/cmh/Makefile
+++ b/drivers/crypto/cmh/Makefile
@@ -14,7 +14,10 @@ cmh-y := \
 	cmh_dma.o \
 	cmh_sysfs.o \
 	cmh_sys.o \
-	cmh_key.o
+	cmh_key.o \
+	cmh_aes.o \
+	cmh_aes_aead.o \
+	cmh_aes_cmac.o
 
 ccflags-y += -I$(src)/include
 
diff --git a/drivers/crypto/cmh/cmh_aes.c b/drivers/crypto/cmh/cmh_aes.c
new file mode 100644
index 000000000000..5ba67ccd5a06
--- /dev/null
+++ b/drivers/crypto/cmh/cmh_aes.c
@@ -0,0 +1,705 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- Kernel Crypto API AES (skcipher) Driver
+ *
+ * Registers skcipher algorithms with the Linux crypto subsystem:
+ *   ecb(aes), cbc(aes), ctr(aes), xts(aes)
+ *
+ * Uses the CMH AES Core via VCQ commands:
+ *   [SYS_CMD_WRITE] + AES_CMD_INIT + [AES_CMD_UPDATE] + AES_CMD_FINAL
+ *   + VCQ_CMD_FLUSH
+ *
+ * The AES core requires bidirectional DMA -- both input and output
+ * buffers are mapped and passed in a single AES_CMD_FINAL command.
+ *
+ * Raw-key atomicity: SYS_CMD_WRITE to SYS_REF_TEMP is packed into
+ * the same VCQ as AES commands (see cmh_key.h for details).
+ *
+ */
+
+#include <linux/module.h>
+#include <linux/kernel.h>
+#include <linux/crypto.h>
+#include <crypto/internal/skcipher.h>
+#include <crypto/aes.h>
+#include <crypto/algapi.h>
+#include <crypto/xts.h>
+#include <crypto/scatterwalk.h>
+#include <linux/scatterlist.h>
+#include <linux/slab.h>
+#include <linux/string.h>
+#include <linux/unaligned.h>
+
+#include "cmh_aes.h"
+#include "cmh_vcq.h"
+#include "cmh_aes_abi.h"
+#include "cmh_sys_abi.h"
+#include "cmh_sys.h"
+#include "cmh_txn.h"
+#include "cmh_dma.h"
+#include "cmh_key.h"
+
+/* Algorithm Table */
+
+struct cmh_aes_alg_info {
+	u32         aes_mode;	/* AES_MODE_* */
+	u32         ivsize;		/* bytes (0 for ECB) */
+	u32         min_keysize;	/* minimum key bytes */
+	u32         max_keysize;	/* maximum key bytes */
+	const char *alg_name;	/* Linux crypto name: "ecb(aes)" */
+	const char *drv_name;	/* driver name: "rambus-cmh-ecb-aes" */
+};
+
+static const struct cmh_aes_alg_info aes_algs[] = {
+	{ AES_MODE_ECB, 0,                AES_KEYSIZE_128, AES_KEYSIZE_256,
+	  "ecb(aes)", "rambus-cmh-ecb-aes" },
+	{ AES_MODE_CBC, CMH_AES_IV_SIZE,  AES_KEYSIZE_128, AES_KEYSIZE_256,
+	  "cbc(aes)", "rambus-cmh-cbc-aes" },
+	{ AES_MODE_CTR, CMH_AES_IV_SIZE,  AES_KEYSIZE_128, AES_KEYSIZE_256,
+	  "ctr(aes)", "rambus-cmh-ctr-aes" },
+	{ AES_MODE_XTS, CMH_AES_IV_SIZE,  2 * AES_KEYSIZE_128, 2 * AES_KEYSIZE_256,
+	  "xts(aes)", "rambus-cmh-xts-aes" },
+};
+
+/* Per-transform context (allocated by crypto framework) */
+
+struct cmh_aes_tfm_ctx {
+	struct cmh_key_ctx key;
+};
+
+/* Per-request context (lives in skcipher_request::__ctx) */
+
+/*
+ * Maximum payload commands:
+ *   [SYS_CMD_WRITE] + AES_CMD_INIT + [AES_CMD_UPDATE] + AES_CMD_FINAL
+ *   + VCQ_CMD_FLUSH = 5
+ * UPDATE is used for XTS data > 2 blocks (see cmh_aes_crypt).
+ */
+#define CMH_AES_MAX_PAYLOAD	5
+#define CMH_AES_MAX_PACKED	(CMH_AES_MAX_PAYLOAD * 2)
+
+struct cmh_aes_reqctx {
+	dma_addr_t in_dma;
+	dma_addr_t out_dma;
+	dma_addr_t iv_dma;
+	dma_addr_t iv2_dma;
+	dma_addr_t key_dma;
+	u8 *in_buf;
+	u8 *out_buf;
+	u8 *iv_buf;
+	u32 cryptlen;
+	u32 ivsize;
+	u32 keylen;
+	u32 aes_mode;
+	u32 aes_op;
+	/* CTR counter-wrap split state */
+	u32 ctr_chunk1_len;
+	/* Set on the chunk-2 leg so its backlog -EINPROGRESS is suppressed. */
+	bool reported_inprogress;
+	u32 core_id;
+	s32 target_mbx;
+	u64 key_ref;
+	struct cmh_req_dma rdma;
+	struct vcq_cmd packed[CMH_AES_MAX_PACKED];
+};
+
+/* VCQ Builders -- AES-specific */
+
+static void vcq_add_aes_init(struct vcq_cmd *slot, u32 core_id, u64 key_ref, u64 iv_dma,
+			     u32 keylen, u32 ivlen, u32 mode, u32 op,
+			     u32 iolen)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(core_id, 0, 1, AES_CMD_INIT);
+	slot->hwc.aes.cmd_init.key = key_ref;
+	slot->hwc.aes.cmd_init.iv = iv_dma;
+	slot->hwc.aes.cmd_init.keylen = keylen;
+	slot->hwc.aes.cmd_init.ivlen = ivlen;
+	slot->hwc.aes.cmd_init.mode = mode;
+	slot->hwc.aes.cmd_init.op = op;
+	slot->hwc.aes.cmd_init.aadlen = 0;
+	slot->hwc.aes.cmd_init.iolen = iolen;
+	slot->hwc.aes.cmd_init.taglen = 0;
+}
+
+static void vcq_add_aes_update(struct vcq_cmd *slot, u32 core_id, u64 input_dma,
+			       u64 output_dma, u32 iolen)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(core_id, 0, 1, AES_CMD_UPDATE);
+	slot->hwc.aes.cmd_update.input = input_dma;
+	slot->hwc.aes.cmd_update.output = output_dma;
+	slot->hwc.aes.cmd_update.iolen = iolen;
+}
+
+static void vcq_add_aes_final(struct vcq_cmd *slot, u32 core_id, u64 input_dma,
+			      u64 output_dma, u32 iolen)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(core_id, 0, 1, AES_CMD_FINAL);
+	slot->hwc.aes.cmd_final.input = input_dma;
+	slot->hwc.aes.cmd_final.output = output_dma;
+	slot->hwc.aes.cmd_final.iolen = iolen;
+	slot->hwc.aes.cmd_final.tag = 0;
+	slot->hwc.aes.cmd_final.taglen = 0;
+}
+
+/*
+ * We wrap each skcipher_alg with its info pointer in a compound struct,
+ * then use container_of() in cmh_aes_get_info() to recover it.
+ * This is the same pattern used by hash, hmac, cmac.
+ */
+struct cmh_aes_alg_drv {
+	struct skcipher_alg             alg;
+	const struct cmh_aes_alg_info  *info;
+};
+
+static bool aes_is_stream_mode(u32 mode)
+{
+	return mode == AES_MODE_CTR;
+}
+
+/*
+ * Update req->iv after a successful encrypt/decrypt.
+ *
+ * The Linux skcipher API contract requires that req->iv is updated to
+ * reflect the state needed to continue processing in a chained call:
+ *   CBC encrypt: IV <- last ciphertext block
+ *   CBC decrypt: IV <- last ciphertext block of the *input*
+ *   CTR:         IV <- counter incremented by ceil(cryptlen / blocksize)
+ */
+static void cmh_aes_update_iv(struct skcipher_request *req, u32 mode,
+			      u32 op, const u8 *in_buf, const u8 *out_buf)
+{
+	u32 bs = CMH_AES_BLOCK_SIZE;
+	u32 nblocks;
+
+	switch (mode) {
+	case AES_MODE_CBC:
+		if (op == AES_OP_ENCRYPT)
+			memcpy(req->iv, out_buf + req->cryptlen - bs, bs);
+		else
+			memcpy(req->iv, in_buf + req->cryptlen - bs, bs);
+		break;
+	case AES_MODE_CTR:
+		/*
+		 * Arithmetic big-endian 128-bit counter increment.
+		 * Process from the least-significant byte (index 15)
+		 * upward, carrying as needed.
+		 */
+		nblocks = DIV_ROUND_UP(req->cryptlen, bs);
+		{
+			u8 *iv = req->iv;
+			int i;
+
+			for (i = bs - 1; i >= 0 && nblocks; i--) {
+				u32 sum = (u32)iv[i] + (nblocks & 0xff);
+
+				iv[i] = (u8)sum;
+				nblocks = (nblocks >> 8) + (sum >> 8);
+			}
+		}
+		break;
+	default:
+		break;
+	}
+}
+
+/* skcipher Operations */
+
+static const struct cmh_aes_alg_info *
+cmh_aes_get_info(struct crypto_skcipher *tfm)
+{
+	struct skcipher_alg *alg = crypto_skcipher_alg(tfm);
+
+	return container_of(alg, struct cmh_aes_alg_drv, alg)->info;
+}
+
+static int cmh_aes_setkey(struct crypto_skcipher *tfm, const u8 *key,
+			  unsigned int keylen)
+{
+	struct cmh_aes_tfm_ctx *tctx = crypto_skcipher_ctx(tfm);
+	const struct cmh_aes_alg_info *info = cmh_aes_get_info(tfm);
+
+	if (info->aes_mode == AES_MODE_XTS) {
+		int err;
+
+		/* XTS: double key (32, 48, or 64 bytes) */
+		if (keylen != 2 * AES_KEYSIZE_128 &&
+		    keylen != 2 * AES_KEYSIZE_192 &&
+		    keylen != 2 * AES_KEYSIZE_256)
+			return -EINVAL;
+		err = xts_verify_key(tfm, key, keylen);
+		if (err)
+			return err;
+	} else {
+		/* Standard: 16, 24, or 32 bytes */
+		if (keylen != AES_KEYSIZE_128 &&
+		    keylen != AES_KEYSIZE_192 &&
+		    keylen != AES_KEYSIZE_256)
+			return -EINVAL;
+	}
+
+	return cmh_key_setkey_raw(&tctx->key, key, keylen, CORE_ID_AES);
+}
+
+static int cmh_aes_init_tfm(struct crypto_skcipher *tfm)
+{
+	struct cmh_aes_tfm_ctx *tctx = crypto_skcipher_ctx(tfm);
+
+	memset(tctx, 0, sizeof(*tctx));
+	crypto_skcipher_set_reqsize(tfm, sizeof(struct cmh_aes_reqctx));
+	return 0;
+}
+
+static void cmh_aes_exit_tfm(struct crypto_skcipher *tfm)
+{
+	struct cmh_aes_tfm_ctx *tctx = crypto_skcipher_ctx(tfm);
+
+	cmh_key_destroy(&tctx->key);
+}
+
+#define CMH_AES_MAX_CRYPTLEN	SZ_32M
+
+/*
+ * Submit the second CTR chunk after the first completes.
+ * Called from cmh_aes_complete when ctr_chunk1_len > 0.
+ */
+static void cmh_aes_complete(void *data, int error);
+
+static int cmh_aes_ctr_submit_chunk2(struct skcipher_request *req)
+{
+	struct crypto_skcipher *tfm = crypto_skcipher_reqtfm(req);
+	struct cmh_aes_tfm_ctx *tctx = crypto_skcipher_ctx(tfm);
+	struct cmh_aes_reqctx *rctx = skcipher_request_ctx(req);
+	struct vcq_cmd cmds[CMH_AES_MAX_PAYLOAD];
+	u32 chunk1 = rctx->ctr_chunk1_len;
+	u32 chunk2 = rctx->cryptlen - chunk1;
+	u64 key_ref;
+	u32 keylen;
+	u32 idx = 0;
+
+	/* Clear split flag so next completion is final */
+	rctx->ctr_chunk1_len = 0;
+	rctx->reported_inprogress = true;
+
+	vcq_add_sys_write(&cmds[idx++], SYS_REF_TEMP,
+			  (u64)rctx->key_dma, SYS_REF_NONE,
+			  tctx->key.raw.len,
+			  tctx->key.raw.sys_type);
+	key_ref = SYS_REF_TEMP;
+	keylen = tctx->key.raw.len;
+
+	vcq_add_aes_init(&cmds[idx++], rctx->core_id, key_ref,
+			 (u64)rctx->iv2_dma, keylen, rctx->ivsize,
+			 rctx->aes_mode, rctx->aes_op, 0);
+	vcq_add_aes_final(&cmds[idx++], rctx->core_id,
+			  (u64)(rctx->in_dma + chunk1),
+			  (u64)(rctx->out_dma + chunk1), chunk2);
+	vcq_add_flush(&cmds[idx++], rctx->core_id);
+
+	return cmh_vcq_pack_and_submit_async(cmds, idx, rctx->packed,
+					     CMH_AES_MAX_PACKED,
+					     rctx->target_mbx,
+					     cmh_aes_complete, req,
+					     &rctx->rdma,
+					     /*
+					      * The request was already accepted:
+					      * backlog the second half rather than
+					      * fail it on a full queue.  Its
+					      * -EINPROGRESS is not reported again.
+					      */
+					     true,
+					     cmh_tm_async_timeout_jiffies());
+}
+
+/*
+ * Async completion callback -- fires from RH threaded IRQ context.
+ *
+ * Unmaps the request DMA set, copies output to req->dst scatterlist,
+ * updates the IV state, frees the set, and completes the request.
+ *
+ * For CTR counter-wrap splits, the first chunk completion chains
+ * into a second VCQ submission rather than finalizing immediately.
+ */
+static void cmh_aes_complete(void *data, int error)
+{
+	struct skcipher_request *req = data;
+	struct cmh_aes_reqctx *rctx = skcipher_request_ctx(req);
+
+	if (error == -EINPROGRESS) {
+		/*
+		 * One in-progress notification per request: a chunk-2 backlog
+		 * must not re-notify an already-in-progress request.
+		 */
+		if (!rctx->reported_inprogress)
+			cmh_complete(&req->base, error);
+		return;
+	}
+
+	/*
+	 * CTR counter-wrap: first chunk completed, submit second.
+	 * DMA mappings remain valid (they cover the full buffer) and the
+	 * second submission carries the same request DMA set.
+	 *
+	 * Recursion depth bounded: chunk2 clears ctr_chunk1_len before
+	 * submission, so the second cmh_aes_complete invocation sees 0
+	 * and finalizes (max depth = 2).
+	 */
+	if (rctx->ctr_chunk1_len && !error) {
+		int ret;
+
+		ret = cmh_aes_ctr_submit_chunk2(req);
+
+		if (!ret || ret == -EBUSY)
+			return;
+		/* Submission failed; clean up below */
+		error = ret;
+	}
+
+	cmh_req_dma_unmap(&rctx->rdma);
+
+	if (!error) {
+		scatterwalk_map_and_copy(rctx->out_buf, req->dst,
+					 0, rctx->cryptlen, 1);
+		cmh_aes_update_iv(req, rctx->aes_mode, rctx->aes_op,
+				  rctx->in_buf, rctx->out_buf);
+	}
+
+	cmh_req_dma_free(&rctx->rdma);
+	cmh_complete(&req->base, error);
+}
+
+/*
+ * Core encrypt/decrypt -- builds a VCQ transaction and submits async.
+ *
+ * Returns -EINPROGRESS on successful submission (completion callback
+ * will fire later).  Returns 0 for trivial cases (zero-length).
+ * Returns negative errno on pre-submission errors.
+ */
+static int cmh_aes_crypt(struct skcipher_request *req, u32 aes_op)
+{
+	struct crypto_skcipher *tfm = crypto_skcipher_reqtfm(req);
+	struct cmh_aes_tfm_ctx *tctx = crypto_skcipher_ctx(tfm);
+	const struct cmh_aes_alg_info *info = cmh_aes_get_info(tfm);
+	struct cmh_aes_reqctx *rctx = skcipher_request_ctx(req);
+	struct vcq_cmd cmds[CMH_AES_MAX_PAYLOAD];
+	u64 key_ref;
+	u32 keylen;
+	struct core_dispatch d;
+	s32 target_mbx;
+	u32 core_id;
+	u32 idx;
+	int ret;
+	gfp_t gfp;
+
+	if (tctx->key.mode == CMH_KEY_NONE)
+		return -ENOKEY;
+
+	if (req->cryptlen > CMH_AES_MAX_CRYPTLEN)
+		return -EINVAL;
+
+	switch (info->aes_mode) {
+	case AES_MODE_CTR:
+		break;
+	case AES_MODE_XTS:
+		if (req->cryptlen < CMH_AES_BLOCK_SIZE)
+			return -EINVAL;
+		break;
+	default:
+		if (req->cryptlen & (CMH_AES_BLOCK_SIZE - 1))
+			return -EINVAL;
+		break;
+	}
+
+	/* After the mode checks: XTS rejects an empty request. */
+	if (!req->cryptlen)
+		return 0;
+
+	gfp = req->base.flags & CRYPTO_TFM_REQ_MAY_SLEEP ?
+	      GFP_KERNEL : GFP_ATOMIC;
+
+	/* Initialise reqctx */
+	memset(rctx, 0, sizeof(*rctx));
+	rctx->cryptlen = req->cryptlen;
+	rctx->ivsize = info->ivsize;
+	rctx->aes_mode = info->aes_mode;
+	rctx->aes_op = aes_op;
+	cmh_req_dma_init(&rctx->rdma);
+
+	/*
+	 * Linearise input from scatterlist.  cryptlen is user-controlled up
+	 * to CMH_AES_MAX_CRYPTLEN (well above KMALLOC_MAX_SIZE), so use
+	 * __GFP_NOWARN: an oversized request fails cleanly with -ENOMEM
+	 * instead of splatting the page allocator.
+	 */
+	rctx->in_buf = kmalloc(req->cryptlen, gfp | __GFP_NOWARN);
+	if (!rctx->in_buf)
+		return -ENOMEM;
+
+	scatterwalk_map_and_copy(rctx->in_buf, req->src, 0, req->cryptlen, 0);
+
+	rctx->in_dma = cmh_req_dma_add(&rctx->rdma, rctx->in_buf,
+				       req->cryptlen, DMA_TO_DEVICE, true);
+	if (cmh_dma_map_error(rctx->in_dma)) {
+		ret = -ENOMEM;
+		goto out_release;
+	}
+
+	/* Allocate and map output buffer */
+	rctx->out_buf = kmalloc(req->cryptlen, gfp | __GFP_NOWARN);
+	if (!rctx->out_buf) {
+		ret = -ENOMEM;
+		goto out_release;
+	}
+
+	rctx->out_dma = cmh_req_dma_add(&rctx->rdma, rctx->out_buf,
+					req->cryptlen, DMA_FROM_DEVICE, true);
+	if (cmh_dma_map_error(rctx->out_dma)) {
+		ret = -ENOMEM;
+		goto out_release;
+	}
+
+	/* Map IV if required */
+	if (info->ivsize > 0) {
+		rctx->iv_buf = kmemdup(req->iv, info->ivsize, gfp);
+		if (!rctx->iv_buf) {
+			ret = -ENOMEM;
+			goto out_release;
+		}
+		rctx->iv_dma = cmh_req_dma_add(&rctx->rdma, rctx->iv_buf,
+					       info->ivsize, DMA_TO_DEVICE,
+					       false);
+		if (cmh_dma_map_error(rctx->iv_dma)) {
+			ret = -ENOMEM;
+			goto out_release;
+		}
+	}
+
+	/* Resolve key reference */
+	idx = 0;
+
+	rctx->key_dma = tctx->key.raw.dma;
+	rctx->keylen = tctx->key.raw.len;
+	vcq_add_sys_write(&cmds[idx++], SYS_REF_TEMP,
+			  (u64)rctx->key_dma, SYS_REF_NONE,
+			  tctx->key.raw.len,
+			  tctx->key.raw.sys_type);
+	key_ref = SYS_REF_TEMP;
+	keylen = tctx->key.raw.len;
+	d = cmh_core_select_instance(CMH_CORE_AES);
+	target_mbx = d.mbx_idx;
+	core_id = d.core_id;
+
+	/*
+	 * iolen in INIT: XTS needs total length upfront for tweak
+	 * computation; all other modes use 0 (streaming).
+	 */
+	vcq_add_aes_init(&cmds[idx++], core_id, key_ref, (u64)rctx->iv_dma,
+			 keylen, info->ivsize, info->aes_mode, aes_op,
+			 info->aes_mode == AES_MODE_XTS ?
+			 req->cryptlen : 0);
+
+	if (info->aes_mode == AES_MODE_XTS &&
+	    req->cryptlen > 2 * CMH_AES_BLOCK_SIZE) {
+		u32 final_len, update_len;
+
+		if (req->cryptlen & (CMH_AES_BLOCK_SIZE - 1))
+			final_len = CMH_AES_BLOCK_SIZE +
+				    (req->cryptlen & (CMH_AES_BLOCK_SIZE - 1));
+		else
+			final_len = 2 * CMH_AES_BLOCK_SIZE;
+
+		update_len = req->cryptlen - final_len;
+
+		vcq_add_aes_update(&cmds[idx++], core_id,
+				   (u64)rctx->in_dma,
+				   (u64)rctx->out_dma, update_len);
+		vcq_add_aes_final(&cmds[idx++], core_id,
+				  (u64)(rctx->in_dma + update_len),
+				  (u64)(rctx->out_dma + update_len),
+				  final_len);
+	} else if (info->aes_mode == AES_MODE_CTR) {
+		/*
+		 * CTR counter-wrap workaround:
+		 * The AES-SCA hardware uses a 64-bit block counter.
+		 * If the lower 64 bits of the IV would wrap during
+		 * this operation, split into two separate VCQ
+		 * transactions -- the completion callback for the
+		 * first chunk submits the second.
+		 */
+		u64 lower64 = get_unaligned_be64(rctx->iv_buf + 8);
+		u32 nblocks = DIV_ROUND_UP(req->cryptlen,
+					  CMH_AES_BLOCK_SIZE);
+		u64 bwrap = lower64 ? (~lower64 + 1ULL) : U64_MAX;
+
+		if (nblocks > bwrap) {
+			u32 chunk1 = (u32)bwrap * CMH_AES_BLOCK_SIZE;
+			u64 upper64;
+			u8 *iv2;
+
+			/* Prepare second IV for chained submission */
+			iv2 = kmalloc(info->ivsize, gfp);
+			if (!iv2) {
+				ret = -ENOMEM;
+				goto out_release;
+			}
+			upper64 = get_unaligned_be64(rctx->iv_buf);
+			put_unaligned_be64(upper64 + 1, iv2);
+			put_unaligned_be64(0, iv2 + 8);
+
+			rctx->iv2_dma = cmh_req_dma_add(&rctx->rdma, iv2,
+							info->ivsize,
+							DMA_TO_DEVICE, false);
+			if (cmh_dma_map_error(rctx->iv2_dma)) {
+				ret = -ENOMEM;
+				goto out_release;
+			}
+
+			/* Store state for the chained second submission */
+			rctx->ctr_chunk1_len = chunk1;
+			rctx->core_id = core_id;
+			rctx->target_mbx = target_mbx;
+			rctx->key_ref = key_ref;
+
+			/* First transaction: only chunk1 */
+			vcq_add_aes_final(&cmds[idx++], core_id,
+					  (u64)rctx->in_dma,
+					  (u64)rctx->out_dma, chunk1);
+		} else {
+			/* No wrap: single FINAL with all data */
+			vcq_add_aes_final(&cmds[idx++], core_id,
+					  (u64)rctx->in_dma,
+					  (u64)rctx->out_dma,
+					  req->cryptlen);
+		}
+	} else {
+		vcq_add_aes_final(&cmds[idx++], core_id,
+				  (u64)rctx->in_dma,
+				  (u64)rctx->out_dma, req->cryptlen);
+	}
+
+	vcq_add_flush(&cmds[idx++], core_id);
+
+	ret = cmh_vcq_pack_and_submit_async(cmds, idx, rctx->packed,
+					    CMH_AES_MAX_PACKED, target_mbx,
+					    cmh_aes_complete, req,
+					    &rctx->rdma,
+					    !!(req->base.flags &
+					       CRYPTO_TFM_REQ_MAY_BACKLOG),
+					    cmh_tm_async_timeout_jiffies());
+	if (ret == -EBUSY)
+		return -EBUSY;
+	if (ret)
+		goto out_release;
+
+	return -EINPROGRESS;
+
+out_release:
+	cmh_req_dma_release(&rctx->rdma);
+	return ret;
+}
+
+static int cmh_aes_encrypt(struct skcipher_request *req)
+{
+	return cmh_aes_crypt(req, AES_OP_ENCRYPT);
+}
+
+static int cmh_aes_decrypt(struct skcipher_request *req)
+{
+	return cmh_aes_crypt(req, AES_OP_DECRYPT);
+}
+
+/* Registration */
+
+static struct cmh_aes_alg_drv aes_drv_algs[ARRAY_SIZE(aes_algs)];
+
+/**
+ * cmh_aes_register() - Register AES-CBC/CTR/ECB/XTS skcipher algorithms with the crypto framework
+ *
+ * Return: 0 on success, negative errno on failure.
+ */
+int cmh_aes_register(void)
+{
+	unsigned int i;
+	int ret;
+
+	if (!cmh_core_present(CMH_CORE_AES))
+		return 0;
+
+	for (i = 0; i < ARRAY_SIZE(aes_algs); i++) {
+		const struct cmh_aes_alg_info *info = &aes_algs[i];
+		struct cmh_aes_alg_drv *drv = &aes_drv_algs[i];
+		struct skcipher_alg *alg = &drv->alg;
+
+		drv->info = info;
+
+		memset(alg, 0, sizeof(*alg));
+
+		alg->setkey      = cmh_aes_setkey;
+		alg->encrypt     = cmh_aes_encrypt;
+		alg->decrypt     = cmh_aes_decrypt;
+		alg->init        = cmh_aes_init_tfm;
+		alg->exit        = cmh_aes_exit_tfm;
+		alg->min_keysize = info->min_keysize;
+		alg->max_keysize = info->max_keysize;
+		alg->ivsize      = info->ivsize;
+
+		strscpy(alg->base.cra_name, info->alg_name,
+			CRYPTO_MAX_ALG_NAME);
+		strscpy(alg->base.cra_driver_name, info->drv_name,
+			CRYPTO_MAX_ALG_NAME);
+		alg->base.cra_priority  = 300;
+		alg->base.cra_flags     = CRYPTO_ALG_KERN_DRIVER_ONLY |
+					  CRYPTO_ALG_ALLOCATES_MEMORY |
+					  CRYPTO_ALG_ASYNC;
+		alg->base.cra_blocksize = aes_is_stream_mode(info->aes_mode)
+					  ? 1 : CMH_AES_BLOCK_SIZE;
+		/*
+		 * CTR uses cra_blocksize=1 but consumes a full cipher
+		 * block per counter step; declare
+		 * chunksize so the crypto layer buffers sub-block data instead
+		 * of splitting the keystream across requests.
+		 */
+		if (aes_is_stream_mode(info->aes_mode))
+			alg->chunksize = CMH_AES_BLOCK_SIZE;
+		alg->base.cra_ctxsize  = sizeof(struct cmh_aes_tfm_ctx);
+		alg->base.cra_module   = THIS_MODULE;
+
+		ret = crypto_register_skcipher(alg);
+		if (ret) {
+			dev_err(cmh_dev(), "cmh_aes: failed to register %s (rc=%d)\n",
+				info->alg_name, ret);
+			goto err_unregister;
+		}
+
+		dev_dbg(cmh_dev(), "cmh_aes: registered %s\n", info->alg_name);
+	}
+
+	return 0;
+
+err_unregister:
+	while (i--)
+		crypto_unregister_skcipher(&aes_drv_algs[i].alg);
+	return ret;
+}
+
+/**
+ * cmh_aes_unregister() - Unregister AES skcipher algorithms from the crypto framework
+ */
+void cmh_aes_unregister(void)
+{
+	unsigned int i;
+
+	if (!cmh_core_present(CMH_CORE_AES))
+		return;
+
+	for (i = 0; i < ARRAY_SIZE(aes_algs); i++) {
+		crypto_unregister_skcipher(&aes_drv_algs[i].alg);
+		dev_dbg(cmh_dev(), "cmh_aes: unregistered %s\n", aes_algs[i].alg_name);
+	}
+}
diff --git a/drivers/crypto/cmh/cmh_aes_aead.c b/drivers/crypto/cmh/cmh_aes_aead.c
new file mode 100644
index 000000000000..7edacf38198b
--- /dev/null
+++ b/drivers/crypto/cmh/cmh_aes_aead.c
@@ -0,0 +1,934 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- Kernel Crypto API AES AEAD Driver (GCM/CCM)
+ *
+ * Registers AEAD algorithms with the Linux crypto subsystem:
+ *   gcm(aes), ccm(aes)
+ *
+ * GCM: AES_CMD_INIT(mode=GCM) + [AAD_FINAL] + AES_CMD_FINAL + FLUSH
+ *   - Standard 12-byte IV (nonce), 16-byte tag
+ *   - AES_CMD_INIT carries aadlen/iolen/taglen
+ *   - AES_CMD_FINAL carries tag DMA for encrypt (produce) / decrypt (verify)
+ *
+ * CCM: AES_CMD_CCM_INIT + [AAD_FINAL] + AES_CMD_FINAL + FLUSH
+ *   - Variable nonce (7--13 bytes), variable tag (4--16 bytes)
+ *   - Uses AES_CMD_CCM_INIT (0x0A) with aes_cmd_init struct
+ *   - Nonce passed via IV field, taglen in init
+ */
+
+#include <linux/module.h>
+#include <linux/kernel.h>
+#include <linux/crypto.h>
+#include <crypto/aes.h>
+#include <crypto/internal/aead.h>
+#include <crypto/scatterwalk.h>
+#include <crypto/utils.h>
+#include <linux/scatterlist.h>
+#include <linux/slab.h>
+#include <linux/string.h>
+
+#include "cmh_aes.h"
+#include "cmh_vcq.h"
+#include "cmh_aes_abi.h"
+#include "cmh_sys_abi.h"
+#include "cmh_sys.h"
+#include "cmh_txn.h"
+#include "cmh_dma.h"
+#include "cmh_key.h"
+
+/*
+ * GCM IV contract:
+ *
+ * The AES core requires exactly 16 bytes loaded into its IV register.
+ * For standard 96-bit nonce GCM, the driver passes:
+ *
+ *   IV[0..11]  = user-supplied 12-byte nonce
+ *   IV[12..15] = 0x00000000
+ *
+ * The hardware internally sets the last 32 bits to the big-endian
+ * counter value 1 (forming J0 = nonce || 0x00000001) before
+ * processing AAD.  The driver must NOT pre-set the counter.
+ *
+ * If the IV format is incorrect, GCM authentication will fail
+ * (encrypt produces wrong ciphertext/tag, decrypt rejects).
+ */
+#define AES_GCM_IV_SIZE		12U	/* GCM nonce size (standard) */
+#define AES_GCM_HW_IV_SIZE	16U	/* HW requires 16-byte IV buffer */
+#define AES_GCM_TAG_SIZE	16U
+
+/* CCM: callers pass a 16-byte IV in RFC 3610 format:
+ * iv[0] = L-1, iv[1..14-iv[0]] = nonce, rest = counter (zeroed).
+ * Nonce length = 14 - iv[0], range 7..13.
+ */
+#define AES_CCM_IV_SIZE	16U
+
+enum cmh_aes_aead_type {
+	CMH_AES_AEAD_GCM,
+	CMH_AES_AEAD_CCM,
+};
+
+struct cmh_aes_aead_info {
+	enum cmh_aes_aead_type type;
+	u32         aes_mode;	/* AES_MODE_GCM or AES_MODE_CCM */
+	u32         ivsize;
+	u32         maxauthsize;
+	const char *alg_name;
+	const char *drv_name;
+};
+
+static const struct cmh_aes_aead_info aes_aead_algs[] = {
+	{ CMH_AES_AEAD_GCM, AES_MODE_GCM, AES_GCM_IV_SIZE,
+	  AES_GCM_TAG_SIZE, "gcm(aes)", "rambus-cmh-gcm-aes" },
+	{ CMH_AES_AEAD_CCM, AES_MODE_CCM, AES_CCM_IV_SIZE,
+	  AES_GCM_TAG_SIZE, "ccm(aes)", "rambus-cmh-ccm-aes" },
+};
+
+struct cmh_aes_aead_tfm_ctx {
+	struct cmh_key_ctx key;
+	u32 authsize;		/* tag length set by setauthsize */
+	bool ccm;
+	struct aes_enckey sw_key;	/* CCM empty-input tag */
+	struct crypto_aead *fallback;	/* CCM authsize=10 fallback */
+};
+
+/* Per-request context (lives in aead_request::__ctx) */
+
+/*
+ * Maximum payload commands:
+ *   [SYS_CMD_WRITE] + AES_CMD_INIT + AAD_FINAL + AES_CMD_FINAL + FLUSH = 5
+ */
+#define CMH_AES_AEAD_MAX_PAYLOAD	5
+#define CMH_AES_AEAD_MAX_PACKED		(CMH_AES_AEAD_MAX_PAYLOAD * 2)
+
+struct cmh_aes_aead_reqctx {
+	dma_addr_t in_dma;
+	dma_addr_t out_dma;
+	dma_addr_t iv_dma;
+	dma_addr_t key_dma;
+	dma_addr_t aad_dma;
+	dma_addr_t tag_dma;
+	u8 *in_buf;
+	u8 *out_buf;
+	u8 *iv_buf;
+	u8 *aad_buf;
+	u8 *tag_buf;
+	u8 exp_tag[AES_GCM_TAG_SIZE];	/* empty-GCM decrypt: expected tag */
+	u32 cryptlen;
+	u32 assoclen;
+	u32 authsize;
+	u32 iv_map_len;
+	u32 keylen;
+	bool encrypting;
+	bool empty_gcm_fallback;
+	struct cmh_req_dma rdma;
+	struct vcq_cmd packed[CMH_AES_AEAD_MAX_PACKED];
+};
+
+struct cmh_aes_aead_drv {
+	struct aead_alg                  alg;
+	const struct cmh_aes_aead_info  *info;
+};
+
+static const struct cmh_aes_aead_info *
+cmh_aes_aead_get_info(struct crypto_aead *tfm)
+{
+	struct aead_alg *alg = crypto_aead_alg(tfm);
+
+	return container_of(alg, struct cmh_aes_aead_drv, alg)->info;
+}
+
+/* VCQ Builders -- AEAD-specific */
+
+static void vcq_add_aes_aead_init(struct vcq_cmd *slot, u32 core_id, u64 key_ref,
+				  u64 iv_dma, u32 keylen, u32 ivlen,
+				  u32 mode, u32 op, u32 aadlen, u32 iolen,
+				  u32 taglen)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(core_id, 0, 1, AES_CMD_INIT);
+	slot->hwc.aes.cmd_init.key = key_ref;
+	slot->hwc.aes.cmd_init.iv = iv_dma;
+	slot->hwc.aes.cmd_init.keylen = keylen;
+	slot->hwc.aes.cmd_init.ivlen = ivlen;
+	slot->hwc.aes.cmd_init.mode = mode;
+	slot->hwc.aes.cmd_init.op = op;
+	slot->hwc.aes.cmd_init.aadlen = aadlen;
+	slot->hwc.aes.cmd_init.iolen = iolen;
+	slot->hwc.aes.cmd_init.taglen = taglen;
+}
+
+static void vcq_add_aes_ccm_init(struct vcq_cmd *slot, u32 core_id, u64 key_ref,
+				 u64 nonce_dma, u32 keylen, u32 noncelen,
+				 u32 op, u32 aadlen, u32 iolen, u32 taglen)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(core_id, 0, 1, AES_CMD_CCM_INIT);
+	slot->hwc.aes.cmd_init.key = key_ref;
+	slot->hwc.aes.cmd_init.iv = nonce_dma;
+	slot->hwc.aes.cmd_init.keylen = keylen;
+	slot->hwc.aes.cmd_init.ivlen = noncelen;
+	slot->hwc.aes.cmd_init.mode = AES_MODE_CCM;
+	slot->hwc.aes.cmd_init.op = op;
+	slot->hwc.aes.cmd_init.aadlen = aadlen;
+	slot->hwc.aes.cmd_init.iolen = iolen;
+	slot->hwc.aes.cmd_init.taglen = taglen;
+}
+
+static void vcq_add_aes_aad_final(struct vcq_cmd *slot, u32 core_id, u64 aad_dma,
+				  u32 aadlen)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(core_id, 0, 1, AES_CMD_AAD_FINAL);
+	slot->hwc.aes.cmd_aad_final.data = aad_dma;
+	slot->hwc.aes.cmd_aad_final.datalen = aadlen;
+}
+
+static void vcq_add_aes_aead_final(struct vcq_cmd *slot, u32 core_id, u64 input_dma,
+				   u64 output_dma, u64 tag_dma,
+				   u32 iolen, u32 taglen)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(core_id, 0, 1, AES_CMD_FINAL);
+	slot->hwc.aes.cmd_final.input = input_dma;
+	slot->hwc.aes.cmd_final.output = output_dma;
+	slot->hwc.aes.cmd_final.tag = tag_dma;
+	slot->hwc.aes.cmd_final.iolen = iolen;
+	slot->hwc.aes.cmd_final.taglen = taglen;
+}
+
+/* setkey */
+static int cmh_aes_aead_setkey(struct crypto_aead *tfm, const u8 *key,
+			       unsigned int keylen)
+{
+	struct cmh_aes_aead_tfm_ctx *tctx = crypto_aead_ctx(tfm);
+	int ret;
+
+	if (keylen != 16 && keylen != 24 && keylen != 32)
+		return -EINVAL;
+
+	/*
+	 * Program the HW key first; only mirror it to the SW key and
+	 * fallback on success so a failed HW step cannot leave them (new)
+	 * inconsistent with the HW key (old).
+	 */
+	ret = cmh_key_setkey_raw(&tctx->key, key, keylen, CORE_ID_AES);
+	if (ret)
+		return ret;
+
+	if (tctx->ccm) {
+		ret = aes_prepareenckey(&tctx->sw_key, key, keylen);
+		if (ret)
+			return ret;
+	}
+	if (tctx->fallback) {
+		ret = crypto_aead_setkey(tctx->fallback, key, keylen);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
+}
+
+static int cmh_aes_aead_setauthsize(struct crypto_aead *tfm,
+				    unsigned int authsize)
+{
+	struct cmh_aes_aead_tfm_ctx *tctx = crypto_aead_ctx(tfm);
+	const struct cmh_aes_aead_info *info = cmh_aes_aead_get_info(tfm);
+	int ret;
+
+	if (info->type == CMH_AES_AEAD_GCM) {
+		/* GCM: accept 4, 8, 12, 13, 14, 15, 16 per NIST SP 800-38D */
+		if (authsize < 4 || authsize > 16 ||
+		    (authsize > 4 && authsize < 8) ||
+		    (authsize > 8 && authsize < 12))
+			return -EINVAL;
+	} else {
+		/* CCM: accept all RFC 3610 values {4,6,8,10,12,14,16} */
+		if (authsize < 4 || authsize > 16 || (authsize & 1))
+			return -EINVAL;
+		/* Forward to SW fallback for authsize=10 (HW unsupported) */
+		if (tctx->fallback) {
+			ret = crypto_aead_setauthsize(tctx->fallback,
+						      authsize);
+			if (ret)
+				return ret;
+		}
+	}
+
+	tctx->authsize = authsize;
+	return 0;
+}
+
+static int cmh_aes_aead_init_tfm(struct crypto_aead *tfm)
+{
+	struct cmh_aes_aead_tfm_ctx *tctx = crypto_aead_ctx(tfm);
+	const struct cmh_aes_aead_info *info = cmh_aes_aead_get_info(tfm);
+
+	memset(tctx, 0, sizeof(*tctx));
+	tctx->authsize = info->maxauthsize;
+
+	if (info->type == CMH_AES_AEAD_CCM) {
+		struct crypto_aead *fb;
+
+		tctx->ccm = true;
+		fb = crypto_alloc_aead("ccm(aes)", 0,
+				       CRYPTO_ALG_NEED_FALLBACK);
+		if (IS_ERR(fb))
+			return PTR_ERR(fb);
+		tctx->fallback = fb;
+
+		/*
+		 * The fallback subrequest is placed after cmh_aes_aead_reqctx
+		 * and PTR_ALIGN()'d to crypto_tfm_ctx_alignment() in
+		 * cmh_aes_ccm_fallback().  Reserve that alignment as slack so
+		 * the aligned subrequest still fits within the request context
+		 * even when ARCH_KMALLOC_MINALIGN exceeds the struct's natural
+		 * alignment.
+		 */
+		crypto_aead_set_reqsize(tfm,
+					sizeof(struct cmh_aes_aead_reqctx) +
+					crypto_tfm_ctx_alignment() +
+					sizeof(struct aead_request) +
+					crypto_aead_reqsize(fb));
+	} else {
+		crypto_aead_set_reqsize(tfm,
+					sizeof(struct cmh_aes_aead_reqctx));
+	}
+
+	return 0;
+}
+
+static void cmh_aes_aead_exit_tfm(struct crypto_aead *tfm)
+{
+	struct cmh_aes_aead_tfm_ctx *tctx = crypto_aead_ctx(tfm);
+
+	if (tctx->fallback)
+		crypto_free_aead(tctx->fallback);
+	memzero_explicit(&tctx->sw_key, sizeof(tctx->sw_key));
+	cmh_key_destroy(&tctx->key);
+}
+
+static void cmh_aes_aead_complete(void *data, int error)
+{
+	struct aead_request *req = data;
+	struct cmh_aes_aead_reqctx *rctx = aead_request_ctx(req);
+
+	if (error == -EINPROGRESS) {
+		cmh_complete(&req->base, error);
+		return;
+	}
+
+	cmh_req_dma_unmap(&rctx->rdma);
+
+	/*
+	 * The eSW AES core reports a tag mismatch with the same error code
+	 * as its other failures, so the response handler completes both
+	 * with -EIO.  The crypto API requires -EBADMSG for an AEAD
+	 * authentication failure, so a GCM/CCM decrypt -EIO is returned as
+	 * -EBADMSG; this also reports a genuine core fault during decrypt as
+	 * an authentication failure.  The empty-GCM path only runs an ECB
+	 * encryption on the device and compares the tag on the host, so a
+	 * device error there is never a mismatch and stays -EIO.
+	 */
+	if (error == -EIO && !rctx->encrypting && !rctx->empty_gcm_fallback)
+		error = -EBADMSG;
+
+	if (!error) {
+		/* GCM empty-input decrypt: compare computed tag with expected */
+		if (rctx->empty_gcm_fallback && !rctx->encrypting) {
+			if (crypto_memneq(rctx->tag_buf, rctx->exp_tag,
+					  rctx->authsize))
+				error = -EBADMSG;
+		}
+		if (!error && rctx->cryptlen > 0)
+			scatterwalk_map_and_copy(rctx->out_buf, req->dst,
+						 req->assoclen,
+						rctx->cryptlen, 1);
+		if (!error && rctx->encrypting)
+			scatterwalk_map_and_copy(rctx->tag_buf, req->dst,
+						 req->assoclen +
+						rctx->cryptlen,
+						rctx->authsize, 1);
+	}
+
+	cmh_req_dma_free(&rctx->rdma);
+	cmh_complete(&req->base, error);
+}
+
+/*
+ * GCM empty-input fallback.
+ *
+ * When both AAD and plaintext are empty, GCM reduces to:
+ *   tag = E(K, J0) where J0 = nonce || 0x00000001
+ *
+ * The eSW GCM engine rejects this degenerate case, so we compute it
+ * via a single ECB block encryption of J0.
+ *
+ * VCQ: [SYS_CMD_WRITE] + AES_CMD_INIT(ECB) + AES_CMD_FINAL + FLUSH
+ */
+static int cmh_aes_gcm_empty(struct aead_request *req, u32 aes_op)
+{
+	struct crypto_aead *tfm = crypto_aead_reqtfm(req);
+	struct cmh_aes_aead_tfm_ctx *tctx = crypto_aead_ctx(tfm);
+	struct cmh_aes_aead_reqctx *rctx = aead_request_ctx(req);
+	struct vcq_cmd cmds[CMH_AES_AEAD_MAX_PAYLOAD];
+	u64 key_ref;
+	u32 keylen, authsize;
+	struct core_dispatch d;
+	s32 target_mbx;
+	u32 core_id;
+	u32 idx;
+	int ret;
+	gfp_t gfp;
+
+	authsize = tctx->authsize;
+
+	gfp = req->base.flags & CRYPTO_TFM_REQ_MAY_SLEEP ?
+	      GFP_KERNEL : GFP_ATOMIC;
+
+	memset(rctx, 0, sizeof(*rctx));
+	rctx->cryptlen = 0;
+	rctx->assoclen = 0;
+	rctx->authsize = authsize;
+	rctx->encrypting = (aes_op == AES_OP_ENCRYPT);
+	rctx->empty_gcm_fallback = true;
+	cmh_req_dma_init(&rctx->rdma);
+
+	/* Build J0 = nonce || 0x00000001 in iv_buf */
+	rctx->iv_buf = kzalloc(AES_GCM_HW_IV_SIZE, gfp);
+	if (!rctx->iv_buf)
+		return -ENOMEM;
+	memcpy(rctx->iv_buf, req->iv, AES_GCM_IV_SIZE);
+	rctx->iv_buf[15] = 0x01; /* big-endian counter = 1 */
+
+	rctx->iv_dma = cmh_req_dma_add(&rctx->rdma, rctx->iv_buf,
+				       AES_GCM_HW_IV_SIZE, DMA_TO_DEVICE,
+				       false);
+	if (cmh_dma_map_error(rctx->iv_dma)) {
+		ret = -ENOMEM;
+		goto out_release;
+	}
+
+	/* Tag buffer -- receives E(K, J0) output */
+	rctx->tag_buf = kzalloc(AES_GCM_HW_IV_SIZE, gfp);
+	if (!rctx->tag_buf) {
+		ret = -ENOMEM;
+		goto out_release;
+	}
+	rctx->tag_dma = cmh_req_dma_add(&rctx->rdma, rctx->tag_buf,
+					AES_GCM_HW_IV_SIZE, DMA_FROM_DEVICE,
+					false);
+	if (cmh_dma_map_error(rctx->tag_dma)) {
+		ret = -ENOMEM;
+		goto out_release;
+	}
+
+	/* For decrypt: read expected tag from request for later comparison */
+	if (!rctx->encrypting)
+		scatterwalk_map_and_copy(rctx->exp_tag, req->src, 0,
+					 authsize, 0);
+
+	/* Resolve key */
+	idx = 0;
+	rctx->key_dma = tctx->key.raw.dma;
+	vcq_add_sys_write(&cmds[idx++], SYS_REF_TEMP,
+			  (u64)rctx->key_dma, SYS_REF_NONE,
+			  tctx->key.raw.len,
+			  tctx->key.raw.sys_type);
+	key_ref = SYS_REF_TEMP;
+	keylen = tctx->key.raw.len;
+	d = cmh_core_select_instance(CMH_CORE_AES);
+	target_mbx = d.mbx_idx;
+	core_id = d.core_id;
+
+	/* ECB INIT: single block encryption of J0 */
+	vcq_add_aes_aead_init(&cmds[idx++], core_id, key_ref,
+			      0, keylen, 0, AES_MODE_ECB, AES_OP_ENCRYPT,
+			      0, AES_GCM_HW_IV_SIZE, 0);
+
+	/* FINAL: J0 in, E(K,J0) out */
+	vcq_add_aes_aead_final(&cmds[idx++], core_id,
+			       (u64)rctx->iv_dma, (u64)rctx->tag_dma,
+			       0, AES_GCM_HW_IV_SIZE, 0);
+
+	vcq_add_flush(&cmds[idx++], core_id);
+
+	ret = cmh_vcq_pack_and_submit_async(cmds, idx, rctx->packed,
+					    CMH_AES_AEAD_MAX_PACKED,
+					    target_mbx,
+					    cmh_aes_aead_complete, req,
+					    &rctx->rdma,
+					    !!(req->base.flags &
+					       CRYPTO_TFM_REQ_MAY_BACKLOG),
+					    cmh_tm_async_timeout_jiffies());
+	if (ret == -EBUSY)
+		return -EBUSY;
+	if (ret)
+		goto out_release;
+
+	return -EINPROGRESS;
+
+out_release:
+	cmh_req_dma_release(&rctx->rdma);
+	return ret;
+}
+
+/*
+ * CCM empty-input fallback.
+ *
+ * When both AAD and plaintext are empty, CCM reduces to:
+ *   T  = E(K, B0)    -- CBC-MAC of the single formatting block
+ *   S0 = E(K, A0)    -- CTR block zero
+ *   tag = (T XOR S0)[0..authsize-1]
+ *
+ * The eSW rejects this degenerate case, so the driver computes it
+ * synchronously via two single-block encryptions with the AES library.
+ */
+static int cmh_aes_ccm_empty(struct aead_request *req, u32 aes_op)
+{
+	struct crypto_aead *tfm = crypto_aead_reqtfm(req);
+	struct cmh_aes_aead_tfm_ctx *tctx = crypto_aead_ctx(tfm);
+	u32 authsize = tctx->authsize;
+	u8 b0[CMH_AES_BLOCK_SIZE], a0[CMH_AES_BLOCK_SIZE];
+	u8 t[CMH_AES_BLOCK_SIZE], s0[CMH_AES_BLOCK_SIZE];
+	u8 tag[CMH_AES_BLOCK_SIZE];
+	u8 L;
+	u32 i;
+
+	/* Defense-in-depth: iv[0] = L-1, valid L is 2..8 per RFC 3610 S2.1 */
+	if (WARN_ON_ONCE(req->iv[0] < 1 || req->iv[0] > 7))
+		return -EINVAL;
+
+	L = req->iv[0] + 1;
+
+	if (tctx->key.mode != CMH_KEY_RAW)
+		return -EOPNOTSUPP;
+
+	/* B0: flags || nonce || Q(=0).  Adata=0, t=authsize, q=L. */
+	memset(b0, 0, CMH_AES_BLOCK_SIZE);
+	b0[0] = (u8)(8 * ((authsize - 2) / 2) + (L - 1));
+	memcpy(&b0[1], &req->iv[1], 15 - L);
+
+	/* A0: (L-1) || nonce || counter(=0) */
+	memset(a0, 0, CMH_AES_BLOCK_SIZE);
+	a0[0] = (u8)(L - 1);
+	memcpy(&a0[1], &req->iv[1], 15 - L);
+
+	aes_encrypt(&tctx->sw_key, t, b0);
+	aes_encrypt(&tctx->sw_key, s0, a0);
+
+	for (i = 0; i < authsize; i++)
+		tag[i] = t[i] ^ s0[i];
+
+	if (aes_op == AES_OP_ENCRYPT) {
+		scatterwalk_map_and_copy(tag, req->dst,
+					 req->assoclen, authsize, 1);
+	} else {
+		u8 expected[CMH_AES_BLOCK_SIZE];
+
+		scatterwalk_map_and_copy(expected, req->src,
+					 req->assoclen, authsize, 0);
+		if (crypto_memneq(tag, expected, authsize))
+			return -EBADMSG;
+	}
+
+	return 0;
+}
+
+/*
+ * CCM authsize=10 fallback.
+ *
+ * The eSW AES CCM core does not support authsize=10 (valid per RFC 3610).
+ * Forward the entire request to the generic CCM implementation.
+ */
+static void cmh_aes_ccm_fb_done(void *data, int err)
+{
+	struct aead_request *req = data;
+
+	cmh_complete(&req->base, err);
+}
+
+static int cmh_aes_ccm_fallback(struct aead_request *req, u32 aes_op)
+{
+	struct crypto_aead *tfm = crypto_aead_reqtfm(req);
+	struct cmh_aes_aead_tfm_ctx *tctx = crypto_aead_ctx(tfm);
+	struct cmh_aes_aead_reqctx *rctx = aead_request_ctx(req);
+	struct aead_request *subreq =
+		PTR_ALIGN((void *)(rctx + 1), crypto_tfm_ctx_alignment());
+
+	aead_request_set_tfm(subreq, tctx->fallback);
+	aead_request_set_callback(subreq, req->base.flags,
+				  cmh_aes_ccm_fb_done, req);
+	aead_request_set_crypt(subreq, req->src, req->dst,
+			       req->cryptlen, req->iv);
+	aead_request_set_ad(subreq, req->assoclen);
+
+	return (aes_op == AES_OP_ENCRYPT) ?
+		crypto_aead_encrypt(subreq) : crypto_aead_decrypt(subreq);
+}
+
+/*
+ * Core AEAD encrypt/decrypt -- async path.
+ *
+ * Encrypt: plaintext -> ciphertext + tag appended
+ * Decrypt: ciphertext + tag -> plaintext (tag verified by eSW)
+ *
+ * VCQ: [SYS_CMD_WRITE] + INIT/CCM_INIT + [AAD_FINAL] + FINAL + FLUSH
+ */
+static int cmh_aes_aead_crypt(struct aead_request *req, u32 aes_op)
+{
+	struct crypto_aead *tfm = crypto_aead_reqtfm(req);
+	struct cmh_aes_aead_tfm_ctx *tctx = crypto_aead_ctx(tfm);
+	const struct cmh_aes_aead_info *info = cmh_aes_aead_get_info(tfm);
+	struct cmh_aes_aead_reqctx *rctx = aead_request_ctx(req);
+	struct vcq_cmd cmds[CMH_AES_AEAD_MAX_PAYLOAD];
+	u64 key_ref;
+	u32 keylen, authsize, cryptlen;
+	struct core_dispatch d;
+	s32 target_mbx;
+	u32 core_id;
+	u32 idx;
+	int ret;
+	gfp_t gfp;
+
+	if (tctx->key.mode == CMH_KEY_NONE)
+		return -ENOKEY;
+
+	authsize = tctx->authsize;
+
+	if (aes_op == AES_OP_ENCRYPT) {
+		cryptlen = req->cryptlen;
+	} else {
+		if (req->cryptlen < authsize)
+			return -EINVAL;
+		cryptlen = req->cryptlen - authsize;
+	}
+
+	/*
+	 * Validate CCM IV format early -- the empty-input fallback and
+	 * nonce extraction both depend on iv[0] being in range [1,7].
+	 */
+	if (info->type == CMH_AES_AEAD_CCM) {
+		if (req->iv[0] < 1 || req->iv[0] > 7)
+			return -EINVAL;
+		/*
+		 * RFC 3610: the payload must fit in L = iv[0] + 1 length
+		 * octets.  Reject an unencodable length with -EOVERFLOW.  This
+		 * is stricter than crypto/ccm.c set_msg_len(), which uses '>'
+		 * and would accept (then silently truncate) exactly 2^(8L).
+		 * (iv[0]==7 => L=8 covers any cryptlen.)
+		 */
+		if (req->iv[0] < 7 &&
+		    (u64)cryptlen >= (1ULL << (8 * (req->iv[0] + 1))))
+			return -EOVERFLOW;
+	}
+
+	/*
+	 * The CMH eSW rejects GCM/CCM when both aadlen and iolen are zero.
+	 * For GCM, the tag is simply E(K, J0) -- handle with ECB fallback.
+	 * For CCM, compute tag = E(K,B0) XOR E(K,A0) in software.
+	 */
+	if (cryptlen == 0 && req->assoclen == 0) {
+		if (info->type == CMH_AES_AEAD_GCM)
+			return cmh_aes_gcm_empty(req, aes_op);
+		return cmh_aes_ccm_empty(req, aes_op);
+	}
+
+	/*
+	 * HW does not support authsize=10 for CCM.  Forward the entire
+	 * request to the generic CCM implementation.
+	 */
+	if (info->type == CMH_AES_AEAD_CCM && authsize == 10)
+		return cmh_aes_ccm_fallback(req, aes_op);
+
+	/*
+	 * HW uses a proprietary LLI scatter-gather format that is
+	 * incompatible with struct scatterlist, so the payload is
+	 * linearised into contiguous buffers for DMA.  Cap total
+	 * size to prevent excessive memory consumption.
+	 */
+	if ((u64)cryptlen + req->assoclen > SZ_1M)
+		return -EINVAL;
+
+	gfp = req->base.flags & CRYPTO_TFM_REQ_MAY_SLEEP ?
+	      GFP_KERNEL : GFP_ATOMIC;
+
+	memset(rctx, 0, sizeof(*rctx));
+	rctx->cryptlen = cryptlen;
+	rctx->assoclen = req->assoclen;
+	rctx->authsize = authsize;
+	rctx->encrypting = (aes_op == AES_OP_ENCRYPT);
+	cmh_req_dma_init(&rctx->rdma);
+
+	/* Linearise AAD */
+	if (req->assoclen > 0) {
+		rctx->aad_buf = kmalloc(req->assoclen, gfp | __GFP_NOWARN);
+		if (!rctx->aad_buf)
+			return -ENOMEM;
+		scatterwalk_map_and_copy(rctx->aad_buf, req->src,
+					 0, req->assoclen, 0);
+		rctx->aad_dma = cmh_req_dma_add(&rctx->rdma, rctx->aad_buf,
+						req->assoclen, DMA_TO_DEVICE,
+						false);
+		if (cmh_dma_map_error(rctx->aad_dma)) {
+			ret = -ENOMEM;
+			goto out_release;
+		}
+	}
+
+	/* Linearise input */
+	if (cryptlen > 0) {
+		rctx->in_buf = kmalloc(cryptlen, gfp | __GFP_NOWARN);
+		if (!rctx->in_buf) {
+			ret = -ENOMEM;
+			goto out_release;
+		}
+		scatterwalk_map_and_copy(rctx->in_buf, req->src,
+					 req->assoclen, cryptlen, 0);
+		rctx->in_dma = cmh_req_dma_add(&rctx->rdma, rctx->in_buf,
+					       cryptlen, DMA_TO_DEVICE, true);
+		if (cmh_dma_map_error(rctx->in_dma)) {
+			ret = -ENOMEM;
+			goto out_release;
+		}
+	}
+
+	/* Allocate output buffer */
+	if (cryptlen > 0) {
+		rctx->out_buf = kmalloc(cryptlen, gfp | __GFP_NOWARN);
+		if (!rctx->out_buf) {
+			ret = -ENOMEM;
+			goto out_release;
+		}
+		rctx->out_dma = cmh_req_dma_add(&rctx->rdma, rctx->out_buf,
+						cryptlen, DMA_FROM_DEVICE,
+						true);
+		if (cmh_dma_map_error(rctx->out_dma)) {
+			ret = -ENOMEM;
+			goto out_release;
+		}
+	}
+
+	/* Tag buffer */
+	rctx->tag_buf = kmalloc(authsize, gfp);
+	if (!rctx->tag_buf) {
+		ret = -ENOMEM;
+		goto out_release;
+	}
+
+	if (!rctx->encrypting) {
+		scatterwalk_map_and_copy(rctx->tag_buf, req->src,
+					 req->assoclen + cryptlen,
+					authsize, 0);
+	} else {
+		memset(rctx->tag_buf, 0, authsize);
+	}
+
+	rctx->tag_dma = cmh_req_dma_add(&rctx->rdma, rctx->tag_buf, authsize,
+					rctx->encrypting ?
+					DMA_FROM_DEVICE : DMA_TO_DEVICE,
+					false);
+	if (cmh_dma_map_error(rctx->tag_dma)) {
+		ret = -ENOMEM;
+		goto out_release;
+	}
+
+	/* Map IV/nonce */
+	if (info->type == CMH_AES_AEAD_GCM) {
+		rctx->iv_buf = kzalloc(AES_GCM_HW_IV_SIZE, gfp);
+		if (!rctx->iv_buf) {
+			ret = -ENOMEM;
+			goto out_release;
+		}
+		memcpy(rctx->iv_buf, req->iv, AES_GCM_IV_SIZE);
+		rctx->iv_map_len = AES_GCM_HW_IV_SIZE;
+	} else {
+		u32 noncelen;
+
+		if (req->iv[0] < 1 || req->iv[0] > 7) {
+			ret = -EINVAL;
+			goto out_release;
+		}
+		noncelen = 14 - req->iv[0];
+
+		rctx->iv_buf = kmemdup(req->iv + 1, noncelen, gfp);
+		if (!rctx->iv_buf) {
+			ret = -ENOMEM;
+			goto out_release;
+		}
+		rctx->iv_map_len = noncelen;
+	}
+	rctx->iv_dma = cmh_req_dma_add(&rctx->rdma, rctx->iv_buf,
+				       rctx->iv_map_len, DMA_TO_DEVICE, false);
+	if (cmh_dma_map_error(rctx->iv_dma)) {
+		ret = -ENOMEM;
+		goto out_release;
+	}
+
+	/* Resolve key reference */
+	idx = 0;
+
+	rctx->key_dma = tctx->key.raw.dma;
+	rctx->keylen = tctx->key.raw.len;
+	vcq_add_sys_write(&cmds[idx++], SYS_REF_TEMP,
+			  (u64)rctx->key_dma, SYS_REF_NONE,
+			  tctx->key.raw.len,
+			  tctx->key.raw.sys_type);
+	key_ref = SYS_REF_TEMP;
+	keylen = tctx->key.raw.len;
+	d = cmh_core_select_instance(CMH_CORE_AES);
+	target_mbx = d.mbx_idx;
+	core_id = d.core_id;
+
+	/* Build INIT command */
+	if (info->type == CMH_AES_AEAD_CCM) {
+		vcq_add_aes_ccm_init(&cmds[idx++], core_id, key_ref,
+				     (u64)rctx->iv_dma, keylen,
+				     rctx->iv_map_len, aes_op,
+				     req->assoclen, cryptlen, authsize);
+	} else {
+		vcq_add_aes_aead_init(&cmds[idx++], core_id, key_ref,
+				      (u64)rctx->iv_dma, keylen,
+				      AES_GCM_HW_IV_SIZE, info->aes_mode,
+				      aes_op, req->assoclen, cryptlen,
+				      authsize);
+	}
+
+	if (req->assoclen > 0)
+		vcq_add_aes_aad_final(&cmds[idx++], core_id,
+				      (u64)rctx->aad_dma, req->assoclen);
+
+	vcq_add_aes_aead_final(&cmds[idx++], core_id,
+			       cryptlen > 0 ? (u64)rctx->in_dma : 0,
+			       cryptlen > 0 ? (u64)rctx->out_dma : 0,
+			       (u64)rctx->tag_dma, cryptlen, authsize);
+
+	vcq_add_flush(&cmds[idx++], core_id);
+
+	ret = cmh_vcq_pack_and_submit_async(cmds, idx, rctx->packed,
+					    CMH_AES_AEAD_MAX_PACKED,
+					    target_mbx,
+					    cmh_aes_aead_complete, req,
+					    &rctx->rdma,
+					    !!(req->base.flags &
+					       CRYPTO_TFM_REQ_MAY_BACKLOG),
+					    cmh_tm_async_timeout_jiffies());
+	if (ret == -EBUSY)
+		return -EBUSY;
+	if (ret)
+		goto out_release;
+
+	return -EINPROGRESS;
+
+out_release:
+	cmh_req_dma_release(&rctx->rdma);
+	return ret;
+}
+
+static int cmh_aes_aead_encrypt(struct aead_request *req)
+{
+	return cmh_aes_aead_crypt(req, AES_OP_ENCRYPT);
+}
+
+static int cmh_aes_aead_decrypt(struct aead_request *req)
+{
+	return cmh_aes_aead_crypt(req, AES_OP_DECRYPT);
+}
+
+/* Registration */
+
+static struct cmh_aes_aead_drv aes_aead_drv_algs[ARRAY_SIZE(aes_aead_algs)];
+
+/**
+ * cmh_aes_aead_register() - Register AES-GCM/CCM AEAD algorithms with the crypto framework
+ *
+ * Return: 0 on success, negative errno on failure.
+ */
+int cmh_aes_aead_register(void)
+{
+	unsigned int i;
+	int ret;
+
+	if (!cmh_core_present(CMH_CORE_AES))
+		return 0;
+
+	for (i = 0; i < ARRAY_SIZE(aes_aead_algs); i++) {
+		const struct cmh_aes_aead_info *info = &aes_aead_algs[i];
+		struct cmh_aes_aead_drv *drv = &aes_aead_drv_algs[i];
+		struct aead_alg *alg = &drv->alg;
+
+		drv->info = info;
+
+		memset(alg, 0, sizeof(*alg));
+
+		alg->setkey      = cmh_aes_aead_setkey;
+		alg->setauthsize = cmh_aes_aead_setauthsize;
+		alg->encrypt     = cmh_aes_aead_encrypt;
+		alg->decrypt     = cmh_aes_aead_decrypt;
+		alg->init        = cmh_aes_aead_init_tfm;
+		alg->exit        = cmh_aes_aead_exit_tfm;
+		alg->ivsize      = info->ivsize;
+		alg->maxauthsize = info->maxauthsize;
+
+		strscpy(alg->base.cra_name, info->alg_name,
+			CRYPTO_MAX_ALG_NAME);
+		strscpy(alg->base.cra_driver_name, info->drv_name,
+			CRYPTO_MAX_ALG_NAME);
+		alg->base.cra_priority  = 300;
+		alg->base.cra_flags     = CRYPTO_ALG_KERN_DRIVER_ONLY |
+					  CRYPTO_ALG_ALLOCATES_MEMORY |
+					  CRYPTO_ALG_ASYNC;
+		if (info->type == CMH_AES_AEAD_CCM) {
+			alg->base.cra_flags |= CRYPTO_ALG_NEED_FALLBACK;
+			/*
+			 * Bump priority above 300 so we beat the generic
+			 * ccm_base template instance.  That template inherits
+			 * priority (ctr + cbcmac) / 2 = 300 when both
+			 * constituents are at 300, and list ordering would
+			 * otherwise let it shadow our driver.
+			 */
+			alg->base.cra_priority = 301;
+		}
+		alg->base.cra_blocksize = 1;
+		alg->base.cra_ctxsize  = sizeof(struct cmh_aes_aead_tfm_ctx);
+		alg->base.cra_module   = THIS_MODULE;
+
+		ret = crypto_register_aead(alg);
+		if (ret) {
+			dev_err(cmh_dev(), "cmh_aes_aead: failed to register %s (rc=%d)\n",
+				info->alg_name, ret);
+			goto err_unregister;
+		}
+
+		dev_dbg(cmh_dev(), "cmh_aes_aead: registered %s\n", info->alg_name);
+	}
+
+	return 0;
+
+err_unregister:
+	while (i--)
+		crypto_unregister_aead(&aes_aead_drv_algs[i].alg);
+	return ret;
+}
+
+/**
+ * cmh_aes_aead_unregister() - Unregister AES AEAD algorithms from the crypto framework
+ */
+void cmh_aes_aead_unregister(void)
+{
+	unsigned int i;
+
+	if (!cmh_core_present(CMH_CORE_AES))
+		return;
+
+	for (i = 0; i < ARRAY_SIZE(aes_aead_algs); i++) {
+		crypto_unregister_aead(&aes_aead_drv_algs[i].alg);
+		dev_dbg(cmh_dev(), "cmh_aes_aead: unregistered %s\n",
+			aes_aead_algs[i].alg_name);
+	}
+}
diff --git a/drivers/crypto/cmh/cmh_aes_cmac.c b/drivers/crypto/cmh/cmh_aes_cmac.c
new file mode 100644
index 000000000000..34a7a5ba07ba
--- /dev/null
+++ b/drivers/crypto/cmh/cmh_aes_cmac.c
@@ -0,0 +1,459 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- Kernel Crypto API AES-CMAC (ahash) Driver
+ *
+ * Registers cmac(aes) as an ahash algorithm.
+ *
+ * CMAC produces a 16-byte tag (MAC) from a key and message.
+ *
+ * Digest-only hardware model with a generic software fallback.  The AES
+ * core cannot save/restore intermediate CMAC state, so the driver
+ * accelerates only the one-shot .digest() and routes every stateful
+ * operation to a generic software cmac(aes) fallback.  The generic
+ * cmac(aes) shash has no export_core, so the crypto core cannot install
+ * it as crypto_ahash_fb(); the driver allocates it in .init_tfm()
+ * (hence CRYPTO_ALG_NO_FALLBACK) and sets CRYPTO_ALG_REQ_VIRT to accept
+ * and forward virtual-address requests itself:
+ *
+ *   .setkey()  -> key the HW (raw key) and the software fallback
+ *   .digest()  -> SYS_CMD_WRITE + AES_CMD_INIT(CMAC) +
+ *                 AES_CMD_AAD_FINAL_AUTH + FLUSH
+ *   .init()/.update()/.final()/.finup()/.export()/.import()
+ *              -> forwarded to the keyed generic cmac(aes) fallback
+ */
+
+#include <linux/module.h>
+#include <linux/kernel.h>
+#include <linux/crypto.h>
+#include <crypto/internal/hash.h>
+#include <crypto/hash.h>
+#include <crypto/scatterwalk.h>
+#include <linux/slab.h>
+#include <linux/string.h>
+
+#include "cmh_aes.h"
+#include "cmh_vcq.h"
+#include "cmh_aes_abi.h"
+#include "cmh_sys_abi.h"
+#include "cmh_sys.h"
+#include "cmh_txn.h"
+#include "cmh_dma.h"
+#include "cmh_key.h"
+
+#define AES_CMAC_DIGEST_SIZE	16U
+#define AES_CMAC_BLOCK_SIZE	16U
+
+/* Per-transform context -- carries the MAC key across requests. */
+struct cmh_aes_cmac_tfm_ctx {
+	struct cmh_key_ctx key;
+	struct crypto_ahash *fb;	/* generic cmac(aes) software fallback */
+};
+
+/* Per-request context (lives in ahash_request::__ctx) */
+
+/*
+ * Maximum payload commands a one-shot CMAC digest produces:
+ *   SYS_CMD_WRITE + AES_CMD_INIT + AES_CMD_AAD_FINAL_AUTH + FLUSH = 4
+ */
+#define CMH_AES_CMAC_MAX_PAYLOAD	4
+#define CMH_AES_CMAC_MAX_PACKED		(CMH_AES_CMAC_MAX_PAYLOAD * 2)
+
+/*
+ * Only the one-shot .digest() path uses the HW fields; every other op
+ * forwards to the fallback request that cmh_aes_cmac_init_tfm() reserved
+ * immediately after this struct (see cmh_aes_cmac_fb_req()).
+ */
+struct cmh_aes_cmac_reqctx {
+	int  error;
+	dma_addr_t in_dma;
+	dma_addr_t tag_dma;
+	u8  *buf;	/* linearised message for DMA */
+	u8  *tag_buf;
+	struct cmh_req_dma rdma;
+	struct vcq_cmd packed[CMH_AES_CMAC_MAX_PACKED];
+	/* Fallback ahash_request follows here; keep this struct last. */
+};
+
+/*
+ * The fallback ahash_request lives immediately after the reqctx;
+ * cmh_aes_cmac_init_tfm() reserves room for it and PTR_ALIGN keeps it
+ * aligned for the fallback's own request context.
+ */
+static struct ahash_request *
+cmh_aes_cmac_fb_req(struct cmh_aes_cmac_reqctx *rctx)
+{
+	return PTR_ALIGN((void *)(rctx + 1), crypto_tfm_ctx_alignment());
+}
+
+/*
+ * .setkey() -- key both the hardware (raw key, used by the one-shot HW
+ * .digest()) and the generic software fallback (crypto_ahash_fb(), used
+ * by every stateful op the crypto core routes through it).
+ */
+static int cmh_aes_cmac_setkey(struct crypto_ahash *tfm, const u8 *key,
+			       unsigned int keylen)
+{
+	struct cmh_aes_cmac_tfm_ctx *tctx = crypto_ahash_ctx(tfm);
+	int ret;
+
+	if (keylen != 16 && keylen != 24 && keylen != 32)
+		return -EINVAL;
+
+	ret = cmh_key_setkey_raw(&tctx->key, key, keylen, CORE_ID_AES);
+	if (ret)
+		return ret;
+
+	/* Keep the software fallback keyed in lock-step. */
+	return crypto_ahash_setkey(tctx->fb, key, keylen);
+}
+
+/* One-shot .digest() completion: copy the tag out, then free buffers. */
+static void cmh_aes_cmac_complete(void *data, int error)
+{
+	struct ahash_request *req = data;
+	struct cmh_aes_cmac_reqctx *rctx = ahash_request_ctx(req);
+
+	if (error == -EINPROGRESS) {
+		cmh_complete(&req->base, error);
+		return;
+	}
+
+	cmh_req_dma_unmap(&rctx->rdma);
+
+	if (!error)
+		memcpy(req->result, rctx->tag_buf, AES_CMAC_DIGEST_SIZE);
+
+	cmh_req_dma_free(&rctx->rdma);
+	cmh_complete(&req->base, error);
+}
+
+/*
+ * .digest() -- compute the CMAC over the whole message in a single
+ * hardware transaction:
+ *   SYS_CMD_WRITE(key) + AES_CMD_INIT(CMAC) + AES_CMD_AAD_FINAL_AUTH +
+ *   FLUSH.
+ * The message is linearised into one DMA-mapped buffer.  cmh_aes_cmac_alg
+ * sets CRYPTO_ALG_REQ_VIRT, so the crypto core dispatches both
+ * virtual-address (CRYPTO_AHASH_REQ_VIRT) and scatterlist requests directly
+ * to .digest; the linearisation below handles whichever form arrives.
+ */
+static int cmh_aes_cmac_digest(struct ahash_request *req)
+{
+	struct crypto_ahash *tfm = crypto_ahash_reqtfm(req);
+	struct cmh_aes_cmac_tfm_ctx *tctx = crypto_ahash_ctx(tfm);
+	struct cmh_aes_cmac_reqctx *rctx = ahash_request_ctx(req);
+	struct vcq_cmd cmds[CMH_AES_CMAC_MAX_PAYLOAD];
+	u32 data_len = req->nbytes;
+	u64 key_ref;
+	u32 keylen;
+	struct core_dispatch d;
+	u32 core_id;
+	u32 idx;
+	int ret;
+	gfp_t gfp = req->base.flags & CRYPTO_TFM_REQ_MAY_SLEEP ?
+		   GFP_KERNEL : GFP_ATOMIC;
+
+	memset(rctx, 0, sizeof(*rctx));
+	cmh_req_dma_init(&rctx->rdma);
+
+	if (tctx->key.mode == CMH_KEY_NONE)
+		return -ENOKEY;
+
+	/* Reject an oversized linearisation with a permanent -EMSGSIZE. */
+	if (data_len > KMALLOC_MAX_SIZE)
+		return -EMSGSIZE;
+
+	rctx->in_dma = DMA_MAPPING_ERROR;
+	if (data_len) {
+		rctx->buf = kmalloc(data_len, gfp | __GFP_NOWARN);
+		if (!rctx->buf)
+			return -ENOMEM;
+		if (req->base.flags & CRYPTO_AHASH_REQ_VIRT)
+			memcpy(rctx->buf, req->svirt, data_len);
+		else
+			scatterwalk_map_and_copy(rctx->buf, req->src, 0,
+						 data_len, 0);
+		rctx->in_dma = cmh_req_dma_add(&rctx->rdma, rctx->buf,
+					       data_len, DMA_TO_DEVICE, true);
+		if (cmh_dma_map_error(rctx->in_dma)) {
+			ret = -ENOMEM;
+			goto err_release;
+		}
+	}
+
+	rctx->tag_buf = kzalloc(AES_CMAC_DIGEST_SIZE, gfp);
+	if (!rctx->tag_buf) {
+		ret = -ENOMEM;
+		goto err_release;
+	}
+	rctx->tag_dma = cmh_req_dma_add(&rctx->rdma, rctx->tag_buf,
+					AES_CMAC_DIGEST_SIZE, DMA_FROM_DEVICE,
+					false);
+	if (cmh_dma_map_error(rctx->tag_dma)) {
+		ret = -ENOMEM;
+		goto err_release;
+	}
+
+	d = cmh_core_select_instance(CMH_CORE_AES);
+	core_id = d.core_id;
+	idx = 0;
+
+	vcq_add_sys_write(&cmds[idx++], SYS_REF_TEMP,
+			  (u64)tctx->key.raw.dma, SYS_REF_NONE,
+			  tctx->key.raw.len, tctx->key.raw.sys_type);
+	key_ref = SYS_REF_TEMP;
+	keylen = tctx->key.raw.len;
+
+	/* INIT: mode=CMAC, op=ENCRYPT; data goes through the AAD path. */
+	{
+		struct vcq_cmd *slot = &cmds[idx++];
+
+		memset(slot, 0, sizeof(*slot));
+		slot->magic = VCQ_CMD_MAGIC;
+		slot->id = VCQ_CMD_ID(core_id, 0, 1, AES_CMD_INIT);
+		slot->hwc.aes.cmd_init.key = key_ref;
+		slot->hwc.aes.cmd_init.iv = 0;
+		slot->hwc.aes.cmd_init.keylen = keylen;
+		slot->hwc.aes.cmd_init.ivlen = 0;
+		slot->hwc.aes.cmd_init.mode = AES_MODE_CMAC;
+		slot->hwc.aes.cmd_init.op = AES_OP_ENCRYPT;
+		slot->hwc.aes.cmd_init.aadlen = data_len;
+		slot->hwc.aes.cmd_init.iolen = 0;
+		slot->hwc.aes.cmd_init.taglen = AES_CMAC_DIGEST_SIZE;
+	}
+
+	/* AAD_FINAL_AUTH: final AAD + tag extraction in one atomic step. */
+	{
+		struct vcq_cmd *slot = &cmds[idx++];
+
+		memset(slot, 0, sizeof(*slot));
+		slot->magic = VCQ_CMD_MAGIC;
+		slot->id = VCQ_CMD_ID(core_id, 0, 1, AES_CMD_AAD_FINAL_AUTH);
+		slot->hwc.aes.cmd_aad_final_auth.data =
+			data_len > 0 ? (u64)rctx->in_dma : 0;
+		slot->hwc.aes.cmd_aad_final_auth.datalen = data_len;
+		slot->hwc.aes.cmd_aad_final_auth.tag = (u64)rctx->tag_dma;
+		slot->hwc.aes.cmd_aad_final_auth.taglen = AES_CMAC_DIGEST_SIZE;
+	}
+
+	vcq_add_flush(&cmds[idx++], core_id);
+
+	ret = cmh_vcq_pack_and_submit_async(cmds, idx, rctx->packed,
+					    CMH_AES_CMAC_MAX_PACKED,
+					    d.mbx_idx,
+					    cmh_aes_cmac_complete, req,
+					    &rctx->rdma,
+					    !!(req->base.flags &
+					       CRYPTO_TFM_REQ_MAY_BACKLOG),
+					    cmh_tm_async_timeout_jiffies());
+	if (ret == -EBUSY)
+		return -EBUSY;
+	if (ret)
+		goto err_release;
+
+	return -EINPROGRESS;
+
+err_release:
+	cmh_req_dma_release(&rctx->rdma);
+	return ret;
+}
+
+/*
+ * Incremental operations and request-state export/import forward to the
+ * keyed generic cmac(aes) fallback allocated in cmh_aes_cmac_init_tfm().
+ * The AES core cannot save/restore intermediate CMAC state, so the
+ * fallback holds the request state; it is synchronous, was
+ * keyed by cmh_aes_cmac_setkey(), and handles both scatterlist and
+ * virtual (CRYPTO_AHASH_REQ_VIRT) input.
+ */
+static int cmh_aes_cmac_init(struct ahash_request *req)
+{
+	struct crypto_ahash *tfm = crypto_ahash_reqtfm(req);
+	struct cmh_aes_cmac_tfm_ctx *tctx = crypto_ahash_ctx(tfm);
+	struct cmh_aes_cmac_reqctx *rctx = ahash_request_ctx(req);
+	struct ahash_request *fb_req = cmh_aes_cmac_fb_req(rctx);
+
+	ahash_request_set_tfm(fb_req, tctx->fb);
+	ahash_request_set_callback(fb_req, 0, NULL, NULL);
+	return crypto_ahash_init(fb_req);
+}
+
+static int cmh_aes_cmac_update(struct ahash_request *req)
+{
+	struct cmh_aes_cmac_reqctx *rctx = ahash_request_ctx(req);
+	struct ahash_request *fb_req = cmh_aes_cmac_fb_req(rctx);
+
+	ahash_request_set_callback(fb_req, 0, NULL, NULL);
+	if (req->base.flags & CRYPTO_AHASH_REQ_VIRT)
+		ahash_request_set_virt(fb_req, req->svirt, NULL, req->nbytes);
+	else
+		ahash_request_set_crypt(fb_req, req->src, NULL, req->nbytes);
+	return crypto_ahash_update(fb_req);
+}
+
+static int cmh_aes_cmac_final(struct ahash_request *req)
+{
+	struct cmh_aes_cmac_reqctx *rctx = ahash_request_ctx(req);
+	struct ahash_request *fb_req = cmh_aes_cmac_fb_req(rctx);
+
+	ahash_request_set_callback(fb_req, 0, NULL, NULL);
+	ahash_request_set_crypt(fb_req, NULL, req->result, 0);
+	return crypto_ahash_final(fb_req);
+}
+
+/*
+ * ahash .export()/.import(): serialize/deserialize the fallback
+ * request's state.  No HW state is involved -- the AES core does not
+ * support save/restore.
+ */
+
+static int cmh_aes_cmac_finup(struct ahash_request *req)
+{
+	struct cmh_aes_cmac_reqctx *rctx = ahash_request_ctx(req);
+	struct ahash_request *fb_req = cmh_aes_cmac_fb_req(rctx);
+
+	ahash_request_set_callback(fb_req, 0, NULL, NULL);
+	if (req->base.flags & CRYPTO_AHASH_REQ_VIRT)
+		ahash_request_set_virt(fb_req, req->svirt, req->result,
+				       req->nbytes);
+	else
+		ahash_request_set_crypt(fb_req, req->src, req->result,
+					req->nbytes);
+	return crypto_ahash_finup(fb_req);
+}
+
+static int cmh_aes_cmac_export(struct ahash_request *req, void *out)
+{
+	struct cmh_aes_cmac_reqctx *rctx = ahash_request_ctx(req);
+
+	return crypto_ahash_export(cmh_aes_cmac_fb_req(rctx), out);
+}
+
+static int cmh_aes_cmac_import(struct ahash_request *req, const void *in)
+{
+	struct crypto_ahash *tfm = crypto_ahash_reqtfm(req);
+	struct cmh_aes_cmac_tfm_ctx *tctx = crypto_ahash_ctx(tfm);
+	struct cmh_aes_cmac_reqctx *rctx = ahash_request_ctx(req);
+	struct ahash_request *fb_req = cmh_aes_cmac_fb_req(rctx);
+
+	ahash_request_set_tfm(fb_req, tctx->fb);
+	ahash_request_set_callback(fb_req, 0, NULL, NULL);
+	return crypto_ahash_import(fb_req, in);
+}
+
+static int cmh_aes_cmac_init_tfm(struct crypto_ahash *tfm)
+{
+	struct cmh_aes_cmac_tfm_ctx *tctx = crypto_ahash_ctx(tfm);
+	struct crypto_ahash *fb;
+
+	tctx->key.mode = CMH_KEY_NONE;
+
+	/*
+	 * The generic cmac(aes) shash has no export_core, so the crypto
+	 * core cannot wrap it as crypto_ahash_fb().  Allocate it here
+	 * instead; masking out CRYPTO_ALG_ASYNC excludes this (async)
+	 * driver so the allocator picks the generic, synchronous transform,
+	 * and its request is embedded after the reqctx.
+	 */
+	fb = crypto_alloc_ahash(crypto_ahash_alg_name(tfm), 0,
+				CRYPTO_ALG_ASYNC);
+	if (IS_ERR(fb))
+		return PTR_ERR(fb);
+	tctx->fb = fb;
+
+	crypto_ahash_set_reqsize(tfm,
+				 sizeof(struct cmh_aes_cmac_reqctx) +
+				 crypto_tfm_ctx_alignment() +
+				 sizeof(struct ahash_request) +
+				 crypto_ahash_reqsize(fb));
+	crypto_ahash_set_statesize(tfm, crypto_ahash_statesize(fb));
+	return 0;
+}
+
+static void cmh_aes_cmac_exit_tfm(struct crypto_ahash *tfm)
+{
+	struct cmh_aes_cmac_tfm_ctx *tctx = crypto_ahash_ctx(tfm);
+
+	crypto_free_ahash(tctx->fb);
+	cmh_key_destroy(&tctx->key);
+}
+
+static struct ahash_alg cmh_aes_cmac_alg = {
+	.init		= cmh_aes_cmac_init,
+	.update		= cmh_aes_cmac_update,
+	.final		= cmh_aes_cmac_final,
+	.finup		= cmh_aes_cmac_finup,
+	.digest		= cmh_aes_cmac_digest,
+	.export		= cmh_aes_cmac_export,
+	.import		= cmh_aes_cmac_import,
+	.setkey		= cmh_aes_cmac_setkey,
+	.init_tfm	= cmh_aes_cmac_init_tfm,
+	.exit_tfm	= cmh_aes_cmac_exit_tfm,
+	.halg		= {
+		.digestsize	= AES_CMAC_DIGEST_SIZE,
+		/*
+		 * Placeholder: cmh_aes_cmac_init_tfm() overrides this with
+		 * the software fallback's real state size.  Nonzero and no
+		 * larger than cra_reqsize for registration to pass.
+		 */
+		.statesize	= AES_CMAC_DIGEST_SIZE,
+		.base		= {
+			.cra_name	 = "cmac(aes)",
+			.cra_driver_name = "rambus-cmh-cmac-aes",
+			.cra_priority	 = 300,
+			/*
+			 * Digest-only hardware with a manually-allocated
+			 * generic cmac(aes) fallback.  The generic cmac shash
+			 * has no export_core, so the crypto core cannot
+			 * install it as crypto_ahash_fb(); the driver
+			 * allocates it in .init_tfm() instead (NO_FALLBACK)
+			 * and sets REQ_VIRT to accept and forward
+			 * virtual-address requests itself.  The AES core
+			 * accelerates only the one-shot .digest().
+			 */
+			.cra_flags	 = CRYPTO_ALG_KERN_DRIVER_ONLY |
+					   CRYPTO_ALG_ALLOCATES_MEMORY |
+					   CRYPTO_ALG_ASYNC |
+					   CRYPTO_ALG_NO_FALLBACK |
+					   CRYPTO_ALG_REQ_VIRT,
+			.cra_blocksize	 = AES_CMAC_BLOCK_SIZE,
+			.cra_ctxsize	 = sizeof(struct cmh_aes_cmac_tfm_ctx),
+			.cra_module	 = THIS_MODULE,
+		},
+	},
+};
+
+/**
+ * cmh_aes_cmac_register() - Register AES-CMAC hash algorithm with the crypto framework
+ *
+ * Return: 0 on success, negative errno on failure.
+ */
+int cmh_aes_cmac_register(void)
+{
+	int ret;
+
+	if (!cmh_core_present(CMH_CORE_AES))
+		return 0;
+
+	ret = crypto_register_ahash(&cmh_aes_cmac_alg);
+	if (ret)
+		dev_err(cmh_dev(), "cmh_aes_cmac: failed to register cmac(aes) (rc=%d)\n",
+			ret);
+	else
+		dev_dbg(cmh_dev(), "cmh_aes_cmac: registered cmac(aes)\n");
+
+	return ret;
+}
+
+/**
+ * cmh_aes_cmac_unregister() - Unregister AES-CMAC hash algorithm from the crypto framework
+ */
+void cmh_aes_cmac_unregister(void)
+{
+	if (!cmh_core_present(CMH_CORE_AES))
+		return;
+
+	crypto_unregister_ahash(&cmh_aes_cmac_alg);
+	dev_dbg(cmh_dev(), "cmh_aes_cmac: unregistered cmac(aes)\n");
+}
diff --git a/drivers/crypto/cmh/cmh_main.c b/drivers/crypto/cmh/cmh_main.c
index d02b758cba02..503be0a02bef 100644
--- a/drivers/crypto/cmh/cmh_main.c
+++ b/drivers/crypto/cmh/cmh_main.c
@@ -32,6 +32,7 @@
 #include "cmh_mqi.h"
 #include "cmh_txn.h"
 #include "cmh_rh.h"
+#include "cmh_aes.h"
 #include "cmh_registers.h"
 #include "cmh_debugfs.h"
 #include "cmh_sysfs.h"
@@ -228,10 +229,32 @@ static int cmh_probe(struct platform_device *pdev)
 	if (ret)
 		goto err_rh_init;
 
+	/* Register AES skcipher algorithms */
+	ret = cmh_aes_register();
+	if (ret)
+		goto err_aes_register;
+
+	/* Register AES AEAD algorithms (GCM, CCM) */
+	ret = cmh_aes_aead_register();
+	if (ret)
+		goto err_aes_aead_register;
+
+	/* Register AES CMAC algorithm */
+	ret = cmh_aes_cmac_register();
+	if (ret)
+		goto err_aes_cmac_register;
+
 	platform_set_drvdata(pdev, dev);
 
 	return 0;
 
+err_aes_cmac_register:
+	cmh_aes_aead_unregister();
+err_aes_aead_register:
+	cmh_aes_unregister();
+err_aes_register:
+	cmh_tm_stop();
+	cmh_rh_cleanup(cfg);
 err_rh_init:
 	cmh_tm_cleanup();
 err_tm_init:
@@ -256,6 +279,10 @@ static void cmh_remove(struct platform_device *pdev)
 
 	cfg = &dev->config;
 
+	cmh_aes_cmac_unregister();
+	cmh_aes_aead_unregister();
+	cmh_aes_unregister();
+
 	/*
 	 * Stop the TM producer before the RH state it consults is freed;
 	 * in-flight work completes through the RH until cmh_rh_cleanup().
diff --git a/drivers/crypto/cmh/include/cmh_aes.h b/drivers/crypto/cmh/include/cmh_aes.h
new file mode 100644
index 000000000000..1ae606264ea3
--- /dev/null
+++ b/drivers/crypto/cmh/include/cmh_aes.h
@@ -0,0 +1,24 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- AES Crypto API Drivers
+ *
+ * Registers AES algorithms with the Linux crypto subsystem:
+ *   skcipher: ecb/cbc/ctr/xts(aes)
+ *   aead:     gcm/ccm(aes)
+ *   shash:    cmac(aes)
+ */
+
+#ifndef CMH_AES_H
+#define CMH_AES_H
+
+int  cmh_aes_register(void);
+void cmh_aes_unregister(void);
+
+int  cmh_aes_aead_register(void);
+void cmh_aes_aead_unregister(void);
+
+int  cmh_aes_cmac_register(void);
+void cmh_aes_cmac_unregister(void);
+
+#endif /* CMH_AES_H */
diff --git a/drivers/crypto/cmh/include/cmh_aes_abi.h b/drivers/crypto/cmh/include/cmh_aes_abi.h
new file mode 100644
index 000000000000..0b876dd67773
--- /dev/null
+++ b/drivers/crypto/cmh/include/cmh_aes_abi.h
@@ -0,0 +1,98 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- AES Core ABI Definitions
+ *
+ * Kernel-side definitions for the CMH AES ABI.
+ * All constants and layouts derived from the CMH eSW ABI.
+ */
+
+#ifndef CMH_AES_ABI_H
+#define CMH_AES_ABI_H
+
+#include <linux/types.h>
+
+/* AES Block Size */
+
+#define CMH_AES_BLOCK_SIZE	16U
+#define CMH_AES_IV_SIZE		16U
+
+/* AES Modes (per CMH AES ABI) */
+
+#define AES_MODE_ECB		1U
+#define AES_MODE_CBC		2U
+#define AES_MODE_CTR		3U
+#define AES_MODE_CFB		4U
+#define AES_MODE_GCM		5U
+#define AES_MODE_CMAC		6U
+#define AES_MODE_CCM		7U
+#define AES_MODE_XTS		8U
+
+/* AES Operations (per CMH AES ABI) */
+
+#define AES_OP_DECRYPT		1U
+#define AES_OP_ENCRYPT		2U
+
+/* AES Command IDs */
+
+#define AES_CMD_INIT		0x01U
+#define AES_CMD_AAD_UPDATE	0x02U
+#define AES_CMD_AAD_FINAL	0x03U
+#define AES_CMD_UPDATE		0x04U
+#define AES_CMD_FINAL		0x05U
+#define AES_CMD_SCATTERGATHER	0x06U
+#define AES_CMD_CCM_INIT	0x0AU
+#define AES_CMD_AAD_FINAL_AUTH	0x0EU
+
+/* AES Command Structures */
+
+struct aes_cmd_init {
+	u64 key;	/* datastore reference for the key */
+	u64 iv;		/* DMA address of the IV (or nonce in CCM) */
+	u32 keylen;	/* key length in bytes */
+	u32 ivlen;	/* IV length in bytes (0..16) */
+	u32 mode;	/* AES mode (AES_MODE_*) */
+	u32 op;		/* AES operation (AES_OP_*) */
+	u32 aadlen;	/* AAD length or 0 */
+	u32 iolen;	/* plaintext/ciphertext length */
+	u32 taglen;	/* tag length or 0 */
+	u32 xts_offset;	/* XTS block index j; 0 for the skcipher path */
+};
+
+struct aes_cmd_aad_final {
+	u64 data;	/* DMA address of AAD data */
+	u32 datalen;	/* AAD data length */
+};
+
+struct aes_cmd_aad_final_auth {
+	u64 data;	/* DMA address of final AAD data */
+	u32 datalen;	/* final AAD data length */
+	u64 tag;		/* DMA address of tag */
+	u32 taglen;	/* tag length */
+};
+
+struct aes_cmd_update {
+	u64 input;	/* DMA address of input data */
+	u64 output;	/* DMA address of output data */
+	u32 iolen;	/* input/output data length */
+};
+
+struct aes_cmd_final {
+	u64 input;	/* DMA address of last input data */
+	u64 output;	/* DMA address of last output data */
+	u64 tag;	/* DMA address of tag (AEAD only) */
+	u32 iolen;	/* last input/output data length */
+	u32 taglen;	/* tag length (AEAD only) */
+};
+
+/* AES Command Union */
+
+union aes_cmd {
+	struct aes_cmd_init		cmd_init;
+	struct aes_cmd_update		cmd_update;
+	struct aes_cmd_final		cmd_final;
+	struct aes_cmd_aad_final	cmd_aad_final;
+	struct aes_cmd_aad_final_auth	cmd_aad_final_auth;
+};
+
+#endif /* CMH_AES_ABI_H */
diff --git a/drivers/crypto/cmh/include/cmh_vcq.h b/drivers/crypto/cmh/include/cmh_vcq.h
index c00fa2fdff92..1145009a8329 100644
--- a/drivers/crypto/cmh/include/cmh_vcq.h
+++ b/drivers/crypto/cmh/include/cmh_vcq.h
@@ -26,6 +26,7 @@
 #include <linux/bits.h>
 
 #include "cmh_sys_abi.h"
+#include "cmh_aes_abi.h"
 
 /* VCQ Magic Numbers */
 
@@ -150,6 +151,7 @@ struct dma_scattergather_item {
 union hwc_cmd {
 	struct vcq_hdr          hdr;
 	union sys_cmd           sys;
+	union aes_cmd           aes;
 };
 
 /**

-- 
2.43.7

