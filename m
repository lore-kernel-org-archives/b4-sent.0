From: Pankaj Gupta <pankaj.gupta@nxp.com>
Subject: [PATCH v37 0/7] firmware: imx: driver for NXP secure-enclave
Date: Wed, 19 Aug 2026 17:12:06 +0530
Message-Id: <20260819-imx-se-if-v37-0-5ef5de9ff1dc@nxp.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAI6WhWoC/3WVy25bIRBAfyXyuo7myUBX+Y+qCy6PxosmkV1Zq
 aL8e8GqfIGq8uoiH2YYzgwfh0s5n8rl8PXh43Au19Pl9PrSPti+PBzSc3z5UY6n3BYOBCSgYMf
 Tz/fjpa3WYxQAVQickzu0/7+dSz293zb79r19P58uv17Pv297X7Gv/t0FYdjlikc4kiWNziSgy
 08v72+P6fXnoe9xpYEjHjlqXINqRh+icpg53jmHY9ZXbly0TD6XqEnizMnOGejISY9HGQAK+oh
 LnjpwSCOnjXMuWgjA0RvNnBs4mjjXuFLINWbztOZpOxdARs5udamZ4mZCTmbO3zkEnM7nGxdQh
 X0LaplnLoycG7nQuJp9jZBAStxmDmEHcU60aQDHrYIDzykFqwu5K4NEszLdGUhWnGaLxdaYd2k
 UcCG7NUlLC6eiBmkheSe5RRnJ7k1IybWjZpdxJWUgaRIOuzlEGER8YCrLjaDupMBMdncKs6dUU
 o6AC+lGMkxkt6c1hRStLGhlIW0gabpOtFttvaJqVMhrTL+TDueY3aAUPAfcosjayRh2MiwV6g5
 lLFaCg4Tolxlwd0jbdc5DoDsUQSK1VibVxSHCgZzbkvDWX5ZdGyzZyxqTRtJPZHcITNCn1s7tM
 AvJIzlViLpDmpwZtznC/5zz7pBr3k72kdy8JaJcFVNapgjpSM7n1FtMLu23uRDXmG4nHc3Zdod
 QXLtK8mqyeEu2kzaPEuoObZsl0aDUOnwh/UhOJlB3CGJwGnp7h/U1CAO5VKg71ERgR1VqSsu8Z
 BjJaQ5xdygVvzWJnAu0dDbjSE4V4ptDGmK1mDfzS4WYBpKnOcTdoaBVXa5Vtri+XryTfn6GuDv
 UXC5MtQIFXUj5P9kdsiKGnFEKrBXSkZxmAneHEDfSbWPwZekyHhzyy2PbHZLem15sa8/E0+vl8
 ninPz8//wBjy3LLgwgAAA==
To: Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Frank Li <Frank.Li@nxp.com>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Pankaj Gupta <pankaj.gupta@nxp.com>
Cc: linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, 
 Frieder Schrempf <frieder.schrempf@kontron.de>, 
 sashiko-bot <sashiko-bot@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787139727; l=80833;
 i=pankaj.gupta@nxp.com; s=20260817; h=from:subject:message-id;
 bh=xYriJFO527j7glc7bNTKlVk33oEeRjz/z85G4q+J8kg=;
 b=AXdu0bGnjvLzH5mwugzOfPu6t8M5uvZ2M9NC70xLzThmGWiHpYw1BpT6H+l1Qw2s1SmoiOkIK
 SxAOyb3eI0ECqd+2mmPFpGwMOw8o5S71YqdykZbMKZzGkDpJTz7c/tc
X-Developer-Key: i=pankaj.gupta@nxp.com; a=ed25519;
 pk=g4ZgzIWbpXnSxRsoH+l6PWLP78a+Mzpl8e6RQe74d5Y=
X-Endpoint-Received: by B4 Relay for pankaj.gupta@nxp.com/20260817 with auth_id=962
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The NXP's i.MX EdgeLock Enclave, a HW IP creating an embedded secure
enclave within the SoC boundary to enable features like
- HSM
- SHE
- V2X

Communicates via message unit with linux kernel. This driver is
enables communication ensuring well defined message sequence protocol
between Application Core and enclave's firmware.

Driver configures multiple misc-device on the MU, for multiple
user-space applications can communicate on single MU.

It exists on some i.MX processors. e.g. i.MX8ULP, i.MX93 etc.

-------
Changes in v37:

1/7, 2/7, 3/7, 4/7, 6/7 & 7/7:
- No changes

5/7:
1. [High] DMA-after-free when a fatal signal races driver unbind.
   ele_msg_rcv() gated se_mark_fw_busy() on !completion_done(), but
   se_if_probe_cleanup() calls complete_all() before freeing the DMA
   buffer. At that point completion_done() returns true, so the circuit
   breaker was skipped and teardown freed the DMA buffer while the
   enclave could still be writing into it. Remove the !completion_done()
   guard: arm the circuit breaker unconditionally when rx_msg is still
   set and rx_delivered is not. rx_delivered (set by se_if_rx_callback()
   under clbk_rx_lock after a genuine response is copied) is the correct
   guard for the safe case.

2. [High] ELE_STORAGE_OPEN_REQ allowed when cmd_receiver slot occupied.
   If process A already registered as command receiver and process B
   issued ELE_STORAGE_OPEN_REQ, the command was forwarded to firmware
   which allocated a new storage handle. NVM callbacks for that handle
   were then routed to process A (the existing receiver), letting A
   observe and tamper with B's NVM traffic. Pre-check the cmd_receiver
   slot in ele_uapi_allowed_fw_cmd() for ELE_STORAGE_OPEN_REQ and reject
   with -EBUSY before the command reaches firmware, so no handle is
   allocated when the slot is occupied by another context.

3. [High] Short rx_buf_sz bypasses handle recording causing a firmware
   resource leak. For ELE_SESSION_OPEN_REQ and ELE_STORAGE_OPEN_REQ the
   caller-supplied rx_buf_sz is now validated against the minimum
   response size (ELE_SESSION_OPEN_RSP_SZ / ELE_STORAGE_OPEN_RSP_SZ) in
   ele_uapi_allowed_fw_cmd() before the command is sent to firmware. If
   the buffer is too small to receive the response carrying the
   FW-allocated handle, the command is rejected with -EINVAL up-front
   rather than letting the handle be allocated and then lost because
   se_val_rsp_hdr_n_status() rejects the truncated response.
   se_chk_tx_msg_hdr() / ele_uapi_allowed_fw_cmd() now accept rx_msg_sz
   as an additional parameter for this check.

4. [High] Uninitialized stack buffer passed to fw_api_specific_ops().
   rx_msg_snap[MAX_NVM_MSG_LEN] in se_if_fops_read() was declared
   without initialization. memcpy filled only min(size, rx_msg_sz) bytes;
   the remainder contained stack garbage. For ELE_STORAGE_MASTER_EXPORT_REQ
   fw_api_specific_ops() reads data[1] as the export-buffer size, which
   would be garbage if the caller supplied a short read length, corrupting
   the DMA bounds check. Initialize the array to zero so any un-copied
   portion is safely zero.

Reference:
- Link to v36: https://lore.kernel.org/r/20260817-imx-se-if-v36-0-45c42847bfd8@oss.nxp.com

Changes in v36:

5/7:
- [High] Fixes the leake of session/storage handle while response copy-out
  failed.
    
- [High] Fixes the racing of close() with driver unbind could transmit on
  a freed mailbox tx channel.

- [High] Fixes a signal during the long-timeout wait left the task
  effectively unkillable.

- [Critical] Fixes the vulnerability of not letting the secure enclave access
  the physical DMA addresses embedded in raw FW commands, that are out
  of bounds.
    
3/7:
- firmware: imx: fix se_restore_imem_state() bad IMEM state handling

Reference:
- Link to v35: https://lore.kernel.org/r/20260806-imx-se-if-v35-0-11b25bb308ef@nxp.com

Changes in v35:

1/7, 2/7, 3/7, 4/7, 6/7 & 7/7: 
- No changes.

5/7:
- [High] Close request built with base API version but validated with
  FW API version.
  se_close_session()/se_close_storage() formatted the request header
  with se_fill_cmd_msg_hdr(..., is_base_api=true) yet validated the
  response with se_val_rsp_hdr_n_status(..., is_base_api=false). The
  version mismatch made validation fail with -EINVAL, so teardown
  closes always reported failure and the FW session/storage handle was
  leaked. Format the close requests with the FW API version to match
  the response validation.

- [High] Storage handle recorded only after receiver registration.
  In fw_api_specific_ops() ELE_STORAGE_OPEN_REQ, dev_ctx->strg_hdl was
  assigned only after a successful set_dev_ctx_as_command_receiver().
  A failing registration (e.g. -EBUSY) left strg_hdl at 0 while the
  ioctl still returned success, so cleanup_dev_ctx() never closed the
  handle and it leaked in FW. Record the handle first, then register.

- [High] Close request did not verify the payload handle belongs to the
  caller.
  ele_uapi_allowed_fw_cmd() only checked that the calling context had
  some session/storage open, not that the handle carried in the payload
  (data[0]) matched. A process could submit a close for another
  process's handle. Thread the tx buffer size through
  se_chk_tx_msg_hdr()/ele_uapi_allowed_fw_cmd() and, for the session
  and storage close requests, reject a buffer too short to hold data[0]
  or a data[0] that does not match this context's own handle. Checking
  the size first also keeps the data[0] read in bounds.

- [High] Concurrent close() racing driver unbind could transmit on a
  freed mailbox channel.
  se_close_session()/se_close_storage() hardcoded priv->priv_dev_ctx as
  the transport, bypassing the going_away teardown safeguard in
  ele_msg_send_rcv(). A userspace close() racing unbind could send on a
  freed priv->tx_chan (use-after-free in mbox_send_message()). Pass the
  transport context explicitly: cleanup_dev_ctx() sends userspace-close
  (is_fclose) traffic on the caller's own dev_ctx so the going_away
  check rejects it with -ENODEV, while the teardown path keeps using
  priv_dev_ctx, the only context let through going_away for
  teardown-close messages while tx_chan is still live.

- [Medium] Interrupted wait discarded an already-delivered FW response
  and leaked the handle.
  On an interrupted wait ele_msg_send_rcv() converts a successful
  (err > 0) result to -ERESTARTSYS. The ioctl handler returned early on
  err < 0 without recording the session/storage handle, so a handle the
  FW had already allocated (and returned in the delivered response) was
  never tracked and leaked. Keep returning -EINTR to userspace so it can
  run its signal handler and the syscall is not auto-restarted, but
  before returning, validate the already-delivered response and, if it
  is well formed, copy out data and run fw_api_specific_ops() so the
  handle is recorded and closed on teardown. No memory is leaked: the
  err < 0 path still calls se_ioctl_cmd_snd_rcv_cleanup() and the tx/rx
  buffers are freed via __free(kfree).

