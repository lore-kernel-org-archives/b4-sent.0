From: "Pankaj Gupta (OSS)" <pankaj.gupta@oss.nxp.com>
Date: Mon, 17 Aug 2026 19:36:03 +0530
Subject: [PATCH v36 5/7] firmware: imx: adds miscdev
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260817-imx-se-if-v36-5-45c42847bfd8@oss.nxp.com>
References: <20260817-imx-se-if-v36-0-45c42847bfd8@oss.nxp.com>
In-Reply-To: <20260817-imx-se-if-v36-0-45c42847bfd8@oss.nxp.com>
To: Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Frank Li <Frank.Li@nxp.com>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Pankaj Gupta <pankaj.gupta@nxp.com>
Cc: linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, sashiko-bot <sashiko-bot@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786975564; l=150270;
 i=pankaj.gupta@oss.nxp.com; s=20260817; h=from:subject:message-id;
 bh=vrV+uvXX4n30qsT+7vjj/BqkoOt3vMUlE02ZOk7JaDA=;
 b=n8hKPElhzn/YNsXFuGwNFT4oXbPdfAQCIWr+JxoN5BUL5m40V58NmiLabS1pR6Q8b06BiWFHu
 bFByrACFJ9EAOuC96e0Ozkg9iQvfqoZgv1DK/Oy95KlLxVbgixHCyyK
X-Developer-Key: i=pankaj.gupta@oss.nxp.com; a=ed25519;
 pk=g4ZgzIWbpXnSxRsoH+l6PWLP78a+Mzpl8e6RQe74d5Y=
X-Endpoint-Received: by B4 Relay for pankaj.gupta@oss.nxp.com/20260817 with auth_id=955
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Pankaj Gupta <pankaj.gupta@nxp.com>

Adds the driver for communication interface to secure-enclave, that
enables exchanging messages with NXP secure enclave HW IP(s)
like EdgeLock Enclave, from:
- User-Space Applications via character driver.

ABI documentation for the NXP secure-enclave driver.

User-space library using this driver:
- i.MX Secure Enclave library:
  -- URL: https://github.com/nxp-imx/imx-secure-enclave.git,
- i.MX Secure Middle-Ware:
  -- URL: https://github.com/nxp-imx/imx-smw.git

Following checks are performed on the incoming msg-header,
to block exchanging invalid arbitrary commands:
- maximum allowed words,
- check if command-tag & response-tag are valid
- version,
- command id validation check, to allow limited base-line API(s)
  and restrict following:
  - exchanging power management commands.
  - reset requests.
  - BBSM configuration requests.
  - re-initializing the FW.
  - RNG init
  - CAAM resource release management
  - SE's internal memory management.
from user-space.

Signed-off-by: Pankaj Gupta <pankaj.gupta@nxp.com>
---
Changes from v35 to v36:

1. [High] Session/storage handle leaked when the response copy-out
   failed.
   se_ioctl_cmd_snd_rcv_rsp_handler() ran fw_api_specific_ops() - which
   records the FW-allocated session/storage handle carried in the
   response - only at the very end, after se_dev_ctx_cpy_out_data() and
   copy_to_user(). If the caller supplied a bad output pointer those
   copy-out steps failed and the handler returned early, so a handle the
   firmware had already committed was never recorded. cleanup_dev_ctx()
   could then never close it and the handle leaked in FW. Record the
   handle first: call fw_api_specific_ops() at the top of the
   well-formed-response block, before the copy-out steps, so the handle
   is tracked (and closed on teardown) regardless of a later copy-out
   failure.

2. [High] close() racing driver unbind could transmit on a freed mailbox
   tx channel.
   ele_msg_send_rcv() checks going_away and arms the transaction under
   clbk_rx_lock, but mbox_send_message() on priv->tx_chan runs after that
   spinlock is dropped. A sender that passed the going_away check just
   before se_if_probe_cleanup() set it could still be inside
   mbox_send_message() when teardown freed tx_chan - a use-after-free in
   the mailbox layer. Teardown deliberately does not hold se_if_cmd_lock
   across the whole unbind (that would stall it for a full receive
   timeout), so add a short drain barrier instead: after the device
   context list has been cleaned up, acquire and immediately release
   se_if_cmd_lock before mbox_free_channel(). going_away is already set
   and complete_all() has already fired, so any in-flight transaction
   unwinds to -ENODEV and drops the lock promptly; the barrier cannot
   stall unbind for a timeout and cannot deadlock. After it, no sender
   can be inside mbox_send_message(), so freeing the channels is safe.

3. [High] A signal during the long-timeout wait left the task
   effectively unkillable.
   For userspace waiters ele_msg_rcv() deferred a signal by recording it
   and then waiting fully uninterruptibly (wait_for_completion_timeout())
   until the FW response or the timeout. The userspace-context timeout is
   SE_RCV_MSG_LONG_TIMEOUT_MS (5000 s), so a task that took a signal
   could sit in uninterruptible sleep for well over an hour, ignoring
   even SIGKILL and tripping the hung-task watchdog. Switch the
   deferred-signal wait to wait_for_completion_killable_timeout(): a
   non-fatal signal is still deferred (recorded once, then the wait
   continues killably, so the in-flight command is neither abandoned nor
   re-sent), but a fatal signal now terminates the wait. On that fatal
   exit the response buffer is quarantined under clbk_rx_lock (rx_msg
   cleared, circuit breaker armed) exactly like the timeout path, because
   the enclave may still DMA into the caller's buffer as it is freed. The
   one exception is a genuine response that raced in just before the fatal
   signal: se_if_rx_callback() has already copied it and set rx_delivered
   under the same lock, so the buffer is done with; that case is reported
   as a normal receive (rx_msg_sz) so the handle it carries is still
   recorded and closed on teardown rather than leaked.

4. [Critical] Physical DMA addresses embedded in raw FW commands.
   NO-CHANGE. The addresses that reach the enclave in a
   SE_IOCTL_CMD_SEND_RCV_RSP payload are produced by the driver itself:
   userspace stages buffers via SE_IOCTL_SETUP_IOBUF, and
   get_shared_mem_slot() returns a kernel-chosen ele_addr inside the
   context's own coherent buffer, carved from the bounded, no-map
   reserved DMA pool bound at probe. Userspace never supplies a raw
   physical address that the driver forwards verbatim. The raw command
   channel is a privileged interface whose trust boundary is the enclave
   firmware, which validates and confines every address it is handed.
   Adding a driver-side physical-address allowlist would duplicate that
   firmware check without adding a boundary. No code change.

5. [High] Use-after-free of se_if_open_gate on the open()/unbind race.
   NO-CHANGE - false positive; the gate lifetime is refcounted and the
   misc core serialises open against deregister. misc_open() and
   misc_deregister() both run under the misc core's misc_mtx, so an
   fops->open() cannot begin after the node is deregistered. The gate is
   a separately kref'd object; se_if_fops_open() takes its reference with
   kref_get_unless_zero(), which fails once teardown has begun dropping
   the last reference, so open() returns -ENODEV instead of touching a
   dying object, and re-validates gate->dying/gate->priv under gate->lock
   afterwards. The object is not freed until its own kref hits zero, which
   cannot happen while this path holds (or fails to obtain) a reference.
   No code change.

Reported-by: sashiko-bot <sashiko-bot@kernel.org>
Closes: https://sashiko.dev/#/patchset/20260805-imx-se-if-v34-0-7e4713d14e0a@nxp.com?part=5
---
 Documentation/ABI/testing/se-cdev         |   44 +
 drivers/firmware/imx/Makefile             |    2 +-
 drivers/firmware/imx/ele_base_msg.c       |   94 +-
 drivers/firmware/imx/ele_base_msg.h       |   19 +
 drivers/firmware/imx/ele_common.c         |  309 +++++-
 drivers/firmware/imx/ele_common.h         |   77 ++
 drivers/firmware/imx/ele_fw_api.c         |  339 ++++++
 drivers/firmware/imx/ele_fw_api.h         |   98 ++
 drivers/firmware/imx/ele_msg_addr_field.c |  650 +++++++++++
 drivers/firmware/imx/se_ctrl.c            | 1681 ++++++++++++++++++++++++++++-
 drivers/firmware/imx/se_ctrl.h            |   90 ++
 include/uapi/linux/se_ioctl.h             |   97 ++
 12 files changed, 3442 insertions(+), 58 deletions(-)

diff --git a/Documentation/ABI/testing/se-cdev b/Documentation/ABI/testing/se-cdev
new file mode 100644
index 000000000000..c6b8e16bda78
--- /dev/null
+++ b/Documentation/ABI/testing/se-cdev
@@ -0,0 +1,44 @@
+What:		/dev/<se>_mu[0-9]+_ch[0-9]+
+Date:		Mar 2025
+KernelVersion:	6.8
+Contact:	linux-imx@nxp.com, pankaj.gupta@nxp.com
+Description:
+		NXP offers multiple hardware IP(s) for secure enclaves like EdgeLock-
+		Enclave(ELE), SECO. The character device file descriptors
+		/dev/<se>_mu*_ch* are the interface between userspace NXP's secure-
+		enclave shared library and the kernel driver.
+
+		The ioctl(2)-based ABI is defined and documented in
+		[include]<linux/firmware/imx/ele_mu_ioctl.h>.
+		ioctl(s) are used primarily for:
+
+			- shared memory management
+			- allocation of I/O buffers
+			- getting mu info
+			- setting a dev-ctx as receiver to receive all the commands from FW
+			- getting SoC info
+			- send command and receive command response
+
+		The following file operations are supported:
+
+		open(2)
+		  Currently the only useful flags are O_RDWR.
+
+		read(2)
+		  Every read() from the opened character device context is waiting on
+		  wait_event_interruptible, that gets set by the registered mailbox callback
+		  function, indicating a message received from the firmware on message-
+		  unit.
+
+		write(2)
+		  Every write() to the opened character device context needs to acquire
+		  mailbox_lock before sending message on to the message unit.
+
+		close(2)
+		  Stops and frees up the I/O contexts that were associated
+		  with the file descriptor.
+
+Users:		https://github.com/nxp-imx/imx-secure-enclave.git,
+		https://github.com/nxp-imx/imx-smw.git,
+		crypto/skcipher,
+		drivers/nvmem/imx-ocotp-ele.c
diff --git a/drivers/firmware/imx/Makefile b/drivers/firmware/imx/Makefile
index 4412b15846b1..33f30eaedad5 100644
--- a/drivers/firmware/imx/Makefile
+++ b/drivers/firmware/imx/Makefile
@@ -4,5 +4,5 @@ obj-$(CONFIG_IMX_SCU)		+= imx-scu.o misc.o imx-scu-irq.o rm.o imx-scu-soc.o
 obj-${CONFIG_IMX_SCMI_CPU_DRV}	+= sm-cpu.o
 obj-${CONFIG_IMX_SCMI_MISC_DRV}	+= sm-misc.o
 obj-${CONFIG_IMX_SCMI_LMM_DRV}	+= sm-lmm.o
-sec_enclave-objs		= se_ctrl.o ele_common.o ele_base_msg.o
+sec_enclave-objs		= se_ctrl.o ele_common.o ele_base_msg.o ele_fw_api.o ele_msg_addr_field.o
 obj-${CONFIG_IMX_SEC_ENCLAVE}	+= sec_enclave.o
diff --git a/drivers/firmware/imx/ele_base_msg.c b/drivers/firmware/imx/ele_base_msg.c
index b70e3ef88a16..78fe40206298 100644
--- a/drivers/firmware/imx/ele_base_msg.c
+++ b/drivers/firmware/imx/ele_base_msg.c
@@ -15,13 +15,67 @@
 
 #define FW_DBG_DUMP_FIXED_STR		"ELE"
 
+int ele_uapi_allowed_base_cmd(struct se_if_device_ctx *dev_ctx,
+			      struct se_msg_hdr *header, u32 tx_msg_sz)
+{
+	struct se_api_msg *msg = container_of(header, struct se_api_msg, header);
+	const struct se_cmd_addr_field *fields;
+	size_t count;
+
+	/*
+	 * Identify the command first. Only commands in this allow-list may be
+	 * issued from userspace; everything else is rejected. Once a command is
+	 * known to be supported, decide whether it needs a DMA-address boundary
+	 * check and, if so, run it before returning.
+	 */
+	switch (header->command) {
+	case ELE_PING_REQ:
+	case ELE_DEBUG_DUMP_REQ:
+	case ELE_OEM_VERIFY_IMAGE_REQ:
+	case ELE_OEM_REL_CONTAINER_REQ:
+	case ELE_FW_LIFE_CYCLE_REQ:
+	case ELE_READ_FUSE_REQ:
+	case ELE_GET_FW_VERS_REQ:
+	case ELE_RETURN_LIFE_CYCLE_REQ:
+	case ELE_GET_EVENT_REQ:
+	case ELE_COMMIT_REQ:
+	case ELE_GET_FW_STATUS_REQ:
+	case ELE_WRITE_FUSE:
+	case ELE_WRITE_SHADOW_FUSE_REQ:
+	case ELE_READ_SHADOW_FUSE_REQ:
+		return 0;
+	default:
+		/* Base commands that embed DMA addresses. */
+		fields = ele_base_cmd_addr_fields(header->command, &count);
+		if (!count)
+			return -EOPNOTSUPP;
+		return se_val_cmd_addrs(dev_ctx, msg, tx_msg_sz, fields, count);
+	}
+}
+
 static void ele_get_info_cleanup(struct se_if_priv *priv, u32 *buf, dma_addr_t d_addr,
 				 size_t size)
 {
-	if (priv->mem_pool)
-		gen_pool_free(priv->mem_pool, (unsigned long)buf, size);
-	else
-		dma_free_coherent(priv->dev, size, buf, d_addr);
+	/* For the case when priv->mem_pool != NULL:
+	 *
+	 *   If this probe-time transaction timed out, the firmware may
+	 *   still write into the SRAM buffer after this function returns.
+	 *   Do not release it back to the pool while the firmware-busy
+	 *   circuit breaker still marks this context as owning an
+	 *   outstanding transaction. The buffer is reclaimed with the
+	 *   device on unbind; leaking this fixed-size probe buffer is
+	 *   preferable to letting the firmware corrupt reused pool memory.
+	 *   This mirrors the guard already applied on the shared-memory
+	 *   cleanup path below.
+	 */
+
+	if (priv->mem_pool) {
+		if (se_is_fw_busy_ctx(priv->priv_dev_ctx))
+			return;
+		se_cleanup_mem_pool_buf(priv->priv_dev_ctx, true);
+	} else {
+		se_dev_ctx_shared_mem_cleanup(priv->priv_dev_ctx);
+	}
 }
 
 int ele_get_info(struct se_if_priv *priv, struct ele_dev_info *s_info)
@@ -34,6 +88,7 @@ int ele_get_info(struct se_if_priv *priv, struct ele_dev_info *s_info)
 	if (!priv)
 		return -EINVAL;
 
+	guard(mutex)(&priv->priv_dev_ctx->fops_lock);
 	memset(s_info, 0x0, sizeof(*s_info));
 
 	struct se_api_msg *tx_msg __free(kfree) =
@@ -47,24 +102,23 @@ int ele_get_info(struct se_if_priv *priv, struct ele_dev_info *s_info)
 		return -ENOMEM;
 
 	get_info_len = ELE_GET_INFO_BUFF_SZ;
