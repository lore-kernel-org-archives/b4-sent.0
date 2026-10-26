From: Alex Ousherovitch <aousherovitch@rambus.com>
Date: Mon, 26 Oct 2026 12:44:59 -0700
Subject: [PATCH v7 3/5] crypto: cmh - add key/datastore infrastructure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-cmh-b4-a-v7-v7-3-500a83faf500@rambus.com>
References: <20261026-cmh-b4-a-v7-v7-0-500a83faf500@rambus.com>
In-Reply-To: <20261026-cmh-b4-a-v7-v7-0-500a83faf500@rambus.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793043902; l=28836;
 i=aousherovitch@rambus.com; s=20261026; h=from:subject:message-id;
 bh=vgpCP0rawPcAFCzlZnhlT62diqPDutqAPu+AxkdDqJU=;
 b=HYAfMr+43JIdtzQ3Al+jZVwbYVc32q0Cva3MvV2rtyn36bZ1MEcmHfteEMUAV9CXzEFly6HRR
 /RoTot2hJwFCY7DTyZWoZ9b2dMwn7jqwiCHX2VsdZfJRpDzsVVKqmdr
X-Developer-Key: i=aousherovitch@rambus.com; a=ed25519;
 pk=ECFtTdQUPAolK+qGZ6v7Xm3sRf7rnM7wxpTeFzbqpmA=
X-Endpoint-Received: by B4 Relay for aousherovitch@rambus.com/20261026 with auth_id=1330
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the CMH key and datastore (system object) layer shared by the
algorithm drivers.  cmh_sys.c manages CMH system objects (allocate and
free datastore slots); cmh_key.c stages a raw key into a per-transform
context and DMA-maps it for the lifetime of the transform.

These are used by the symmetric, hash/MAC and asymmetric algorithm
drivers that follow, and by the /dev/cmh_mgmt ioctl device.  No crypto
API algorithm is registered by this patch.

Co-developed-by: Saravanakrishnan Krishnamoorthy <skrishnamoorthy@rambus.com>
Signed-off-by: Saravanakrishnan Krishnamoorthy <skrishnamoorthy@rambus.com>
Signed-off-by: Alex Ousherovitch <aousherovitch@rambus.com>
---
 drivers/crypto/cmh/Makefile          |   4 +-
 drivers/crypto/cmh/cmh_key.c         | 130 ++++++++++++
 drivers/crypto/cmh/cmh_sys.c         | 376 +++++++++++++++++++++++++++++++++++
 drivers/crypto/cmh/include/cmh_key.h |  73 +++++++
 drivers/crypto/cmh/include/cmh_sys.h | 111 +++++++++++
 5 files changed, 693 insertions(+), 1 deletion(-)

diff --git a/drivers/crypto/cmh/Makefile b/drivers/crypto/cmh/Makefile
index 742e65e3917e..485247405cb2 100644
--- a/drivers/crypto/cmh/Makefile
+++ b/drivers/crypto/cmh/Makefile
@@ -12,7 +12,9 @@ cmh-y := \
 	cmh_txn.o \
 	cmh_rh.o \
 	cmh_dma.o \
-	cmh_sysfs.o
+	cmh_sysfs.o \
+	cmh_sys.o \
+	cmh_key.o
 
 ccflags-y += -I$(src)/include
 