Reference:
- Link to v34: https://lore.kernel.org/r/20260805-imx-se-if-v34-0-7e4713d14e0a@nxp.com

Changes in v34:
5/7:
Teardown vs. in-flight transaction (lost wakeup / unbind hang):
- se_if_probe_cleanup() now sets priv->going_away under clbk_rx_lock
  instead of se_if_cmd_lock. se_if_cmd_lock is held across the whole
  blocking transaction, so acquiring it during unbind could stall for a
  full receive timeout. clbk_rx_lock is the short spinlock the sender
  holds while arming a transaction, so setting going_away under it and
  then calling complete_all() makes teardown and arming mutually
  exclusive and closes the lost-wakeup window.
- complete_all() is issued before walking the device-context list so a
  waiter sleeping on the completion while holding dev_ctx->fops_lock is
  released before cleanup takes the same lock, avoiding an unbind hang.

ele_msg_send_rcv() arming:
- going_away and fw_busy are now evaluated under clbk_rx_lock together
  with reinit_completion() and the buffer publish, so a new transaction
  is never armed concurrently with teardown.
- going_away is checked before fw_busy so a caller racing unbind gets a
  permanent -ENODEV rather than a misleading retryable -EBUSY. fw_busy
  is only atomic_read() here, so no fw_busy_lock is taken and there is
  no deadlock. Teardown session/storage close commands issued on
  priv_dev_ctx are still let through so the kernel can resynchronise
  state with FW.

ele_msg_rcv() response classification:
- Add se_clbk_handle::rx_delivered, set by se_if_rx_callback() under
  clbk_rx_lock only after a real response is copied. ele_msg_rcv() uses
  it to tell a genuine firmware response apart from a teardown-forced
  complete_all() that wakes the waiter with no data. Without this a
  teardown-time close response could be mistaken for the forced abort,
  failing the close and leaking its DMA buffer, and a forced wakeup
  could be mistaken for a response while the enclave still DMAs into the
  shared buffer. The forced-abort path returns -ENODEV and arms the
  circuit breaker so the buffer is quarantined, not freed.

Session/storage handle tracking (ele_uapi_allowed_fw_cmd()):
- Reject a repeated ELE_SESSION_OPEN_REQ / ELE_STORAGE_OPEN_REQ with
  -EEXIST when a handle is already open, preventing a handle leak.
- Reject ELE_SESSION_CLOSE_REQ / ELE_STORAGE_CLOSE_REQ with -ENXIO when
  no handle is open.

se_close_session() / se_close_storage():
- Use __free(kfree) scope-based cleanup consistently and return directly
  instead of mixing it with goto-based cleanup.

Reference:
- Link to v33: https://lore.kernel.org/r/20260805-imx-se-if-v33-0-212e32ff0295@nxp.com

Changes in v33:
5/7: Sashiko AI comment disposition (5/7, 8 comments; 5 fixed, 3 no-change):

- [High] 32/64-bit ABI mismatch in struct se_ioctl_cmd_snd_rcv_rsp_info:
  FIXED. The members were ordered __u64 tx_buf, __u32 tx_buf_sz, __u64
  rx_buf, __u32 rx_buf_sz, so the second __u64 (rx_buf) forced 4 bytes of
  implicit padding after tx_buf_sz. That padding makes the struct size
  (and therefore the _IOWR() size baked into SE_IOCTL_CMD_SEND_RCV_RSP)
  differ between 32- and 64-bit userspace. The two __u64 members are now
  placed first, followed by the two __u32 members, giving a naturally
  packed, padding-free layout that is identical for 32- and 64-bit
  callers.
- [High] fops write/read/ioctl/open returned -EBUSY when the interruptible
  mutex acquisition was aborted by a signal: FIXED. scoped_cond_guard(
  mutex_intr, ...) and mutex_lock_interruptible() abort with an
  interrupted-wait status when a signal is pending, but the handlers
  anslated that into -EBUSY, which userspace cannot distinguish from a
  genuinely contended device and which defeats automatic syscall restart.
  The interrupted-acquire paths in se_if_fops_write(), se_if_fops_read(),
  se_if_fops_open() (both the gate->lock and priv_dev_ctx->fops_lock
  acquisitions) and se_ioctl() now return -ERESTARTSYS, so the kernel
  restarts the syscall or reports -EINTR per the caller's SA_RESTART
  disposition. The three remaining -EBUSY returns (command receiver
  already registered, and the two firmware-busy circuit-breaker checks)
  are genuine non-signal conditions and are intentionally left unchanged.

- [High] se_if_fops_read() could strand an already-consumed response when
  the fops_lock reacquire after the wait was interrupted: FIXED. The read
  path drops fops_lock while waiting for the firmware response and then
  reacquired it with mutex_lock_interruptible(), returning -ERESTARTSYS on
  a pending signal. By that point the message had already been received
  and committed, so aborting on a signal discarded a completed response
  that could not be re-fetched. The reacquire now uses an uninterruptible
  mutex_lock(); the wait itself stays interruptible, and the cleanup_done
  re-check under fops_lock is preserved.

- [High] TOCTOU / lost-wakeup between ele_msg_send_rcv() and
  se_if_probe_cleanup(): FIXED. ele_msg_send_rcv() checks going_away and
  arms the response completion under se_if_cmd_lock, but teardown set
  going_away and called complete_all() outside that lock. A thread parked
  on se_if_cmd_lock could therefore arm the completion after the teardown
  wakeup had already fired, then block for the full timeout while unbind
  waited on that thread's fops_lock. se_if_probe_cleanup() now sets
  going_away and calls complete_all() while holding se_if_cmd_lock, making
  teardown and the arming path mutually exclusive so the wakeup can no
  longer be lost. As part of tear-down, close-session & close-storage msg
  is sent to FW using priv_dev_ctx, to keep FW in sync.

- [High] NULL-pointer dereference on the init_misc_device_context() error
  path: FIXED. dev_ctx->priv was assigned only after the kasprintf() that
  builds devname, but the kasprintf() failure path jumps to a cleanup that
  calls cleanup_se_shared_mem(), which dereferences dev_ctx->priv->mem_pool.
  If kasprintf() failed, priv was still NULL and cleanup dereferenced NULL.
  The dev_ctx->priv = priv assignment is moved to immediately after the
  allocation succeeds, before any goto to the error path.

- [High] Unbounded per-open DMA allocation (device-context exhaustion):
  NO-CHANGE. Each open() reserves a MAX_DATA_SIZE_PER_USER (128 KB) buffer
  via dma_alloc_coherent(), but on these platforms the device is bound to
  a fixed no-map reserved DMA pool (the ele_reserved "shared-dma-pool"
  region attached with of_reserved_mem_device_init() in probe).
  Allocations are served exclusively from that bounded pool and cannot
  exhaust general system memory; once the pool is full dma_alloc_coherent()
  returns NULL, init_se_shared_mem() returns -ENOMEM and open() fails
  gracefully. The bounded pool together with the per-process RLIMIT_NOFILE
  is the real, self-adjusting limit, so no artificial open-count cap is
  added. No code change.

- [High] SE_IOCTL_CMD_SEND_RCV_RSP reports -EINTR for a successful but
  signal-interrupted transaction: NO-CHANGE. This is the intended Ctrl+C
  behaviour. The underlying firmware command is not idempotent and must
  not be silently re-issued, so once the wait is interrupted the
  deferred-signal path resynchronises the protocol and ele_msg_send_rcv()
  reports -ERESTARTSYS, which the handler surfaces as -EINTR to the
  interrupted application. Reporting plain success here would hide the
  interruption from the caller. No code change.

- [High] Use-after-free of the open gate / priv between open() and unbind:
  NO-CHANGE (false positive). misc_open() and misc_deregister() are
  serialised by misc_mtx, and the open path takes a reference on the stable
  se_if_open_gate with kref_get_unless_zero() and re-validates
  gate->dying / gate->priv under gate->lock before use, so it can never
  operate on a torn-down gate. No code change.

3/7
- Sample jiffies once. jiffies is volatile, so reading
  it separately for the deadline check and for the
  remaining-time subtraction would be a TOCTOU: a timer
  tick (or a NO_HZ/virtualized tick catch-up that jumps
  jiffies by several ticks) landing between the two
  reads could push jiffies past the deadline and make
  deadline_jiffies - jiffies underflow to a near
  ULONG_MAX timeout, hanging the wait. One snapshot
  keeps both uses consistent, so now < deadline_jiffies
  guarantees a strictly positive remainder.

Reference:
- Link to v32: https://lore.kernel.org/r/20260730-imx-se-if-v32-0-95f56dff4ba9@nxp.com

Changes in v32:
5/7:
- [Critical, new] Kernel panic while traversing the uninitialised
  mem_pool_buf_list head during device-context cleanup: FIXED.
  init_se_shared_mem() only ran INIT_LIST_HEAD() on mem_pool_buf_list
  when priv->mem_pool was non-NULL, but cleanup_se_shared_mem() called
  se_cleanup_mem_pool_buf() unconditionally, and that walks the head
  with list_for_each_entry_safe() on every close/teardown. On interfaces
  with no gen_pool (e.g. imx93, which has no pool_name so
  priv->mem_pool == NULL) the head stayed zero-filled (next/prev == NULL)
  and the cleanup walk dereferenced NULL. cleanup_se_shared_mem() now
  calls se_cleanup_mem_pool_buf() only when priv->mem_pool is non-NULL;
  interfaces without a pool have nothing to reclaim, so the walk is
  simply skipped.
- [High, new] SE_IOCTL_CMD_SEND_RCV_RSP returned a positive value to
  userspace on success, masking the plain-success contract: FIXED.
  ele_msg_send_rcv() returns a positive received-message size on success,
  so on the happy path err held that size and was returned as the ioctl
  result, making a successful transaction look like a positive (non-zero)
  return value. The handler now records the received size in
  rx_buf_sz (copied back to userspace in the response info) and
  normalises err to 0 so the ioctl reports plain success. The firmware
  response header/status is validated by se_val_rsp_hdr_n_status() and
  conveyed to userspace inside the response buffer itself; an -EFAULT
  copy_to_user() failure or a cleanup error still takes precedence over
  the success return.
- [High, new] slab-out-of-bounds read in se_val_rsp_hdr_n_status() when
  handling debug-dump responses with a small rx_buf_sz: FIXED. Commands
  that take the variable-length exception in check_hdr_exception_for_sz()
  bypass the header/size match check, so the caller's receive buffer may
  be smaller than the size the firmware header claims. Reading the status
  word msg->data[0] with an rx_buf_sz as small as SE_MU_HDR_SZ over-read
  the allocation. The status word is now read only when both the firmware
  header count (header->size) and the received size in words (sz >> 2)
  exceed the header word SE_MU_HDR_WORD_SZ, so a debug-dump response whose
  received buffer is too small to hold the status word skips the read
  instead of over-reading the allocation.