-	if (priv->mem_pool)
-		get_info_data = gen_pool_dma_alloc(priv->mem_pool,
-						   get_info_len,
-						   &get_info_addr);
-	else
-		get_info_data = dma_alloc_coherent(priv->dev,
-						   get_info_len,
-						   &get_info_addr,
-						   GFP_KERNEL);
-	if (!get_info_data) {
-		dev_err(priv->dev,
-			"%s: Failed to allocate get_info_addr.", __func__);
-		return -ENOMEM;
+	if (priv->mem_pool) {
+		ret = se_get_mem_pool_buf(priv->priv_dev_ctx, &get_info_data,
+					  &get_info_addr, get_info_len);
+		if (ret) {
+			dev_err(priv->dev, "Failed[0x%x] to alloc from gen_pool.\n", ret);
+			return -ENOMEM;
+		}
+	} else {
+		ret = get_shared_mem_slot(priv->priv_dev_ctx,
+					  &get_info_len, &get_info_addr,
+					  &get_info_data);
+		if (ret) {
+			dev_err(priv->dev, "Failed to allocate buffer.\n");
+			return -ENOMEM;
+		}
 	}
 
-	/* gen_pool_dma_alloc() does not zero the buffer. */
-	memset(get_info_data, 0, get_info_len);
-
 	se_fill_cmd_msg_hdr(priv, (struct se_msg_hdr *)&tx_msg->header,
 			    ELE_GET_INFO_REQ, ELE_GET_INFO_REQ_MSG_SZ, true);
 
diff --git a/drivers/firmware/imx/ele_base_msg.h b/drivers/firmware/imx/ele_base_msg.h
index 02525d5e2873..50e2a1a75716 100644
--- a/drivers/firmware/imx/ele_base_msg.h
+++ b/drivers/firmware/imx/ele_base_msg.h
@@ -29,6 +29,19 @@
 #define ELE_DEBUG_DUMP_REQ_SZ		0x4
 #define ELE_DEBUG_DUMP_RSP_SZ		0x5c
 
+#define ELE_OEM_AUTH_CONTAINER_REQ	0x87
+#define ELE_OEM_VERIFY_IMAGE_REQ	0x88
+#define ELE_OEM_REL_CONTAINER_REQ	0x89
+#define ELE_FW_LIFE_CYCLE_REQ		0x95
+#define ELE_READ_FUSE_REQ		0x97
+#define ELE_GET_FW_VERS_REQ		0x9d
+#define ELE_RETURN_LIFE_CYCLE_REQ	0xa0
+#define ELE_GET_EVENT_REQ		0xa2
+#define ELE_COMMIT_REQ			0xa8
+#define ELE_GEN_KEY_BLOB_REQ		0xaf
+#define ELE_GET_FW_STATUS_REQ		0xc5
+#define ELE_WRITE_FUSE                  0xd6
+
 #define ELE_GET_INFO_REQ		0xda
 #define ELE_GET_INFO_REQ_MSG_SZ		0x10
 #define ELE_GET_INFO_RSP_MSG_SZ		0x08
@@ -71,6 +84,10 @@ struct ele_dev_info {
 #define ELE_GET_INFO_BUFF_SZ		(sizeof(struct ele_dev_info) \
 						+ ELE_DEV_INFO_EXTRA_SZ)
 
+#define ELE_DEV_ATTEST_REQ              0xdb
+#define ELE_WRITE_SHADOW_FUSE_REQ       0xf2
+#define ELE_READ_SHADOW_FUSE_REQ        0xf3
+
 #define ELE_SERVICE_SWAP_REQ		0xdf
 #define ELE_SERVICE_SWAP_REQ_MSG_SZ	0x18
 #define ELE_SERVICE_SWAP_RSP_MSG_SZ	0x0c
@@ -97,4 +114,6 @@ int ele_service_swap(struct se_if_priv *priv, dma_addr_t addr,
 int ele_fw_authenticate(struct se_if_priv *priv, dma_addr_t contnr_addr,
 			dma_addr_t img_addr);
 int ele_debug_dump(struct se_if_priv *priv);
+int ele_uapi_allowed_base_cmd(struct se_if_device_ctx *dev_ctx,
+			      struct se_msg_hdr *header, u32 tx_msg_sz);
 #endif
diff --git a/drivers/firmware/imx/ele_common.c b/drivers/firmware/imx/ele_common.c
index b662063c3b1c..dc868949186f 100644
--- a/drivers/firmware/imx/ele_common.c
+++ b/drivers/firmware/imx/ele_common.c
@@ -5,6 +5,147 @@
 
 #include "ele_base_msg.h"
 #include "ele_common.h"
+#include "ele_fw_api.h"
+#include "se_ctrl.h"
+
+int se_chk_tx_msg_hdr(struct se_if_device_ctx *dev_ctx, struct se_msg_hdr *header,
+		      u32 tx_msg_sz)
+{
+	struct se_if_priv *priv = dev_ctx->priv;
+
+	if (!header->size || header->size > MAX_WORD_SIZE)
+		return -EINVAL;
+
+	if (header->tag != priv->if_defs->cmd_tag &&
+	    header->tag != priv->if_defs->rsp_tag)
+		return -EINVAL;
+
+	if (header->ver == priv->if_defs->base_api_ver)
+		return ele_uapi_allowed_base_cmd(dev_ctx, header, tx_msg_sz);
+	else if (header->ver == priv->if_defs->fw_api_ver)
+		return ele_uapi_allowed_fw_cmd(dev_ctx, header, tx_msg_sz);
+
+	return -EINVAL;
+}
+
+/*
+ * Reject a command that embeds a DMA physical address which does not point
+ * inside this context's shared-memory window. The userspace library stages all
+ * command buffers in that coherent region (see get_shared_mem_slot), so any
+ * address outside [dma_addr, dma_addr + size) is not one the driver handed out
+ * and must not be forwarded to firmware. Absent optional buffers are encoded as
+ * a zero address and skipped; polymorphic key words are only range-checked when
+ * their gating flag marks them as a plaintext-key buffer rather than an integer
+ * key identifier. An address may occupy one word (FW-API, low 32 bits only) or
+ * two words (some base-API commands split it into low and high halves).
+ *
+ * When a field also names a size word, the buffer length carried there is
+ * validated too: the whole buffer [addr, addr + len) must fit inside the
+ * window, not just its start address. The check is written as len > end - addr
+ * (addr is already known to be < end) so it cannot overflow.
+ */
+int se_val_cmd_addrs(struct se_if_device_ctx *dev_ctx, struct se_api_msg *msg,
+		     u32 tx_msg_sz, const struct se_cmd_addr_field *fields,
+		     size_t count)
+{
+	const struct se_shared_mem *mem = &dev_ctx->se_shared_mem_mgmt.non_secure_mem;
+	u32 payload_words;
+	size_t i;
+	u64 base, end;
+
+	if (!fields || !count)
+		return 0;
+
+	if (!msg)
+		return -EINVAL;
+
+	/* Number of complete u32 payload words present after the header. */
+	if (tx_msg_sz < SE_MU_HDR_SZ)
+		return -EINVAL;
+	/*
+	 * The caller-supplied byte count must agree with the size the firmware
+	 * will act on (header word-size field, in 32-bit words), so a lying
+	 * header cannot make us validate fewer words than are actually sent.
+	 */
+	if (tx_msg_sz != (u32)msg->header.size * sizeof(u32))
+		return -EINVAL;
+	payload_words = (tx_msg_sz - SE_MU_HDR_SZ) / sizeof(u32);
+
+	base = (u64)mem->dma_addr;
+	end = base + mem->size;
+
+	/* A zero-sized or wrapping window can never contain a valid buffer. */
+	if (end <= base)
+		return -EINVAL;
+
+	for (i = 0; i < count; i++) {
+		const struct se_cmd_addr_field *f = &fields[i];
+		u64 addr;
+
+		/* Every word the field references must lie within the message. */
+		if (f->lsb_idx >= payload_words)
+			return -EINVAL;
+		if (f->has_msb && f->msb_idx >= payload_words)
+			return -EINVAL;
+
+		if (f->flag_idx != SE_CMD_ADDR_ALWAYS) {
+			bool flag_set;
+
+			if (f->flag_idx >= payload_words)
+				return -EINVAL;
+
+			flag_set = !!(msg->data[f->flag_idx] & f->flag_mask);
+			/*
+			 * When the flag does not select DMA-address mode the
+			 * word holds an integer key identifier; leave it alone.
+			 */
+			if (flag_set != f->is_addr_when_set)
+				continue;
+		}
+
+		addr = msg->data[f->lsb_idx];
+		if (f->has_msb)
+			addr |= (u64)msg->data[f->msb_idx] << 32;
+
+		/* Zero marks an absent optional buffer. */
+		if (!addr)
+			continue;
+
+		if (addr < base || addr >= end)
+			return -EACCES;
+
+		/*
+		 * When the message also carries this buffer's length, the whole
+		 * buffer [addr, addr + len) must fit inside the window, not just
+		 * its start. addr is already >= base and < end here, so end - addr
+		 * is a positive value and the comparison cannot overflow.
+		 */
+		if (f->size_idx != SE_CMD_ADDR_NO_SIZE) {
+			u64 len;
+
+			if (f->size_idx >= payload_words)
+				return -EINVAL;
+
+			/* size_mask == 0 with a valid size_idx is a descriptor bug. */
+			if (!f->size_mask)
+				return -EINVAL;
+
+			/*
+			 * Widen to u64 before shifting: size_shift is u8 and
+			 * shifting a u32 by >= 32 is undefined behaviour.
+			 */
+			len = ((u64)msg->data[f->size_idx] >> f->size_shift) & f->size_mask;
+			if (len > end - addr)
+				return -EACCES;
+		} else if (f->buf_size) {
+			/* buf_size: literal byte count (FW-defined constant or saved at runtime). */
+			if ((u64)f->buf_size > end - addr)
+				return -EACCES;
+		}
+	}
+
+	return 0;
+}
 
 /*
  * se_update_msg_chksum() - calculate and update message checksum word.
@@ -46,20 +187,50 @@ int se_update_msg_chksum(u32 *msg, u32 msg_len)
 	return 0;
 }
 
+static void se_mark_fw_busy(struct se_if_device_ctx *dev_ctx)
+{
+	struct se_if_priv *priv = dev_ctx->priv;
+	unsigned long flags;
+
+	spin_lock_irqsave(&priv->fw_busy_lock, flags);
+	if (!priv->fw_busy_dev_ctx) {
+		kref_get(&dev_ctx->refcount);
+		priv->fw_busy_dev_ctx = dev_ctx;
+		atomic_set(&priv->fw_busy, 1);
+	}
+	spin_unlock_irqrestore(&priv->fw_busy_lock, flags);
+}
+
+void set_se_rcv_msg_timeout(struct se_if_device_ctx *dev_ctx, u32 timeout_ms)
+{
+	dev_ctx->rcv_msg_timeout_jiffies = msecs_to_jiffies(timeout_ms);
+}
+
 int ele_msg_rcv(struct se_if_device_ctx *dev_ctx, struct se_clbk_handle *se_clbk_hdl)
 {
 	struct se_if_priv *priv = dev_ctx->priv;
 	bool is_rsp_wait_with_timeout = false;
 	bool wait_uninterruptible = false;
+	bool wait_killable = false;
 	unsigned long remaining_jiffies;
 	unsigned long deadline_jiffies;
 	unsigned long flags;
 	int ret;
 
-	remaining_jiffies = msecs_to_jiffies(SE_RCV_MSG_DEFAULT_TIMEOUT_MS);
+	remaining_jiffies = dev_ctx->rcv_msg_timeout_jiffies;
 	if (se_clbk_hdl == &priv->waiting_rsp_clbk_hdl) {
 		is_rsp_wait_with_timeout = true;
 		deadline_jiffies = jiffies + remaining_jiffies;
+
+		/*
+		 * Internal kernel transactions run on priv_dev_ctx (probe
+		 * get_info/ping, FW auth, PM IMEM swap). They are not tied to a
+		 * restartable syscall, so wait uninterruptibly: PM freezer fake
+		 * signals must not abort them with -ERESTARTSYS. Userspace
+		 * waiters stay interruptible via the deferred-signal path below.
+		 */
+		if (se_clbk_hdl->dev_ctx == priv->priv_dev_ctx)
+			wait_uninterruptible = true;
 	}
 
 	do {
@@ -71,7 +242,7 @@ int ele_msg_rcv(struct se_if_device_ctx *dev_ctx, struct se_clbk_handle *se_clbk
 				spin_lock_irqsave(&se_clbk_hdl->clbk_rx_lock, flags);
 				se_clbk_hdl->rx_msg = NULL;
 				if (!completion_done(&se_clbk_hdl->done))
-					atomic_set(&priv->fw_busy, 1);
+					se_mark_fw_busy(dev_ctx);
 				spin_unlock_irqrestore(&se_clbk_hdl->clbk_rx_lock, flags);
 				ret = -ETIMEDOUT;
 				break;
@@ -82,23 +253,67 @@ int ele_msg_rcv(struct se_if_device_ctx *dev_ctx, struct se_clbk_handle *se_clbk
 		if (wait_uninterruptible)
 			ret = wait_for_completion_timeout(&se_clbk_hdl->done,
 							  remaining_jiffies);
+		else if (wait_killable)
+			ret = wait_for_completion_killable_timeout(&se_clbk_hdl->done,
+								   remaining_jiffies);
 		else
 			ret = wait_for_completion_interruptible_timeout(&se_clbk_hdl->done,
 									remaining_jiffies);
 		if (ret == -ERESTARTSYS) {
 			/*
-			 * Record that a signal was observed, then continue waiting non-
-			 * interruptibly until the response arrives or the timeout
-			 * expires. The caller can surface the interruption to userspace
-			 * after the protocol transaction is brought back to a
-			 * synchronized state.
+			 * First, non-fatal signal on the interruptible userspace
+			 * path: defer it. Record that a signal was observed and keep
+			 * waiting - now only killably - until the response arrives or
+			 * the timeout expires. ele_msg_send_rcv() then surfaces the
+			 * interruption to userspace as -ERESTARTSYS once the protocol
+			 * transaction has resynchronised, so the in-flight command is
+			 * neither abandoned nor re-sent.
+			 *
+			 * Waiting killably rather than fully uninterruptibly is what
+			 * keeps a fatal signal (SIGKILL) able to terminate the task:
+			 * a non-fatal signal no longer aborts the wait, but the task
+			 * can never get stuck for the multi-thousand-second long
+			 * timeout and trip the hung-task watchdog.
 			 */
-			if (is_rsp_wait_with_timeout &&
+			if (is_rsp_wait_with_timeout && !wait_killable &&
 			    READ_ONCE(se_clbk_hdl->rx_msg)) {
 				WRITE_ONCE(se_clbk_hdl->signal_rcvd, true);
-				wait_uninterruptible = true;
+				wait_killable = true;
 				continue;
 			}
+
+			/*
+			 * Reached here either on the command-receiver path (no
+			 * response buffer of the caller's to protect) or because a
+			 * fatal signal fired on the killable path above. In the
+			 * latter case the task is being killed but the enclave may
+			 * still DMA into the caller's response buffer, which is about
+			 * to be freed. Quarantine it under clbk_rx_lock - drop rx_msg
+			 * so a late se_if_rx_callback() cannot copy into freed memory,
+			 * and arm the circuit breaker - exactly like the timeout path
+			 * below.
+			 *
+			 * The exception is a genuine response that raced in just
+			 * before the fatal signal: se_if_rx_callback() has already
+			 * copied it and set rx_delivered under the same lock, so the
+			 * enclave is done with the buffer. Report it as a normal
+			 * receive (rx_msg_sz) so the handle it carries is still
+			 * recorded and later closed, rather than leaked.
+			 */
+			if (is_rsp_wait_with_timeout) {
+				spin_lock_irqsave(&se_clbk_hdl->clbk_rx_lock, flags);
+				if (se_clbk_hdl->rx_delivered) {
+					ret = se_clbk_hdl->rx_msg_sz;
+					spin_unlock_irqrestore(&se_clbk_hdl->clbk_rx_lock, flags);
+					break;
+				}
+				if (se_clbk_hdl->rx_msg) {
+					se_clbk_hdl->rx_msg = NULL;
+					if (!completion_done(&se_clbk_hdl->done))
+						se_mark_fw_busy(dev_ctx);
+				}
+				spin_unlock_irqrestore(&se_clbk_hdl->clbk_rx_lock, flags);
+			}
 			break;
 		}
 
@@ -119,7 +334,7 @@ int ele_msg_rcv(struct se_if_device_ctx *dev_ctx, struct se_clbk_handle *se_clbk
 			spin_lock_irqsave(&se_clbk_hdl->clbk_rx_lock, flags);
 			se_clbk_hdl->rx_msg = NULL;
 			if (!completion_done(&se_clbk_hdl->done))
-				atomic_set(&priv->fw_busy, 1);
+				se_mark_fw_busy(dev_ctx);
 
 			spin_unlock_irqrestore(&se_clbk_hdl->clbk_rx_lock, flags);
 			ret = -ETIMEDOUT;
@@ -128,8 +343,35 @@ int ele_msg_rcv(struct se_if_device_ctx *dev_ctx, struct se_clbk_handle *se_clbk
 				get_se_if_name(priv->if_defs->se_if_type));
 			break;
 		}
+
+		/*
+		 * A positive wait return normally means a real response. During
+		 * teardown, se_if_probe_cleanup() forces this wait to return via
+		 * complete_all() with no response, while the enclave may still
+		 * DMA into the shared buffer. Treat that as a failed transaction
+		 * and arm the circuit breaker so the buffer is quarantined, not
+		 * freed.
+		 *
+		 * rx_delivered tells the two apart: se_if_rx_callback() sets it
+		 * under clbk_rx_lock only after copying a real response. This
+		 * keeps teardown-time session/storage close responses from being
+		 * mistaken for the forced abort, which would fail the close and
+		 * leak its DMA buffer.
+		 */
+		spin_lock_irqsave(&se_clbk_hdl->clbk_rx_lock, flags);
+		if (is_rsp_wait_with_timeout && atomic_read(&priv->going_away) &&
+		    !se_clbk_hdl->rx_delivered) {
+			se_clbk_hdl->rx_msg = NULL;
+			se_mark_fw_busy(dev_ctx);
+			spin_unlock_irqrestore(&se_clbk_hdl->clbk_rx_lock, flags);
+			ret = -ENODEV;
+			break;
+		}
+		spin_unlock_irqrestore(&se_clbk_hdl->clbk_rx_lock, flags);
+
 		ret = se_clbk_hdl->rx_msg_sz;
 		break;
+
 	} while (ret < 0);
 
 	return ret;
@@ -190,16 +432,42 @@ int ele_msg_send_rcv(struct se_if_device_ctx *dev_ctx, void *tx_msg,
 
 	guard(mutex)(&priv->se_if_cmd_lock);
 
+	/*
+	 * Arm the transaction under clbk_rx_lock. se_if_probe_cleanup() sets
+	 * going_away under this same lock, then complete_all()s, so checking
+	 * going_away and arming (reinit_completion() + publish) together makes
+	 * teardown and arming mutually exclusive and closes the lost-wakeup
+	 * window. priv_dev_ctx teardown-close commands are still let through.
+	 *
+	 * Check going_away before fw_busy so a caller racing unbind gets
+	 * -ENODEV, not a misleading retryable -EBUSY. fw_busy is only
+	 * atomic_read() here, so no fw_busy_lock is taken and there is no
+	 * deadlock.
+	 */
+	spin_lock_irqsave(&priv->waiting_rsp_clbk_hdl.clbk_rx_lock, flags);
+	if (atomic_read(&priv->going_away) &&
+	    (dev_ctx != priv->priv_dev_ctx ||
+	    !is_msg_xchng_for_tdown(tx_msg))) {
+		spin_unlock_irqrestore(&priv->waiting_rsp_clbk_hdl.clbk_rx_lock, flags);
+		return -ENODEV;
+	}
+
 	if (atomic_read(&priv->fw_busy)) {
+		spin_unlock_irqrestore(&priv->waiting_rsp_clbk_hdl.clbk_rx_lock, flags);
 		dev_dbg(priv->dev, "%s: ELE became unresponsive.\n", dev_ctx->devname);
 		return -EBUSY;
 	}
+
 	reinit_completion(&priv->waiting_rsp_clbk_hdl.done);
-	/* Publish rx_msg/rx_msg_sz under the lock read by se_if_rx_callback(). */
-	spin_lock_irqsave(&priv->waiting_rsp_clbk_hdl.clbk_rx_lock, flags);
 	priv->waiting_rsp_clbk_hdl.dev_ctx = dev_ctx;
 	priv->waiting_rsp_clbk_hdl.rx_msg_sz = exp_rx_msg_sz;
 	priv->waiting_rsp_clbk_hdl.rx_msg = rx_msg;
+	/*
+	 * Arm a fresh transaction: clear the delivered flag so a stale value
+	 * from a previous response cannot make ele_msg_rcv() mistake a
+	 * teardown-forced complete_all() for a genuine firmware response.
+	 */
+	priv->waiting_rsp_clbk_hdl.rx_delivered = false;
 	spin_unlock_irqrestore(&priv->waiting_rsp_clbk_hdl.clbk_rx_lock, flags);
 
 	err = ele_msg_send(dev_ctx, tx_msg, tx_msg_sz);
@@ -248,6 +516,7 @@ static bool check_hdr_exception_for_sz(struct se_if_priv *priv,
 void se_if_rx_callback(struct mbox_client *mbox_cl, void *msg)
 {
 	struct se_clbk_handle *se_clbk_hdl;
+	bool schedule_fw_busy_work = false;
 	struct device *dev = mbox_cl->dev;
 	const char *devname = NULL;
 	struct se_msg_hdr *header;
@@ -325,9 +594,13 @@ void se_if_rx_callback(struct mbox_client *mbox_cl, void *msg)
 		se_clbk_hdl = &priv->waiting_rsp_clbk_hdl;
 		spin_lock_irqsave(&se_clbk_hdl->clbk_rx_lock, flags);
 		if (!se_clbk_hdl->rx_msg) {
-			/* Close circuit breaker on spinlock race */
-			atomic_set(&priv->fw_busy, 0);
+			if (atomic_read(&priv->fw_busy))
+				schedule_fw_busy_work = true;
 			spin_unlock_irqrestore(&se_clbk_hdl->clbk_rx_lock, flags);
+
+			if (schedule_fw_busy_work)
+				schedule_work(&priv->fw_busy_work);
+
 			dev_info(dev, "ELE responded (late), recovery FW available.");
 			return;
 		}
@@ -347,6 +620,12 @@ void se_if_rx_callback(struct mbox_client *mbox_cl, void *msg)
 		se_clbk_hdl->rx_msg_sz = min(rx_msg_sz, exp_rx_msg_sz);
 		devname = se_clbk_hdl->dev_ctx->devname;
 		memcpy(se_clbk_hdl->rx_msg, msg, se_clbk_hdl->rx_msg_sz);
+		/*
+		 * Mark that a genuine firmware response was delivered. ele_msg_rcv()
+		 * reads this under clbk_rx_lock to avoid mistaking this response for
+		 * a teardown-forced complete_all() wakeup.
+		 */
+		se_clbk_hdl->rx_delivered = true;
 		complete(&se_clbk_hdl->done);
 		spin_unlock_irqrestore(&se_clbk_hdl->clbk_rx_lock, flags);
 
@@ -398,7 +677,7 @@ int se_val_rsp_hdr_n_status(struct se_if_priv *priv, struct se_api_msg *msg,
 		return -EINVAL;
 	}
 
-	if (header->size > SE_MU_HDR_WORD_SZ) {
+	if (header->size > SE_MU_HDR_WORD_SZ && (sz >> 2) > SE_MU_HDR_WORD_SZ) {
 		status = RES_STATUS(msg->data[0]);
 		if (status != priv->if_defs->success_tag) {
 			dev_dbg(priv->dev, "Command Id[%x], Response Failure = 0x%x",
diff --git a/drivers/firmware/imx/ele_common.h b/drivers/firmware/imx/ele_common.h
index 07e6b6a1bafa..6d29add2fc8e 100644
--- a/drivers/firmware/imx/ele_common.h
+++ b/drivers/firmware/imx/ele_common.h
@@ -9,11 +9,15 @@
 #include "se_ctrl.h"
 
 #define SE_RCV_MSG_DEFAULT_TIMEOUT_MS	3000
+#define SE_RCV_MSG_LONG_TIMEOUT_MS	5000000
 
 #define ELE_SUCCESS_IND			0xD6
 
 #define IMX_ELE_FW_DIR                 "imx/ele/"
 
+#define MAX_WORD_SIZE			0x20
+
+void set_se_rcv_msg_timeout(struct se_if_device_ctx *dev_ctx, u32 val);
 int se_update_msg_chksum(u32 *msg, u32 msg_len);
 
 int ele_msg_rcv(struct se_if_device_ctx *dev_ctx, struct se_clbk_handle *se_clbk_hdl);
@@ -28,6 +32,76 @@ void se_if_rx_callback(struct mbox_client *mbox_cl, void *msg);
 int se_val_rsp_hdr_n_status(struct se_if_priv *priv, struct se_api_msg *msg,
 			    u8 msg_id, u8 sz, bool is_base_api);
 
+/*
+ * A number of ELE commands carry DMA physical addresses inside their message
+ * payload. se_val_cmd_addrs() range-checks each such address against the
+ * calling context's shared-memory window before the message reaches firmware.
+ *
+ * data[] index = message WORD index - 1, because the 4-byte se_msg_hdr is
+ * message WORD 0 and se_api_msg.data[0] is message WORD 1.
+ *
+ * struct se_cmd_addr_field describes one address embedded in the payload:
+ *   lsb_idx          - data[] index of the low 32 bits of the address
+ *   msb_idx          - data[] index of the high 32 bits, valid only when
+ *                      has_msb is set. Some base-API commands split the
+ *                      address into two words; FW-API commands do not.
+ *   has_msb          - true when the address occupies two words (lsb + msb)
+ *   flag_idx         - data[] index of the flag word that selects whether
+ *                      data[lsb_idx] is a DMA address or an integer key
+ *                      identifier; SE_CMD_ADDR_ALWAYS when the word is always
+ *                      a DMA address
+ *   flag_mask        - the selecting flag bit, already shifted to its position
+ *                      inside the 32-bit little-endian flag word
+ *   is_addr_when_set - true when the word is a DMA address if the flag bit is
+ *                      set; false when it is an address if the bit is clear
+ *                      (inverse polarity, e.g. VERIFY_SIGN OPAQUE_KEY)
+ *   size_idx         - data[] index of the word carrying the length in bytes
+ *                      of the buffer at this address. se_val_cmd_addrs() uses
+ *                      it to confirm the whole buffer [addr, addr + len) fits
+ *                      inside the shared-memory window, not just its start.
+ *                      SE_CMD_ADDR_NO_SIZE when the message carries no length
+ *                      for this buffer.
+ *   size_shift       - right shift applied to the size word before masking,
+ *                      for a length packed into the high half of a word
+ *   size_mask        - bitmask applied after the shift to extract the length
+ *                      from the message word (0xFFFFFFFF for a full 32-bit
+ *                      length, 0xFFFF for a u16, 0xFF for a u8). Used only
+ *                      when size_idx != SE_CMD_ADDR_NO_SIZE; zero otherwise.
+ *   buf_size         - literal byte count used when size_idx ==
+ *                      SE_CMD_ADDR_NO_SIZE and buf_size != 0: the whole
+ *                      buffer [addr, addr + buf_size) must fit inside the
+ *                      shared-memory window. Use this for buffers whose size
+ *                      is a firmware-defined constant not carried in the
+ *                      message, or populated at runtime via
+ *                      ele_set_sz_in_field_addr(). Zero means no end-bound
+ *                      check (start-address check only; see comments at each
+ *                      descriptor entry for the accepted exception rationale).
+ */
+struct se_cmd_addr_field {
+	u8 lsb_idx;
+	u8 msb_idx;
+	bool has_msb;
+	u8 flag_idx;
+	u32 flag_mask;
+	bool is_addr_when_set;
+	u8 size_idx;
+	u8 size_shift;
+	u32 size_mask;
+	u32 buf_size;
+};
+
+#define SE_CMD_ADDR_ALWAYS	0xEFu
+#define SE_CMD_ADDR_NO_SIZE	0xFFu
+
+int se_val_cmd_addrs(struct se_if_device_ctx *dev_ctx, struct se_api_msg *msg,
+		     u32 tx_msg_sz, const struct se_cmd_addr_field *fields,
+		     size_t count);
+
+const struct se_cmd_addr_field *ele_fw_cmd_addr_fields(u8 cmd, size_t *count);
+const struct se_cmd_addr_field *ele_fw_rsp_addr_fields(u8 cmd, size_t *count);
+const struct se_cmd_addr_field *ele_base_cmd_addr_fields(u8 cmd, size_t *count);
+void ele_set_sz_in_field_addr(u8 cmd, u32 size);
+
 /* Fill a command message header with a given command ID and length in bytes. */
 static inline void se_fill_cmd_msg_hdr(struct se_if_priv *priv, struct se_msg_hdr *hdr,
 				       u8 cmd, u32 len, bool is_base_api)
@@ -42,4 +116,7 @@ int se_save_imem_state(struct se_if_priv *priv, struct se_imem_buf *imem);
 
 int se_restore_imem_state(struct se_if_priv *priv, struct se_imem_buf *imem);
 
+int se_chk_tx_msg_hdr(struct se_if_device_ctx *dev_ctx, struct se_msg_hdr *header,
+		      u32 tx_msg_sz);
+
 #endif /*__ELE_COMMON_H__ */
diff --git a/drivers/firmware/imx/ele_fw_api.c b/drivers/firmware/imx/ele_fw_api.c
new file mode 100644
index 000000000000..e237dfa16377
--- /dev/null
+++ b/drivers/firmware/imx/ele_fw_api.c
@@ -0,0 +1,339 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright 2026 NXP
+ */
+
+#include "se_ctrl.h"
+#include "ele_common.h"
+#include "ele_fw_api.h"
+
+static int se_cmd_receiver_allowed_cmd(struct se_if_device_ctx *dev_ctx,
+                                       struct se_api_msg *msg, u32 tx_msg_sz)
+{
+	u8 cmd = msg->header.command;
+
+	switch (cmd) {
+	case ELE_SESSION_CLOSE_REQ:
+	case ELE_STORAGE_CLOSE_REQ:
+		return 0;
+	case ELE_STORAGE_MASTER_IMPORT_REQ:
+		const struct se_cmd_addr_field *fields;
+		size_t count;
+
+		fields = ele_fw_cmd_addr_fields(cmd, &count);
+		return se_val_cmd_addrs(dev_ctx, msg, tx_msg_sz, fields, count);
+	default:
+		return -EOPNOTSUPP;
+	}
+}
+
+static int se_cmd_receiver_allowed_rsp(struct se_if_device_ctx *dev_ctx,
+				       struct se_api_msg *msg, u32 tx_msg_sz)
+{
+	const struct se_cmd_addr_field *fields;
+	u8 cmd = msg->header.command;
+	size_t count;
+
+	switch (cmd) {
+	case ELE_STORAGE_EXPORT_FINISH_REQ:
+	case ELE_STORAGE_CHUNK_GET_DONE_REQ:
+	case ELE_STORAGE_CHUNK_DELETE_REQ:
+		return 0;
+	default:
+		/*
+		 * These responses supply a kernel buffer address to firmware.
+		 * Range-check the embedded DMA address against the calling
+		 * context's shared-memory window before the message is sent.
+		 */
+		fields = ele_fw_rsp_addr_fields(cmd, &count);
+		if (!count)
+			return -EOPNOTSUPP;
+		return se_val_cmd_addrs(dev_ctx, msg, tx_msg_sz, fields, count);
+	}
+}
+
+int ele_uapi_allowed_fw_cmd(struct se_if_device_ctx *dev_ctx, struct se_msg_hdr *header,
+			    u32 tx_msg_sz)
+{
+	struct se_api_msg *msg = container_of(header, struct se_api_msg, header);
+	struct se_if_priv *priv = dev_ctx->priv;
+	const struct se_cmd_addr_field *fields;
+	bool is_cmd_receiver = false;
+	size_t count;
+	int ret = 0;
+
+	scoped_guard(mutex, &priv->modify_lock)
+		if (dev_ctx == priv->cmd_receiver_clbk_hdl.dev_ctx)
+			is_cmd_receiver = true;
+
+	if (is_cmd_receiver) {
+		if (header->tag == priv->if_defs->cmd_tag)
+			return se_cmd_receiver_allowed_cmd(dev_ctx, msg, tx_msg_sz);
+
+		if (header->tag == priv->if_defs->rsp_tag)
+			return se_cmd_receiver_allowed_rsp(dev_ctx, msg, tx_msg_sz);
+	}
+
+	/* Reject any response message with non-command receiver */
+	if (header->tag == priv->if_defs->rsp_tag)
+		return -EOPNOTSUPP;
+
+	/* Reject any other tag */
+	if (header->tag != priv->if_defs->cmd_tag)
+		return -EOPNOTSUPP;
+
+	/*
+	 * Identify the command first. Session/storage commands enforce their
+	 * own-handle checks; crypto commands that embed DMA addresses defer to
+	 * the shared range check below. Any command not named here is left with
+	 * ret == 0 (permitted) as before.
+	 */
+	switch (header->command) {
+	case ELE_SESSION_OPEN_REQ:
+		/* Might be cleared as part of tear down. */
+		ret = dev_ctx->sess_hdl ? -EEXIST : 0;
+		break;
+	case ELE_SESSION_CLOSE_REQ:
+		/* Might be cleared as part of tear down. */
+		if (!dev_ctx->sess_hdl) {
+			ret = -ENXIO;
+			break;
+		}
+		/*
+		 * A close request must target this context's own session. The
+		 * handle to close is carried in the payload (data[0]); reject a
+		 * request whose buffer is too short to hold it, or whose handle
+		 * does not match this context. Checking the buffer size first
+		 * also keeps the data[0] read in bounds. This stops one process
+		 * from closing - and leaking - another process's session with a
+		 * spoofed handle.
+		 */
+		if (tx_msg_sz < ELE_SESSION_CLOSE_REQ_SZ ||
+		    msg->data[0] != dev_ctx->sess_hdl)
+			ret = -EINVAL;
+		break;
+	case ELE_FW_GET_INFO_REQ:
+	case ELE_KEY_STORE_OPEN_REQ:
+	case ELE_KEY_STORE_CLOSE_REQ:
+	case ELE_KEY_MGMT_OPEN_REQ:
+	case ELE_KEY_MGMT_CLOSE_REQ:
+	case ELE_MANAGE_KEY_GROUP_REQ:
+	case ELE_GET_KEY_ATTR_REQ:
+	case ELE_KEY_DELETE_REQ:
+	case ELE_MAC_OPEN_REQ:
+	case ELE_MAC_CLOSE_REQ:
+	case ELE_CIPHER_OPEN_REQ:
+	case ELE_CIPHER_CLOSE_REQ:
+	case ELE_SIGNATURE_GENERATE_OPEN_REQ:
+	case ELE_SIGNATURE_GENERATE_CLOSE_REQ:
+	case ELE_SIGNATURE_VERIFY_OPEN_REQ:
+	case ELE_SIGNATURE_VERIFY_CLOSE_REQ:
+	case ELE_DATA_STORAGE_OPEN_REQ:
+	case ELE_DATA_STORAGE_CLOSE_REQ:
+	case ELE_DATA_DELETE_REQ:
+		ret = 0;
+		break;
+	case ELE_STORAGE_OPEN_REQ:
+		/* Might be cleared as part of tear down. */
+		ret = dev_ctx->strg_hdl ? -EEXIST : 0;
+		break;
+	case ELE_STORAGE_CLOSE_REQ:
+		/* Might be cleared as part of tear down. */
+		if (!dev_ctx->strg_hdl) {
+			ret = -ENXIO;
+			break;
+		}
+		/* Same self-ownership check as the session close above. */
+		if (tx_msg_sz < ELE_STORAGE_CLOSE_REQ_SZ ||
+		    msg->data[0] != dev_ctx->strg_hdl)
+			ret = -EINVAL;
+		break;
+	case ELE_STORAGE_STATUS_REQ:
+		ret = 0;
+		break;
+	default:
+		/* FW commands that embed DMA addresses. */
+		fields = ele_fw_cmd_addr_fields(header->command, &count);
+		if (!count) {
+			ret = -EOPNOTSUPP;
+			break;
+		}
+
+		ret = se_val_cmd_addrs(dev_ctx, msg, tx_msg_sz, fields, count);
+		break;
+	}
+
+	return ret;
+}
+
+void fw_api_specific_ops(struct se_if_device_ctx *dev_ctx, struct se_api_msg *rx_msg)
+{
+	struct se_msg_hdr *header = &rx_msg->header;
+	struct se_if_priv *priv = dev_ctx->priv;
+
+	switch (header->command) {
+	case ELE_SESSION_OPEN_REQ:
+		dev_ctx->sess_hdl = rx_msg->data[1];
+		break;
+	case ELE_SESSION_CLOSE_REQ:
+		dev_ctx->sess_hdl = 0;
+		break;
+	case ELE_STORAGE_CLOSE_REQ:
+		scoped_guard(mutex, &priv->modify_lock)
+			unset_dev_ctx_as_command_receiver(dev_ctx);
+		dev_ctx->strg_hdl = 0;
+		break;
+	case ELE_STORAGE_OPEN_REQ: {
+		int rc = 0;
+
+		/*
+		 * Record the storage handle before registering as command
+		 * receiver. FW has already allocated the handle; if we assigned
+		 * it only after a successful registration, a failing
+		 * set_dev_ctx_as_command_receiver() (e.g. -EBUSY) would leave
+		 * strg_hdl at 0 while the ioctl still returns success to
+		 * userspace. The kernel would then never close the handle on
+		 * teardown, leaking it in FW. Storing it first guarantees
+		 * cleanup_dev_ctx() closes it regardless of registration.
+		 */
+		dev_ctx->strg_hdl = rx_msg->data[1];
+
+		rc = set_dev_ctx_as_command_receiver(dev_ctx);
+		if (rc)
+			dev_err(priv->dev,
+				"Failed to register %s as CMD-Receiver: %d\n",
+				dev_ctx->devname, rc);
+		break;
+	}
+	case ELE_STORAGE_MASTER_EXPORT_REQ:
+		/*
+		 * FW sent an export-start command with key_store_size at
+		 * data[1]. Save it so se_val_cmd_addrs() can range-check the
+		 * response buffer when the cmd_receiver sends back the address.
+		 */
+		ele_set_sz_in_field_addr(ELE_STORAGE_MASTER_EXPORT_REQ,
+					 rx_msg->data[1]);
+		break;
+	case ELE_STORAGE_CHUNK_EXPORT_REQ:
+		/*
+		 * FW sent a chunk-export command with chunk_size at data[1].
+		 * Save it so se_val_cmd_addrs() can range-check the response
+		 * buffer when the cmd_receiver sends back the address.
+		 */
+		ele_set_sz_in_field_addr(ELE_STORAGE_CHUNK_EXPORT_REQ,
+					 rx_msg->data[1]);
+		break;
+	}
+}
+
+/*
+ * Return true when tx_msg is one of the close requests the driver issues
+ * from its own teardown path (session/storage close). ele_msg_send_rcv()
+ * uses this to let those close messages through even after going_away is
+ * set, so the kernel can still resynchronise session/storage state with FW.
+ */
+bool is_msg_xchng_for_tdown(void *tx_msg)
+{
+	struct se_msg_hdr *header = &((struct se_api_msg *)tx_msg)->header;
+
+	return (header->command == ELE_SESSION_CLOSE_REQ ||
+		header->command == ELE_STORAGE_CLOSE_REQ);
+}
+
+int se_close_session(struct se_if_device_ctx *dev_ctx, u32 session_hdl)
+{
+	struct se_api_msg *tx_msg __free(kfree) = NULL;
+	struct se_api_msg *rx_msg __free(kfree) = NULL;
+	struct se_if_priv *priv;
+	int ret;
+
+	if (!dev_ctx || !dev_ctx->priv)
+		return -EINVAL;
+
+	priv = dev_ctx->priv;
+
+	tx_msg = kzalloc(ELE_SESSION_CLOSE_REQ_SZ, GFP_KERNEL);
+	if (!tx_msg)
+		return -ENOMEM;
+
+	rx_msg = kzalloc(ELE_SESSION_CLOSE_RSP_SZ, GFP_KERNEL);
+	if (!rx_msg)
+		return -ENOMEM;
+
+	/*
+	 * Session close is a FW-API command; format it with the FW API version
+	 * so se_val_rsp_hdr_n_status() below (called with is_base_api = false,
+	 * i.e. expecting fw_api_ver) does not reject the matching response and
+	 * wrongly report the close as failed, which would leak the handle.
+	 */
+	se_fill_cmd_msg_hdr(priv, (struct se_msg_hdr *)&tx_msg->header,
+			    ELE_SESSION_CLOSE_REQ, ELE_SESSION_CLOSE_REQ_SZ, false);
+
+	tx_msg->data[0] = session_hdl;
+
+	/*
+	 * Transmit on the caller's own context. Using dev_ctx (rather than
+	 * hardcoding priv->priv_dev_ctx) keeps a userspace close() subject to
+	 * the going_away check in ele_msg_send_rcv(): if unbind has begun and
+	 * freed priv->tx_chan, the send is rejected with -ENODEV instead of
+	 * touching the freed mailbox channel. The teardown path passes
+	 * priv_dev_ctx so its resync closes are still let through.
+	 */
+	ret = ele_msg_send_rcv(dev_ctx,
+			       tx_msg,
+			       ELE_SESSION_CLOSE_REQ_SZ,
+			       rx_msg,
+			       ELE_SESSION_CLOSE_RSP_SZ);
+	if (ret < 0)
+		return ret;
+
+	ret = se_val_rsp_hdr_n_status(priv,
+				      rx_msg,
+				      ELE_SESSION_CLOSE_REQ,
+				      ELE_SESSION_CLOSE_RSP_SZ,
+				      false);
+	return ret;
+}
+
+int se_close_storage(struct se_if_device_ctx *dev_ctx, u32 storage_hdl)
+{
+	struct se_api_msg *tx_msg __free(kfree) = NULL;
+	struct se_api_msg *rx_msg __free(kfree) = NULL;
+	struct se_if_priv *priv;
+	int ret;
+
+	if (!dev_ctx || !dev_ctx->priv)
+		return -EINVAL;
+
+	priv = dev_ctx->priv;
+
+	tx_msg = kzalloc(ELE_STORAGE_CLOSE_REQ_SZ, GFP_KERNEL);
+	if (!tx_msg)
+		return -ENOMEM;
+
+	rx_msg = kzalloc(ELE_STORAGE_CLOSE_RSP_SZ, GFP_KERNEL);
+	if (!rx_msg)
+		return -ENOMEM;
+
+	/* Same FW-API version handling as se_close_session() above. */
+	se_fill_cmd_msg_hdr(priv, (struct se_msg_hdr *)&tx_msg->header,
+			    ELE_STORAGE_CLOSE_REQ, ELE_STORAGE_CLOSE_REQ_SZ, false);
+
+	tx_msg->data[0] = storage_hdl;
+
+	/* Transmit on the caller's own context; see se_close_session(). */
+	ret = ele_msg_send_rcv(dev_ctx,
+			       tx_msg,
+			       ELE_STORAGE_CLOSE_REQ_SZ,
+			       rx_msg,
+			       ELE_STORAGE_CLOSE_RSP_SZ);
+	if (ret < 0)
+		return ret;
+
+	ret = se_val_rsp_hdr_n_status(priv,
+				      rx_msg,
+				      ELE_STORAGE_CLOSE_REQ,
+				      ELE_STORAGE_CLOSE_RSP_SZ,
+				      false);
+	return ret;
+}
diff --git a/drivers/firmware/imx/ele_fw_api.h b/drivers/firmware/imx/ele_fw_api.h
new file mode 100644
index 000000000000..22484a892392
--- /dev/null
+++ b/drivers/firmware/imx/ele_fw_api.h
@@ -0,0 +1,98 @@
+/* SPDX-License-Identifier: GPL-2.0+ */
+/*
+ * Copyright 2026 NXP
+ */
+
+#ifndef ELE_FW_API_H
+#define ELE_FW_API_H
+#include "se_ctrl.h"
+
+#define ELE_SESSION_OPEN_REQ            0x10u
+
+#define ELE_SESSION_CLOSE_REQ_SZ	0x08u
+#define ELE_SESSION_CLOSE_RSP_SZ	0x08u
+#define ELE_SESSION_CLOSE_REQ           0x11u
+
+/*
+ * Session-scoped FW-API service, key-management and close command opcodes
+ * (SAB command IDs, PSA_COMPLIANT message layout). These commands do not
+ * embed DMA staging-buffer addresses that require range-checking; they are
+ * defined here for completeness and for use by the command allow-list.
+ * ELE_FW_GET_INFO_REQ is the FW-API get-info opcode and is intentionally
+ * distinct from the base-API ELE_GET_INFO_REQ (0xda) in ele_base_msg.h.
+ */
+#define ELE_FW_GET_INFO_REQ             0x16u
+#define ELE_KEY_STORE_OPEN_REQ          0x30u
+#define ELE_KEY_STORE_CLOSE_REQ         0x31u
+#define ELE_KEY_MGMT_OPEN_REQ           0x40u
+#define ELE_KEY_MGMT_CLOSE_REQ          0x41u
+#define ELE_MANAGE_KEY_GROUP_REQ        0x45u
+#define ELE_GET_KEY_ATTR_REQ            0x4Cu
+#define ELE_KEY_DELETE_REQ              0x4Eu
+#define ELE_MAC_OPEN_REQ                0x50u
+#define ELE_MAC_CLOSE_REQ               0x51u
+#define ELE_CIPHER_OPEN_REQ             0x60u
+#define ELE_CIPHER_CLOSE_REQ            0x61u
+#define ELE_SIGNATURE_GENERATE_OPEN_REQ 0x70u
+#define ELE_SIGNATURE_GENERATE_CLOSE_REQ 0x71u
+#define ELE_SIGNATURE_VERIFY_OPEN_REQ   0x80u
+#define ELE_SIGNATURE_VERIFY_CLOSE_REQ  0x81u
+#define ELE_DATA_STORAGE_OPEN_REQ       0xA0u
+#define ELE_DATA_STORAGE_CLOSE_REQ      0xA1u
+#define ELE_DATA_DELETE_REQ             0xA4u
+
+/*
+ * FW-API crypto command opcodes that embed one or more DMA physical addresses
+ * in their message payload. ele_uapi_allowed_fw_cmd() range-checks those
+ * addresses against the calling context's shared-memory window before the
+ * message is handed to firmware. Opcodes match the SAB command IDs emitted by
+ * the userspace library (PSA_COMPLIANT message layout).
+ */
+#define ELE_PUB_KEY_EXPORT_REQ          0x32u
+#define ELE_KEYSTORE_REPROV_ENABLE_REQ  0x3Fu
+#define ELE_KEYGEN_REQ                  0x42u
+#define ELE_KEY_EXCHANGE_REQ            0x47u
+#define ELE_KEY_IMPORT_REQ              0x4Fu
+#define ELE_KEY_IMPORT                  0x4Fu
+#define ELE_MAC_REQ                     0x52u
+#define ELE_CIPHER_REQ                  0x62u
+#define ELE_AUTH_ENC_REQ                0x64u
+#define ELE_AUTH_ENC_NEW_REQ            0x65u
+#define ELE_SIGNATURE_GENERATE_REQ      0x72u
+#define ELE_PUB_KEY_ATTEST_REQ          0x74u
+#define ELE_SIGNATURE_VERIFY_REQ        0x82u
+#define ELE_DATA_STORAGE_REQ            0xA2u
+#define ELE_ENC_DATA_STORAGE_REQ        0xA3u
+#define ELE_ASYMMETRIC_ENC_REQ          0x92u
+
+#define ELE_KEY_GENERIC_CRYPTO_REQ      0xC2u
+#define ELE_GC_CIPHER_REQ               0xC8u
+#define ELE_GC_AEAD_REQ                 0xC9u
+#define ELE_GC_ACRYPTO_REQ              0xCAu
+#define ELE_GC_AKEY_GEN_REQ             0xCBu
+#define ELE_HASH_ONE_GO_REQ             0xCCu
+#define ELE_RNG_GET_RANDOM_REQ          0xCDu
+
+#define ELE_STORAGE_OPEN_REQ            0xE0u
+
+#define ELE_STORAGE_CLOSE_REQ_SZ	0x08u
+#define ELE_STORAGE_CLOSE_RSP_SZ	0x08u
+#define ELE_STORAGE_CLOSE_REQ           0xE1u
+
+#define ELE_STORAGE_MASTER_IMPORT_REQ   0xE2u
+#define ELE_STORAGE_MASTER_EXPORT_REQ   0xE3u
+#define ELE_STORAGE_EXPORT_FINISH_REQ   0xE4u
+#define ELE_STORAGE_CHUNK_EXPORT_REQ    0xE5u
+#define ELE_STORAGE_CHUNK_GET_REQ       0xE6u
+#define ELE_STORAGE_CHUNK_GET_DONE_REQ  0xE7u
+#define ELE_STORAGE_CHUNK_DELETE_REQ    0xE9u
+#define ELE_STORAGE_STATUS_REQ          0xEAu
+
+int ele_uapi_allowed_fw_cmd(struct se_if_device_ctx *dev_ctx, struct se_msg_hdr *header,
+			    u32 tx_msg_sz);
+void fw_api_specific_ops(struct se_if_device_ctx *dev_ctx, struct se_api_msg *rx_msg);
+bool is_msg_xchng_for_tdown(void *tx_msg);
+int se_close_session(struct se_if_device_ctx *dev_ctx, u32 session_hdl);
+int se_close_storage(struct se_if_device_ctx *dev_ctx, u32 storage_hdl);
+
+#endif /* ELE_FW_API_H */
diff --git a/drivers/firmware/imx/ele_msg_addr_field.c b/drivers/firmware/imx/ele_msg_addr_field.c
new file mode 100644
index 000000000000..c8df021c27d2
--- /dev/null
+++ b/drivers/firmware/imx/ele_msg_addr_field.c
@@ -0,0 +1,650 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright 2026 NXP
+ */
+
+#include <linux/types.h>
+
+#include "ele_common.h"
+#include "ele_base_msg.h"
+#include "ele_fw_api.h"
+
+/*
+ * Base-API commands that embed one or more DMA physical addresses in their
+ * payload. Unlike the FW-API crypto commands, GET_INFO and DEV_ATTEST split
+ * their response-buffer address across two words: the high half is written
+ * first (lower word index) and the low half next, so has_msb is set and the
+ * msb_idx precedes the lsb_idx. GEN_KEY_BLOB uses single-word LSB addresses.
+ * See struct se_cmd_addr_field in ele_common.h for the field semantics.
+ */
+static const struct se_cmd_addr_field ele_get_info_addr_fields[] = {
+	/*
+	 * rsp_data_addr_hi @ data[0], rsp_data_addr_lo @ data[1];
+	 * buf_sz is a u16 in the low half of data[2].
+	 */
+	{ .lsb_idx = 1, .msb_idx = 0, .has_msb = true, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 2, .size_mask = 0xFFFFu },
+};
+
+static const struct se_cmd_addr_field ele_dev_attest_addr_fields[] = {
+	/*
+	 * rsp_data_addr_hi @ data[0], rsp_data_addr_lo @ data[1];
+	 * buf_sz is a u16 in the low half of data[2].
+	 */
+	{ .lsb_idx = 1, .msb_idx = 0, .has_msb = true, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 2, .size_mask = 0xFFFFu },
+};
+
+static const struct se_cmd_addr_field ele_oem_auth_cntr_addr_fields[] = {
+	/*
+	 * Container Header address: a 64-bit physical address split across two
+	 * words. data[0] holds the 32-bit MSB and data[1] holds the 32-bit LSB
+	 * (ELE API spec Table 27, word size = 0x3, so the command is header +
+	 * MSB + LSB only). The message carries no length word for this buffer;
+	 * the container size is variable and not communicated in the MU payload,
+	 * and no static firmware-defined maximum is specified. Because this is a
+	 * read-only input buffer (the ELE ROM/FW copies the container header
+	 * into its internal memory for authentication and does not write back
+	 * through this address), enforcing only the start-address range check is
+	 * acceptable: a rogue caller can at most cause firmware to read within
+	 * the shared-memory window, which is memory the caller already owns.
+	 * Output buffers must be fully bounded; input-only buffers are safe with
+	 * addr-only checks.
+	 */
+	{ .lsb_idx = 1, .msb_idx = 0, .has_msb = true, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = SE_CMD_ADDR_NO_SIZE },			/* container_hdr_addr */
+};
+
+/*
+ * GENERATE ELE KEY BLOB command (ELE_GEN_KEY_BLOB_REQ, 0xAF).
+ * ELE API spec Table 73, word size = 0x8 (header + 7 data words):
+ *   data[0] = key_identifier
+ *   data[1] = Reserved
+ *   data[2] = load_address  (32-bit; must be 64-bit aligned)
+ *   data[3] = Reserved
+ *   data[4] = store_address (32-bit; must be 64-bit aligned)
+ *   data[5] = Reserved[31:16] | max_export_size[15:0]
+ *   data[6] = CRC
+ *
+ * load_addr points to the input: a blob header (8 bytes, Table 77) followed
+ * by the plaintext payload. No size word is present in the message for this
+ * input buffer. The maximum input size is determined by the largest supported
+ * payload type: OTFAD key configuration (0x28 bytes per Table 79) plus the
+ * 8-byte header gives 0x30 bytes. That is the literal upper bound used as
+ * buf_size so se_val_cmd_addrs() can verify [load_addr, load_addr+0x30)
+ * lies within the shared-memory window. This is an input-only buffer
+ * (firmware reads it to generate the blob) so start-address-plus-fixed-max
+ * is a safe and sufficient check.
+ */
+#define OP_GEN_ELE_KEY_BLOB_INPUT_MAX_SZ	0x30  /* blob hdr (8) + OTFAD payload (0x28) */
+static const struct se_cmd_addr_field ele_gen_key_blob_addr_fields[] = {
+	{ .lsb_idx = 2, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = SE_CMD_ADDR_NO_SIZE,
+	  .buf_size = OP_GEN_ELE_KEY_BLOB_INPUT_MAX_SZ },	/* load_address */
+	/* store_address @ data[4]; max_export_size is u16 in low half of data[5] */
+	{ .lsb_idx = 4, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 5, .size_mask = 0xFFFFu },		/* store_address */
+};
+
+/*
+ * Return the address-field descriptor table for a base-API command, or NULL
+ * when the command embeds no DMA addresses. count is set to the number of
+ * entries.
+ */
+const struct se_cmd_addr_field *ele_base_cmd_addr_fields(u8 cmd, size_t *count)
+{
+	switch (cmd) {
+	case ELE_OEM_AUTH_CONTAINER_REQ:
+		*count = ARRAY_SIZE(ele_oem_auth_cntr_addr_fields);
+		return ele_oem_auth_cntr_addr_fields;
+	case ELE_GEN_KEY_BLOB_REQ:
+		*count = ARRAY_SIZE(ele_gen_key_blob_addr_fields);
+		return ele_gen_key_blob_addr_fields;
+	case ELE_GET_INFO_REQ:
+		*count = ARRAY_SIZE(ele_get_info_addr_fields);
+		return ele_get_info_addr_fields;
+	case ELE_DEV_ATTEST_REQ:
+		*count = ARRAY_SIZE(ele_dev_attest_addr_fields);
+		return ele_dev_attest_addr_fields;
+	default:
+		*count = 0;
+		return NULL;
+	}
+}
+
+/*
+ * FW-API crypto commands that embed one or more DMA physical addresses in
+ * their payload. On the PSA_COMPLIANT ABI most addresses are written by the
+ * userspace library as a single little-endian 32-bit LSB word (the high half
+ * is always zero), so has_msb is left false for those entries. A few commands
+ * (pub-key-export 0x32, keystore reprov-enable 0x3F) carry an explicit ext/MSB
+ * word ahead of the LSB word, matching the base-API two-word address layout;
+ * their entries set has_msb = true so the MSB word is validated too. See
+ * struct se_cmd_addr_field in ele_common.h for the field semantics.
+ */
+static const struct se_cmd_addr_field ele_pub_key_export_addr_fields[] = {
+	/*
+	 * out_key_addr: the recovered public key output buffer. Its high half
+	 * out_key_addr_ext is data[2] and its low half out_key_addr is data[3];
+	 * the library always writes it via set_phy_addr_to_words(), so it is
+	 * always a DMA address. Its length is out_key_size, the u16 in the low
+	 * half of data[4]. key_identifier (data[1]) is an integer, not an
+	 * address.
+	 */
+	{ .lsb_idx = 3, .msb_idx = 2, .has_msb = true, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 4, .size_mask = 0xFFFFu },		/* out_key_addr */
+};
+
+static const struct se_cmd_addr_field ele_keystore_reprov_en_addr_fields[] = {
+	/*
+	 * Signed message address: a 64-bit physical address split across two
+	 * words. data[0] holds the 32-bit MSB and data[1] holds the 32-bit LSB
+	 * (ELE API spec Table 202, word size = 0x3, so the command is header +
+	 * MSB + LSB only). The address points to the start of the complete
+	 * signed message block (header + 12-byte payload from Table 204 +
+	 * signature); the total block size depends on the signing format and is
+	 * not carried anywhere in the MU payload words. No static
+	 * firmware-defined maximum for the full block is specified. Because this
+	 * is a read-only input buffer (firmware reads and verifies the signed
+	 * block, does not write back through this address), enforcing only the
+	 * start-address range check is acceptable: a rogue caller can at most
+	 * cause firmware to read within the shared-memory window, which is
+	 * memory the caller already owns. Output buffers must be fully bounded;
+	 * input-only buffers are safe with addr-only checks.
+	 */
+	{ .lsb_idx = 1, .msb_idx = 0, .has_msb = true, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = SE_CMD_ADDR_NO_SIZE },			/* signed_msg_addr */
+};
+
+static const struct se_cmd_addr_field ele_keygen_addr_fields[] = {
+	/*
+	 * key @ data[1]: a plaintext private-key output buffer only when the
+	 * KEY_GENERATION PLAINTEXT_KEY flag (bit 3 of the flags byte in the low
+	 * 8 bits of data[8]) is set; otherwise it is an integer key identifier.
+	 * Its length is priv_key_sz, the u16 in the high half of data[8].
+	 */
+	{ .lsb_idx = 1, .flag_idx = 8, .flag_mask = 0x00000008u, .is_addr_when_set = true,
+	  .size_idx = 8, .size_shift = 16, .size_mask = 0xFFFFu },	/* priv_key_addr */
+	/*
+	 * pub_key_addr @ data[9]: always a DMA address. Its length is
+	 * pub_key_sz, the u16 in the low half of data[2].
+	 */
+	{ .lsb_idx = 9, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 2, .size_mask = 0xFFFFu },		/* pub_key_addr */
+};
+
+static const struct se_cmd_addr_field ele_key_exchange_addr_fields[] = {
+	/*
+	 * PSA_COMPLIANT key-exchange payload. key_management_handle is data[0]
+	 * and flags/reserved is data[1]; the four buffer addresses that follow
+	 * are each written unconditionally via set_phy_addr_to_words() (single
+	 * LSB word, high half always zero), so all are always DMA addresses.
+	 * Each address is immediately followed by its full u32 byte length.
+	 */
+	{ .lsb_idx = 2, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 3, .size_mask = 0xFFFFFFFFu },		/* in_content_addr */
+	{ .lsb_idx = 4, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 5, .size_mask = 0xFFFFFFFFu },		/* in_pub_buffer_addr */
+	{ .lsb_idx = 6, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 7, .size_mask = 0xFFFFFFFFu },		/* user_fixed_info_addr */
+	{ .lsb_idx = 8, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 9, .size_mask = 0xFFFFFFFFu },		/* output_addr */
+};
+
+static const struct se_cmd_addr_field ele_key_import_addr_fields[] = {
+	/*
+	 * PSA_COMPLIANT key-import payload. key_management_handle is data[0]
+	 * and flags/reserved is data[1]; the single input buffer address that
+	 * follows is written unconditionally via set_phy_addr_to_words()
+	 * (single LSB word, high half always zero), so it is always a DMA
+	 * address. Its length is the full u32 input_size in data[3].
+	 */
+	{ .lsb_idx = 2, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 3, .size_mask = 0xFFFFFFFFu },		/* input_address */
+};
+
+/* ELE_MAC_REQ: MAC one-go operation. */
+static const struct se_cmd_addr_field ele_mac_addr_fields[] = {
+	/* key: plaintext-key buffer only when the MAC PLAINTEXT_KEY flag is set */
+	{ .lsb_idx = 1, .flag_idx = 5, .flag_mask = 0x00080000u, .is_addr_when_set = true,
+	  .size_idx = 7, .size_mask = 0xFFFFu },		/* key_size */
+	{ .lsb_idx = 2, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 4, .size_mask = 0xFFFFFFFFu },		/* payload_address */
+	{ .lsb_idx = 3, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 5, .size_mask = 0xFFFFu },		/* mac_address */
+	{ .lsb_idx = 8, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 9, .size_mask = 0xFFFFu },		/* context_address */
+};
+
+/* ELE_CIPHER_REQ: symmetric cipher one-go operation. */
+static const struct se_cmd_addr_field ele_cipher_addr_fields[] = {
+	/* key: plaintext-key buffer only when the CIPHER PLAINTEXT_KEY flag is set */
+	{ .lsb_idx = 1, .flag_idx = 3, .flag_mask = 0x00080000u, .is_addr_when_set = true,
+	  .size_idx = 9, .size_mask = 0xFFFFu },		/* key_size */
+	{ .lsb_idx = 2, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 3, .size_mask = 0xFFFFu },		/* iv_address */
+	{ .lsb_idx = 5, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 7, .size_mask = 0xFFFFFFFFu },		/* input_address */
+	{ .lsb_idx = 6, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 8, .size_mask = 0xFFFFFFFFu },		/* output_address */
+	{ .lsb_idx = 10, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 11, .size_mask = 0xFFFFu },		/* context_address */
+};
+
+/*
+ * AEAD encrypt/decrypt legacy command (ELE_AUTH_ENC_REQ, 0x64).
+ * ELE API spec Table 287, word size = 0xD (header + 12 data words):
+ *   data[0]  = cipher_handle
+ *   data[1]  = key_identifier
+ *   data[2]  = IV LSB address
+ *   data[3]  = Reserved[31:24] | Flags[23:16] | IV_size[15:0]
+ *   data[4]  = algorithm
+ *   data[5]  = AAD LSB address
+ *   data[6]  = Reserved[31:16] | AAD_size[15:0]
+ *   data[7]  = Input LSB address
+ *   data[8]  = Output LSB address
+ *   data[9]  = Input size (u32)
+ *   data[10] = Output size (u32)
+ *   data[11] = CRC
+ * IV size is the 16-bit low half of data[3]; AAD size is the 16-bit low half
+ * of data[6]; input and output sizes are full u32 words.
+ */
+static const struct se_cmd_addr_field ele_auth_enc_addr_fields[] = {
+	{ .lsb_idx = 2, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 3, .size_mask = 0xFFFFu },		/* iv_address    (size[15:0]  @ data[3]) */
+	{ .lsb_idx = 5, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 6, .size_mask = 0xFFFFu },		/* aad_address   (size[15:0]  @ data[6]) */
+	{ .lsb_idx = 7, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 9, .size_mask = 0xFFFFFFFFu },		/* input_address (size[31:0]  @ data[9]) */
+	{ .lsb_idx = 8, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 10, .size_mask = 0xFFFFFFFFu },		/* output_address (size[31:0] @ data[10]) */
+};
+
+/* ELE_AUTH_ENC_NEW_REQ: AEAD encrypt/decrypt with internally-generated IV output. */
+#define ELE_AUTH_ENC_IV_OUT_SIZE      12  /* firmware always writes exactly 12 bytes */
+static const struct se_cmd_addr_field ele_auth_enc_new_addr_fields[] = {
+	/* iv_address_in length is packed in the high half of the iv-size word */
+	{ .lsb_idx = 3, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 2, .size_shift = 16, .size_mask = 0xFFFFu },	/* iv_address_in */
+	/* iv_address_out has a fixed firmware-defined length, not carried in msg */
+	{ .lsb_idx = 4, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = SE_CMD_ADDR_NO_SIZE,
+	  .buf_size = ELE_AUTH_ENC_IV_OUT_SIZE },		/* iv_address_out */
+	/* key: plaintext-key buffer only when the PLAINTEXT_KEY flag is set */
+	{ .lsb_idx = 5, .flag_idx = 2, .flag_mask = 0x00000008u, .is_addr_when_set = true,
+	  .size_idx = 7, .size_shift = 16, .size_mask = 0xFFFFu },	/* key_size */
+	{ .lsb_idx = 6, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 7, .size_mask = 0xFFFFu },		/* tag_address */
+	{ .lsb_idx = 8, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 9, .size_mask = 0xFFFFFFFFu },		/* aad_address */
+	{ .lsb_idx = 10, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 11, .size_mask = 0xFFFFFFFFu },		/* input_address */
+	{ .lsb_idx = 12, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 13, .size_mask = 0xFFFFFFFFu },		/* output_address */
+	{ .lsb_idx = 14, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 15, .size_mask = 0xFFFFu },		/* context_address */
+};
+
+/* ELE_SIGNATURE_GENERATE_REQ: digital signature generation. */
+static const struct se_cmd_addr_field ele_sign_gen_addr_fields[] = {
+	/* key: plaintext-key buffer only when GENERATE_SIGN PLAINTEXT_KEY is set */
+	{ .lsb_idx = 1, .flag_idx = 5, .flag_mask = 0x00080000u, .is_addr_when_set = true,
+	  .size_idx = 8, .size_mask = 0xFFFFu },		/* priv_key_size */
+	{ .lsb_idx = 2, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 4, .size_mask = 0xFFFFFFFFu },		/* message_addr */
+	{ .lsb_idx = 3, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 5, .size_mask = 0xFFFFu },		/* signature_addr */
+	{ .lsb_idx = 9, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 11, .size_mask = 0xFFFFu },		/* sm2_pub_key_addr */
+	{ .lsb_idx = 10, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 11, .size_shift = 16,
+	  .size_mask = 0xFFFFu },			/* sm2_id / ml_dsa_ctx addr */
+};
+
+static const struct se_cmd_addr_field ele_pub_key_attest_addr_fields[] = {
+	/*
+	 * PSA_COMPLIANT public-key-attestation payload. sig_gen_hdl is data[0],
+	 * key_identifier data[1], key_attestation_id data[2], attest_algo
+	 * data[3]. The two buffer addresses that follow are each written
+	 * unconditionally via set_phy_addr_to_words() (single LSB word, high
+	 * half always zero), so both are always DMA addresses. Each address is
+	 * immediately followed by its full u32 byte length.
+	 */
+	{ .lsb_idx = 4, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 5, .size_mask = 0xFFFFFFFFu },		/* auth_challenge_addr */
+	{ .lsb_idx = 6, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 7, .size_mask = 0xFFFFFFFFu },		/* certificate_addr */
+};
+
+/* ELE_SIGNATURE_VERIFY_REQ: digital signature verification. */
+static const struct se_cmd_addr_field ele_verify_sign_addr_fields[] = {
+	/* key: plaintext-key buffer unless the VERIFY_SIGN OPAQUE_KEY flag is set */
+	{ .lsb_idx = 1, .flag_idx = 7, .flag_mask = 0x00000008u, .is_addr_when_set = false,
+	  .size_idx = 5, .size_shift = 16, .size_mask = 0xFFFFu },	/* key_size */
+	{ .lsb_idx = 2, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 4, .size_mask = 0xFFFFFFFFu },		/* msg_addr */
+	{ .lsb_idx = 3, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 5, .size_mask = 0xFFFFu },		/* sig_addr */
+	{ .lsb_idx = 10, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 11, .size_mask = 0xFFFFu },		/* sm2_id / ml_dsa_ctx addr */
+};
+
+static const struct se_cmd_addr_field ele_data_storage_addr_fields[] = {
+	/*
+	 * PSA_COMPLIANT data-storage payload. data_storage_handle is data[0],
+	 * flags/reserved is data[1], data_id is data[2]. data_address (data[3])
+	 * is the plaintext data buffer, written unconditionally via
+	 * set_phy_addr_to_words() (single LSB word, high half always zero), so
+	 * it is always a DMA address. Its length is the full u32 data_size in
+	 * data[4].
+	 */
+	{ .lsb_idx = 3, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 4, .size_mask = 0xFFFFFFFFu },		/* data_address */
+};
+
+/* ELE_ASYMMETRIC_ENC_REQ: asymmetric encryption/decryption. */
+static const struct se_cmd_addr_field ele_asym_enc_addr_fields[] = {
+	/* key_id_addr: plaintext-key buffer only when the PLAINTEXT_KEY flag is set */
+	{ .lsb_idx = 1, .flag_idx = 8, .flag_mask = 0x00000008u, .is_addr_when_set = true,
+	  .size_idx = 10, .size_mask = 0xFFFFFFFFu },		/* input_plainkey_size */
+	{ .lsb_idx = 2, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 5, .size_mask = 0xFFFFFFFFu },		/* plaintext_addr */
+	{ .lsb_idx = 3, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 6, .size_mask = 0xFFFFFFFFu },		/* ciphertext_addr */
+	{ .lsb_idx = 4, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 7, .size_mask = 0xFFFFFFFFu },		/* label_addr */
+};
+
+/* ELE_KEY_GENERIC_CRYPTO_REQ: generic crypto operation with a raw key. */
+static const struct se_cmd_addr_field ele_key_generic_crypto_addr_fields[] = {
+	/* key_address length is the u8 key_size in the third byte of the iv-size word */
+	{ .lsb_idx = 1, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 3, .size_shift = 16, .size_mask = 0xFFu },	/* key_address */
+	{ .lsb_idx = 2, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 3, .size_mask = 0xFFFFu },		/* iv_address */
+	{ .lsb_idx = 4, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 5, .size_mask = 0xFFFFu },		/* aad_address */
+	{ .lsb_idx = 6, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 8, .size_mask = 0xFFFFFFFFu },		/* input_address */
+	{ .lsb_idx = 7, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 9, .size_mask = 0xFFFFFFFFu },		/* output_address */
+};
+
+/* ELE_GC_CIPHER_REQ: GC symmetric cipher operation. */
+static const struct se_cmd_addr_field ele_gc_cipher_addr_fields[] = {
+	{ .lsb_idx = 0, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 2, .size_mask = 0xFFFFFFFFu },		/* in_addr */
+	{ .lsb_idx = 1, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 2, .size_mask = 0xFFFFFFFFu },		/* out_addr (shares data_size) */
+	{ .lsb_idx = 3, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 4, .size_mask = 0xFFFFFFFFu },		/* key_addr */
+	{ .lsb_idx = 5, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 6, .size_mask = 0xFFFFFFFFu },		/* iv_addr */
+};
+
+/* ELE_GC_AEAD_REQ: GC AEAD operation. */
+static const struct se_cmd_addr_field ele_gc_aead_addr_fields[] = {
+	{ .lsb_idx = 0, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 2, .size_mask = 0xFFFFFFFFu },		/* in_addr */
+	{ .lsb_idx = 1, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 2, .size_mask = 0xFFFFFFFFu },		/* out_addr (shares data_size) */
+	{ .lsb_idx = 3, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 4, .size_mask = 0xFFFFFFFFu },		/* key_addr */
+	{ .lsb_idx = 5, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 6, .size_mask = 0xFFFFFFFFu },		/* nonce_addr */
+	{ .lsb_idx = 7, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 8, .size_mask = 0xFFFFFFFFu },		/* aad_addr */
+	{ .lsb_idx = 9, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 10, .size_mask = 0xFFFFFFFFu },		/* tag_addr */
+};
+
+/* ELE_GC_ACRYPTO_REQ: GC asymmetric crypto operation. */
+static const struct se_cmd_addr_field ele_gc_acrypto_addr_fields[] = {
+	{ .lsb_idx = 3, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 5, .size_mask = 0xFFFFFFFFu },		/* data_buff1_addr */
+	{ .lsb_idx = 4, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 6, .size_mask = 0xFFFFFFFFu },		/* data_buff2_addr */
+	{ .lsb_idx = 7, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 9, .size_mask = 0xFFFFu },		/* key_buff1_addr */
+	{ .lsb_idx = 8, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 9, .size_shift = 16, .size_mask = 0xFFFFu },	/* key_buff2_addr */
+	{ .lsb_idx = 12, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 13, .size_mask = 0xFFFFu },		/* rsa_label_addr */
+};
+
+/* ELE_GC_AKEY_GEN_REQ: GC asymmetric key generation. */
+static const struct se_cmd_addr_field ele_gc_akey_gen_addr_fields[] = {
+	{ .lsb_idx = 1, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 4, .size_mask = 0xFFFFu },		/* modulus_addr */
+	{ .lsb_idx = 2, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 4, .size_shift = 16, .size_mask = 0xFFFFu },	/* priv_buff_addr */
+	{ .lsb_idx = 3, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 5, .size_mask = 0xFFFFu },		/* pub_buff_addr */
+};
+
+/* ELE_HASH_ONE_GO_REQ: hash one-go operation. */
+static const struct se_cmd_addr_field ele_hash_one_go_addr_fields[] = {
+	{ .lsb_idx = 1, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 6, .size_shift = 16, .size_mask = 0xFFFFu },	/* ctx_addr */
+	{ .lsb_idx = 2, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 4, .size_mask = 0xFFFFFFFFu },		/* input_addr */
+	{ .lsb_idx = 3, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 5, .size_mask = 0xFFFFFFFFu },		/* output_addr */
+};
+
+static const struct se_cmd_addr_field ele_enc_data_storage_addr_fields[] = {
+	/*
+	 * PSA_COMPLIANT encrypted-data-storage payload. data_storage_handle is
+	 * data[0] and data_id is data[1]. data_address (data[2]) is written
+	 * unconditionally via set_phy_addr_to_words() (single LSB word, high
+	 * half always zero), so it is always a DMA address; its length is the
+	 * full u32 data_size in data[3]. iv_address (data[8]) is only written
+	 * when an IV is supplied and is left zero otherwise, so it is an
+	 * optional always-address handled by the zero-address skip; its length
+	 * is the u16 iv_size in the low half of data[9].
+	 */
+	{ .lsb_idx = 2, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 3, .size_mask = 0xFFFFFFFFu },		/* data_address */
+	{ .lsb_idx = 8, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 9, .size_mask = 0xFFFFu },		/* iv_address */
+};
+
+static const struct se_cmd_addr_field ele_rng_get_random_addr_fields[] = {
+	/*
+	 * PSA_COMPLIANT get-random payload. reserved/flags is data[0]; rnd_addr
+	 * (data[1]) is the output buffer, written unconditionally via
+	 * set_phy_addr_to_words() (single LSB word, high half always zero), so
+	 * it is always a DMA address. Its length is the full u32 rnd_size in
+	 * data[2].
+	 */
+	{ .lsb_idx = 1, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 2, .size_mask = 0xFFFFFFFFu },		/* rnd_addr */
+};
+
+static const struct se_cmd_addr_field ele_storage_master_import_addr_fields[] = {
+	/*
+	 * Storage master-import command (ELE_STORAGE_MASTER_IMPORT_REQ).
+	 * Payload layout (data[] = message word minus header word 0):
+	 *   data[0] = storage_handle
+	 *   data[1] = key_store_address  (LSB; high half always zero)
+	 *   data[2] = key_store_size
+	 * The address is set unconditionally via set_phy_addr_to_words() and
+	 * its length is the full u32 key_store_size.
+	 */
+	{ .lsb_idx = 1, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 2, .size_mask = 0xFFFFFFFFu },		/* key_store_address */
+};
+
+const struct se_cmd_addr_field *ele_fw_cmd_addr_fields(u8 cmd, size_t *count)
+{
+	switch (cmd) {
+	case ELE_PUB_KEY_EXPORT_REQ:
+		*count = ARRAY_SIZE(ele_pub_key_export_addr_fields);
+		return ele_pub_key_export_addr_fields;
+	case ELE_KEYSTORE_REPROV_ENABLE_REQ:
+		*count = ARRAY_SIZE(ele_keystore_reprov_en_addr_fields);
+		return ele_keystore_reprov_en_addr_fields;
+	case ELE_KEYGEN_REQ:
+		*count = ARRAY_SIZE(ele_keygen_addr_fields);
+		return ele_keygen_addr_fields;
+	case ELE_KEY_EXCHANGE_REQ:
+		*count = ARRAY_SIZE(ele_key_exchange_addr_fields);
+		return ele_key_exchange_addr_fields;
+	case ELE_KEY_IMPORT_REQ:
+		*count = ARRAY_SIZE(ele_key_import_addr_fields);
+		return ele_key_import_addr_fields;
+	case ELE_MAC_REQ:
+		*count = ARRAY_SIZE(ele_mac_addr_fields);
+		return ele_mac_addr_fields;
+	case ELE_CIPHER_REQ:
+		*count = ARRAY_SIZE(ele_cipher_addr_fields);
+		return ele_cipher_addr_fields;
+	case ELE_AUTH_ENC_REQ:
+		*count = ARRAY_SIZE(ele_auth_enc_addr_fields);
+		return ele_auth_enc_addr_fields;
+	case ELE_AUTH_ENC_NEW_REQ:
+		*count = ARRAY_SIZE(ele_auth_enc_new_addr_fields);
+		return ele_auth_enc_new_addr_fields;
+	case ELE_SIGNATURE_GENERATE_REQ:
+		*count = ARRAY_SIZE(ele_sign_gen_addr_fields);
+		return ele_sign_gen_addr_fields;
+	case ELE_PUB_KEY_ATTEST_REQ:
+		*count = ARRAY_SIZE(ele_pub_key_attest_addr_fields);
+		return ele_pub_key_attest_addr_fields;
+	case ELE_SIGNATURE_VERIFY_REQ:
+		*count = ARRAY_SIZE(ele_verify_sign_addr_fields);
+		return ele_verify_sign_addr_fields;
+	case ELE_DATA_STORAGE_REQ:
+		*count = ARRAY_SIZE(ele_data_storage_addr_fields);
+		return ele_data_storage_addr_fields;
+	case ELE_ENC_DATA_STORAGE_REQ:
+		*count = ARRAY_SIZE(ele_enc_data_storage_addr_fields);
+		return ele_enc_data_storage_addr_fields;
+	case ELE_ASYMMETRIC_ENC_REQ:
+		*count = ARRAY_SIZE(ele_asym_enc_addr_fields);
+		return ele_asym_enc_addr_fields;
+	case ELE_KEY_GENERIC_CRYPTO_REQ:
+		*count = ARRAY_SIZE(ele_key_generic_crypto_addr_fields);
+		return ele_key_generic_crypto_addr_fields;
+	case ELE_GC_CIPHER_REQ:
+		*count = ARRAY_SIZE(ele_gc_cipher_addr_fields);
+		return ele_gc_cipher_addr_fields;
+	case ELE_GC_AEAD_REQ:
+		*count = ARRAY_SIZE(ele_gc_aead_addr_fields);
+		return ele_gc_aead_addr_fields;
+	case ELE_GC_ACRYPTO_REQ:
+		*count = ARRAY_SIZE(ele_gc_acrypto_addr_fields);
+		return ele_gc_acrypto_addr_fields;
+	case ELE_GC_AKEY_GEN_REQ:
+		*count = ARRAY_SIZE(ele_gc_akey_gen_addr_fields);
+		return ele_gc_akey_gen_addr_fields;
+	case ELE_HASH_ONE_GO_REQ:
+		*count = ARRAY_SIZE(ele_hash_one_go_addr_fields);
+		return ele_hash_one_go_addr_fields;
+	case ELE_RNG_GET_RANDOM_REQ:
+		*count = ARRAY_SIZE(ele_rng_get_random_addr_fields);
+		return ele_rng_get_random_addr_fields;
+	case ELE_STORAGE_MASTER_IMPORT_REQ:
+		*count = ARRAY_SIZE(ele_storage_master_import_addr_fields);
+		return ele_storage_master_import_addr_fields;
+	default:
+		*count = 0;
+		return NULL;
+	}
+}
+
+/*
+ * FW API for Command Receiver.
+ *
+ * Storage master-export response (ELE_STORAGE_MASTER_EXPORT_REQ).
+ * The cmd_receiver sends this response to firmware to supply the
+ * output buffer address. Payload layout:
+ *   data[0] = storage_handle
+ *   data[1] = rsp_code
+ *   data[2] = key_store_export_address  (LSB; high half always zero)
+ * No length word is present in the response itself; the export size is
+ * taken from the FW command received earlier (key_store_size). The size
+ * is stored in buf_size and used as a literal byte count by
+ * se_val_cmd_addrs() when size_idx == SE_CMD_ADDR_NO_SIZE and buf_size
+ * is non-zero. ele_set_sz_in_field_addr() writes it before the response
+ * is validated.
+ */
+static struct se_cmd_addr_field ele_storage_master_export_addr_fields[] = {
+	{ .lsb_idx = 2, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = SE_CMD_ADDR_NO_SIZE, .buf_size = 0 },	/* key_store_export_address */
+};
+
+/*
+ * Storage chunk-get response (ELE_STORAGE_CHUNK_GET_REQ).
+ * The cmd_receiver fills in the chunk buffer address and its size so
+ * firmware can DMA the chunk data into the kernel's coherent buffer.
+ * Payload layout:
+ *   data[0] = chunk_size
+ *   data[1] = chunk_addr  (LSB; high half always zero)
+ *   data[2] = rsp_code
+ * The size word precedes the address in the message.
+ */
+static const struct se_cmd_addr_field ele_storage_chunk_get_addr_fields[] = {
+	{ .lsb_idx = 1, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = 0, .size_mask = 0xFFFFFFFFu },		/* chunk_addr */
+};
+
+/*
+ * Storage chunk-export response (ELE_STORAGE_CHUNK_EXPORT_REQ).
+ * The cmd_receiver supplies the output buffer address. Payload layout:
+ *   data[0] = rsp_code
+ *   data[1] = chunk_export_address  (LSB; high half always zero)
+ * No length word is present in the response itself; the export size is
+ * taken from the FW command received earlier (chunk_size). The size
+ * is stored in buf_size and used as a literal byte count by
+ * se_val_cmd_addrs() when size_idx == SE_CMD_ADDR_NO_SIZE and buf_size
+ * is non-zero. ele_set_sz_in_field_addr() writes it before the response
+ * is validated.
+ */
+static struct se_cmd_addr_field ele_storage_chunk_export_addr_fields[] = {
+	{ .lsb_idx = 1, .flag_idx = SE_CMD_ADDR_ALWAYS,
+	  .size_idx = SE_CMD_ADDR_NO_SIZE, .buf_size = 0 },	/* chunk_export_address */
+};
+
+/*
+ * Record the export buffer size from the FW command into buf_size so
+ * se_val_cmd_addrs() can range-check the full response buffer. Called from
+ * fw_api_specific_ops() when the cmd_receiver reads the FW command.
+ */
+void ele_set_sz_in_field_addr(u8 cmd, u32 size)
+{
+	switch (cmd) {
+	case ELE_STORAGE_MASTER_EXPORT_REQ:
+		ele_storage_master_export_addr_fields[0].buf_size = size;
+		break;
+	case ELE_STORAGE_CHUNK_EXPORT_REQ:
+		ele_storage_chunk_export_addr_fields[0].buf_size = size;
+		break;
+	}
+}
+
+/*
+ * Return the address-field descriptor table for a cmd_receiver response
+ * message (rsp_tag), or NULL when the response embeds no DMA addresses.
+ * count is set to the number of entries. Only the three storage responses
+ * that supply a kernel buffer address to firmware are covered here;
+ * ELE_STORAGE_EXPORT_FINISH_REQ, ELE_STORAGE_CHUNK_GET_DONE_REQ, and
+ * ELE_STORAGE_CHUNK_DELETE_REQ carry no DMA addresses and return NULL.
+ */
+const struct se_cmd_addr_field *ele_fw_rsp_addr_fields(u8 cmd, size_t *count)
+{
+	switch (cmd) {
+	case ELE_STORAGE_MASTER_EXPORT_REQ:
+		*count = ARRAY_SIZE(ele_storage_master_export_addr_fields);
+		return ele_storage_master_export_addr_fields;
+	case ELE_STORAGE_CHUNK_GET_REQ:
+		*count = ARRAY_SIZE(ele_storage_chunk_get_addr_fields);
+		return ele_storage_chunk_get_addr_fields;
+	case ELE_STORAGE_CHUNK_EXPORT_REQ:
+		*count = ARRAY_SIZE(ele_storage_chunk_export_addr_fields);
+		return ele_storage_chunk_export_addr_fields;
+	default:
+		*count = 0;
+		return NULL;
+	}
+}
diff --git a/drivers/firmware/imx/se_ctrl.c b/drivers/firmware/imx/se_ctrl.c
index a8974eef190b..8922399ee1fb 100644
--- a/drivers/firmware/imx/se_ctrl.c
+++ b/drivers/firmware/imx/se_ctrl.c
@@ -4,6 +4,7 @@
  */
 
 #include <linux/bitfield.h>
+#include <linux/cleanup.h>
 #include <linux/completion.h>
 #include <linux/delay.h>
 #include <linux/dev_printk.h>
@@ -15,6 +16,7 @@
 #include <linux/genalloc.h>
 #include <linux/init.h>
 #include <linux/io.h>
+#include <linux/kref.h>
 #include <linux/miscdevice.h>
 #include <linux/module.h>
 #include <linux/of_platform.h>
@@ -23,22 +25,21 @@
 #include <linux/slab.h>
 #include <linux/string.h>
 #include <linux/sys_soc.h>
+#include <uapi/linux/se_ioctl.h>
 
 #include "ele_base_msg.h"
 #include "ele_common.h"
+#include "ele_fw_api.h"
 #include "se_ctrl.h"
 
+/* Maximum response buffer size in bytes for debug-dump replies. */
+#define MAX_ALLOWED_RX_MSG_SZ		ELE_DEBUG_DUMP_RSP_SZ
+#define MAX_ALLOWED_TX_MSG_SZ		SZ_4K
+
 #define MAX_SOC_INFO_DATA_SZ		256
 #define MBOX_TX_NAME			"tx"
 #define MBOX_RX_NAME			"rx"
 
-#define SE_TYPE_STR_DBG			"dbg"
-#define SE_TYPE_STR_HSM			"hsm"
-
-#define SE_TYPE_ID_DBG			0x1
-
-#define SE_TYPE_ID_HSM			0x2
-
 struct se_soc_dev_regn {
 	bool soc_dev_registered;
 	struct soc_device *soc_dev;
@@ -133,6 +134,13 @@ char *get_se_if_name(u8 se_if_id)
 	return "unknown";
 }
 
+static u32 get_se_soc_id(struct se_if_priv *priv)
+{
+	const struct se_if_node *if_node = device_get_match_data(priv->dev);
+
+	return if_node->se_info->soc_id;
+}
+
 static struct se_fw_load_info *get_load_fw_instance(struct se_if_priv *priv)
 {
 	return &priv->load_fw;
@@ -284,11 +292,319 @@ static int get_se_soc_info(struct se_if_priv *priv, const struct se_soc_info *se
 	return 0;
 }
 
+static int load_firmware(struct se_if_priv *priv, const u8 *se_img_file_to_load)
+{
+	const struct firmware *fw = NULL;
+	dma_addr_t se_fw_dma_addr;
+	u32 se_fw_buf_len;
+	void *se_fw_buf;
+	int ret;
+
+	if (!se_img_file_to_load) {
+		dev_err(priv->dev, "FW image is not provided.");
+		return -EINVAL;
+	}
+	ret = request_firmware(&fw, se_img_file_to_load, priv->dev);
+	if (ret)
+		return ret;
+
+	if (fw->size > U32_MAX) {
+		ret = -EFBIG;
+		release_firmware(fw);
+		return ret;
+	}
+	dev_info(priv->dev, "loading firmware %s.", se_img_file_to_load);
+
+	/*
+	 * Serialize access to priv_dev_ctx shared memory to prevent pos
+	 * corruption if two driver-internal callers run concurrently (e.g.
+	 * ele_get_info() racing with load_firmware()).
+	 */
+	scoped_guard(mutex, &priv->priv_dev_ctx->fops_lock) {
+		se_fw_buf_len = fw->size;
+		ret = get_shared_mem_slot(priv->priv_dev_ctx,
+					  &se_fw_buf_len, &se_fw_dma_addr,
+					  &se_fw_buf);
+		if (ret) {
+			dev_err(priv->dev, "Failed to allocate firmware shared buffer: %d\n",
+				ret);
+			release_firmware(fw);
+			return ret;
+		}
+
+		memcpy(se_fw_buf, fw->data, fw->size);
+		ret = ele_fw_authenticate(priv, se_fw_dma_addr, se_fw_dma_addr);
+		if (ret < 0) {
+			dev_err(priv->dev,
+				"Error %pe: Authenticate & load SE firmware %s.",
+				ERR_PTR(ret), se_img_file_to_load);
+			ret = -EPERM;
+		}
+		if (!se_is_fw_busy_ctx(priv->priv_dev_ctx))
+			se_dev_ctx_shared_mem_cleanup(priv->priv_dev_ctx);
+	}
+
+	release_firmware(fw);
+
+	return ret;
+}
+
+static int se_load_firmware(struct se_if_priv *priv)
+{
+	struct se_fw_load_info *load_fw = get_load_fw_instance(priv);
+	int ret = 0;
+
+	guard(mutex)(&load_fw->load_fw_lock);
+	if (!load_fw->is_fw_tobe_loaded)
+		return 0;
+
+	if (load_fw->imem.state == ELE_IMEM_STATE_BAD) {
+		ret = load_firmware(priv, load_fw->se_fw_img_nm->prim_fw_nm_in_rfs);
+		if (ret) {
+			dev_err(priv->dev, "Failed to load boot firmware.");
+			return -EPERM;
+		}
+	}
+
+	ret = load_firmware(priv, load_fw->se_fw_img_nm->seco_fw_nm_in_rfs);
+	if (ret) {
+		dev_err(priv->dev, "Failed to load runtime firmware.");
+		return -EPERM;
+	}
+
+	load_fw->is_fw_tobe_loaded = false;
+
+	return ret;
+}
+
+static int init_se_shared_mem(struct se_if_device_ctx *dev_ctx)
+{
+	struct se_shared_mem_mgmt_info *se_shared_mem_mgmt = &dev_ctx->se_shared_mem_mgmt;
+	struct se_if_priv *priv = dev_ctx->priv;
+
+	INIT_LIST_HEAD(&se_shared_mem_mgmt->pending_out);
+	INIT_LIST_HEAD(&se_shared_mem_mgmt->pending_in);
+
+	if (priv->mem_pool)
+		INIT_LIST_HEAD(&se_shared_mem_mgmt->mem_pool_buf_list);
+
+	se_shared_mem_mgmt->non_secure_mem.ptr =
+			dma_alloc_coherent(priv->dev, MAX_DATA_SIZE_PER_USER,
+					   &se_shared_mem_mgmt->non_secure_mem.dma_addr,
+					   GFP_KERNEL);
+	if (!se_shared_mem_mgmt->non_secure_mem.ptr)
+		return -ENOMEM;
+
+	se_shared_mem_mgmt->non_secure_mem.size = MAX_DATA_SIZE_PER_USER;
+	se_shared_mem_mgmt->non_secure_mem.pos = 0;
+
+	return 0;
+}
+
+static void cleanup_se_shared_mem(struct se_if_device_ctx *dev_ctx, bool reclaim)
+{
+	struct se_shared_mem_mgmt_info *se_shared_mem_mgmt = &dev_ctx->se_shared_mem_mgmt;
+	struct se_if_priv *priv = dev_ctx->priv;
+	bool free_dma_buf;
+
+	/*
+	 * mem_pool_buf_list is only initialised for interfaces that own a
+	 * gen_pool (priv->mem_pool != NULL). On interfaces without a pool
+	 * (e.g. imx93, which has no pool_name) the list head is left
+	 * zero-filled, so se_cleanup_mem_pool_buf() must not walk it here or
+	 * list_for_each_entry_safe() would dereference a NULL head and panic
+	 * the kernel on close/teardown. Skip the pool cleanup entirely when
+	 * there is no pool; there is nothing to reclaim in that case.
+	 */
+	if (priv->mem_pool)
+		se_cleanup_mem_pool_buf(dev_ctx, reclaim);
+
+	/* Guard against being called before shared memory was ever allocated
+	 * (e.g. probe failure before dma_alloc_coherent succeeded).
+	 */
+	if (!se_shared_mem_mgmt->non_secure_mem.ptr)
+		return;
+
+	/*
+	 * Decide whether the DMA buffer can be released before touching the
+	 * pending lists. se_dev_ctx_shared_mem_cleanup() resets
+	 * non_secure_mem.pos, so the "nothing staged" test must be sampled
+	 * here first. When reclaim is false the buffer is released only if no
+	 * data is still staged for the firmware; otherwise the enclave may
+	 * still be DMA-ing into it and the buffer is deliberately leaked to
+	 * avoid a DMA-after-free.
+	 */
+	free_dma_buf = reclaim || !se_shared_mem_mgmt->non_secure_mem.pos;
+
+	/*
+	 * Free any se_buf_desc items that were never consumed (e.g. when the
+	 * fd is closed while pending I/O buffers are still listed). This must
+	 * happen before the DMA backing memory is released to avoid a leak.
+	 */
+	se_dev_ctx_shared_mem_cleanup(dev_ctx);
+
+	if (free_dma_buf) {
+		dma_free_coherent(priv->dev, MAX_DATA_SIZE_PER_USER,
+				  se_shared_mem_mgmt->non_secure_mem.ptr,
+				  se_shared_mem_mgmt->non_secure_mem.dma_addr);
+	}
+
+	/*
+	 * Drop the host-side tracking unconditionally. On the reclaim path the
+	 * buffer has been freed. On the deliberate-leak path the buffer is
+	 * abandoned on purpose, so clearing the pointer here guarantees a later
+	 * cleanup pass (e.g. se_if_priv_release()) cannot double-free it.
+	 */
+	se_shared_mem_mgmt->non_secure_mem.ptr = NULL;
+	se_shared_mem_mgmt->non_secure_mem.dma_addr = 0;
+	se_shared_mem_mgmt->non_secure_mem.size = 0;
+	se_shared_mem_mgmt->non_secure_mem.pos = 0;
+}
+
+static int se_dev_ctx_cpy_out_data(struct se_if_device_ctx *dev_ctx)
+{
+	struct se_shared_mem_mgmt_info *se_shared_mem_mgmt = &dev_ctx->se_shared_mem_mgmt;
+	struct se_if_priv *priv = dev_ctx->priv;
+	struct se_buf_desc *b_desc, *temp;
+	bool do_cpy = true;
+
+	list_for_each_entry_safe(b_desc, temp, &se_shared_mem_mgmt->pending_out, link) {
+		if (b_desc->usr_buf_ptr && b_desc->shared_buf_ptr && do_cpy) {
+			dev_dbg(priv->dev, "Copying output data to user.");
+			if (do_cpy && copy_to_user(b_desc->usr_buf_ptr,
+						   b_desc->shared_buf_ptr,
+						   b_desc->size)) {
+				dev_err(priv->dev, "Failure copying output data to user.");
+				do_cpy = false;
+			}
+		}
+
+		if (b_desc->shared_buf_ptr)
+			memset(b_desc->shared_buf_ptr, 0, b_desc->size);
+
+		list_del(&b_desc->link);
+		kfree(b_desc);
+	}
+
+	return do_cpy ? 0 : -EFAULT;
+}
+
+/*
+ * Clean the used Shared Memory space,
+ * whether its Input Data copied from user buffers, or
+ * Data received from FW.
+ */
+void se_dev_ctx_shared_mem_cleanup(struct se_if_device_ctx *dev_ctx)
+{
+	struct se_shared_mem_mgmt_info *se_shared_mem_mgmt = &dev_ctx->se_shared_mem_mgmt;
+	struct list_head *pending_lists[] = {&se_shared_mem_mgmt->pending_in,
+						&se_shared_mem_mgmt->pending_out};
+	struct se_buf_desc *b_desc, *temp;
+	bool is_fw_busy_dev_ctx;
+	int i;
+
+	/*
+	 * If this context is the one that caused a firmware timeout the shared
+	 * DMA buffers may still be actively read/written by the firmware.
+	 */
+	is_fw_busy_dev_ctx = se_is_fw_busy_ctx(dev_ctx);
+
+	for (i = 0; i < ARRAY_SIZE(pending_lists); i++) {
+		list_for_each_entry_safe(b_desc, temp, pending_lists[i], link) {
+			if (!is_fw_busy_dev_ctx && b_desc->shared_buf_ptr)
+				memset(b_desc->shared_buf_ptr, 0, b_desc->size);
+
+			list_del(&b_desc->link);
+			kfree(b_desc);
+		}
+	}
+
+	/*
+	 * Keep non_secure_mem.pos non-zero while this context still owns an
+	 * outstanding firmware transaction. A non-zero pos is the marker that
+	 * data is still staged for the enclave, which cleanup_se_shared_mem()
+	 * uses to decide the buffer must be leaked rather than freed. Resetting
+	 * it here would let a later teardown pass free a buffer the enclave may
+	 * still be DMA-ing into.
+	 */
+	if (!is_fw_busy_dev_ctx)
+		se_shared_mem_mgmt->non_secure_mem.pos = 0;
+}
+
+static struct se_buf_desc *add_b_desc_to_pending_list(void *shared_ptr_with_pos,
+						      struct se_ioctl_setup_iobuf *io,
+						      struct se_if_device_ctx *dev_ctx)
+{
+	struct se_shared_mem_mgmt_info *se_shared_mem_mgmt = &dev_ctx->se_shared_mem_mgmt;
+	struct se_buf_desc *b_desc = NULL;
+
+	b_desc = kzalloc_obj(*b_desc, GFP_KERNEL);
+	if (!b_desc)
+		return ERR_PTR(-ENOMEM);
+
+	b_desc->shared_buf_ptr = shared_ptr_with_pos;
+	b_desc->usr_buf_ptr = u64_to_user_ptr(io->user_buf);
+	b_desc->size = io->length;
+
+	if (io->flags & SE_IO_BUF_FLAGS_IS_INPUT) {
+		/*
+		 * buffer is input:
+		 * add an entry in the "pending input buffers" list so
+		 * that copied data can be cleaned from shared memory
+		 * later.
+		 */
+		list_add_tail(&b_desc->link, &se_shared_mem_mgmt->pending_in);
+	} else {
+		/*
+		 * buffer is output:
+		 * add an entry in the "pending out buffers" list so data
+		 * can be copied to user space when receiving Secure-Enclave
+		 * response.
+		 */
+		list_add_tail(&b_desc->link, &se_shared_mem_mgmt->pending_out);
+	}
+
+	return b_desc;
+}
+
+static void se_if_open_gate_release(struct kref *kref)
+{
+	struct se_if_open_gate *gate =
+		container_of(kref, struct se_if_open_gate, refcount);
+
+	kfree(gate);
+}
+
+static bool se_if_open_gate_get(struct se_if_open_gate *gate)
+{
+	if (!gate)
+		return false;
+
+	return kref_get_unless_zero(&gate->refcount);
+}
+
+static void se_if_open_gate_put(struct se_if_open_gate *gate)
+{
+	if (gate)
+		kref_put(&gate->refcount, se_if_open_gate_release);
+}
+
+/*
+ * Distinct lockdep class for the internal priv_dev_ctx fops_lock. Taking it
+ * while an open context's fops_lock is held (for example a firmware load
+ * triggered from an ioctl) is valid hierarchical locking, but shares the same
+ * class as the per-open fops_lock and would otherwise be misreported as
+ * recursive locking by lockdep.
+ */
+static struct lock_class_key se_priv_ctx_fops_key;
+
 static int init_misc_device_context(struct se_if_priv *priv, int ch_id,
-				    struct se_if_device_ctx **new_dev_ctx)
+				    struct se_if_device_ctx **new_dev_ctx,
+				    const struct file_operations *se_if_fops)
 {
 	const char *err_str = "Failed to allocate memory";
 	struct se_if_device_ctx *dev_ctx;
+	struct se_if_open_gate *gate = NULL;
 	int ret = -ENOMEM;
 
 	dev_ctx = kzalloc_obj(*dev_ctx, GFP_KERNEL);
@@ -296,19 +612,57 @@ static int init_misc_device_context(struct se_if_priv *priv, int ch_id,
 	if (!dev_ctx)
 		return ret;
 
+	dev_ctx->priv = priv;
 	dev_ctx->devname = kasprintf(GFP_KERNEL, "%s0_ch%d",
 				     get_se_if_name(priv->if_defs->se_if_type),
 				     ch_id);
 	if (!dev_ctx->devname)
 		goto exit;
 
-	dev_ctx->priv = priv;
+	mutex_init(&dev_ctx->fops_lock);
+	lockdep_set_class(&dev_ctx->fops_lock, &se_priv_ctx_fops_key);
+
+	kref_init(&dev_ctx->refcount);
+	dev_ctx->cleanup_done = false;
 	*new_dev_ctx = dev_ctx;
+	set_se_rcv_msg_timeout(dev_ctx, SE_RCV_MSG_DEFAULT_TIMEOUT_MS);
+
+	ret = init_se_shared_mem(dev_ctx);
+	if (ret < 0)
+		goto exit;
+
+	gate = kzalloc_obj(*gate, GFP_KERNEL);
+	if (!gate) {
+		ret = -ENOMEM;
+		goto exit;
+	}
+
+	mutex_init(&gate->lock);
+	kref_init(&gate->refcount);    /* device-owned reference */
+	gate->priv = priv;
+	gate->dying = false;
+	priv->open_gate = gate;
+
+	/*
+	 * The miscdevice storage is now owned by the open gate object.
+	 * priv->priv_dev_ctx still keeps a pointer to that miscdevice.
+	 */
+	dev_ctx->miscdev = &gate->miscdev;
+
+	dev_ctx->miscdev->name = dev_ctx->devname;
+	dev_ctx->miscdev->minor = MISC_DYNAMIC_MINOR;
+	dev_ctx->miscdev->fops = se_if_fops;
+	dev_ctx->miscdev->parent = priv->dev;
 
 	return 0;
 exit:
 	*new_dev_ctx = NULL;
 
+	if (gate) {
+		priv->open_gate = NULL;
+		se_if_open_gate_put(gate);
+	}
+	cleanup_se_shared_mem(dev_ctx, true);
 	kfree(dev_ctx->devname);
 	kfree(dev_ctx);
 	return dev_err_probe(priv->dev, ret, "%s", err_str);
@@ -329,9 +683,25 @@ static int se_if_request_channel(struct device *dev, struct mbox_chan **chan,
 	return 0;
 }
 
+/*
+ * Forward declarations. se_if_probe_cleanup() and se_if_probe() are kept
+ * together as the teardown/probe pair, but several helpers, the file
+ * operations table and the firmware-busy work handler they reference are
+ * defined further down in this file.
+ */
+static void dlink_dev_ctx(struct se_if_device_ctx *dev_ctx);
+static void cleanup_dev_ctx(struct se_if_device_ctx *dev_ctx, bool is_fclose);
+static void se_clear_fw_busy(struct se_if_priv *priv);
+static void se_if_dev_ctx_release(struct kref *kref);
+static void se_if_priv_release(struct kref *kref);
+static int se_if_misc_register(struct se_if_priv *priv);
+static void se_fw_busy_work(struct work_struct *work);
+static const struct file_operations se_if_fops;
+
 static void se_if_probe_cleanup(void *plat_dev)
 {
 	struct platform_device *pdev = plat_dev;
+	struct se_if_device_ctx *dev_ctx;
 	struct device *dev = &pdev->dev;
 	struct se_if_priv *priv;
 
@@ -339,31 +709,148 @@ static void se_if_probe_cleanup(void *plat_dev)
 	if (!priv)
 		return;
 
+	/*
+	 * Announce teardown, then wake any in-flight waiter. going_away makes
+	 * ele_msg_send_rcv() bail out instead of arming a new transaction and
+	 * lets ele_msg_rcv() tell a teardown-forced completion apart from a
+	 * real response; it must be set before complete_all().
+	 *
+	 * Set it under clbk_rx_lock, not se_if_cmd_lock: se_if_cmd_lock is held
+	 * across the whole blocking transaction, so taking it here would stall
+	 * unbind for a full receive-timeout. clbk_rx_lock is the short spinlock
+	 * ele_msg_send_rcv() holds while arming, so this closes the lost-wakeup
+	 * window - the sender either sees going_away and bails before arming, or
+	 * armed first and this store (and complete_all()) is ordered after its
+	 * reinit_completion() - and supplies the ordering the relaxed atomics do
+	 * not.
+	 */
+	scoped_guard(spinlock_irqsave, &priv->waiting_rsp_clbk_hdl.clbk_rx_lock)
+		atomic_set(&priv->going_away, 1);
+	/*
+	 * Wake the waiter before iterating the device-context list. It sleeps on
+	 * this completion holding dev_ctx->fops_lock, which cleanup_dev_ctx()
+	 * below also takes, so completing first avoids an unbind hang. Runs
+	 * outside clbk_rx_lock; the going_away store above already orders it
+	 * against the arming path.
+	 */
+	complete_all(&priv->waiting_rsp_clbk_hdl.done);
+
+	/*
+	 * Mark the private device context as cleanup_done first.
+	 * This prevents new device contexts from being created in open().
+	 */
+	if (priv->priv_dev_ctx) {
+		/*
+		 * Mark cleanup_done under fops_lock so that se_if_fops_open(),
+		 * which checks cleanup_done while holding fops_lock, cannot
+		 * race past this and add a new device context after teardown.
+		 */
+		scoped_guard(mutex, &priv->priv_dev_ctx->fops_lock)
+			priv->priv_dev_ctx->cleanup_done = true;
+
+		if (priv->open_gate) {
+			scoped_guard(mutex, &priv->open_gate->lock) {
+				priv->open_gate->dying = true;
+				priv->open_gate->priv = NULL;
+			}
+		}
+
+		/*
+		 * misc_register() is deferred to the end of probe, so the
+		 * device may have a miscdev set up but never registered if
+		 * probe failed before se_if_misc_register(). Only deregister
+		 * when registration actually succeeded.
+		 */
+		if (priv->open_gate && priv->open_gate->registered &&
+		    priv->priv_dev_ctx->miscdev)
+			misc_deregister(priv->priv_dev_ctx->miscdev);
+	}
+
+	while (true) {
+		dev_ctx = NULL;
+
+		scoped_guard(mutex, &priv->modify_lock) {
+			if (list_empty(&priv->dev_ctx_list))
+				goto out_done;
+
+			dev_ctx = list_first_entry(&priv->dev_ctx_list,
+						   struct se_if_device_ctx, link);
+
+			/* pin this context so close() cannot free it under us */
+			kref_get(&dev_ctx->refcount);
+			dlink_dev_ctx(dev_ctx);
+		}
+
+		/*
+		 * Local cleanup outside the global lock avoids ABBA deadlock
+		 * with paths that already take dev_ctx->fops_lock first.
+		 */
+		cleanup_dev_ctx(dev_ctx, false);
+		kref_put(&dev_ctx->refcount, se_if_dev_ctx_release);
+	}
+out_done:
+
+	/*
+	 * Drain any in-flight synchronous sender before releasing the mailbox
+	 * channels. ele_msg_send_rcv() holds se_if_cmd_lock across the entire
+	 * transaction, including ele_msg_send()'s mbox_send_message() on
+	 * priv->tx_chan. going_away is checked and the transaction armed under
+	 * clbk_rx_lock, but the mbox_send_message() itself runs after that
+	 * spinlock is dropped, so a sender that passed the going_away check
+	 * just before teardown set it could still be about to touch tx_chan
+	 * when we free it here - a use-after-free in the mailbox layer.
+	 *
+	 * Acquire and immediately release se_if_cmd_lock as a barrier: it waits
+	 * for such a sender to finish its transaction and drop the lock. This
+	 * cannot stall unbind for a full receive timeout - going_away is
+	 * already set and complete_all() has already woken any waiter, so an
+	 * in-flight transaction only unwinds to -ENODEV before releasing the
+	 * lock. It also cannot deadlock: the dev_ctx_list loop above has
+	 * finished (teardown holds no se_if_cmd_lock of its own here) and a
+	 * racing userspace close, which takes fops_lock then se_if_cmd_lock,
+	 * bails out of ele_msg_send_rcv() with -ENODEV without waiting. After
+	 * this barrier no sender can enter or remain inside mbox_send_message(),
+	 * so freeing the channels below cannot race it.
+	 */
+	scoped_guard(mutex, &priv->se_if_cmd_lock) {
+		;
+	}
+
+	/*
+	 * Free the rx mailbox channel before cancelling fw_busy_work.
+	 * se_if_rx_callback() runs from the rx channel and can schedule
+	 * fw_busy_work when a late response arrives. If the channel were still
+	 * live after cancel_work_sync(), a callback could re-arm the work and
+	 * later dereference priv after it has been freed. Releasing the rx
+	 * channel first guarantees no further callbacks, so the subsequent
+	 * cancel_work_sync() is final.
+	 */
 	if (priv->rx_chan)
 		mbox_free_channel(priv->rx_chan);
 	if (priv->tx_chan)
 		mbox_free_channel(priv->tx_chan);
 
 	/*
-	 * Being device managed buffer, no need to free the buffer allocated
-	 * in se probe to store encrypted IMEM.
+	 * A timed-out synchronous command may have retained a dev_ctx through
+	 * priv->fw_busy_dev_ctx even after the fd was closed and the context was
+	 * removed from dev_ctx_list. If no late response arrived, release that
+	 * retained context during driver teardown.
+	 *
+	 * se_clear_fw_busy() is idempotent and internally checks
+	 * priv->fw_busy_dev_ctx under fw_busy_lock.
 	 */
+	se_clear_fw_busy(priv);
+	cancel_work_sync(&priv->fw_busy_work);
 
 	/*
-	 * No need to check, if reserved memory is allocated
-	 * before calling for its release. Or clearing the
-	 * un-set bit.
+	 * Being device managed buffer, no need to free the buffer allocated
+	 * in se probe to store encrypted IMEM.
 	 */
-	of_reserved_mem_device_release(dev);
 
 	dev_set_drvdata(dev, NULL);
 
-	if (priv->priv_dev_ctx) {
-		kfree(priv->priv_dev_ctx->devname);
-		kfree(priv->priv_dev_ctx);
-	}
-
-	kfree(priv);
+	/* Drop the initial reference - priv will be freed when last fd closes */
+	kref_put(&priv->refcount, se_if_priv_release);
 }
 
 static int se_if_probe(struct platform_device *pdev)
@@ -386,15 +873,30 @@ static int se_if_probe(struct platform_device *pdev)
 		return -ENOMEM;
 
 	priv->dev = dev;
+	/*
+	 * Pin the parent device for the lifetime of priv. A file descriptor may
+	 * stay open after the device is unbound; close() then still passes
+	 * priv->dev to dma_free_coherent()/dev_warn(). Without this reference
+	 * the struct device could be freed while priv->dev still points at it,
+	 * so the reference is dropped in se_if_priv_release() via put_device().
+	 */
+	get_device(priv->dev);
+	kref_init(&priv->refcount);
 	priv->if_defs = &if_node->if_defs;
 	dev_set_drvdata(dev, priv);
 
 	mutex_init(&priv->se_if_cmd_lock);
+	mutex_init(&priv->modify_lock);
 	spin_lock_init(&priv->cmd_receiver_clbk_hdl.clbk_rx_lock);
 	spin_lock_init(&priv->waiting_rsp_clbk_hdl.clbk_rx_lock);
 	atomic_set(&priv->fw_busy, 0);
+	spin_lock_init(&priv->fw_busy_lock);
+	priv->fw_busy_dev_ctx = NULL;
+	INIT_WORK(&priv->fw_busy_work, se_fw_busy_work);
+
 	init_completion(&priv->waiting_rsp_clbk_hdl.done);
 	init_completion(&priv->cmd_receiver_clbk_hdl.done);
+	INIT_LIST_HEAD(&priv->dev_ctx_list);
 
 	ret = devm_add_action_or_reset(dev, se_if_probe_cleanup, pdev);
 	if (ret)
@@ -460,7 +962,7 @@ static int se_if_probe(struct platform_device *pdev)
 		load_fw->imem_mgmt = true;
 	}
 
-	ret = init_misc_device_context(priv, 0, &priv->priv_dev_ctx);
+	ret = init_misc_device_context(priv, 0, &priv->priv_dev_ctx, &se_if_fops);
 	if (ret)
 		return dev_err_probe(dev, ret,
 				     "Failed[0x%x] to create device contexts.",
@@ -472,12 +974,1147 @@ static int se_if_probe(struct platform_device *pdev)
 			return dev_err_probe(dev, ret, "Failed to fetch SoC Info.");
 	}
 
+	/*
+	 * All probe-time initialization is complete; expose the
+	 * interface to userspace last so that an open()/ioctl cannot
+	 * race against a not-yet-initialized device.
+	 */
+	ret = se_if_misc_register(priv);
+	if (ret)
+		return ret;
+
 	dev_info(dev, "i.MX secure-enclave: %s0 interface to firmware, configured.",
 		 get_se_if_name(priv->if_defs->se_if_type));
 
 	return ret;
 }
 
+/*
+ * Expose the interface to userspace. Deferred until the end of probe so
+ * the device node only becomes openable after SoC info has been fetched
+ * and, on SoCs with IMEM management, the encrypted-IMEM buffer has been
+ * allocated. This prevents userspace from opening the node and issuing
+ * commands against a partially initialized interface.
+ */
+static int se_if_misc_register(struct se_if_priv *priv)
+{
+	int ret;
+
+	ret = misc_register(priv->priv_dev_ctx->miscdev);
+	if (ret)
+		return dev_err_probe(priv->dev, ret,
+				     "Failed to register misc device.");
+
+	priv->open_gate->registered = true;
+
+	return 0;
+}
+
+static void se_if_priv_release(struct kref *kref)
+{
+	struct se_if_priv *priv = container_of(kref, struct se_if_priv, refcount);
+
+	/* Free priv_dev_ctx if it exists */
+	if (priv->priv_dev_ctx) {
+		/*
+		 * miscdev storage belongs to open_gate, not directly to
+		 * priv_dev_ctx. The gate should already have been detached
+		 * from priv during teardown.
+		 *
+		 * Reclaim the internal context's shared memory directly here
+		 * instead of through cleanup_dev_ctx(). Teardown already set
+		 * cleanup_done on priv_dev_ctx, so cleanup_dev_ctx() would
+		 * short-circuit and leak the host descriptors and the coherent
+		 * buffer. By this point the device is fully unbound; if this
+		 * context ever armed the firmware-busy breaker, se_clear_fw_busy()
+		 * has already run with reclaim=false and freed the host
+		 * descriptors, emptied the pool list and cleared
+		 * non_secure_mem.ptr. A reclaim=true pass here is therefore both
+		 * safe and idempotent: it releases the buffers for a normal
+		 * context and is a no-op for the abandoned firmware-busy one.
+		 */
+		scoped_guard(mutex, &priv->priv_dev_ctx->fops_lock)
+			cleanup_se_shared_mem(priv->priv_dev_ctx, true);
+
+		kfree(priv->priv_dev_ctx->devname);
+		kfree(priv->priv_dev_ctx);
+		priv->priv_dev_ctx = NULL;
+	}
+	/*
+	 * No need to check, if reserved memory is allocated
+	 * before calling for its release. Or clearing the
+	 * un-set bit.
+	 */
+	of_reserved_mem_device_release(priv->dev);
+
+	/*
+	 * Be defensive: if teardown did not already drop the device-owned
+	 * gate reference for some reason, release it here.
+	 */
+	if (priv->open_gate) {
+		se_if_open_gate_put(priv->open_gate);
+		priv->open_gate = NULL;
+	}
+
+	/*
+	 * Drop the reference on priv->dev taken in se_if_probe(). The device was
+	 * pinned so that a file descriptor closed after device unbind can still
+	 * safely pass priv->dev to dma_free_coherent()/dev_warn().
+	 */
+	put_device(priv->dev);
+
+	/* Free any remaining resources that weren't devm-managed */
+	kfree(priv);
+}
+
+static void se_if_dev_ctx_release(struct kref *kref)
+{
+	struct se_if_device_ctx *dev_ctx =
+		container_of(kref, struct se_if_device_ctx, refcount);
+	struct se_if_priv *priv = dev_ctx->priv;
+
+	kfree(dev_ctx);
+
+	/* drop the priv reference owned by this device context */
+	kref_put(&priv->refcount, se_if_priv_release);
+}
+
+static void se_clear_fw_busy(struct se_if_priv *priv)
+{
+	struct se_if_device_ctx *dev_ctx = NULL;
+	unsigned long flags;
+
+	spin_lock_irqsave(&priv->fw_busy_lock, flags);
+	dev_ctx = priv->fw_busy_dev_ctx;
+	priv->fw_busy_dev_ctx = NULL;
+	atomic_set(&priv->fw_busy, 0);
+	spin_unlock_irqrestore(&priv->fw_busy_lock, flags);
+
+	if (!dev_ctx)
+		return;
+
+	/*
+	 * The circuit breaker is cleared from two places, which need opposite
+	 * memory-reclaim policies:
+	 *
+	 *   1. se_fw_busy_work(): a late firmware response actually arrived.
+	 *      going_away is not set and the enclave has finished with the
+	 *      buffer, so a full reclaim (reclaim=true) is safe. Only do this
+	 *      once the owning fd has been closed (cleanup_done); while the fd
+	 *      is still open the buffer belongs to that context and is released
+	 *      on its normal close path.
+	 *
+	 *   2. se_if_probe_cleanup(): teardown. going_away is set and no
+	 *      response has been confirmed, so the enclave may still be
+	 *      DMA-writing into the shared buffer. Freeing it here would be a
+	 *      DMA-after-free. Pass reclaim=false so cleanup_se_shared_mem()
+	 *      frees only the host-side descriptors and deliberately leaks the
+	 *      DMA buffer that the enclave might still touch.
+	 */
+	scoped_guard(mutex, &dev_ctx->fops_lock) {
+		if (atomic_read(&priv->going_away)) {
+			/*
+			 * Fatal, but deliberately non-panic: the enclave is
+			 * unresponsive at unbind with a transaction still in
+			 * flight. Both the coherent staging buffer and any
+			 * gen_pool buffers this context owns are abandoned
+			 * (host descriptors freed, DMA-visible memory leaked)
+			 * to avoid a DMA-after-free while the enclave may still
+			 * be writing. Emit one headline error here rather than
+			 * per-buffer so the count of faulted contexts is clear.
+			 * Do not use WARN/BUG: this path is recoverable and
+			 * panic_on_warn kernels must not be brought down by it.
+			 */
+			dev_err(priv->dev,
+				"%s: FATAL: enclave stuck at unbind, DMA leaked.\n",
+				dev_ctx->devname);
+			cleanup_se_shared_mem(dev_ctx, false);
+		} else if (dev_ctx->cleanup_done) {
+			cleanup_se_shared_mem(dev_ctx, true);
+		}
+	}
+
+	kref_put(&dev_ctx->refcount, se_if_dev_ctx_release);
+}
+
+void unset_dev_ctx_as_command_receiver(struct se_if_device_ctx *dev_ctx)
+{
+	struct se_if_priv *priv = dev_ctx->priv;
+	struct se_api_msg *old_rx_msg = NULL;
+	struct se_clbk_handle *se_clbk_hdl;
+	unsigned long flags;
+
+	lockdep_assert_held(&priv->modify_lock);
+
+	se_clbk_hdl = &priv->cmd_receiver_clbk_hdl;
+
+	if (se_clbk_hdl->dev_ctx == dev_ctx) {
+		spin_lock_irqsave(&se_clbk_hdl->clbk_rx_lock, flags);
+		old_rx_msg = se_clbk_hdl->rx_msg;
+		se_clbk_hdl->dev_ctx = NULL;
+		se_clbk_hdl->rx_msg = NULL;
+		se_clbk_hdl->rx_msg_sz = 0;
+		spin_unlock_irqrestore(&se_clbk_hdl->clbk_rx_lock, flags);
+
+		kfree(old_rx_msg);
+		complete_all(&se_clbk_hdl->done);
+	}
+}
+
+int set_dev_ctx_as_command_receiver(struct se_if_device_ctx *dev_ctx)
+{
+	struct se_if_priv *priv = dev_ctx->priv;
+	struct se_api_msg *new_rx_msg = NULL;
+	struct se_clbk_handle *se_clbk_hdl;
+	unsigned long flags;
+
+	se_clbk_hdl = &priv->cmd_receiver_clbk_hdl;
+	guard(mutex)(&priv->modify_lock);
+	if (se_clbk_hdl->dev_ctx == dev_ctx)
+		return 0;
+
+	if (se_clbk_hdl->dev_ctx)
+		return -EBUSY;
+
+	if (!se_clbk_hdl->rx_msg) {
+		new_rx_msg = kzalloc(MAX_NVM_MSG_LEN, GFP_KERNEL);
+		if (!new_rx_msg)
+			return -ENOMEM;
+	}
+	spin_lock_irqsave(&se_clbk_hdl->clbk_rx_lock, flags);
+	if (new_rx_msg)
+		se_clbk_hdl->rx_msg = new_rx_msg;
+	reinit_completion(&se_clbk_hdl->done);
+	se_clbk_hdl->rx_msg_sz = MAX_NVM_MSG_LEN;
+	se_clbk_hdl->dev_ctx = dev_ctx;
+	dev_ctx->rcv_msg_timeout_jiffies = MAX_SCHEDULE_TIMEOUT;
+	spin_unlock_irqrestore(&se_clbk_hdl->clbk_rx_lock, flags);
+
+	return 0;
+}
+
+static void dlink_dev_ctx(struct se_if_device_ctx *dev_ctx)
+{
+	struct se_if_priv *priv = dev_ctx->priv;
+
+	unset_dev_ctx_as_command_receiver(dev_ctx);
+
+	if (!list_empty(&dev_ctx->link)) {
+		list_del_init(&dev_ctx->link);
+		priv->active_devctx_count--;
+	}
+}
+
+bool se_is_fw_busy_ctx(struct se_if_device_ctx *dev_ctx)
+{
+	struct se_if_priv *priv = dev_ctx->priv;
+	unsigned long flags;
+	bool match;
+
+	spin_lock_irqsave(&priv->fw_busy_lock, flags);
+	match = priv->fw_busy_dev_ctx == dev_ctx;
+	spin_unlock_irqrestore(&priv->fw_busy_lock, flags);
+
+	return match;
+}
+
+static void cleanup_dev_ctx(struct se_if_device_ctx *dev_ctx, bool is_fclose)
+{
+	bool already_done;
+
+	scoped_guard(mutex, &dev_ctx->fops_lock) {
+		already_done = dev_ctx->cleanup_done;
+		if (!already_done) {
+			/*
+			 * Ask FW to drop this context's session and storage so
+			 * the kernel and FW stay in sync. Done here, under this
+			 * context's fops_lock only (not the global modify_lock),
+			 * because both close requests block on a firmware
+			 * round-trip; issuing them while modify_lock was held
+			 * would stall every other context for the FW timeout.
+			 *
+			 * Skip the round-trips once the FW path is marked busy.
+			 * fw_busy is armed when a synchronous transaction times
+			 * out; while it is set ele_msg_send_rcv() rejects further
+			 * commands with -EBUSY without waiting. It is only cleared
+			 * by se_clear_fw_busy(), which during unbind runs once
+			 * after this loop (or earlier from fw_busy_work only if a
+			 * genuine late FW response arrives). On a hung FW no late
+			 * response comes, so the breaker stays set for the rest of
+			 * the loop and the remaining closes would just return
+			 * -EBUSY and log spurious "failed to close" errors. Skip
+			 * them and emit a single warning instead.
+			 */
+			if (atomic_read(&dev_ctx->priv->fw_busy)) {
+				if (dev_ctx->strg_hdl || dev_ctx->sess_hdl)
+					dev_warn(dev_ctx->priv->dev,
+						 "%s: skipping session/storage close, FW is busy\n",
+						 dev_ctx->devname);
+			} else {
+				/*
+				 * Pick the context that carries the close messages.
+				 *
+				 * fclose (is_fclose): a userspace close() may race
+				 * driver unbind. Send on the caller's own dev_ctx so
+				 * ele_msg_send_rcv()'s going_away check rejects the
+				 * transmission with -ENODEV if unbind has begun (and
+				 * may have freed priv->tx_chan), instead of touching a
+				 * freed mailbox channel.
+				 *
+				 * Teardown (!is_fclose): going_away is already set, but
+				 * priv->tx_chan is still live at this point in
+				 * se_if_probe_cleanup(). Send on priv_dev_ctx, the only
+				 * context ele_msg_send_rcv() lets through going_away for
+				 * teardown-close messages, so the kernel can still
+				 * resynchronise session/storage state with FW.
+				 */
+				struct se_if_device_ctx *tx_ctx = is_fclose ? dev_ctx :
+							dev_ctx->priv->priv_dev_ctx;
+
+				if (dev_ctx->strg_hdl && se_close_storage(tx_ctx,
+									  dev_ctx->strg_hdl))
+					dev_err(dev_ctx->priv->dev, "failed to close storage.\n");
+				if (dev_ctx->sess_hdl && se_close_session(tx_ctx,
+									  dev_ctx->sess_hdl))
+					dev_err(dev_ctx->priv->dev, "failed to close session.\n");
+			}
+			/*
+			 * fw_busy is caused by one timed-out synchronous transaction.
+			 * Only that transaction's dev_ctx may still have coherent
+			 * memory referenced by FW. Do not skip cleanup for unrelated
+			 * contexts while fw_busy is set.
+			 */
+			if (se_is_fw_busy_ctx(dev_ctx))
+				dev_warn(dev_ctx->priv->dev,
+					 "%s: deferring shared memory cleanup while FW is busy\n",
+					 dev_ctx->devname);
+			else
+				cleanup_se_shared_mem(dev_ctx, true);
+
+			kfree(dev_ctx->devname);
+			dev_ctx->devname = NULL;
+			dev_ctx->cleanup_done = true;
+		}
+	}
+
+	if (is_fclose)
+		kref_put(&dev_ctx->refcount, se_if_dev_ctx_release);
+}
+
+static void dlink_n_cleanup_dev_ctx(struct se_if_device_ctx *dev_ctx, bool is_fclose)
+{
+	struct se_if_priv *priv = dev_ctx->priv;
+
+	if (is_fclose) {
+		scoped_guard(mutex, &priv->modify_lock)
+			dlink_dev_ctx(dev_ctx);
+	}
+
+	cleanup_dev_ctx(dev_ctx, is_fclose);
+}
+
+static int init_device_context(struct se_if_priv *priv, int ch_id,
+			       struct se_if_device_ctx **new_dev_ctx)
+{
+	struct se_if_device_ctx *dev_ctx;
+	int ret = 0;
+
+	dev_ctx = kzalloc_obj(*dev_ctx, GFP_KERNEL);
+
+	if (!dev_ctx)
+		return -ENOMEM;
+
+	dev_ctx->devname = kasprintf(GFP_KERNEL, "%s0_ch%d",
+				     get_se_if_name(priv->if_defs->se_if_type),
+				     ch_id);
+	if (!dev_ctx->devname) {
+		kfree(dev_ctx);
+		return -ENOMEM;
+	}
+
+	mutex_init(&dev_ctx->fops_lock);
+	kref_init(&dev_ctx->refcount);
+	dev_ctx->priv = priv;
+	dev_ctx->cleanup_done = false;
+	INIT_LIST_HEAD(&dev_ctx->link);
+	set_se_rcv_msg_timeout(dev_ctx, SE_RCV_MSG_LONG_TIMEOUT_MS);
+	*new_dev_ctx = dev_ctx;
+
+	ret = init_se_shared_mem(dev_ctx);
+	if (ret < 0) {
+		kfree(dev_ctx->devname);
+		kfree(dev_ctx);
+		*new_dev_ctx = NULL;
+
+		return ret;
+	}
+
+	/* Take a reference to priv for this device context */
+	kref_get(&priv->refcount);
+
+	scoped_guard(mutex, &priv->modify_lock) {
+		list_add_tail(&dev_ctx->link, &priv->dev_ctx_list);
+		priv->active_devctx_count++;
+	}
+
+	return ret;
+}
+
+static int se_ioctl_cmd_snd_rcv_cleanup(struct se_if_device_ctx *dev_ctx, void __user *uarg,
+					struct se_ioctl_cmd_snd_rcv_rsp_info *cmd_snd_rcv_rsp_info)
+{
+	/* shared memory is allocated before this IOCTL */
+	se_dev_ctx_shared_mem_cleanup(dev_ctx);
+
+	if (cmd_snd_rcv_rsp_info->rx_buf_sz &&
+	    copy_to_user(uarg, cmd_snd_rcv_rsp_info, sizeof(*cmd_snd_rcv_rsp_info))) {
+		dev_err(dev_ctx->priv->dev, "%s: Failed to copy cmd_snd_rcv_rsp_info to user.",
+			dev_ctx->devname);
+		return -EFAULT;
+	}
+
+	return 0;
+}
+
+static int se_ioctl_cmd_snd_rcv_rsp_handler(struct se_if_device_ctx *dev_ctx,
+					    void __user *uarg)
+{
+	struct se_ioctl_cmd_snd_rcv_rsp_info cmd_snd_rcv_rsp_info = {0};
+	struct se_if_priv *priv = dev_ctx->priv;
+	int rsp_status_err = 0;
+	int cleanup_err = 0;
+	int err = 0;
+
+	if (copy_from_user(&cmd_snd_rcv_rsp_info, uarg,
+			   sizeof(cmd_snd_rcv_rsp_info))) {
+		dev_err(priv->dev,
+			"%s: Failed to copy cmd_snd_rcv_rsp_info from user.",
+			dev_ctx->devname);
+		se_ioctl_cmd_snd_rcv_cleanup(dev_ctx, uarg, &cmd_snd_rcv_rsp_info);
+		return -EFAULT;
+	}
+
+	if (cmd_snd_rcv_rsp_info.tx_buf_sz < SE_MU_HDR_SZ ||
+	    cmd_snd_rcv_rsp_info.tx_buf_sz > MAX_ALLOWED_TX_MSG_SZ) {
+		dev_err(priv->dev, "%s: User buffer too small/large(%d < %d)",
+			dev_ctx->devname, cmd_snd_rcv_rsp_info.tx_buf_sz,
+			cmd_snd_rcv_rsp_info.tx_buf_sz < SE_MU_HDR_SZ ? SE_MU_HDR_SZ :
+								MAX_ALLOWED_TX_MSG_SZ);
+		se_ioctl_cmd_snd_rcv_cleanup(dev_ctx, uarg, &cmd_snd_rcv_rsp_info);
+		return -ENOSPC;
+	}
+
+	struct se_api_msg *tx_msg __free(kfree) =
+		memdup_user(u64_to_user_ptr(cmd_snd_rcv_rsp_info.tx_buf),
+			    cmd_snd_rcv_rsp_info.tx_buf_sz);
+	if (IS_ERR(tx_msg)) {
+		err = PTR_ERR(tx_msg);
+		se_ioctl_cmd_snd_rcv_cleanup(dev_ctx, uarg, &cmd_snd_rcv_rsp_info);
+		return err;
+	}
+
+	err = se_chk_tx_msg_hdr(dev_ctx, &tx_msg->header,
+				cmd_snd_rcv_rsp_info.tx_buf_sz);
+	if (err) {
+		se_ioctl_cmd_snd_rcv_cleanup(dev_ctx, uarg, &cmd_snd_rcv_rsp_info);
+		return err;
+	}
+
+	if (cmd_snd_rcv_rsp_info.rx_buf_sz < SE_MU_HDR_SZ ||
+	    cmd_snd_rcv_rsp_info.rx_buf_sz > MAX_ALLOWED_RX_MSG_SZ) {
+		se_ioctl_cmd_snd_rcv_cleanup(dev_ctx, uarg, &cmd_snd_rcv_rsp_info);
+		return -EINVAL;
+	}
+
+	if (tx_msg->header.tag != priv->if_defs->cmd_tag) {
+		se_ioctl_cmd_snd_rcv_cleanup(dev_ctx, uarg, &cmd_snd_rcv_rsp_info);
+		return -EINVAL;
+	}
+
+	if (tx_msg->header.ver == priv->if_defs->fw_api_ver &&
+	    get_load_fw_instance(priv)->is_fw_tobe_loaded) {
+		err = se_load_firmware(priv);
+		if (err) {
+			dev_err(priv->dev, "Could not send msg as FW is not loaded.");
+			se_ioctl_cmd_snd_rcv_cleanup(dev_ctx, uarg, &cmd_snd_rcv_rsp_info);
+			return -EPERM;
+		}
+	}
+
+	struct se_api_msg *rx_msg __free(kfree) =
+		kzalloc(cmd_snd_rcv_rsp_info.rx_buf_sz, GFP_KERNEL);
+	if (!rx_msg) {
+		se_ioctl_cmd_snd_rcv_cleanup(dev_ctx, uarg, &cmd_snd_rcv_rsp_info);
+		return -ENOMEM;
+	}
+
+	err = ele_msg_send_rcv(dev_ctx, tx_msg, cmd_snd_rcv_rsp_info.tx_buf_sz,
+			       rx_msg, cmd_snd_rcv_rsp_info.rx_buf_sz);
+	if (err < 0) {
+		/*
+		 * -ERESTARTSYS here means the wait was interrupted by a signal
+		 * after the command had already been handed to - and executed
+		 * by - the firmware, with its response delivered into rx_msg
+		 * (ele_msg_send_rcv() converts only a positive, i.e. successfully
+		 * received, result to -ERESTARTSYS). If that response carried a
+		 * freshly allocated session/storage handle, record it now via
+		 * fw_api_specific_ops(): the handle is already live in firmware,
+		 * so leaving it untracked would stop cleanup_dev_ctx() from ever
+		 * closing it and leak the firmware resource. Validate the
+		 * delivered response first, using its own declared length bounded
+		 * by the caller's buffer, so a truncated or malformed reply is
+		 * not acted upon.
+		 */
+		if (err == -ERESTARTSYS) {
+			u32 rsp_sz = rx_msg->header.size << 2;
+
+			if (rsp_sz && rsp_sz <= cmd_snd_rcv_rsp_info.rx_buf_sz &&
+			    !se_val_rsp_hdr_n_status(priv, rx_msg,
+						     tx_msg->header.command, rsp_sz,
+						     tx_msg->header.ver ==
+						     priv->if_defs->base_api_ver)) {
+				se_dev_ctx_cpy_out_data(dev_ctx);
+				fw_api_specific_ops(dev_ctx, rx_msg);
+			}
+			/*
+			 * Returning -ERESTARTSYS would let the VFS transparently restart
+			 * the ioctl, which would re-run the command with the just
+			 * cleaned-up (zeroed) shared input buffers. Report -EINTR instead
+			 * so the syscall is not auto-restarted; userspace enters its
+			 * signal handler and can decide whether to reissue the command.
+			 */
+			err = -EINTR;
+		}
+
+		se_ioctl_cmd_snd_rcv_cleanup(dev_ctx, uarg, &cmd_snd_rcv_rsp_info);
+
+		return err;
+	}
+
+	/*
+	 * ele_msg_send_rcv() returns a positive received-message size on
+	 * success. Returning that raw size as the ioctl result would make a
+	 * successful transaction look like a positive (non-zero) return value
+	 * to userspace. Record the actual received size in rx_buf_sz for the
+	 * response copied back to userspace, then normalise err to 0 so the
+	 * ioctl reports plain success; the firmware status is conveyed to
+	 * userspace inside the response buffer itself.
+	 */
+	cmd_snd_rcv_rsp_info.rx_buf_sz = err;
+	err = 0;
+
+	dev_dbg(priv->dev, "%s: %s %s.", dev_ctx->devname, __func__,
+		"message received, start transmit to user");
+
+	rsp_status_err =
+		se_val_rsp_hdr_n_status(priv, rx_msg, tx_msg->header.command,
+					cmd_snd_rcv_rsp_info.rx_buf_sz,
+					tx_msg->header.ver == priv->if_defs->base_api_ver);
+
+	if (!rsp_status_err) {
+		/*
+		 * The response is well formed and fully fits the caller's
+		 * buffer, so any FW-allocated session/storage handle it carries
+		 * (data[1]) has been delivered. Record it now, before the
+		 * copy-out steps below. The FW has already committed the handle;
+		 * running fw_api_specific_ops() only after a successful
+		 * se_dev_ctx_cpy_out_data()/copy_to_user() would leave the
+		 * handle untracked - and so never closed on teardown, leaking it
+		 * in FW - whenever the caller supplied a bad output pointer.
+		 */
+		fw_api_specific_ops(dev_ctx, rx_msg);
+
+		err = se_dev_ctx_cpy_out_data(dev_ctx);
+		if (err < 0) {
+			se_ioctl_cmd_snd_rcv_cleanup(dev_ctx, uarg, &cmd_snd_rcv_rsp_info);
+			return err;
+		}
+	}
+
+	/* Copy data from the buffer */
+	print_hex_dump_debug("to user ", DUMP_PREFIX_OFFSET, 4, 4, rx_msg,
+			     cmd_snd_rcv_rsp_info.rx_buf_sz, false);
+
+	if (copy_to_user(u64_to_user_ptr(cmd_snd_rcv_rsp_info.rx_buf), rx_msg,
+			 cmd_snd_rcv_rsp_info.rx_buf_sz)) {
+		dev_err(priv->dev, "%s: Failed to copy to user.", dev_ctx->devname);
+		err = -EFAULT;
+	}
+
+	cleanup_err = se_ioctl_cmd_snd_rcv_cleanup(dev_ctx, uarg, &cmd_snd_rcv_rsp_info);
+
+	if (cleanup_err && !err)
+		err = cleanup_err;
+
+	return err;
+}
+
+static int se_ioctl_get_mu_info(struct se_if_device_ctx *dev_ctx,
+				void __user *uarg)
+{
+	struct se_if_priv *priv = dev_ctx->priv;
+	struct se_ioctl_get_if_info if_info;
+	struct se_if_node *if_node;
+	int err = 0;
+
+	if_node = container_of(priv->if_defs, typeof(*if_node), if_defs);
+
+	if_info.se_if_id = 0;
+	if_info.interrupt_idx = 0;
+	if_info.tz = 0;
+	if_info.did = 0;
+	if_info.cmd_tag = priv->if_defs->cmd_tag;
+	if_info.rsp_tag = priv->if_defs->rsp_tag;
+	if_info.success_tag = priv->if_defs->success_tag;
+	if_info.base_api_ver = priv->if_defs->base_api_ver;
+	if_info.fw_api_ver = priv->if_defs->fw_api_ver;
+
+	dev_dbg(priv->dev, "%s: info [se_if_id: %d, irq_idx: %d, tz: 0x%x, did: 0x%x].",
+		dev_ctx->devname, if_info.se_if_id, if_info.interrupt_idx, if_info.tz,
+		if_info.did);
+
+	if (copy_to_user(uarg, &if_info, sizeof(if_info))) {
+		dev_err(priv->dev, "%s: Failed to copy mu info to user.",
+			dev_ctx->devname);
+		err = -EFAULT;
+	}
+
+	return err;
+}
+
+static void rollback_shared_mem_pos(struct se_if_device_ctx *dev_ctx, u32 length)
+{
+	struct se_shared_mem *shared_mem = NULL;
+
+	shared_mem = &dev_ctx->se_shared_mem_mgmt.non_secure_mem;
+
+	if (WARN_ON_ONCE(length > shared_mem->pos)) {
+		shared_mem->pos = 0;
+		return;
+	}
+
+	shared_mem->pos -= length;
+}
+
+int get_shared_mem_slot(struct se_if_device_ctx *dev_ctx,
+			u32 *length, dma_addr_t *ele_dma_addr, void **ptr)
+{
+	struct se_shared_mem *shared_mem = NULL;
+	bool is_fw_busy_dev_ctx;
+	size_t aligned_len = 0;
+	u32 pos;
+
+	/*
+	 * If this context is the one that caused a firmware timeout the shared
+	 * DMA buffers may still be actively read/written by the firmware.
+	 */
+	is_fw_busy_dev_ctx = se_is_fw_busy_ctx(dev_ctx);
+	if (is_fw_busy_dev_ctx)
+		return -EBUSY;
+
+	aligned_len = round_up((size_t)*length, 8);
+	if (aligned_len < *length) {
+		dev_err(dev_ctx->priv->dev, "%s: Invalid buffer length.",
+			dev_ctx->devname);
+		return -EINVAL;
+	}
+
+	/* No specific requirement for this buffer. */
+	shared_mem = &dev_ctx->se_shared_mem_mgmt.non_secure_mem;
+
+	/* Check there is enough space in the shared memory. */
+	dev_dbg(dev_ctx->priv->dev, "%s: req_size = %zd, max_size= %d, curr_pos = %d",
+		dev_ctx->devname, aligned_len, shared_mem->size,
+		shared_mem->pos);
+
+	if (shared_mem->size < shared_mem->pos ||
+	    aligned_len > (shared_mem->size - shared_mem->pos)) {
+		dev_err(dev_ctx->priv->dev, "%s: Not enough space in shared memory.",
+			dev_ctx->devname);
+		return -ENOMEM;
+	}
+
+	/* Allocate space in shared memory. 8 bytes aligned. */
+	pos = shared_mem->pos;
+	shared_mem->pos += aligned_len;
+	*ele_dma_addr = (u64)shared_mem->dma_addr + pos;
+	*ptr = shared_mem->ptr + pos;
+	*length = aligned_len;
+
+	memset(shared_mem->ptr + pos, 0, aligned_len);
+
+	return 0;
+}
+
+/*
+ * Copy a buffer of data to/from the user and return the address to use in
+ * messages
+ */
+static int se_ioctl_setup_iobuf_handler(struct se_if_device_ctx *dev_ctx,
+					void __user *uarg)
+{
+	struct se_ioctl_setup_iobuf io = {0};
+	struct se_buf_desc *b_desc = NULL;
+	void *dma_buf_ptr = NULL;
+	dma_addr_t ele_dma_addr;
+	u32 aligned_len = 0;
+	int err = 0;
+
+	if (copy_from_user(&io, uarg, sizeof(io))) {
+		dev_err(dev_ctx->priv->dev, "%s: Failed copy iobuf config from user.",
+			dev_ctx->devname);
+		return -EFAULT;
+	}
+
+	dev_dbg(dev_ctx->priv->dev, "%s: io [buf: %p(%d) flag: %x].", dev_ctx->devname,
+		u64_to_user_ptr(io.user_buf), io.length, io.flags);
+
+	if (io.length == 0 || !io.user_buf) {
+		/*
+		 * Accept NULL pointers since some buffers are optional
+		 * in FW commands. In this case we should return 0 as
+		 * pointer to be embedded into the message.
+		 * Skip all data copy part of code below.
+		 */
+		io.ele_addr = 0;
+		goto copy;
+	}
+
+	aligned_len = io.length;
+	err = get_shared_mem_slot(dev_ctx, &aligned_len, &ele_dma_addr, &dma_buf_ptr);
+	if (err)
+		return err;
+
+	io.ele_addr = ele_dma_addr;
+	if ((io.flags & SE_IO_BUF_FLAGS_IS_INPUT) ||
+	    (io.flags & SE_IO_BUF_FLAGS_IS_IN_OUT)) {
+		/*
+		 * buffer is input:
+		 * copy data from user space to this allocated buffer.
+		 */
+		if (copy_from_user(dma_buf_ptr, u64_to_user_ptr(io.user_buf),
+				   io.length)) {
+			dev_err(dev_ctx->priv->dev,
+				"%s: Failed copy data to shared memory.",
+				dev_ctx->devname);
+			err = -EFAULT;
+			goto rollback;
+		}
+	}
+
+	b_desc = add_b_desc_to_pending_list(dma_buf_ptr, &io, dev_ctx);
+	if (IS_ERR(b_desc)) {
+		err = PTR_ERR(b_desc);
+		dev_err(dev_ctx->priv->dev, "%s: Failed to allocate/link b_desc.",
+			dev_ctx->devname);
+		goto rollback;
+	}
+
+copy:
+	/* Provide the EdgeLock Enclave address to user space only if success.*/
+	if (copy_to_user(uarg, &io, sizeof(io))) {
+		dev_err(dev_ctx->priv->dev, "%s: Failed to copy iobuff setup to user.",
+			dev_ctx->devname);
+		err = -EFAULT;
+		goto rollback;
+	}
+	return err;
+
+rollback:
+	if (!IS_ERR_OR_NULL(b_desc)) {
+		list_del(&b_desc->link);
+		kfree(b_desc);
+	}
+
+	if (dma_buf_ptr && aligned_len) {
+		memset(dma_buf_ptr, 0, aligned_len);
+		rollback_shared_mem_pos(dev_ctx, aligned_len);
+	}
+
+	return err;
+}
+
+/* IOCTL to provide SoC information */
+static int se_ioctl_get_se_soc_info_handler(struct se_if_device_ctx *dev_ctx,
+					    void __user *uarg)
+{
+	struct se_ioctl_get_soc_info soc_info;
+	int err = -EINVAL;
+
+	soc_info.soc_id = get_se_soc_id(dev_ctx->priv);
+	soc_info.soc_rev = var_se_info.soc_rev;
+
+	err = copy_to_user(uarg, (u8 *)(&soc_info), sizeof(soc_info));
+	if (err) {
+		dev_err(dev_ctx->priv->dev, "%s: Failed to copy soc info to user.",
+			dev_ctx->devname);
+		err = -EFAULT;
+	}
+
+	return err;
+}
+
+/*
+ * File operations for user-space
+ */
+
+/* Write a message to the MU. */
+static ssize_t se_if_fops_write(struct file *fp, const char __user *buf,
+				size_t size, loff_t *ppos)
+{
+	struct se_if_device_ctx *dev_ctx = fp->private_data;
+	struct se_if_priv *priv;
+	int err;
+
+	scoped_cond_guard(mutex_intr, return -ERESTARTSYS, &dev_ctx->fops_lock) {
+		if (dev_ctx->cleanup_done)
+			return -ENODEV;
+
+		priv = dev_ctx->priv;
+
+		dev_dbg(priv->dev, "%s: write from buf (%p)%zu, ppos=%lld.", dev_ctx->devname,
+			buf, size, ((ppos) ? *ppos : 0));
+
+		if (dev_ctx != priv->cmd_receiver_clbk_hdl.dev_ctx) {
+			se_dev_ctx_shared_mem_cleanup(dev_ctx);
+			return -EINVAL;
+		}
+
+		if (size < SE_MU_HDR_SZ || size > MAX_ALLOWED_TX_MSG_SZ) {
+			dev_err(priv->dev, "%s: User buffer too small/large(%zu < %d)",
+				dev_ctx->devname, size,
+				size < SE_MU_HDR_SZ ? SE_MU_HDR_SZ :
+								MAX_ALLOWED_TX_MSG_SZ);
+			return -ENOSPC;
+		}
+
+		struct se_api_msg *tx_msg __free(kfree) = memdup_user(buf, size);
+		if (IS_ERR(tx_msg))
+			return PTR_ERR(tx_msg);
+
+		err = se_chk_tx_msg_hdr(dev_ctx, &tx_msg->header, size);
+		if (err)
+			return err;
+
+		print_hex_dump_debug("from user ", DUMP_PREFIX_OFFSET, 4, 4,
+				     tx_msg, size, false);
+
+		err = ele_msg_send(dev_ctx, tx_msg, size);
+
+		return err;
+	}
+}
+
+/*
+ * Read a message from the MU.
+ * Blocking until a message is available.
+ */
+static ssize_t se_if_fops_read(struct file *fp, char __user *buf, size_t size,
+			       loff_t *ppos)
+{
+	struct se_if_device_ctx *dev_ctx = fp->private_data;
+	u8 rx_msg_snap[MAX_NVM_MSG_LEN];
+	struct se_if_priv *priv;
+	unsigned long flags;
+	size_t copy_len;
+	int err;
+
+	scoped_cond_guard(mutex_intr, return -ERESTARTSYS, &dev_ctx->fops_lock) {
+		priv = dev_ctx->priv;
+
+		if (dev_ctx->cleanup_done)
+			return -ENODEV;
+
+		dev_dbg(priv->dev, "%s: read to buf %p(%zu), ppos=%lld.", dev_ctx->devname,
+			buf, size, ((ppos) ? *ppos : 0));
+
+		mutex_lock(&priv->modify_lock);
+		if (dev_ctx != priv->cmd_receiver_clbk_hdl.dev_ctx) {
+			mutex_unlock(&priv->modify_lock);
+			se_dev_ctx_shared_mem_cleanup(dev_ctx);
+			return -EINVAL;
+		}
+		mutex_unlock(&priv->modify_lock);
+	}
+
+	err = ele_msg_rcv(dev_ctx, &priv->cmd_receiver_clbk_hdl);
+	if (err < 0) {
+		if (err != -ERESTARTSYS)
+			dev_err(priv->dev,
+				"%s: Er[0x%x]: Signal Interrupted. Current act-dev-ctx count: %d.",
+				dev_ctx->devname, err, dev_ctx->priv->active_devctx_count);
+		return err;
+	}
+
+	/*
+	 * Reacquire fops_lock before touching any dev_ctx state (pending lists,
+	 * rx_msg) after the blocking wait. fops_lock was dropped before calling
+	 * ele_msg_rcv(). If cleanup_dev_ctx() ran concurrently it could have
+	 * freed the DMA buffers and the pending lists, leading to UAF and list
+	 * corruption. Re-checking cleanup_done under fops_lock prevents that.
+	 */
+	mutex_lock(&dev_ctx->fops_lock);
+
+	if (dev_ctx->cleanup_done) {
+		mutex_unlock(&dev_ctx->fops_lock);
+		return -ENODEV;
+	}
+
+	/*
+	 * Snapshot rx_msg pointer under clbk_rx_lock before releasing it.
+	 * unset_dev_ctx_as_command_receiver() can acquire the lock, NULL out
+	 * rx_msg, and free the buffer at any time after the unlock; using a
+	 * stale pointer from the shared field after the unlock is a UAF.
+	 */
+	scoped_guard(mutex, &priv->modify_lock) {
+		spin_lock_irqsave(&priv->cmd_receiver_clbk_hdl.clbk_rx_lock, flags);
+		if (priv->cmd_receiver_clbk_hdl.dev_ctx != dev_ctx ||
+		    !priv->cmd_receiver_clbk_hdl.rx_msg ||
+		    !priv->cmd_receiver_clbk_hdl.rx_msg_sz) {
+			spin_unlock_irqrestore(&priv->cmd_receiver_clbk_hdl.clbk_rx_lock, flags);
+			mutex_unlock(&dev_ctx->fops_lock);
+			return -ENODEV;
+		}
+		/* Taking snapshot is enough for the one common pre-allocated buffer. */
+		copy_len = min(size, priv->cmd_receiver_clbk_hdl.rx_msg_sz);
+		memcpy(rx_msg_snap, priv->cmd_receiver_clbk_hdl.rx_msg, copy_len);
+		priv->cmd_receiver_clbk_hdl.rx_msg_sz = 0;
+		spin_unlock_irqrestore(&priv->cmd_receiver_clbk_hdl.clbk_rx_lock, flags);
+
+		/* We may need to copy the output data to user before
+		 * delivering the completion message.
+		 */
+		err = se_dev_ctx_cpy_out_data(dev_ctx);
+		if (err < 0) {
+			se_dev_ctx_shared_mem_cleanup(dev_ctx);
+			mutex_unlock(&dev_ctx->fops_lock);
+			return err;
+		}
+		/* Copy data from the buffer using the snapshot taken under the lock. */
+		print_hex_dump_debug("to user ", DUMP_PREFIX_OFFSET, 4, 4,
+				     rx_msg_snap, copy_len, false);
+
+		fw_api_specific_ops(dev_ctx, (struct se_api_msg *)rx_msg_snap);
+		err = copy_len;
+		if (copy_to_user(buf, rx_msg_snap, copy_len))
+			err = -EFAULT;
+
+		se_dev_ctx_shared_mem_cleanup(dev_ctx);
+		mutex_unlock(&dev_ctx->fops_lock);
+	}
+
+	return err;
+}
+
+/* Open a character device. */
+static int se_if_fops_open(struct inode *nd, struct file *fp)
+{
+	struct miscdevice *miscdev = fp->private_data;
+	struct se_if_open_gate *gate;
+	struct se_if_device_ctx *misc_dev_ctx;
+	struct se_if_device_ctx *dev_ctx;
+	struct se_if_priv *priv;
+	int err = 0;
+
+	gate = container_of(miscdev, struct se_if_open_gate, miscdev);
+
+	if (!se_if_open_gate_get(gate))
+		return -ENODEV;
+
+	if (mutex_lock_interruptible(&gate->lock)) {
+		se_if_open_gate_put(gate);
+		return -ERESTARTSYS;
+	}
+
+	if (gate->dying || !gate->priv ||
+	    !kref_get_unless_zero(&gate->priv->refcount)) {
+		err = -ENODEV;
+		goto out_unlock_gate;
+	}
+
+	priv = gate->priv;
+	mutex_unlock(&gate->lock);
+
+	misc_dev_ctx = priv->priv_dev_ctx;
+
+	if (mutex_lock_interruptible(&misc_dev_ctx->fops_lock)) {
+		err = -ERESTARTSYS;
+		goto out_put_priv;
+	}
+
+	if (misc_dev_ctx->cleanup_done) {
+		err = -ENODEV;
+		goto out_unlock_misc;
+	}
+
+	priv->dev_ctx_mono_count++;
+	err = init_device_context(priv, priv->dev_ctx_mono_count, &dev_ctx);
+	if (err) {
+		dev_err(priv->dev, "Failed[0x%x] to create dev-ctx.", err);
+		goto out_unlock_misc;
+	}
+
+	fp->private_data = dev_ctx;
+
+out_unlock_misc:
+	mutex_unlock(&misc_dev_ctx->fops_lock);
+out_put_priv:
+	kref_put(&priv->refcount, se_if_priv_release);
+	se_if_open_gate_put(gate);
+	return err;
+out_unlock_gate:
+	mutex_unlock(&gate->lock);
+	se_if_open_gate_put(gate);
+	return err;
+}
+
+/* Close a character device. */
+static int se_if_fops_close(struct inode *nd, struct file *fp)
+{
+	struct se_if_device_ctx *dev_ctx = fp->private_data;
+
+	dlink_n_cleanup_dev_ctx(dev_ctx, true);
+
+	return 0;
+}
+
+/* IOCTL entry point of a character device */
+static long se_ioctl(struct file *fp, unsigned int cmd, unsigned long arg)
+{
+	struct se_if_device_ctx *dev_ctx = fp->private_data;
+	struct se_if_priv *priv;
+	void __user *uarg = (void __user *)arg;
+	long err;
+
+	/* Prevent race during change of device context */
+	scoped_cond_guard(mutex_intr, return -ERESTARTSYS, &dev_ctx->fops_lock) {
+		if (dev_ctx->cleanup_done)
+			return -ENODEV;
+
+		priv = dev_ctx->priv;
+
+		switch (cmd) {
+		case SE_IOCTL_ENABLE_CMD_RCV: {
+			err = set_dev_ctx_as_command_receiver(dev_ctx);
+			if (err)
+				dev_err(priv->dev, "Failed to register %s as CMD-Receiver: %ld\n",
+					dev_ctx->devname, err);
+		break;
+		}
+		case SE_IOCTL_GET_MU_INFO:
+			err = se_ioctl_get_mu_info(dev_ctx, uarg);
+			break;
+		case SE_IOCTL_SETUP_IOBUF:
+			err = se_ioctl_setup_iobuf_handler(dev_ctx, uarg);
+			break;
+		case SE_IOCTL_GET_SOC_INFO:
+			err = se_ioctl_get_se_soc_info_handler(dev_ctx, uarg);
+			break;
+		case SE_IOCTL_CMD_SEND_RCV_RSP:
+			err = se_ioctl_cmd_snd_rcv_rsp_handler(dev_ctx, uarg);
+			break;
+		default:
+			err = -ENOTTY;
+			dev_dbg(priv->dev, "%s: IOCTL %.8x not supported.",
+				dev_ctx->devname, cmd);
+		}
+	}
+
+	return err;
+}
+
+/* Char driver setup */
+static const struct file_operations se_if_fops = {
+	.open		= se_if_fops_open,
+	.owner		= THIS_MODULE,
+	.release	= se_if_fops_close,
+	.unlocked_ioctl = se_ioctl,
+	.compat_ioctl   = compat_ptr_ioctl,
+	.read		= se_if_fops_read,
+	.write		= se_if_fops_write,
+};
+
+int se_get_mem_pool_buf(struct se_if_device_ctx *dev_ctx, void **buf,
+			dma_addr_t *daddr, u32 len)
+{
+	struct se_shared_mem_mgmt_info *se_shared_mem_mgmt = &dev_ctx->se_shared_mem_mgmt;
+	struct se_if_priv *priv = dev_ctx->priv;
+	struct se_buf_desc *b_desc = NULL;
+
+	lockdep_assert_held(&dev_ctx->fops_lock);
+
+	if (se_is_fw_busy_ctx(dev_ctx))
+		return -EBUSY;
+
+	b_desc = kzalloc_obj(*b_desc, GFP_KERNEL);
+	if (!b_desc)
+		return -ENOMEM;
+
+	/*
+	 * gen_pool is internally thread-safe, so contexts may allocate
+	 * concurrently. The buffer is tracked on this context's own
+	 * mem_pool_buf_list and released on its cleanup path.
+	 */
+	*buf = gen_pool_dma_alloc(priv->mem_pool, len, daddr);
+	if (!*buf) {
+		dev_err(priv->dev, "Failed to alloc from gen_pool.\n");
+		kfree(b_desc);
+		return -ENOMEM;
+	}
+
+	/* gen_pool_dma_alloc() does not zero the buffer. */
+	memset(*buf, 0, len);
+	b_desc->shared_buf_ptr = *buf;
+	b_desc->size = len;
+
+	list_add_tail(&b_desc->link, &se_shared_mem_mgmt->mem_pool_buf_list);
+
+	return 0;
+}
+
+void se_cleanup_mem_pool_buf(struct se_if_device_ctx *dev_ctx, bool reclaim)
+{
+	struct se_shared_mem_mgmt_info *se_shared_mem_mgmt = &dev_ctx->se_shared_mem_mgmt;
+	struct se_if_priv *priv = dev_ctx->priv;
+	struct se_buf_desc *b_desc, *temp;
+
+	/*
+	 * Free only the buffers this context allocated. A context that never
+	 * used the pool has an empty list, so this is a no-op for it.
+	 *
+	 * Unlike the coherent staging buffer, the pool path needs no
+	 * "nothing staged" (pos) gate on the reclaim=false leg. Pool buffers
+	 * are ephemeral, per-transaction allocations: se_get_mem_pool_buf()
+	 * refuses to allocate once the context is fw_busy, ele_msg_send_rcv()
+	 * refuses to start a new command while fw_busy, and the success path
+	 * frees the whole list via se_cleanup_mem_pool_buf(reclaim=true)
+	 * before returning. se_if_cmd_lock serialises synchronous commands, so
+	 * at most one transaction is outstanding. The only way to reach here
+	 * with reclaim=false and a non-empty list is the single fw_busy
+	 * context still owning the buffer(s) from the one timed-out
+	 * transaction. Those buffers are exactly the in-flight ones the
+	 * enclave may still be DMA-ing into, so leaving them on the list (no
+	 * gen_pool_free) deliberately leaks them to avoid a DMA-after-free -
+	 * there are no already-consumed pool buffers to reclaim on this leg.
+	 */
+	list_for_each_entry_safe(b_desc, temp, &se_shared_mem_mgmt->mem_pool_buf_list, link) {
+		if (reclaim)
+			gen_pool_free(priv->mem_pool,
+				      (unsigned long)b_desc->shared_buf_ptr,
+				      b_desc->size);
+		list_del(&b_desc->link);
+		kfree(b_desc);
+	}
+}
+
+static void se_fw_busy_work(struct work_struct *work)
+{
+	struct se_if_priv *priv =
+		container_of(work, struct se_if_priv, fw_busy_work);
+
+	se_clear_fw_busy(priv);
+}
+
 static int se_suspend(struct device *dev)
 {
 	struct se_if_priv *priv = dev_get_drvdata(dev);
diff --git a/drivers/firmware/imx/se_ctrl.h b/drivers/firmware/imx/se_ctrl.h
index dd4a1ea7e35a..35389095ed1c 100644
--- a/drivers/firmware/imx/se_ctrl.h
+++ b/drivers/firmware/imx/se_ctrl.h
@@ -10,20 +10,40 @@
 #include <linux/miscdevice.h>
 #include <linux/mailbox_client.h>
 #include <linux/semaphore.h>
+#include <linux/workqueue.h>
 
 #define MAX_FW_LOAD_RETRIES		50
 #define SE_MSG_WORD_SZ			0x4
 
 #define RES_STATUS(x)			FIELD_GET(0x000000ff, x)
+#define MAX_DATA_SIZE_PER_USER		(128 * 1024)
 #define MAX_NVM_MSG_LEN			(256)
 #define MESSAGING_VERSION_6		0x6
 #define MESSAGING_VERSION_7		0x7
 
+struct se_if_open_gate {
+	struct miscdevice miscdev;
+	struct se_if_priv *priv;
+	/* to lock to update the structure */
+	struct mutex lock;
+	struct kref refcount;
+	bool dying;
+	/* set once misc_register() has succeeded (deferred to probe end) */
+	bool registered;
+};
+
 struct se_clbk_handle {
 	struct se_if_device_ctx *dev_ctx;
 	struct completion done;
 	bool signal_rcvd;
+	/*
+	 * Set under clbk_rx_lock once a real response is copied into rx_msg,
+	 * cleared when a new transaction is armed. Lets ele_msg_rcv() tell a
+	 * genuine response from a teardown-forced complete_all() with no data.
+	 */
+	bool rx_delivered;
 	u32 rx_msg_sz;
+
 	/*
 	 * Assignment of the rx_msg buffer to held till the
 	 * received content as part callback function, is copied.
@@ -45,10 +65,46 @@ struct se_imem_buf {
 	u32 state;
 };
 
+struct se_buf_desc {
+	u8 *shared_buf_ptr;
+	void __user *usr_buf_ptr;
+	u32 size;
+	struct list_head link;
+};
+
+struct se_shared_mem {
+	dma_addr_t dma_addr;
+	u32 size;
+	u32 pos;
+	u8 *ptr;
+};
+
+struct se_shared_mem_mgmt_info {
+	struct list_head mem_pool_buf_list;
+	struct list_head pending_in;
+	struct list_head pending_out;
+
+	struct se_shared_mem non_secure_mem;
+};
+
 /* Private struct for each char device instance. */
 struct se_if_device_ctx {
 	struct se_if_priv *priv;
+	struct miscdevice *miscdev;
 	const char *devname;
+	u32 sess_hdl;
+	u32 strg_hdl;
+	bool cleanup_done;
+	unsigned long rcv_msg_timeout_jiffies;
+
+	/* process one file operation at a time. */
+	struct mutex fops_lock;
+
+	struct se_shared_mem_mgmt_info se_shared_mem_mgmt;
+	struct list_head link;
+
+	/* Add reference counting */
+	struct kref refcount;
 };
 
 /* Header of the messages exchange with the EdgeLock Enclave */
@@ -113,9 +169,43 @@ struct se_if_priv {
 	struct se_fw_load_info load_fw;
 
 	atomic_t fw_busy;
+	/*
+	 * Set once teardown begins. New synchronous transactions are rejected
+	 * and a teardown-forced completion is not mistaken for a real firmware
+	 * response.
+	 */
+	atomic_t going_away;
+	/*
+	 * Serialise the fw_busy_dev_ctx and fw_busy state updates between the
+	 * timeout path, late-response callback/work, and teardown.
+	 */
+	spinlock_t fw_busy_lock;
+	struct se_if_device_ctx *fw_busy_dev_ctx;
+	struct work_struct fw_busy_work;
 
 	struct se_if_device_ctx *priv_dev_ctx;
+	struct list_head dev_ctx_list;
+
+	/* prevent modifying priv member variable in parallel. */
+	struct mutex modify_lock;
+	u32 active_devctx_count;
+	u32 dev_ctx_mono_count;
+
+	/* Add reference counting */
+	struct kref refcount;
+
+	/* stable gate used by .open() */
+	struct se_if_open_gate *open_gate;
 };
 
 char *get_se_if_name(u8 se_if_id);
+void unset_dev_ctx_as_command_receiver(struct se_if_device_ctx *dev_ctx);
+int set_dev_ctx_as_command_receiver(struct se_if_device_ctx *dev_ctx);
+bool se_is_fw_busy_ctx(struct se_if_device_ctx *dev_ctx);
+void se_dev_ctx_shared_mem_cleanup(struct se_if_device_ctx *dev_ctx);
+int get_shared_mem_slot(struct se_if_device_ctx *dev_ctx,
+			u32 *length, dma_addr_t *ele_dma_addr, void **ptr);
+int se_get_mem_pool_buf(struct se_if_device_ctx *dev_ctx, void **buf,
+			dma_addr_t *daddr, u32 len);
+void se_cleanup_mem_pool_buf(struct se_if_device_ctx *dev_ctx, bool reclaim);
 #endif
diff --git a/include/uapi/linux/se_ioctl.h b/include/uapi/linux/se_ioctl.h
new file mode 100644
index 000000000000..6302ff66034f
--- /dev/null
+++ b/include/uapi/linux/se_ioctl.h
@@ -0,0 +1,97 @@
+/* SPDX-License-Identifier: (GPL-2.0 WITH Linux-syscall-note) OR BSD-3-Clause*/
+/*
+ * Copyright 2025 NXP
+ */
+
+#ifndef SE_IOCTL_H
+#define SE_IOCTL_H
+
+#include <linux/types.h>
+
+#define SE_TYPE_STR_DBG			"dbg"
+#define SE_TYPE_STR_HSM			"hsm"
+#define SE_TYPE_ID_UNKWN		0x0
+#define SE_TYPE_ID_DBG			0x1
+#define SE_TYPE_ID_HSM			0x2
+/* IOCTL definitions. */
+
+struct se_ioctl_setup_iobuf {
+	__u64 user_buf;
+	__u32 length;
+	__u32 flags;
+	__u64 ele_addr;
+};
+
+struct se_ioctl_shared_mem_cfg {
+	__u32 base_offset;
+	__u32 size;
+};
+
+struct se_ioctl_get_if_info {
+	__u8 se_if_id;
+	__u8 interrupt_idx;
+	__u8 tz;
+	__u8 did;
+	__u8 cmd_tag;
+	__u8 rsp_tag;
+	__u8 success_tag;
+	__u8 base_api_ver;
+	__u8 fw_api_ver;
+};
+
+struct se_ioctl_cmd_snd_rcv_rsp_info {
+	__u64 tx_buf;
+	__u64 rx_buf;
+	__u32 tx_buf_sz;
+	__u32 rx_buf_sz;
+};
+
+struct se_ioctl_get_soc_info {
+	__u16 soc_id;
+	__u16 soc_rev;
+};
+
+/* IO Buffer Flags */
+#define SE_IO_BUF_FLAGS_IS_OUTPUT	(0x00u)
+#define SE_IO_BUF_FLAGS_IS_INPUT	(0x01u)
+#define SE_IO_BUF_FLAGS_USE_SEC_MEM	(0x02u)
+#define SE_IO_BUF_FLAGS_USE_SHORT_ADDR	(0x04u)
+#define SE_IO_BUF_FLAGS_IS_IN_OUT	(0x10u)
+
+/* IOCTLS */
+#define SE_IOCTL			0x0A /* like MISC_MAJOR. */
+
+/*
+ * ioctl to designated the current fd as logical-reciever.
+ * This is ioctl is send when the nvm-daemon, a slave to the
+ * firmware is started by the user.
+ */
+#define SE_IOCTL_ENABLE_CMD_RCV	_IO(SE_IOCTL, 0x01)
+
+/*
+ * ioctl to get the buffer allocated from the memory, which is shared
+ * between kernel and FW.
+ * Post allocation, the kernel tagged the allocated memory with:
+ *  Output
+ *  Input
+ *  Input-Output
+ *  Short address
+ *  Secure-memory
+ */
+#define SE_IOCTL_SETUP_IOBUF	_IOWR(SE_IOCTL, 0x03, struct se_ioctl_setup_iobuf)
+
+/*
+ * ioctl to get the mu information, that is used to exchange message
+ * with FW, from user-spaced.
+ */
+#define SE_IOCTL_GET_MU_INFO	_IOR(SE_IOCTL, 0x04, struct se_ioctl_get_if_info)
+/*
+ * ioctl to get SoC Info from user-space.
+ */
+#define SE_IOCTL_GET_SOC_INFO      _IOR(SE_IOCTL, 0x06, struct se_ioctl_get_soc_info)
+
+/*
+ * ioctl to send command and receive response from user-space.
+ */
+#define SE_IOCTL_CMD_SEND_RCV_RSP _IOWR(SE_IOCTL, 0x07, struct se_ioctl_cmd_snd_rcv_rsp_info)
+#endif

-- 
2.43.0