diff --git a/drivers/crypto/cmh/cmh_key.c b/drivers/crypto/cmh/cmh_key.c
new file mode 100644
index 000000000000..bb0951deebc6
--- /dev/null
+++ b/drivers/crypto/cmh/cmh_key.c
@@ -0,0 +1,130 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- Dual Key Path Implementation
+ *
+ * Two key provisioning paths are supported:
+ *
+ * Raw key:  key bytes -> stored in tfm context ->
+ *   SYS_CMD_WRITE(SYS_REF_TEMP) packed into every crypto VCQ.
+ *   The raw key buffer is DMA-mapped once at setkey time and remains
+ *   mapped for the lifetime of the transform (unmapped in destroy).
+ *
+ * Raw key DMA lifetime rationale
+ * ------------------------------
+ * Raw keys are DMA-mapped at setkey time and the mapping persists
+ * until the transform is destroyed (cmh_key_destroy).  This is a
+ * deliberate design choice, consistent with upstream HW crypto
+ * drivers (CAAM, ccree, CCP) that also map keys at setkey for
+ * transform-lifetime reuse:
+ *
+ *   - The Linux crypto framework expects setkey to prepare the
+ *     transform for repeated encrypt/decrypt calls.  Remapping the
+ *     same key on every request would add DMA API overhead per crypto
+ *     operation with no security benefit.
+ *   - On destroy, kfree_sensitive() scrubs the key buffer and the
+ *     DMA mapping is released.  For key-by-ID (persistent), the
+ *     per-MBX ref cache is zeroed with memzero_explicit().
+ *   - No key material is ever logged; dev_dbg() messages only show
+ *     CIDs (content identifiers), not key bytes.
+ *
+ * Hardware-required behaviors (not driver policy)
+ * ------------------------------------------------
+ * - SYS_REF_TEMP lifetime:  the eSW firmware reclaims temporary
+ *   datastore objects when the mailbox slot is reused.  This is a
+ *   hardware constraint; the driver packs SYS_CMD_WRITE into every
+ *   VCQ to re-provision the raw key for each operation.
+ * - Mailbox flush (SYS_CMD_FLUSH):  reclaims temp-stack space on the
+ *   target MBX.  Required by HW to prevent temp-stack exhaustion
+ *   across multi-VCQ operations.
+ *
+ * Net-zero temp invariant (driver policy that MUST hold)
+ * ------------------------------------------------------
+ * Each crypto VCQ stages its raw key with SYS_CMD_WRITE(SYS_REF_TEMP) and
+ * consumes it in the SAME VCQ (the core key-load drops it on use), leaving
+ * the mailbox temporary memory unchanged.  These VCQs can share the mgmt
+ * mailbox (MBX 0) with /dev/cmh_mgmt cross-VCQ keys; that memory is a
+ * per-mailbox stack that persists until it is freed (by a SYS flush or
+ * MBX_COMMAND_FLUSH), so an op that left a temp object behind would
+ * march toward -ENOMEM and could shadow a live mgmt key.  Never carry
+ * SYS_REF_TEMP across VCQs outside the mgmt path.
+ */
+
+#include <linux/kernel.h>
+#include <linux/slab.h>
+#include <linux/string.h>
+
+#include "cmh_key.h"
+#include "cmh_sys.h"
+#include "cmh_txn.h"
+#include "cmh_dma.h"
+#include "cmh_sys_abi.h"
+
+/**
+ * cmh_key_setkey_raw() - Store a raw key in the key context
+ * @ctx: Key context to populate
+ * @key: Pointer to the raw key bytes
+ * @keylen: Length of @key in bytes
+ * @core_id: Logical core ID for SYS_TYPE tagging
+ *
+ * Duplicates the raw key, DMA-maps the copy for the lifetime of the
+ * transform, and stores the mapping in @ctx.  Any previously held key
+ * is destroyed first.
+ *
+ * The DMA mapping persists until cmh_key_destroy() is called (typically
+ * from the algorithm .exit_tfm callback).  This avoids per-request DMA
+ * mapping overhead and matches the setkey-to-destroy lifetime model used
+ * by other upstream HW crypto drivers (CAAM, ccree, CCP).  The key
+ * buffer is freed via kfree_sensitive() on destroy.
+ *
+ * Return: 0 on success, negative errno on failure.
+ */
+int cmh_key_setkey_raw(struct cmh_key_ctx *ctx, const u8 *key,
+		       u32 keylen, u32 core_id)
+{
+	dma_addr_t dma;
+	u8 *copy;
+
+	if (!keylen || !key)
+		return -EINVAL;
+
+	copy = kmemdup(key, keylen, GFP_KERNEL);
+	if (!copy)
+		return -ENOMEM;
+
+	/* Pre-map for the lifetime of the transform */
+	dma = cmh_dma_map_single(copy, keylen, DMA_TO_DEVICE);
+	if (cmh_dma_map_error(dma)) {
+		kfree_sensitive(copy);
+		return -ENOMEM;
+	}
+
+	/* Clean up any previous key */
+	cmh_key_destroy(ctx);
+
+	ctx->mode = CMH_KEY_RAW;
+	ctx->raw.data = copy;
+	ctx->raw.len = keylen;
+	ctx->raw.dma = dma;
+	ctx->raw.sys_type = SYS_TYPE_SET(SYS_TYPE_FLAG_PT, core_id);
+
+	return 0;
+}
+
+/**
+ * cmh_key_destroy() - Destroy and zero-fill a key context
+ * @ctx: Key context to destroy
+ *
+ * For raw keys, unmaps the DMA buffer and securely frees the key material.
+ * Resets the key mode to CMH_KEY_NONE.
+ */
+void cmh_key_destroy(struct cmh_key_ctx *ctx)
+{
+	if (ctx->mode == CMH_KEY_RAW && ctx->raw.data) {
+		cmh_dma_unmap_single(ctx->raw.dma, ctx->raw.len,
+				     DMA_TO_DEVICE);
+		kfree_sensitive(ctx->raw.data);
+		memzero_explicit(&ctx->raw, sizeof(ctx->raw));
+	}
+	ctx->mode = CMH_KEY_NONE;
+}
diff --git a/drivers/crypto/cmh/cmh_sys.c b/drivers/crypto/cmh/cmh_sys.c
new file mode 100644
index 000000000000..b01d058e6d89
--- /dev/null
+++ b/drivers/crypto/cmh/cmh_sys.c
@@ -0,0 +1,376 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- SYS Core VCQ Builders
+ *
+ * VCQ builder functions for SYS core datastore commands.  Each function
+ * populates a single vcq_cmd slot.  Callers (cmh_mgmt.c, cmh_key.c)
+ * assemble complete VCQs by combining header + command(s) + flush,
+ * then submit via cmh_tm_submit_sync().
+ *
+ * Hardware-required datastore semantics
+ * --------------------------------------
+ * The commands below (NEW, WRITE, DATA, FIND, DELETE, FLUSH) are
+ * direct mappings of the eSW firmware SYS core command set.  The
+ * eSW maintains per-mailbox datastore namespaces with two object
+ * classes:
+ *
+ *   SYS_REF_TEMP   -- Temporary objects.  Lifetime is scoped to the
+ *                      current mailbox slot; reclaimed automatically
+ *                      when the slot is reused or on explicit FLUSH.
+ *                      Used for raw-key provisioning on every VCQ.
+ *
+ *   SYS_REF_PERSIST -- Persistent objects.  Survive across slots;
+ *                      require explicit DELETE to reclaim.  Identified
+ *                      by a 64-bit Content ID (CID) and resolved to
+ *                      a per-MBX ref via SYS_CMD_FIND.
+ *
+ * These semantics are hardware requirements, not driver policy.
+ * The per-MBX temp-stack and per-MBX ref namespace are eSW firmware
+ * design constraints that cannot be changed by the kernel driver.
+ */
+
+#include <linux/string.h>
+
+#include "cmh_sys.h"
+
+/**
+ * vcq_add_sys_flush() - Build a SYS_FLUSH VCQ command
+ * @slot: VCQ command slot to populate
+ */
+void vcq_add_sys_flush(struct vcq_cmd *slot)
+{
+	vcq_add_flush(slot, CORE_ID_SYS);
+}
+
+/**
+ * vcq_add_sys_new() - Build a SYS_NEW VCQ command
+ * @slot: VCQ command slot to populate
+ * @cid: Content identifier for the new datastore object
+ * @ref_dma: DMA address of the object reference buffer
+ * @len: Length of the object data in bytes
+ */
+void vcq_add_sys_new(struct vcq_cmd *slot, u64 cid, u64 ref_dma, u32 len)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(CORE_ID_SYS, 0, 1, SYS_CMD_NEW);
+	slot->hwc.sys.cmd_new.cid = cid;
+	slot->hwc.sys.cmd_new.ref = ref_dma;
+	slot->hwc.sys.cmd_new.len = len;
+}
+
+/**
+ * vcq_add_sys_write() - Build a SYS_WRITE VCQ command
+ * @slot: VCQ command slot to populate
+ * @ref: Datastore object reference handle
+ * @src_dma: DMA address of source data buffer
+ * @wrap_key: Wrapping key reference (0 if none)
+ * @len: Length of data to write in bytes
+ * @sys_type: Datastore object type identifier
+ */
+void vcq_add_sys_write(struct vcq_cmd *slot, u64 ref, u64 src_dma,
+		       u64 wrap_key, u32 len, u32 sys_type)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(CORE_ID_SYS, 0, 1, SYS_CMD_WRITE);
+	slot->hwc.sys.cmd_write.ref = ref;
+	slot->hwc.sys.cmd_write.src = src_dma;
+	slot->hwc.sys.cmd_write.key = wrap_key;
+	slot->hwc.sys.cmd_write.len = len;
+	slot->hwc.sys.cmd_write.type = sys_type;
+}
+
+/**
+ * vcq_add_sys_read() - Build a SYS_READ VCQ command
+ * @slot: VCQ command slot to populate
+ * @ref: Datastore object reference handle
+ * @dst_dma: DMA address of destination buffer
+ * @wrap_key: Wrapping key reference (0 if none)
+ * @len: Length of data to read in bytes
+ */
+void vcq_add_sys_read(struct vcq_cmd *slot, u64 ref, u64 dst_dma,
+		      u64 wrap_key, u32 len)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(CORE_ID_SYS, 0, 1, SYS_CMD_READ);
+	slot->hwc.sys.cmd_read.ref = ref;
+	slot->hwc.sys.cmd_read.dst = dst_dma;
+	slot->hwc.sys.cmd_read.key = wrap_key;
+	slot->hwc.sys.cmd_read.len = len;
+}
+
+/**
+ * vcq_add_sys_data() - Build a SYS_DATA VCQ command
+ * @slot: VCQ command slot to populate
+ * @ref: Datastore object reference handle
+ * @dst_dma: DMA address of destination buffer
+ * @len: Length of data section to read in bytes
+ */
+void vcq_add_sys_data(struct vcq_cmd *slot, u64 ref, u64 dst_dma, u32 len)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(CORE_ID_SYS, 0, 1, SYS_CMD_DATA);
+	slot->hwc.sys.cmd_data.ref = ref;
+	slot->hwc.sys.cmd_data.dst = dst_dma;
+	slot->hwc.sys.cmd_data.len = len;
+}
+
+/**
+ * vcq_add_sys_find() - Build a SYS_FIND VCQ command
+ * @slot: VCQ command slot to populate
+ * @cid: Content identifier to search for
+ * @dst_dma: DMA address of destination buffer for result
+ * @len: Length of destination buffer in bytes
+ */
+void vcq_add_sys_find(struct vcq_cmd *slot, u64 cid, u64 dst_dma, u32 len)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(CORE_ID_SYS, 0, 1, SYS_CMD_FIND);
+	slot->hwc.sys.cmd_find.cid = cid;
+	slot->hwc.sys.cmd_find.dst = dst_dma;
+	slot->hwc.sys.cmd_find.len = len;
+}
+
+/**
+ * vcq_add_sys_list() - Build a SYS_LIST VCQ command
+ * @slot: VCQ command slot to populate
+ * @ref: Datastore object reference for enumeration start
+ * @dst_dma: DMA address of destination buffer for list
+ * @len: Length of destination buffer in bytes
+ */
+void vcq_add_sys_list(struct vcq_cmd *slot, u64 ref, u64 dst_dma, u32 len)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(CORE_ID_SYS, 0, 1, SYS_CMD_LIST);
+	slot->hwc.sys.cmd_list.ref = ref;
+	slot->hwc.sys.cmd_list.dst = dst_dma;
+	slot->hwc.sys.cmd_list.len = len;
+}
+
+/**
+ * vcq_add_sys_grant() - Build a SYS_GRANT VCQ command
+ * @slot: VCQ command slot to populate
+ * @ref: Datastore object reference handle
+ * @read: Read permission bitmask
+ * @write: Write permission bitmask
+ * @execute: Execute permission bitmask
+ */
+void vcq_add_sys_grant(struct vcq_cmd *slot, u64 ref, u64 read,
+		       u64 write, u64 execute)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(CORE_ID_SYS, 0, 1, SYS_CMD_GRANT);
+	slot->hwc.sys.cmd_grant.ref = ref;
+	slot->hwc.sys.cmd_grant.read = read;
+	slot->hwc.sys.cmd_grant.write = write;
+	slot->hwc.sys.cmd_grant.execute = execute;
+}
+
+/**
+ * vcq_add_sys_export() - Build a SYS_EXPORT VCQ command
+ * @slot: VCQ command slot to populate
+ * @cid: Content identifier of object to export
+ * @dst_dma: DMA address of destination buffer for wrapped blob
+ * @wrap_key: Wrapping key reference for export
+ * @len: Length of destination buffer in bytes
+ */
+void vcq_add_sys_export(struct vcq_cmd *slot, u64 cid, u64 dst_dma,
+			u64 wrap_key, u32 len)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(CORE_ID_SYS, 0, 1, SYS_CMD_EXPORT);
+	slot->hwc.sys.cmd_export.cid = cid;
+	slot->hwc.sys.cmd_export.dst = dst_dma;
+	slot->hwc.sys.cmd_export.key = wrap_key;
+	slot->hwc.sys.cmd_export.len = len;
+}
+
+/**
+ * vcq_add_sys_import() - Build a SYS_IMPORT VCQ command
+ * @slot: VCQ command slot to populate
+ * @src_dma: DMA address of wrapped datastore blob to import
+ * @wrap_key: Wrapping key reference for unwrapping
+ * @len: Length of wrapped blob in bytes
+ */
+void vcq_add_sys_import(struct vcq_cmd *slot, u64 src_dma,
+			u64 wrap_key, u32 len)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(CORE_ID_SYS, 0, 1, SYS_CMD_IMPORT);
+	slot->hwc.sys.cmd_import.src = src_dma;
+	slot->hwc.sys.cmd_import.key = wrap_key;
+	slot->hwc.sys.cmd_import.len = len;
+}
+
+/* -- KIC Core VCQ Builders --------------------- */
+
+/**
+ * vcq_add_kic_hkdf1() - Build a KIC HKDF-Expand VCQ command
+ * @slot: VCQ command slot to populate
+ * @dst: Datastore reference for derived key output
+ * @base: Datastore reference for base key input
+ * @label_dma: DMA address of HKDF label/info buffer
+ * @key_len: Derived key length in bytes
+ * @label_len: Length of label buffer in bytes
+ * @type: Derived key datastore type
+ */
+void vcq_add_kic_hkdf1(struct vcq_cmd *slot, u64 dst, u64 base,
+		       u64 label_dma, u32 key_len, u32 label_len, u32 type)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(CORE_ID_KIC, 0, 1, KIC_CMD_HKDF1);
+	slot->hwc.kic.cmd_hkdf1.dst = dst;
+	slot->hwc.kic.cmd_hkdf1.base = base;
+	slot->hwc.kic.cmd_hkdf1.label = label_dma;
+	slot->hwc.kic.cmd_hkdf1.llen = label_len;
+	slot->hwc.kic.cmd_hkdf1.len = key_len;
+	slot->hwc.kic.cmd_hkdf1.type = type;
+}
+
+/**
+ * vcq_add_kic_hkdf2() - Build a KIC HKDF-with-salt VCQ command
+ * @slot: VCQ command slot to populate
+ * @dst: Datastore reference for derived key output
+ * @base: Datastore reference for base key input
+ * @salt: Datastore reference for HKDF salt key
+ * @label_dma: DMA address of HKDF label/info buffer
+ * @key_len: Derived key length in bytes
+ * @label_len: Length of label buffer in bytes
+ * @type: Derived key datastore type
+ */
+void vcq_add_kic_hkdf2(struct vcq_cmd *slot, u64 dst, u64 base, u64 salt,
+		       u64 label_dma, u32 key_len, u32 label_len, u32 type)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(CORE_ID_KIC, 0, 1, KIC_CMD_HKDF2);
+	slot->hwc.kic.cmd_hkdf2.dst = dst;
+	slot->hwc.kic.cmd_hkdf2.base = base;
+	slot->hwc.kic.cmd_hkdf2.salt = salt;
+	slot->hwc.kic.cmd_hkdf2.label = label_dma;
+	slot->hwc.kic.cmd_hkdf2.llen = label_len;
+	slot->hwc.kic.cmd_hkdf2.len = key_len;
+	slot->hwc.kic.cmd_hkdf2.type = type;
+}
+
+/**
+ * vcq_add_kic_aes_cmac_kdf() - Build a KIC AES-CMAC KDF VCQ command
+ * @slot: VCQ command slot to populate
+ * @out_key: Datastore reference for derived key output
+ * @base_key: Datastore reference for base key input
+ * @label_dma: DMA address of KDF label buffer
+ * @key_len: Derived key length in bytes
+ * @label_len: Length of label buffer in bytes
+ * @type: Derived key datastore type
+ */
+void vcq_add_kic_aes_cmac_kdf(struct vcq_cmd *slot, u64 out_key, u64 base_key,
+			      u64 label_dma, u32 key_len, u32 label_len,
+			      u32 type)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(CORE_ID_KIC, 0, 1, KIC_CMD_AES_CMAC_KDF);
+	slot->hwc.kic.cmd_aes_cmac_kdf.base_key = base_key;
+	slot->hwc.kic.cmd_aes_cmac_kdf.out_key = out_key;
+	slot->hwc.kic.cmd_aes_cmac_kdf.label = label_dma;
+	slot->hwc.kic.cmd_aes_cmac_kdf.key_len = key_len;
+	slot->hwc.kic.cmd_aes_cmac_kdf.label_len = label_len;
+	slot->hwc.kic.cmd_aes_cmac_kdf.type = type;
+}
+
+/**
+ * vcq_add_kic_dkek_derive() - Build a KIC DKEK derivation VCQ command
+ * @slot: VCQ command slot to populate
+ * @out_key: Datastore reference for derived DKEK output
+ * @base_key: Datastore reference for base key input
+ * @host_id: Host identifier for key binding
+ * @metadata_dma: DMA address of derivation metadata buffer
+ * @metadata_len: Length of metadata buffer in bytes
+ */
+void vcq_add_kic_dkek_derive(struct vcq_cmd *slot, u64 out_key, u64 base_key,
+			     u32 host_id, u64 metadata_dma, u32 metadata_len)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(CORE_ID_KIC, 0, 1, KIC_CMD_DKEK_DERIVE);
+	slot->hwc.kic.cmd_dkek_derive.base_key = base_key;
+	slot->hwc.kic.cmd_dkek_derive.out_key = out_key;
+	slot->hwc.kic.cmd_dkek_derive.host_id = host_id;
+	slot->hwc.kic.cmd_dkek_derive.metadata = metadata_dma;
+	slot->hwc.kic.cmd_dkek_derive.metadata_len = metadata_len;
+}
+
+/* -- DRBG Core VCQ Builders -------------------- */
+
+/**
+ * vcq_add_drbg_reset() - Build a DRBG reset VCQ command
+ * @slot: VCQ command slot to populate
+ *
+ * Issues DRBG_CMD_RESET which clears the instantiated state, allowing
+ * a subsequent CONFIG to proceed without a double-instantiate error.
+ */
+void vcq_add_drbg_reset(struct vcq_cmd *slot)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(CORE_ID_DRBG, 0, 1, DRBG_CMD_RESET);
+}
+
+/**
+ * vcq_add_drbg_config() - Build a DRBG configuration VCQ command
+ * @slot: VCQ command slot to populate
+ * @ratio: Entropy-to-output ratio
+ * @strength: Security strength in bits
+ */
+void vcq_add_drbg_config(struct vcq_cmd *slot, u32 ratio, u32 strength)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(CORE_ID_DRBG, 0, 1, DRBG_CMD_CONFIG);
+	slot->hwc.drbg.cmd_config.entropy_ratio = ratio;
+	slot->hwc.drbg.cmd_config.security_strength = strength;
+}
+
+/**
+ * vcq_add_drbg_datastore() - Build a DRBG datastore setup VCQ command
+ * @slot: VCQ command slot to populate
+ * @ref: Datastore object reference handle
+ * @len: Length of datastore allocation in bytes
+ * @type: Datastore object type
+ */
+void vcq_add_drbg_datastore(struct vcq_cmd *slot, u64 ref, u32 len, u32 type)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(CORE_ID_DRBG, 0, 1, DRBG_CMD_DATASTORE);
+	slot->hwc.drbg.cmd_datastore.ref = ref;
+	slot->hwc.drbg.cmd_datastore.len = len;
+	slot->hwc.drbg.cmd_datastore.type = type;
+}
+
+/* -- EAC Core VCQ Builder ---------------------- */
+
+/**
+ * vcq_add_eac_read() - Build an EAC read VCQ command
+ * @slot: VCQ command slot to populate
+ * @dst_dma: DMA address of destination buffer
+ * @len: Length of data to read in bytes
+ */
+void vcq_add_eac_read(struct vcq_cmd *slot, u64 dst_dma, u32 len)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(CORE_ID_EAC, 0, 1, EAC_CMD_READ);
+	slot->hwc.eac.cmd_read.dst = dst_dma;
+	slot->hwc.eac.cmd_read.len = len;
+}
diff --git a/drivers/crypto/cmh/include/cmh_key.h b/drivers/crypto/cmh/include/cmh_key.h
new file mode 100644
index 000000000000..6591f120a85e
--- /dev/null
+++ b/drivers/crypto/cmh/include/cmh_key.h
@@ -0,0 +1,73 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- Per-transform key context
+ *
+ * Per-transform key context used by all keyed crypto algorithms (AES,
+ * SM4, CCP, HMAC, KMAC).  Stores raw key bytes supplied via the crypto
+ * API .setkey() callback: the key is DMA-mapped once at setkey time and
+ * written to SYS_REF_TEMP in every VCQ.
+ *
+ * Each keyed algorithm driver embeds a struct cmh_key_ctx in its
+ * per-transform context and calls cmh_key_setkey_raw() from its
+ * .setkey() callback.
+ *
+ * Raw-key atomicity (SYS_REF_TEMP)
+ * ---------------------------------
+ * SYS_CMD_WRITE to SYS_REF_TEMP is packed into the same VCQ as the
+ * algorithm commands (AES_CMD_INIT, HC_CMD_HMAC, etc.).  SYS_REF_TEMP
+ * is per-MBX -- the CMH eSW allocates it in the tail of each mailbox's
+ * own VCQ buffer (mbx_alloc_temp), so concurrent raw-key requests on
+ * different MBXes do not interfere.
+ */
+
+#ifndef CMH_KEY_H
+#define CMH_KEY_H
+
+#include <linux/types.h>
+#include "cmh_config.h"
+#include "cmh_vcq.h"
+
+/* Key context mode */
+enum cmh_key_mode {
+	CMH_KEY_NONE = 0,	/* no key set yet */
+	CMH_KEY_RAW,		/* raw key bytes in memory */
+};
+
+/* Per-transform key context */
+struct cmh_key_ctx {
+	enum cmh_key_mode mode;
+	struct {
+		u8 *data;	/* kmemdup'd raw key bytes */
+		u32 len;	/* key length in bytes */
+		u32 sys_type;	/* SYS_TYPE_SET(flags, core_id) */
+		dma_addr_t dma;	/* pre-mapped DMA addr (DMA_TO_DEVICE) */
+	} raw;
+};
+
+/**
+ * cmh_key_setkey_raw() - Store raw key bytes in the transform context
+ * @ctx: Per-transform key context
+ * @key: Raw key bytes
+ * @keylen: Key length in bytes
+ * @core_id: Target algorithm core (e.g. CORE_ID_AES)
+ *
+ * SYS_TYPE_FLAG_PT is set so the written temp key
+ * can be read back as plaintext if needed.  The actual SYS_CMD_WRITE
+ * to SYS_REF_TEMP is deferred to each encrypt/decrypt VCQ, where it
+ * is packed inline for atomicity.
+ *
+ * Return: 0 on success, -ENOMEM on allocation failure.
+ */
+int cmh_key_setkey_raw(struct cmh_key_ctx *ctx, const u8 *key,
+		       u32 keylen, u32 core_id);
+
+/**
+ * cmh_key_destroy() - Free key resources
+ * @ctx: Per-transform key context
+ *
+ * Zeroises and frees the raw key buffer.
+ */
+void cmh_key_destroy(struct cmh_key_ctx *ctx);
+
+#endif /* CMH_KEY_H */
diff --git a/drivers/crypto/cmh/include/cmh_sys.h b/drivers/crypto/cmh/include/cmh_sys.h
new file mode 100644
index 000000000000..47c19e2f72a9
--- /dev/null
+++ b/drivers/crypto/cmh/include/cmh_sys.h
@@ -0,0 +1,111 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- SYS Core VCQ Builders
+ *
+ * VCQ builder functions for SYS core commands (NEW, WRITE, READ,
+ * FIND, GRANT, DATA, EXPORT, IMPORT).  Each builder populates one
+ * vcq_cmd slot with the appropriate magic, command ID, and payload.
+ *
+ * Callers combine these with vcq_set_header() + vcq_add_flush()
+ * and submit via cmh_tm_submit_sync().
+ */
+
+#ifndef CMH_SYS_H
+#define CMH_SYS_H
+
+#include "cmh_vcq.h"
+
+void vcq_add_sys_new(struct vcq_cmd *slot, u64 cid, u64 ref_dma, u32 len);
+void vcq_add_sys_write(struct vcq_cmd *slot, u64 ref, u64 src_dma,
+		       u64 wrap_key, u32 len, u32 sys_type);
+void vcq_add_sys_read(struct vcq_cmd *slot, u64 ref, u64 dst_dma,
+		      u64 wrap_key, u32 len);
+void vcq_add_sys_data(struct vcq_cmd *slot, u64 ref, u64 dst_dma, u32 len);
+void vcq_add_sys_find(struct vcq_cmd *slot, u64 cid, u64 dst_dma, u32 len);
+void vcq_add_sys_list(struct vcq_cmd *slot, u64 ref, u64 dst_dma, u32 len);
+void vcq_add_sys_grant(struct vcq_cmd *slot, u64 ref, u64 read,
+		       u64 write, u64 execute);
+void vcq_add_sys_export(struct vcq_cmd *slot, u64 cid, u64 dst_dma,
+			u64 wrap_key, u32 len);
+void vcq_add_sys_import(struct vcq_cmd *slot, u64 src_dma,
+			u64 wrap_key, u32 len);
+
+/* KIC core VCQ builders */
+void vcq_add_kic_hkdf1(struct vcq_cmd *slot, u64 dst, u64 base,
+		       u64 label_dma, u32 key_len, u32 label_len, u32 type);
+void vcq_add_kic_hkdf2(struct vcq_cmd *slot, u64 dst, u64 base, u64 salt,
+		       u64 label_dma, u32 key_len, u32 label_len, u32 type);
+void vcq_add_kic_aes_cmac_kdf(struct vcq_cmd *slot, u64 out_key, u64 base_key,
+			      u64 label_dma, u32 key_len, u32 label_len,
+			      u32 type);
+void vcq_add_kic_dkek_derive(struct vcq_cmd *slot, u64 out_key, u64 base_key,
+			     u32 host_id, u64 metadata_dma, u32 metadata_len);
+
+/* DRBG core VCQ builders */
+void vcq_add_drbg_reset(struct vcq_cmd *slot);
+void vcq_add_drbg_config(struct vcq_cmd *slot, u32 ratio, u32 strength);
+void vcq_add_drbg_datastore(struct vcq_cmd *slot, u64 ref, u32 len, u32 type);
+
+/* QSE core VCQ builders */
+void vcq_add_qse_flush(struct vcq_cmd *slot, u32 core_id);
+void vcq_add_qse_ml_kem_keygen(struct vcq_cmd *slot, u32 core_id, u32 k, u32 flags,
+			       u64 seed, u64 z, u64 ek, u64 dk, u32 dk_type,
+			       bool masked);
+void vcq_add_qse_ml_kem_enc(struct vcq_cmd *slot, u32 core_id, u32 k, u32 flags,
+			    u64 coin, u64 ek, u64 ct, u64 ss, u32 ss_type,
+			    bool masked);
+void vcq_add_qse_ml_kem_dec(struct vcq_cmd *slot, u32 core_id, u32 k, u32 flags,
+			    u64 ct, u64 dk, u64 ss, u32 ss_type,
+			    bool masked);
+void vcq_add_qse_ml_dsa_keygen(struct vcq_cmd *slot, u32 core_id, u32 mode, u32 flags,
+			       u64 seed, u64 pk, u64 sk, u32 sk_type,
+			       bool masked);
+void vcq_add_qse_ml_dsa_sign(struct vcq_cmd *slot, u32 core_id, u32 mode, u32 flags,
+			     u64 rnd, u64 m, u64 sk, u64 sig, u32 mlen,
+			     bool masked);
+void vcq_add_qse_ml_dsa_verify(struct vcq_cmd *slot, u32 core_id, u32 mode, u32 flags,
+			       u64 m, u64 pk, u64 sig, u32 mlen);
+
+/* HCQ core VCQ builders */
+void vcq_add_hcq_flush(struct vcq_cmd *slot, u32 core_id);
+void vcq_add_hcq_slhdsa_keygen(struct vcq_cmd *slot, u32 core_id, u32 param_set,
+			       u32 seed_len, u32 pk_len, u32 sk_len,
+			       u64 seed, u64 pk, u64 sk, u32 sk_type);
+void vcq_add_hcq_slhdsa_sign(struct vcq_cmd *slot, u32 core_id, u32 param_set,
+			     u32 msg_len, u32 ctx_len,
+			     u64 add_random, u64 msg, u64 ctx,
+			     u64 sk, u64 sig);
+void vcq_add_hcq_slhdsa_sign_internal(struct vcq_cmd *slot, u32 core_id, u32 param_set,
+				      u32 msg_len, u64 add_random,
+				      u64 msg, u64 sk, u64 sig);
+void vcq_add_hcq_slhdsa_verify(struct vcq_cmd *slot, u32 core_id, u32 param_set,
+			       u32 msg_len, u32 ctx_len,
+			       u64 msg, u64 ctx, u64 pk, u64 sig);
+void vcq_add_hcq_slhdsa_sign_prehash(struct vcq_cmd *slot, u32 core_id,
+				     u32 cmd, u32 param_set, u32 prehash_algo,
+				     u32 msg_len, u32 ctx_len,
+				     u64 add_random, u64 msg, u64 ctx,
+				     u64 sk, u64 sig);
+void vcq_add_hcq_slhdsa_verify_prehash(struct vcq_cmd *slot, u32 core_id,
+				       u32 cmd, u32 param_set, u32 prehash_algo,
+				       u32 msg_len, u32 ctx_len,
+				       u64 msg, u64 ctx, u64 pk, u64 sig);
+void vcq_add_hcq_slhdsa_verify_internal(struct vcq_cmd *slot, u32 core_id, u32 param_set,
+					u32 msg_len, u64 msg, u64 pk, u64 sig);
+void vcq_add_hcq_slhdsa_pubgen(struct vcq_cmd *slot, u32 core_id, u32 param_set,
+			       u32 sk_len, u64 sk, u64 pk);
+void vcq_add_hcq_lms_verify(struct vcq_cmd *slot, u32 core_id, u32 lms_hss,
+			    u32 pk_len, u32 sig_len, u32 msg_len,
+			    u64 pk, u64 sig, u64 msg);
+void vcq_add_hcq_xmss_verify(struct vcq_cmd *slot, u32 core_id, u32 xmss_mt,
+			     u32 pk_len, u32 sig_len, u32 msg_len,
+			     u64 pk, u64 sig, u64 msg);
+
+/* SYS core flush */
+void vcq_add_sys_flush(struct vcq_cmd *slot);
+
+/* EAC core VCQ builder */
+void vcq_add_eac_read(struct vcq_cmd *slot, u64 dst_dma, u32 len);
+
+#endif /* CMH_SYS_H */

-- 
2.43.7