- [High, pre-existing] Internal kernel HW ops (IMEM save/restore during
  suspend/resume) fail spuriously with -ERESTARTSYS when a signal is
  pending, breaking PM transitions: FIXED. All internal kernel-initiated
  transactions run on priv->priv_dev_ctx (probe-time get_info/ping,
  firmware authentication, and the PM IMEM export/import). These are not
  issued on behalf of a restartable userspace syscall, so ele_msg_rcv()
  now waits uninterruptibly whenever dev_ctx == priv->priv_dev_ctx. The
  freezer's fake signals raised during a system PM transition can no
  longer abort them with -ERESTARTSYS; only genuine userspace ioctl/read
  waiters remain interruptible and use the existing deferred-signal path.
- [Critical, new] Userspace can construct raw command payloads and embed
  unvalidated DMA addresses (confused-deputy): NO-CHANGE. Passing
  physical/DMA addresses inside the message body is inherent to the
  firmware ABI this interface exposes, and is constrained by
  se_chk_tx_msg_hdr() -> ele_uapi_allowed_base_cmd()/
  ele_uapi_allowed_fw_cmd(), which restrict the command set to a
  vetted allow-list (power-management, reset, BBSM, RNG init, FW
  re-init, CAAM resource release and SE internal memory management are
  all blocked). The enclave firmware is the trust boundary that
  validates addresses against the caller's provisioned resources;
  per-command address bounds-checking in the kernel would duplicate that
  policy without owning the authoritative resource map. No code change.
- [High, new] Firmware commands to the command receiver can overwrite an
  unprocessed command (se_if_rx_callback() cmd_tag branch memcpy+complete
  unconditionally): NO-CHANGE. The NVM command-receiver protocol is
  half-duplex: the firmware issues one storage/NVM command at a time and
  waits for the userspace daemon's response before issuing the next, so
  there is no in-flight command to overwrite. The receiver uses a
  dedicated long-lived buffer and clbk_rx_lock already serialises the
  callback against se_if_fops_read(). No code change.
- [High, new] TOCTOU race between ele_msg_send_rcv() checking going_away
  and se_if_probe_cleanup() forcing wakeup (lost wakeup / deadlock):
  NO-CHANGE. The ordering is already safe: se_if_probe_cleanup() sets
  going_away before complete_all() (with an explicit ordering comment),
  ele_msg_send_rcv() reads going_away under se_if_cmd_lock and bails with
  -ENODEV before reinit_completion(), and ele_msg_rcv() re-checks
  going_away after the wake and returns -ENODEV so a teardown-forced
  completion is never mistaken for a real response. No code change.

4/7:
- moved the cleanup of priv_dev_ctx->dev_name & priv_dev_ctx, in the end of
  se_if_probe_cleanup(), after priv->rx_chan freed.
  Though it gets replaced in the next patch.

Reference:
- Link to v31: https://lore.kernel.org/r/20260729-imx-se-if-v31-0-e59af7adb784@nxp.com

Changes in v31:
7/7
- Kernel is free to choose the exact placement of the 1 MiB block, as long
  as it lands inside the ELE-accessible window. This avoids hardcoding a
  fixed address.
- Adds a new shared imx8ulp-firmware.dtsi that also enables the hsm0
  node and wires up its memory-region, so every i.MX8ULP board can bring up
  the enclave with a single include instead of duplicating the reserved
  memory node. Include it from imx8ulp-evk.

6/7:
- Keep the node disabled in the SoC dtsi so it does not impose a
  reserved-memory requirement on every board. Boards enable the enclave and
  provide its memory-region by including imx8ulp-firmware.dtsi.

5/7:
- [Critical, new] Driver unbind forcefully wakes waiting ioctls and
  clears firmware-busy state, causing DMA use-after-free by hardware:
  FIXED. ele_msg_rcv() detects the teardown-forced wake
  (is_rsp_wait_with_timeout && going_away), clears rx_msg, arms the
  circuit breaker via se_mark_fw_busy() and returns -ENODEV; the woken
  thread no longer treats the forced wake as success and does not free
  the buffer. se_clear_fw_busy() quarantines (does not reclaim) the DMA
  buffer during teardown.
- [High, new] Late mailbox interrupt schedules fw_busy_work after
  cancel_work_sync(), use-after-free of priv: FIXED.
  se_if_probe_cleanup() now frees the rx mailbox channel
  (mbox_free_channel) before cancel_work_sync(&priv->fw_busy_work), so
  no further se_if_rx_callback() can re-arm the work; the cancel is
  final.
- [High, new] Unbind deadlock/hang: a concurrent ioctl blocked on
  se_if_cmd_lock misses complete_all(), re-arms and waits the full
  timeout while unbind blocks on fops_lock: FIXED. going_away is set at
  the very start of teardown before complete_all(); ele_msg_send_rcv()
  checks going_away under se_if_cmd_lock and returns -ENODEV before
  reinit_completion(), so the thread bails out instead of re-arming.
= [Medium, new] 128 KB DMA shared-memory buffer of the internal
  priv_dev_ctx permanently leaked on unbind: FIXED. New
  se_shared_mem_mgmt_info.mem_pool_buf_list plus
  se_get_mem_pool_buf()/se_cleanup_mem_pool_buf() track pool
  allocations; se_if_priv_release() reclaims the internal context
  directly so the buffer is released deterministically (except the
  intentional fw_busy quarantine from the Critical fix above).
- [High, pre-existing] Race between se_if_rx_callback() and
  se_if_fops_read() on the shared rx_msg command-receiver buffer, data
  corruption: FIXED. se_if_fops_read() bounces the payload into a local
  u8 rx_msg_snap[MAX_NVM_MSG_LEN] under clbk_rx_lock, then
  copy_to_user() from the private copy after unlocking. copy_len is
  bounded by MAX_NVM_MSG_LEN so the stack buffer cannot overflow.
- [High, pre-existing] Dangling priv->dev passed to
  dma_free_coherent()/dev_warn() if an fd is closed after device unbind:
  FIXED. get_device(priv->dev) in se_if_probe() pins the parent device
  for the lifetime of priv and is balanced by put_device(priv->dev) in
  se_if_priv_release(), so priv->dev stays valid for a late close().

4/7:
-  add the cleanup of priv_dev_ctx->dev_name & priv_dev_ctx, as part of
   se_if_probe_cleanup(). Though it gets replaced in the next patch.

3/7:
- ele_msg_send_rcv(): publish rx_msg/rx_msg_sz under clbk_rx_lock so
  se_if_rx_callback() cannot observe a torn pair. This change is part
  of 5/7, already.
- ele_msg_rcv(): engage the fw_busy breaker on the deadline path, like
  the ret==0 path, so a hung FW is fenced.
- ele_get_info(): zero the gen_pool_dma_alloc() buffer, which is not
  zeroed on allocation.

Two findings need no code change:
- DMA free on timeout: -ETIMEDOUT means FW is fenced by fw_busy, so the
  free is safe.
- -ERESTARTSYS after a completed transaction: the command is not
  re-sent and the ioctl path converts it to -EINTR.

References:
- Link to v30: https://lore.kernel.org/r/20260724-imx-se-if-v30-0-ce8ba256692c@nxp.com

Changes in v30:

3/7
This change dispositions all six findings from the Sashiko AI review:
- Five are code fixes (three in se_ctrl.c, two in ele_common.c);
- One is documented as intentional protocol-synchronization behavior.

Addressed (drivers/firmware/imx/se_ctrl.c):
- [High] Incorrect devres registration order (UAF / NULL pointer deref
  in the mailbox RX callback):
- [Medium] priv structure leak on early probe failure paths:
  The cleanup action is now registered before the channel requests, so
  priv is released even if se_if_request_channel() fails early.
- [Medium] soc_device singleton lifecycle tied to the first probed MU
  interface (data race and premature sysfs deletion):
  Decouple the singleton from the first-probed MU interface. Track it in
  var_se_info.soc_dev_regn and release it once at module unload via an
  explicit module_init()/module_exit() pair instead of a devm action on
  priv->dev. Serialize soc_dev registration state under se_var_info_lock;
  se_soc_device_unregister() now takes the lock via guard(mutex).

Addressed (drivers/firmware/imx/ele_common.c):
- [High] Data race on rx_msg_sz in se_if_rx_callback():
  Move the read of the expected response size (exp_rx_msg_sz =
  se_clbk_hdl->rx_msg_sz) to after clbk_rx_lock is acquired, so it can no
  longer be observed stale relative to a concurrent transaction updating
  rx_msg_sz under the lock. This prevents copying truncated or corrupted
  response data.
- [Medium] ele_msg_rcv() reset the timeout after a signal instead of
  accounting for elapsed time:
  For the response-waiter path, compute an absolute deadline_jiffies once
  and derive remaining_jiffies from it on every iteration. After a signal
  falls back to an uninterruptible wait, the wait no longer restarts the
  full timeout; the deadline is honored and -ETIMEDOUT is returned when it
  elapses.

Documented as intentional, no code change (drivers/firmware/imx/ele_common.c):
- [Medium] "Unsafe syscall restart on completed non-idempotent hardware
  operations" in ele_msg_send_rcv():
  This is intentional protocol-synchronization behavior, not a
  re-execution bug. A signal is deliberately not acted on while a firmware
  message exchange is in progress; ele_msg_rcv() defers it until the
  response path completes and the FW/kernel protocol state is synchronized
  again, so Linux and firmware never diverge on message ownership. Only
  after synchronization is the interrupted wait surfaced to userspace via
  -ERESTARTSYS. The command/response ABI must treat this as an interrupted
  operation after synchronization; it is not permission for the kernel
  driver to re-send the command, so the enclave never receives it twice.
  Clarified with an expanded code comment.

4/7: Sashiko AI issues resolved in this patch; no functional change
     required beyond a cosmetic whitespace cleanup:

- [High][NEW] Accessing se_clbk_hdl->dev_ctx->devname outside
  clbk_rx_lock in the cmd_tag path (UAF / NULL deref):
  Already fixed. In se_if_rx_callback(), the cmd_tag path holds
  clbk_rx_lock across the dev_dbg() that reads dev_ctx->devname and only
  proceeds after the explicit "!se_clbk_hdl->dev_ctx" check. The devname
  used by the post-unlock dev_err() is cached into a local (devname)
  while the lock is still held, so no dev_ctx dereference happens outside
  the lock.
- [High] Incorrect devm registration order frees priv while the RX
  mailbox channel is still active (NULL deref):
  Already fixed in drivers/firmware/imx/se_ctrl.c. se_if_probe()
  registers devm_add_action_or_reset(dev, se_if_probe_cleanup, pdev)
  before requesting the tx/rx mailbox channels, so LIFO teardown frees
  the channels (se_if_probe_cleanup) before priv is released.
- [High] Memory leak of priv when early probe steps fail:
  Already fixed by the same change. priv is allocated, stored via
  dev_set_drvdata(), and its release is tied to se_if_probe_cleanup(),
  which is registered early; any subsequent probe failure unwinds through
  the devres action that frees priv.
- [High] Unprotected read of rx_msg_sz creates a TOCTOU race leading to
  response truncation on late interrupts:
  Already fixed. The rsp_tag path in se_if_rx_callback() reads
  exp_rx_msg_sz = se_clbk_hdl->rx_msg_sz only after acquiring
  clbk_rx_lock (and after confirming rx_msg != NULL), so the size cannot
  change between the check and the memcpy().

5/7:
[High] Overwriting a successful firmware transaction with -ERESTARTSYS
  leads to double execution with zeroed DMA buffers.
  Fixed. se_ioctl_cmd_snd_rcv_rsp_handler() now converts the deferred
  -ERESTARTSYS returned by ele_msg_send_rcv() into -EINTR before returning
  to userspace. -EINTR is not auto-restarted by the VFS, so the ioctl is
  not silently re-run against the already cleaned-up (zeroed) shared input
  buffers. Userspace decides whether to reissue the command.

[High] Unbind deadlock/hang caused by incorrect ordering of complete_all()
  and fops_lock.
  Fixed. In se_if_probe_cleanup(), complete_all() on the response waiter is
  now issued before the dev_ctx_list cleanup loop. The blocked ioctl waiter
  sleeps in ele_msg_rcv() while holding its dev_ctx->fops_lock, and
  cleanup_dev_ctx() takes the same lock; waking the waiter first lets it
  drop fops_lock so teardown can proceed instead of hanging.

[High] NULL pointer dereference in se_if_rx_callback().
  Fixed in 3/7. se_if_rx_callback() now checks priv (dev_get_drvdata()) for
  NULL before use. A late mailbox interrupt can be delivered during tear-
  down; the callback returns early instead of dereferencing a cleared
  drvdata.

[High] Out-of-bounds read/write in se_if_rx_callback() by trusting the
  unvalidated firmware payload length.
  Fixed in 3/7. Both the cmd_tag and rsp_tag paths now clamp the memcpy()
  length to min(firmware-declared size, destination buffer capacity). The
  copy never trusts the firmware size beyond what fits in either buffer; a
  size mismatch is still reported after the lock is dropped.

[High] Premature freeing of the gen_pool DMA buffer on timeout.
  Fixed. ele_get_info_cleanup() now guards the gen_pool_free() path with
  se_is_fw_busy_ctx(), mirroring the existing guard on the shared-memory
  path. If the probe-time transaction timed out and firmware may still
  write the SRAM buffer, the buffer is not returned to the pool (it is
  reclaimed with the device on unbind) to avoid pool corruption.

[Medium] Lockdep false positive "possible recursive locking detected" on
  fops_lock.
  Fixed. The internal priv_dev_ctx fops_lock is given a distinct lockdep
  class via lockdep_set_class(). Taking it while an open context's
  fops_lock is held (e.g. a firmware load triggered from an ioctl) is
  valid hierarchical locking and is no longer misreported.

[Medium] Early device exposure to userspace before probe completes.
  Fixed. misc_register() is deferred out of init_misc_device_context() into
  se_if_misc_register(), called at the very end of se_if_probe() after SoC
  info is fetched and the encrypted-IMEM buffer is allocated. The dev_ctx
  and its shared memory are still set up early because the internal
  probe-time ELE_GET_INFO transaction uses priv->priv_dev_ctx directly. A
  new se_if_open_gate.registered flag ensures se_if_probe_cleanup() only
  calls misc_deregister() when registration actually succeeded.

[Critical] Arbitrary physical memory read/write (Confused Deputy) via
  SE_IOCTL_CMD_SEND_RCV_RSP.
  By design, no code change. The SE messaging-unit protocol legitimately
  carries firmware-owned physical DMA addresses inside command payloads, so
  the kernel cannot treat those addresses as the trust boundary. The node is
  root-only (0600); the ELE firmware and the SoC memory-domain/xRDC hardware
  enforce which physical regions the enclave may access, and
  se_chk_tx_msg_hdr() already restricts the permitted command set (power,
  reset, BBSM, FW re-init, RNG init, CAAM release and SE internal memory
  management are all blocked from user-space).

[High] Use-After-Free of gate and miscdev due to a race between unbind and
  VFS open.
  Already safe, documented as defense-in-depth; no code change. misc_open()
  invokes file->f_op->open() while holding misc_mtx, and misc_deregister()
  acquires the same misc_mtx before removing the node, so open() is fully
  serialized against deregistration. The gate is additionally kref-counted
  and se_if_fops_open() takes its reference via kref_get_unless_zero(), so a
  VFS-resolved but not-yet-run open() can never observe a freed gate or
  miscdev.

[Low] Implicit compiler padding in UAPI struct se_ioctl_cmd_snd_rcv_rsp_info.
  WONTFIX, no code change. include/uapi/linux/se_ioctl.h is a stable ABI that
  has shipped to NXP customers for around two years; the member order cannot
  be changed without breaking existing user-space. The 4-byte hole after
  tx_buf_sz is part of the established, frozen layout. The struct uses only
  fixed-width __u64/__u32 members, and the ARM AAPCS aligns 64-bit types to
  8 bytes on both the 32-bit (AArch32) and 64-bit (AArch64) ABIs this i.MX
  driver targets, so the layout (members at offsets 0/8/16/24, sizeof 32) is
  identical for 32-bit and 64-bit user-space and needs no compat-ioctl
  translation.

Reference:
- Link to v29: https://lore.kernel.org/r/20260721-imx-se-if-v29-0-04a362f4fcca@nxp.com

Changes in v29:
5/7:
- Fix ele_get_info() mem_pool path by initializing get_info_len before
  gen_pool_dma_alloc() and checking allocation failure before using the
  returned buffer.

- Add a probe-time comment for ELE_GET_INFO timeout cleanup. The SRAM buffer is
  used only during probe, and a timeout means the secure-enclave interface is
  considered unsynchronized and probe fails.

- Serialize internal priv_dev_ctx shared-memory allocation by taking
  priv_dev_ctx->fops_lock in ele_get_info() and load_firmware().

- Move load_firmware() to use priv_dev_ctx shared memory instead of a temporary
  dma_alloc_coherent() buffer, and skip shared-memory cleanup while priv_dev_ctx
  is marked fw_busy.

- Fix init_misc_device_context() error handling so gate allocation failure sets
  ret = -ENOMEM and releases previously allocated shared memory before freeing
  the device context.

- Release priv_dev_ctx resources through cleanup_dev_ctx() before freeing
  priv_dev_ctx during priv release.

- Guard cleanup_se_shared_mem() against being called before coherent shared
  memory was allocated.

- Fix se_if_fops_read() initialization by assigning priv before first use.

- Avoid modifying command-receiver rx_msg_sz when read() is called from a
  non-command-receiver context.

- Rework se_if_fops_read() to reacquire fops_lock after ele_msg_rcv() returns
  before accessing shared-memory lists or command-receiver state.

- Snapshot the command-receiver rx_msg under clbk_rx_lock and hold modify_lock
  while copying it to userspace, preventing concurrent command-receiver teardown
  from freeing the buffer.

- Clear command-receiver rx_msg_sz under clbk_rx_lock only after consuming the
  message.

- Keep shared-memory cleanup in the read path under fops_lock.

- Mark priv_dev_ctx cleanup_done under fops_lock during probe cleanup so open()

- Register se_if_probe_cleanup after mailbox channel requests so devres LIFO
  ordering runs misc-device cleanup before mailbox channel release.

- Initialize firmware-load state before exposing the misc device to userspace.

4/7:
- priv->waiting_rsp_clbk_hdl.dev_ctx, priv->waiting_rsp_clbk_hdl.rx_msg,
  priv->waiting_rsp_clbk_hdl.rx_msg_sz will be updated after
  acquiring the clbk_rx_lock.
- Create a local variable "const char *devname" and assigned its value
   under the clbk_rx_lock in se_if_rx_callback().

3/7:
- Remove file descriptor, shared-memory setup, and userspace send/receive
  working from the initial Kconfig help text, because the misc-device UAPIs
  added later in the series.

- Replace unaligned u32 pointer access in GET_SERIAL_NUM_FROM_UID() with
  get_unaligned_le32(), avoiding undefined behavior when parsing UID data
  from byte-aligned buffers.

- Add SE_RCV_MSG_DEFAULT_TIMEOUT_MS and set the default response timeout to
  3000 ms.

- Replace MAX_SCHEDULE_TIMEOUT in ele_msg_rcv() with a bounded default response
  timeout using SE_RCV_MS_DEFAULT_TIMEOUT_MS.

- Start handling mailbox messages with IS_ERR_OR_NULL() in se_if_rx_callback()
  before dereferencing msg.

- Fix SoC revision string formatting to print major.minor instead of
  mijor.major.

Fixes for issues reported by Sashiko AI bot on 5/7:
- Move se_if_probe_cleanup devres registration right after mailbox channel
  requests.

- Split the changes into two so that:
  - Initialize load_fw_lock and firmware-load state before the misc device can be
    registered or exposed to userspace in 5/7. Setting load_fw->se_fw_img_nm and
    load_fw->is_fw_tobe_loaded before possible userspace access to the misc device.

  - Keep IMEM management independent from runtime firmware loading metadata.
    Add imem_state_mgmt to struct se_soc_info to separate IMEM save/restore
    buffer management from firmware image availability. Enable IMEM state
    management explicitly for i.MX8ULP by setting imem_state_mgmt = true.
    Allocate encrypted IMEM buffer based on imem_state_mgmt instead of tying it
    to prim_fw_nm_in_rfs.

Reference:
- Link to v28: https://lore.kernel.org/r/20260717-imx-se-if-v28-0-0a9659c7e69d@nxp.com

Changes in v28:

5/7: Fix 10 of the 13 issues reported by Sashiko AI review

- [High] se_ctrl.c: se_if_fops_read(): reacquire fops_lock after
ele_msg_rcv() returns before accessing pending lists or rx_msg.
fops_lock is dropped before the blocking wait; a concurrent close could
free the DMA buffers and pending lists while the read is blocked, leading
to UAF and list corruption. Re-check cleanup_done under fops_lock before
touching any shared state.

- [High] ele_common.c: se_val_rsp_hdr_n_status(): guard msg->data[0] read
with if (header->size > SE_MU_HDR_WORD_SZ). A header-only response (1
word) is valid; the unconditional read caused a KASAN slab-out-of-bounds.

- [High] ele_common.h: reduce SE_RCV_MSG_DEFAULT_TIMEOUT from 5000 s to
3000 ms. After a signal interrupts the interruptible wait, ele_msg_rcv()
switches to TASK_UNINTERRUPTIBLE. A 5000-second uninterruptible sleep
reliably triggers the hung-task watchdog. 3000 ms is well below the
default 120 s threshold.

- [High] se_ctrl.c: cleanup_se_shared_mem(): call
se_dev_ctx_shared_mem_cleanup() to free se_buf_desc list entries before
releasing the DMA backing memory, fixing a leak when the fd is closed
with pending I/O buffers.

- [High] se_ctrl.c: se_dev_ctx_shared_mem_cleanup(): skip memset of DMA
buffers when the context is the fw_busy one (command timed out). The
firmware may still be actively accessing the buffer; zeroing it would
corrupt the in-flight DMA transaction.

- [High] se_ctrl.c: cleanup_se_shared_mem(): guard against calling
dma_free_coherent() with a NULL ptr (probe failure before DMA alloc
succeeded).

- [High] The command-receiver rx_msg_sz update is now done under
cmd_receiver_clbk_hdl.clbk_rx_lock. The read path also validates
cmd_receiver_clbk_hdl.dev_ctx, rx_msg, and rx_msg_sz under the same callback
lock before consuming the message.

- [High] se_ctrl.c: se_if_probe_cleanup(): call se_clear_fw_busy() before
cancel_work_sync(). A late mailbox interrupt arriving between the two
calls would see fw_busy still set and schedule work on the already-
cancelled fw_busy_work, causing a use-after-free.

- [Medium] se_ctrl.c: cleanup_dev_ctx(): remove goto from inside a
scoped_guard() block. Use a local already_done flag instead to keep the
cleanup path flat and avoid confusing ownership semantics.

- [Misc] se_ctrl.c: se_ctrl.h: add SE_MU_HDR_WORD_SZ = 1 constant.
Make se_is_fw_busy_ctx(), se_dev_ctx_shared_mem_cleanup() and
get_shared_mem_slot() non-static so they can be called from ele_common.c
and future callers.

4/7: Fix init_misc_device_context() to return 0 on the success path.

- The helper initialized ret to -ENOMEM and returned ret even after
successfully allocating and initializing priv_dev_ctx. This caused
se_if_probe() to treat a successful init_misc_device_context() call as a
failure and abort probe. Return 0 after assigning *new_dev_ctx.

- Avoid a possible NULL pointer dereference in se_if_rx_callback() after
waking the synchronous response waiter. The response callback used
se_clbk_hdl->dev_ctx->devname after calling complete() and dropping
clbk_rx_lock. The awakened ele_msg_send_rcv() cleanup path can clear
waiting_rsp_clbk_hdl.dev_ctx under the same lock before the size-mismatch
dev_err() is emitted. Snapshot devname while clbk_rx_lock is still held and
use the local copy after dropping the lock.

3/7: Fix several issues reported by Sashiko in the ELE driver:

- Add cleanup helper for ele_get_info() and remove the goto-based cleanup path
  that mixed manual cleanup with scoped __free(kfree) objects.

- Document the mailbox TX buffer lifetime assumption in ele_msg_send().
  The i.MX MU mailbox controller copies message payload words into MU
  registers synchronously and does not retain the caller-provided tx_msg
  pointer after mbox_send_message() returns.

- Replace se_get_msg_chksum() with se_update_msg_chksum(), which validates
  the message pointer and size, calculates the checksum, and updates the
  checksum word directly.

- Remove the stale ret check after se_fill_cmd_msg_hdr(), since
  se_fill_cmd_msg_hdr() now returns void.

- Validate the encrypted IMEM export size returned by firmware against
  ELE_IMEM_SIZE before storing it in imem->size for later resume-time import.

- Add a mutex to serialize population of common SoC-level information stored
  in var_se_info.

- Add NULL checks for devm_kasprintf() results before passing revision and
  serial-number strings to soc_device_register().

- Set a 32-bit DMA/coherent mask to make the ELE 32-bit firmware address
  constraint explicit, while still relying on the reserved memory region for
  ELE-accessible DMA memory.

- Keep mutable firmware-load and IMEM state per device in struct se_if_priv,
  while var_se_info only caches immutable SoC-level revision data.

- Keep the SoC device unregister devres action and devm-managed IMEM coherent
  memory handling from v27.

Reference:
- Link to v27: https://lore.kernel.org/r/20260715-imx-se-if-v27-0-bb7c45952f06@nxp.com

Changes in v27:

Address Sashiko findings around:
Changes in v27:

Address Sashiko findings around:
- Encrypted IMEM DMA address handling, response waiter cleanup,
  service-swap address validation, SoC device unregister,
  devm-managed IMEM cleanup, timeout classification, signal
  handling, firmware-load serialization, UAPI compatibility, and
  timed-out firmware transaction cleanup.

- Use dma_addr_t for ELE firmware authentication and IMEM service-swap
  buffers, store the encrypted IMEM DMA handle in the IMEM state, and pass
  imem->daddr to IMEM save/restore.

- Reject ELE service-swap addresses whose upper 32 bits are set before
  placing the address into the 32-bit firmware message field.

- Clear waiting_rsp_clbk_hdl state under clbk_rx_lock on all send/receive
  exit paths, including ele_msg_send() failure.

- Keep mailbox TX completion handled by the mailbox controller/core with
  knows_txdone set to false. The i.MX MU controller copies the message
  payload into hardware registers synchronously.

- Move mutable firmware-load and IMEM state to per-device storage in
  struct se_if_priv.

- Register a devres cleanup action to unregister the SoC device returned by
  soc_device_register().

- Remove manual freeing of the devm-managed encrypted IMEM coherent buffer
  from probe cleanup.

- Fix response-wait timeout classification by basing timeout handling on
  the callback handle being waited on, not on command-receiver file context
  identity.

- Use fixed-width UAPI fields and u64_to_user_ptr() to support 32-bit
  userspace compatibility.

- Add compat_ioctl support for the misc-device UAPI.

- Bound userspace-provided message sizes before memdup_user().

- Track timed-out firmware transactions with the corresponding dev_ctx so
  coherent DMA memory is not freed while firmware may still access it.

- Serialize firmware loading state with load_fw_lock to avoid concurrent
  firmware authentication requests.

- Fix get_se_soc_id() to use the correct match-data type.

- Fix command-receiver lifecycle handling by clearing command-receiver
  callback state under clbk_rx_lock and freeing rx_msg only after dropping
  the lock.

- Avoid unbind/remove deadlock by not holding dev_ctx->fops_lock across the
  blocking command-receiver read wait.

- Initialize dev_ctx reference counting with kref_init().

- Add ELE FW API command filtering through ele_uapi_allowed_fw_cmd().

- Move FW API command IDs and FW API-specific state transitions into
  ele_fw_api.c/ele_fw_api.h.

- Allow command-receiver registration/unregistration through the supported
  storage open/close FW API flow.

- Refactor shared-memory slot allocation and rollback in
  se_ioctl_setup_iobuf_handler().

- Fix hsm0 device tree indentation reported by Sashiko.

- Address Lothar Waßmann's review comments:
  - make se_fill_cmd_msg_hdr() return void and remove dead error checks;
  - remove the trailing comma after the final empty of_device_id sentinel.

- Validate the series with checkpatch, sparse, W=1/W=2 builds, coccicheck,
  dt_binding_check for fsl,imx-se.yaml, CHECK_DTBS=y for imx8ulp-evk.dtb,
  and headers_install for include/uapi/linux/se_ioctl.h.

Reference:
- Link to v26: https://lore.kernel.org/r/20260629-imx-se-if-v26-0-146446285744@nxp.com

Changes in v26:
- Folded kernel test robot and Sashiko-bot fixes into the series.
- Added MAILBOX dependency for COMPILE_TEST builds.
- Hardened response waiter timeout handling and late-response processing.
- Serialized command receiver registration and callback-visible receiver state.
- Added iobuf round_up() overflow detection.
- Rolled back iobuf shared-memory reservation on setup failures.
- Bounded userspace-controlled response buffer size.
- Preserved ioctl operation errors across cleanup.
- Added explicit priv/dev_ctx lifetime handling and teardown/open serialization.

Testing:
- checkpatch.pl --strict: no warnings
- sparse: no warnings
- coccicheck on drivers/firmware/imx/: no driver-specific warnings

Reference:
- Link to v25: https://lore.kernel.org/r/20260122-imx-se-if-v25-0-5c3e3e3b69a8@nxp.com

Changes in v25:
5/7
- removes kernel bot reported warning errors.

3/7
- fix checkpatch --strict error.

1/2, 2/7, 4/7, 6/7 & 7/7
- No changes

Reference:
- Link to v24: https://lore.kernel.org/r/20260121-imx-se-if-v24-0-c5222df51cc2@nxp.com

Changes in v24:
5/7 & 3/7
- removes kernel bot reported warning errors.

1/2, 2/7, 4/7, 6/7 & 7/7
- No changes

Reference:
- Link to v23: https://lore.kernel.org/r/20251219-imx-se-if-v23-0-5c6773d00318@nxp.com

Changes in v23:
5/7
- removed un-neccessary 'kfree' from the func se_ioctl_cmd_snd_rcv_rsp_handler().

1/2, 2/7, 3/7, 4/7, 6/7 & 7/7
- No changes

Reference:
- Link to v22: https://lore.kernel.org/r/20251218-imx-se-if-v22-0-07418c872509@nxp.com

Changes in v22:
3/7 & 5/7
- reverted to previous change of using "__free(kfree)", by declare-and-initialize __free() vars next to their allocations.

1/7
- rename the se_fw.c to se_ctrl.c

2/7, 4/7, 5/7 & 7/7
- No changes.

Reference:
- Link to v21: https://lore.kernel.org/r/20251212-imx-se-if-v21-0-ee7d6052d848@nxp.com

Changes in v21:
3/7
- smatch warning fixes.
- Added "COMPILE_TEST" into "depends on IMX_MBOX && ARCH_MXC && ARM64"
- removed "__free(kfree)" & added kfree();

5/7
- removed "__free(kfree)" & added kfree();

1/2, 2/7, 4/7, & 7/7
- No changes

Reference:
- Link to v20: https://lore.kernel.org/r/20251203-imx-se-if-v20-0-a04a25c4255f@nxp.com

Changes in v20:
5/7:
- adds a func "se_chk_tx_msg_hdr", to check the validity of the in-coming message from usersapce.

1/2, 2/7, 3/7, 4/7, 6/7 & 7/7
- No changes

Reference:
- Link to v19: https://lore.kernel.org/r/20250927-imx-se-if-v19-0-d1e7e960c118@nxp.com

Changes in v19:

1/7
- Added 9 lines to the Introduction from line 73-82.

3/7
-  Update the commit message for " For i.MX9x SoC(s) there is at least one
dedicated ELE MU(s) for each world - Linux(one or more) and OP-TEE OS (one or
more), that needs to be shared between them.."

Reference:
- Link to v18: https://lore.kernel.org/r/20250619-imx-se-if-v18-0-c98391ba446d@nxp.com

Changes in v18:

1/7
- Wrap both diagrams above in literal code block by using double-colon

3/7 & 5/7
- Collected Frank's R-b tag.

2/7, 4/7, 6/7 & 7/7
- No changes

Reference:
- Link to v17: https://lore.kernel.org/r/20250426-imx-se-if-v17-0-0c85155a50d1@nxp.com

Changes in v17:
- Changes to 3/7 & 5/7: to wrap code text at 80 character whereever possible.

Reference:
- Link to v16: https://lore.kernel.org/r/20250409-imx-se-if-v16-0-5394e5f3417e@nxp.com

Changes in v16:
- commit 3/7 and 4/7 are moved to end commits making them as 6/7 and 7/7 respectively.
- No change in 1/7 & 2/7.

7/7
- Collected Frank's R-b tag.

6/7
- commit message is updated to wrap at 75 characters.

5/7
- func add_b_desc_to_pending_list, removed the initialization of b_desc to
  NULL.
- variable timeout in func ele_msg_rcv(), is renamed to timeout_ms.
- struct se_if_priv, member variable se_rcv_msg_timeout, is renamed to
  se_rcv_msg_timeout_ms.
- in func load_firmware, move the label exit after dma_free_coherent.

4/7
- commit message is updated to wrap at 75 characters.

3/7
- ele_debug_dump, updated the assignment of keep_logging.
- ele_fw_authenticate function definition is updated to take two address
  as arguments.

Reference:
- Link to v15: https://lore.kernel.org/r/20250407-imx-se-if-v15-0-e3382cecda01@nxp.com

Changes in v15:
- Patch 3/6 is split into two:
  - 3/7: arm64: dts: imx8ulp-evk: add reserved memory property
  - 4/7: arm64: dts: imx8ulp: add nxp secure enclave firmware
- No change in 1/7 & 2/7.

7/7
- removed the se_intance_id structure member variable.
- replace variable name from wait to timeout.
- used 'goto' to follow the common exit path calling "release_firmware(fw);" in case of error path.
- removed TBD string.
- Used ARRAY_SIZE(pending_lists).
- moved init_device_context after init_misc_device_context.
- defined err as long to avoid force convert in func
- added se_rcv_msg_timeout to priv, to control probe/suspend/resume per interface.

6/7
- removed the se_intance_id structure member variable.
- Added dev_ctx to the structure se_clbk_handle, too.
- Collected Frank's R-b tag.

5/7
- removed the se_intance_id structure member variable.
- since added se_if_probe_cleanup to devm, se_if_remove() is redundant. hence removed it.
- rename se_add_msg_chksum to se_get_msg_chksum
- added check if msg-size is 4 byte aligned.
- Fixed multiline comments.
- ele_debug_dump api is updated as part of comment disposition like single setting of flag "keep_logging" & adding if (ret).
- moved dev_err to dev_dbg, for imem save/restore functions.
- moved func get_se_if_name, from 7/7 to here.

3/7
- Updated the commit message.
- split the current patch into two:
  -- 3/7 for board dts, and
  -- 4/7 for chip dts

Reference:
- Link to v14: https://lore.kernel.org/r/20250327-imx-se-if-v14-0-2219448932e4@nxp.com

Changes in v14:

- Patch 5/5 is split into two:
  - firmware: drivers: imx: adds miscdev
  - Introduce dev-ctx dedicated to private.
    -- Base patch before enabling misc-device context, to have the send-receive path, based on device context.
- No change in 1/6 & 2/6.
- Copied change logs from individual commits.

6/6
- moved definition of func se_load_firmware, from 4/6 patch to this patch.
- split init_device_context to init_misc_device_context.
- Different value of se_rcv_msg_timeout is required to be set. Receiving the response of 4K RSA operation can to take upto 3 minutes.
  This long value cannot be set during Linux: boot-up and suspend-resume.
  Hence, it will be set to default small-value during Linux: boot-up and suspend-resume.
- func se_dev_ctx_cpy_out_data(), in either case: do_cpy true or false, the clean-up needs to be done and it is implemented like wise.
  Once do_cpy is false, no need to continue copy to user buffer. But continue to do clean-up. hence cannot return.
  And every dev-ctx operation is done after taking the lock. Hence, two operations with same dev-ctx is not possible in parallel.
- func "init_device_context", for 0th misc dev_ctx, which is created at the time of probe, the device memory management is required. hence there is a difference.
- func "init_device_context", dev_er is replaced with return dev_err_probe.
- func "init_device_context", devm_add_action is replaced by devm_add_action_reset.
- removed type-cast from func se_ioctl_get_se_soc_info_handler().
- used scoped_cond_guard(mutex, _intr, return -EBUSY, &<mutex_lock>)
- combined dev_err & dev_dbg to one dev_err in se_if_fops_read().
- removed the structure member "se_shared_mem_mgmt->secure_mem".

4/6
- trimmed the ele_fetch_soc_info.
- removed the function ptr "se_info->se_fetch_soc_info" and replaced with ele_fetch_soc_info.
- moved definition of func se_load_firmware, to 6/6 patch.
- Different SoC, different ways to fetch soc_info. Generic function declaration for ele_fetch_soc_info() is needed. Hence wrapping ele_get_info() in it.
- Updated Kconfig help text for assertive tone.
- func ele_debug_dump is updated, to remove constructing the format string.
- removed the macro usage for SOC_ID_MASK.
- used low case hex number.
- Condition will never occur, where msg_len satisfy the following condition "msg_len % 4 != 0". Err msg is added if it occurs.
- Function description is added to se_add_msg_crc.
- timeout is added to function ele_msg_rcv, in 5/5 patch.
- local variable "header" is initialized with "tx_msg" and replaced "return err" with "return tx_msg_sz" in func ele_msg_send().
- replace function name from "exception_for_size" to "check_hdr_exception_for_sz"
- replaced "return ret > 0 ? 0 : -1;" with "return ret > 0 ? 0 : ret;" in func "se_save_imem_state".
- func "se_restore_imem_state", to return if the condition is false to proceed.
- removed casting by (void *).
- removed devm_kasprintf and done direct allocatiion for attr->soc_id = "i.MX8ULP" & attr->soc_id = "i.MX8ULP", & attr->family.
- Followed Reverse christmas tree order, whereever missing.
- There is no return if ele_fw_authenticate fails. Execution flow continue forward and execute the fucn dma_free_coherent().
- The loop is not for retry. The loop is needed to load secondary fw followed by loading primary fw, first. This is the case when ELE also got reset.
- dev_err_probe is corrected in func "se_if_request_channel".

3/6
-

Reference:
- Link to v13: https://lore.kernel.org/r/20250311-imx-se-if-v13-0-9cc6d8fd6d1c@nxp.com

Changes in v13:

5/5
- Updated the commit message for imperative mood.
- Remove the usage of macros- NODE_NAME, GET_ASCII_TO_U8, GET_IDX_FROM_DEV_NODE_NAME.
- Clean-up the return path by replacing "ret = -<err>; return ret;" with "return -<err>;"
- Clean-up the return path by replacing "ret = -<err>; goto exit;" with "return -<err>;"
- Removed goto statements from the entire driver, where there is no common code at function's exit.
- Fixes the check-patch erros reported with flag "--strict"
- Replaced devm_add_action, with devm_add_action_or_reset
- Removed the un-necesary and obvious code comments.
- Removed dev_probe_err at the exit of function se_if_probe().

4/5
- Clean-up the return path by replacing "ret = -<err>; return ret;" with "return -<err>;"
- Clean-up the return path by replacing "ret = -<err>; goto exit;" with "return -<err>;"
- Removed goto statements from the entire driver, where there is no common code at function's exit.
- fixes the check-patch erros reported with flag "--strict"
- removed the un-necesary and obvious code comments.
- variable received msg timeout to be different at boot-up & suspend/resume and send/recv ioctlis.

3/5
- compatible string is modified from "fsl,imx8ulp-se" to "fsl,imx8ulp-se-ele-hsm".
- updated the alias name.

2/5
- compatible string is modified from "fsl,imx8ulp-se" to "fsl,imx8ulp-se-ele-hsm".
- compatible string is modified from "fsl,imx93-se" to "fsl,imx93-se-ele-hsm".
- compatible string is modified from "fsl,imx95-se" to "fsl,imx95-se-ele-hsm".
- Mis-understood the +1 from Conor. Hence dropped the Reviewed-by tag.
- Collected Rob's R-b tag on v7 (https://lore.kernel.org/all/172589152997.4184616.5889493628960272898.robh@kernel.org/)

1/5
- No change

Reference:
- Link to v12: https://lore.kernel.org/r/20250120-imx-se-if-v12-0-c5ec9754570c@nxp.com

Changes in v12:

5/5
- increased the wait-timeout.

4/5
- rename flag "handle_susp_resm" to "imem_mgmt"
- moved the buffer allocation ot load_fw->imem.buf, to se_probe_if.
- setting imem state at initialization.

3/5
- No change

2/5
- No change

1/5
- No change

Reference:
- Link to v11: https://lore.kernel.org/r/20241220-imx-se-if-v11-0-0c7e65d7ae7b@nxp.com

Changes in v11:

5/5
- devname is constructed by concatinating get_se_if_name(se_if_id) & se_if_instance_id.
- ele_rcv_msg(), is updated to add the wait_interruptible_timeout for the non-NVM-Daemon message exchanges, such that in case of no response from FW,
  Linux donot hangs.
- added a new helper function get_se_if_name(), to return the secure-enclave interface owner's name string.
- added a new helper function get_se_soc_id(), to return the secure-enclave's SoC id.

4/5
- moved the se_if_node_info member "soc_register", to the struct "se_if_node_info_list"; as soc registration done once, not per interface.
- moved the se_if_node_info member "se_fetch_soc_info", to the struct "se_if_node_info_list"; as soc info fetching is done once, not per interface.
- Added two member variable se_if_id and se_if_instance_id to struct se_if_defines.
- removed the member "se_name" from struct "se_if_node_info". Rather, it will constructed by concatinating get_se_if_name(se_if_id) & se_if_instance_id.
- moved the static global variable "se_version", to the newly created structure "struct se_var_info".
- moved the member "struct se_fw_load_info load_fw" of "se_if_node_info_list", to the newly created structure "struct se_var_info".
- Replaced RUNTIME_PM_OPS with SET_SYSTEM_SLEEP_PM_OPS, in power-managment ops.

3/5
- No change

2/5
- No change

1/5
- No change

Reference:
- Link to v10: https://lore.kernel.org/r/20241104-imx-se-if-v10-0-bf06083cc97f@nxp.com

v10: firmware: imx: driver for NXP secure-enclave

Changes in v10:
5/5
- replaced the u8, u16, u32, u64, with __u8, __u16, __u32, __u64 in
  'include/uapi/linux/se_ioctl.h'.

4/5
- No change

3/5
- No change

2/5
- No change

1/5
- No change

Reference:
- Link to v9: https://lore.kernel.org/r/20241016-imx-se-if-v9-0-fd8fa0c04eab@nxp.com

Changes in v9:

4/5
- change se_if_remove function signature, required after rebase to v6.12-rc1.
- move the info->macros to a structure "struct se_if_defines if_defs".
- Removed "info" from "struct se_if_defines if_defs".
- Moved "mem_pool" from "struct se_if_defines if_defs" to "priv".
- Fetching "info" using container-of.

5/5
- Fetching "info" using container-of.
- Fixed issue reported by sparse.

Reference:
- Link to v8: https://lore.kernel.org/r/20241015-imx-se-if-v8-0-915438e267d3@nxp.com

Changes in v8:

5/5
- Remove the check for SE_IF_CTX_OPENED.
- replaced dev_ctx->priv-dev, priv->dev, whereever possible.
- func "if_misc_deregister" moved before func "init_device_context".
- func "init_device_context" before func "se_ioctl_cmd_snd_rcv_rsp_handler".
- func "se_if_fops_write" and "se_if_fops_read", are moved after func "se_ioctl_get_mu_info".
- non static functions "se_dev_ctx_cpy_out_data, se_dev_ctx_shared_mem_cleanup & init_device_context" are moved static and local scope.
- Removed back & forth between the two structs "struct se_if_device_ctx *dev_ctx" and "struct se_shared_mem_mgmt_info *se_shared_mem_mgmt"
- removed the NULL check for bdesc.
- fops_open, is corrected for acquiring the fops_lock.
- Fops_close, mutex unlock is removed. Infact check for waiting_rsp_clbk_hdl.dev_ctx, is removed.
- sema_init(&dev_ctx->fops_lock, 1);, replaced with Mutex.
- structure member se_notify, is removed.

4/5
- removed initializing err to zero in func ele_fetch_soc_info(),
- replaced 'return 0', with 'goto exit', if the condition (!priv->mem_pool) is true.
- replaced "struct *dev" with "struct se_if_priv *priv", in base_message API(s) and others.
- Created a separate structure "struct se_if_defines" to maintain interface's fixed values like cmd_tag, rsp_tag, success_tag etc.
- removed the macros "WORD_SZ", "SOC_VER_MASK", "DEFAULT_IMX_SOC_VER", "RESERVED_DMA_POOL".
- Added handling for "ctrl+c", by postponing the interrupt, till the response to the "command in flight" is received.
- Removed the mutext lock "se_if_lock".
- furnction prototype for "se_save_imem_state" and "se_restore_imem_state", is changed to pass "imem" by reference.
- Added a new structure "struct se_fw_load_info", dedicated to contain FW loading relevant info. It is a member of struct info_list.
- split "imem_mgmt_file_in_rfs" into two "prim_fw_nm_in_rfs" and "seco_fw_nm_in_rfs", to be part of "struct se_fw_load_info".
- moved the function "se_load_firmware" prior to func "if_mbox_free_channel".
- function "se_load_firmware" is updated to use "request_firmware", instead of "request_firmware_no_wait".
- function "se_load_firmware" is updated to load "primary" fw image, if the imem_state is not BAD. Then load the "secondary FW" image.
- Added a new mutex_lock in the function "se_load_firmware", for ensuring FW loading done once, when there are multiple application are in play.
- instead of "wait_queue_head_t wq", used "sruct completion".
- add devm_add_action with action as se_if_probe_cleanup.

Reference:
- Link to v7: https://lore.kernel.org/r/20240904-imx-se-if-v7-0-5afd2ab74264@nxp.com

Changes in v7:

5/5
- struct se_clbk_handle, is added with a member struct se_if_device_ctx *dev_ctx.
- func call to ele_miscdev_msg_rcv() & ele_miscdev_msg_send(), are removed.
- func se_ioctl_cmd_snd_rcv_rsp_handler(), is modified to remove the func call to ele_miscdev_msg_rcv() & ele_miscdev_msg_send()
- func se_ioctl_cmd_snd_rcv_rsp_handler is callig func ele_msg_send_rcv(), instead.
- Mutext "se_cmd_if_lock", handling is removed from this patch.
- func ele_miscdev_msg_send() is replaced with func ele_msg_send(), in fops_write.
- func ele_miscdev_msg_rcv() is replaced with func ele_msg_rcv(), in fops_read.
- fops_open is modified to create the new dev_ctx instance (using func init_device_context()), which is not registered as miscdev.
- Only one dev_ctx is registered as miscdev and its reference is stored in the struct se_if_priv, as priv_dev_ctx.
- Separate func cleanup_se_shared_mem() & func init_se_shared_mem(), for shared memory handling part of struct dev_ctx.
- Input param for func(s) ele_msg_rcv(), ele_msg_send() & ele_msg_send_rcv(), is replaced from struct se_if_priv to struct se_if_device_ctx.

4/5
- A new structure is defined name struct "se_clbk_handle", to contain members processed in mailbox call-back function.
- "struct se_if_priv" is modified to contain the two structures of "se_clbk_handle" - waiting_rsp_clbk_hdl & cmd_receiver_clbk_hdl.
- func ele_msg_rcv() is modified to take a new additional input reference param "struct se_clbk_handle *se_clbk_hdl".
- func ele_msg_send() is modified to take a new additional input tx_msg_sz.
- func ele_msg_send_rcv(), is modified to take 2 more inputs - tx_msg_sz & exp_rx_msg_sz.
- func se_val_rsp_hdr_n_status(), is modified to take input of rx_msg buffer, instead of header value, as input param.
- each caller of the func ele_msg_send_rcv(), is sending these two additional input params.
- func se_if_callback(), is modified to work on two structures of "se_clbk_handle" - waiting_rsp_clbk_hdl & cmd_receiver_clbk_hdl.
- Variable "max_dev_ctx", is removed from info & priv struture, as well its usage.
- New member variable "se_img_file_to_load", is added to structure "priv".
- Other member variables - rx_msg(ptr), rx_msg_sz, completion done & list of dev_ctxs, is removed from priv struture, along with their usage.
- func se_resume(), updated to wakeup the two "wq", part of "struct se_clbk_handle": priv->waiting_rsp_clbk_hdl & priv->cmd_receiver_clbk_hdl.

3/5
- Node name is changed from senclave-firmware@0 to "secure-enclave"

2/5
- Node name is changed to "secure-enclave".

Reference:
- Link to v6: https://lore.kernel.org/r/20240722-imx-se-if-v6-0-ee26a87b824a@nxp.com

Changes in v6:

5/5
- replaced scope_gaurd with gaurd.

4/5
- replaced scope_gaurd with gaurd.
- remove reading the regs property from dtb.
- Added NULL check for priv data fetched from device, as a sanity check, for ele_base_msg apis)

3/5
- replace firmware with senclave-firmware.

2/5
- replace firmware with senclave-firmware.
- drop description for mbox
- Replaced "items:" with maxItems:1 for "memory-region"
- Replaced "items:" with maxItems:1 for "sram"
- remove regs property.
- remove "$nodename"

Reference:
- Link to v5: https://lore.kernel.org/r/20240712-imx-se-if-v5-0-66a79903a872@nxp.com

Changes in v5:

2/5
- updated the description of mboxes
- updated the description & items for mbox-names.
- updated the description of memory-region
- move "additional properties: false" after allOf block.
- removed other example except one.

4/5
- Corrected the indentation in Kconfig.
- info members:mbox_tx_name & mbox_rx_name, are replaced with macros.

5/5
- Replaced "for  secure enclaves", with "for secure enclaves"
- Replaced "user space" with "userspace".
- End the line "[include]<linux/firmware/imx/ele_mu_ioctl.h>" with a period.

Reference:
- Link to v4: https://lore.kernel.org/r/20240705-imx-se-if-v4-0-52d000e18a1d@nxp.com

Changes in v4:

1/5
a. Removed - from EdgeLock Enclave.

b. Removed , after "Each of the above feature,"

c. replace "can exists" with "can exist".

d.
-messaging units(MU) per SE. Each co-existing 'se' can have one or multiple exclusive
-MU(s), dedicated to itself. None of the MU is shared between two SEs.
+messaging units(MU) per SE. Each co-existing SE can have one or multiple exclusive
+MUs, dedicated to itself. None of the MU is shared between two SEs.
 Communication of the MU is realized using the Linux mailbox driver.

e.
-All those SE interfaces 'se-if' that is/are dedicated to a particular SE, will be
-enumerated and provisioned under the very single 'SE' node.
+Although MU(s) is/are not shared between SE(s). But for SoC like i.MX95 which has
+multiple SE(s) like HSM, V2X-HSM, V2X-SHE; all the SE(s) and their interfaces 'se-if'
+that is/are dedicated to a particular SE will be enumerated and provisioned using the
+single compatible node("fsl,imx95-se").

f. Removed ",". Replaced for "Each 'se-if'," with "Each se-if'.

g. removed ","
-  This layer is responsible for ensuring the communication protocol, that is defined
+  This layer is responsible for ensuring the communication protocol that is defined

h. removed "-"
-  - FW can handle one command-message at a time.
+  - FW can handle one command message at a time.

i.
-  Using these multiple device contexts, that are getting multiplexed over a single MU,
-  user-space application(s) can call fops like write/read to send the command-message,
-  and read back the command-response-message to/from Firmware.
-  fops like read & write uses the above defined service layer API(s) to communicate with
+  Using these multiple device contexts that are getting multiplexed over a single MU,
+  userspace application(s) can call fops like write/read to send the command message,
+  and read back the command response message to/from Firmware.
+  fops like read & write use the above defined service layer API(s) to communicate with
   Firmware.

j. Uppercase for word "Linux".

2/5
a. Rephrased the description to remove list of phandles.

b. Moved required before allOf:
+required:
+  - compatible
+  - reg
+  - mboxes
+  - mbox-names
+
+additionalProperties: false
+
 allOf:

c. replaced not: required: with properties: <property-name>: false.
   # memory-region
-      not:
-        required:
-          - memory-region
+      properties:
+        memory-region: false

   # sram
-    else:
-      not:
-        required:
-          - sram

d. Reduced examples. keeping example of i.MX95.
e. node-name is changed to "firmware@<hex>"

3/5
- node name changed to "firmware@<hex>".

4/5
- used sizeof(*s_info)
- return early, rather than doing goto exit, in ele_get_info().
- Use upper_32_bits() and lower_32_bits()
- use rx_msg here instead of priv->rx_msg
- Moved the status check to validate_rsp_hdr. Rename the function to "se_val_rsp_hdr_n_status"
- typecasting removed header = (struct se_msg_hdr *) msg;
- Converted the API name with prefix imx_ele_* or imx_se_*, to ele_* and se_*, respectively.
- Removed the functions definition & declaration for: free_phybuf_mem_pool() & get_phybuf_mem_pool()
- removed the mbox_free_channel() calls from clean-up.
- Flag "priv->flags" is removed.
- Converted the int se_if_probe_cleanup() to void se_if_probe_cleanup().
- Replaced NULL initialization of structure members: priv->cmd_receiver_dev & priv->waiting_rsp_dev , with comments.
- Removed the function's declaration get_phy_buf_mem_pool1

5/5
Changes to Documentation/ABI/testing/se-cdev.
a. Removed "-" from "secure-enclave" and "file-descriptor".

b. Removed "-" from "shared-library"

c. Replaced "get" with "getting".

d. Added description for the new IOCTL "send command and receive command response"

e. Replaced "wakeup_intruptible" with "wait_event_interruptible"

f. Removed ";"

g. Removd "," from "mailbox_lock,"

h. Replaced "free" with "frees"

i. In mailbox callback function, checking the buffer size before
copying.

Reference:
- Link to v3: https://lore.kernel.org/r/20240617-imx-se-if-v3-0-a7d28dea5c4a@nxp.com

Changes in v3:
5/5:
- Initialize tx_msg with NULL.
- memdup_user() returns an error pointer, not NULL. correct it by adding check for err_ptr.
- new IOCTL is added to send & recieve the message.
- replaced the while loop till list is empty, with list_for_each_entry.
- replaced __list_del_entry, with list_del.
- Removed the dev_err message from copy to user.
- Removed the casting of void *.
- corrected the typcasting in copy to user.
- removed un-necessary goto statement.
- Removed dead code for clean-up of memory.
- Removed un-mapping of secured memory
- Passing se_if_priv structure to init_device_context.
- Updated the below check to replace io.length with round_up(io.length).
	if (shared_mem->size < shared_mem->pos|| io.length >= shared_mem->size - shared_mem->pos)
- Created a function to cleanup the list of shared memory buffers.
- Used list_for_each_entry_safe(). created a separate functions: se_dev_ctx_cpy_out_data() & se_dev_ctx_shared_mem_cleanup()

4/5
- Changed the compatible string to replace "-ele", to "-se".
- Declaration of imx_se_node_info, is done as const in the whole file
- Remove the unused macros from ele_base_msg.h
- Remove the function declaration get_phy_buf_mem_pool1, from the header file.
- Replace the use of dmam_alloc_coherent to dma_alloc_coherent
- Check for function pointer, before calling the fucntion pointer in imx_fetch_se_soc_info
- Removed the unused flag for SE_MU_IO_FLAGS_USE_SEC_MEM.
-  Removed the unused macros WORD_SZ
- instead of struct device *dev, struct se_if_priv *priv, is used as argument to the funtions:se_save_imem_state, se_restore_imem_state, imx_fetch_se_soc_info
- Removed ret from validate_rsp_hdr.
- changed the prefix of the funtion: plat_add_msg_crc and plat_fill_cmd_msg_hdr.
- indentation correction for info structures.
- remove the check for priv not null from se_if_probe_cleanup
- Removed the casting of void *.
- se_load_firmware function is corrected for not freeing the buffer when allocation fails.
- Checking if get_imx_se_node_info() can return NULL, in se_if_probe()
- imem.size has type u32. return value from se_save_imem_state() will be assigned to imem.size in case of success only.
- removed the flag un-setting in case of failure. priv->flags &= (~RESERVED_DMA_POOL);
- removed the function call for devm_of_platform_populate(dev);
- Checking for not-NULL,  before calling the funtion pointer se_fetch_soc_info.
- Removed the checking for reserved memory flag, before freeing up the reserved memory, in se_probe_if_cleanup.

3/5
- Changed the compatible string to replace "-ele", to "-se".

2/5
- to fix the warning error, replaced the "-ele" & "-v2x" in compatible string, to "-se".
- Added an example for ele@0 for compatible string "fsl,imx95-se"

Reference
- Link to v2: https://lore.kernel.org/r/20240523-imx-se-if-v2-0-5a6fd189a539@nxp.com

Changes in v2:

4/4
- Split this patch into two: 1. base driver & 2. Miscdev
- Initialize the return variable "err" as 0, before calling 'return err', in the file ele_common.c
- Fix the usage of un-iniitialized pointer variable, by initializing them with NULL, in ele_base_msg.c.
- Fix initializing the ret variable, to return the correct error code in case of issue.
- replaced dmam_alloc_coherent with dma_alloc_coherent.
- Replace the use of ELE_GET_INFO_READ_SZ, with sizeof(soc_info).
- Replaced -1 with -EPERM
- Removed the safety check on func-input param, in ele_get_info().
- fix the assigning data[1] with lower 32 address, rather than zero, for ele_fw_authenticate API.
- Correctly initializing the function's return error code, for file  ele_base_msg.c.
- replaced 'return' with 'goto'.
- Use length in bytes.
- Corrected the structure se_msg_hdr.
- Moved setting of rx_msg  to priv, into the function imx_ele_msg_send_rcv
- Will add lockdep_assert_held, to receive path, in v2.
- corrected the spacing at "ret  = validate_rsp_hdr"
- FIELD_GET() used for RES_STATUS
- Re-write the structure soc_info, matching the information provided in response to this api.
- The "|" goes to the end of the previous line.
- Moved the locking and unlocking of the command lock to the caller of the function.
- removed the safety check for device private data.
- Structure memory reference, used to read message header.
- In the interrupt call back function, remove assigning waiting_rsp_dev to NULL, in case of response message rcv from FW.
- do while removed.
- replaced BIT(1) for RESERVED_DMA_POOL, to BIT(0)
- The backslash is removed while assigning the file name with absolute path to structure variable.fw_name_in_rfs =.
- Update the 'if' condition by removing "idx < 0".
- mbox_request_channel_byname() uses a "char" for the name not a u8. Corrected.
- devm managed resources, are not cleaned now, in function se_probe_if_cleanup
- Used dev_err_probe().
- Used %pe to print error string.
- remove "__maybe_unused" for "struct platform_device *enum_plat_dev __maybe_unused;"
- used FIELD_GET(), for  RES_STATUS. Removed the use of MSG_TAG, MSG_COMMAND, MSG_SIZE, MSG_VER.
- Depricated the used of member of struct se_if_priv, bool no_dev_ctx_used;
- Moved the text explaing the synchronization logic via mutexes, from patch 1/4 to se_ctrl.h.
- removed the type casting of info_list = (struct imx_se_node_info_list *) device_get_match_data(dev->parent);
- Used static variable priv->soc_rev in the se_ctrl.c, replaced the following condition: if (info_list->soc_rev) to if (priv->soc_rev) for checking if this flow is already executed or not.
- imx_fetch_soc_info will return failure if the get_info function fails.
- Removed devm_free from imx_fetch_soc_info too.

3/3
- Made changes to move all the properties to parent node, without any child node.

2/4
- Use Hex pattern string.
- Move the properties to parent node, with no child node.
- Add i.MX95-ele to compatible nodes to fix the warning "/example-2/v2x: failed to match any schema with compatible: ['fsl,imx95-v2x']"

1/1
- Corrected the spelling from creats to creates.
- drop the braces around the plural 's' for interfaces
- written se in upper case SE.
- Replace "multiple message(s)" with messages.
- Removed too much details about locks.

Testing
- make CHECK_DTBS=y freescale/imx8ulp-evk.dtb;
- make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j8  dt_binding_check DT_SCHEMA_FILES=fsl,imx-se.yaml
- make C=1 CHECK=scripts/coccicheck drivers/firmware/imx/*.* W=1 > r.txt
- ./scripts/checkpatch.pl --git <>..HEAD
- Tested the Image and .dtb, on the i.MX8ULP.

Reference
- Link to v1: https://lore.kernel.org/r/20240510-imx-se-if-v1-0-27c5a674916d@nxp.com

---
Pankaj Gupta (7):
      Documentation/firmware: add imx/se to other_interfaces
      dt-bindings: arm: fsl: add imx-se-fw binding doc
      firmware: imx: add driver for NXP EdgeLock Enclave
      firmware: imx: device context dedicated to priv
      firmware: imx: adds miscdev
      arm64: dts: imx8ulp: add secure enclave node
      arm64: dts: imx8ulp: add reserved memory for EdgeLock Enclave

 Documentation/ABI/testing/se-cdev                  |   44 +
 .../devicetree/bindings/firmware/fsl,imx-se.yaml   |   91 +
 .../driver-api/firmware/other_interfaces.rst       |  133 ++
 arch/arm64/boot/dts/freescale/imx8ulp-evk.dts      |    3 +-
 .../arm64/boot/dts/freescale/imx8ulp-firmware.dtsi |   31 +
 arch/arm64/boot/dts/freescale/imx8ulp.dtsi         |   12 +-
 drivers/firmware/imx/Kconfig                       |   12 +
 drivers/firmware/imx/Makefile                      |    2 +
 drivers/firmware/imx/ele_base_msg.c                |  337 +++
 drivers/firmware/imx/ele_base_msg.h                |  119 ++
 drivers/firmware/imx/ele_common.c                  |  813 ++++++++
 drivers/firmware/imx/ele_common.h                  |  122 ++
 drivers/firmware/imx/ele_fw_api.c                  |  361 ++++
 drivers/firmware/imx/ele_fw_api.h                  |  100 +
 drivers/firmware/imx/ele_msg_addr_field.c          |  654 ++++++
 drivers/firmware/imx/se_ctrl.c                     | 2186 ++++++++++++++++++++
 drivers/firmware/imx/se_ctrl.h                     |  211 ++
 include/linux/firmware/imx/se_api.h                |   14 +
 include/uapi/linux/se_ioctl.h                      |   97 +
 19 files changed, 5339 insertions(+), 3 deletions(-)
---
base-commit: 112b9e6bafec7b139c99cc0255f21ce73c115cc2
change-id: 20240507-imx-se-if-a40055093dc6

Best regards,
-- 
Pankaj Gupta <pankaj.gupta@nxp.com>

