From: Alex Ousherovitch <aousherovitch@rambus.com>
Date: Tue, 10 Nov 2026 08:52:28 -0800
Subject: [PATCH v8 2/5] crypto: cmh - add core platform driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-cmh-b4-a-v8-v8-2-4cea8ebc1d40@rambus.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794329557; l=299925;
 i=aousherovitch@rambus.com; s=20261026; h=from:subject:message-id;
 bh=rRri6SPqWhHPMqYoT2vXcxdMuEWlc95/pzt9VJvCLzw=;
 b=XoIiIXXdkTAIHHFVJJ9EIYg7z+SGEep1NDX/QXDoeYRYTFk+EGqsf+6J6znY452R63k6aTWIa
 UEflvNPF+GpBG9r0E83OckSZuEE0OHTuWQFwMQyXATd2jaNZGVxWnch
X-Developer-Key: i=aousherovitch@rambus.com; a=ed25519;
 pk=ECFtTdQUPAolK+qGZ6v7Xm3sRf7rnM7wxpTeFzbqpmA=
X-Endpoint-Received: by B4 Relay for aousherovitch@rambus.com/20261026 with auth_id=1330
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the core platform driver for the Rambus CryptoManager Hub (CMH).
The CMH embedded software (eSW) executes commands that the host posts,
as VCQs (Virtual Command Queues), to mailbox rings in DMA memory, and
signals completion through the mailbox interrupt.  This patch registers
no algorithms; those follow in later patches.

- Probe/remove: map the device, wait for the eSW, discover the enabled
  cores and set up the mailboxes described in the Device Tree.
- Transaction manager: a kthread that writes each request's VCQs into a
  mailbox ring and rings the doorbell, with a backlog for
  CRYPTO_TFM_REQ_MAY_BACKLOG requests.
- Response handler: completes requests from the threaded mailbox
  interrupt, with a watchdog for missed interrupts, and recovers a
  mailbox after an error with RESTART or FLUSH.
- DMA: memory the device may still write is freed only once the
  device is known to be done with it.
- sysfs attributes (fw_version, hw_version, boot_status, mbx_available,
  mbx_count).  With CONFIG_CRYPTO_DEV_CMH_DEBUG: debugfs counters and
  tunables, ABORT/drain fault injection, and bring-up module parameters
  that override the mailbox geometry or skip the eSW boot check.
- Documentation: the driver overview and the sysfs and debugfs ABI.

Co-developed-by: Saravanakrishnan Krishnamoorthy <skrishnamoorthy@rambus.com>
Signed-off-by: Saravanakrishnan Krishnamoorthy <skrishnamoorthy@rambus.com>
Signed-off-by: Alex Ousherovitch <aousherovitch@rambus.com>
---
 Documentation/ABI/testing/debugfs-driver-cmh  |  145 ++
 Documentation/ABI/testing/sysfs-driver-cmh    |   62 +
 Documentation/crypto/device_drivers/cmh.rst   |  282 +++
 Documentation/crypto/device_drivers/index.rst |    1 +
 drivers/crypto/Kconfig                        |    1 +
 drivers/crypto/Makefile                       |    1 +
 drivers/crypto/cmh/Kconfig                    |   37 +
 drivers/crypto/cmh/Makefile                   |   25 +
 drivers/crypto/cmh/cmh_config.c               |  625 ++++++
 drivers/crypto/cmh/cmh_debugfs.c              |  309 +++
 drivers/crypto/cmh/cmh_dma.c                  |  354 ++++
 drivers/crypto/cmh/cmh_main.c                 |  386 ++++
 drivers/crypto/cmh/cmh_mqi.c                  |  457 +++++
 drivers/crypto/cmh/cmh_rh.c                   | 1434 ++++++++++++++
 drivers/crypto/cmh/cmh_sysfs.c                |  108 ++
 drivers/crypto/cmh/cmh_txn.c                  | 2531 +++++++++++++++++++++++++
 drivers/crypto/cmh/include/cmh.h              |   24 +
 drivers/crypto/cmh/include/cmh_config.h       |  110 ++
 drivers/crypto/cmh/include/cmh_debugfs.h      |   94 +
 drivers/crypto/cmh/include/cmh_dma.h          |  195 ++
 drivers/crypto/cmh/include/cmh_mqi.h          |   59 +
 drivers/crypto/cmh/include/cmh_registers.h    |  147 ++
 drivers/crypto/cmh/include/cmh_rh.h           |   98 +
 drivers/crypto/cmh/include/cmh_sys_abi.h      |  148 ++
 drivers/crypto/cmh/include/cmh_sysfs.h        |   14 +
 drivers/crypto/cmh/include/cmh_txn.h          |  666 +++++++
 drivers/crypto/cmh/include/cmh_vcq.h          |  201 ++
 27 files changed, 8514 insertions(+)

diff --git a/Documentation/ABI/testing/debugfs-driver-cmh b/Documentation/ABI/testing/debugfs-driver-cmh
new file mode 100644
index 000000000000..02951136c1e8
--- /dev/null
+++ b/Documentation/ABI/testing/debugfs-driver-cmh
@@ -0,0 +1,145 @@
+What:		/sys/kernel/debug/cmh/mbx<N>/vcqs_submitted
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		(RO) Total number of VCQ command entries submitted to
+		mailbox N since the driver was loaded.
+
+What:		/sys/kernel/debug/cmh/mbx<N>/vcqs_completed
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		(RO) Total number of VCQ command completions received
+		from mailbox N.
+
+What:		/sys/kernel/debug/cmh/mbx<N>/vcqs_errors
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		(RO) Total number of error completions received from
+		mailbox N.
+
+What:		/sys/kernel/debug/cmh/mbx<N>/queue_full_count
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		(RO) Number of times the transaction manager skipped
+		mailbox N because its in-flight queue was full.
+
+What:		/sys/kernel/debug/cmh/mbx<N>/max_queue_depth
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		(RO) High-water mark of in-flight transactions on
+		mailbox N.
+
+What:		/sys/kernel/debug/cmh/mbx<N>/inject_abort
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		(WO) Write any value to inject an MBX_COMMAND_ABORT on
+		mailbox N.  The abort triggers error-IRQ handling: the
+		aborted transaction completes with -EIO and
+		MBX_COMMAND_RESTART resumes the mailbox, or, if that
+		transaction spans several VCQs, the mailbox is flushed and,
+		once the eSW acknowledges the FLUSH, the transactions queued
+		behind it complete with -ECANCELED.
+		Only available when CONFIG_CRYPTO_DEV_CMH_DEBUG is enabled.
+
+What:		/sys/kernel/debug/cmh/mbx<N>/force_drain
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		(WO) Write any value to FLUSH mailbox N as a last-resort
+		recovery, including of a retired (wedged) mailbox.  The
+		recovery state is reset, the mailbox is closed to new work
+		and MBX_COMMAND_FLUSH is issued.  When the eSW acknowledges
+		it (the write waits up to one second), every pending
+		transaction completes with -ECANCELED and the mailbox
+		reopens; otherwise the watchdog keeps waiting for the
+		acknowledgment and retires the mailbox again if it never
+		comes.
+		Only available when CONFIG_CRYPTO_DEV_CMH_DEBUG is enabled.
+
+What:		/sys/kernel/debug/cmh/tm/cmq_posts
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		(RO) Total number of cmh_tm_post_command() calls (one
+		per crypto request submitted to the transaction manager).
+
+What:		/sys/kernel/debug/cmh/tm/cmq_depth_max
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		(RO) High-water mark of the command queue length.
+
+What:		/sys/kernel/debug/cmh/tm/cmq_full_count
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		(RO) Number of times the command queue was full and
+		returned -ENOSPC to the caller.
+
+What:		/sys/kernel/debug/cmh/tm/backoff_count
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		(RO) Number of times the transaction manager backed off
+		because all mailbox queues were full.
+
+What:		/sys/kernel/debug/cmh/tm/async_timeout_count
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		(RO) Number of async crypto requests that timed out
+		waiting for hardware completion.
+
+What:		/sys/kernel/debug/cmh/config/async_timeout_ms
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		(RW) Async request timeout in milliseconds.  A request
+		that times out completes with -ETIMEDOUT once the device
+		has finished with it.  If it is at the head of its mailbox
+		and the device does not finish, the watchdog issues
+		MBX_COMMAND_ABORT and then FLUSH.
+
+What:		/sys/kernel/debug/cmh/config/vcq_timeout_ms
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		(RW) Timeout in milliseconds for synchronous commands.  On
+		expiry the driver issues MBX_COMMAND_ABORT if the command
+		is executing.
+
+What:		/sys/kernel/debug/cmh/config/slow_op_timeout_ms
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		(RW) Slow-operation timeout in milliseconds.  Used for
+		operations known to take longer, such as key generation.
+
+What:		/sys/kernel/debug/cmh/config/drain_timeout_ms
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		(RW) Drain timeout in milliseconds.  Maximum time suspend
+		waits for the transactions already on the device to
+		complete; if any is still running, the suspend is refused
+		with -EBUSY.
+
+What:		/sys/kernel/debug/cmh/config/watchdog_ms
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		(RW) Result-handler watchdog interval in milliseconds.
+		Detects missed IRQs, stuck mailboxes, and abort-stall
+		conditions.  Clamped to a 10 ms minimum.
+
+What:		/sys/kernel/debug/cmh/config/cmq_max_depth
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		(RW) Maximum number of pending commands in the central
+		Command Message Queue.
diff --git a/Documentation/ABI/testing/sysfs-driver-cmh b/Documentation/ABI/testing/sysfs-driver-cmh
new file mode 100644
index 000000000000..adcfcc4ae36c
--- /dev/null
+++ b/Documentation/ABI/testing/sysfs-driver-cmh
@@ -0,0 +1,62 @@
+What:		/sys/devices/platform/<dev>/fw_version
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		Reports the CryptoManager Hub embedded software (eSW) firmware
+		version as a 32-bit hexadecimal value read from the SIC
+		SW_VERSION register.
+
+		Example: "0x00010002"
+
+		Read-only.
+
+What:		/sys/devices/platform/<dev>/hw_version
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		Reports the CryptoManager Hub hardware version as a 32-bit
+		hexadecimal value read from the SIC HW_VERSION0 register.
+
+		Example: "0x00000000"
+
+		Read-only.
+
+What:		/sys/devices/platform/<dev>/boot_status
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		Reports the CryptoManager Hub boot status register as a 32-bit
+		hexadecimal value.  This reflects the firmware boot
+		progress and final state:
+
+		  0x00000066 - firmware booted (post-self-test)
+		  other      - firmware boot in progress or failed
+
+		Read-only.
+
+What:		/sys/devices/platform/<dev>/mbx_available
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		Reports the mailbox availability bitmap as a 32-bit
+		hexadecimal value read from the SIC MBX_AVAILABILITY
+		register.  Each set bit indicates a hardware mailbox
+		instance that the firmware has made available.
+
+		Example: "0x00000003" (mailboxes 0 and 1 available)
+
+		Read-only.
+
+What:		/sys/devices/platform/<dev>/mbx_count
+Date:		November 2026
+Contact:	linux-crypto@vger.kernel.org
+Description:
+		Reports the number of mailboxes the driver has configured,
+		as a decimal integer.  This reflects the driver's active
+		configuration (from DT properties, or a debug-only
+		override), which may be fewer than illustrated by
+		mbx_available.
+
+		Example: "2"
+
+		Read-only.
diff --git a/Documentation/crypto/device_drivers/cmh.rst b/Documentation/crypto/device_drivers/cmh.rst
new file mode 100644
index 000000000000..ddc44d235541
--- /dev/null
+++ b/Documentation/crypto/device_drivers/cmh.rst
@@ -0,0 +1,282 @@
+.. SPDX-License-Identifier: GPL-2.0
+
+=====================================
+Rambus CryptoManager Hub (CMH) Driver
+=====================================
+
+Overview
+========
+
+The ``cmh`` driver supports the Rambus CryptoManager Hub hardware cryptographic
+accelerator.  The hardware is accessed through a mailbox-based VCQ
+(Virtual Command Queue) interface: the driver writes command sequences
+into per-mailbox DMA queue buffers and rings a doorbell register; the
+CryptoManager Hub embedded software (eSW) processes the commands and signals
+completion through the mailbox registers, optionally with an interrupt.
+
+The driver registers algorithms with the Linux kernel crypto subsystem.
+
+Hardware Interface
+==================
+
+The CryptoManager Hub is presented as a platform device matched via Device Tree
+(compatible ``"rambus,cmh-v1030"``).  The driver maps a single MMIO region
+(the SIC -- System Interface Controller) whose sub-regions contain
+per-mailbox doorbell, status, and command queue registers.
+
+The driver uses the mailboxes the device tree assigns to the host, one
+``queue@N`` child node each (at least one is required).  Each mailbox
+queue has a configurable number of slots (default 64) and a configurable
+stride (default 512 bytes per slot).  The driver allocates DMA-coherent
+memory for each mailbox queue during probe.
+
+A mailbox is owned by a single host identity for the duration of a lock,
+and the hardware permits only that identity to access it.  The platform
+must present one consistent HOST ID for all accesses to a given mailbox,
+independent of the issuing CPU; see the device-tree binding for this
+integration requirement.
+
+Each mailbox may have its own completion/error interrupt, for which the
+driver registers a threaded IRQ handler.  Without interrupts the driver
+polls the mailboxes from a watchdog timer.
+
+The eSW is loaded independently of this driver -- typically by the
+boot firmware or a platform-specific loader -- so the driver does not
+use ``request_firmware()``.  Instead it waits for the eSW to reach
+mission mode during probe, bounded by a fixed timeout.
+
+Supported Algorithms
+====================
+
+The registered families are listed below; the live set on a running
+kernel is listed in ``/proc/crypto``.  The exact parameter sets, key
+sizes, and curves within each family are those of the underlying CMH
+device; the CMH host-API documentation is authoritative for the
+supported set on a given CMH configuration.
+
+All algorithm driver names use the ``rambus-cmh-`` prefix (e.g.
+``rambus-cmh-ecb-aes``, ``rambus-cmh-gcm-aes``).  Names generally follow
+the kernel's hyphenated template name; families that have no kernel
+template use the concatenated upstream algorithm name.
+
+All algorithms register at priority 300.  Priority is selection policy,
+not a performance claim: a generic name resolves to the highest-priority
+implementation that matches the caller's type and mask, which may be a
+CPU implementation (on RISC-V, for example, the AES library modes
+register at 500).  Between implementations of equal priority the most
+recently registered one is chosen, so the result depends on load order.
+Callers that require this hardware should allocate by driver name, and
+can check the driver name of an allocated transform.
+
+Request model
+-------------
+
+The skcipher, AEAD and hash algorithms are registered
+``CRYPTO_ALG_ASYNC``.  The driver queues a request to its
+transaction-manager kthread and returns ``-EINPROGRESS``, then completes
+it through the caller's callback when the hardware finishes.  Some
+requests complete synchronously without reaching the hardware -- for
+example a zero-length skcipher request, an empty CCM request, or
+incremental MAC operations served by the software fallback
+(see `Data-Size Limits`_).  Completion callbacks run from the threaded
+interrupt handler, from the watchdog timer (softirq), or from the
+transaction manager, so they must be safe in atomic context; the final
+status is always delivered with bottom halves disabled.
+
+The algorithms also set ``CRYPTO_ALG_ALLOCATES_MEMORY``: each request
+allocates bounce buffers (``GFP_ATOMIC`` unless the request may sleep).
+
+When the command queue is full, a request with
+``CRYPTO_TFM_REQ_MAY_BACKLOG`` is placed on the backlog and ``-EBUSY``
+is returned; the callback is invoked with ``-EINPROGRESS`` when it
+leaves the backlog, and again with the final status.  The backlog is
+unbounded, so such a request is never refused for lack of space.
+Without that flag ``-ENOSPC`` is returned and the request is not
+queued.
+
+The final status is 0 or a negative errno:
+
+``-EIO``
+  The device reported an error for the command.
+``-EBADMSG``
+  AEAD authentication failure on decryption.
+``-ECANCELED``
+  Cancelled before it completed: by mailbox recovery, which discards a
+  mailbox's queue with a FLUSH and completes the requests on it once the
+  device acknowledges the FLUSH, by suspend before it was sent to the
+  device, or by driver teardown.
+``-ETIMEDOUT``
+  The device did not respond: the request's own timeout expired (it
+  then completes when the device finishes with it), or its mailbox was
+  retired after the device failed to acknowledge a FLUSH.
+``-ENODEV``
+  No usable mailbox (all retired), or the device is suspended.
+``-EINVAL``, ``-EMSGSIZE``, ``-EOVERFLOW``
+  Malformed or oversized request (see `Data-Size Limits`_); a CCM length
+  that does not fit the nonce's length field is ``-EOVERFLOW``.
+``-ENOMEM``
+  A bounce buffer could not be allocated.
+
+Driver Architecture
+===================
+
+The driver is structured as follows:
+
+Platform Driver
+  Matches DT compatible ``"rambus,cmh-v1030"``.  Probe initializes all
+  subsystems in order; remove tears them down in reverse.  The device is
+  expected to be a static platform device: removal frees state that live
+  transforms use, so binding and unbinding through sysfs is disabled,
+  and removing the device by other means (for example a device-tree
+  overlay) while transforms exist is not supported.  Module unload is
+  refused while any transform exists.
+
+Configuration
+  Parses and validates the DT properties (mailbox nodes, slot counts,
+  strides, and core affinity).
+
+Algorithms
+  Each algorithm copies or maps its request data into DMA buffers and
+  builds the VCQ command sequence for its core.
+
+MQI (Mailbox Queue Interface)
+  Allocates the DMA-coherent queue memory per mailbox and programs the
+  mailbox registers at probe, and FLUSHes the mailboxes at teardown.  At
+  probe each mailbox must first acknowledge a FLUSH, so no DMA memory is
+  allocated while the device may still be using memory from a previous
+  load; otherwise the probe fails with ``-EBUSY``.
+
+Transaction Manager
+  A dedicated kthread dequeues requests from a central command queue,
+  writes their VCQs into mailbox slots and rings the doorbell.  Each core
+  is bound to one mailbox, from the ``rambus,cores`` affinity or, if
+  unassigned, on its first use; all of that core's requests then go to
+  that mailbox.
+
+Response Handler
+  The threaded IRQ handler and a watchdog timer (the ``watchdog_ms``
+  debugfs knob, default 200 ms) read the mailbox HEAD and status and
+  complete requests in order.  When the device reports an error the
+  failed request completes with it and RESTART resumes the mailbox.  A
+  failed multi-VCQ request, an unresponsive RESTART, or a stalled ABORT
+  escalates to FLUSH: the mailbox takes no new requests until the device
+  acknowledges the FLUSH, and only then are the requests left on its
+  queue completed.  A mailbox whose FLUSH is never acknowledged is
+  retired.  This hardware has no DMA-stop primitive, so the buffers of
+  requests the device may still access are then never freed: they are
+  quarantined, and released at module unload only if the device
+  acknowledges a final FLUSH.
+
+Power Management
+  System sleep is supported through ``DEFINE_SIMPLE_DEV_PM_OPS``.  On
+  suspend, the transaction-manager kthread is stopped and requests not
+  yet sent to the device are cancelled; requests already on the device
+  are given up to ``drain_timeout_ms`` (default 10000 ms) to complete,
+  and if any is still running the suspend is refused with ``-EBUSY``.
+  Requests of a retired mailbox are not waited for: their memory is
+  kept, but the device may still access it.  Resume restarts the
+  kthread.  The platform must keep the CryptoManager
+  Hub powered across system sleep: resume does not reprogram the
+  mailboxes or restore state held by the eSW, such as keys.
+
+Module Parameters
+=================
+
+The driver defines no production module parameters.  All mailbox
+topology, per-core affinity, slot counts, and strides are taken from
+Device Tree properties; the eSW boot timeout and queue depths are
+built-in constants, and the runtime-tunable knobs are exposed via
+debugfs (see `debugfs Counters`_ below).
+
+A small set of debug-only parameters is compiled in only with
+``CONFIG_CRYPTO_DEV_CMH_DEBUG``.  They exist solely to force alternate
+geometries at ``insmod`` time during bringup and validation (for
+example, to drive the mailbox-contention and cross-mailbox dispatch
+paths without rebuilding the Device Tree); they default to "use the DT
+value" and have no effect in a production build:
+
+``mbx_count_override`` (uint, default 0)
+  Override the DT mailbox count (0 = use DT) to force fewer
+  mailboxes than the hardware provides.
+
+``mbx_slots_override`` (uint, default 0)
+  Override the log2 of every mailbox's slot count (e.g. 1 = 2 slots;
+  0 = use DT), within the range the DT property allows.
+
+``mbx_round_robin`` (bool, default false)
+  Ignore DT ``rambus,cores`` affinity and round-robin all cores
+  across the configured mailboxes (0 = use DT affinity).
+
+``skip_fw_check`` (bool, default false)
+  Skip the SIC boot status and eSW mission-mode checks at probe, and the
+  mailbox FLUSH fence that precedes any DMA allocation.  Allows the
+  module to load before the eSW has booted; it also loses the fence's
+  protection against memory a previous load could not fence.
+
+sysfs Attributes
+================
+
+The driver exposes five read-only attributes under the platform
+device sysfs directory: ``fw_version``, ``hw_version``,
+``boot_status``, ``mbx_available``, and ``mbx_count``.  See
+``Documentation/ABI/testing/sysfs-driver-cmh`` for the authoritative
+per-attribute description.
+
+debugfs Counters
+================
+
+When built with ``CONFIG_CRYPTO_DEV_CMH_DEBUG``, the driver creates
+``/sys/kernel/debug/cmh/`` with three groups: per-mailbox counters
+(``mbxN/``), transaction-manager statistics (``tm/``), and
+runtime-tunable knobs (``config/``, including ``drain_timeout_ms``,
+``watchdog_ms`` and ``cmq_max_depth``).  See
+``Documentation/ABI/testing/debugfs-driver-cmh`` for the authoritative
+per-file description.
+
+Device Tree Binding
+===================
+
+See ``Documentation/devicetree/bindings/crypto/rambus,cmh-v1030.yaml`` for
+the full DT binding schema.  Each
+mailbox owned by the host is a ``queue@N`` child node with its own
+``reg`` (instance index), optional ``interrupts``, optional per-mailbox
+VCQ ring geometry (``rambus,num-slots`` / ``rambus,slot-stride-bytes``,
+defaulting to 64 and 512), and an optional ``rambus,cores`` list pinning
+specific crypto cores to that mailbox.  Which crypto cores are present
+is read from the SIC ``CORE_ENABLE`` register at probe, not described in
+the device tree.
+
+The parent node may also carry up to three ``clocks`` (the main core
+clock, a half-rate clock present only on configurations with
+side-channel-protected cores, and the real-time tick clock) and an
+optional ``reset-gpios``.  The driver enables every supplied clock and
+acquires the reset line deasserted; it does not drive a reset sequence.
+Both are absent when a separate management controller owns them, in
+which case the driver drives neither.
+
+Interfaces
+==========
+
+In-kernel crypto API
+  All algorithms register with the standard kernel crypto API and are
+  consumed by in-kernel users (dm-crypt, IPsec, kTLS, etc.).
+
+Data-Size Limits
+================
+
+Symmetric requests are copied into contiguous bounce buffers allocated
+per request, so the driver caps their size.  A request over a cap fails
+with ``-EINVAL``; it is not passed to a software implementation.  Below
+a cap a large request can still fail with ``-ENOMEM`` when the bounce
+buffers cannot be allocated, in particular for ``GFP_ATOMIC`` requests.
+
+MAC and hash algorithms offload the one-shot ``.digest()`` only.  The
+hardware's intermediate state is a non-portable internal checkpoint, and
+the keyed MACs cannot save it at all, so the incremental operations
+(``.init``/``.update``/``.final``/``.export``/``.import``) are served
+synchronously by a generic software transform.  ``.digest()`` copies the
+whole message into one DMA buffer and rejects an input larger than
+``KMALLOC_MAX_SIZE`` with ``-EMSGSIZE``; incremental operation through
+the software transform has no such limit.  For keyed algorithms the key
+is programmed into both the hardware and the software transform on
+``.setkey()``.
diff --git a/Documentation/crypto/device_drivers/index.rst b/Documentation/crypto/device_drivers/index.rst
index c81d311ac61b..c0247fc97bf8 100644
--- a/Documentation/crypto/device_drivers/index.rst
+++ b/Documentation/crypto/device_drivers/index.rst
@@ -6,4 +6,5 @@ Hardware Device Driver Specific Documentation
 .. toctree::
    :maxdepth: 1
 
+   cmh
    octeontx2
diff --git a/drivers/crypto/Kconfig b/drivers/crypto/Kconfig
index 0189dfdcbbe1..db2aae7e0ac7 100644
--- a/drivers/crypto/Kconfig
+++ b/drivers/crypto/Kconfig
@@ -830,5 +830,6 @@ source "drivers/crypto/aspeed/Kconfig"
 source "drivers/crypto/starfive/Kconfig"
 source "drivers/crypto/inside-secure/eip93/Kconfig"
 source "drivers/crypto/ti/Kconfig"
+source "drivers/crypto/cmh/Kconfig"
 
 endif # CRYPTO_HW
diff --git a/drivers/crypto/Makefile b/drivers/crypto/Makefile
index 2c33b83f3cfa..dae0d5f0500d 100644
--- a/drivers/crypto/Makefile
+++ b/drivers/crypto/Makefile
@@ -46,3 +46,4 @@ obj-y += intel/
 obj-y += starfive/
 obj-y += cavium/
 obj-y += ti/
+obj-$(CONFIG_CRYPTO_DEV_CMH) += cmh/
diff --git a/drivers/crypto/cmh/Kconfig b/drivers/crypto/cmh/Kconfig
new file mode 100644
index 000000000000..861fe31ec5fb
--- /dev/null
+++ b/drivers/crypto/cmh/Kconfig
@@ -0,0 +1,37 @@
+# SPDX-License-Identifier: GPL-2.0
+#
+# Rambus CryptoManager Hub (CMH) hardware crypto accelerator
+#
+# The VCQ command and DMA descriptor ABI uses native (host-endian)
+# integer types and is only valid on little-endian hosts: the CMH block
+# and its eSW are co-located on the same little-endian SoC and there is
+# no big-endian deployment.  Gate the driver on !CPU_BIG_ENDIAN rather
+# than byte-swapping an ABI that would never be exercised.
+#
+
+config CRYPTO_DEV_CMH
+	tristate "Rambus CryptoManager Hub (CMH) hardware crypto accelerator"
+	depends on CRYPTO && OF && HAS_IOMEM && (64BIT || COMPILE_TEST)
+	depends on !CPU_BIG_ENDIAN
+	help
+	  Driver for the Rambus CryptoManager Hub (CMH) hardware crypto
+	  accelerator.  The device is accessed through a mailbox-based VCQ
+	  (Virtual Command Queue) interface: the driver writes command
+	  sequences into per-mailbox DMA queues and completes them from a
+	  threaded interrupt, registering the algorithms the hardware
+	  provides with the kernel crypto subsystem.  See /proc/crypto for
+	  the set on a running kernel.
+
+	  To compile this driver as a module, choose M here.
+
+config CRYPTO_DEV_CMH_DEBUG
+	bool "CMH debug instrumentation (debugfs counters)"
+	depends on CRYPTO_DEV_CMH && DEBUG_FS
+	help
+	  Enable per-mailbox debugfs counters under
+	  /sys/kernel/debug/cmh/ for the CMH driver.
+	  Exposes VCQ submit/complete/error counts, queue depth
+	  high-water marks, and transaction manager backoff statistics.
+
+	  Useful for bringup, validation, and performance analysis.
+	  Not recommended for production.
diff --git a/drivers/crypto/cmh/Makefile b/drivers/crypto/cmh/Makefile
new file mode 100644
index 000000000000..742e65e3917e
--- /dev/null
+++ b/drivers/crypto/cmh/Makefile
@@ -0,0 +1,25 @@
+# SPDX-License-Identifier: GPL-2.0
+#
+# Makefile for the Rambus CryptoManager Hub (CMH) hardware crypto accelerator driver.
+#
+
+obj-$(CONFIG_CRYPTO_DEV_CMH) += cmh.o
+
+cmh-y := \
+	cmh_main.o \
+	cmh_config.o \
+	cmh_mqi.o \
+	cmh_txn.o \
+	cmh_rh.o \
+	cmh_dma.o \
+	cmh_sysfs.o
+
+ccflags-y += -I$(src)/include
+
+# Suppress -Woverride-init for the [0 ... N] = -1 range-initializer pattern
+# (standard kernel idiom for sparse lookup tables with a default value).
+CFLAGS_cmh_config.o += -Wno-override-init
+
+# Debug instrumentation: per-mailbox debugfs counters.
+# cmh_debugfs.o is linked into the composite cmh.o (same tristate).
+cmh-$(CONFIG_CRYPTO_DEV_CMH_DEBUG) += cmh_debugfs.o
diff --git a/drivers/crypto/cmh/cmh_config.c b/drivers/crypto/cmh/cmh_config.c
new file mode 100644
index 000000000000..bf81f07d169b
--- /dev/null
+++ b/drivers/crypto/cmh/cmh_config.c
@@ -0,0 +1,625 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- Configuration from Device Tree
+ *
+ * The CMH device tree node provides:
+ *   - reg: SIC base + size (mandatory)
+ *
+ * Per-mailbox child nodes (queue@N):
+ *   - reg: 0-based MBX instance index (mandatory)
+ *   - interrupts: (optional) per-MBX completion IRQ; absent => polling
+ *   - rambus,num-slots / rambus,slot-stride-bytes: (optional) VCQ ring
+ *     geometry (slot count / per-slot stride in bytes, both powers of two)
+ *   - rambus,cores: (optional) crypto core names pinned to this mailbox
+ *
+ * Crypto cores are discovered from the SIC CORE_ENABLE register at probe
+ * (cmh_config_discover_cores), not described in the device tree.
+ */
+
+#include <linux/module.h>
+#include <linux/kernel.h>
+#include <linux/platform_device.h>
+#include <linux/of.h>
+#include <linux/of_irq.h>
+#include <linux/log2.h>
+#include <linux/string.h>
+
+#include "cmh_config.h"
+#include "cmh_dma.h"
+
+/*
+ * Debug-only MBX overrides for stress testing.
+ * When non-zero, these override the corresponding DT values, enabling
+ * contention stress tests to force a minimal MBX config
+ * (e.g. mbx_count_override=1 mbx_slots_override=1 for 1 MBX, 2 slots).
+ */
+#ifdef CONFIG_CRYPTO_DEV_CMH_DEBUG
+static unsigned int mbx_count_override;
+module_param(mbx_count_override, uint, 0444);
+MODULE_PARM_DESC(mbx_count_override,
+		 "[debug] Override DT MBX count (0 = use DT, default: 0)");
+
+static unsigned int mbx_slots_override;
+module_param(mbx_slots_override, uint, 0444);
+MODULE_PARM_DESC(mbx_slots_override,
+		 "[debug] Override all MBX slots_log2 (0 = use DT, default: 0)");
+
+static bool mbx_round_robin;
+module_param(mbx_round_robin, bool, 0444);
+MODULE_PARM_DESC(mbx_round_robin,
+		 "[debug] Ignore DT rambus,cores affinity and round-robin all cores across MBXes (0 = use DT affinity, default: 0)");
+#endif
+
+/* -- Core ID -> core_type lookup --------------------------------------- */
+
+/*
+ * Map hardware core IDs to enum cmh_core_type.
+ *
+ * Entries set to -1 are not dispatchable crypto cores: system cores
+ * (SYS, DMA, KIC, TIC, MPU, EMC, EAC) and the DRBG, which serves the
+ * hwrng rather than the crypto API.
+ */
+static const int core_id_to_type[CORE_ID_NUM] = {
+	[0 ... CORE_ID_NUM - 1] = -1,
+	[CORE_ID_HC]  = CMH_CORE_HC,
+	[CORE_ID_AES] = CMH_CORE_AES,
+	[CORE_ID_SM4] = CMH_CORE_SM4,
+	[CORE_ID_SM3] = CMH_CORE_SM3,
+	[CORE_ID_CCP] = CMH_CORE_CCP,
+	[CORE_ID_PKE] = CMH_CORE_PKE,
+	[CORE_ID_QSE] = CMH_CORE_QSE,
+	[CORE_ID_HCQ] = CMH_CORE_HCQ,
+};
+
+/* Human-readable names for error messages */
+static const char * const core_type_names[CMH_NUM_CORE_TYPES] = {
+	[CMH_CORE_HC]  = "hc",
+	[CMH_CORE_AES] = "aes",
+	[CMH_CORE_SM4] = "sm4",
+	[CMH_CORE_SM3] = "sm3",
+	[CMH_CORE_CCP] = "ccp",
+	[CMH_CORE_PKE] = "pke",
+	[CMH_CORE_QSE] = "qse",
+	[CMH_CORE_HCQ] = "hcq",
+};
+
+/* -- Hardware core discovery ------------------------------------------ */
+
+/*
+ * Per-core-type discovery descriptor: the dual-rail CORE_ENABLE mask and
+ * the canonical hardware core ID for that type.  DRBG is intentionally
+ * absent -- it is not a dispatchable crypto core.
+ */
+struct cmh_core_desc {
+	u32 enable_mask;
+	u32 core_id;
+};
+
+static const struct cmh_core_desc cmh_core_descs[CMH_NUM_CORE_TYPES] = {
+	[CMH_CORE_HC]  = { SIC_CORE_ENABLE_HC,  CORE_ID_HC  },
+	[CMH_CORE_AES] = { SIC_CORE_ENABLE_AES, CORE_ID_AES },
+	[CMH_CORE_SM4] = { SIC_CORE_ENABLE_SM4, CORE_ID_SM4 },
+	[CMH_CORE_SM3] = { SIC_CORE_ENABLE_SM3, CORE_ID_SM3 },
+	[CMH_CORE_CCP] = { SIC_CORE_ENABLE_CCP, CORE_ID_CCP },
+	[CMH_CORE_PKE] = { SIC_CORE_ENABLE_PKE, CORE_ID_PKE },
+	[CMH_CORE_QSE] = { SIC_CORE_ENABLE_QSE, CORE_ID_QSE },
+	[CMH_CORE_HCQ] = { SIC_CORE_ENABLE_HCQ, CORE_ID_HCQ },
+};
+
+/* rambus,cores DT names -> hardware core IDs (see cmh_vcq.h). */
+static const struct cmh_dt_core_name {
+	const char *name;
+	u32 id;
+} cmh_dt_core_names[] = {
+	{ "hc",  CORE_ID_HC },
+	{ "aes", CORE_ID_AES },
+	{ "sm4", CORE_ID_SM4 },
+	{ "sm3", CORE_ID_SM3 },
+	{ "hcq", CORE_ID_HCQ },
+	{ "qse", CORE_ID_QSE },
+	{ "pke", CORE_ID_PKE },
+	{ "ccp", CORE_ID_CCP },
+};
+
+static int cmh_dt_core_id(const char *name)
+{
+	unsigned int i;
+
+	for (i = 0; i < ARRAY_SIZE(cmh_dt_core_names); i++)
+		if (!strcmp(name, cmh_dt_core_names[i].name))
+			return (int)cmh_dt_core_names[i].id;
+	return -1;
+}
+
+/*
+ * Read a power-of-two DT geometry property (a slot count or a byte stride)
+ * and return its log2 -- the encoding the mailbox QUEUE registers use.  An
+ * absent property yields @def_log2; a present value must be a power of two
+ * whose log2 lies in [@min_log2, @max_log2], otherwise -EINVAL.
+ */
+static int cmh_dt_read_geom_log2(const struct device_node *child,
+				 const char *prop, u32 def_log2,
+				 u32 min_log2, u32 max_log2, u32 *out_log2)
+{
+	u32 val;
+
+	if (of_property_read_u32(child, prop, &val)) {
+		*out_log2 = def_log2;
+		return 0;
+	}
+	if (!is_power_of_2(val) ||
+	    ilog2(val) < min_log2 || ilog2(val) > max_log2)
+		return -EINVAL;
+	*out_log2 = ilog2(val);
+	return 0;
+}
+
+/*
+ * Apply the per-mailbox rambus,cores affinity to the discovered cores.  Each
+ * core ID listed on a mailbox pins that core's instance to the mailbox; a
+ * core listed on no mailbox keeps mbx = -1 (round-robin across mailboxes).
+ */
+static int cmh_config_apply_affinity(struct cmh_config *cfg)
+{
+	unsigned int mi, ci, inst;
+
+	for (mi = 0; mi < cfg->mbx_count; mi++) {
+		struct cmh_mbx_config *m = &cfg->mailboxes[mi];
+
+		for (ci = 0; ci < m->num_cores; ci++) {
+			u32 core_id = m->cores[ci];
+			struct cmh_core_type_cfg *ct;
+			int type;
+
+			if (core_id >= CORE_ID_NUM ||
+			    core_id_to_type[core_id] < 0) {
+				dev_err(cmh_dev(),
+					"mbx[%u]: rambus,cores 0x%02x is not a dispatchable core\n",
+					mi, core_id);
+				return -EINVAL;
+			}
+
+			type = core_id_to_type[core_id];
+			ct = &cfg->core_types[type];
+
+			for (inst = 0; inst < ct->num_instances; inst++) {
+				if (ct->core_ids[inst] != core_id)
+					continue;
+				if (ct->mbx[inst] >= 0) {
+					dev_err(cmh_dev(),
+						"core 0x%02x pinned to more than one mailbox\n",
+						core_id);
+					return -EINVAL;
+				}
+				ct->mbx[inst] = (s32)mi;
+				break;
+			}
+		}
+	}
+
+#ifdef CONFIG_CRYPTO_DEV_CMH_DEBUG
+	if (mbx_round_robin) {
+		unsigned int t, j;
+
+		for (t = 0; t < CMH_NUM_CORE_TYPES; t++)
+			for (j = 0; j < cfg->core_types[t].num_instances; j++)
+				cfg->core_types[t].mbx[j] = -1;
+		dev_info(cmh_dev(),
+			 "[debug] mbx_round_robin: dropped all rambus,cores affinity\n");
+	}
+#endif
+
+	return 0;
+}
+
+/* -- Validation -------------------------------------------------------- */
+
+static int cmh_config_validate_core_types(struct cmh_config *cfg)
+{
+	unsigned int i, j, k;
+
+	for (i = 0; i < CMH_NUM_CORE_TYPES; i++) {
+		struct cmh_core_type_cfg *ct = &cfg->core_types[i];
+		const char *name = core_type_names[i];
+
+		/* Zero instances is valid -- core absent from DT */
+		if (ct->num_instances == 0)
+			continue;
+
+		if (ct->num_instances > CMH_MAX_CORE_INSTANCES) {
+			dev_err(cmh_dev(), "%s: num_instances %u > max %u\n",
+				name, ct->num_instances,
+				CMH_MAX_CORE_INSTANCES);
+			return -EINVAL;
+		}
+
+		/* Validate MBX indices */
+		for (j = 0; j < ct->num_instances; j++) {
+			if (ct->mbx[j] >= 0 &&
+			    (u32)ct->mbx[j] >= cfg->mbx_count) {
+#ifdef CONFIG_CRYPTO_DEV_CMH_DEBUG
+				if (mbx_count_override > 0) {
+					dev_info(cmh_dev(),
+						 "%s: mbx[%u]=%d >= overridden mbx_count %u, auto-assigning\n",
+						 name, j, ct->mbx[j],
+						 cfg->mbx_count);
+					ct->mbx[j] = -1;
+					continue;
+				}
+#endif
+				dev_err(cmh_dev(), "%s: mbx[%u]=%d >= mbx_count %u\n",
+					name, j, ct->mbx[j],
+					cfg->mbx_count);
+				return -EINVAL;
+			}
+		}
+
+		/* No duplicate core IDs within this type */
+		for (j = 1; j < ct->num_instances; j++) {
+			for (k = 0; k < j; k++) {
+				if (ct->core_ids[j] == ct->core_ids[k]) {
+					dev_err(cmh_dev(),
+						"%s: duplicate core_id 0x%02x at [%u] and [%u]\n",
+						name, ct->core_ids[j],
+						k, j);
+					return -EINVAL;
+				}
+			}
+		}
+
+		/* No duplicate MBX within this type (if explicit) */
+		for (j = 1; j < ct->num_instances; j++) {
+			if (ct->mbx[j] < 0)
+				continue;
+			for (k = 0; k < j; k++) {
+				if (ct->mbx[k] == ct->mbx[j]) {
+					dev_err(cmh_dev(),
+						"%s: duplicate mbx %d at [%u] and [%u]\n",
+						name, ct->mbx[j], k, j);
+					return -EINVAL;
+				}
+			}
+		}
+
+		/* All core IDs must fit in VCQ 8-bit field */
+		for (j = 0; j < ct->num_instances; j++) {
+			if (ct->core_ids[j] > CORE_ID_MAX) {
+				dev_err(cmh_dev(),
+					"%s: core_ids[%u]=0x%02x > CORE_ID_MAX\n",
+					name, j, ct->core_ids[j]);
+				return -EINVAL;
+			}
+		}
+	}
+
+	/* Cross-type: no core ID used by more than one type */
+	for (i = 0; i < CMH_NUM_CORE_TYPES; i++) {
+		struct cmh_core_type_cfg *ct_i = &cfg->core_types[i];
+
+		for (j = i + 1; j < CMH_NUM_CORE_TYPES; j++) {
+			struct cmh_core_type_cfg *ct_j = &cfg->core_types[j];
+
+			for (k = 0; k < ct_i->num_instances; k++) {
+				unsigned int m;
+
+				for (m = 0; m < ct_j->num_instances; m++) {
+					if (ct_i->core_ids[k] !=
+					    ct_j->core_ids[m])
+						continue;
+					dev_err(cmh_dev(),
+						"core_id 0x%02x conflict: %s[%u] and %s[%u]\n",
+						ct_i->core_ids[k],
+						core_type_names[i], k,
+						core_type_names[j], m);
+					return -EINVAL;
+				}
+			}
+		}
+	}
+
+	return 0;
+}
+
+static int cmh_config_validate(struct cmh_config *cfg)
+{
+	unsigned int i, j;
+	unsigned long max_instance_end;
+
+	if (cfg->mbx_count == 0 || cfg->mbx_count > CMH_MAX_CONFIGURED_MBX) {
+		dev_err(cmh_dev(), "mbx_count %u out of range (1..%u)\n",
+			cfg->mbx_count, CMH_MAX_CONFIGURED_MBX);
+		return -EINVAL;
+	}
+
+	for (i = 0; i < cfg->mbx_count; i++) {
+		struct cmh_mbx_config *m = &cfg->mailboxes[i];
+
+		if (m->instance >= CMH_MAX_MBX_INSTANCES) {
+			dev_err(cmh_dev(), "mbx_instances[%u]=%u >= %u\n",
+				i, m->instance, CMH_MAX_MBX_INSTANCES);
+			return -EINVAL;
+		}
+
+		if (m->slots_log2 < CMH_MBX_SLOTS_LOG2_MIN ||
+		    m->slots_log2 > CMH_MBX_SLOTS_LOG2_MAX) {
+			dev_err(cmh_dev(), "mbx_slots[%u]=%u out of range (%u..%u)\n",
+				i, m->slots_log2,
+			       CMH_MBX_SLOTS_LOG2_MIN, CMH_MBX_SLOTS_LOG2_MAX);
+			return -EINVAL;
+		}
+
+		if (m->stride_log2 < CMH_MBX_STRIDE_LOG2_MIN ||
+		    m->stride_log2 > CMH_MBX_STRIDE_LOG2_MAX) {
+			dev_err(cmh_dev(), "mbx_strides[%u]=%u out of range (%u..%u)\n",
+				i, m->stride_log2,
+			       CMH_MBX_STRIDE_LOG2_MIN, CMH_MBX_STRIDE_LOG2_MAX);
+			return -EINVAL;
+		}
+
+		/* Check for duplicate instance indices */
+		for (j = 0; j < i; j++) {
+			if (cfg->mailboxes[j].instance == m->instance) {
+				dev_err(cmh_dev(), "duplicate instance %u at indices %u and %u\n",
+					m->instance, j, i);
+				return -EINVAL;
+			}
+		}
+	}
+
+	/* Ensure SIC region is large enough for all requested instances */
+	max_instance_end = 0;
+	for (i = 0; i < cfg->mbx_count; i++) {
+		unsigned long end = ((unsigned long)cfg->mailboxes[i].instance + 1)
+				    << CMH_MBX_INSTANCE_SHIFT;
+		if (end > max_instance_end)
+			max_instance_end = end;
+	}
+
+	if (max_instance_end > cfg->sic_size) {
+		dev_err(cmh_dev(), "sic_size 0x%zx too small for instance requiring 0x%lx\n",
+			cfg->sic_size, max_instance_end);
+		return -EINVAL;
+	}
+
+	return 0;
+}
+
+/* -- Public Interface -------------------------------------------------- */
+
+/**
+ * cmh_config_init() - Initialize device configuration from platform/DT data
+ * @cfg: Configuration structure to populate
+ * @pdev: Platform device providing DT node and resources
+ *
+ * Parse the "rambus,cmh-v1030" device tree node for the MMIO base
+ * address, interrupt specifiers and per-mailbox properties (instance
+ * indices, slot counts, strides, core affinity); an absent slot count or
+ * stride takes the built-in default.  Then validate the configuration.
+ *
+ * Return: 0 on success, negative errno on failure.
+ */
+int cmh_config_init(struct cmh_config *cfg, struct platform_device *pdev)
+{
+	struct device_node *np = pdev->dev.of_node;
+	struct resource *res;
+	struct device_node *child;
+	int ret;
+
+	if (!np) {
+		dev_err(&pdev->dev, "device tree node required\n");
+		return -ENODEV;
+	}
+
+	/* SIC base + size from DT "reg" property (mandatory) */
+	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
+	if (!res) {
+		dev_err(cmh_dev(), "missing DT reg resource\n");
+		return -EINVAL;
+	}
+	cfg->sic_base = res->start;
+	cfg->sic_size = resource_size(res);
+
+	/*
+	 * Interrupts are per-mailbox (declared in each mailbox child node)
+	 * and resolved per MBX by cmh_rh_resolve_irqs().  There is no
+	 * top-level interrupt; if no mailbox has one the response handler
+	 * falls back to watchdog-timer polling.
+	 */
+	cfg->sic_mapped = NULL;
+	cfg->fw_ready_timeout_ms = CMH_FW_READY_TIMEOUT_MS;
+
+	/* -- Mailbox configuration from DT child nodes ----------------- */
+
+	cfg->mbx_count = 0;
+	for_each_child_of_node(np, child) {
+		struct cmh_mbx_config *m;
+		int nc, ci;
+
+		if (!of_node_name_eq(child, "queue"))
+			continue;
+
+		if (cfg->mbx_count >= CMH_MAX_CONFIGURED_MBX) {
+			dev_err(cmh_dev(),
+				"too many mailbox nodes in DT (max %u)\n",
+				CMH_MAX_CONFIGURED_MBX);
+			of_node_put(child);
+			return -EINVAL;
+		}
+		m = &cfg->mailboxes[cfg->mbx_count];
+
+		ret = of_property_read_u32(child, "reg", &m->instance);
+		if (ret) {
+			dev_err(cmh_dev(), "mailbox %pOFn: missing 'reg'\n",
+				child);
+			of_node_put(child);
+			return ret;
+		}
+
+		ret = cmh_dt_read_geom_log2(child, "rambus,num-slots",
+					    CMH_DEFAULT_SLOTS_LOG2,
+					    CMH_MBX_SLOTS_LOG2_MIN,
+					    CMH_MBX_SLOTS_LOG2_MAX,
+					    &m->slots_log2);
+		if (ret) {
+			dev_err(cmh_dev(),
+				"mailbox %u: rambus,num-slots not power-of-2 in %u..%u\n",
+				m->instance, 1U << CMH_MBX_SLOTS_LOG2_MIN,
+				1U << CMH_MBX_SLOTS_LOG2_MAX);
+			of_node_put(child);
+			return ret;
+		}
+
+		ret = cmh_dt_read_geom_log2(child, "rambus,slot-stride-bytes",
+					    CMH_DEFAULT_STRIDE_LOG2,
+					    CMH_MBX_STRIDE_LOG2_MIN,
+					    CMH_MBX_STRIDE_LOG2_MAX,
+					    &m->stride_log2);
+		if (ret) {
+			dev_err(cmh_dev(),
+				"mailbox %u: rambus,slot-stride-bytes not power-of-2 in %u..%u\n",
+				m->instance, 1U << CMH_MBX_STRIDE_LOG2_MIN,
+				1U << CMH_MBX_STRIDE_LOG2_MAX);
+			of_node_put(child);
+			return ret;
+		}
+
+#ifdef CONFIG_CRYPTO_DEV_CMH_DEBUG
+		if (mbx_slots_override > 0) {
+			/* Range-check before queue_size shifts by it below. */
+			if (mbx_slots_override < CMH_MBX_SLOTS_LOG2_MIN ||
+			    mbx_slots_override > CMH_MBX_SLOTS_LOG2_MAX) {
+				dev_err(cmh_dev(),
+					"mbx_slots_override=%u out of range (%u..%u)\n",
+					mbx_slots_override,
+					CMH_MBX_SLOTS_LOG2_MIN,
+					CMH_MBX_SLOTS_LOG2_MAX);
+				of_node_put(child);
+				return -EINVAL;
+			}
+			m->slots_log2 = mbx_slots_override;
+		}
+#endif
+
+		/* Optional per-mailbox interrupt (absent => polling). */
+		m->irq = of_irq_get(child, 0);
+		if (m->irq == -EPROBE_DEFER) {
+			of_node_put(child);
+			return -EPROBE_DEFER;
+		}
+		/* of_irq_get() returns 0 (not <0) on a mapping failure. */
+		if (m->irq <= 0)
+			m->irq = -1;
+
+		/* Optional rambus,cores affinity list (core-name strings). */
+		m->num_cores = 0;
+		nc = of_property_count_strings(child, "rambus,cores");
+		if (nc > 0) {
+			if (nc > CMH_NUM_CORE_TYPES) {
+				dev_err(cmh_dev(),
+					"mailbox %u: too many rambus,cores (%d > %u)\n",
+					m->instance, nc, CMH_NUM_CORE_TYPES);
+				of_node_put(child);
+				return -EINVAL;
+			}
+			for (ci = 0; ci < nc; ci++) {
+				const char *cname;
+				int cid;
+
+				of_property_read_string_index(child,
+							      "rambus,cores",
+							      ci, &cname);
+				cid = cmh_dt_core_id(cname);
+				if (cid < 0) {
+					dev_err(cmh_dev(),
+						"mailbox %u: unknown rambus,cores core '%s'\n",
+						m->instance, cname);
+					of_node_put(child);
+					return -EINVAL;
+				}
+				m->cores[ci] = (u32)cid;
+			}
+			m->num_cores = nc;
+		}
+
+		m->queue_size = (1UL << m->slots_log2) << m->stride_log2;
+		m->dma_handle = 0;
+		m->virt_addr = NULL;
+		m->reg_base = NULL;
+		cfg->mbx_count++;
+	}
+
+	if (cfg->mbx_count == 0) {
+		dev_err(cmh_dev(), "no mailbox child nodes in DT\n");
+		return -EINVAL;
+	}
+
+#ifdef CONFIG_CRYPTO_DEV_CMH_DEBUG
+	if (mbx_count_override > 0) {
+		if (mbx_count_override > cfg->mbx_count) {
+			dev_err(cmh_dev(),
+				"mbx_count_override %u > DT count %u\n",
+				mbx_count_override, cfg->mbx_count);
+			return -EINVAL;
+		}
+		dev_info(cmh_dev(), "[debug] overriding mbx_count: %u -> %u\n",
+			 cfg->mbx_count, mbx_count_override);
+		cfg->mbx_count = mbx_count_override;
+	}
+#endif
+
+	/*
+	 * Cores are discovered later (cmh_config_discover_cores) once the
+	 * SIC region is mapped and CORE_ENABLE is readable.  Here we only
+	 * validate the mailbox configuration.
+	 */
+	return cmh_config_validate(cfg);
+}
+
+/**
+ * cmh_config_discover_cores() - Enumerate cores from the CORE_ENABLE register
+ * @cfg: Configuration structure (SIC must already be mapped)
+ *
+ * Reads the SIC CORE_ENABLE register to determine which crypto core types
+ * the silicon build provides, populates cfg->core_types[], applies the
+ * per-mailbox rambus,cores affinity, and validates the result.  Called after
+ * the SIC ioremap.
+ *
+ * Return: 0 on success, negative errno on failure.
+ */
+int cmh_config_discover_cores(struct cmh_config *cfg)
+{
+	u32 core_enable;
+	unsigned int type;
+	int ret;
+
+	if (!cfg->sic_mapped) {
+		dev_err(cmh_dev(), "discover_cores: SIC not mapped\n");
+		return -EINVAL;
+	}
+
+	core_enable = cmh_reg_read32(cfg->sic_mapped, R_SIC_CORE_ENABLE);
+	dev_dbg(cmh_dev(), "CORE_ENABLE=0x%08x\n", core_enable);
+
+	for (type = 0; type < CMH_NUM_CORE_TYPES; type++) {
+		const struct cmh_core_desc *d = &cmh_core_descs[type];
+		struct cmh_core_type_cfg *ct = &cfg->core_types[type];
+
+		if (!d->enable_mask)
+			continue;
+		if (!cmh_sic_core_enabled(core_enable, d->enable_mask))
+			continue;
+
+		ct->core_ids[0] = d->core_id;
+		ct->mbx[0] = -1;
+		ct->num_instances = 1;
+		dev_dbg(cmh_dev(), "core %s (0x%02x) present\n",
+			core_type_names[type], d->core_id);
+	}
+
+	ret = cmh_config_apply_affinity(cfg);
+	if (ret)
+		return ret;
+
+	return cmh_config_validate_core_types(cfg);
+}
diff --git a/drivers/crypto/cmh/cmh_debugfs.c b/drivers/crypto/cmh/cmh_debugfs.c
new file mode 100644
index 000000000000..36fdc3283369
--- /dev/null
+++ b/drivers/crypto/cmh/cmh_debugfs.c
@@ -0,0 +1,309 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- debugfs Per-MBX Counters and Fault Injection
+ *
+ * Creates the /sys/kernel/debug/cmh/ tree with:
+ *   mbxN/vcqs_submitted   (ro) Total VCQs sent to MBX N
+ *   mbxN/vcqs_completed   (ro) Total completions received
+ *   mbxN/vcqs_errors      (ro) Total error completions
+ *   mbxN/queue_full_count (ro) Times select_mailbox() skipped this MBX
+ *   mbxN/max_queue_depth  (ro) High-water mark of in-flight transactions
+ *   mbxN/inject_abort     (wo) Write any value to inject MBX_COMMAND_ABORT
+ *   mbxN/force_drain      (wo) Write any value to force-drain all pending txns
+ *   tm/cmq_posts          (ro) Total cmh_tm_post_command() calls
+ *   tm/cmq_depth_max      (ro) High-water mark of CMQ length
+ *   tm/cmq_full_count     (ro) Times CMQ was full (-ENOSPC)
+ *   tm/backoff_count      (ro) Times TM backed off (all MBX queues full)
+ *   tm/async_timeout_count (ro) Async requests that timed out
+ *
+ * This file is only compiled when CONFIG_CRYPTO_DEV_CMH_DEBUG=y (see Kbuild).
+ * Requires CONFIG_DEBUG_FS=y in the kernel (standard for dev builds).
+ */
+
+#include <linux/module.h>
+#include <linux/kernel.h>
+#include <linux/debugfs.h>
+#include <linux/slab.h>
+
+#include "cmh_debugfs.h"
+#include "cmh_config.h"
+#include "cmh_registers.h"
+#include "cmh_dma.h"
+#include "cmh_txn.h"
+#include "cmh_rh.h"
+
+/* -- Module State ---------------------------------------------------------- */
+
+static struct {
+	struct dentry		*root;		/* /sys/kernel/debug/cmh/ */
+	struct dentry		*config;	/* config/ subdir (subsystem tunables) */
+	struct cmh_mbx_stats	*mbx;		/* array[mbx_count] */
+	struct cmh_tm_stats	 tm;
+	struct cmh_config	*cfg;		/* for inject_abort register access */
+	u32			 mbx_count;
+} dbgfs;
+
+/* -- debugfs file ops for atomic64_t --------------------------------------- */
+
+static int cmh_dbgfs_u64_get(void *data, u64 *val)
+{
+	*val = (u64)atomic64_read((atomic64_t *)data);
+	return 0;
+}
+
+DEFINE_DEBUGFS_ATTRIBUTE(cmh_dbgfs_u64_ro_fops,
+			 cmh_dbgfs_u64_get, NULL, "%llu\n");
+
+/* -- Per-MBX directory ----------------------------------------------------- */
+
+/*
+ * inject_abort -- write-only debugfs file for fault injection.
+ *
+ * Writing any value triggers MBX_COMMAND_ABORT on this mailbox.
+ * The eSW calls mbx_abort() -> mbx_cmd_error(mbx, -EPIPE) and fires the
+ * error IRQ; the LKM RH completes the aborted transaction with -EIO and
+ * then recovers the mailbox (see cmh_rh_process_mbx()).
+ *
+ * Private data points to the MBX index (cast to void *).
+ */
+static ssize_t inject_abort_write(struct file *file,
+				  const char __user *ubuf,
+				  size_t count, loff_t *ppos)
+{
+	u32 idx = (u32)(unsigned long)file->private_data;
+
+	if (!dbgfs.cfg || idx >= dbgfs.cfg->mbx_count)
+		return -EINVAL;
+
+	dev_warn(cmh_dev(), "debugfs: injecting ABORT on mbx[%u]\n", idx);
+	/* Locked helper: don't race the response handler or watchdog. */
+	cmh_rh_abort_mbx(idx, -1);
+
+	return count;
+}
+
+static const struct file_operations inject_abort_fops = {
+	.owner = THIS_MODULE,
+	.open = simple_open,
+	.write = inject_abort_write,
+	.llseek = noop_llseek,
+};
+
+/*
+ * force_drain -- write-only debugfs file for administrative recovery.
+ *
+ * Writing any value resets the recovery bookkeeping (including the
+ * wedged flag), closes the mailbox and issues MBX_COMMAND_FLUSH (see
+ * cmh_rh_force_drain_mbx()).  Once the eSW acknowledges it, every
+ * pending transaction completes with -ECANCELED and the mailbox reopens;
+ * a mailbox that never acknowledges is retired again.
+ *
+ * Use this when normal ABORT/RESTART escalation has not recovered the
+ * mailbox.
+ */
+static ssize_t force_drain_write(struct file *file,
+				 const char __user *ubuf,
+				 size_t count, loff_t *ppos)
+{
+	u32 idx = (u32)(unsigned long)file->private_data;
+
+	if (!dbgfs.cfg || idx >= dbgfs.cfg->mbx_count)
+		return -EINVAL;
+
+	cmh_rh_force_drain_mbx(idx);
+	return count;
+}
+
+static const struct file_operations force_drain_fops = {
+	.owner = THIS_MODULE,
+	.open = simple_open,
+	.write = force_drain_write,
+	.llseek = noop_llseek,
+};
+
+static void create_mbx_dir(u32 idx, struct dentry *parent)
+{
+	struct cmh_mbx_stats *s = &dbgfs.mbx[idx];
+	struct dentry *d;
+	char name[16];
+
+	snprintf(name, sizeof(name), "mbx%u", idx);
+	d = debugfs_create_dir(name, parent);
+
+	debugfs_create_file("vcqs_submitted",   0444, d,
+			    &s->vcqs_submitted,   &cmh_dbgfs_u64_ro_fops);
+	debugfs_create_file("vcqs_completed",   0444, d,
+			    &s->vcqs_completed,   &cmh_dbgfs_u64_ro_fops);
+	debugfs_create_file("vcqs_errors",      0444, d,
+			    &s->vcqs_errors,      &cmh_dbgfs_u64_ro_fops);
+	debugfs_create_file("queue_full_count", 0444, d,
+			    &s->queue_full_count, &cmh_dbgfs_u64_ro_fops);
+	debugfs_create_file("max_queue_depth",  0444, d,
+			    &s->max_queue_depth,  &cmh_dbgfs_u64_ro_fops);
+	debugfs_create_file("inject_abort",     0200, d,
+			    (void *)(uintptr_t)idx, &inject_abort_fops);
+	debugfs_create_file("force_drain",      0200, d,
+			    (void *)(uintptr_t)idx, &force_drain_fops);
+}
+
+/* -- TM directory ---------------------------------------------------------- */
+
+static void create_tm_dir(struct dentry *parent)
+{
+	struct cmh_tm_stats *s = &dbgfs.tm;
+	struct dentry *d;
+
+	d = debugfs_create_dir("tm", parent);
+
+	debugfs_create_file("cmq_posts",        0444, d,
+			    &s->cmq_posts,        &cmh_dbgfs_u64_ro_fops);
+	debugfs_create_file("cmq_depth_max",    0444, d,
+			    &s->cmq_depth_max,    &cmh_dbgfs_u64_ro_fops);
+	debugfs_create_file("cmq_full_count", 0444, d,
+			    &s->cmq_full_count, &cmh_dbgfs_u64_ro_fops);
+	debugfs_create_file("backoff_count",    0444, d,
+			    &s->backoff_count,    &cmh_dbgfs_u64_ro_fops);
+	debugfs_create_file("async_timeout_count", 0444, d,
+			    &s->async_timeout_count, &cmh_dbgfs_u64_ro_fops);
+}
+
+/* -- Config directory: timeout tuning ---------------------------------- */
+
+static void create_config_dir(struct dentry *parent)
+{
+	struct dentry *d;
+
+	d = debugfs_create_dir("config", parent);
+	dbgfs.config = d;
+
+	/* TM timeouts */
+	debugfs_create_u32("async_timeout_ms",   0644, d,
+			   cmh_tm_timeout_async_ptr());
+	debugfs_create_u32("vcq_timeout_ms",     0644, d,
+			   cmh_tm_timeout_vcq_ptr());
+	debugfs_create_u32("slow_op_timeout_ms", 0644, d,
+			   cmh_tm_timeout_slow_op_ptr());
+	debugfs_create_u32("drain_timeout_ms",   0644, d,
+			   cmh_tm_timeout_drain_ptr());
+
+	/* RH watchdog */
+	debugfs_create_u32("watchdog_ms",        0644, d,
+			   cmh_rh_timeout_watchdog_ptr());
+
+	/*
+	 * Subsystem tunables publish themselves here via
+	 * cmh_debugfs_config_u32() as they come up, so this core file does
+	 * not reference per-algorithm symbols.
+	 */
+
+	/* TM queue depth */
+	debugfs_create_u32("cmq_max_depth", 0644, d,
+			   cmh_tm_cmq_max_depth_ptr());
+}
+
+/* -- Public Interface ------------------------------------------------------ */
+
+/**
+ * cmh_debugfs_init() - Create debugfs directory hierarchy for CMH
+ * @cfg: Platform configuration containing mailbox count and register bases.
+ *
+ * Allocates per-mailbox statistics and creates the /sys/kernel/debug/cmh/
+ * tree with per-mailbox counters, fault-injection files, and transaction
+ * manager statistics.  debugfs is optional; failure to create entries does
+ * not prevent module initialisation.
+ */
+void cmh_debugfs_init(struct cmh_config *cfg)
+{
+	u32 mbx_count = cfg->mbx_count;
+	u32 i;
+
+	dbgfs.root = debugfs_create_dir("cmh", NULL);
+	if (IS_ERR_OR_NULL(dbgfs.root)) {
+		if (!IS_ERR(dbgfs.root))
+			dev_warn(cmh_dev(), "debugfs: creation returned NULL -- counters disabled\n");
+		else
+			dev_warn(cmh_dev(), "debugfs: creation failed (rc=%ld) -- counters disabled\n",
+				 PTR_ERR(dbgfs.root));
+		dbgfs.root = NULL;
+		return;  /* debugfs is optional -- never fail module init */
+	}
+
+	dbgfs.mbx = kcalloc(mbx_count, sizeof(*dbgfs.mbx), GFP_KERNEL);
+	if (!dbgfs.mbx) {
+		debugfs_remove_recursive(dbgfs.root);
+		dbgfs.root = NULL;
+		return;
+	}
+	dbgfs.mbx_count = mbx_count;
+	dbgfs.cfg = cfg;
+
+	for (i = 0; i < mbx_count; i++)
+		create_mbx_dir(i, dbgfs.root);
+
+	create_tm_dir(dbgfs.root);
+
+	create_config_dir(dbgfs.root);
+
+	dev_dbg(cmh_dev(), "debugfs: initialized (%u mailboxes)\n", mbx_count);
+}
+
+/**
+ * cmh_debugfs_cleanup() - Remove all CMH debugfs entries
+ *
+ * Tears down the /sys/kernel/debug/cmh/ tree and frees per-mailbox
+ * statistics memory.  Safe to call even if cmh_debugfs_init() was never
+ * called or failed.
+ */
+void cmh_debugfs_cleanup(void)
+{
+	debugfs_remove_recursive(dbgfs.root);
+	dbgfs.root = NULL;
+	dbgfs.config = NULL;
+	kfree(dbgfs.mbx);
+	dbgfs.mbx = NULL;
+	dbgfs.mbx_count = 0;
+	dbgfs.cfg = NULL;
+	dev_dbg(cmh_dev(), "debugfs: cleaned up\n");
+}
+
+/**
+ * cmh_debugfs_config_u32() - Publish a subsystem tunable in config/
+ * @name: debugfs file name
+ * @val:  pointer to the u32 tunable (must outlive the debugfs tree)
+ *
+ * Lets a subsystem register its own runtime tunable in the shared
+ * config/ directory as it comes up, so this core debugfs file
+ * never references per-algorithm symbols -- each algorithm driver stays
+ * self-contained.  A no-op if debugfs is unavailable.
+ */
+void cmh_debugfs_config_u32(const char *name, u32 *val)
+{
+	if (dbgfs.config)
+		debugfs_create_u32(name, 0644, dbgfs.config, val);
+}
+
+/**
+ * cmh_debugfs_mbx_stats() - Return per-mailbox statistics pointer
+ * @mbx_idx: Zero-based mailbox index.
+ *
+ * Return: Pointer to the statistics structure for @mbx_idx, or NULL if
+ *         debugfs is disabled or @mbx_idx is out of range.
+ */
+struct cmh_mbx_stats *cmh_debugfs_mbx_stats(u32 mbx_idx)
+{
+	if (!dbgfs.mbx || mbx_idx >= dbgfs.mbx_count)
+		return NULL;
+	return &dbgfs.mbx[mbx_idx];
+}
+
+/**
+ * cmh_debugfs_tm_stats() - Return transaction manager statistics pointer
+ *
+ * Return: Pointer to the singleton TM statistics structure.  The pointer
+ *         is always valid (points to static storage).
+ */
+struct cmh_tm_stats *cmh_debugfs_tm_stats(void)
+{
+	return &dbgfs.tm;
+}
diff --git a/drivers/crypto/cmh/cmh_dma.c b/drivers/crypto/cmh/cmh_dma.c
new file mode 100644
index 000000000000..10914fcd3ca9
--- /dev/null
+++ b/drivers/crypto/cmh/cmh_dma.c
@@ -0,0 +1,354 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- DMA Operations
+ *
+ * Implements the cmh_dma.h interface using the kernel DMA API
+ * (dma_map_single, dma_alloc_coherent, etc.).
+ *
+ * Scatterlist linearization rationale
+ * ------------------------------------
+ * The eSW firmware supports SCATTERGATHER commands for all core
+ * types (AES_CMD_SCATTERGATHER, SM4_CMD_SCATTERGATHER,
+ * CCP_CMD_SCATTERGATHER, HC_CMD_GATHER), using a proprietary
+ * linked-list-item (LLI) descriptor chain format, built from a kernel
+ * scatterlist by cmh_dma_build_sg() for the hash gather command.
+ *
+ * For symmetric cipher and AEAD commands, the LKM currently
+ * linearizes scatterlist input into contiguous bounce buffers via
+ * scatterwalk_map_and_copy() rather than building LLI chains from
+ * kernel scatterlists.  This is a deliberate first-submission
+ * simplification with a concrete technical justification:
+ *
+ *   - The hash SG path is unidirectional (DMA_TO_DEVICE gather only).
+ *     Skcipher and AEAD require bidirectional handling: separate src
+ *     and dst scatterlists (which may alias for in-place operations),
+ *     plus AAD and authentication tag regions with distinct DMA
+ *     directions and alignment constraints.
+ *   - The CMH LLI descriptors (struct dma_scattergather_item: u64
+ *     lli/src/dst/len, 32-bit lengths) need only natural alignment,
+ *     and data buffer addresses have no hardware alignment
+ *     requirement.  Direct SG-to-LLI translation still needs separate
+ *     chains for src, dst, AAD and tag and handling of aliased
+ *     (in-place) lists -- substantially more complex than the
+ *     unidirectional hash gather case.
+ *   - Each skcipher/AEAD driver caps linearization (32 MiB for
+ *     skcipher, 1 MiB of AAD plus payload for AEAD) and rejects
+ *     larger requests with -EINVAL.
+ *     In practice, crypto API callers (dm-crypt, IPsec, kernel TLS)
+ *     send page-sized or smaller buffers, so the bounce allocation
+ *     is typically <= PAGE_SIZE and succeeds even under GFP_ATOMIC.
+ *
+ * This linearization pattern is consistent with other upstream HW
+ * crypto drivers that use bounce buffers in their initial
+ * submissions (e.g. ccree, sa2ul, omap-aes).
+ */
+
+#include <linux/kernel.h>
+#include <linux/slab.h>
+#include <linux/dma-mapping.h>
+#include <linux/platform_device.h>
+#include <linux/overflow.h>
+#include <linux/string.h>
+
+#include "cmh_dma.h"
+
+/* Module-global device pointer, set in cmh_dma_init() */
+static struct device *cmh_device;
+
+/**
+ * cmh_dma_init() - Initialize the standard DMA backend
+ * @pdev: Platform device providing the struct device for DMA ops
+ *
+ * Stores the device pointer for use by all DMA wrapper functions.
+ *
+ * Return: 0 (always succeeds for the standard backend).
+ */
+int cmh_dma_init(struct platform_device *pdev)
+{
+	cmh_device = &pdev->dev;
+	return 0;
+}
+
+/**
+ * cmh_dma_cleanup() - Tear down the standard DMA backend
+ *
+ * Clears the stored device pointer.
+ */
+void cmh_dma_cleanup(void)
+{
+	cmh_device = NULL;
+}
+
+/**
+ * cmh_dev() - Return the platform device pointer
+ *
+ * Return: struct device pointer, or NULL outside probe/remove lifecycle.
+ */
+struct device *cmh_dev(void)
+{
+	return cmh_device;
+}
+
+/* -- Streaming DMA -------------------------------------------------------- */
+
+/**
+ * cmh_dma_map_single() - Map a kernel buffer for streaming DMA
+ * @buf:  Kernel virtual address
+ * @size: Buffer length in bytes
+ * @dir:  DMA direction
+ *
+ * Return: DMA address, or a DMA_MAPPING_ERROR value on failure.
+ */
+dma_addr_t cmh_dma_map_single(void *buf, size_t size,
+			      enum dma_data_direction dir)
+{
+	return dma_map_single(cmh_device, buf, size, dir);
+}
+
+/**
+ * cmh_dma_unmap_single() - Unmap a streaming DMA buffer
+ * @addr: DMA address returned by cmh_dma_map_single()
+ * @size: Buffer length in bytes
+ * @dir:  DMA direction (must match the map call)
+ */
+void cmh_dma_unmap_single(dma_addr_t addr, size_t size,
+			  enum dma_data_direction dir)
+{
+	dma_unmap_single(cmh_device, addr, size, dir);
+}
+
+/**
+ * cmh_dma_sync_for_cpu() - Sync a DMA buffer for CPU access
+ * @addr: DMA address of the mapped buffer
+ * @size: Region length in bytes
+ * @dir:  DMA direction
+ */
+void cmh_dma_sync_for_cpu(dma_addr_t addr, size_t size,
+			  enum dma_data_direction dir)
+{
+	dma_sync_single_for_cpu(cmh_device, addr, size, dir);
+}
+
+/**
+ * cmh_dma_sync_for_device() - Sync a DMA buffer for device access
+ * @addr: DMA address of the mapped buffer
+ * @size: Region length in bytes
+ * @dir:  DMA direction
+ */
+void cmh_dma_sync_for_device(dma_addr_t addr, size_t size,
+			     enum dma_data_direction dir)
+{
+	dma_sync_single_for_device(cmh_device, addr, size, dir);
+}
+
+/**
+ * cmh_dma_map_error() - Check whether a DMA mapping failed
+ * @addr: DMA address to check
+ *
+ * Return: Non-zero if @addr indicates a mapping error.
+ */
+int cmh_dma_map_error(dma_addr_t addr)
+{
+	return dma_mapping_error(cmh_device, addr);
+}
+
+/* -- Coherent DMA --------------------------------------------------------- */
+
+/**
+ * cmh_dma_alloc() - Allocate coherent DMA memory
+ * @size:   Allocation size in bytes
+ * @handle: Output DMA address
+ * @gfp:    GFP allocation flags
+ *
+ * Return: Kernel virtual address, or NULL on failure.
+ */
+void *cmh_dma_alloc(size_t size, dma_addr_t *handle, gfp_t gfp)
+{
+	return dma_alloc_coherent(cmh_device, size, handle, gfp);
+}
+
+/**
+ * cmh_dma_free() - Free coherent DMA memory
+ * @size:   Allocation size (must match cmh_dma_alloc)
+ * @virt:   Kernel virtual address
+ * @handle: DMA address
+ */
+void cmh_dma_free(size_t size, void *virt, dma_addr_t handle)
+{
+	dma_free_coherent(cmh_device, size, virt, handle);
+}
+
+/* -- Buffer write helpers ------------------------------------------------- */
+
+/**
+ * cmh_dma_write() - Copy data into a DMA buffer
+ * @dst: Destination (from cmh_dma_alloc)
+ * @src: Source kernel buffer
+ * @len: Byte count
+ */
+void cmh_dma_write(void *dst, const void *src, size_t len)
+{
+	memcpy(dst, src, len);
+}
+
+/**
+ * cmh_dma_fence() - No-op on standard DMA API platforms (coherent)
+ * @ptr: Unused -- present for interface compatibility
+ */
+void cmh_dma_fence(void *ptr)
+{
+	/* Standard DMA API: coherent memory, no cross-slave fence needed */
+}
+
+/**
+ * cmh_dma_zero() - Zero a DMA buffer
+ * @dst: Destination (from cmh_dma_alloc)
+ * @len: Byte count
+ */
+void cmh_dma_zero(void *dst, size_t len)
+{
+	memset(dst, 0, len);
+}
+
+/**
+ * cmh_dma_build_sg() - Build a scatter-gather DMA mapping
+ * @bufs: Array of buffer descriptors to map
+ * @count: Number of entries in @bufs
+ * @gfp: GFP flags for memory allocation
+ *
+ * Allocates a streaming-DMA descriptor array and maps each buffer in @bufs
+ * for DMA-to-device transfer, filling CMH eSW-format scatter-gather
+ * descriptors with linked-list pointers.
+ *
+ * The descriptor array uses streaming DMA (kmalloc + dma_map_single) rather
+ * than dma_alloc_coherent so that cmh_dma_free_sg() -- which calls
+ * dma_unmap_single + kfree -- is safe from any context including BH-disabled
+ * completion callbacks.
+ *
+ * Return: Pointer to the allocated cmh_sg_map on success, NULL on failure.
+ */
+struct cmh_sg_map *cmh_dma_build_sg(const struct cmh_dma_buf *bufs, u32 count,
+				    gfp_t gfp)
+{
+	struct cmh_sg_map *sgm;
+	u32 i;
+
+	if (!count)
+		return NULL;
+
+	sgm = kzalloc(struct_size(sgm, bufs, count), gfp);
+	if (!sgm)
+		return NULL;
+
+	sgm->count = count;
+	sgm->items_size = array_size(count, sizeof(*sgm->items));
+	if (sgm->items_size == SIZE_MAX)
+		goto err_free_sgm;
+
+	/*
+	 * Allocate descriptor array with kmalloc and map for streaming DMA.
+	 * We map first to obtain items_dma (needed for .lli pointers),
+	 * then sync-for-cpu, fill descriptors, and sync-for-device.
+	 *
+	 * The eSW SG walker (struct dma_scattergather_item: u64 lli/src/dst/
+	 * len) requires only natural u64/4-byte alignment of the descriptor
+	 * and its LLI chain pointers -- there is no 64-byte-per-descriptor
+	 * requirement -- so a plain kzalloc (>= ARCH_KMALLOC_MINALIGN) is
+	 * sufficient and DMA-safe.
+	 */
+	sgm->items = kzalloc(sgm->items_size, gfp);
+	if (!sgm->items)
+		goto err_free_sgm;
+
+	sgm->items_dma = cmh_dma_map_single(sgm->items, sgm->items_size,
+					    DMA_TO_DEVICE);
+	if (cmh_dma_map_error(sgm->items_dma))
+		goto err_free_items;
+
+	/* Map each source buffer for device read */
+	for (i = 0; i < count; i++) {
+		dma_addr_t dma;
+
+		if (!bufs[i].len)
+			goto err_unmap;
+		sgm->bufs[i].len = bufs[i].len;
+		dma = cmh_dma_map_single(bufs[i].data, bufs[i].len,
+					 DMA_TO_DEVICE);
+		if (cmh_dma_map_error(dma))
+			goto err_unmap;
+		sgm->bufs[i].dma = dma;
+	}
+
+	/*
+	 * Reclaim CPU ownership of the descriptor buffer.  After
+	 * dma_map_single the device owns the mapping; we must call
+	 * sync_for_cpu before writing regardless of direction.  The
+	 * direction matches the original mapping (DMA_TO_DEVICE) --
+	 * this tells the DMA layer which cache operations apply:
+	 * invalidate so the CPU sees coherent data before we fill
+	 * the SG descriptors and later sync_for_device.
+	 */
+	cmh_dma_sync_for_cpu(sgm->items_dma, sgm->items_size,
+			     DMA_TO_DEVICE);
+
+	/* Fill CMH eSW SG descriptors */
+	for (i = 0; i < count; i++) {
+		u64 lli_val;
+
+		if (i + 1 < count)
+			lli_val = (u64)(sgm->items_dma +
+				(i + 1) * sizeof(*sgm->items));
+		else
+			lli_val = 0;
+
+		sgm->items[i].lli = lli_val;
+		sgm->items[i].src = (u64)sgm->bufs[i].dma;
+		sgm->items[i].dst = 0;
+		sgm->items[i].len = (u64)bufs[i].len;
+	}
+
+	/* Flush descriptor writes to device */
+	cmh_dma_sync_for_device(sgm->items_dma, sgm->items_size,
+				DMA_TO_DEVICE);
+
+	return sgm;
+
+err_unmap:
+	while (i--)
+		cmh_dma_unmap_single(sgm->bufs[i].dma,
+				     sgm->bufs[i].len, DMA_TO_DEVICE);
+	cmh_dma_unmap_single(sgm->items_dma, sgm->items_size,
+			     DMA_TO_DEVICE);
+err_free_items:
+	kfree(sgm->items);
+err_free_sgm:
+	kfree(sgm);
+	return NULL;
+}
+
+/**
+ * cmh_dma_free_sg() - Unmap and free a scatter-gather mapping
+ * @sgm: Scatter-gather mapping created by cmh_dma_build_sg(), or NULL
+ *
+ * Unmaps all DMA-mapped buffers, unmaps and frees the descriptor array,
+ * and releases the cmh_sg_map structure.  Safe to call from any context
+ * (including BH-disabled completion callbacks) because it uses only
+ * dma_unmap_single + kfree -- no vunmap/dma_free_coherent.
+ */
+void cmh_dma_free_sg(struct cmh_sg_map *sgm)
+{
+	u32 i;
+
+	if (!sgm)
+		return;
+
+	for (i = 0; i < sgm->count; i++)
+		cmh_dma_unmap_single(sgm->bufs[i].dma,
+				     sgm->bufs[i].len, DMA_TO_DEVICE);
+
+	cmh_dma_unmap_single(sgm->items_dma, sgm->items_size,
+			     DMA_TO_DEVICE);
+	kfree(sgm->items);
+	kfree(sgm);
+}
diff --git a/drivers/crypto/cmh/cmh_main.c b/drivers/crypto/cmh/cmh_main.c
new file mode 100644
index 000000000000..d02b758cba02
--- /dev/null
+++ b/drivers/crypto/cmh/cmh_main.c
@@ -0,0 +1,386 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- Platform Driver Entry and Exit
+ *
+ * Responsibilities:
+ *   - Match "rambus,cmh-v1030" DT node via platform_driver
+ *   - Parse device-tree properties via cmh_config_init()
+ *   - ioremap the SIC region
+ *   - Verify CMH boot status (sanity check)
+ *   - Compute per-instance register bases
+ *   - Initialize MBX queues (MQI)
+ *   - Start Transaction Manager kthread
+ *   - Register Response Handler IRQ
+ *   - Register the algorithms with the kernel crypto API
+ *   - Clean up in reverse order on exit or error
+ */
+
+#include <linux/atomic.h>
+#include <linux/module.h>
+#include <linux/kernel.h>
+#include <linux/slab.h>
+#include <linux/io.h>
+#include <linux/clk.h>
+#include <linux/gpio/consumer.h>
+#include <linux/dma-mapping.h>
+#include <linux/platform_device.h>
+#include <linux/of.h>
+
+#include "cmh.h"
+#include "cmh_dma.h"
+#include "cmh_mqi.h"
+#include "cmh_txn.h"
+#include "cmh_rh.h"
+#include "cmh_registers.h"
+#include "cmh_debugfs.h"
+#include "cmh_sysfs.h"
+
+#include <linux/iopoll.h>
+
+#ifdef CONFIG_CRYPTO_DEV_CMH_DEBUG
+static bool skip_fw_check;
+module_param(skip_fw_check, bool, 0444);
+MODULE_PARM_DESC(skip_fw_check,
+		 "[debug] Skip the eSW boot status check and the mailbox FLUSH fence at probe (default: false)");
+#else
+#define skip_fw_check false
+#endif
+
+/* SIC Sanity Check */
+
+static int cmh_check_sic(struct cmh_config *cfg)
+{
+	const u32 ready = SIC_SW_BOOT_STATUS_MISSION |
+			  SIC_SW_BOOT_STATUS_MISSION2;
+	u32 boot_status;
+	u32 sw_boot;
+	int ret;
+
+	boot_status = cmh_reg_read32(cfg->sic_mapped, R_SIC_BOOT_STATUS);
+
+	if ((boot_status & SIC_BOOT_STATUS_MASK) != SIC_BOOT_STATUS_PASS) {
+		dev_err(cmh_dev(), "SIC boot status check failed (0x%02x != 0x%02x)\n",
+			boot_status & SIC_BOOT_STATUS_MASK, SIC_BOOT_STATUS_PASS);
+		return -EIO;
+	}
+
+	/*
+	 * Wait for eSW readiness: MISSION signals the primary VCQ engine,
+	 * MISSION2 the sidecar engine (set asynchronously).  The driver
+	 * uses both, so require both bits.
+	 */
+	ret = read_poll_timeout(ioread32, sw_boot,
+				(sw_boot & ready) == ready,
+				1000,
+				(unsigned long)cfg->fw_ready_timeout_ms * 1000UL,
+				false,
+				cfg->sic_mapped + R_SIC_SW_BOOT_STATUS);
+	if (ret) {
+		sw_boot = cmh_reg_read32(cfg->sic_mapped, R_SIC_SW_BOOT_STATUS);
+		dev_err(cmh_dev(), "CMH eSW not ready (sw_boot_status=0x%08x, timeout=%ums)\n",
+			sw_boot, cfg->fw_ready_timeout_ms);
+		return -ETIMEDOUT;
+	}
+
+	return 0;
+}
+
+/* Module Init -- platform driver probe */
+
+/*
+ * The transaction manager and response handler keep file-scope singleton
+ * state (queues, mailbox array), so only one CMH instance may be bound at
+ * a time.  Claim the singleton on probe and release it via devres on both
+ * probe failure and remove.
+ */
+static atomic_t cmh_bound = ATOMIC_INIT(0);
+
+static void cmh_release_instance(void *data)
+{
+	/*
+	 * Store-release so a concurrent probe of another node that acquires
+	 * the guard via atomic_cmpxchg() observes this instance's teardown.
+	 */
+	atomic_set_release(&cmh_bound, 0);
+}
+
+static int cmh_probe(struct platform_device *pdev)
+{
+	struct cmh_device *dev;
+	struct cmh_config *cfg;
+	struct clk_bulk_data *clks;
+	struct gpio_desc *reset;
+	unsigned int i;
+	int ret;
+
+	if (atomic_cmpxchg(&cmh_bound, 0, 1))
+		return dev_err_probe(&pdev->dev, -EBUSY,
+				     "only one CMH instance is supported\n");
+	ret = devm_add_action_or_reset(&pdev->dev, cmh_release_instance,
+				       NULL);
+	if (ret)
+		return ret;
+
+	dev = devm_kzalloc(&pdev->dev, sizeof(*dev), GFP_KERNEL);
+	if (!dev)
+		return -ENOMEM;
+
+	dev->dev = &pdev->dev;
+	cfg = &dev->config;
+
+	/* Declare DMA addressing capability */
+	ret = dma_set_mask_and_coherent(&pdev->dev, DMA_BIT_MASK(64));
+	if (ret) {
+		ret = dev_err_probe(&pdev->dev, ret,
+				    "dma_set_mask_and_coherent failed\n");
+		goto err_free_dev;
+	}
+
+	/* Initialize DMA backend (standard API or FPGA pool) */
+	ret = cmh_dma_init(pdev);
+	if (ret) {
+		ret = dev_err_probe(&pdev->dev, ret, "DMA init failed\n");
+		goto err_free_dev;
+	}
+
+	/* Step 1: Parse and validate configuration (DT + module params) */
+	ret = cmh_config_init(cfg, pdev);
+	if (ret)
+		goto err_dma_init;
+
+	/*
+	 * Enable functional clocks and release reset.  Both are optional --
+	 * integrations where a separate management/power controller owns the
+	 * clock and reset lines describe neither, and these calls are
+	 * no-ops.  The hub gates its clocks internally, but
+	 * clk_disable_unused() would otherwise gate an always-on input the
+	 * driver never claimed, so the driver enables whatever clocks the
+	 * device tree provides.  Clocks come up before reset is released (a
+	 * hard reset requires an active clock) and before any SIC register
+	 * access.  The reset line is acquired already deasserted; the driver
+	 * does not drive a reset pulse -- the eSW boots independently and its
+	 * mission-mode readiness is verified separately below, and no in-tree
+	 * platform wires this line for a reset sequence to be exercised.
+	 * devm unwinds both on remove or probe error.
+	 */
+	ret = devm_clk_bulk_get_all_enabled(&pdev->dev, &clks);
+	if (ret < 0) {
+		ret = dev_err_probe(&pdev->dev, ret,
+				    "failed to enable clocks\n");
+		goto err_dma_init;
+	}
+
+	reset = devm_gpiod_get_optional(&pdev->dev, "reset", GPIOD_OUT_LOW);
+	if (IS_ERR(reset)) {
+		ret = dev_err_probe(&pdev->dev, PTR_ERR(reset),
+				    "failed to acquire reset GPIO\n");
+		goto err_dma_init;
+	}
+
+	/* Step 2: ioremap the SIC region */
+	cfg->sic_mapped = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(cfg->sic_mapped)) {
+		ret = dev_err_probe(&pdev->dev, PTR_ERR(cfg->sic_mapped),
+				    "ioremap failed for SIC region\n");
+		cfg->sic_mapped = NULL;
+		goto err_dma_init;
+	}
+
+	/* Step 3: Verify CMH is alive */
+	if (!skip_fw_check) {
+		ret = cmh_check_sic(cfg);
+		if (ret)
+			goto err_dma_init;
+	}
+
+	/* Step 3.5: Discover crypto cores from the SIC CORE_ENABLE register */
+	ret = cmh_config_discover_cores(cfg);
+	if (ret)
+		goto err_dma_init;
+
+	/* Step 4: Compute per-instance register bases */
+	for (i = 0; i < cfg->mbx_count; i++) {
+		struct cmh_mbx_config *m = &cfg->mailboxes[i];
+
+		m->reg_base = cmh_mbx_instance_base(cfg->sic_mapped,
+						    m->instance);
+
+		dev_dbg(cmh_dev(), "mbx[%u] instance=%u reg_base=%p\n",
+			i, m->instance, m->reg_base);
+	}
+
+	cmh_debugfs_init(cfg);
+
+	/* Initialise mailbox queue interface */
+	/* Fence the mailboxes unless the eSW may not be running yet. */
+	ret = cmh_mqi_init(cfg, !skip_fw_check);
+	if (ret)
+		goto err_mqi_init;
+
+	/* Initialise transaction manager */
+	ret = cmh_tm_init(cfg);
+	if (ret)
+		goto err_tm_init;
+
+	/* Initialise response handler */
+	ret = cmh_rh_init(cfg);
+	if (ret)
+		goto err_rh_init;
+
+	platform_set_drvdata(pdev, dev);
+
+	return 0;
+
+err_rh_init:
+	cmh_tm_cleanup();
+err_tm_init:
+	cmh_mqi_cleanup(cfg);
+err_mqi_init:
+	cmh_debugfs_cleanup();
+err_dma_init:
+	cmh_dma_cleanup();
+err_free_dev:
+	return ret;
+}
+
+/* Module Exit -- platform driver remove */
+
+static void cmh_remove(struct platform_device *pdev)
+{
+	struct cmh_device *dev = platform_get_drvdata(pdev);
+	struct cmh_config *cfg;
+
+	if (!dev)
+		return;
+
+	cfg = &dev->config;
+
+	/*
+	 * Stop the TM producer before the RH state it consults is freed;
+	 * in-flight work completes through the RH until cmh_rh_cleanup().
+	 */
+	cmh_tm_stop();
+	cmh_rh_cleanup(cfg);
+	cmh_tm_cleanup();
+	cmh_mqi_cleanup(cfg);
+	cmh_debugfs_cleanup();
+	cmh_dma_cleanup();
+}
+
+static const struct of_device_id cmh_of_match[] = {
+	{ .compatible = "rambus,cmh-v1030" },
+	{ /* sentinel */ }
+};
+MODULE_DEVICE_TABLE(of, cmh_of_match);
+
+/*
+ * PM suspend/resume.
+ *
+ * Suspend: drain the TM first (while the RH is still active and can
+ * deliver completions for in-flight transactions), then quiesce the
+ * RH (cancel watchdog, mask HW interrupts).  This ordering lets the
+ * drain_timeout_ms wait in cmh_tm_quiesce() succeed -- if we suspended
+ * the RH first, no completions would be delivered.  In-flight work is
+ * never cancelled (this HW cannot stop its DMA): if it has not finished
+ * by the deadline, the suspend is refused with -EBUSY.
+ *
+ * IRQ handlers remain registered (standard PM pattern: the kernel
+ * disables the IRQ lines during suspend, no need to free/re-request).
+ *
+ * Resume: re-check the SIC/SW boot status, re-synchronise the RH
+ * with hardware (head positions, interrupt masks, watchdog), then
+ * restart the TM kthread.
+ */
+
+static int cmh_suspend(struct device *dev)
+{
+	struct cmh_device *cmh = dev_get_drvdata(dev);
+	int ret;
+
+	if (!cmh)
+		return 0;
+
+	/* Refused (-EBUSY) while work is still in flight on the device. */
+	ret = cmh_tm_quiesce();
+	if (ret)
+		return ret;
+	cmh_rh_suspend(&cmh->config);
+	return 0;
+}
+
+static int cmh_resume(struct device *dev)
+{
+	struct cmh_device *cmh = dev_get_drvdata(dev);
+	int ret;
+
+	if (!cmh)
+		return 0;
+
+	ret = cmh_check_sic(&cmh->config);
+	if (ret) {
+		dev_err(dev, "resume: CMH eSW health check failed (%d)\n",
+			ret);
+		return ret;
+	}
+
+	/*
+	 * cmh_rh_resume() is void: it only re-syncs MMIO head pointers,
+	 * clears stale interrupt status bits (W1C), re-enables interrupt
+	 * masks, and re-arms the watchdog timer -- none of which can fail
+	 * after the SIC health check above has confirmed HW accessibility.
+	 */
+	cmh_rh_resume(&cmh->config);
+
+	ret = cmh_tm_resume();
+	if (ret) {
+		dev_err(dev, "resume: TM restart failed (%d)\n", ret);
+		return ret;
+	}
+	return 0;
+}
+
+static DEFINE_SIMPLE_DEV_PM_OPS(cmh_pm_ops,
+				cmh_suspend,
+				cmh_resume);
+
+/*
+ * Runtime PM is intentionally not implemented.  The CMH hardware does
+ * not expose HLOS-accessible clock gates or power domains -- the eSW
+ * firmware manages HW power state independently.  There is no mechanism
+ * for the kernel to idle, gate clocks, or power down the accelerator
+ * block from HLOS.  If a future platform variant exposes power control
+ * to HLOS (e.g. via a SCMI power domain), runtime PM support can be
+ * added at that time using SET_RUNTIME_PM_OPS and pm_runtime_get/put
+ * around VCQ submission paths.
+ *
+ * System sleep (suspend/resume) is supported via DEFINE_SIMPLE_DEV_PM_OPS
+ * above: suspend quiesces the TM and masks IRQs; resume re-verifies
+ * eSW health (SIC status) and restarts the TM thread.
+ */
+
+static struct platform_driver cmh_driver = {
+	.probe      = cmh_probe,
+	.remove     = cmh_remove,
+	.driver = {
+		.name           = "cmh",
+		.of_match_table = cmh_of_match,
+		.dev_groups     = cmh_sysfs_groups,
+		.pm             = pm_sleep_ptr(&cmh_pm_ops),
+		/*
+		 * Removal tears down the shared device state that live
+		 * transforms and in-flight requests use.  Module references
+		 * keep rmmod away while any transform exists, but sysfs
+		 * unbind would not wait, so it is disabled.
+		 */
+		.suppress_bind_attrs = true,
+	},
+};
+
+module_platform_driver(cmh_driver);
+
+MODULE_DESCRIPTION("Rambus CryptoManager Hub (CMH) hardware crypto accelerator");
+MODULE_AUTHOR("Alex Ousherovitch <aousherovitch@rambus.com>");
+MODULE_AUTHOR("Saravanakrishnan Krishnamoorthy <skrishnamoorthy@rambus.com>");
+MODULE_AUTHOR("Joel Wittenauer <Joel.Wittenauer@cryptography.com>");
+MODULE_LICENSE("GPL");
diff --git a/drivers/crypto/cmh/cmh_mqi.c b/drivers/crypto/cmh/cmh_mqi.c
new file mode 100644
index 000000000000..d4edd96093dd
--- /dev/null
+++ b/drivers/crypto/cmh/cmh_mqi.c
@@ -0,0 +1,457 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- Mailbox Queue Initializer
+ *
+ * Responsibilities:
+ *   - Allocate queue buffers for each configured mailbox
+ *   - Execute the MBX lock/setup/enable register sequence
+ *   - Readback-verify all critical register writes
+ *   - Hold lock for MBX lifetime (CMH eSW requires it for host access)
+ *   - Clean up (flush + unlock + free) on exit or error
+ *
+ * Register sequence per instance (per CMH MBX hardware specification):
+ *   1. Read R_MBX_LOCK -> non-zero = ownership token acquired
+ *   2. W1C stale R_MBX_INTERRUPT bits (avoids spurious error cascade)
+ *   3. Set R_MBX_INTERRUPT_MASK = MBX_IRQ_MASK
+ *   4. Write QUEUE_LO/HI, SLOTS, STRIDE (queue address + geometry)
+ *   5. Sync TAIL = HEAD (CMH eSW owns HEAD; avoids stale-queue parse)
+ *   6. Readback verify QUEUE_LO/HI/SLOTS/STRIDE
+ *   7. Write COMMAND = MBX_COMMAND_RUN
+ *   8. Lock stays held -- released only in teardown
+ */
+
+#include <linux/module.h>
+#include <linux/kernel.h>
+#include <linux/slab.h>
+#include <linux/delay.h>
+#include <linux/jiffies.h>
+#include <linux/io.h>
+#include <linux/ktime.h>
+
+#include "cmh_mqi.h"
+#include "cmh_dma.h"
+#include "cmh_registers.h"
+#include "cmh_config.h"
+
+/* MBX Lock / Unlock */
+
+/*
+ * Attempt to acquire the MBX hardware lock.
+ * Returns the lock token (non-zero) on success, 0 on timeout.
+ */
+static u32 cmh_mbx_lock(void __iomem *reg_base, u32 instance)
+{
+	unsigned long deadline = jiffies + msecs_to_jiffies(MBX_LOCK_TIMEOUT_MS);
+	u32 lock;
+
+	while (time_before(jiffies, deadline)) {
+		lock = cmh_reg_read32(reg_base, R_MBX_LOCK);
+		if (lock) {
+			dev_dbg(cmh_dev(), "mbx %u lock acquired (token=0x%08x)\n",
+				instance, lock);
+			return lock;
+		}
+		/* HW lock may be held by CMH eSW -- back off before retry */
+		usleep_range(MBX_LOCK_POLL_MIN_US, MBX_LOCK_POLL_MAX_US);
+	}
+
+	return 0;
+}
+
+/* Release the MBX lock: clear interrupt mask, write token back */
+static void cmh_mbx_unlock(void __iomem *reg_base, u32 lock_val)
+{
+	cmh_reg_write32(0, reg_base, R_MBX_INTERRUPT_MASK);
+	cmh_reg_write32(lock_val, reg_base, R_MBX_LOCK);
+}
+
+/* Register Readback Verification */
+
+static int cmh_verify_reg(void __iomem *base, u32 offset, u32 expected,
+			  const char *name, u32 instance)
+{
+	u32 actual = cmh_reg_read32(base, offset);
+
+	if (actual != expected) {
+		dev_err(cmh_dev(), "mbx %u %s readback mismatch: 0x%08x != 0x%08x\n",
+			instance, name, actual, expected);
+		return -EIO;
+	}
+	return 0;
+}
+
+/* Clear any stale interrupt bits left from a prior module lifecycle. */
+static void cmh_mbx_clear_stale_irqs(void __iomem *base, u32 instance)
+{
+	u32 stale = cmh_reg_read32(base, R_MBX_INTERRUPT);
+
+	if (stale) {
+		cmh_reg_write32(stale, base, R_MBX_INTERRUPT);
+		dev_dbg(cmh_dev(), "mbx %u cleared stale irq bits=0x%x\n",
+			instance, stale);
+	}
+}
+
+/* Read CMH eSW HEAD and set TAIL = HEAD so the queue appears empty. */
+static void cmh_mbx_sync_tail_to_head(void __iomem *base, u32 instance)
+{
+	u32 fw_head = cmh_reg_read32(base, R_MBX_QUEUE_HEAD);
+
+	cmh_reg_write32(fw_head, base, R_MBX_QUEUE_TAIL);
+	if (fw_head)
+		dev_dbg(cmh_dev(), "mbx %u synced tail=%u to fw head\n",
+			instance, fw_head);
+}
+
+/* Per-Mailbox Setup */
+
+/*
+ * Program and start a mailbox already locked by cmh_mqi_init() (step 1,
+ * acquiring exclusive access, and the probe-time FLUSH fence happen there).
+ * On failure the lock is released.
+ */
+static int cmh_mbx_setup_one(struct cmh_mbx_config *mbx)
+{
+	void __iomem *base = mbx->reg_base;
+	u32 addr_lo = lower_32_bits(mbx->dma_handle);
+	u32 addr_hi = upper_32_bits(mbx->dma_handle);
+	int ret;
+
+	/*
+	 * Step 1.5: Clear stale interrupt bits from a prior module lifecycle.
+	 *
+	 * After rmmod, the CMH eSW may leave ERROR_IRQ set in
+	 * R_MBX_INTERRUPT even though STATUS is IDLE.  If we enable
+	 * the mask first, the stale bits immediately trigger the
+	 * CMH eSW interrupt chain, which can cascade into ERROR
+	 * status before the first hash operation.  W1C-clear them first.
+	 */
+	cmh_mbx_clear_stale_irqs(base, mbx->instance);
+
+	/* Step 2: Program interrupt mask (enable DONE/ERROR interrupts) */
+	cmh_reg_write32(MBX_IRQ_MASK, base, R_MBX_INTERRUPT_MASK);
+
+	/* Step 3: Configure queue address (64-bit split) */
+	cmh_reg_write32(addr_lo, base, R_MBX_QUEUE_LO);
+	cmh_reg_write32(addr_hi, base, R_MBX_QUEUE_HI);
+
+	/* Step 4: Configure queue geometry */
+	cmh_reg_write32(mbx->slots_log2, base, R_MBX_QUEUE_SLOTS);
+	cmh_reg_write32(mbx->stride_log2, base, R_MBX_QUEUE_STRIDE);
+
+	/*
+	 * Step 5: Synchronise TAIL to CMH eSW's HEAD.
+	 *
+	 * R_MBX_QUEUE_HEAD is read-only from the host side -- only the
+	 * CMH eSW can write it.  On a fresh boot HEAD is 0; after an
+	 * rmmod/insmod cycle it retains the value from the previous
+	 * session (e.g. 44).  Writing 0 from the host is silently
+	 * dropped by the MBX HW.
+	 *
+	 * If we set TAIL=0 while HEAD=44 the CMH eSW sees a non-empty
+	 * queue (head != tail with wrap-around) and immediately tries
+	 * to load a VCQ at the old head offset into our freshly-zeroed
+	 * DMA buffer, causing an "Invalid VCQ" EFAULT -> ECHILD cascade.
+	 *
+	 * Fix: read HEAD and set TAIL = HEAD so the queue looks empty.
+	 */
+	cmh_mbx_sync_tail_to_head(base, mbx->instance);
+
+	/*
+	 * Step 6: Readback verify the critical queue registers before the
+	 * mailbox is enabled.  Enabling is the MBX_COMMAND_RUN write in
+	 * step 7 -- once it lands the CMH eSW acts on the queue, so the
+	 * configuration must be confirmed first.
+	 */
+	ret = cmh_verify_reg(base, R_MBX_QUEUE_LO, addr_lo,
+			     "QUEUE_LO", mbx->instance);
+	if (ret)
+		goto err_unlock;
+
+	ret = cmh_verify_reg(base, R_MBX_QUEUE_HI, addr_hi,
+			     "QUEUE_HI", mbx->instance);
+	if (ret)
+		goto err_unlock;
+
+	ret = cmh_verify_reg(base, R_MBX_QUEUE_SLOTS, mbx->slots_log2,
+			     "QUEUE_SLOTS", mbx->instance);
+	if (ret)
+		goto err_unlock;
+
+	ret = cmh_verify_reg(base, R_MBX_QUEUE_STRIDE, mbx->stride_log2,
+			     "QUEUE_STRIDE", mbx->instance);
+	if (ret)
+		goto err_unlock;
+
+	/* Step 7: Enable -- start the mailbox */
+	cmh_reg_write32(MBX_COMMAND_RUN, base, R_MBX_COMMAND);
+
+	/* Read status while we still hold the lock */
+	dev_dbg(cmh_dev(), "mbx %u setup: dma=0x%08x%08x slots=%u stride=%u status=0x%08x\n",
+		mbx->instance, addr_hi, addr_lo,
+		 mbx->slots_log2, mbx->stride_log2,
+		 cmh_reg_read32(base, R_MBX_STATUS));
+
+	/*
+	 * Lock stays held for the lifetime of this MBX session.
+	 *
+	 * mbx->lock_val is the ownership token returned by R_MBX_LOCK at
+	 * acquisition time.  The CMH eSW validates this token on every
+	 * register access and requires it to be written back to release.
+	 * It is NOT a transient mutex -- it persists until teardown.
+	 */
+	return 0;
+
+err_unlock:
+	cmh_mbx_unlock(base, mbx->lock_val);
+	mbx->lock_val = 0;
+	return ret;
+}
+
+/* Per-Mailbox Teardown */
+
+/*
+ * The eSW acknowledges FLUSH by clearing R_MBX_COMMAND after it has
+ * flushed every core and DMA engine bound to the mailbox and set HEAD =
+ * TAIL and the status to MBX_STATUS_IDLE.  Require all three: a command
+ * written while the eSW was still finishing an earlier one can be cleared
+ * by that earlier acknowledgment, and nothing is submitted meanwhile, so
+ * TAIL cannot move.
+ */
+static bool cmh_mbx_flush_acked(void __iomem *base)
+{
+	return !cmh_reg_read32(base, R_MBX_COMMAND) &&
+	       MBX_STATUS_CODE(cmh_reg_read32(base, R_MBX_STATUS)) ==
+	       MBX_STATUS_IDLE &&
+	       cmh_reg_read32(base, R_MBX_QUEUE_HEAD) ==
+	       cmh_reg_read32(base, R_MBX_QUEUE_TAIL);
+}
+
+/*
+ * cmh_mbx_flush_wait() - FLUSH a mailbox and wait for the eSW to acknowledge
+ * @mbx: Mailbox to flush
+ *
+ * Issues MBX_COMMAND_FLUSH and waits for the acknowledgment described at
+ * cmh_mbx_flush_acked(), which confirms that no DMA for this mailbox is
+ * outstanding.  This HW has no DMA-stop primitive, so a mailbox that does
+ * not acknowledge cannot be fenced: the result is recorded in
+ * @mbx->fenced and DMA memory the device may reach must then be kept, not
+ * freed.  An offline mailbox (the eSW has shut down) is not fenced either.
+ *
+ * The caller MUST have stopped the response handler first so that no
+ * completion races the flush.
+ *
+ * Return: true if the eSW acknowledged (or the mailbox was never set up).
+ */
+static bool cmh_mbx_flush_wait(struct cmh_mbx_config *mbx)
+{
+	void __iomem *base = mbx->reg_base;
+	ktime_t deadline;
+
+	if (!base) {
+		mbx->fenced = true;
+		return true;
+	}
+	if (MBX_STATUS_CODE(cmh_reg_read32(base, R_MBX_STATUS)) ==
+	    MBX_STATUS_OFFLINE)
+		goto unfenced;
+
+	cmh_reg_write32(MBX_COMMAND_FLUSH, base, R_MBX_COMMAND);
+	deadline = ktime_add_us(ktime_get(), MBX_FLUSH_TIMEOUT_US);
+	for (;;) {
+		if (cmh_mbx_flush_acked(base)) {
+			mbx->fenced = true;
+			return true;
+		}
+		if (ktime_after(ktime_get(), deadline))
+			break;
+		/* Cleared by an earlier command's acknowledgment: reissue. */
+		if (!cmh_reg_read32(base, R_MBX_COMMAND))
+			cmh_reg_write32(MBX_COMMAND_FLUSH, base,
+					R_MBX_COMMAND);
+		usleep_range(MBX_FLUSH_POLL_US, 2 * MBX_FLUSH_POLL_US);
+	}
+
+unfenced:
+	dev_err(cmh_dev(),
+		"mbx %u: FLUSH not acknowledged (status=0x%08x)\n",
+		mbx->instance, cmh_reg_read32(base, R_MBX_STATUS));
+	mbx->fenced = false;
+	return false;
+}
+
+static bool cmh_mbx_teardown_one(struct cmh_mbx_config *mbx)
+{
+	bool fenced;
+
+	if (!mbx->reg_base || !mbx->lock_val)
+		return true;
+
+	fenced = cmh_mbx_flush_wait(mbx);
+	if (!fenced)
+		dev_err(cmh_dev(), "mbx %u: keeping its DMA memory\n",
+			mbx->instance);
+	cmh_mbx_unlock(mbx->reg_base, mbx->lock_val);
+	mbx->lock_val = 0;
+	return fenced;
+}
+
+/**
+ * cmh_mqi_settle_all() - FLUSH every mailbox and wait for the engines to settle
+ * @cfg: Global device configuration
+ *
+ * FLUSHes each active mailbox and waits for the eSW to acknowledge, i.e.
+ * to quiesce its cores and DMA engines back to MBX_STATUS_IDLE, so no DMA
+ * is outstanding before in-flight buffers are released at teardown.  The
+ * per-mailbox result is recorded in cfg->mailboxes[i].fenced.  The caller
+ * must have stopped the response handler first, and the mailboxes must
+ * still be locked.
+ *
+ * Return: true if every mailbox acknowledged.
+ */
+bool cmh_mqi_settle_all(struct cmh_config *cfg)
+{
+	bool all = true;
+	u32 i;
+
+	if (!cfg)
+		return true;
+
+	for (i = 0; i < cfg->mbx_count; i++) {
+		if (!cmh_mbx_flush_wait(&cfg->mailboxes[i])) {
+			dev_err(cmh_dev(), "mbx %u: keeping its DMA memory\n",
+				cfg->mailboxes[i].instance);
+			all = false;
+		}
+	}
+	return all;
+}
+
+/* Public Interface */
+
+/**
+ * cmh_mqi_init() - Initialize all mailbox queues
+ * @cfg: CMH configuration describing the mailboxes to set up
+ * @fence: FLUSH each mailbox and require the acknowledgment first
+ *
+ * Locks each mailbox and, with @fence, FLUSHes it and requires the eSW to
+ * acknowledge before any DMA memory is allocated: a previous load of the
+ * driver may have left the device accessing memory it could not fence,
+ * and that memory (e.g. a fixed DMA pool) could otherwise be handed out
+ * again.  Then allocates the DMA queue buffers and executes the MBX
+ * setup/enable register sequence.  On failure, all successfully
+ * initialized mailboxes are torn down and buffers freed.
+ *
+ * Return: 0 on success, -EBUSY if a mailbox does not acknowledge the
+ *         fence, or another negative errno on failure.
+ */
+int cmh_mqi_init(struct cmh_config *cfg, bool fence)
+{
+	unsigned int i, j;
+	int ret;
+
+	/* Acquire exclusive access to each mailbox and fence it */
+	for (i = 0; i < cfg->mbx_count; i++) {
+		struct cmh_mbx_config *m = &cfg->mailboxes[i];
+
+		m->lock_val = cmh_mbx_lock(m->reg_base, m->instance);
+		if (!m->lock_val) {
+			dev_err(cmh_dev(), "mbx %u lock timeout after %u ms\n",
+				m->instance, MBX_LOCK_TIMEOUT_MS);
+			ret = -ETIMEDOUT;
+			goto err_unlock;
+		}
+		if (fence && !cmh_mbx_flush_wait(m)) {
+			dev_err(cmh_dev(),
+				"mbx %u: device not quiescent, not allocating DMA memory\n",
+				m->instance);
+			cmh_mbx_unlock(m->reg_base, m->lock_val);
+			m->lock_val = 0;
+			ret = -EBUSY;
+			goto err_unlock;
+		}
+	}
+
+	/* Allocate queue buffers */
+	for (i = 0; i < cfg->mbx_count; i++) {
+		struct cmh_mbx_config *m = &cfg->mailboxes[i];
+
+		m->virt_addr = cmh_dma_alloc(m->queue_size, &m->dma_handle,
+					     GFP_KERNEL);
+		if (!m->virt_addr) {
+			ret = -ENOMEM;
+			goto err_free_bufs;
+		}
+
+		dev_dbg(cmh_dev(), "mqi[%u] alloc %zu bytes @ virt=%pK dma=%pad\n",
+			i, m->queue_size, m->virt_addr, &m->dma_handle);
+	}
+
+	/* Set up and enable each mailbox */
+	for (i = 0; i < cfg->mbx_count; i++) {
+		ret = cmh_mbx_setup_one(&cfg->mailboxes[i]);
+		if (ret) {
+			dev_err(cmh_dev(), "mqi[%u] setup failed (rc=%d)\n",
+				i, ret);
+			goto err_teardown;
+		}
+	}
+
+	return 0;
+
+err_teardown:
+	for (j = 0; j < i; j++) {
+		/* Started: keep (leak) its queue unless the FLUSH is acked. */
+		if (!cmh_mbx_teardown_one(&cfg->mailboxes[j]))
+			cfg->mailboxes[j].virt_addr = NULL;
+	}
+err_free_bufs:
+	for (j = 0; j < cfg->mbx_count; j++) {
+		if (cfg->mailboxes[j].virt_addr)
+			cmh_dma_free(cfg->mailboxes[j].queue_size,
+				     cfg->mailboxes[j].virt_addr,
+				     cfg->mailboxes[j].dma_handle);
+		cfg->mailboxes[j].virt_addr = NULL;
+		cfg->mailboxes[j].dma_handle = 0;
+	}
+err_unlock:
+	/* Release the locks still held (zero lock_val = not held). */
+	for (j = 0; j < cfg->mbx_count; j++) {
+		struct cmh_mbx_config *m = &cfg->mailboxes[j];
+
+		if (m->lock_val) {
+			cmh_mbx_unlock(m->reg_base, m->lock_val);
+			m->lock_val = 0;
+		}
+	}
+	return ret;
+}
+
+/**
+ * cmh_mqi_cleanup() - Clean up all mailbox queues
+ * @cfg: CMH configuration describing the mailboxes to tear down
+ *
+ * Tears down each mailbox (flush + unlock) and frees the DMA queue
+ * buffers allocated by cmh_mqi_init().  The queue of a mailbox whose
+ * FLUSH the eSW did not acknowledge may still be read by the device, so
+ * it is leaked rather than freed.
+ */
+void cmh_mqi_cleanup(struct cmh_config *cfg)
+{
+	unsigned int i;
+
+	for (i = 0; i < cfg->mbx_count; i++) {
+		struct cmh_mbx_config *m = &cfg->mailboxes[i];
+
+		if (!cmh_mbx_teardown_one(m) && m->virt_addr)
+			dev_err(cmh_dev(),
+				"mbx %u: leaking its %zu-byte queue\n",
+				m->instance, m->queue_size);
+		else if (m->virt_addr)
+			cmh_dma_free(m->queue_size, m->virt_addr,
+				     m->dma_handle);
+		m->virt_addr = NULL;
+		m->dma_handle = 0;
+	}
+}
diff --git a/drivers/crypto/cmh/cmh_rh.c b/drivers/crypto/cmh/cmh_rh.c
new file mode 100644
index 000000000000..fadb860b8d7a
--- /dev/null
+++ b/drivers/crypto/cmh/cmh_rh.c
@@ -0,0 +1,1434 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- Response Handler
+ *
+ * IRQ-driven completion processing using request_threaded_irq():
+ *
+ *   Hardirq:  For each MBX, read R_MBX_INTERRUPT.  If any bit is set,
+ *             W1C-clear it and mark the MBX for threaded processing.
+ *             Return IRQ_WAKE_THREAD if any MBX had work.
+ *
+ *   Thread:   For each pending MBX, read R_MBX_QUEUE_HEAD.  Walk the
+ *             per-MBX transaction queue (oldest first): for every txn
+ *             whose last_vcq_id < new_head, check status, fire the
+ *             completion callback, and free the transaction object.
+ *
+ * The DT "rambus,cmh-v1030" node declares one interrupt per mailbox,
+ * matching the real CMH ch_sys_interrupt_mbx[N-1:0] topology.
+ * Each MBX gets its own Linux virq; the same hardirq/thread pair
+ * is registered for all of them.  The hardirq only touches the
+ * mailboxes routed to the line that fired; the thread then does a
+ * final poll of every mailbox, for robustness against coalesced or
+ * missed edges.  Without interrupts the watchdog polls instead.
+ *
+ * Recovery: an eSW error stops the mailbox (status ERROR, HEAD held).
+ * The failed transaction completes with the decoded error and RESTART
+ * skips it.  A failed multi-VCQ group, an unresponsive RESTART or a
+ * stalled ABORT escalates to FLUSH: the mailbox is closed to new
+ * submissions, and once the eSW acknowledges the FLUSH everything left
+ * on its queue completes with -ECANCELED and it reopens.  A mailbox that
+ * never acknowledges is wedged: its queue completes with -ETIMEDOUT, the
+ * DMA of those requests is quarantined, and it stays closed.
+ */
+
+#include <linux/module.h>
+#include <linux/kernel.h>
+#include <linux/interrupt.h>
+#include <linux/io.h>
+#include <linux/slab.h>
+#include <linux/atomic.h>
+#include <linux/of.h>
+#include <linux/of_irq.h>
+#include <linux/timer.h>
+#include <linux/jiffies.h>
+#include <linux/delay.h>
+#include <linux/ktime.h>
+
+#include "cmh_rh.h"
+#include "cmh_txn.h"
+#include "cmh_registers.h"
+#include "cmh_config.h"
+#include "cmh_debugfs.h"
+#include "cmh_dma.h"
+#include "cmh_mqi.h"
+
+/* Per-mailbox IRQ bookkeeping */
+struct cmh_rh_mbx {
+	u32        last_head;   /* last-observed MBX head position */
+	atomic_t   irq_bits;   /* interrupt bits saved by hardirq (atomic_or) */
+	bool       pending;     /* threaded handler should process this MBX */
+	bool       restart_pending; /* RESTART issued, awaiting eSW ack */
+	u32        restart_retries; /* watchdog ticks since RESTART issued */
+	u32        restart_head;    /* HEAD latched when recovery was issued */
+	bool       flush_pending;   /* FLUSH issued, drain awaits the eSW ack */
+	u32        flush_ticks;     /* watchdog ticks since FLUSH issued */
+	u32        flush_count;     /* consecutive unacknowledged FLUSHes */
+	bool       wedged;          /* recovery failed, MBX offline */
+	u32        abort_stall_ticks; /* ticks since async timeout ABORT issued */
+};
+
+/* Module-level RH state */
+static struct {
+	struct cmh_config      *cfg;
+	int                     irqs[CMH_MAX_CONFIGURED_MBX]; /* per-MBX virqs */
+	u32                     nirqs;          /* number of registered IRQs */
+	struct cmh_rh_mbx      *mbx;            /* array[cfg->mbx_count] */
+	atomic_t                irq_count;      /* hardirq invocation counter */
+	bool                    active;
+} rh;
+
+/*
+ * Serialise the read-last_head / process_mbx / update-last_head
+ * sequence between the threaded IRQ handler (process context) and
+ * the watchdog timer (softirq context).  Without this, a timer
+ * softirq can preempt the kthread mid-sequence, causing both paths
+ * to process the same head advance and prematurely complete a
+ * subsequent transaction before the CMH eSW has written its DMA
+ * output -- leading to data corruption and SLAB freelist poisoning.
+ *
+ * The kthread acquires with spin_lock_bh (disables softirqs), the
+ * watchdog acquires with spin_lock (already in softirq context).
+ */
+static DEFINE_SPINLOCK(rh_process_lock);
+
+/*
+ * Watchdog timer -- missed-IRQ recovery.
+ *
+ * Fires every watchdog_ms while rh.active.  Reads MBX head registers;
+ * if any head has advanced without an IRQ, processes completions and
+ * logs a notice.  Standard kernel pattern, analogous to NIC watchdog
+ * timers.
+ *
+ * Safe from timer/softirq context: cmh_reg_read32() is an MMIO read,
+ * cmh_tm_pop_transaction() uses spin_lock_irqsave(), and TM completion
+ * callbacks (crypto_request_complete et al.) are documented safe from
+ * any context including softirq.  rh_process_lock serialises the
+ * head-read / process / head-update sequence against the threaded
+ * IRQ handler to prevent double-processing of the same completion.
+ *
+ * Default 200 ms (5 fires/s) provides ~10 recovery attempts within
+ * the default vcq_timeout_ms (2 s).  Tune via debugfs config/watchdog_ms
+ * for platforms where interrupt delivery is more reliable (e.g. MSI on
+ * FPGA/silicon -- 500 ms--1 s may suffice as a safety net).
+ */
+#define CMH_RH_WATCHDOG_MS_DEFAULT  200
+
+/*
+ * Floor for watchdog_ms to prevent a zero/near-zero value from
+ * spinning the timer in a tight softirq loop.  Enforced at the
+ * point of use so debugfs writes are never rejected.
+ */
+#define CMH_RH_WATCHDOG_MS_MIN      10
+
+/*
+ * Maximum watchdog ticks to wait for the eSW to process RESTART
+ * before escalating to FLUSH.  At the default 200 ms interval,
+ * 5 retries = 1 s -- generous for an operation that should take
+ * microseconds.  If the eSW hasn't responded by then, issue
+ * MBX_COMMAND_FLUSH to hard-reset the mailbox state.
+ */
+#define CMH_RH_RESTART_MAX_RETRIES  5
+
+/*
+ * Maximum consecutive unacknowledged FLUSHes before marking the MBX as
+ * wedged.  Each FLUSH gets RESTART_MAX_RETRIES watchdog ticks (~1 s at
+ * the default interval) to be acknowledged before it is reissued.  Two
+ * unacknowledged FLUSHes (~2 s total) strongly indicate the eSW is not
+ * processing MBX commands at all.
+ */
+#define CMH_RH_FLUSH_MAX_FAILURES   2
+
+/*
+ * Time budget (ms) after an async timeout ABORT before escalating
+ * to FLUSH.  Converted to watchdog ticks at runtime
+ * via abort_stall_ms / watchdog_ms, so the actual wall-clock bound
+ * stays constant regardless of watchdog_ms tuning.
+ *
+ * The stall detector fires when:
+ *   - The head-of-queue transaction is in TXN_TIMED_OUT state
+ *   - HEAD hasn't advanced (eSW didn't process the ABORT)
+ *   - abort_stall_ticks exceeds the derived threshold
+ *
+ * At that point we issue FLUSH; once the eSW acknowledges it the pending
+ * transactions are drained (the timed-out one with -ETIMEDOUT, the rest
+ * with -ECANCELED), waking any blocked waiters.
+ *
+ * Default 5000 ms bounds worst-case D-state to
+ * async_timeout (2 s) + abort_stall (5 s) = ~7 s.
+ */
+#define CMH_RH_ABORT_STALL_MS       5000
+
+static unsigned int watchdog_ms = CMH_RH_WATCHDOG_MS_DEFAULT;
+
+/*
+ * Re-poke R_MBX_QUEUE_TAIL to generate a fresh interrupt to the eSW.
+ * Writing the current value back is a queue no-op but guarantees a
+ * SIC interrupt edge, ensuring the eSW wakes from WFI.
+ */
+static void cmh_rh_poke_tail(void __iomem *base)
+{
+	cmh_tm_poke_tail(base);
+}
+
+/*
+ * Drain all remaining in-flight transactions for a mailbox, completing
+ * each with the given error code.  Called once the eSW has acknowledged a
+ * FLUSH (which discarded all queued VCQs), or when marking a mailbox as
+ * wedged, in which case the device may still access their DMA
+ * (@dma_live).  Updates last_head to the current hardware HEAD so
+ * subsequent polls don't re-process the same (now-dead) VCQ IDs as
+ * successful completions.
+ *
+ * Caller must hold rh_process_lock.
+ */
+static void cmh_rh_drain_mbx(u32 mbx_idx, int error, bool dma_live)
+{
+	struct transaction_obj *txn;
+
+	while ((txn = cmh_tm_pop_transaction(mbx_idx)) != NULL) {
+		dev_dbg(cmh_dev(), "rh: mbx[%u] drain vcq=%u..%u err=%d\n",
+			mbx_idx, txn->first_vcq_id,
+			txn->last_vcq_id, error);
+		cmh_txn_finish(txn, error, dma_live);
+		cmh_tm_txq_completion_notify();
+	}
+
+	rh.mbx[mbx_idx].last_head =
+		cmh_reg_read32(rh.cfg->mailboxes[mbx_idx].reg_base,
+			       R_MBX_QUEUE_HEAD);
+}
+
+/*
+ * Close @mbx_idx to new submissions and issue MBX_COMMAND_FLUSH.  The
+ * transactions on its queue are not completed here: until the eSW
+ * processes the FLUSH it may still be running the VCQ at HEAD, so they
+ * are drained by cmh_rh_flush_poll() once the FLUSH is acknowledged
+ * (DMA-safe), or with their DMA quarantined if it never is.  Admission
+ * stays closed until then, so no VCQ is published that the FLUSH could
+ * discard (and that would then look completed) or that the drain could
+ * pop while it runs.
+ *
+ * Caller must hold rh_process_lock.
+ */
+static void cmh_rh_issue_flush(u32 mbx_idx)
+{
+	void __iomem *base = rh.cfg->mailboxes[mbx_idx].reg_base;
+
+	cmh_tm_mbx_admit(mbx_idx, false);
+	cmh_reg_write32(MBX_IRQ_MASK, base, R_MBX_INTERRUPT);
+	cmh_reg_write32(MBX_COMMAND_FLUSH, base, R_MBX_COMMAND);
+	cmh_rh_poke_tail(base);
+	rh.mbx[mbx_idx].flush_pending = true;
+	rh.mbx[mbx_idx].flush_ticks = 0;
+	WRITE_ONCE(rh.mbx[mbx_idx].restart_pending, false);
+	rh.mbx[mbx_idx].restart_retries = 0;
+	rh.mbx[mbx_idx].abort_stall_ticks = 0;
+}
+
+/*
+ * The eSW acknowledges FLUSH by clearing R_MBX_COMMAND after it has
+ * flushed every core and DMA engine of the mailbox and set HEAD = TAIL and
+ * the status to IDLE.  Check all three: a command written while the eSW
+ * was still finishing an earlier one can be cleared by that earlier
+ * acknowledgment, and admission is closed, so TAIL cannot move.
+ */
+static bool cmh_rh_flush_acked(void __iomem *base)
+{
+	return !cmh_reg_read32(base, R_MBX_COMMAND) &&
+	       MBX_STATUS_CODE(cmh_reg_read32(base, R_MBX_STATUS)) ==
+	       MBX_STATUS_IDLE &&
+	       cmh_reg_read32(base, R_MBX_QUEUE_HEAD) ==
+	       cmh_reg_read32(base, R_MBX_QUEUE_TAIL);
+}
+
+/*
+ * Check a pending FLUSH.  Once acknowledged, drain the mailbox with
+ * -ECANCELED (the eSW is done with every discarded VCQ) and reopen it.
+ * HEAD progress seen while the FLUSH was pending is not processed: HEAD
+ * jumps to TAIL on the FLUSH, so a completion cannot be told apart from a
+ * discard, and everything is drained as cancelled instead.
+ *
+ * On a watchdog @tick, count towards the acknowledgment budget: reissue
+ * the FLUSH, and after CMH_RH_FLUSH_MAX_FAILURES unacknowledged ones mark
+ * the mailbox wedged and drain it with -ETIMEDOUT (unresponsive device)
+ * and its DMA quarantined, since the device may still access it.  A
+ * wedged mailbox stays closed.
+ *
+ * Caller must hold rh_process_lock.
+ */
+static void cmh_rh_flush_poll(u32 mbx_idx, bool tick)
+{
+	void __iomem *base = rh.cfg->mailboxes[mbx_idx].reg_base;
+	struct cmh_rh_mbx *m = &rh.mbx[mbx_idx];
+
+	if (cmh_rh_flush_acked(base)) {
+		m->flush_pending = false;
+		m->flush_count = 0;
+		cmh_rh_drain_mbx(mbx_idx, -ECANCELED, false);
+		cmh_tm_mbx_admit(mbx_idx, true);
+		return;
+	}
+
+	if (!tick)
+		return;
+
+	if (++m->flush_ticks <= CMH_RH_RESTART_MAX_RETRIES) {
+		/* Re-poke TAIL in case the eSW missed the interrupt. */
+		cmh_rh_poke_tail(base);
+		return;
+	}
+
+	if (++m->flush_count < CMH_RH_FLUSH_MAX_FAILURES) {
+		dev_err(cmh_dev(),
+			"rh: mbx[%u] FLUSH not acknowledged, reissuing (attempt %u/%u)\n",
+			mbx_idx, m->flush_count + 1,
+			CMH_RH_FLUSH_MAX_FAILURES);
+		cmh_rh_issue_flush(mbx_idx);
+		return;
+	}
+
+	dev_crit(cmh_dev(),
+		 "rh: mbx[%u] wedged after %u unacknowledged FLUSHes (cmd=0x%x status=0x%x hb=0x%x err=0x%x)\n",
+		 mbx_idx, m->flush_count,
+		 cmh_reg_read32(base, R_MBX_COMMAND),
+		 cmh_reg_read32(base, R_MBX_STATUS),
+		 cmh_reg_read32(rh.cfg->sic_mapped, R_SIC_SW_HEARTBEAT),
+		 cmh_reg_read32(rh.cfg->sic_mapped, R_SIC_SW_ERROR_INFO));
+	m->flush_pending = false;
+	WRITE_ONCE(m->wedged, true);
+	cmh_rh_drain_mbx(mbx_idx, -ETIMEDOUT, true);
+}
+
+/**
+ * cmh_rh_force_drain_mbx() - FLUSH + drain a mailbox from external context
+ * @mbx_idx: Mailbox index to drain
+ *
+ * Clears the wedged flag and recovery bookkeeping and issues
+ * MBX_COMMAND_FLUSH to the eSW, then waits up to MBX_FLUSH_TIMEOUT_US for
+ * the acknowledgment, on which every pending transaction completes with
+ * -ECANCELED and the mailbox reopens.  Without an acknowledgment the
+ * watchdog keeps tracking the FLUSH (cmh_rh_flush_poll()).  This is an
+ * administrative last-resort recovery path exposed via debugfs.
+ *
+ * Context: process context.  Acquires rh_process_lock internally.
+ */
+void cmh_rh_force_drain_mbx(u32 mbx_idx)
+{
+	ktime_t deadline;
+
+	/*
+	 * Guard rh.mbx under rh_process_lock, not before it: cmh_rh_cleanup()
+	 * (and the cmh_rh_init() failure path) free rh.mbx under the same lock,
+	 * so this debugfs-triggered path must re-check it inside the lock to
+	 * avoid a use-after-free racing teardown.
+	 */
+	spin_lock_bh(&rh_process_lock);
+	if (!rh.cfg || !rh.mbx || mbx_idx >= rh.cfg->mbx_count) {
+		spin_unlock_bh(&rh_process_lock);
+		return;
+	}
+
+	dev_warn(cmh_dev(), "rh: force-drain mbx[%u] (debugfs)\n", mbx_idx);
+	WRITE_ONCE(rh.mbx[mbx_idx].wedged, false);
+	rh.mbx[mbx_idx].flush_count = 0;
+	cmh_rh_issue_flush(mbx_idx);
+	spin_unlock_bh(&rh_process_lock);
+
+	/* Bounded wait, so the drained requests complete before we return. */
+	deadline = ktime_add_us(ktime_get(), MBX_FLUSH_TIMEOUT_US);
+	do {
+		usleep_range(MBX_FLUSH_POLL_US, 2 * MBX_FLUSH_POLL_US);
+		spin_lock_bh(&rh_process_lock);
+		if (!rh.mbx || !rh.mbx[mbx_idx].flush_pending) {
+			spin_unlock_bh(&rh_process_lock);
+			return;
+		}
+		cmh_rh_flush_poll(mbx_idx, false);
+		spin_unlock_bh(&rh_process_lock);
+	} while (ktime_before(ktime_get(), deadline));
+}
+
+/**
+ * cmh_rh_mbx_is_wedged() - Check if a mailbox is permanently wedged
+ * @mbx_idx: Mailbox index to check
+ *
+ * Return: true if the mailbox has failed recovery and is offline.
+ */
+bool cmh_rh_mbx_is_wedged(u32 mbx_idx)
+{
+	if (!rh.mbx || !rh.cfg || mbx_idx >= rh.cfg->mbx_count)
+		return false;
+
+	return READ_ONCE(rh.mbx[mbx_idx].wedged);
+}
+
+/**
+ * cmh_rh_abort_mbx() - Issue MBX_COMMAND_ABORT under rh_process_lock
+ * @mbx_idx: Mailbox index to abort
+ * @vcq_id: Abort only while this VCQ is at HEAD; negative for any
+ *
+ * Serialises the ABORT write with the RESTART/FLUSH commands of the
+ * response handler and watchdog.  Skipped while either is pending: a
+ * FLUSH already stops the mailbox, and overwriting a RESTART or FLUSH
+ * would lose it.  Safe to call from any context (uses spin_lock_bh).
+ *
+ * Return: true if the ABORT was written.
+ */
+bool cmh_rh_abort_mbx(u32 mbx_idx, s64 vcq_id)
+{
+	void __iomem *base;
+	bool issued = false;
+
+	spin_lock_bh(&rh_process_lock);
+	if (!rh.cfg || !rh.mbx || mbx_idx >= rh.cfg->mbx_count)
+		goto out;
+
+	/* Never overwrite a RESTART or FLUSH the eSW has not yet taken. */
+	if (rh.mbx[mbx_idx].flush_pending ||
+	    READ_ONCE(rh.mbx[mbx_idx].restart_pending))
+		goto out;
+
+	/*
+	 * Holding rh_process_lock, no RESTART can move HEAD past the VCQ
+	 * checked here; the eSW can still complete it before the ABORT
+	 * lands, which no host-side check can exclude.
+	 */
+	base = rh.cfg->mailboxes[mbx_idx].reg_base;
+	if (vcq_id >= 0 &&
+	    cmh_reg_read32(base, R_MBX_QUEUE_HEAD) != (u32)vcq_id)
+		goto out;
+
+	cmh_reg_write32(MBX_COMMAND_ABORT, base, R_MBX_COMMAND);
+	issued = true;
+out:
+	spin_unlock_bh(&rh_process_lock);
+	return issued;
+}
+
+static struct timer_list rh_watchdog;
+
+/*
+ * Hardirq handler -- runs with interrupts disabled.
+ *
+ * Read and W1C-clear R_MBX_INTERRUPT for each mailbox.
+ * If any MBX had a pending interrupt, return IRQ_WAKE_THREAD.
+ * Shared-IRQ safe: returns IRQ_NONE if we didn't handle anything.
+ */
+static irqreturn_t cmh_rh_hardirq(int irq, void *data)
+{
+	struct cmh_config *cfg = data;
+	bool handled = false;
+	u32 i;
+
+	for (i = 0; i < cfg->mbx_count; i++) {
+		void __iomem *base = cfg->mailboxes[i].reg_base;
+		u32 bits;
+
+		/*
+		 * Only touch mailboxes routed to the line that fired.  With
+		 * distinct per-mailbox IRQ lines this stops one line's handler
+		 * from W1C-clearing another mailbox's R_MBX_INTERRUPT (which
+		 * would strand it and trip the spurious-IRQ detector); a shared
+		 * line matches all of its mailboxes.
+		 */
+		if (cfg->mailboxes[i].irq != irq)
+			continue;
+
+		bits = cmh_reg_read32(base, R_MBX_INTERRUPT);
+		if (!bits)
+			continue;
+
+		/* W1C: write back the set bits to clear them */
+		cmh_reg_write32(bits, base, R_MBX_INTERRUPT);
+
+		/*
+		 * Accumulate bits atomically so a second hardirq
+		 * firing while the threaded handler runs does not
+		 * overwrite the first set of bits.
+		 */
+		atomic_or((int)bits, &rh.mbx[i].irq_bits);
+		/*
+		 * Order the bit accumulation before publishing @pending: the
+		 * threaded handler reads @pending then consumes @irq_bits, so
+		 * it must not observe @pending set while the just-ORed bits
+		 * are not yet visible (which would strand them).
+		 */
+		smp_mb__after_atomic();
+		WRITE_ONCE(rh.mbx[i].pending, true);
+		handled = true;
+	}
+
+	/*
+	 * Ordering: the kernel IRQ threading infrastructure
+	 * performs a full barrier between hardirq return and
+	 * the threaded handler invocation.
+	 */
+	if (handled)
+		atomic_inc(&rh.irq_count);
+
+	return handled ? IRQ_WAKE_THREAD : IRQ_NONE;
+}
+
+static void cmh_rh_stat_inc_errors(u32 mbx_idx)
+{
+	struct cmh_mbx_stats *s = cmh_debugfs_mbx_stats(mbx_idx);
+
+	if (s)
+		atomic64_inc(&s->vcqs_errors);
+}
+
+static void cmh_rh_stat_add_completed(u32 mbx_idx, u32 first_vcq, u32 last_vcq)
+{
+	struct cmh_mbx_stats *s = cmh_debugfs_mbx_stats(mbx_idx);
+
+	if (s)
+		atomic64_add(last_vcq - first_vcq + 1, &s->vcqs_completed);
+}
+
+/*
+ * Decode the eSW error of a failed VCQ into the errno its transaction
+ * completes with.  The status word carries the failing core ID and the
+ * eSW error code; CMH_ESW_ECHILD means a child VCQ failed, and
+ * R_MBX_CHILD then holds the child's core ID and error code.  A failure
+ * completes with -EIO unless the core reports it with a code mapped
+ * below.
+ */
+static int cmh_rh_vcq_errno(u32 mbx_idx, void __iomem *base, u32 status)
+{
+	u32 core = MBX_STATUS_CORE_ID(status);
+	u32 code = MBX_STATUS_ERROR_CODE(status);
+
+	dev_dbg(cmh_dev(), "rh: mbx[%u] error status=0x%08x (core=%u code=%u cmd_idx=%u)\n",
+		mbx_idx, status, core, code, MBX_STATUS_CMD_INDEX(status));
+
+	if (code == CMH_ESW_ECHILD) {
+		u32 child = cmh_reg_read32(base, R_MBX_CHILD);
+
+		core = MBX_STATUS_CORE_ID(child);
+		code = MBX_STATUS_ERROR_CODE(child);
+		dev_dbg(cmh_dev(),
+			"rh: mbx[%u] child error=0x%08x (core=%u code=%u cmd_idx=%u)\n",
+			mbx_idx, child, core, code,
+			MBX_STATUS_CMD_INDEX(child));
+	}
+
+	return -EIO;
+}
+
+/*
+ * Whether the RESTART issued at restart_head has been carried out.  The
+ * eSW advances HEAD past the failed VCQ, then writes the status, and only
+ * then clears R_MBX_COMMAND; between the first two steps HEAD has moved
+ * while the status still shows the old ERROR.  Only once the command is
+ * cleared do HEAD and the status describe the mailbox coherently, so an
+ * ERROR seen at an advanced HEAD is a new error only then.
+ *
+ * Caller must hold rh_process_lock.
+ */
+static bool cmh_rh_restart_done(u32 mbx_idx, u32 new_head)
+{
+	return new_head != rh.mbx[mbx_idx].restart_head &&
+	       !cmh_reg_read32(rh.cfg->mailboxes[mbx_idx].reg_base,
+			       R_MBX_COMMAND);
+}
+
+/*
+ * Process completions for a single mailbox.
+ *
+ * Walk the per-MBX transaction queue FIFO.  For each transaction
+ * whose last_vcq_id is strictly less than the new head, fire the
+ * completion callback and free the object.
+ *
+ * "Strictly less than" using signed (s32) arithmetic handles wrap-around:
+ * the CMH eSW uses monotonically increasing 32-bit VCQ IDs.
+ */
+static void cmh_rh_process_mbx(u32 mbx_idx, u32 new_head, u32 irq_bits)
+{
+	struct transaction_obj *txn;
+	int error = 0;
+
+	/* Determine error state from saved IRQ bits */
+	if (irq_bits & MBX_ERROR_IRQ) {
+		void __iomem *base = rh.cfg->mailboxes[mbx_idx].reg_base;
+		u32 status;
+
+		/*
+		 * Idempotency: a RESTART is in flight and not yet carried out
+		 * (cmh_rh_restart_done()), so this is the same error latched
+		 * again (a hardirq bit racing the status-poll/watchdog), even
+		 * if HEAD has already moved.  Baseline on restart_head, not
+		 * last_head: a normal completion advances last_head and would
+		 * wrongly suppress a genuine fresh error at the new head.
+		 * Re-processing would pop an innocent in-flight transaction;
+		 * only completions below HEAD are retired.
+		 */
+		if (READ_ONCE(rh.mbx[mbx_idx].restart_pending) &&
+		    !cmh_rh_restart_done(mbx_idx, new_head))
+			goto completions;
+
+		/*
+		 * The eSW leaves ERROR only on a recovery command, and only
+		 * this handler issues one, under rh_process_lock, after
+		 * processing the error.  A saved error bit seen with the
+		 * status no longer at ERROR was therefore already handled
+		 * (e.g. by the watchdog) and recovery has moved HEAD on to
+		 * the next, running, transaction: treat it as a plain
+		 * completion poll rather than fail that transaction.  A real
+		 * back-to-back error leaves the status at ERROR at the new
+		 * HEAD and is processed below.
+		 */
+		status = cmh_reg_read32(base, R_MBX_STATUS);
+		if (MBX_STATUS_CODE(status) != MBX_STATUS_ERROR)
+			goto completions;
+
+		/*
+		 * HEAD was sampled before the status: the eSW may have
+		 * completed more VCQs and failed a later one in between.  It
+		 * does not move HEAD while stopped in ERROR, so re-read it now
+		 * to pair the error with the VCQ it belongs to.
+		 */
+		new_head = cmh_reg_read32(base, R_MBX_QUEUE_HEAD);
+
+		error = cmh_rh_vcq_errno(mbx_idx, base, status);
+
+		/*
+		 * CMH eSW does not advance head on error -- the MBX is
+		 * stuck in ERROR state until the host issues a recovery
+		 * command.  However, HEAD may have advanced past one or
+		 * more already-completed transactions before the error
+		 * occurred (their completion IRQ may not have been
+		 * processed yet).  Retire those normally first, then
+		 * force-complete the NEXT transaction (the one that
+		 * actually failed) with the decoded error.
+		 *
+		 * MBX command semantics after ERROR:
+		 *   CONTINUE -- re-run the same VCQ at HEAD (retry)
+		 *   RESTART  -- advance HEAD+1, skip failed, resume
+		 *   FLUSH    -- HEAD=TAIL, flush all HWCs, discard queue
+		 */
+
+		/* First: retire transactions completed before the error */
+		while ((txn = cmh_tm_peek_transaction(mbx_idx)) != NULL) {
+			if ((s32)(new_head - txn->last_vcq_id) <= 0)
+				break;
+			txn = cmh_tm_pop_transaction(mbx_idx);
+			if (!txn)
+				break;
+			dev_dbg(cmh_dev(),
+				"rh: mbx[%u] pre-error complete vcq=%u..%u\n",
+				mbx_idx, txn->first_vcq_id,
+				txn->last_vcq_id);
+			cmh_txn_finish(txn, 0, false);
+			cmh_tm_txq_completion_notify();
+		}
+
+		/*
+		 * The transaction that errored is now at the head.  If it is
+		 * multi-VCQ (first_vcq_id != last_vcq_id) it needs special
+		 * care: the eSW has no notion of a VCQ group and RESTART only
+		 * advances HEAD by one, so it would resume the surviving slots
+		 * of THIS transaction -- whose DMA cmh_txn_finish() is about
+		 * to free.  FLUSH instead discards the whole queue
+		 * (HEAD=TAIL) so no surviving slot runs.  The eSW stays
+		 * stopped in ERROR until it processes the FLUSH, so neither
+		 * the failed VCQ nor anything behind it is running: this
+		 * transaction is complete and finishes with the error now.
+		 * The ones queued behind it never ran and are drained with
+		 * -ECANCELED once the FLUSH is acknowledged.
+		 */
+		txn = cmh_tm_peek_transaction(mbx_idx);
+		if (txn && txn->first_vcq_id != txn->last_vcq_id) {
+			dev_warn_ratelimited(cmh_dev(),
+					     "rh: mbx[%u] multi-VCQ error vcq=%u..%u -- FLUSH\n",
+					     mbx_idx, txn->first_vcq_id,
+					     txn->last_vcq_id);
+			cmh_rh_stat_inc_errors(mbx_idx);
+			txn = cmh_tm_pop_transaction(mbx_idx);
+			if (txn) {
+				cmh_txn_finish(txn, error, false);
+				cmh_tm_txq_completion_notify();
+			}
+			cmh_rh_issue_flush(mbx_idx);
+			return;
+		}
+
+		/* Now pop and fail the transaction that actually errored */
+		txn = cmh_tm_pop_transaction(mbx_idx);
+		if (txn) {
+			dev_dbg(cmh_dev(), "rh: mbx[%u] error-complete vcq=%u..%u\n",
+				mbx_idx, txn->first_vcq_id,
+				txn->last_vcq_id);
+			cmh_txn_finish(txn, error, false);
+			cmh_tm_txq_completion_notify();
+		} else {
+			u32 head_reg, tail_reg;
+
+			head_reg = cmh_reg_read32(base, R_MBX_QUEUE_HEAD);
+			tail_reg = cmh_reg_read32(base, R_MBX_QUEUE_TAIL);
+			dev_warn_ratelimited(cmh_dev(),
+					     "rh: mbx[%u] ERROR with empty txn queue (orphaned) status=0x%08x head=%u tail=%u core=%u ecode=%u cmd_idx=%u\n",
+					     mbx_idx, status,
+					     head_reg, tail_reg,
+					     MBX_STATUS_CORE_ID(status),
+					     MBX_STATUS_ERROR_CODE(status),
+					     MBX_STATUS_CMD_INDEX(status));
+		}
+		cmh_rh_stat_inc_errors(mbx_idx);
+
+		/*
+		 * W1C-clear R_MBX_INTERRUPT before issuing RESTART.
+		 *
+		 * The eSW sets MBX_ERROR_IRQ in R_MBX_INTERRUPT when
+		 * it writes ERROR status.  On platforms where the
+		 * hardirq handler runs (IRQ wired to GIC), this bit
+		 * is cleared there.  On polling-only platforms (no
+		 * IRQ line), it must be cleared explicitly before
+		 * issuing a recovery command to de-assert the
+		 * MBX-to-SIC interrupt line.
+		 */
+		cmh_reg_write32(MBX_IRQ_MASK, base, R_MBX_INTERRUPT);
+		cmh_reg_write32(MBX_COMMAND_RESTART, base, R_MBX_COMMAND);
+
+		/*
+		 * Poke R_MBX_QUEUE_TAIL to guarantee the eSW receives
+		 * an interrupt.
+		 *
+		 * Writing R_MBX_COMMAND alone may not produce a new
+		 * SIC interrupt edge if the MBX-to-SIC line is still
+		 * asserted from prior error processing.  The eSW RUN
+		 * handler re-writes ERROR_IRQ to R_MBX_INTERRUPT on
+		 * every spurious wakeup while in ERROR state, which
+		 * can keep the SIC line high on level-triggered HW.
+		 *
+		 * R_MBX_QUEUE_TAIL writes always generate a fresh
+		 * interrupt to the eSW (this is the normal VCQ
+		 * submission path).  Writing the current TAIL value
+		 * back is a no-op from the queue perspective but
+		 * ensures the eSW wakes from WFI and processes the
+		 * RESTART command.
+		 */
+		cmh_rh_poke_tail(base);
+		WRITE_ONCE(rh.mbx[mbx_idx].restart_pending, true);
+		rh.mbx[mbx_idx].restart_retries = 0;
+		rh.mbx[mbx_idx].restart_head = new_head;
+		return;
+	}
+
+completions:
+	/*
+	 * Pop completed transactions.  A transaction is complete when
+	 * the CMH eSW has advanced head past its last VCQ ID:
+	 *   (s32)(new_head - txn->last_vcq_id) > 0
+	 * Using signed comparison for correct wrap-around handling.
+	 *
+	 * Multi-VCQ note: a transaction can span multiple parent VCQs
+	 * (a command sequence longer than one slot).  The CMH eSW advances
+	 * HEAD one VCQ at a time
+	 * and raises a completion interrupt per VCQ, so for a multi-VCQ
+	 * transaction HEAD can legitimately be observed partway through
+	 * the group while the remaining VCQs are still running.  The
+	 * transaction is treated atomically here: it is completed only
+	 * once HEAD has advanced past its last_vcq_id.  An intermediate
+	 * HEAD position is expected and simply causes us to wait.
+	 */
+	while ((txn = cmh_tm_peek_transaction(mbx_idx)) != NULL) {
+		if ((s32)(new_head - txn->last_vcq_id) <= 0) {
+			/*
+			 * Not yet complete.  An intermediate HEAD within a
+			 * multi-VCQ group is normal (the eSW advances HEAD
+			 * per VCQ), so log at debug level and wait for the
+			 * group to finish.
+			 */
+			if (txn->first_vcq_id != txn->last_vcq_id &&
+			    (s32)(new_head - txn->first_vcq_id) > 0)
+				dev_dbg_ratelimited(cmh_dev(),
+						    "rh: mbx[%u] head %u mid-group %u..%u\n",
+						    mbx_idx, new_head,
+						    txn->first_vcq_id,
+						    txn->last_vcq_id);
+			break;
+		}
+
+		txn = cmh_tm_pop_transaction(mbx_idx);
+		if (!txn)
+			break;
+
+		dev_dbg(cmh_dev(), "rh: mbx[%u] complete vcq=%u..%u err=%d\n",
+			mbx_idx, txn->first_vcq_id, txn->last_vcq_id,
+			 error);
+
+		cmh_rh_stat_add_completed(mbx_idx, txn->first_vcq_id,
+					  txn->last_vcq_id);
+
+		cmh_txn_finish(txn, error, false);
+		cmh_tm_txq_completion_notify();
+	}
+}
+
+/*
+ * Threaded IRQ handler -- runs in process context.
+ *
+ * Walk all MBXes that had pending interrupts.  After processing the
+ * pending set, do a final hardware poll of all MBX head registers to
+ * catch completions whose PLIC interrupt was consumed during an
+ * earlier register access (e.g. an inline interrupt notification
+ * during MMIO can cause the PLIC edge to be claimed before the
+ * hardirq sees it).
+ */
+static irqreturn_t cmh_rh_thread(int irq, void *data)
+{
+	struct cmh_config *cfg = data;
+	u32 i;
+	bool recheck;
+
+	do {
+		recheck = false;
+
+		for (i = 0; i < cfg->mbx_count; i++) {
+			u32 new_head, irq_bits;
+
+			if (!READ_ONCE(rh.mbx[i].pending))
+				continue;
+
+			/*
+			 * Clear @pending before consuming @irq_bits so a
+			 * hardirq landing between the two does not have its
+			 * freshly-set @pending cleared and its bits stranded.
+			 * The xchg is a full barrier and captures any bits the
+			 * hardirq ORs in; @pending then stays set and the outer
+			 * loop rescans this mailbox.
+			 */
+			WRITE_ONCE(rh.mbx[i].pending, false);
+			irq_bits = (u32)atomic_xchg(&rh.mbx[i].irq_bits, 0);
+
+			spin_lock_bh(&rh_process_lock);
+			if (rh.mbx[i].flush_pending) {
+				cmh_rh_flush_poll(i, false);
+				spin_unlock_bh(&rh_process_lock);
+				continue;
+			}
+			new_head = cmh_reg_read32(cfg->mailboxes[i].reg_base,
+						  R_MBX_QUEUE_HEAD);
+
+			if (new_head == rh.mbx[i].last_head && !irq_bits) {
+				spin_unlock_bh(&rh_process_lock);
+				continue;
+			}
+
+			cmh_rh_process_mbx(i, new_head, irq_bits);
+			rh.mbx[i].last_head = new_head;
+			spin_unlock_bh(&rh_process_lock);
+		}
+
+		/*
+		 * Re-check: if the hardirq fired again while we were
+		 * processing, pending flags will be set again.
+		 */
+		for (i = 0; i < cfg->mbx_count; i++) {
+			if (READ_ONCE(rh.mbx[i].pending)) {
+				recheck = true;
+				break;
+			}
+		}
+	} while (recheck);
+
+	/*
+	 * Final hardware poll: read every MBX head register and status
+	 * to catch completions or errors whose interrupt was missed.
+	 */
+	for (i = 0; i < cfg->mbx_count; i++) {
+		u32 new_head;
+		u32 status;
+		u32 poll_irq_bits = 0;
+
+		spin_lock_bh(&rh_process_lock);
+		if (rh.mbx[i].flush_pending) {
+			cmh_rh_flush_poll(i, false);
+			spin_unlock_bh(&rh_process_lock);
+			continue;
+		}
+		new_head = cmh_reg_read32(cfg->mailboxes[i].reg_base,
+					  R_MBX_QUEUE_HEAD);
+		status = cmh_reg_read32(cfg->mailboxes[i].reg_base,
+					R_MBX_STATUS);
+
+		if (MBX_STATUS_CODE(status) == MBX_STATUS_ERROR) {
+			if (READ_ONCE(rh.mbx[i].wedged)) {
+				spin_unlock_bh(&rh_process_lock);
+				continue;
+			}
+			if (READ_ONCE(rh.mbx[i].restart_pending)) {
+				/*
+				 * HEAD advanced past the recovery baseline means
+				 * RESTART worked but the next VCQ also failed.
+				 * Clear restart state and process the new error.
+				 */
+				if (cmh_rh_restart_done(i, new_head)) {
+					WRITE_ONCE(rh.mbx[i].restart_pending,
+						   false);
+					rh.mbx[i].restart_retries = 0;
+				} else {
+					spin_unlock_bh(&rh_process_lock);
+					continue;
+				}
+			}
+			poll_irq_bits = MBX_ERROR_IRQ;
+		} else {
+			WRITE_ONCE(rh.mbx[i].restart_pending, false);
+			rh.mbx[i].restart_retries = 0;
+			rh.mbx[i].flush_count = 0;
+		}
+
+		if (new_head != rh.mbx[i].last_head || poll_irq_bits) {
+			cmh_rh_process_mbx(i, new_head, poll_irq_bits);
+			rh.mbx[i].last_head = new_head;
+		}
+		spin_unlock_bh(&rh_process_lock);
+	}
+
+	return IRQ_HANDLED;
+}
+
+/*
+ * Watchdog timer callback -- missed-IRQ recovery.
+ *
+ * Reads all MBX head registers.  If any head advanced without a
+ * corresponding IRQ, process the completions here.  Re-arms itself
+ * while rh.active is true.
+ */
+static void cmh_rh_watchdog_fn(struct timer_list *t)
+{
+	u32 i;
+
+	if (!rh.active || !rh.cfg || !rh.mbx)
+		return;
+
+	for (i = 0; i < rh.cfg->mbx_count; i++) {
+		u32 new_head;
+		u32 status;
+		u32 irq_bits = 0;
+
+		spin_lock(&rh_process_lock);
+		if (rh.mbx[i].flush_pending) {
+			cmh_rh_flush_poll(i, true);
+			spin_unlock(&rh_process_lock);
+			continue;
+		}
+		new_head = cmh_reg_read32(rh.cfg->mailboxes[i].reg_base,
+					  R_MBX_QUEUE_HEAD);
+		status = cmh_reg_read32(rh.cfg->mailboxes[i].reg_base,
+					R_MBX_STATUS);
+
+		if (MBX_STATUS_CODE(status) == MBX_STATUS_ERROR) {
+			if (READ_ONCE(rh.mbx[i].wedged)) {
+				spin_unlock(&rh_process_lock);
+				continue;
+			}
+			/*
+			 * Back-to-back failure scenario: the crypto API
+			 * (e.g. testmgr) may submit requests continuously.
+			 * If RESTART succeeds but the next VCQ also fails,
+			 * the entire RESTART->IDLE->RUN->ERROR cycle can
+			 * complete within a single 200ms watchdog period.
+			 * Without the HEAD-advance check below, the watchdog
+			 * would mistake the new error for a failed RESTART,
+			 * increment restart_retries, and eventually escalate
+			 * to FLUSH -- wedging the mailbox unnecessarily.
+			 */
+			if (READ_ONCE(rh.mbx[i].restart_pending)) {
+				void __iomem *base =
+					rh.cfg->mailboxes[i].reg_base;
+
+				/*
+				 * HEAD advanced since RESTART was issued:
+				 * RESTART succeeded, this is a fresh error.
+				 * Clear recovery state and process normally.
+				 */
+				if (cmh_rh_restart_done(i, new_head)) {
+					dev_dbg(cmh_dev(),
+						"rh: watchdog: mbx[%u] head advanced %u->%u during restart -- new error\n",
+						i, rh.mbx[i].restart_head,
+						new_head);
+					WRITE_ONCE(rh.mbx[i].restart_pending,
+						   false);
+					rh.mbx[i].restart_retries = 0;
+					goto new_error;
+				}
+
+				rh.mbx[i].restart_retries++;
+				if (rh.mbx[i].restart_retries >
+				    CMH_RH_RESTART_MAX_RETRIES) {
+					/*
+					 * Backstop: eSW did not respond
+					 * to RESTART within the retry
+					 * budget.  Escalate to FLUSH
+					 * which is a harder reset of
+					 * the eSW mailbox state.  The
+					 * failed transaction was already
+					 * completed; the queued ones
+					 * never ran and are drained once
+					 * the FLUSH is acknowledged.
+					 */
+					dev_err(cmh_dev(),
+						"rh: watchdog: mbx[%u] RESTART unresponsive after %u ticks, escalating to FLUSH\n",
+						i, rh.mbx[i].restart_retries);
+					cmh_rh_issue_flush(i);
+					spin_unlock(&rh_process_lock);
+					continue;
+				}
+				/*
+				 * RESTART was already issued on a prior
+				 * tick but the eSW hasn't cleared the
+				 * ERROR status yet.  Do NOT pop another
+				 * transaction -- that would cascade-kill
+				 * unrelated in-flight work.  Re-poke TAIL
+				 * in case the eSW missed the interrupt.
+				 */
+				cmh_rh_poke_tail(base);
+				dev_dbg_ratelimited(cmh_dev(),
+						    "rh: watchdog: mbx[%u] restart pending (%u/%u) status=0x%08x, re-poke\n",
+						    i,
+						    rh.mbx[i].restart_retries,
+						    CMH_RH_RESTART_MAX_RETRIES,
+						    status);
+				spin_unlock(&rh_process_lock);
+				continue;
+			}
+new_error:
+			dev_dbg_ratelimited(cmh_dev(),
+					    "rh: watchdog: mbx[%u] error status=0x%08x (missed error IRQ) head=%u tail=%u core=%u ecode=%u cmd_idx=%u\n",
+					    i, status, new_head,
+					    cmh_reg_read32(rh.cfg->mailboxes[i].reg_base,
+							   R_MBX_QUEUE_TAIL),
+					    MBX_STATUS_CORE_ID(status),
+					    MBX_STATUS_ERROR_CODE(status),
+					    MBX_STATUS_CMD_INDEX(status));
+			irq_bits = MBX_ERROR_IRQ;
+		} else {
+			/* eSW cleared ERROR -- recovery succeeded */
+			WRITE_ONCE(rh.mbx[i].restart_pending, false);
+			rh.mbx[i].restart_retries = 0;
+			rh.mbx[i].flush_count = 0;
+		}
+
+		if (new_head != rh.mbx[i].last_head || irq_bits) {
+			if (new_head != rh.mbx[i].last_head)
+				dev_dbg_ratelimited(cmh_dev(),
+						    "rh: watchdog: mbx[%u] head %u->%u (missed IRQ recovery)\n",
+						    i, rh.mbx[i].last_head,
+						    new_head);
+			cmh_rh_process_mbx(i, new_head, irq_bits);
+			rh.mbx[i].last_head = new_head;
+			rh.mbx[i].abort_stall_ticks = 0;
+		}
+
+		/*
+		 * Abort-stall detector: if the head-of-queue transaction
+		 * timed out (state == TXN_TIMED_OUT) but the eSW hasn't
+		 * responded (HEAD didn't advance, no ERROR status):
+		 *
+		 *   tick 1:        issue MBX_COMMAND_ABORT (serialised
+		 *                  under rh_process_lock -- safe against
+		 *                  concurrent RESTART/FLUSH)
+		 *   ticks 2..N-1:  wait for eSW to respond with ERROR
+		 *   tick N:        escalate to FLUSH; the queue is drained
+		 *                  once the eSW acknowledges it
+		 *
+		 * If the eSW responds with ERROR between ticks, the ERROR
+		 * status branch above handles RESTART recovery and resets
+		 * abort_stall_ticks via the restart_pending guard.
+		 */
+		if (!READ_ONCE(rh.mbx[i].wedged) &&
+		    !READ_ONCE(rh.mbx[i].restart_pending) &&
+		    !rh.mbx[i].flush_pending) {
+			struct transaction_obj *head_txn;
+
+			head_txn = cmh_tm_peek_transaction(i);
+			if (head_txn &&
+			    atomic_read(&head_txn->state) == TXN_TIMED_OUT) {
+				unsigned int stall_max;
+				void __iomem *base =
+					rh.cfg->mailboxes[i].reg_base;
+
+				rh.mbx[i].abort_stall_ticks++;
+
+				if (rh.mbx[i].abort_stall_ticks == 1) {
+					dev_warn(cmh_dev(),
+						 "rh: watchdog: mbx[%u] head txn timed out, issuing ABORT\n",
+						 i);
+					cmh_reg_write32(MBX_COMMAND_ABORT,
+							base,
+							R_MBX_COMMAND);
+				}
+
+				stall_max = DIV_ROUND_UP(CMH_RH_ABORT_STALL_MS,
+							 max(watchdog_ms,
+							     CMH_RH_WATCHDOG_MS_MIN));
+				if (rh.mbx[i].abort_stall_ticks >=
+				    stall_max) {
+					dev_err(cmh_dev(),
+						"rh: watchdog: mbx[%u] abort stall (%u ticks) -- FLUSH\n",
+						i, rh.mbx[i].abort_stall_ticks);
+					cmh_rh_issue_flush(i);
+				}
+			} else {
+				rh.mbx[i].abort_stall_ticks = 0;
+			}
+		}
+		spin_unlock(&rh_process_lock);
+	}
+
+	if (rh.active) {
+		unsigned int wdog = max(watchdog_ms, CMH_RH_WATCHDOG_MS_MIN);
+
+		mod_timer(&rh_watchdog,
+			  jiffies + msecs_to_jiffies(wdog));
+	}
+}
+
+/*
+ * Resolve per-MBX Linux virqs for the CMH interrupt lines.
+ *
+ * Each mailbox declares its own completion interrupt in its device-tree
+ * child node; cmh_config_init() resolves these to Linux virqs and stores
+ * them in cfg->mailboxes[i].irq (-1 when the mailbox has no interrupt).
+ * IRQ mode requires every configured mailbox to have an interrupt; if
+ * none do (or only some), the response handler uses watchdog polling.
+ *
+ * Populates rh.irqs[] and rh.nirqs.  Returns 0 on success, or a
+ * negative errno if no IRQs could be resolved (polling-only mode).
+ */
+static int cmh_rh_resolve_irqs(struct cmh_config *cfg)
+{
+	u32 i, nwith = 0;
+
+	rh.nirqs = 0;
+
+	for (i = 0; i < cfg->mbx_count; i++)
+		if (cfg->mailboxes[i].irq >= 0)
+			nwith++;
+
+	if (nwith == 0)
+		return -ENODEV;
+
+	if (nwith != cfg->mbx_count) {
+		dev_warn(cmh_dev(),
+			 "rh: only %u/%u mailboxes have IRQs -- falling back to polling\n",
+			 nwith, cfg->mbx_count);
+		return -ENODEV;
+	}
+
+	/*
+	 * Collect distinct virqs.  Multiple mailboxes may be wired to the
+	 * same line; the threaded handler scans all mailboxes, so each
+	 * distinct line needs only one registration.  Requesting (and later
+	 * freeing) a shared line once per mailbox would fail -EBUSY / double
+	 * free.
+	 */
+	rh.nirqs = 0;
+	for (i = 0; i < cfg->mbx_count; i++) {
+		int irq = cfg->mailboxes[i].irq;
+		bool seen = false;
+		u32 j;
+
+		for (j = 0; j < rh.nirqs; j++)
+			if (rh.irqs[j] == irq) {
+				seen = true;
+				break;
+			}
+		if (seen)
+			continue;
+
+		rh.irqs[rh.nirqs++] = irq;
+		dev_dbg(cmh_dev(), "rh: MBX%u -> IRQ %d\n", i, irq);
+	}
+
+	return 0;
+}
+
+/**
+ * cmh_rh_init() - Initialize the response handler
+ * @cfg: Device configuration (mailbox count, MMIO bases, IRQ info)
+ *
+ * Resolve per-mailbox IRQs from the device tree, register threaded IRQ
+ * handlers (hardirq + kthread), and arm the missed-IRQ software watchdog
+ * timer.  If no IRQs can be resolved, falls back to watchdog-only
+ * polling mode.
+ *
+ * Return: 0 on success, negative errno on failure.
+ */
+int cmh_rh_init(struct cmh_config *cfg)
+{
+	unsigned long irqflags;
+	int ret;
+	u32 i;
+
+	rh.cfg = cfg;
+	rh.nirqs = 0;
+	rh.active = false;
+	atomic_set(&rh.irq_count, 0);
+
+	/* Allocate per-MBX tracking */
+	rh.mbx = kcalloc(cfg->mbx_count, sizeof(*rh.mbx), GFP_KERNEL);
+	if (!rh.mbx)
+		return -ENOMEM;
+
+	/* Resolve per-MBX IRQs */
+	if (cmh_rh_resolve_irqs(cfg) < 0) {
+		/*
+		 * No IRQs available.  The watchdog timer provides
+		 * a polling fallback: it reads MBX head registers
+		 * periodically and processes completions.  This is
+		 * slower than IRQ-driven completion but functional.
+		 *
+		 * Completion latency in polling-only mode is bounded
+		 * by the watchdog interval (default 200 ms, tunable
+		 * via debugfs config/watchdog_ms).
+		 */
+		dev_warn(cmh_dev(),
+			 "rh: no IRQs -- using watchdog polling (interval %u ms)\n",
+			 watchdog_ms);
+
+		/* Seed last_head from HW before first watchdog tick */
+		for (i = 0; i < cfg->mbx_count; i++)
+			rh.mbx[i].last_head =
+				cmh_reg_read32(cfg->mailboxes[i].reg_base,
+					       R_MBX_QUEUE_HEAD);
+
+		rh.active = true;
+		timer_setup(&rh_watchdog, cmh_rh_watchdog_fn, 0);
+		mod_timer(&rh_watchdog, jiffies +
+			  msecs_to_jiffies(max(watchdog_ms,
+					       CMH_RH_WATCHDOG_MS_MIN)));
+		return 0;
+	}
+
+	/* Initialize per-MBX state: read current head positions */
+	for (i = 0; i < cfg->mbx_count; i++)
+		rh.mbx[i].last_head = cmh_reg_read32(rh.cfg->mailboxes[i].reg_base,
+						     R_MBX_QUEUE_HEAD);
+
+	/*
+	 * Register threaded IRQ handlers, one per DISTINCT line
+	 * (cmh_rh_resolve_irqs() de-duplicated shared virqs).  The handler
+	 * scans all mailboxes unconditionally, so one registration per line
+	 * covers every mailbox wired to it.
+	 *
+	 * When de-dup collapsed lines (nirqs < mbx_count) at least one line
+	 * is shared across mailboxes -- register IRQF_SHARED.
+	 */
+	irqflags = (rh.nirqs < cfg->mbx_count) ? IRQF_SHARED : 0;
+
+	for (i = 0; i < rh.nirqs; i++) {
+		ret = request_threaded_irq(rh.irqs[i],
+					   cmh_rh_hardirq,
+					   cmh_rh_thread,
+					   irqflags,
+					   "cmh", cfg);
+		if (ret) {
+			dev_err(cmh_dev(), "rh: request_threaded_irq(%d) for MBX%u failed (rc=%d)\n",
+				rh.irqs[i], i, ret);
+			/* Unwind previously registered IRQs */
+			while (i--)
+				free_irq(rh.irqs[i], cfg);
+			rh.nirqs = 0;
+			spin_lock_bh(&rh_process_lock);
+			kfree(rh.mbx);
+			rh.mbx = NULL;
+			spin_unlock_bh(&rh_process_lock);
+			return ret;
+		}
+	}
+
+	rh.active = true;
+
+	/* Enable MBX completion interrupts (DONE + ERROR) */
+	for (i = 0; i < cfg->mbx_count; i++) {
+		u32 stale;
+
+		/*
+		 * W1C any interrupt bits that accumulated between
+		 * MQI setup and now (e.g. CMH eSW processing stale
+		 * commands) before enabling the mask.
+		 */
+		stale = cmh_reg_read32(cfg->mailboxes[i].reg_base,
+				       R_MBX_INTERRUPT);
+		if (stale)
+			cmh_reg_write32(stale, cfg->mailboxes[i].reg_base,
+					R_MBX_INTERRUPT);
+
+		cmh_reg_write32(MBX_IRQ_MASK,
+				cfg->mailboxes[i].reg_base,
+				R_MBX_INTERRUPT_MASK);
+	}
+
+	/* Arm missed-IRQ watchdog timer */
+	timer_setup(&rh_watchdog, cmh_rh_watchdog_fn, 0);
+	mod_timer(&rh_watchdog, jiffies +
+		  msecs_to_jiffies(max(watchdog_ms,
+				       CMH_RH_WATCHDOG_MS_MIN)));
+
+	return 0;
+}
+
+/**
+ * cmh_rh_suspend() - Suspend the response handler
+ * @cfg: Device configuration
+ *
+ * Stop the watchdog timer and mask mailbox interrupts at the hardware
+ * level.  The IRQ handlers remain registered so that resume can
+ * re-enable them without re-requesting.
+ */
+void cmh_rh_suspend(struct cmh_config *cfg)
+{
+	u32 i;
+
+	if (!rh.active)
+		return;
+
+	/*
+	 * Clear rh.active before deleting the timer: the watchdog re-arms
+	 * itself only while rh.active is set, so an in-flight callback will
+	 * not re-queue the timer once this is cleared.  Keep
+	 * timer_delete_sync (not _shutdown) so cmh_rh_resume() can re-arm.
+	 */
+	rh.active = false;
+
+	/* Stop the watchdog before masking HW interrupts */
+	timer_delete_sync(&rh_watchdog);
+
+	/* Mask MBX interrupts at the hardware level */
+	for (i = 0; i < cfg->mbx_count; i++)
+		cmh_reg_write32(0, cfg->mailboxes[i].reg_base,
+				R_MBX_INTERRUPT_MASK);
+
+	/*
+	 * Ensure no threaded IRQ handler is still in-flight.
+	 * After masking, a handler may already have been scheduled.
+	 * synchronize_irq() waits for it to complete before we
+	 * proceed with suspend (which tears down TM state).
+	 */
+	for (i = 0; i < rh.nirqs; i++)
+		synchronize_irq(rh.irqs[i]);
+}
+
+/**
+ * cmh_rh_resume() - Resume the response handler after suspend
+ * @cfg: Device configuration
+ *
+ * Re-synchronize per-mailbox head tracking with hardware, clear stale
+ * interrupt bits accumulated during the power transition, re-enable
+ * mailbox completion interrupts, and re-arm the watchdog timer.
+ */
+void cmh_rh_resume(struct cmh_config *cfg)
+{
+	u32 i;
+
+	if (!rh.mbx || !cfg)
+		return;
+
+	/*
+	 * Resume assumes the CryptoManager Hub kept power across suspend, so
+	 * the mailbox queue registers and the eSW state (keys, DRBG config)
+	 * are intact and only head/IRQ state needs re-syncing.  A platform
+	 * that powers it off would lose all of that and need a full re-init
+	 * here, not a partial register reprogram.
+	 */
+
+	/* Re-sync per-MBX head tracking with hardware */
+	for (i = 0; i < cfg->mbx_count; i++) {
+		u32 stale;
+
+		rh.mbx[i].last_head =
+			cmh_reg_read32(cfg->mailboxes[i].reg_base,
+				       R_MBX_QUEUE_HEAD);
+
+		/* W1C any stale interrupt bits from the power transition */
+		stale = cmh_reg_read32(cfg->mailboxes[i].reg_base,
+				       R_MBX_INTERRUPT);
+		if (stale)
+			cmh_reg_write32(stale, cfg->mailboxes[i].reg_base,
+					R_MBX_INTERRUPT);
+
+		/* Re-enable MBX completion interrupts */
+		cmh_reg_write32(MBX_IRQ_MASK, cfg->mailboxes[i].reg_base,
+				R_MBX_INTERRUPT_MASK);
+	}
+
+	rh.active = true;
+
+	/* Re-arm the watchdog */
+	mod_timer(&rh_watchdog, jiffies +
+		  msecs_to_jiffies(max(watchdog_ms,
+				       CMH_RH_WATCHDOG_MS_MIN)));
+}
+
+/**
+ * cmh_rh_cleanup() - Clean up the response handler
+ * @cfg: Device configuration
+ *
+ * Stop the watchdog timer, mask mailbox interrupts at the hardware
+ * level, release all registered IRQ handlers, and free per-mailbox
+ * tracking state.  Safe to call even if init was never completed.
+ */
+void cmh_rh_cleanup(struct cmh_config *cfg)
+{
+	u32 i;
+
+	if (rh.active) {
+		/*
+		 * Clear rh.active first (the watchdog re-arm is gated on
+		 * it), then shut the timer down: after timer_shutdown_sync()
+		 * a stray mod_timer() is a no-op, so the callback cannot
+		 * resurrect the timer before rh.mbx is freed.  A later probe
+		 * re-inits it via timer_setup() in cmh_rh_init().
+		 */
+		rh.active = false;
+
+		/* Cancel watchdog before disabling interrupts */
+		timer_shutdown_sync(&rh_watchdog);
+
+		/* Disable MBX interrupts before releasing handlers */
+		for (i = 0; i < cfg->mbx_count; i++)
+			cmh_reg_write32(0,
+					cfg->mailboxes[i].reg_base,
+					R_MBX_INTERRUPT_MASK);
+	}
+
+	/*
+	 * Release IRQs by registration count, not rh.active: cmh_rh_suspend()
+	 * clears rh.active but leaves the IRQs registered (only masked), so a
+	 * teardown that runs after a suspend must still free them or they
+	 * leak.  nirqs is 0 when none were registered, so this is a no-op on
+	 * an uninitialised or already-released response handler.
+	 */
+	for (i = 0; i < rh.nirqs; i++)
+		free_irq(rh.irqs[i], cfg);
+	if (rh.nirqs)
+		dev_dbg(cmh_dev(), "rh: %u IRQs released\n", rh.nirqs);
+	rh.nirqs = 0;
+
+	dev_dbg(cmh_dev(), "rh: %u IRQs handled\n",
+		atomic_read(&rh.irq_count));
+
+	/* Free under the lock: a debugfs force-drain may still read rh.mbx. */
+	spin_lock_bh(&rh_process_lock);
+	kfree(rh.mbx);
+	rh.mbx = NULL;
+	spin_unlock_bh(&rh_process_lock);
+}
+
+/* -- debugfs timeout accessor ------------------------------------------ */
+
+#ifdef CONFIG_CRYPTO_DEV_CMH_DEBUG
+/**
+ * cmh_rh_timeout_watchdog_ptr() - Return pointer to watchdog_ms for debugfs
+ *
+ * Exposes the Response Handler watchdog timeout for runtime tuning
+ * via debugfs config/ directory.
+ *
+ * Return: pointer to the static watchdog_ms variable.
+ */
+unsigned int *cmh_rh_timeout_watchdog_ptr(void) { return &watchdog_ms; }
+#endif
diff --git a/drivers/crypto/cmh/cmh_sysfs.c b/drivers/crypto/cmh/cmh_sysfs.c
new file mode 100644
index 000000000000..ab482a222167
--- /dev/null
+++ b/drivers/crypto/cmh/cmh_sysfs.c
@@ -0,0 +1,108 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- sysfs Device Attributes
+ *
+ * Exposes hardware identity and status as read-only sysfs attributes
+ * under /sys/devices/platform/cmh/.  Wired via .dev_groups in the
+ * platform_driver struct -- the driver core creates and removes these
+ * automatically around .probe() / .remove().
+ *
+ * Because .dev_groups is used (not manual sysfs_create_group), the
+ * driver core guarantees that attributes are created after .probe()
+ * sets drvdata and removed before .remove() clears it.  Therefore
+ * platform_get_drvdata() cannot return NULL in any show callback and
+ * no NULL check is needed.  Same pattern as caam/ctrl.c and
+ * ccree/cc_sysfs.c.
+ */
+
+#include <linux/device.h>
+#include <linux/platform_device.h>
+#include <linux/sysfs.h>
+
+#include "cmh.h"
+#include "cmh_registers.h"
+#include "cmh_sysfs.h"
+
+static ssize_t fw_version_show(struct device *dev,
+			       struct device_attribute *attr, char *buf)
+{
+	struct cmh_device *cmh = platform_get_drvdata(to_platform_device(dev));
+	struct cmh_config *cfg = &cmh->config;
+
+	if (!cfg->sic_mapped)
+		return -ENODEV;
+
+	return sysfs_emit(buf, "0x%08x\n",
+			  cmh_reg_read32(cfg->sic_mapped, R_SIC_SW_VERSION));
+}
+static DEVICE_ATTR_RO(fw_version);
+
+static ssize_t hw_version_show(struct device *dev,
+			       struct device_attribute *attr, char *buf)
+{
+	struct cmh_device *cmh = platform_get_drvdata(to_platform_device(dev));
+	struct cmh_config *cfg = &cmh->config;
+
+	if (!cfg->sic_mapped)
+		return -ENODEV;
+
+	return sysfs_emit(buf, "0x%08x\n",
+			  cmh_reg_read32(cfg->sic_mapped, R_SIC_HW_VERSION0));
+}
+static DEVICE_ATTR_RO(hw_version);
+
+static ssize_t boot_status_show(struct device *dev,
+				struct device_attribute *attr, char *buf)
+{
+	struct cmh_device *cmh = platform_get_drvdata(to_platform_device(dev));
+	struct cmh_config *cfg = &cmh->config;
+
+	if (!cfg->sic_mapped)
+		return -ENODEV;
+
+	return sysfs_emit(buf, "0x%08x\n",
+			  cmh_reg_read32(cfg->sic_mapped, R_SIC_BOOT_STATUS));
+}
+static DEVICE_ATTR_RO(boot_status);
+
+static ssize_t mbx_available_show(struct device *dev,
+				  struct device_attribute *attr, char *buf)
+{
+	struct cmh_device *cmh = platform_get_drvdata(to_platform_device(dev));
+	struct cmh_config *cfg = &cmh->config;
+
+	if (!cfg->sic_mapped)
+		return -ENODEV;
+
+	return sysfs_emit(buf, "0x%08x\n",
+			  cmh_reg_read32(cfg->sic_mapped, R_SIC_MBX_AVAILABILITY));
+}
+static DEVICE_ATTR_RO(mbx_available);
+
+static ssize_t mbx_count_show(struct device *dev,
+			      struct device_attribute *attr, char *buf)
+{
+	struct cmh_device *cmh = platform_get_drvdata(to_platform_device(dev));
+
+	return sysfs_emit(buf, "%u\n", cmh->config.mbx_count);
+}
+static DEVICE_ATTR_RO(mbx_count);
+
+static struct attribute *cmh_sysfs_attrs[] = {
+	&dev_attr_fw_version.attr,
+	&dev_attr_hw_version.attr,
+	&dev_attr_boot_status.attr,
+	&dev_attr_mbx_available.attr,
+	&dev_attr_mbx_count.attr,
+	NULL,
+};
+
+static const struct attribute_group cmh_sysfs_group = {
+	.attrs = cmh_sysfs_attrs,
+};
+
+const struct attribute_group *cmh_sysfs_groups[] = {
+	&cmh_sysfs_group,
+	NULL,
+};
diff --git a/drivers/crypto/cmh/cmh_txn.c b/drivers/crypto/cmh/cmh_txn.c
new file mode 100644
index 000000000000..9a84b52781bf
--- /dev/null
+++ b/drivers/crypto/cmh/cmh_txn.c
@@ -0,0 +1,2531 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- Transaction Manager
+ *
+ * Dedicated kthread that dequeues command messages, builds VCQs in
+ * DMA queue slots, and rings the MBX doorbell.
+ *
+ * Command flow:
+ *   1. Caller posts command_msg via cmh_tm_post_command()
+ *   2. TM thread wakes, dequeues msg from CMQ
+ *   3. Selects mailbox (core-to-MBX affinity, or caller-pinned)
+ *   4. Copies pre-built VCQ entries into DMA slot at tail
+ *   5. Creates transaction_obj, appends to per-MBX txn queue
+ *   6. Writes tail+1 -> R_MBX_QUEUE_TAIL (doorbell)
+ *
+ * The Response Handler (cmh_rh.c) walks per-MBX txn queues
+ * when an IRQ fires and the head advances, firing completion callbacks.
+ *
+ * Transaction state machine
+ * -------------------------
+ * Each async transaction moves through the following states.  DMA
+ * buffers remain mapped and owned by the HW until the COMPLETE state
+ * is reached -- only then are they safe to unmap/free.
+ *
+ *   QUEUED --[TM posts to HW]--> INFLIGHT
+ *   (cmq)   |                       |      \
+ *          |                       |       \--[timer fires]-->
+ *          |                       |            TIMED_OUT
+ *          |                       |               |
+ *          |                  [HW completes /   [HW completes /
+ *          |                   RH pops txn]      RH pops txn]
+ *          |                       |               |
+ *          |                       v               v
+ *          |                    COMPLETE        COMPLETE
+ *          |                   (err=HW rc)    (err=-ETIMEDOUT)
+ *          |
+ *          +--[pre-submit fail]--> freed (callback never fires)
+ *
+ * Note: QUEUED is the command_msg phase (sitting in the CMQ list,
+ * not yet a transaction_obj).  The transaction_obj states tracked
+ * by atomic_cmpxchg are INFLIGHT, TIMED_OUT, and COMPLETE only.
+ *
+ * Completion callback context guarantee:
+ *   The final crypto_request_complete() callback always runs with BH
+ *   disabled, as the crypto API expects (e.g. IPsec resumes under a
+ *   plain spin_lock), from one of:
+ *     - The RH threaded IRQ handler (under spin_lock_bh)
+ *     - The watchdog timer (softirq / timer context)
+ *     - The TM kthread on a submit failure or queue drain/cleanup
+ *       (process context, wrapped in local_bh_disable())
+ *
+ *   It is NEVER invoked from hardirq context.  Callers must NOT assume
+ *   process context in their completion callbacks -- all operations
+ *   therein must be softirq-safe (no mutex, no GFP_KERNEL, no sleeping
+ *   locks).
+ *
+ *   For backlog promotion the -EINPROGRESS notification is issued with
+ *   the CMQ spinlock dropped, so a consumer may safely resubmit (or take
+ *   sleeping locks) from that callback without re-entering cmq_lock.
+ */
+
+#include <linux/module.h>
+#include <linux/kernel.h>
+#include <linux/kthread.h>
+#include <linux/slab.h>
+#include <linux/delay.h>
+#include <linux/io.h>
+#include <linux/iopoll.h>
+#include <linux/string.h>
+#include <linux/completion.h>
+#include <linux/overflow.h>
+#include <linux/refcount.h>
+
+#include "cmh_txn.h"
+#include "cmh_rh.h"
+#include "cmh_registers.h"
+#include "cmh_config.h"
+#include "cmh_vcq.h"
+#include "cmh_debugfs.h"
+#include "cmh_dma.h"
+#include "cmh_mqi.h"
+
+/* Module State */
+
+static struct {
+	struct cmh_config      *cfg;
+	struct task_struct     *thread;
+	/*
+	 * Gates submission acceptance in cmh_tm_post_command(); the TM
+	 * thread's lifetime is governed by kthread_should_stop(), not this.
+	 */
+	bool                    running;
+
+	/* Command Message Queue (CMQ) */
+	struct list_head        cmq;
+	spinlock_t              cmq_lock;   /* protects cmq + backlog lists */
+	wait_queue_head_t       cmq_waitq;
+
+	/* Backlog queue for CRYPTO_TFM_REQ_MAY_BACKLOG requests */
+	struct list_head        backlog;
+	u32                     backlog_depth;
+
+	/* Per-mailbox transaction queues */
+	struct cmh_mbx_txq     *txqs;       /* array[cfg->mbx_count] */
+
+	/* Round-robin mailbox selector */
+	u32                     next_mbx;
+
+	/*
+	 * Latched once a transaction completes without the device having
+	 * acknowledged the FLUSH that ended it: some DMA may still be live.
+	 */
+	bool                    dma_live;
+} tm;
+
+/*
+ * Command Message Queue depth.  Built-in default; a debug build can tune
+ * it at runtime via debugfs config/cmq_max_depth.  The backlog has no
+ * limit: like crypto_enqueue_request(), a CRYPTO_TFM_REQ_MAY_BACKLOG
+ * request is never refused for lack of space.
+ */
+#define CMH_TM_CMQ_MAX_DEPTH		256
+
+static unsigned int cmq_max_depth = CMH_TM_CMQ_MAX_DEPTH;
+
+static unsigned int async_timeout_ms = 2000;
+
+#define CMH_TM_BACKOFF_MAX_US   500  /* queue-full backoff (us) */
+static unsigned int cmq_depth;       /* current CMQ depth, protected by tm.cmq_lock */
+
+/*
+ * Monotonically increasing counter bumped by cmh_tm_txq_completion_notify().
+ * Used as a generation check in the queue-full backoff predicate so that
+ * wait_event_interruptible_timeout() returns immediately when a TXQ
+ * completion frees a slot, rather than sleeping for the full timeout.
+ */
+static atomic_t txq_completion_gen;
+
+/* -- Debugfs stat helpers (avoid anonymous compound blocks) ------------- */
+
+static void cmh_stat_inc_mbx_queue_full(u32 mbx_idx)
+{
+	struct cmh_mbx_stats *s = cmh_debugfs_mbx_stats(mbx_idx);
+
+	if (s)
+		atomic64_inc(&s->queue_full_count);
+}
+
+static void cmh_stat_record_vcq_submit(u32 mbx_idx, u32 num_vcqs, u32 depth)
+{
+	struct cmh_mbx_stats *s = cmh_debugfs_mbx_stats(mbx_idx);
+
+	if (s) {
+		atomic64_add(num_vcqs, &s->vcqs_submitted);
+		cmh_stat_update_max(&s->max_queue_depth, (s64)depth);
+	}
+}
+
+static void cmh_stat_inc_tm_backoff(void)
+{
+	struct cmh_tm_stats *s = cmh_debugfs_tm_stats();
+
+	if (s)
+		atomic64_inc(&s->backoff_count);
+}
+
+static void cmh_stat_inc_cmq_full(void)
+{
+	struct cmh_tm_stats *s = cmh_debugfs_tm_stats();
+
+	if (s)
+		atomic64_inc(&s->cmq_full_count);
+}
+
+static void cmh_stat_record_cmq_post(u32 depth)
+{
+	struct cmh_tm_stats *s = cmh_debugfs_tm_stats();
+
+	if (s) {
+		atomic64_inc(&s->cmq_posts);
+		cmh_stat_update_max(&s->cmq_depth_max, (s64)depth);
+	}
+}
+
+static void cmh_stat_inc_async_timeout(void)
+{
+	struct cmh_tm_stats *s = cmh_debugfs_tm_stats();
+
+	if (s)
+		atomic64_inc(&s->async_timeout_count);
+}
+
+/*
+ * Drop one reference on a command_msg; free when the last ref is dropped.
+ * Used by cmh_tm_submit_sync() to share msg ownership between the
+ * waiter (caller) and the TM subsystem (thread or cleanup drain).
+ */
+static void command_msg_put(struct command_msg *msg)
+{
+	if (refcount_dec_and_test(&msg->refs)) {
+		kfree(msg->vcq_data);
+		kfree(msg);
+	}
+}
+
+/*
+ * Drop one reference on a transaction_obj; free when the last ref drops.
+ * Two references are held when the per-request timeout timer is armed:
+ * one for the TXQ owner (RH/cleanup), one for the timer callback.
+ * When no timer is armed, only the owner ref exists.
+ */
+static void txn_put(struct transaction_obj *txn)
+{
+	if (refcount_dec_and_test(&txn->refs))
+		kfree(txn);
+}
+
+/* DMA Quarantine */
+
+/*
+ * Buffers the device may still access.  This HW has no DMA-stop
+ * primitive, so a buffer whose transfer was never confirmed finished must
+ * not go back to the allocator: it is held here, never freed at runtime,
+ * and released by cmh_tm_cleanup() only if every mailbox then acknowledges
+ * a FLUSH -- otherwise it is deliberately leaked.
+ */
+static LIST_HEAD(cmh_dma_quarantine);
+static DEFINE_SPINLOCK(cmh_dma_quarantine_lock);
+
+static void cmh_dma_orphan_reap(struct cmh_dma_orphan *o)
+{
+	if (o->buf) {
+		if (o->dir != DMA_NONE)
+			cmh_dma_unmap_single(o->addr, o->len, o->dir);
+		kfree_sensitive(o->buf);
+	}
+	cmh_dma_free_sg(o->sgm);
+	kfree(o);
+}
+
+static void cmh_dma_quarantine_add(struct cmh_dma_orphan *o)
+{
+	unsigned long flags;
+
+	spin_lock_irqsave(&cmh_dma_quarantine_lock, flags);
+	list_add_tail(&o->node, &cmh_dma_quarantine);
+	spin_unlock_irqrestore(&cmh_dma_quarantine_lock, flags);
+}
+
+/*
+ * Track @buf/@sgm in the quarantine.  If no record can be allocated the
+ * memory is leaked rather than freed while the device may still use it.
+ */
+static void cmh_dma_quarantine_track(void *buf, dma_addr_t dma, size_t len,
+				     enum dma_data_direction dir,
+				     struct cmh_sg_map *sgm)
+{
+	struct cmh_dma_orphan *o = kzalloc_obj(*o, GFP_ATOMIC);
+
+	if (!o) {
+		dev_err_ratelimited(cmh_dev(),
+				    "tm: no memory to track quarantined DMA, leaking it\n");
+		return;
+	}
+	o->buf  = buf;
+	o->addr = dma;
+	o->len  = len;
+	o->dir  = dir;
+	o->sgm  = sgm;
+	cmh_dma_quarantine_add(o);
+}
+
+/**
+ * cmh_tm_dma_quarantine_buf() - Quarantine a buffer the device may access
+ * @buf: kmalloc'd CPU buffer (freed with kfree_sensitive()), or NULL
+ * @dma: Its DMA mapping
+ * @len: Mapped length
+ * @dir: DMA direction of the mapping
+ *
+ * Safe from any non-hardirq context.  If no tracking record can be
+ * allocated the buffer is leaked, never freed.
+ */
+void cmh_tm_dma_quarantine_buf(void *buf, dma_addr_t dma, size_t len,
+			       enum dma_data_direction dir)
+{
+	cmh_dma_quarantine_track(buf, dma, len, dir, NULL);
+}
+
+/**
+ * cmh_tm_dma_quiescent() - Whether all device DMA is known to be finished
+ *
+ * Return: false once any transaction has completed without the device
+ *         acknowledging the FLUSH that ended it, true otherwise.
+ */
+bool cmh_tm_dma_quiescent(void)
+{
+	return !READ_ONCE(tm.dma_live);
+}
+
+/**
+ * cmh_dma_orphan_free() - Release or quarantine an orphaned DMA buffer
+ * @data: Pointer to a struct cmh_dma_orphan
+ * @error: Completion status of the owning VCQ (0 = clean completion)
+ *
+ * Callback for cmh_tm_submit_sync_noabort(), also called directly by a
+ * caller whose synchronous operation completed abnormally.  A clean
+ * completion means the eSW finished the transfer, so the buffer is
+ * unmapped and freed; any other status (an eSW error, or a recovery or
+ * teardown cancel) quarantines it.
+ */
+void cmh_dma_orphan_free(void *data, int error)
+{
+	struct cmh_dma_orphan *o = data;
+
+	if (error) {
+		cmh_dma_quarantine_add(o);
+		return;
+	}
+
+	cmh_dma_orphan_reap(o);
+}
+
+/**
+ * cmh_dma_free_out() - Dispose of a synchronous op's DMA output buffer
+ * @buf: kmalloc'd CPU buffer the eSW writes into
+ * @dma: Its DMA mapping
+ * @len: Mapped length
+ * @dir: DMA direction of the mapping
+ * @park: Quarantine instead of freeing (the submit timed out)
+ *
+ * cmh_tm_submit_sync_tmo() issues MBX_COMMAND_ABORT on a timeout and waits
+ * for the RH to drain the VCQ, so on a normal return the caller may free
+ * its buffers.  A -ETIMEDOUT return means the device never confirmed it
+ * was done with the buffer -- the abort was not observed to complete, or
+ * the mailbox was retired after a FLUSH it never acknowledged -- so pass
+ * @park and the buffer is quarantined.  Input-only (DMA_TO_DEVICE)
+ * buffers are released by the caller; a late device read of one cannot
+ * corrupt host memory, and its result lands in a quarantined output.
+ */
+void cmh_dma_free_out(void *buf, dma_addr_t dma, size_t len,
+		      enum dma_data_direction dir, bool park)
+{
+	if (park) {
+		cmh_dma_quarantine_track(buf, dma, len, dir, NULL);
+		return;
+	}
+
+	cmh_dma_unmap_single(dma, len, dir);
+	kfree_sensitive(buf);
+}
+
+/*
+ * Release the quarantine at module unload: free it if every mailbox has
+ * just acknowledged a FLUSH (@fenced), otherwise leak it.
+ */
+static void cmh_dma_quarantine_release(bool fenced)
+{
+	struct cmh_dma_orphan *o, *tmp;
+	unsigned long flags;
+	unsigned int leaked = 0;
+	LIST_HEAD(list);
+
+	spin_lock_irqsave(&cmh_dma_quarantine_lock, flags);
+	list_splice_init(&cmh_dma_quarantine, &list);
+	spin_unlock_irqrestore(&cmh_dma_quarantine_lock, flags);
+
+	list_for_each_entry_safe(o, tmp, &list, node) {
+		list_del(&o->node);
+		if (fenced)
+			cmh_dma_orphan_reap(o);
+		else
+			leaked++;
+	}
+	if (leaked)
+		dev_err(cmh_dev(),
+			"tm: leaking %u quarantined DMA buffers: the device did not acknowledge the final FLUSH\n",
+			leaked);
+}
+
+/* Request DMA Set */
+
+/**
+ * cmh_req_dma_init() - Initialise an empty request DMA set
+ * @rd: Set to initialise
+ */
+void cmh_req_dma_init(struct cmh_req_dma *rd)
+{
+	rd->n = 0;
+	rd->sgm = NULL;
+}
+
+/**
+ * cmh_req_dma_add() - Record and DMA-map a request buffer
+ * @rd: Request DMA set
+ * @buf: kmalloc'd buffer; the set owns it from this call on
+ * @len: Length to map
+ * @dir: DMA direction
+ * @sensitive: Free with kfree_sensitive() rather than kfree()
+ *
+ * The set takes ownership of @buf even when the mapping fails, so the
+ * caller unwinds with cmh_req_dma_release() alone.
+ *
+ * Return: The DMA address, or a mapping error (cmh_dma_map_error()).
+ */
+dma_addr_t cmh_req_dma_add(struct cmh_req_dma *rd, void *buf, size_t len,
+			   enum dma_data_direction dir, bool sensitive)
+{
+	struct cmh_req_dma_ent *e;
+
+	if (WARN_ON_ONCE(rd->n >= CMH_REQ_DMA_MAX)) {
+		if (sensitive)
+			kfree_sensitive(buf);
+		else
+			kfree(buf);
+		return DMA_MAPPING_ERROR;
+	}
+
+	e = &rd->ent[rd->n++];
+	e->buf = buf;
+	e->len = len;
+	e->dir = dir;
+	e->sensitive = sensitive;
+	e->sg_src = false;
+	e->dma = cmh_dma_map_single(buf, len, dir);
+	e->mapped = !cmh_dma_map_error(e->dma);
+	return e->dma;
+}
+
+/**
+ * cmh_req_dma_add_sg() - Record a scatter-gather chain
+ * @rd: Request DMA set
+ * @sgm: Chain from cmh_dma_build_sg(); the set owns it from this call on
+ */
+void cmh_req_dma_add_sg(struct cmh_req_dma *rd, struct cmh_sg_map *sgm)
+{
+	WARN_ON_ONCE(rd->sgm);
+	rd->sgm = sgm;
+}
+
+/**
+ * cmh_req_dma_own() - Record a source buffer of the scatter-gather chain
+ * @rd: Request DMA set
+ * @buf: kmalloc'd buffer passed to cmh_dma_build_sg(); the set owns it
+ *       from this call on
+ * @sensitive: Free with kfree_sensitive() rather than kfree()
+ *
+ * The chain maps and unmaps @buf itself, so the set only frees it, after
+ * the chain.  Quarantining the set holds @buf together with the chain.
+ * Record @buf even when cmh_dma_build_sg() fails, so the caller unwinds
+ * with cmh_req_dma_release() alone.
+ */
+void cmh_req_dma_own(struct cmh_req_dma *rd, void *buf, bool sensitive)
+{
+	struct cmh_req_dma_ent *e;
+
+	if (WARN_ON_ONCE(rd->n >= CMH_REQ_DMA_MAX)) {
+		if (sensitive)
+			kfree_sensitive(buf);
+		else
+			kfree(buf);
+		return;
+	}
+
+	e = &rd->ent[rd->n++];
+	e->buf = buf;
+	e->dma = DMA_MAPPING_ERROR;
+	e->len = 0;
+	e->dir = DMA_NONE;
+	e->mapped = false;
+	e->sensitive = sensitive;
+	e->sg_src = true;
+}
+
+/**
+ * cmh_req_dma_unmap() - Unmap every mapped buffer for CPU access
+ * @rd: Request DMA set
+ */
+void cmh_req_dma_unmap(struct cmh_req_dma *rd)
+{
+	unsigned int i;
+
+	for (i = 0; i < rd->n; i++) {
+		struct cmh_req_dma_ent *e = &rd->ent[i];
+
+		if (e->mapped) {
+			cmh_dma_unmap_single(e->dma, e->len, e->dir);
+			e->mapped = false;
+		}
+	}
+}
+
+/**
+ * cmh_req_dma_free() - Free every buffer of the set and empty it
+ * @rd: Request DMA set; call cmh_req_dma_unmap() first
+ */
+void cmh_req_dma_free(struct cmh_req_dma *rd)
+{
+	unsigned int i;
+
+	/* The chain unmaps the sg_src buffers, so free it before them. */
+	cmh_dma_free_sg(rd->sgm);
+	rd->sgm = NULL;
+	for (i = 0; i < rd->n; i++) {
+		struct cmh_req_dma_ent *e = &rd->ent[i];
+
+		WARN_ON_ONCE(e->mapped);
+		if (e->sensitive)
+			kfree_sensitive(e->buf);
+		else
+			kfree(e->buf);
+	}
+	rd->n = 0;
+}
+
+/**
+ * cmh_req_dma_release() - Unmap and free the whole set
+ * @rd: Request DMA set
+ */
+void cmh_req_dma_release(struct cmh_req_dma *rd)
+{
+	cmh_req_dma_unmap(rd);
+	cmh_req_dma_free(rd);
+}
+
+/*
+ * Move a request's DMA set into the quarantine and empty it, so the
+ * completion callback that follows releases nothing.  Buffers that were
+ * never mapped cannot be reached by the device and are freed; the source
+ * buffers of the chain are held with it, queued after it so that a
+ * release at unload unmaps them before freeing them.
+ */
+static void cmh_req_dma_quarantine(struct cmh_req_dma *rd)
+{
+	unsigned int i;
+
+	if (rd->sgm)
+		cmh_dma_quarantine_track(NULL, 0, 0, DMA_NONE, rd->sgm);
+	for (i = 0; i < rd->n; i++) {
+		struct cmh_req_dma_ent *e = &rd->ent[i];
+
+		if (e->mapped)
+			cmh_dma_quarantine_track(e->buf, e->dma, e->len,
+						 e->dir, NULL);
+		else if (e->sg_src && rd->sgm)
+			cmh_dma_quarantine_track(e->buf, 0, 0, DMA_NONE,
+						 NULL);
+		else if (e->sensitive)
+			kfree_sensitive(e->buf);
+		else
+			kfree(e->buf);
+	}
+	rd->n = 0;
+	rd->sgm = NULL;
+}
+
+/*
+ * A transaction is being completed while the device may still access its
+ * DMA: latch that DMA may be live and quarantine the request's buffers.
+ */
+static void cmh_txn_quarantine(struct transaction_obj *txn)
+{
+	WRITE_ONCE(tm.dma_live, true);
+	if (txn->rdma)
+		cmh_req_dma_quarantine(txn->rdma);
+}
+
+/*
+ * Per-request async timeout callback (runs in softirq / timer context).
+ *
+ * This function ONLY marks the transaction state as TIMED_OUT via
+ * atomic cmpxchg and drops the timer reference.  It does NOT fire
+ * the completion callback, does NOT touch DMA buffers, and does NOT
+ * write any MBX registers.
+ *
+ * Rationale: the HW may still be writing to DMA buffers at this
+ * point, so unmapping or freeing them here would be unsafe.
+ * The actual -ETIMEDOUT completion fires later, from process
+ * context, when the RH threaded IRQ pops the transaction after the
+ * HW finishes, or when its mailbox is drained after a FLUSH or at
+ * teardown.
+ *
+ * MBX_COMMAND_ABORT is NOT issued here.  It is issued by the RH
+ * watchdog abort-stall detector under rh_process_lock, which
+ * serialises it against RESTART/FLUSH recovery commands.  Writing
+ * ABORT from timer softirq without the lock caused a race where
+ * concurrent timeouts clobbered an in-progress RESTART, wedging
+ * the mailbox.
+ *
+ * Context: softirq (timer).  Must not sleep.
+ */
+static void txn_timeout_fn(struct timer_list *t)
+{
+	struct transaction_obj *txn = timer_container_of(txn, t, timeout_timer);
+	int old;
+
+	old = atomic_cmpxchg(&txn->state, TXN_INFLIGHT, TXN_TIMED_OUT);
+	if (old == TXN_INFLIGHT) {
+		dev_err_ratelimited(cmh_dev(),
+				    "tm: async timeout vcq=%u..%u mbx=%u cmd_id=0x%08x\n",
+				    txn->first_vcq_id,
+				    txn->last_vcq_id, txn->mailbox_idx,
+				    txn->command_id);
+		cmh_stat_inc_async_timeout();
+	}
+
+	txn_put(txn); /* drop timer ref */
+}
+
+/**
+ * cmh_txn_finish() - Complete a popped transaction with FSM + timer cleanup
+ * @txn: Transaction object to complete
+ * @error: Error code from HW (0 on success)
+ * @dma_live: The device may still access the transaction's DMA buffers
+ *
+ * Two cases:
+ *   1. Normal: state INFLIGHT -> COMPLETE.  Fire callback with @error.
+ *   2. Timed out: state already TXN_TIMED_OUT (timer marked it).
+ *      Fire callback with -ETIMEDOUT.
+ *
+ * Unless @dma_live, the device is done with the transaction (HEAD moved
+ * past it, it failed and stopped the mailbox, or a FLUSH that discarded
+ * it was acknowledged), so the callback may release its DMA.  With
+ * @dma_live (the mailbox was retired after a FLUSH it never acknowledged)
+ * the request's DMA set is quarantined before the callback runs.
+ */
+void cmh_txn_finish(struct transaction_obj *txn, int error, bool dma_live)
+{
+	int old;
+
+	old = atomic_cmpxchg(&txn->state, TXN_INFLIGHT, TXN_COMPLETE);
+
+	/* Dequeue the timer if still pending; drop timer ref if we did */
+	if (timer_delete(&txn->timeout_timer))
+		txn_put(txn);
+
+	if (dma_live)
+		cmh_txn_quarantine(txn);
+
+	if (old == TXN_INFLIGHT) {
+		/* HW completion (may carry error) */
+		if (txn->complete)
+			txn->complete(txn->completion_data, error);
+	} else if (old == TXN_TIMED_OUT) {
+		/* Timer won earlier; now HW is done -- deliver -ETIMEDOUT */
+		if (txn->complete)
+			txn->complete(txn->completion_data, -ETIMEDOUT);
+	}
+
+	txn_put(txn); /* drop owner ref */
+}
+
+/* Mailbox Slot Addressing */
+
+/*
+ * Return a kernel-virtual pointer to the VCQ slot for the given vcqid.
+ * Mirrors CMH eSW's mbx_queue_addr() but uses the kernel virt_addr.
+ */
+static void *mbx_slot_ptr(struct cmh_mbx_config *mbx, u32 vcqid)
+{
+	u32 slot_mask = (1U << mbx->slots_log2) - 1U;
+	u32 slot_offset = (vcqid & slot_mask) << mbx->stride_log2;
+
+	return (u8 *)mbx->virt_addr + slot_offset;
+}
+
+/*
+ * Return the number of free slots in a mailbox queue.
+ */
+static u32 mbx_free_slots(struct cmh_mbx_config *mbx)
+{
+	u32 head = cmh_reg_read32(mbx->reg_base, R_MBX_QUEUE_HEAD);
+	u32 tail = cmh_reg_read32(mbx->reg_base, R_MBX_QUEUE_TAIL);
+	u32 size = 1U << mbx->slots_log2;
+
+	return size - (u32)(tail - head);
+}
+
+/**
+ * cmh_tm_max_cmds_per_vcq() - Return max commands per VCQ slot
+ *
+ * Scans all mailbox configurations and returns the minimum number of
+ * VCQ command entries that fit in a single slot, clamped to the
+ * MIN_VCQ_CMDS..MAX_VCQ_CMDS range.
+ *
+ * Return: Maximum usable VCQ command count per slot.
+ */
+u32 cmh_tm_max_cmds_per_vcq(void)
+{
+	u32 i, min_cmds = MAX_VCQ_CMDS;
+
+	for (i = 0; i < tm.cfg->mbx_count; i++) {
+		u32 stride = 1U << tm.cfg->mailboxes[i].stride_log2;
+		u32 cmds = stride / (u32)sizeof(struct vcq_cmd);
+
+		if (cmds < min_cmds)
+			min_cmds = cmds;
+	}
+
+	if (min_cmds < MIN_VCQ_CMDS)
+		min_cmds = MIN_VCQ_CMDS;
+
+	return min_cmds;
+}
+
+/**
+ * cmh_tm_mbx_count() - Return the number of configured mailboxes
+ *
+ * Return: Number of mailboxes in the current configuration.
+ */
+u32 cmh_tm_mbx_count(void)
+{
+	return tm.cfg->mbx_count;
+}
+
+/* Core-to-MBX Affinity -- Config-Driven Multi-Instance Support */
+
+/*
+ * Per-core-type configuration table.  Each entry holds one or more
+ * (core_id, mbx_idx) instances.  Defaults: single instance per core
+ * type with the standard CORE_ID_* and MBX auto-assigned on first use
+ * (mbx_idx = -1).  Module params can override for explicit assignment
+ * and multi-instance support.
+ *
+ * Round-robin across instances for each new crypto operation.
+ */
+
+struct core_instance_info {
+	u32		core_id;	/* VCQ dispatch core_id */
+	/*
+	 * Assigned MBX index, or -1 (sentinel) for auto-assign on first
+	 * use.  Uses atomic_t for a lockless once-only latch: the first
+	 * caller does atomic_cmpxchg(&mbx_idx, -1, new_mbx); all later
+	 * callers see the winning value via atomic_read().
+	 */
+	atomic_t	mbx_idx;
+};
+
+struct core_type_info {
+	u32		num_instances;
+	struct core_instance_info instances[CMH_MAX_CORE_INSTANCES];
+	atomic_t	next_instance;	/* round-robin counter */
+};
+
+static struct core_type_info core_types[CMH_NUM_CORE_TYPES] = {
+	[CMH_CORE_HC]  = { .num_instances = 1,
+	  .instances = { { .core_id = CORE_ID_HC,
+			   .mbx_idx = ATOMIC_INIT(-1) } } },
+	[CMH_CORE_AES] = { .num_instances = 1,
+	  .instances = { { .core_id = CORE_ID_AES,
+			   .mbx_idx = ATOMIC_INIT(-1) } } },
+	[CMH_CORE_SM4] = { .num_instances = 1,
+	  .instances = { { .core_id = CORE_ID_SM4,
+			   .mbx_idx = ATOMIC_INIT(-1) } } },
+	[CMH_CORE_SM3] = { .num_instances = 1,
+	  .instances = { { .core_id = CORE_ID_SM3,
+			   .mbx_idx = ATOMIC_INIT(-1) } } },
+	[CMH_CORE_CCP] = { .num_instances = 1,
+	  .instances = { { .core_id = CORE_ID_CCP,
+			   .mbx_idx = ATOMIC_INIT(-1) } } },
+	[CMH_CORE_PKE] = { .num_instances = 1,
+	  .instances = { { .core_id = CORE_ID_PKE,
+			   .mbx_idx = ATOMIC_INIT(-1) } } },
+	[CMH_CORE_QSE] = { .num_instances = 1,
+	  .instances = { { .core_id = CORE_ID_QSE,
+			   .mbx_idx = ATOMIC_INIT(-1) } } },
+	[CMH_CORE_HCQ] = { .num_instances = 1,
+	  .instances = { { .core_id = CORE_ID_HCQ,
+			   .mbx_idx = ATOMIC_INIT(-1) } } },
+};
+
+/* Round-robin counter for auto-assigning MBXes to core instances */
+static atomic_t affinity_next_mbx = ATOMIC_INIT(0);
+
+/**
+ * cmh_tm_affinity_reset() - Reset core-to-MBX affinity state
+ *
+ * Clears all auto-assigned MBX bindings and resets round-robin
+ * counters for both the global MBX allocator and per-core-type
+ * instance selectors.
+ */
+void cmh_tm_affinity_reset(void)
+{
+	u32 i, j;
+
+	atomic_set(&affinity_next_mbx, 0);
+
+	/* Reset multi-instance table */
+	for (i = 0; i < CMH_NUM_CORE_TYPES; i++) {
+		struct core_type_info *ct = &core_types[i];
+
+		atomic_set(&ct->next_instance, 0);
+		for (j = 0; j < ct->num_instances; j++)
+			atomic_set(&ct->instances[j].mbx_idx, -1);
+	}
+}
+
+/**
+ * cmh_core_default_id() - Return default core_id for a core type
+ * @type: Core type selector
+ *
+ * Returns the first-instance core_id for @type without advancing the
+ * round-robin counter.  Used by callers pinned to a fixed MBX that only
+ * need the VCQ core_id field.
+ *
+ * Return: VCQ core_id value for the default instance of @type.
+ */
+u32 cmh_core_default_id(enum cmh_core_type type)
+{
+	if (WARN_ON_ONCE(type >= CMH_NUM_CORE_TYPES))
+		return CORE_ID_NUM;
+
+	return core_types[type].instances[0].core_id;
+}
+
+/**
+ * cmh_core_select_instance() - Select a core instance via round-robin
+ * @type: Core type selector
+ *
+ * Round-robin across configured instances, each permanently pinned to
+ * its MBX (auto-assigned on first use if mbx_idx was -1).
+ *
+ * Uses atomic_inc_return (pre-increment), so the very first call for a
+ * given type returns instance[1 % N].  Over the lifetime of the module
+ * the distribution is perfectly balanced; the off-by-one only affects
+ * the first cycle.
+ *
+ * The (u32) cast before the modulo ensures correct behaviour across
+ * the INT_MAX -> INT_MIN wraparound of atomic_t: (u32)INT_MIN =
+ * 0x80000000, and 0x80000000 % N still yields a valid index.
+ *
+ * Return: A core_dispatch with (core_id, mbx_idx) for the selected
+ *         instance.
+ */
+struct core_dispatch cmh_core_select_instance(enum cmh_core_type type)
+{
+	struct core_type_info *ct;
+	struct core_instance_info *inst;
+	struct core_dispatch d;
+	u32 idx, count;
+	s32 mbx, new_mbx, old;
+
+	if (WARN_ON_ONCE(type >= CMH_NUM_CORE_TYPES))
+		return (struct core_dispatch){ .core_id = CORE_ID_NUM, .mbx_idx = -1 };
+
+	ct = &core_types[type];
+
+	/*
+	 * A core type absent from CORE_ENABLE has num_instances == 0 (algs
+	 * for it should never have been reached).  Return CORE_ID_NUM, the
+	 * out-of-range core sentinel: if a caller ignores this and submits,
+	 * the eSW rejects the unknown core rather than the VCQ landing on
+	 * CORE_ID_SYS (0).  Also avoids the divide-by-zero below.
+	 */
+	if (WARN_ONCE(!ct->num_instances,
+		      "cmh: dispatch for absent core type %u\n", type))
+		return (struct core_dispatch){ .core_id = CORE_ID_NUM, .mbx_idx = -1 };
+
+	idx = (u32)atomic_inc_return(&ct->next_instance) % ct->num_instances;
+	inst = &ct->instances[idx];
+
+	d.core_id = inst->core_id;
+
+	mbx = atomic_read(&inst->mbx_idx);
+	if (mbx >= 0) {
+		d.mbx_idx = mbx;
+		return d;
+	}
+
+	/* Auto-assign on first use */
+	count = tm.cfg->mbx_count;
+	new_mbx = (s32)((u32)atomic_inc_return(&affinity_next_mbx) % count);
+	old = atomic_cmpxchg(&inst->mbx_idx, -1, new_mbx);
+
+	if (old >= 0)
+		d.mbx_idx = old;
+	else
+		d.mbx_idx = new_mbx;
+
+	return d;
+}
+
+/**
+ * cmh_core_num_instances() - Return instance count for a core type
+ * @type: Core type selector
+ *
+ * Return: Number of configured instances for @type, or 0 if the core is
+ *         absent from the CORE_ENABLE register.
+ */
+u32 cmh_core_num_instances(enum cmh_core_type type)
+{
+	if (WARN_ON_ONCE(type >= CMH_NUM_CORE_TYPES))
+		return 1;
+
+	return core_types[type].num_instances;
+}
+
+/**
+ * cmh_core_get_instance() - Get dispatch info for a specific instance
+ * @type: Core type selector
+ * @idx: Instance index within @type
+ *
+ * Returns (core_id, mbx_idx) for a specific instance by index,
+ * without advancing the round-robin counter.  Triggers MBX auto-assign
+ * on first use if the instance has no MBX yet.
+ *
+ * Return: A core_dispatch with (core_id, mbx_idx) for instance @idx.
+ */
+struct core_dispatch cmh_core_get_instance(enum cmh_core_type type, u32 idx)
+{
+	struct core_type_info *ct;
+	struct core_instance_info *inst;
+	struct core_dispatch d;
+	u32 count;
+	s32 mbx, new_mbx, old;
+
+	if (WARN_ON_ONCE(type >= CMH_NUM_CORE_TYPES))
+		return (struct core_dispatch){ .core_id = CORE_ID_NUM, .mbx_idx = -1 };
+
+	ct = &core_types[type];
+	if (WARN_ON_ONCE(idx >= ct->num_instances))
+		return (struct core_dispatch){ .core_id = CORE_ID_NUM, .mbx_idx = -1 };
+
+	inst = &ct->instances[idx];
+	d.core_id = inst->core_id;
+
+	mbx = atomic_read(&inst->mbx_idx);
+	if (mbx >= 0) {
+		d.mbx_idx = mbx;
+		return d;
+	}
+
+	/* Auto-assign on first use */
+	count = tm.cfg->mbx_count;
+	new_mbx = (s32)((u32)atomic_inc_return(&affinity_next_mbx) % count);
+	old = atomic_cmpxchg(&inst->mbx_idx, -1, new_mbx);
+
+	if (old >= 0)
+		d.mbx_idx = old;
+	else
+		d.mbx_idx = new_mbx;
+
+	return d;
+}
+
+/**
+ * cmh_tm_txq_completion_notify() - Wake TM thread after RH completion
+ *
+ * Wakes the TM thread after the Response Handler completes a
+ * transaction.  This unblocks the TM if it is waiting for a free MBX
+ * slot.  The generation counter bump ensures the wait_event predicate
+ * evaluates to true on the next check.
+ */
+void cmh_tm_txq_completion_notify(void)
+{
+	atomic_inc(&txq_completion_gen);
+	wake_up_interruptible(&tm.cmq_waitq);
+}
+
+/**
+ * cmh_tm_mbx_admit() - Open or close a mailbox to new submissions
+ * @mbx_idx: Mailbox index
+ * @open: true to accept submissions again, false to stop them
+ *
+ * Closed while the Response Handler waits for the eSW to acknowledge a
+ * FLUSH, so that no VCQ is published that the FLUSH could discard or the
+ * post-FLUSH drain could pop.  submit_vcq() checks the flag under the same
+ * txq->lock it publishes and rings the doorbell under, so a close is
+ * atomic with respect to publication.  Requests for a closed mailbox wait
+ * in the CMQ.  Safe from softirq context.
+ */
+void cmh_tm_mbx_admit(u32 mbx_idx, bool open)
+{
+	unsigned long flags;
+
+	if (!tm.txqs || mbx_idx >= tm.cfg->mbx_count)
+		return;
+
+	spin_lock_irqsave(&tm.txqs[mbx_idx].lock, flags);
+	WRITE_ONCE(tm.txqs[mbx_idx].closed, !open);
+	spin_unlock_irqrestore(&tm.txqs[mbx_idx].lock, flags);
+
+	/* Let requests that waited for this mailbox be dispatched. */
+	if (open)
+		cmh_tm_txq_completion_notify();
+}
+
+/* Mailbox Selection */
+
+/*
+ * Select a mailbox with at least @slots_needed free slots (round-robin),
+ * skipping wedged mailboxes and those closed while a FLUSH is pending.
+ * Returns a mailbox index, or a negative errno: -EAGAIN (all usable
+ * mailboxes transiently full or closed), -EIO (every mailbox is wedged),
+ * or -EMSGSIZE (no usable ring can ever hold the request).
+ *
+ * Note: the free-slot check here is advisory -- actual slot availability
+ * is enforced by the ring arithmetic under dispatch_lock in submit_vcq().
+ * A TOCTOU gap exists between this check and the subsequent slot write,
+ * but it is safe: the worst case is a spurious -EAGAIN / backoff, never
+ * a ring overcommit.
+ */
+static int select_mailbox(u32 slots_needed)
+{
+	u32 count = tm.cfg->mbx_count;
+	u32 start = tm.next_mbx;
+	bool fits_anywhere = false;
+	bool any_usable = false;
+	u32 i;
+
+	for (i = 0; i < count; i++) {
+		u32 idx = (start + i) % count;
+		struct cmh_mbx_config *m = &tm.cfg->mailboxes[idx];
+
+		if (cmh_rh_mbx_is_wedged(idx))
+			continue;
+		any_usable = true;
+
+		/* Could this ring ever hold the request, once drained? */
+		if ((1U << m->slots_log2) >= slots_needed)
+			fits_anywhere = true;
+
+		/* Recovering: transiently unavailable (submit_vcq rechecks). */
+		if (READ_ONCE(tm.txqs[idx].closed))
+			continue;
+
+		if (mbx_free_slots(m) >= slots_needed) {
+			tm.next_mbx = (idx + 1) % count;
+			return (int)idx;
+		}
+		cmh_stat_inc_mbx_queue_full(idx);
+	}
+
+	/* Every mailbox is wedged: the request can never be placed. */
+	if (!any_usable)
+		return -EIO;
+
+	/*
+	 * No mailbox had room now.  If no (non-wedged) mailbox's ring is
+	 * even large enough to ever hold the request, it can never be
+	 * placed -- report a permanent error so the caller fails it rather
+	 * than spinning forever (head-of-line block).
+	 */
+	return fits_anywhere ? -EAGAIN : -EMSGSIZE;
+}
+
+/*
+ * Resolve the target mailbox for a command message.
+ *
+ * If the message has a pinned MBX and it has enough free slots, use it.
+ * Otherwise fall back to round-robin selection.  Returns a mailbox index,
+ * or a negative errno: -EAGAIN (transiently full or recovering -- retry),
+ * -EIO (the pinned MBX, or every MBX, is permanently wedged -- fail the
+ * request), or -EMSGSIZE (can never fit any eligible ring).
+ */
+static int resolve_mbx(struct command_msg *msg)
+{
+	u32 slots = msg->num_vcqs > 0 ? msg->num_vcqs : 1;
+
+	if (msg->target_mbx >= 0 &&
+	    (u32)msg->target_mbx < tm.cfg->mbx_count) {
+		struct cmh_mbx_config *m =
+			&tm.cfg->mailboxes[msg->target_mbx];
+
+		if (cmh_rh_mbx_is_wedged((u32)msg->target_mbx))
+			return -EIO; /* pinned mbx wedged: fail, do not spin */
+		if ((1U << m->slots_log2) < slots)
+			return -EMSGSIZE; /* never fits this pinned ring */
+		if (READ_ONCE(tm.txqs[msg->target_mbx].closed))
+			return -EAGAIN; /* FLUSH pending, retry */
+		if (mbx_free_slots(m) >= slots)
+			return msg->target_mbx;
+		return -EAGAIN; /* pinned MBX full, retry */
+	}
+
+	return select_mailbox(slots);
+}
+
+/* VCQ Submission */
+
+/*
+ * Serialise all writes to R_MBX_QUEUE_TAIL.  submit_vcq()'s doorbell
+ * advances TAIL while the response handler's cmh_tm_poke_tail()
+ * re-writes the current TAIL to wake the eSW.  The latter is a
+ * read-modify-write running from softirq/timer context on another CPU,
+ * so without this lock it could read a stale TAIL and roll back a
+ * concurrent doorbell, dropping submitted VCQs.
+ */
+static DEFINE_SPINLOCK(cmh_mbx_tail_lock);
+
+/**
+ * cmh_tm_poke_tail() - Re-write R_MBX_QUEUE_TAIL to wake the eSW
+ * @base: Mailbox register base
+ *
+ * Writing the current TAIL back is a queue no-op but generates a fresh
+ * SIC interrupt edge so the eSW wakes from WFI.  Serialised against the
+ * submit_vcq() doorbell so the read-modify-write cannot roll back a
+ * concurrent submission.  Safe from softirq/timer context.
+ */
+void cmh_tm_poke_tail(void __iomem *base)
+{
+	unsigned long flags;
+	u32 tail;
+
+	spin_lock_irqsave(&cmh_mbx_tail_lock, flags);
+	tail = cmh_reg_read32(base, R_MBX_QUEUE_TAIL);
+	cmh_reg_write32(tail, base, R_MBX_QUEUE_TAIL);
+	spin_unlock_irqrestore(&cmh_mbx_tail_lock, flags);
+}
+
+/*
+ * Write VCQ(s) into consecutive DMA slots and ring the doorbell.
+ *
+ * A command_msg may carry one or more VCQs (num_vcqs field).  For a
+ * multi-VCQ message the flat vcq_data array contains N VCQs laid out
+ * contiguously, each starting with its own header whose cmds field
+ * gives that VCQ's entry count.  All VCQs are written to consecutive
+ * MBX slots and tracked by a single transaction_obj.
+ *
+ * Returns 0 on success, -EAGAIN if the mailbox is closed for recovery
+ * (nothing published; dispatch again later), or another negative errno.
+ */
+static int submit_vcq(struct command_msg *msg, u32 mbx_idx)
+{
+	struct cmh_mbx_config *mbx = &tm.cfg->mailboxes[mbx_idx];
+	struct cmh_mbx_txq *txq = &tm.txqs[mbx_idx];
+	struct transaction_obj *txn;
+	const struct vcq_cmd *cmds = msg->vcq_data;
+	u32 num_vcqs = msg->num_vcqs > 0 ? msg->num_vcqs : 1;
+	u32 tail, stride_bytes, offset = 0;
+	unsigned long flags;
+	u32 v;
+
+	mutex_lock(&txq->dispatch_lock);
+
+	/* Read current tail (first VCQ ID) */
+	tail = cmh_reg_read32(mbx->reg_base, R_MBX_QUEUE_TAIL);
+	stride_bytes = 1U << mbx->stride_log2;
+
+	/* Allocate transaction tracking object */
+	txn = kzalloc_obj(*txn, GFP_KERNEL);
+	if (!txn) {
+		mutex_unlock(&txq->dispatch_lock);
+		return -ENOMEM;
+	}
+
+	/* Write each VCQ into a consecutive DMA slot */
+	for (v = 0; v < num_vcqs; v++) {
+		u32 vcq_cmds, copy_size;
+		void *slot;
+
+		/*
+		 * For single-VCQ messages (backward compat) use the
+		 * msg-level vcq_count.  For multi-VCQ, parse the per-VCQ
+		 * header to find each VCQ's command count.
+		 */
+		if (num_vcqs == 1) {
+			vcq_cmds = msg->vcq_count;
+		} else {
+			const struct vcq_hdr *hdr;
+
+			/* Bound the per-VCQ header read within vcq_data. */
+			if (offset >= msg->vcq_count) {
+				dev_err(cmh_dev(),
+					"tm: multi-VCQ %u offset OOB\n", v);
+				mutex_unlock(&txq->dispatch_lock);
+				kfree(txn);
+				return -EINVAL;
+			}
+			hdr = (const struct vcq_hdr *)&cmds[offset].hwc;
+			vcq_cmds = hdr->cmds;
+		}
+
+		copy_size = vcq_cmds * sizeof(struct vcq_cmd);
+		if (copy_size > stride_bytes) {
+			dev_err(cmh_dev(), "tm: VCQ %u too large (%u bytes > stride %u)\n",
+				v, copy_size, stride_bytes);
+			mutex_unlock(&txq->dispatch_lock);
+			kfree(txn);
+			return -EMSGSIZE;
+		}
+
+		if (vcq_cmds < MIN_VCQ_CMDS || vcq_cmds > MAX_VCQ_CMDS) {
+			dev_err(cmh_dev(), "tm: invalid vcq_count %u (range %u..%u)\n",
+				vcq_cmds, MIN_VCQ_CMDS, MAX_VCQ_CMDS);
+			mutex_unlock(&txq->dispatch_lock);
+			kfree(txn);
+			return -EINVAL;
+		}
+
+		/* Bound the VCQ body within vcq_data. */
+		if (vcq_cmds > msg->vcq_count - offset) {
+			dev_err(cmh_dev(),
+				"tm: VCQ %u body exceeds vcq_data\n", v);
+			mutex_unlock(&txq->dispatch_lock);
+			kfree(txn);
+			return -EINVAL;
+		}
+
+		/* Copy pre-built VCQ into DMA slot */
+		slot = mbx_slot_ptr(mbx, tail + v);
+		cmh_dma_write(slot, &cmds[offset], copy_size);
+
+		/* Zero remaining slot bytes to avoid stale data */
+		if (copy_size < stride_bytes)
+			cmh_dma_zero((u8 *)slot + copy_size,
+				     stride_bytes - copy_size);
+
+		offset += vcq_cmds;
+	}
+
+	/* Ensure VCQ data is visible in memory before advancing tail */
+	wmb();
+	/* FPGA: confirm DRAM accepted writes before SIC doorbell (cross-slave) */
+	cmh_dma_fence(mbx_slot_ptr(mbx, tail + num_vcqs - 1));
+
+	/* Fill in transaction spanning all VCQs */
+	txn->first_vcq_id = tail;
+	txn->last_vcq_id = tail + num_vcqs - 1;
+	txn->mailbox_idx = mbx_idx;
+	txn->command_id = msg->command_id;
+	txn->error_code = 0;
+	txn->complete = msg->complete;
+	txn->completion_data = msg->completion_data;
+	txn->rdma = msg->rdma;
+	atomic_set(&txn->state, TXN_INFLIGHT);
+	timer_setup(&txn->timeout_timer, txn_timeout_fn, 0);
+	INIT_LIST_HEAD(&txn->list);
+
+	/*
+	 * Set refcount: 2 if a per-txn timer will be armed (one ref for
+	 * the TXQ owner that pops it, one for the timer callback), or 1
+	 * if no timer (sync paths, or async_timeout_ms == 0).
+	 */
+	if (msg->timeout_jiffies)
+		refcount_set(&txn->refs, 2);
+	else
+		refcount_set(&txn->refs, 1);
+
+	/*
+	 * Publish the transaction, arm its timeout and ring the doorbell while
+	 * holding txq->lock, so it becomes visible on the queue and live
+	 * (doorbelled) atomically.  An error drain (cmh_rh_drain_mbx) pops
+	 * under txq->lock, so it can no longer observe the txn on the queue
+	 * before its doorbell and free a VCQ that was never launched.  The
+	 * timer is still armed before the doorbell so a HW completion that
+	 * pops the txn can always drop the timer ref.  cmh_mbx_tail_lock nests
+	 * inside txq->lock (poke_tail only ever takes cmh_mbx_tail_lock, so the
+	 * ordering is consistent).
+	 *
+	 * A mailbox closed by cmh_tm_mbx_admit() (FLUSH pending) must not get
+	 * new work: the slots written above lie beyond TAIL, which the eSW
+	 * never reads, so returning -EAGAIN here simply leaves the message to
+	 * be dispatched again later.
+	 */
+	spin_lock_irqsave(&txq->lock, flags);
+	if (txq->closed) {
+		spin_unlock_irqrestore(&txq->lock, flags);
+		mutex_unlock(&txq->dispatch_lock);
+		kfree(txn);
+		return -EAGAIN;
+	}
+	/* Expose the HW VCQ id so a sync timeout can check HEAD. */
+	WRITE_ONCE(msg->first_vcq_id, tail);
+	list_add_tail(&txn->list, &txq->head);
+	txq->depth++;
+
+	if (msg->timeout_jiffies)
+		mod_timer(&txn->timeout_timer,
+			  jiffies + msg->timeout_jiffies);
+
+	spin_lock(&cmh_mbx_tail_lock);
+	cmh_reg_write32(tail + num_vcqs, mbx->reg_base, R_MBX_QUEUE_TAIL);
+	spin_unlock(&cmh_mbx_tail_lock);
+	spin_unlock_irqrestore(&txq->lock, flags);
+
+	mutex_unlock(&txq->dispatch_lock);
+
+	cmh_stat_record_vcq_submit(mbx_idx, num_vcqs, txq->depth);
+
+	dev_dbg(cmh_dev(), "tm: submitted %u vcq(s) id=%u..%u to mbx[%u] tail_now=%u\n",
+		num_vcqs, tail, tail + num_vcqs - 1, mbx_idx,
+		 tail + num_vcqs);
+
+	return 0;
+}
+
+/* TM Thread */
+
+/*
+ * Promote one backlogged request into a just-freed CMQ slot and deliver its
+ * initial -EINPROGRESS.  Called after a CMQ entry has been consumed
+ * (dispatched or rejected), or when the CMQ has drained while the backlog is
+ * non-empty so a backlog entry is never stranded.  A concurrent
+ * cmh_tm_post_command() racing between the consume and this promote can
+ * transiently push cmq_depth one past cmq_max_depth -- a soft accounting bound
+ * on a linked list, not an overflow; it subsides as the queue drains
+ * (dequeues outpace promotion once the backlog empties).
+ */
+static void cmh_tm_promote_backlog(void)
+{
+	struct command_msg *bl;
+	unsigned long flags;
+
+	spin_lock_irqsave(&tm.cmq_lock, flags);
+	bl = list_first_entry_or_null(&tm.backlog, struct command_msg, list);
+	if (bl) {
+		list_move_tail(&bl->list, &tm.cmq);
+		tm.backlog_depth--;
+		cmq_depth++;
+		cmh_stat_record_cmq_post(cmq_depth);
+	}
+	spin_unlock_irqrestore(&tm.cmq_lock, flags);
+
+	/*
+	 * Signal -EINPROGRESS with cmq_lock dropped: a consumer that resubmits
+	 * from this callback would otherwise re-enter cmq_lock and deadlock.
+	 */
+	if (bl && bl->complete)
+		bl->complete(bl->completion_data, -EINPROGRESS);
+}
+
+/*
+ * Deliver a final status from process context (TM kthread, drains) with
+ * BH disabled, matching the response-handler completions.
+ */
+static void cmh_tm_msg_finish(struct command_msg *msg, int err)
+{
+	if (!msg->complete)
+		return;
+	local_bh_disable();
+	msg->complete(msg->completion_data, err);
+	local_bh_enable();
+}
+
+/*
+ * No mailbox can take @msg yet (rings full, or closed while a FLUSH is
+ * pending): put it back at the head of the CMQ and wait for a completion
+ * or a reopened mailbox.
+ *
+ * Sleep on cmq_waitq with a short timeout.  The RH calls
+ * cmh_tm_txq_completion_notify() after each completed transaction and when
+ * a mailbox reopens, which bumps the generation counter and wakes us
+ * immediately.  The timeout is a safety net for missed wakeups.
+ */
+static void cmh_tm_requeue_wait(struct command_msg *msg)
+{
+	int gen = atomic_read(&txq_completion_gen);
+	unsigned long flags, tmo;
+
+	spin_lock_irqsave(&tm.cmq_lock, flags);
+	list_add(&msg->list, &tm.cmq);
+	cmq_depth++;
+	spin_unlock_irqrestore(&tm.cmq_lock, flags);
+
+	tmo = usecs_to_jiffies(CMH_TM_BACKOFF_MAX_US);
+	wait_event_interruptible_timeout(tm.cmq_waitq,
+					 kthread_should_stop() ||
+					 atomic_read(&txq_completion_gen) != gen,
+					 tmo ?: 1);
+	cmh_stat_inc_tm_backoff();
+}
+
+static int cmh_tm_thread(void *data)
+{
+	struct command_msg *msg;
+	unsigned long flags;
+	int mbx_idx, ret;
+
+	while (!kthread_should_stop()) {
+		/* Wait for work or stop signal */
+		wait_event_interruptible(tm.cmq_waitq,
+					 !list_empty(&tm.cmq) ||
+					 !list_empty(&tm.backlog) ||
+					 kthread_should_stop());
+
+		if (kthread_should_stop())
+			break;
+
+		/* Dequeue one command message */
+		spin_lock_irqsave(&tm.cmq_lock, flags);
+		if (list_empty(&tm.cmq)) {
+			spin_unlock_irqrestore(&tm.cmq_lock, flags);
+			/*
+			 * CMQ is empty but requests may still be backlogged
+			 * (e.g. the CMQ entries were cancelled): promote one so
+			 * it makes progress instead of being stranded.
+			 */
+			cmh_tm_promote_backlog();
+			continue;
+		}
+		msg = list_first_entry(&tm.cmq, struct command_msg, list);
+		list_del_init(&msg->list);
+		cmq_depth--;
+		spin_unlock_irqrestore(&tm.cmq_lock, flags);
+
+		/* Select a mailbox: pinned or round-robin */
+		mbx_idx = resolve_mbx(msg);
+
+		if (mbx_idx == -EMSGSIZE) {
+			/*
+			 * The request needs more ring slots than any mailbox
+			 * can ever provide.  Fail it rather than re-queuing:
+			 * retrying would spin forever and head-of-line block
+			 * every other request.
+			 */
+			dev_err(cmh_dev(),
+				"tm: cmd=0x%08x needs %u VCQs, exceeds ring capacity -- rejecting\n",
+				msg->command_id,
+				msg->num_vcqs > 0 ? msg->num_vcqs : 1);
+			cmh_tm_msg_finish(msg, -EMSGSIZE);
+			command_msg_put(msg);
+			cmh_tm_promote_backlog();
+			continue;
+		}
+
+		if (mbx_idx == -EIO) {
+			/*
+			 * The pinned target mailbox, or every mailbox, is
+			 * permanently wedged.  Fail this request rather than
+			 * re-queuing it forever and head-of-line blocking the
+			 * CMQ.  It never reached the device, so complete it
+			 * with -ENODEV (no usable mailbox), not the -EIO a
+			 * device failure reports.
+			 */
+			if (msg->target_mbx >= 0 &&
+			    (u32)msg->target_mbx < tm.cfg->mbx_count)
+				dev_err_ratelimited(cmh_dev(),
+						    "tm: cmd=0x%08x pinned mbx %d wedged -- rejecting\n",
+						    msg->command_id,
+						    msg->target_mbx);
+			else
+				dev_err_ratelimited(cmh_dev(),
+						    "tm: cmd=0x%08x all mailboxes wedged -- rejecting\n",
+						    msg->command_id);
+			cmh_tm_msg_finish(msg, -ENODEV);
+			command_msg_put(msg);
+			cmh_tm_promote_backlog();
+			continue;
+		}
+
+		if (mbx_idx < 0) {
+			/* Rings full or mailboxes recovering -- retry. */
+			cmh_tm_requeue_wait(msg);
+			continue;
+		}
+
+		/* Submit VCQ to selected mailbox */
+		WRITE_ONCE(msg->actual_mbx, mbx_idx);
+		ret = submit_vcq(msg, mbx_idx);
+		if (ret == -EAGAIN) {
+			/* Closed for recovery after selection -- retry. */
+			WRITE_ONCE(msg->actual_mbx, -1);
+			cmh_tm_requeue_wait(msg);
+			continue;
+		}
+		if (ret)
+			cmh_tm_msg_finish(msg, ret);
+		command_msg_put(msg);
+
+		/* The dispatched CMQ slot is free -- refill it from backlog. */
+		cmh_tm_promote_backlog();
+	}
+
+	return 0;
+}
+
+/* Public Interface */
+
+/**
+ * cmh_tm_init() - Initialize the Transaction Manager subsystem
+ * @cfg: Hardware configuration describing mailboxes and core types
+ *
+ * Allocates per-mailbox transaction queues, applies core-type
+ * configuration, and starts the TM kthread.
+ *
+ * Return: 0 on success, negative errno on failure.
+ */
+int cmh_tm_init(struct cmh_config *cfg)
+{
+	u32 i, j;
+
+	tm.cfg = cfg;
+	tm.next_mbx = 0;
+	cmq_depth = 0;
+
+	cmh_tm_affinity_reset();
+
+	/* Apply per-core-type config from DT child nodes */
+	for (i = 0; i < CMH_NUM_CORE_TYPES; i++) {
+		struct cmh_core_type_cfg *src = &cfg->core_types[i];
+		struct core_type_info *ct = &core_types[i];
+
+		ct->num_instances = src->num_instances;
+		for (j = 0; j < src->num_instances; j++) {
+			ct->instances[j].core_id = src->core_ids[j];
+			if (src->mbx[j] >= 0)
+				atomic_set(&ct->instances[j].mbx_idx,
+					   src->mbx[j]);
+		}
+	}
+
+	/* Initialize CMQ and backlog */
+	INIT_LIST_HEAD(&tm.cmq);
+	INIT_LIST_HEAD(&tm.backlog);
+	tm.backlog_depth = 0;
+	spin_lock_init(&tm.cmq_lock);
+	init_waitqueue_head(&tm.cmq_waitq);
+
+	/* Allocate per-mailbox transaction queues */
+	tm.txqs = kcalloc(cfg->mbx_count, sizeof(*tm.txqs), GFP_KERNEL);
+	if (!tm.txqs)
+		return -ENOMEM;
+
+	for (i = 0; i < cfg->mbx_count; i++) {
+		INIT_LIST_HEAD(&tm.txqs[i].head);
+		spin_lock_init(&tm.txqs[i].lock);
+		mutex_init(&tm.txqs[i].dispatch_lock);
+		tm.txqs[i].depth = 0;
+	}
+
+	/* Start TM thread */
+	tm.thread = kthread_run(cmh_tm_thread, NULL, "cmh_tm");
+	if (IS_ERR(tm.thread)) {
+		int ret = PTR_ERR(tm.thread);
+
+		dev_err(cmh_dev(), "tm: failed to start thread (rc=%d)\n", ret);
+		tm.thread = NULL;
+		kfree(tm.txqs);
+		tm.txqs = NULL;
+		return ret;
+	}
+
+	WRITE_ONCE(tm.running, true);
+
+	return 0;
+}
+
+/*
+ * cmh_tm_stop_and_drain_cmq() - Stop TM thread and drain CMQ/backlog
+ *
+ * Shared preamble for cmh_tm_cleanup() and cmh_tm_quiesce(): stops the
+ * kthread, marks the TM as not running, then splices the CMQ and backlog
+ * to local lists and cancels every pending command_msg outside the lock.
+ */
+static void cmh_tm_stop_and_drain_cmq(void)
+{
+	struct command_msg *msg;
+	unsigned long flags;
+
+	if (tm.thread) {
+		kthread_stop(tm.thread);
+		tm.thread = NULL;
+	}
+	WRITE_ONCE(tm.running, false);
+
+	/*
+	 * Pop each queued command under cmq_lock and cancel it with the lock
+	 * dropped.  list_del_init() fully detaches the node before we release
+	 * the lock, so a concurrent cmh_tm_try_cancel_command() either removes
+	 * the node before we reach it or sees list_empty() and backs off -- it
+	 * can no longer list_del a node that this drain is walking on a private
+	 * list.  Completion callbacks run with cmq_lock dropped (they may
+	 * resubmit or take sleeping locks).
+	 */
+	for (;;) {
+		spin_lock_irqsave(&tm.cmq_lock, flags);
+		msg = list_first_entry_or_null(&tm.cmq, struct command_msg,
+					       list);
+		if (msg) {
+			list_del_init(&msg->list);
+			cmq_depth--;
+		}
+		spin_unlock_irqrestore(&tm.cmq_lock, flags);
+		if (!msg)
+			break;
+		cmh_tm_msg_finish(msg, -ECANCELED);
+		command_msg_put(msg);
+	}
+
+	for (;;) {
+		spin_lock_irqsave(&tm.cmq_lock, flags);
+		msg = list_first_entry_or_null(&tm.backlog, struct command_msg,
+					       list);
+		if (msg) {
+			list_del_init(&msg->list);
+			tm.backlog_depth--;
+		}
+		spin_unlock_irqrestore(&tm.cmq_lock, flags);
+		if (!msg)
+			break;
+		if (msg->complete) {
+			/*
+			 * Backlogged requests returned -EBUSY from post and
+			 * never got their initial -EINPROGRESS.  A MAY_BACKLOG
+			 * waiter (e.g. dm-crypt) blocks for that notification
+			 * before the final status, so issue it before
+			 * -ECANCELED to release the waiter.
+			 */
+			msg->complete(msg->completion_data, -EINPROGRESS);
+			cmh_tm_msg_finish(msg, -ECANCELED);
+		}
+		command_msg_put(msg);
+	}
+}
+
+/**
+ * cmh_tm_stop() - Stop accepting and dispatching new work
+ *
+ * Stops the TM kthread and cancels everything still queued in the CMQ
+ * and backlog with -ECANCELED.  In-flight transactions are left to
+ * complete through the Response Handler.  Idempotent.
+ */
+void cmh_tm_stop(void)
+{
+	cmh_tm_stop_and_drain_cmq();
+}
+
+/*
+ * Complete every transaction still on mailbox @i's queue.  The Response
+ * Handler must be stopped, so this drain owns them exclusively.  If
+ * @dma_live the device may still access their DMA, so each request's DMA
+ * set is quarantined and the transaction completes with -ETIMEDOUT
+ * (unresponsive device); otherwise it completes with -ECANCELED.
+ * Transactions whose async timer already fired complete with -ETIMEDOUT.
+ */
+static void cmh_tm_drain_txq(u32 i, bool dma_live)
+{
+	struct transaction_obj *txn, *tmp_txn;
+	unsigned long flags;
+	LIST_HEAD(drain);
+	int old;
+
+	spin_lock_irqsave(&tm.txqs[i].lock, flags);
+	list_splice_init(&tm.txqs[i].head, &drain);
+	tm.txqs[i].depth = 0;
+	spin_unlock_irqrestore(&tm.txqs[i].lock, flags);
+
+	list_for_each_entry_safe(txn, tmp_txn, &drain, list) {
+		list_del(&txn->list);
+
+		if (timer_delete_sync(&txn->timeout_timer))
+			txn_put(txn);
+
+		old = atomic_cmpxchg(&txn->state, TXN_INFLIGHT, TXN_COMPLETE);
+		if (dma_live)
+			cmh_txn_quarantine(txn);
+		if (txn->complete) {
+			/* Process context: complete with BH disabled. */
+			local_bh_disable();
+			if (old == TXN_INFLIGHT)
+				txn->complete(txn->completion_data,
+					      dma_live ? -ETIMEDOUT :
+							 -ECANCELED);
+			else if (old == TXN_TIMED_OUT)
+				txn->complete(txn->completion_data,
+					      -ETIMEDOUT);
+			local_bh_enable();
+		}
+
+		txn_put(txn);
+	}
+}
+
+/**
+ * cmh_tm_cleanup() - Tear down the Transaction Manager subsystem
+ *
+ * Stops the TM kthread (if cmh_tm_stop() has not already), FLUSHes every
+ * mailbox and drains the per-mailbox transaction queues, then releases
+ * all TM-owned resources.
+ *
+ * The caller (cmh_remove) stops the TM and then runs cmh_rh_cleanup(),
+ * which cancels the watchdog, masks the MBX interrupts and frees the IRQ
+ * handlers, so the Response Handler can no longer deliver a completion
+ * and this drain owns every remaining transaction.  Before releasing any
+ * DMA, cmh_mqi_settle_all() FLUSHes every mailbox and waits for the eSW
+ * to acknowledge, i.e. to quiesce the cores and DMA engines back to
+ * MBX_STATUS_IDLE.  This HW has no DMA-stop primitive, so for a mailbox
+ * that does not acknowledge, its transactions' DMA is quarantined, and
+ * the quarantine (including buffers held from earlier recoveries) is
+ * released only if every mailbox acknowledged; otherwise it is leaked.
+ */
+void cmh_tm_cleanup(void)
+{
+	bool fenced = true;
+	u32 i;
+
+	cmh_tm_stop_and_drain_cmq();
+
+	if (tm.cfg)
+		fenced = cmh_mqi_settle_all(tm.cfg);
+
+	if (tm.cfg && tm.txqs) {
+		for (i = 0; i < tm.cfg->mbx_count; i++)
+			cmh_tm_drain_txq(i, !tm.cfg->mailboxes[i].fenced);
+		kfree(tm.txqs);
+		tm.txqs = NULL;
+	}
+
+	cmh_dma_quarantine_release(fenced);
+}
+
+/*
+ * Default drain timeout for suspend/quiesce (milliseconds).
+ * Covers ordinary operations; a slow one (e.g. a hash-based signature)
+ * still running at the deadline makes the suspend be refused.
+ */
+static unsigned int drain_timeout_ms = 10000;
+
+/**
+ * cmh_tm_quiesce() - Quiesce the TM for suspend
+ *
+ * Stops the TM kthread and drains the CMQ and backlog, then waits up to
+ * drain_timeout_ms for in-flight transactions to complete via the
+ * Response Handler.  In-flight work is never cancelled: this HW has no
+ * DMA-stop primitive, so if any is still running at the deadline the TM
+ * is restarted and the suspend is refused.
+ *
+ * Return: 0 once drained, -EBUSY if work is still in flight.
+ */
+int cmh_tm_quiesce(void)
+{
+	unsigned long deadline;
+	bool drained;
+	u32 i;
+
+	cmh_tm_stop_and_drain_cmq();
+
+	/* Wait for in-flight TXQ transactions to complete via RH */
+	if (!tm.txqs)
+		return 0;
+
+	deadline = jiffies + msecs_to_jiffies(drain_timeout_ms);
+	do {
+		drained = true;
+		for (i = 0; i < tm.cfg->mbx_count; i++) {
+			if (READ_ONCE(tm.txqs[i].depth)) {
+				drained = false;
+				break;
+			}
+		}
+		if (drained)
+			return 0;
+		usleep_range(1000, 2000);
+	} while (time_before(jiffies, deadline));
+
+	dev_warn(cmh_dev(),
+		 "tm: work still in flight after %u ms, refusing suspend\n",
+		 drain_timeout_ms);
+	if (cmh_tm_resume())
+		dev_err(cmh_dev(), "tm: could not restart after refused suspend\n");
+	return -EBUSY;
+}
+
+/**
+ * cmh_tm_resume() - Resume the TM after suspend
+ *
+ * Restarts the TM kthread after a prior cmh_tm_quiesce().
+ *
+ * Return: 0 on success, negative errno if kthread creation fails.
+ */
+int cmh_tm_resume(void)
+{
+	if (tm.thread || !tm.cfg)
+		return 0;
+
+	tm.thread = kthread_run(cmh_tm_thread, NULL, "cmh_tm");
+	if (IS_ERR(tm.thread)) {
+		int ret = PTR_ERR(tm.thread);
+
+		dev_err(cmh_dev(), "tm: resume kthread_run failed (%d)\n",
+			ret);
+		tm.thread = NULL;
+		return ret;
+	}
+	WRITE_ONCE(tm.running, true);
+	return 0;
+}
+
+/**
+ * cmh_tm_try_cancel_command() - Cancel a queued command message
+ * @msg: Command message to cancel
+ *
+ * Attempts to remove @msg from the CMQ before the TM thread dequeues
+ * it.  Must be called while @msg is still valid (before the caller's
+ * stack frame that owns it is freed).
+ *
+ * Return: true if @msg was removed, false if already consumed by TM.
+ */
+bool cmh_tm_try_cancel_command(struct command_msg *msg)
+{
+	unsigned long flags;
+	bool cancelled = false;
+
+	spin_lock_irqsave(&tm.cmq_lock, flags);
+	if (!list_empty(&msg->list)) {
+		list_del_init(&msg->list);
+		cmq_depth--;
+		cancelled = true;
+	}
+	spin_unlock_irqrestore(&tm.cmq_lock, flags);
+
+	/* A freed CMQ slot may let a backlogged request run -- wake the TM. */
+	if (cancelled)
+		wake_up_interruptible(&tm.cmq_waitq);
+
+	return cancelled;
+}
+
+/**
+ * cmh_tm_post_command() - Post a command message to the CMQ
+ * @msg: Pre-built command message to enqueue
+ *
+ * Enqueues @msg on the Command Message Queue and wakes the TM thread.
+ * If the CMQ is full, the message is placed on the (unbounded) backlog
+ * queue, returning -EBUSY, if @msg->backlog_ok is set, or rejected with
+ * -ENOSPC (the crypto_enqueue_request() convention).
+ *
+ * Return: 0 on success, -EBUSY if backlogged, -ENOSPC if full,
+ *         -ENODEV if TM is not running.
+ */
+int cmh_tm_post_command(struct command_msg *msg)
+{
+	unsigned long flags;
+
+	spin_lock_irqsave(&tm.cmq_lock, flags);
+	/*
+	 * Re-check tm.running under cmq_lock.  cmh_tm_stop_and_drain_cmq()
+	 * clears it and then splices the CMQ under this same lock, so a post
+	 * that wins the lock after the drain sees !running and bails, while
+	 * one that wins before is caught by the splice -- neither leaks a
+	 * message onto a queue nobody will service.
+	 */
+	if (!READ_ONCE(tm.running)) {
+		spin_unlock_irqrestore(&tm.cmq_lock, flags);
+		return -ENODEV;
+	}
+	if (cmq_depth >= cmq_max_depth) {
+		if (msg->backlog_ok) {
+			list_add_tail(&msg->list, &tm.backlog);
+			tm.backlog_depth++;
+			spin_unlock_irqrestore(&tm.cmq_lock, flags);
+			/* The TM may be idle (e.g. a zero cmq_max_depth). */
+			wake_up_interruptible(&tm.cmq_waitq);
+			return -EBUSY;
+		}
+		spin_unlock_irqrestore(&tm.cmq_lock, flags);
+		cmh_stat_inc_cmq_full();
+		return -ENOSPC;
+	}
+	INIT_LIST_HEAD(&msg->list);
+	list_add_tail(&msg->list, &tm.cmq);
+	cmq_depth++;
+	cmh_stat_record_cmq_post(cmq_depth);
+	spin_unlock_irqrestore(&tm.cmq_lock, flags);
+
+	wake_up_interruptible(&tm.cmq_waitq);
+	return 0;
+}
+
+/* Synchronous Submit (refcounted completion + timeout) */
+
+/*
+ * Heap-allocated sync context with refcounting.
+ *
+ * The completion callback may fire after the waiter has timed out and
+ * returned (e.g. during cmh_tm_cleanup on rmmod).  If the struct lived
+ * on the waiter's stack, the callback would touch freed memory --
+ * triggering a "BUG: spinlock bad magic" on the completion's spinlock.
+ *
+ * Two references are held: one by the waiter, one by the callback.
+ * Whichever runs last frees the struct.
+ */
+struct cmh_sync_ctx {
+	struct completion   done;
+	int                 error;
+	refcount_t          refs;   /* 2: waiter + callback */
+
+	/* Optional orphan cleanup -- called when the last ref drops after
+	 * the waiter abandoned an in-flight VCQ (noabort path).  Lets the
+	 * caller defer DMA-buffer cleanup until the eSW finishes writing.
+	 * Receives the completion @error so it can free a clean buffer but
+	 * park one the eSW may still be writing.
+	 */
+	void (*orphan_cb)(void *data, int error);
+	void *orphan_data;
+};
+
+static void cmh_sync_ctx_put(struct cmh_sync_ctx *ctx)
+{
+	if (refcount_dec_and_test(&ctx->refs)) {
+		if (ctx->orphan_cb)
+			ctx->orphan_cb(ctx->orphan_data, ctx->error);
+		kfree(ctx);
+	}
+}
+
+static void cmh_sync_complete(void *data, int error)
+{
+	struct cmh_sync_ctx *ctx = data;
+
+	ctx->error = error;
+	complete(&ctx->done);
+	cmh_sync_ctx_put(ctx);
+}
+
+/*
+ * Default VCQ completion timeout (milliseconds), tunable via debugfs
+ * config/vcq_timeout_ms.  Only affects the default timeout used by cmh_tm_submit_sync()
+ * and cmh_tm_submit_sync_mbx(); callers that pass an explicit timeout_hz
+ * (slow operations) are not affected.
+ */
+static unsigned int vcq_timeout_ms = 2000;
+
+/*
+ * Extended timeout for slow crypto operations such as key generation.
+ * Tunable via debugfs config/slow_op_timeout_ms.
+ */
+static unsigned int slow_op_timeout_ms = 300000;
+
+/**
+ * cmh_tm_submit_sync_tmo() - Synchronous VCQ submit with timeout
+ * @vcq_cmds: Array of pre-built VCQ command entries
+ * @vcq_count: Total number of entries in @vcq_cmds
+ * @num_vcqs: Number of VCQs packed in @vcq_cmds
+ * @target_mbx: Pinned mailbox index, or -1 for round-robin
+ * @timeout_hz: Completion timeout in jiffies
+ *
+ * Posts a VCQ command to the TM and waits for completion up to
+ * @timeout_hz.  On timeout it issues MBX_COMMAND_ABORT for an in-flight
+ * VCQ and waits for the RH to drain it, so callers normally free their
+ * DMA buffers on return.  This HW cannot always issue or observe the
+ * abort to complete (see the 5 s abort-timeout branch below).  Must be
+ * called from process context.
+ *
+ * Return: 0 on success, -EAGAIN if the command queue is full, -ETIMEDOUT
+ *         (the device never confirmed completion), or negative errno.
+ */
+int cmh_tm_submit_sync_tmo(struct vcq_cmd *vcq_cmds, u32 vcq_count,
+			   u32 num_vcqs, s32 target_mbx,
+			   unsigned long timeout_hz)
+{
+	struct cmh_sync_ctx *sync;
+	struct command_msg *msg;
+	unsigned long left;
+	int ret;
+
+	/*
+	 * This path sleeps (GFP_KERNEL allocations + wait_for_completion)
+	 * and is not safe from atomic / non-sleepable contexts.  All
+	 * current callers run in process context, so this is never
+	 * violated today.  Catch it loudly if a future caller gets this
+	 * wrong.
+	 */
+	WARN_ON_ONCE(!in_task());
+
+	sync = kzalloc_obj(*sync, GFP_KERNEL);
+	if (!sync)
+		return -ENOMEM;
+
+	msg = kzalloc_obj(*msg, GFP_KERNEL);
+	if (!msg) {
+		kfree(sync);
+		return -ENOMEM;
+	}
+
+	init_completion(&sync->done);
+	sync->error = 0;
+	refcount_set(&sync->refs, 2);  /* waiter + callback */
+
+	/*
+	 * Heap-copy the caller's VCQ array so the msg owns its data.
+	 * This decouples VCQ lifetime from the caller's stack frame,
+	 * which matters when the TM thread backs off (resolve_mbx
+	 * returns -1) and re-enqueues the msg after the caller's
+	 * wait_for_completion_timeout expires.
+	 */
+	msg->vcq_data = kmemdup(vcq_cmds, vcq_count * sizeof(*vcq_cmds),
+				GFP_KERNEL);
+	if (!msg->vcq_data) {
+		kfree(msg);
+		kfree(sync);
+		return -ENOMEM;
+	}
+
+	INIT_LIST_HEAD(&msg->list);
+	if (WARN_ON_ONCE(vcq_count < MIN_VCQ_CMDS)) {
+		ret = -EINVAL;
+		goto err_free;
+	}
+	msg->command_id = vcq_cmds[1].id;  /* first real command's ID */
+	msg->vcq_count  = vcq_count;
+	msg->num_vcqs   = num_vcqs;
+	msg->target_mbx = target_mbx;
+	msg->actual_mbx = -1;
+	msg->first_vcq_id = U32_MAX;
+	msg->complete   = cmh_sync_complete;
+	msg->completion_data = sync;
+	refcount_set(&msg->refs, 2);       /* waiter + TM subsystem */
+
+	ret = cmh_tm_post_command(msg);
+	if (ret) {
+err_free:
+		kfree(msg->vcq_data);
+		kfree(msg);
+		kfree(sync);  /* callback will never fire */
+		/*
+		 * -ENOSPC is the crypto_enqueue_request() convention for the
+		 * async crypto API; a synchronous caller is told to retry.
+		 */
+		return ret == -ENOSPC ? -EAGAIN : ret;
+	}
+
+	dev_dbg(cmh_dev(), "tm: submit_sync posted cmd 0x%08x, waiting...\n",
+		msg->command_id);
+
+	left = wait_for_completion_timeout(&sync->done, timeout_hz);
+	if (!left) {
+		dev_err(cmh_dev(),
+			"tm: submit_sync timeout (%lums) cmd=0x%08x\n",
+			timeout_hz * 1000 / HZ, msg->command_id);
+		if (cmh_tm_try_cancel_command(msg)) {
+			/*
+			 * Msg was still queued -- TM never saw it.
+			 * Drop the callback ref (no txn will fire it)
+			 * and free msg directly (sole owner).
+			 */
+			cmh_sync_ctx_put(sync);  /* no txn -> drop cb ref */
+			cmh_sync_ctx_put(sync);  /* drop waiter ref */
+			command_msg_put(msg);    /* matches refcount_set(2) */
+			command_msg_put(msg);
+		} else {
+			/*
+			 * TM has dequeued msg and the VCQ is in-flight.
+			 * Issue MBX_COMMAND_ABORT to force-stop the VCQ;
+			 * the RH will fire MBX_ERROR_IRQ, complete the
+			 * transaction with -EIO, and issue RESTART.
+			 *
+			 * cmh_rh_abort_mbx() serialises the write under
+			 * rh_process_lock, preventing clobber of a
+			 * concurrent RESTART/FLUSH from the watchdog.
+			 */
+			s32 abrt_mbx = READ_ONCE(msg->actual_mbx);
+
+			/*
+			 * Only ABORT if our VCQ is the one currently at the
+			 * mailbox HEAD.  ABORT stops whatever executes at
+			 * HEAD, so aborting while a different (older,
+			 * possibly long-running) transaction is at HEAD would
+			 * kill an unrelated request.  If ours is queued behind
+			 * it, the HW has not started ours yet -- leave it to
+			 * the completion wait / watchdog rather than abort
+			 * someone else.
+			 */
+			if (abrt_mbx >= 0 &&
+			    (u32)abrt_mbx < tm.cfg->mbx_count &&
+			    cmh_rh_abort_mbx((u32)abrt_mbx,
+					     READ_ONCE(msg->first_vcq_id)))
+				dev_warn(cmh_dev(),
+					 "tm: aborted mbx[%d] cmd=0x%08x\n",
+					 abrt_mbx, msg->command_id);
+
+			/*
+			 * Wait for the RH completion (ABORT triggers
+			 * MBX_ERROR_IRQ within microseconds).  Fixed
+			 * 5 s ceiling -- not configurable because if
+			 * ABORT doesn't complete in this window the
+			 * HW is wedged and more waiting won't help.
+			 */
+			left = wait_for_completion_timeout(&sync->done,
+							   5 * HZ);
+			if (!left) {
+				/*
+				 * ABORT did not complete within 5 s.  Unlike
+				 * cmh_tm_submit_sync_noabort, this path sets no
+				 * orphan_cb, so the caller frees its DMA buffers
+				 * on the -ETIMEDOUT below.  This HW exposes no
+				 * DMA-stop primitive, so where an ABORT cannot be
+				 * issued or observed to complete the driver has
+				 * no positive confirmation the engine has
+				 * finished with those buffers.
+				 */
+				dev_err(cmh_dev(),
+					"tm: abort timeout (5s) cmd=0x%08x - HW wedged\n",
+					msg->command_id);
+			}
+			cmh_sync_ctx_put(sync);  /* drop waiter ref */
+			command_msg_put(msg);    /* drop waiter ref on msg */
+		}
+		return -ETIMEDOUT;
+	}
+
+	ret = sync->error;
+	cmh_sync_ctx_put(sync);  /* drop waiter ref */
+	command_msg_put(msg);    /* drop waiter ref on msg */
+	return ret;
+}
+
+/**
+ * cmh_tm_submit_sync_mbx() - Synchronous VCQ submit on a target MBX
+ * @vcq_cmds: Array of pre-built VCQ command entries
+ * @vcq_count: Total number of entries in @vcq_cmds
+ * @num_vcqs: Number of VCQs packed in @vcq_cmds
+ * @target_mbx: Pinned mailbox index, or -1 for round-robin
+ *
+ * Convenience wrapper around cmh_tm_submit_sync_tmo() using the
+ * default vcq_timeout_ms (debugfs config/vcq_timeout_ms).
+ *
+ * Return: 0 on success, negative errno on failure.
+ */
+int cmh_tm_submit_sync_mbx(struct vcq_cmd *vcq_cmds, u32 vcq_count,
+			   u32 num_vcqs, s32 target_mbx)
+{
+	return cmh_tm_submit_sync_tmo(vcq_cmds, vcq_count, num_vcqs,
+				     target_mbx,
+				     msecs_to_jiffies(vcq_timeout_ms));
+}
+
+/**
+ * cmh_tm_async_timeout_jiffies() - Default async per-request timeout
+ *
+ * Return: Timeout in jiffies from async_timeout_ms (debugfs
+ *         config/async_timeout_ms), or 0 if async timeouts are disabled.
+ */
+unsigned long cmh_tm_async_timeout_jiffies(void)
+{
+	return async_timeout_ms ? msecs_to_jiffies(async_timeout_ms) : 0;
+}
+
+/**
+ * cmh_tm_slow_op_timeout_jiffies() - Timeout for slow crypto ops
+ *
+ * Returns the extended timeout used for long-running operations such as
+ * key generation.
+ *
+ * Return: Timeout in jiffies from slow_op_timeout_ms (debugfs
+ *         config/slow_op_timeout_ms).
+ */
+unsigned long cmh_tm_slow_op_timeout_jiffies(void)
+{
+	return msecs_to_jiffies(slow_op_timeout_ms);
+}
+
+/**
+ * cmh_tm_submit_async() - Asynchronous VCQ submission
+ * @vcq_cmds: Array of pre-built VCQ command entries
+ * @vcq_count: Total number of entries in @vcq_cmds
+ * @num_vcqs: Number of VCQs packed in @vcq_cmds
+ * @target_mbx: Pinned mailbox index, or -1 for round-robin
+ * @callback: Completion callback (see context note below)
+ * @callback_data: Opaque data passed to @callback
+ * @rdma: Request DMA set, or NULL
+ * @backlog_ok: Allow backlogging if CMQ is full
+ * @timeout_jiffies: Per-request timeout (0 = no timeout)
+ *
+ * Builds a command_msg, heap-copies the VCQ data, and posts it to the
+ * CMQ via cmh_tm_post_command().
+ *
+ * Callback context guarantee:
+ *   The @callback may be invoked from one of:
+ *   - RH threaded IRQ handler (process context, BH disabled)
+ *   - RH watchdog timer (softirq / timer context)
+ *   - TM kthread if submit_vcq() fails post-dequeue
+ *   - cmh_tm_cleanup()/cmh_tm_quiesce() during drain (process context)
+ *   It is NEVER invoked from hardirq context.
+ *
+ *   Because the watchdog path runs from timer softirq, callbacks
+ *   MUST be safe in atomic/softirq context: no mutex, no GFP_KERNEL,
+ *   no sleeping locks.  crypto_request_complete() is safe (documented
+ *   callable from any context).  kfree_sensitive() and
+ *   scatterwalk_map_and_copy() are also safe (non-sleeping).
+ *   Callers must not assume thread affinity (callback may run on any CPU).
+ *
+ * Unlike the _sync variants, this function:
+ *   - Does NOT allocate a cmh_sync_ctx or wait for completion
+ *   - Uses GFP_ATOMIC for internal allocations because the crypto API
+ *     may call ->encrypt/->decrypt/->hash_final from softirq context
+ *     (e.g. network stack via IPsec/TLS); GFP_KERNEL would deadlock.
+ *
+ * The command_msg is single-owner (refcount 1) -- the TM subsystem
+ * owns it after post and frees it after dispatching to the HW.
+ *
+ * DMA buffer ownership: the caller transfers ownership to the callback
+ * on return of 0 or -EBUSY.  On any other return, the caller must
+ * clean up DMA buffers itself -- the callback will never fire.  @rdma
+ * must record every buffer the device can reach and stay valid until the
+ * final callback: if the request completes while the device may still
+ * access them (a FLUSH that was never acknowledged), the TM quarantines
+ * the set before the callback runs, emptying it.
+ *
+ * Return: 0 on successful post, -EBUSY if backlogged, -ENOMEM,
+ *         -EINVAL, -ENOSPC, or -ENODEV on failure.
+ */
+int cmh_tm_submit_async(struct vcq_cmd *vcq_cmds, u32 vcq_count,
+			u32 num_vcqs, s32 target_mbx,
+			cmh_completion_fn callback, void *callback_data,
+			struct cmh_req_dma *rdma,
+			bool backlog_ok, unsigned long timeout_jiffies)
+{
+	struct command_msg *msg;
+	int ret;
+
+	msg = kzalloc_obj(*msg, GFP_ATOMIC);
+	if (!msg)
+		return -ENOMEM;
+
+	msg->vcq_data = kmemdup(vcq_cmds,
+				array_size(vcq_count, sizeof(*vcq_cmds)),
+				GFP_ATOMIC);
+	if (!msg->vcq_data) {
+		kfree(msg);
+		return -ENOMEM;
+	}
+
+	INIT_LIST_HEAD(&msg->list);
+	if (WARN_ON_ONCE(vcq_count < MIN_VCQ_CMDS)) {
+		kfree(msg->vcq_data);
+		kfree(msg);
+		return -EINVAL;
+	}
+	msg->command_id      = vcq_cmds[1].id;
+	msg->vcq_count       = vcq_count;
+	msg->num_vcqs        = num_vcqs;
+	msg->target_mbx      = target_mbx;
+	msg->actual_mbx      = -1;
+	msg->complete        = callback;
+	msg->completion_data = callback_data;
+	msg->rdma            = rdma;
+	msg->backlog_ok      = backlog_ok;
+	msg->timeout_jiffies = timeout_jiffies;
+	refcount_set(&msg->refs, 1);  /* sole owner: TM subsystem */
+
+	ret = cmh_tm_post_command(msg);
+	if (ret && ret != -EBUSY) {
+		kfree(msg->vcq_data);
+		kfree(msg);
+	}
+	return ret;
+}
+
+/**
+ * cmh_tm_submit_sync_noabort() - Sync submit without MBX abort on timeout
+ * @vcq_cmds: Array of pre-built VCQ command entries
+ * @vcq_count: Total number of entries in @vcq_cmds
+ * @num_vcqs: Number of VCQs packed in @vcq_cmds
+ * @timeout_hz: Completion timeout in jiffies
+ * @orphan_cb: Optional cleanup callback for abandoned DMA buffers
+ * @orphan_data: Opaque data passed to @orphan_cb
+ *
+ * On timeout, if the command was still queued it is cancelled and
+ * -EAGAIN is returned (caller may free all resources).  If the VCQ is
+ * already in-flight, the waiter drops its refs and returns -EINPROGRESS
+ * -- the RH callback will fire when the eSW finishes the VCQ and free
+ * the sync_ctx / msg via the refcount mechanism.
+ *
+ * @orphan_cb is invoked when the last ref on the sync_ctx drops after
+ * the waiter abandoned an in-flight VCQ, allowing the caller to defer
+ * DMA-buffer cleanup until the eSW finishes writing.
+ *
+ * This prevents a short-timeout command (e.g. DRBG GENERATE from the
+ * hwrng kthread) from aborting the entire MBX and killing unrelated
+ * long-running operations on the same mailbox.
+ *
+ * Return: 0 on success, -EAGAIN if the command queue is full or the
+ *         command was cancelled from the queue,
+ *         -EINPROGRESS if left in-flight, or negative errno.
+ */
+int cmh_tm_submit_sync_noabort(struct vcq_cmd *vcq_cmds, u32 vcq_count,
+			       u32 num_vcqs, unsigned long timeout_hz,
+			       void (*orphan_cb)(void *, int), void *orphan_data)
+{
+	struct cmh_sync_ctx *sync;
+	struct command_msg *msg;
+	unsigned long left;
+	int ret;
+
+	WARN_ON_ONCE(!in_task());
+
+	sync = kzalloc_obj(*sync, GFP_KERNEL);
+	if (!sync)
+		return -ENOMEM;
+
+	msg = kzalloc_obj(*msg, GFP_KERNEL);
+	if (!msg) {
+		kfree(sync);
+		return -ENOMEM;
+	}
+
+	init_completion(&sync->done);
+	sync->error = 0;
+	refcount_set(&sync->refs, 2);
+
+	INIT_LIST_HEAD(&msg->list);
+	if (WARN_ON_ONCE(vcq_count < MIN_VCQ_CMDS)) {
+		kfree(msg);
+		kfree(sync);
+		return -EINVAL;
+	}
+	msg->command_id = vcq_cmds[1].id;
+	msg->vcq_data = kmemdup(vcq_cmds, vcq_count * sizeof(*vcq_cmds),
+				GFP_KERNEL);
+	if (!msg->vcq_data) {
+		kfree(msg);
+		kfree(sync);
+		return -ENOMEM;
+	}
+	msg->vcq_count  = vcq_count;
+	msg->num_vcqs   = num_vcqs;
+	msg->target_mbx = -1;
+	msg->actual_mbx = -1;
+	msg->complete   = cmh_sync_complete;
+	msg->completion_data = sync;
+	refcount_set(&msg->refs, 2);
+
+	ret = cmh_tm_post_command(msg);
+	if (ret) {
+		kfree(msg->vcq_data);
+		kfree(msg);
+		kfree(sync);
+		/* Synchronous callers retry a full queue (see sync_tmo). */
+		return ret == -ENOSPC ? -EAGAIN : ret;
+	}
+
+	left = wait_for_completion_timeout(&sync->done, timeout_hz);
+	if (!left) {
+		if (cmh_tm_try_cancel_command(msg)) {
+			/* Still queued -- TM never saw it, clean up fully */
+			cmh_sync_ctx_put(sync);  /* drop cb ref */
+			cmh_sync_ctx_put(sync);  /* drop waiter ref */
+			command_msg_put(msg);    /* matches refcount_set(2) */
+			command_msg_put(msg);
+			return -EAGAIN;
+		}
+
+		/*
+		 * In-flight: skip ABORT.  Transfer orphan cleanup
+		 * ownership to sync_ctx -- the RH callback will
+		 * eventually complete this VCQ, and when the last
+		 * ref drops, orphan_cb frees any DMA buffers the
+		 * eSW was still writing to.
+		 */
+		dev_dbg_ratelimited(cmh_dev(),
+				    "tm: noabort timeout (%lums) cmd=0x%08x, leaving in-flight\n",
+				    timeout_hz * 1000 / HZ,
+				    msg->command_id);
+		sync->orphan_cb   = orphan_cb;
+		sync->orphan_data = orphan_data;
+		cmh_sync_ctx_put(sync);
+		command_msg_put(msg);
+		return -EINPROGRESS;
+	}
+
+	ret = sync->error;
+	cmh_sync_ctx_put(sync);
+	command_msg_put(msg);
+	return ret;
+}
+
+/**
+ * cmh_tm_submit_sync() - Synchronous VCQ submit with default timeout
+ * @vcq_cmds: Array of pre-built VCQ command entries
+ * @vcq_count: Total number of entries in @vcq_cmds
+ * @num_vcqs: Number of VCQs packed in @vcq_cmds
+ *
+ * Convenience wrapper: submits via round-robin MBX selection with the
+ * default vcq_timeout_ms.
+ *
+ * Return: 0 on success, negative errno on failure.
+ */
+int cmh_tm_submit_sync(struct vcq_cmd *vcq_cmds, u32 vcq_count,
+		       u32 num_vcqs)
+{
+	return cmh_tm_submit_sync_mbx(vcq_cmds, vcq_count, num_vcqs, -1);
+}
+
+/**
+ * cmh_vcq_pack_and_submit_async() - Pack payload and submit async
+ * @payload: Array of VCQ command entries (without headers)
+ * @count: Number of entries in @payload
+ * @packed: Caller-provided output buffer for packed VCQ data
+ * @max_packed: Size of @packed buffer in vcq_cmd entries
+ * @target_mbx: Pinned mailbox index, or -1 for round-robin
+ * @callback: Completion callback
+ * @callback_data: Opaque data passed to @callback
+ * @rdma: Request DMA set, or NULL (see cmh_tm_submit_async())
+ * @backlog_ok: Allow backlogging if CMQ is full
+ * @timeout_jiffies: Per-request timeout (0 = no timeout)
+ *
+ * Splits @payload into VCQ-sized chunks, prepends headers, and submits
+ * via cmh_tm_submit_async().
+ *
+ * Return: 0 on success, -EBUSY if backlogged, -EMSGSIZE if @packed
+ *         is too small, or negative errno from submit.
+ */
+int cmh_vcq_pack_and_submit_async(const struct vcq_cmd *payload, u32 count,
+				  struct vcq_cmd *packed, u32 max_packed,
+				  s32 target_mbx,
+				  cmh_completion_fn callback,
+				  void *callback_data,
+				  struct cmh_req_dma *rdma,
+				  bool backlog_ok,
+				  unsigned long timeout_jiffies)
+{
+	u32 max_per_vcq = cmh_tm_max_cmds_per_vcq();
+	u32 max_payload_per = max_per_vcq - 1;
+	u32 num_vcqs = 0, total = 0, i = 0;
+
+	while (i < count) {
+		u32 chunk = min_t(u32, count - i, max_payload_per);
+		u32 vcq_cmds = chunk + 1;
+
+		if (total + vcq_cmds > max_packed)
+			return -EMSGSIZE;
+
+		vcq_set_header(&packed[total], vcq_cmds);
+		memcpy(&packed[total + 1], &payload[i],
+		       chunk * sizeof(struct vcq_cmd));
+
+		total += vcq_cmds;
+		i += chunk;
+		num_vcqs++;
+	}
+
+	return cmh_tm_submit_async(packed, total, num_vcqs, target_mbx,
+				   callback, callback_data, rdma, backlog_ok,
+				   timeout_jiffies);
+}
+
+/**
+ * cmh_tm_peek_transaction() - Peek at the head of a mailbox TXQ
+ * @mbx_idx: Mailbox index to inspect
+ *
+ * Returns a pointer to the oldest in-flight transaction without
+ * removing it from the queue.  The caller must not free the returned
+ * object.
+ *
+ * Return: Pointer to the head transaction, or NULL if empty.
+ */
+struct transaction_obj *cmh_tm_peek_transaction(u32 mbx_idx)
+{
+	struct cmh_mbx_txq *txq;
+	struct transaction_obj *txn = NULL;
+	unsigned long flags;
+
+	if (!tm.txqs || mbx_idx >= tm.cfg->mbx_count)
+		return NULL;
+
+	txq = &tm.txqs[mbx_idx];
+
+	spin_lock_irqsave(&txq->lock, flags);
+	if (!list_empty(&txq->head))
+		txn = list_first_entry(&txq->head, struct transaction_obj,
+				       list);
+	spin_unlock_irqrestore(&txq->lock, flags);
+
+	return txn;
+}
+
+/**
+ * cmh_tm_pop_transaction() - Remove and return the head of a MBX TXQ
+ * @mbx_idx: Mailbox index to pop from
+ *
+ * Dequeues the oldest in-flight transaction from the per-mailbox
+ * transaction queue.  The caller takes ownership and must eventually
+ * call cmh_txn_finish() or txn_put().
+ *
+ * Return: Pointer to the dequeued transaction, or NULL if empty.
+ */
+struct transaction_obj *cmh_tm_pop_transaction(u32 mbx_idx)
+{
+	struct cmh_mbx_txq *txq;
+	struct transaction_obj *txn;
+	unsigned long flags;
+
+	if (!tm.txqs || mbx_idx >= tm.cfg->mbx_count)
+		return NULL;
+
+	txq = &tm.txqs[mbx_idx];
+
+	spin_lock_irqsave(&txq->lock, flags);
+	if (list_empty(&txq->head)) {
+		spin_unlock_irqrestore(&txq->lock, flags);
+		return NULL;
+	}
+	txn = list_first_entry(&txq->head, struct transaction_obj, list);
+	list_del_init(&txn->list);
+	txq->depth--;
+	spin_unlock_irqrestore(&txq->lock, flags);
+
+	return txn;
+}
+
+/* -- debugfs timeout accessors ----------------------------------------- */
+
+#ifdef CONFIG_CRYPTO_DEV_CMH_DEBUG
+/**
+ * cmh_tm_timeout_async_ptr() - Return pointer to async_timeout_ms for debugfs
+ *
+ * Return: pointer to the static async_timeout_ms variable.
+ */
+unsigned int *cmh_tm_timeout_async_ptr(void)    { return &async_timeout_ms; }
+
+/**
+ * cmh_tm_timeout_vcq_ptr() - Return pointer to vcq_timeout_ms for debugfs
+ *
+ * Return: pointer to the static vcq_timeout_ms variable.
+ */
+unsigned int *cmh_tm_timeout_vcq_ptr(void)      { return &vcq_timeout_ms; }
+
+/**
+ * cmh_tm_timeout_slow_op_ptr() - Return pointer to slow_op_timeout_ms for debugfs
+ *
+ * Return: pointer to the static slow_op_timeout_ms variable.
+ */
+unsigned int *cmh_tm_timeout_slow_op_ptr(void)  { return &slow_op_timeout_ms; }
+
+/**
+ * cmh_tm_timeout_drain_ptr() - Return pointer to drain_timeout_ms for debugfs
+ *
+ * Return: pointer to the static drain_timeout_ms variable.
+ */
+unsigned int *cmh_tm_timeout_drain_ptr(void)    { return &drain_timeout_ms; }
+
+/**
+ * cmh_tm_cmq_max_depth_ptr() - Return pointer to cmq_max_depth for debugfs
+ *
+ * Return: pointer to the static cmq_max_depth variable.
+ */
+unsigned int *cmh_tm_cmq_max_depth_ptr(void)    { return &cmq_max_depth; }
+
+#endif
diff --git a/drivers/crypto/cmh/include/cmh.h b/drivers/crypto/cmh/include/cmh.h
new file mode 100644
index 000000000000..97a7bc764d9b
--- /dev/null
+++ b/drivers/crypto/cmh/include/cmh.h
@@ -0,0 +1,24 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- Top-level Device Structure
+ */
+
+#ifndef CMH_H
+#define CMH_H
+
+#include <linux/device.h>
+
+#include "cmh_config.h"
+
+/**
+ * struct cmh_device - Top-level driver state for a CMH hardware instance
+ * @config: Hardware configuration (core mappings, MBX layout, feature flags)
+ * @dev:    Platform or parent device used for DMA and logging
+ */
+struct cmh_device {
+	struct cmh_config       config;
+	struct device          *dev;
+};
+
+#endif /* CMH_H */
diff --git a/drivers/crypto/cmh/include/cmh_config.h b/drivers/crypto/cmh/include/cmh_config.h
new file mode 100644
index 000000000000..b0fc80b46143
--- /dev/null
+++ b/drivers/crypto/cmh/include/cmh_config.h
@@ -0,0 +1,110 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- Configuration Structures and Defaults
+ */
+
+#ifndef CMH_CONFIG_H
+#define CMH_CONFIG_H
+
+#include <linux/types.h>
+#include <linux/dma-mapping.h>
+
+#include "cmh_registers.h"
+#include "cmh_vcq.h"
+
+/* Limits */
+
+/*
+ * Max mailboxes the driver manages simultaneously.  The hardware address
+ * space supports CMH_MAX_MBX_INSTANCES (64) instance indices, but this
+ * compile-time constant caps how many the driver allocates DMA queues,
+ * IRQ slots, and per-transform cache entries for.  To manage more
+ * mailboxes (up to the HW max), increase this value and rebuild the LKM
+ * -- it cannot be changed via module parameters at runtime.
+ */
+#define CMH_MAX_CONFIGURED_MBX    16
+#define CMH_MAX_CORE_INSTANCES    8
+
+/*
+ * MBX setup parameter ranges.  The hardware accepts 128..1024-byte
+ * strides; the driver needs 512 so that each command sequence it builds
+ * fits one slot and a raw-key SYS_WRITE stays in the VCQ that uses it.
+ */
+#define CMH_MBX_SLOTS_LOG2_MIN        1
+#define CMH_MBX_SLOTS_LOG2_MAX        15
+#define CMH_MBX_STRIDE_LOG2_MIN       9
+#define CMH_MBX_STRIDE_LOG2_MAX       10
+
+/* Default Configuration Values */
+
+#define CMH_DEFAULT_MBX_COUNT         2
+#define CMH_DEFAULT_SLOTS_LOG2        6   /* 2^6 = 64 slots */
+#define CMH_DEFAULT_STRIDE_LOG2       9   /* 2^9 = 512 bytes per slot */
+#define CMH_DEFAULT_IRQ               (-1) /* polling mode */
+#define CMH_FW_READY_TIMEOUT_MS  5000 /* built-in; raise here for a slower eSW boot */
+
+/* Per-Core-Type Instance Configuration */
+
+struct cmh_core_type_cfg {
+	u32	num_instances;
+	u32	core_ids[CMH_MAX_CORE_INSTANCES];
+	s32	mbx[CMH_MAX_CORE_INSTANCES]; /* -1 = auto-assign */
+};
+
+/* Per-Mailbox Configuration */
+
+struct cmh_mbx_config {
+	u32             instance;       /* 0-based MBX instance index (0..63) */
+	u32             slots_log2;     /* log2(slot count), range 1..15 */
+	u32             stride_log2;    /* log2(bytes per slot), range 7..10 */
+	int             irq;            /* per-mailbox virq, -1 if none (poll) */
+	u32             cores[CMH_NUM_CORE_TYPES]; /* rambus,cores affinity IDs */
+	u32             num_cores;      /* number of entries in cores[] */
+	u32             lock_val;       /* MBX lock token (non-zero while held) */
+	dma_addr_t      dma_handle;     /* DMA bus address from dma_alloc_coherent */
+	void           *virt_addr;      /* kernel virtual address of MBXQ buffer */
+	size_t          queue_size;     /* total queue buffer size in bytes */
+	void __iomem   *reg_base;       /* ioremap'd register base for this instance */
+	bool            fenced;         /* last settle FLUSH acknowledged */
+};
+
+/* Global Device Configuration */
+
+struct cmh_config {
+	phys_addr_t                 sic_base;
+	size_t                      sic_size;
+	void __iomem               *sic_mapped;    /* ioremap'd SIC region */
+	u32                         mbx_count;
+	struct cmh_mbx_config       mailboxes[CMH_MAX_CONFIGURED_MBX];
+	unsigned int                fw_ready_timeout_ms; /* FW mission-mode timeout */
+	struct cmh_core_type_cfg    core_types[CMH_NUM_CORE_TYPES];
+};
+
+/* Module Parameter Interface */
+
+struct platform_device;
+
+/**
+ * cmh_config_init() - Populate config from module params and device-tree
+ * @cfg: Configuration structure to fill
+ * @pdev: Platform device (for DT properties and IRQ lookup)
+ *
+ * Return: 0 on success, negative errno on failure.
+ */
+int cmh_config_init(struct cmh_config *cfg, struct platform_device *pdev);
+
+/**
+ * cmh_config_discover_cores() - Enumerate crypto cores from the hardware
+ * @cfg: Configuration structure (SIC must already be mapped)
+ *
+ * Reads the SIC CORE_ENABLE register to determine which crypto core types
+ * the silicon build provides, populates cfg->core_types[], applies the
+ * per-mailbox rambus,cores affinity, and validates the result.  Must be
+ * called after cfg->sic_mapped is valid (i.e. after the SIC ioremap).
+ *
+ * Return: 0 on success, negative errno on failure.
+ */
+int cmh_config_discover_cores(struct cmh_config *cfg);
+
+#endif /* CMH_CONFIG_H */
diff --git a/drivers/crypto/cmh/include/cmh_debugfs.h b/drivers/crypto/cmh/include/cmh_debugfs.h
new file mode 100644
index 000000000000..3456deafa9fa
--- /dev/null
+++ b/drivers/crypto/cmh/include/cmh_debugfs.h
@@ -0,0 +1,94 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- debugfs Per-MBX and TM Counters
+ *
+ * Exposes diagnostic counters under /sys/kernel/debug/cmh/:
+ *
+ *   mbxN/vcqs_submitted      Total VCQs sent to MBX N
+ *   mbxN/vcqs_completed      Total completions received
+ *   mbxN/vcqs_errors         Total error completions
+ *   mbxN/queue_full_count    Times select_mailbox() skipped this MBX
+ *   mbxN/max_queue_depth     High-water mark of in-flight transactions
+ *
+ *   tm/cmq_posts             Total cmh_tm_post_command() calls
+ *   tm/cmq_depth_max         High-water mark of CMQ length
+ *   tm/cmq_full_count        Times CMQ was full (-ENOSPC)
+ *   tm/backoff_count         Times TM backed off (all MBX queues full)
+ *   tm/async_timeout_count   Async requests that timed out
+ *
+ * Counters are atomic64_t -- safe to read from any context.
+ * When CONFIG_CRYPTO_DEV_CMH_DEBUG is off, all functions become no-ops and the
+ * compiler eliminates the counter code entirely.
+ */
+
+#ifndef CMH_DEBUGFS_H
+#define CMH_DEBUGFS_H
+
+#include <linux/types.h>
+#include <linux/atomic.h>
+
+/* Per-Mailbox Statistics */
+
+struct cmh_mbx_stats {
+	atomic64_t vcqs_submitted;
+	atomic64_t vcqs_completed;
+	atomic64_t vcqs_errors;
+	atomic64_t queue_full_count;
+	atomic64_t max_queue_depth;
+};
+
+/* TM-Level Statistics */
+
+struct cmh_tm_stats {
+	atomic64_t cmq_posts;
+	atomic64_t cmq_depth_max;
+	atomic64_t cmq_full_count;
+	atomic64_t backoff_count;
+	atomic64_t async_timeout_count;
+};
+
+/**
+ * cmh_stat_update_max() - Atomically update a high-water mark counter
+ * @counter: atomic64_t counter to update
+ * @val: New candidate value
+ *
+ * Updates @counter to @val if @val exceeds the current maximum.
+ * Lock-free via atomic cmpxchg loop.
+ */
+static inline void cmh_stat_update_max(atomic64_t *counter, s64 val)
+{
+	s64 cur;
+
+	do {
+		cur = atomic64_read(counter);
+		if (val <= cur)
+			return;
+	} while (atomic64_cmpxchg(counter, cur, val) != cur);
+}
+
+/* Interface (stub when CONFIG_CRYPTO_DEV_CMH_DEBUG is off) */
+
+struct cmh_config;
+
+#ifdef CONFIG_CRYPTO_DEV_CMH_DEBUG
+
+void cmh_debugfs_init(struct cmh_config *cfg);
+void cmh_debugfs_cleanup(void);
+
+/* Publish a subsystem's u32 tunable in the shared config/ dir. */
+void cmh_debugfs_config_u32(const char *name, u32 *val);
+
+struct cmh_mbx_stats *cmh_debugfs_mbx_stats(u32 mbx_idx);
+struct cmh_tm_stats  *cmh_debugfs_tm_stats(void);
+
+#else /* !CONFIG_CRYPTO_DEV_CMH_DEBUG */
+
+static inline void cmh_debugfs_init(struct cmh_config *c) { }
+static inline void cmh_debugfs_cleanup(void) {}
+static inline void cmh_debugfs_config_u32(const char *name, u32 *val) { }
+static inline struct cmh_mbx_stats *cmh_debugfs_mbx_stats(u32 i) { return NULL; }
+static inline struct cmh_tm_stats  *cmh_debugfs_tm_stats(void)   { return NULL; }
+
+#endif /* CONFIG_CRYPTO_DEV_CMH_DEBUG */
+#endif /* CMH_DEBUGFS_H */
diff --git a/drivers/crypto/cmh/include/cmh_dma.h b/drivers/crypto/cmh/include/cmh_dma.h
new file mode 100644
index 000000000000..034b2b6292cb
--- /dev/null
+++ b/drivers/crypto/cmh/include/cmh_dma.h
@@ -0,0 +1,195 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- DMA Interface
+ *
+ * Platform-independent DMA operations for the CMH crypto accelerator.
+ * All functions are implemented in cmh_dma.c (standard kernel DMA API).
+ *
+ * Alternate backends may be linked in place of cmh_dma.c for
+ * non-standard platforms.  Such backends must implement the same
+ * symbol set and may use different allocation and mapping semantics
+ * (e.g. pool-based alloc/free instead of address translation).
+ */
+
+#ifndef CMH_DMA_H
+#define CMH_DMA_H
+
+#include <linux/dma-mapping.h>
+#include <linux/types.h>
+
+#include "cmh_vcq.h"
+
+struct platform_device;
+
+/**
+ * cmh_dma_init() - Initialize the DMA backend
+ * @pdev: Platform device (provides struct device for DMA ops)
+ *
+ * Called early in .probe().  The standard backend stores the device
+ * pointer; alternate backends may set up additional resources.
+ *
+ * Return: 0 on success, negative errno on failure.
+ */
+int cmh_dma_init(struct platform_device *pdev);
+
+/**
+ * cmh_dma_cleanup() - Tear down the DMA backend
+ *
+ * Called in .remove() and error paths.  Releases any resources
+ * allocated by cmh_dma_init().
+ */
+void cmh_dma_cleanup(void);
+
+/**
+ * cmh_dev() - Global device accessor
+ *
+ * Returns the struct device * associated with the platform_driver instance.
+ * Valid only between cmh_dma_init() and cmh_dma_cleanup().
+ *
+ * Return: Platform device pointer, or NULL outside lifecycle.
+ */
+struct device *cmh_dev(void);
+
+/* Streaming DMA map / unmap (short-lived per-request buffers) */
+
+dma_addr_t cmh_dma_map_single(void *buf, size_t size,
+			      enum dma_data_direction dir);
+void cmh_dma_unmap_single(dma_addr_t addr, size_t size,
+			  enum dma_data_direction dir);
+
+/*
+ * Sync a DMA_FROM_DEVICE buffer so the CPU sees device-written data.
+ *
+ * Required before reading *buf when SWIOTLB bounce buffering is active
+ * (e.g. arm64 without IOMMU): the device writes to the bounce buffer,
+ * not the original allocation, so the CPU must sync before access.
+ * On architectures without bounce buffers (e.g. rv64) this is a no-op.
+ *
+ * Call between cmh_tm_submit_sync() and the first CPU read of the buffer,
+ * while the mapping is still live (before cmh_dma_unmap_single).
+ */
+void cmh_dma_sync_for_cpu(dma_addr_t addr, size_t size,
+			  enum dma_data_direction dir);
+
+/*
+ * Sync a DMA_TO_DEVICE buffer so the device sees CPU-written data.
+ *
+ * Required after CPU writes to a mapped streaming buffer (e.g. SG
+ * descriptor arrays that need items_dma for .lli pointer calculation
+ * before content is written).  Must be called before the device reads.
+ */
+void cmh_dma_sync_for_device(dma_addr_t addr, size_t size,
+			     enum dma_data_direction dir);
+
+int cmh_dma_map_error(dma_addr_t addr);
+
+/* Coherent DMA alloc / free (long-lived MBX queue buffers) */
+
+void *cmh_dma_alloc(size_t size, dma_addr_t *handle, gfp_t gfp);
+void cmh_dma_free(size_t size, void *virt, dma_addr_t handle);
+
+/**
+ * cmh_dma_write() - Copy data into a DMA-allocated buffer
+ * @dst: Destination pointer (from cmh_dma_alloc)
+ * @src: Source kernel buffer
+ * @len: Number of bytes to copy
+ *
+ * Copies @len bytes from @src to @dst.  @dst must have been obtained
+ * from cmh_dma_alloc().  Abstracted to allow platforms with non-standard
+ * DMA buffer access semantics.
+ */
+void cmh_dma_write(void *dst, const void *src, size_t len);
+
+/**
+ * cmh_dma_fence() - Fence preceding writes to DMA-allocated memory
+ * @ptr: Any pointer into the region that was written
+ *
+ * Ensures all preceding CPU writes to DMA memory are committed to the
+ * target memory controller before subsequent MMIO register writes.
+ *
+ * Required on FPGA platforms where DMA memory and device control
+ * registers reside on different AXI slaves -- a CPU-side wmb() only
+ * orders store dispatch, not arrival at the target.  A read from the
+ * DMA memory slave forces the memory controller to serialize behind
+ * all preceding writes from this CPU before responding, guaranteeing
+ * the data is committed before the doorbell register write is issued.
+ *
+ * On standard DMA API platforms (cache-coherent), this is a no-op.
+ */
+void cmh_dma_fence(void *ptr);
+
+/**
+ * cmh_dma_zero() - Zero a DMA-allocated buffer
+ * @dst: Destination pointer (from cmh_dma_alloc)
+ * @len: Number of bytes to zero
+ */
+void cmh_dma_zero(void *dst, size_t len);
+
+/*
+ * CMH eSW scatter-gather chain -- built with proper DMA mappings.
+ *
+ * The CMH eSW DMAC walks a linked list of dma_scattergather_item
+ * descriptors.  Each .src is the DMA address of an input buffer;
+ * each .lli is the DMA address of the next descriptor (0 = end).
+ *
+ * The descriptor array uses streaming DMA (kmalloc + dma_map_single)
+ * so that cmh_dma_free_sg() is safe from any context -- including
+ * BH-disabled completion callbacks where dma_free_coherent's
+ * vunmap() path would crash on non-coherent architectures.
+ */
+
+/* Input descriptor for cmh_dma_build_sg() -- one per data buffer */
+struct cmh_dma_buf {
+	void *data;
+	u32   len;
+};
+
+/* Opaque handle returned by cmh_dma_build_sg(); pass to cmh_dma_free_sg() */
+struct cmh_sg_map {
+	struct dma_scattergather_item *items;	/* CPU virtual address */
+	dma_addr_t  items_dma;			/* DMA address (pass to GATHER cmd) */
+	size_t      items_size;			/* allocation size */
+	u32         count;
+	struct {
+		dma_addr_t dma;
+		u32        len;
+	} bufs[];				/* per-entry source DMA handles */
+};
+
+/**
+ * cmh_dma_build_sg() - Build a DMA-mapped CMH eSW SG chain
+ * @bufs: Array of kernel buffer descriptors (data pointer + length)
+ * @count: Number of entries in @bufs (must be > 0; returns NULL for 0)
+ * @gfp: Allocation flags (GFP_KERNEL or GFP_ATOMIC)
+ *
+ * Allocates a dma_scattergather_item chain using streaming DMA
+ * (kmalloc + dma_map_single), DMA-maps each source buffer, and
+ * links the descriptors.
+ * The returned cmh_sg_map->items_dma is the address to pass to
+ * vcq_add_hc_gather() (or any core's scatter-gather command).
+ *
+ * Caller contract:
+ *   - Each bufs[i].data must point to DMA-mappable memory (kmalloc,
+ *     page-allocated, or vmalloc with DMA support).  Stack buffers
+ *     are NOT safe.
+ *   - Each bufs[i].len must be > 0.
+ *   - The returned cmh_sg_map must remain alive (not freed) until
+ *     the hardware completes the scatter-gather operation.  Only then
+ *     may cmh_dma_free_sg() be called.
+ *   - There is no hardware-imposed limit on @count, but callers are
+ *     responsible for bounding it to avoid excessive DMA mappings.
+ *     In practice, hash uses <= 2 entries (partial + new data).
+ *
+ * Return: Opaque cmh_sg_map handle, or NULL on allocation/mapping failure.
+ */
+struct cmh_sg_map *cmh_dma_build_sg(const struct cmh_dma_buf *bufs, u32 count,
+				    gfp_t gfp);
+
+/**
+ * cmh_dma_free_sg() - Unmap all buffers and free the SG chain
+ * @sgm: Handle from cmh_dma_build_sg(), or NULL (no-op)
+ */
+void cmh_dma_free_sg(struct cmh_sg_map *sgm);
+
+#endif /* CMH_DMA_H */
diff --git a/drivers/crypto/cmh/include/cmh_mqi.h b/drivers/crypto/cmh/include/cmh_mqi.h
new file mode 100644
index 000000000000..cd72d8123415
--- /dev/null
+++ b/drivers/crypto/cmh/include/cmh_mqi.h
@@ -0,0 +1,59 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- Mailbox Queue Initializer
+ *
+ * Allocates DMA-capable queue buffers and programs MBX registers
+ * via the MBX lock/setup/enable/unlock register sequence.
+ */
+
+#ifndef CMH_MQI_H
+#define CMH_MQI_H
+
+#include "cmh_config.h"
+
+#define MBX_LOCK_TIMEOUT_MS     1000
+#define MBX_LOCK_POLL_MIN_US    10
+#define MBX_LOCK_POLL_MAX_US    50
+
+/* FLUSH acknowledgment polling (the eSW clears R_MBX_COMMAND) */
+#define MBX_FLUSH_POLL_US       50
+#define MBX_FLUSH_TIMEOUT_US    1000000	/* 1 second */
+
+/**
+ * cmh_mqi_init() - Allocate MBX queue buffers and program registers
+ * @cfg: Global device configuration
+ * @fence: FLUSH each mailbox and require the acknowledgment first
+ *
+ * Locks each configured MBX and, with @fence, requires an acknowledged
+ * FLUSH before allocating any DMA memory, then performs the setup/enable
+ * sequence.
+ *
+ * Return: 0 on success, -EBUSY if a mailbox does not acknowledge the
+ *         fence, or another negative errno on failure.
+ */
+int cmh_mqi_init(struct cmh_config *cfg, bool fence);
+
+/**
+ * cmh_mqi_cleanup() - Free MBX queue buffers and release locks
+ * @cfg: Global device configuration
+ */
+void cmh_mqi_cleanup(struct cmh_config *cfg);
+
+/**
+ * cmh_mqi_settle_all() - FLUSH every mailbox and wait for the engines to settle
+ * @cfg: Global device configuration
+ *
+ * FLUSHes each active mailbox and waits for the eSW to acknowledge, i.e.
+ * to quiesce its cores and DMA engines back to MBX_STATUS_IDLE, so DMA
+ * buffers can be released safely at teardown.  The per-mailbox result is
+ * recorded in cfg->mailboxes[i].fenced; this HW has no DMA-stop primitive,
+ * so memory the device may reach through an unacknowledged mailbox must be
+ * kept.  The caller MUST have stopped the response handler first (so no
+ * completion races the flush) and the mailboxes must still be locked/active.
+ *
+ * Return: true if every mailbox acknowledged.
+ */
+bool cmh_mqi_settle_all(struct cmh_config *cfg);
+
+#endif /* CMH_MQI_H */
diff --git a/drivers/crypto/cmh/include/cmh_registers.h b/drivers/crypto/cmh/include/cmh_registers.h
new file mode 100644
index 000000000000..c9e83daebcae
--- /dev/null
+++ b/drivers/crypto/cmh/include/cmh_registers.h
@@ -0,0 +1,147 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- Hardware Register Definitions
+ *
+ * Derived from the CMH hardware register specification.
+ * All offsets are taken directly from the hardware documentation.
+ */
+
+#ifndef CMH_REGISTERS_H
+#define CMH_REGISTERS_H
+
+#include <linux/io.h>
+#include <linux/types.h>
+
+/* MBX Instance Addressing */
+
+#define CMH_MBX_INSTANCE_SHIFT        12
+#define CMH_MBX_INSTANCE_SIZE         BIT(CMH_MBX_INSTANCE_SHIFT) /* 0x1000 */
+#define CMH_MAX_MBX_INSTANCES         64U
+
+/* MBX Per-Instance Register Offsets */
+
+#define R_MBX_LOCK                    0x000U
+#define R_MBX_HOST_INFO               0x004U
+#define R_MBX_QUEUE_LO                0x008U
+#define R_MBX_QUEUE_HI                0x00CU
+#define R_MBX_QUEUE_SLOTS             0x010U
+#define R_MBX_QUEUE_STRIDE            0x014U
+#define R_MBX_QUEUE_HEAD              0x018U
+#define R_MBX_QUEUE_TAIL              0x01CU
+#define R_MBX_INTERRUPT               0x020U
+#define R_MBX_INTERRUPT_MASK          0x024U
+#define R_MBX_COMMAND                 0x028U
+#define R_MBX_STATUS                  0x02CU
+#define R_MBX_CHILD                   0x030U
+#define R_MBX_ID                      0x034U
+#define R_MBX_HOST_CONFIG             0x038U
+#define R_MBX_SCRATCH                 0x03CU
+
+#define MBX_QUEUE_ALIGNMENT           0x4U
+
+/* MBX Interrupt Bits */
+
+#define MBX_DONE_IRQ                  BIT(0)
+#define MBX_ERROR_IRQ                 BIT(1)
+#define MBX_IRQ_MASK                  (MBX_DONE_IRQ | MBX_ERROR_IRQ)
+
+/* MBX Command Values */
+
+#define MBX_COMMAND_RUN               0x000U
+#define MBX_COMMAND_PAUSE             0xC2FU
+#define MBX_COMMAND_CONTINUE          0x5DBU
+#define MBX_COMMAND_RESTART           0xB78U
+#define MBX_COMMAND_ABORT             0x6F6U
+#define MBX_COMMAND_FLUSH             0x3A5U
+
+/* MBX Status Values */
+
+#define MBX_STATUS_IDLE               0x01U
+#define MBX_STATUS_BUSY               0x10U
+#define MBX_STATUS_HOLD               0x20U
+#define MBX_STATUS_PAUSED             0x28U
+#define MBX_STATUS_SUCCESS            0x40U
+#define MBX_STATUS_ERROR              0x80U
+#define MBX_STATUS_OFFLINE            0x88U  /* ERROR | 0x08: offline/stopped */
+
+#define MBX_MASK_DONE                 (MBX_STATUS_IDLE | MBX_STATUS_SUCCESS)
+#define MBX_MASK_RUNNING              (MBX_STATUS_BUSY | MBX_STATUS_HOLD)
+#define MBX_MASK_STOPPED              MBX_STATUS_OFFLINE
+
+/* MBX Status Field Extraction */
+
+#define MBX_STATUS_CODE(v)            ((v) & 0xFFU)
+#define MBX_STATUS_CORE_ID(v)         (((v) >> 8) & 0xFFU)
+#define MBX_STATUS_ERROR_CODE(v)      (((v) >> 16) & 0xFFU)
+#define MBX_STATUS_CMD_INDEX(v)       (((v) >> 24) & 0xFFU)
+
+/* eSW error codes reported in MBX_STATUS_ERROR_CODE() */
+
+#define CMH_ESW_ECHILD                10U  /* child VCQ failed: see R_MBX_CHILD */
+
+/* SIC Register Offsets (relative to SIC base / instance 0 base) */
+
+#define R_SIC_BOOT_STATUS             0x100U
+#define SIC_BOOT_STATUS_MASK          0x77U
+#define SIC_BOOT_STATUS_PASS          0x66U
+
+#define R_SIC_MBX_AVAILABILITY        0x104U
+#define R_SIC_MBX_AVAILABILITY2       0x108U
+
+#define R_SIC_SW_BOOT_STATUS          0x12CU
+#define SIC_SW_BOOT_STATUS_STARTED    BIT(0)
+#define SIC_SW_BOOT_STATUS_READY      BIT(1)
+#define SIC_SW_BOOT_STATUS_MISSION    BIT(6)
+#define SIC_SW_BOOT_STATUS_MISSION2   BIT(7)
+
+#define R_SIC_SW_ERROR_INFO           0x130U
+#define R_SIC_SW_HEARTBEAT            0x154U
+
+#define R_SIC_GPINTERRUPT             0x160U
+
+#define R_SIC_HW_VERSION0             0x200U
+#define R_SIC_SW_VERSION              0x218U
+#define R_SIC_CORE_ENABLE             0x22CU
+
+/*
+ * Per-core dual-rail enable fields within R_SIC_CORE_ENABLE.  Each core
+ * occupies a 2-bit field; the value 0b01 (low bit set, high bit clear)
+ * means enabled.  A core is present iff (val & (mask | mask << 1)) == mask.
+ */
+#define SIC_CORE_ENABLE_HC            0x00001U
+#define SIC_CORE_ENABLE_AES           0x00004U
+#define SIC_CORE_ENABLE_SM4           0x00010U
+#define SIC_CORE_ENABLE_SM3           0x00040U
+#define SIC_CORE_ENABLE_HCQ           0x00100U
+#define SIC_CORE_ENABLE_QSE           0x00400U
+#define SIC_CORE_ENABLE_PKE           0x01000U
+#define SIC_CORE_ENABLE_DRBG          0x04000U
+#define SIC_CORE_ENABLE_CCP           0x10000U
+
+static inline bool cmh_sic_core_enabled(u32 core_enable, u32 mask)
+{
+	return (core_enable & (mask | (mask << 1))) == mask;
+}
+
+/* Register Access Helpers */
+
+static inline u32 cmh_reg_read32(void __iomem *base, u32 offset)
+{
+	return ioread32((u8 __iomem *)base + offset);
+}
+
+static inline void cmh_reg_write32(u32 value, void __iomem *base, u32 offset)
+{
+	iowrite32(value, (u8 __iomem *)base + offset);
+}
+
+/* Return the ioremap'd base for MBX instance N within the SIC region */
+static inline void __iomem *cmh_mbx_instance_base(void __iomem *sic_mapped,
+						  u32 instance)
+{
+	return (u8 __iomem *)sic_mapped +
+	       ((unsigned long)instance << CMH_MBX_INSTANCE_SHIFT);
+}
+
+#endif /* CMH_REGISTERS_H */
diff --git a/drivers/crypto/cmh/include/cmh_rh.h b/drivers/crypto/cmh/include/cmh_rh.h
new file mode 100644
index 000000000000..7c58399109c8
--- /dev/null
+++ b/drivers/crypto/cmh/include/cmh_rh.h
@@ -0,0 +1,98 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- Response Handler
+ *
+ * IRQ-driven completion processing.  Uses request_threaded_irq():
+ *   - Hardirq: read+clear MBX interrupt registers, wake thread
+ *   - Threaded handler: walk per-MBX transaction queues,
+ *     fire completion callbacks, free transaction objects
+ *
+ * The Response Handler consumes transaction_obj entries enqueued
+ * by the Transaction Manager (cmh_txn.c) on each per-mailbox txq.
+ */
+
+#ifndef CMH_RH_H
+#define CMH_RH_H
+
+#include "cmh_config.h"
+
+/**
+ * cmh_rh_init() - Register IRQ handler and start response processing
+ * @cfg: Global device configuration
+ *
+ * Return: 0 on success, negative errno on failure.
+ */
+int  cmh_rh_init(struct cmh_config *cfg);
+
+/**
+ * cmh_rh_cleanup() - Free IRQ and stop response processing
+ * @cfg: Global device configuration
+ */
+void cmh_rh_cleanup(struct cmh_config *cfg);
+
+/**
+ * cmh_rh_suspend() - Quiesce RH for system suspend
+ * @cfg: Global device configuration
+ *
+ * Cancels the watchdog timer and masks MBX interrupts at the hardware
+ * level.  IRQ handlers remain registered (standard PM pattern).
+ * The threaded IRQ handler stays active so that cmh_tm_quiesce()
+ * (called after this) can still drain in-flight transactions via
+ * IRQ-driven completions.
+ */
+void cmh_rh_suspend(struct cmh_config *cfg);
+
+/**
+ * cmh_rh_resume() - Restart RH after system resume
+ * @cfg: Global device configuration
+ *
+ * Re-synchronises per-MBX head tracking with hardware, clears stale
+ * interrupt bits, re-enables MBX interrupt masks, and re-arms the
+ * watchdog timer.  Must be called before cmh_tm_resume().
+ */
+void cmh_rh_resume(struct cmh_config *cfg);
+
+/* debugfs timeout accessor (debug builds only) */
+#ifdef CONFIG_CRYPTO_DEV_CMH_DEBUG
+unsigned int *cmh_rh_timeout_watchdog_ptr(void);
+#endif
+
+/**
+ * cmh_rh_force_drain_mbx() - FLUSH + drain all pending transactions on a MBX
+ * @mbx_idx: Mailbox index to drain
+ *
+ * Resets the recovery bookkeeping (including the wedged flag), closes
+ * the mailbox to new submissions and issues MBX_COMMAND_FLUSH, then waits
+ * up to MBX_FLUSH_TIMEOUT_US for the eSW to acknowledge it; on the
+ * acknowledgment every pending transaction completes with -ECANCELED and
+ * the mailbox reopens.  Process context; acquires rh_process_lock.
+ * Intended for debugfs last-resort recovery.
+ */
+void cmh_rh_force_drain_mbx(u32 mbx_idx);
+
+/**
+ * cmh_rh_mbx_is_wedged() - Check if a mailbox is permanently wedged
+ * @mbx_idx: Mailbox index to check
+ *
+ * Returns true if the mailbox has failed RESTART+FLUSH recovery and
+ * is offline.  Used by the TM to avoid submitting new work to a dead
+ * mailbox.
+ *
+ * Return: true if wedged, false otherwise (including out-of-range idx).
+ */
+bool cmh_rh_mbx_is_wedged(u32 mbx_idx);
+
+/**
+ * cmh_rh_abort_mbx() - Issue MBX_COMMAND_ABORT under rh_process_lock
+ * @mbx_idx: Mailbox index to abort
+ * @vcq_id: Abort only while this VCQ is at HEAD; negative for any
+ *
+ * Serialises the ABORT with the RESTART/FLUSH commands of the response
+ * handler and watchdog, and skips it while one of those is pending.
+ *
+ * Return: true if the ABORT was written.
+ */
+bool cmh_rh_abort_mbx(u32 mbx_idx, s64 vcq_id);
+
+#endif /* CMH_RH_H */
diff --git a/drivers/crypto/cmh/include/cmh_sys_abi.h b/drivers/crypto/cmh/include/cmh_sys_abi.h
new file mode 100644
index 000000000000..64110311e552
--- /dev/null
+++ b/drivers/crypto/cmh/include/cmh_sys_abi.h
@@ -0,0 +1,148 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- SYS Core ABI Definitions
+ *
+ * Kernel-side definitions for the CMH SYS ABI.
+ * All constants and layouts derived from the CMH eSW ABI.
+ */
+
+#ifndef CMH_SYS_ABI_H
+#define CMH_SYS_ABI_H
+
+#include <linux/bits.h>
+#include <linux/types.h>
+
+/* SYS Commands (per CMH SYS ABI) */
+
+#define SYS_CMD_RUN		0x01U
+#define SYS_CMD_NOP		0x02U
+#define SYS_CMD_IMPORT		0x07U
+#define SYS_CMD_EXPORT		0x08U
+#define SYS_CMD_NEW		0x0AU
+#define SYS_CMD_READ		0x0BU
+#define SYS_CMD_WRITE		0x0CU
+#define SYS_CMD_GRANT		0x0DU
+#define SYS_CMD_LIST		0x0EU
+#define SYS_CMD_FIND		0x0FU
+#define SYS_CMD_DATA		0x11U
+
+/* SYS Reference Constants */
+
+#define SYS_REF_NONE		0x0000000000000000ULL
+#define SYS_REF_TEMP		0x1111111111111111ULL
+#define SYS_REF_LAST		0xFFFFFFFFFFFFFFFFULL
+
+typedef u64 sys_ref_t;
+
+/* SYS CID */
+
+#define SYS_CID_NONE		0x0000000000000000ULL
+
+/* SYS Type Encoding -- bits [7:0] = core_id, bits [23:16] = flags */
+
+#define SYS_TYPE_FLAG_PT	BIT(16)  /* can be read as plaintext */
+#define SYS_TYPE_FLAG_XC	BIT(17)  /* can be exported over XC bus */
+#define SYS_TYPE_FLAG_SCA	BIT(18)  /* SCA key in 2 shares */
+
+#define SYS_TYPE_SET(flags, core) \
+	(((flags) & 0xFF0000UL) | ((core) & 0xFFUL))
+#define SYS_TYPE_CORE(type)	((type) & 0xFFU)
+#define SYS_TYPE_FLAGS(type)	((type) & 0xFF0000U)
+#define SYS_TYPE_NONE		0U	/* DMA output, no DS storage */
+
+#define SYS_WRAP_HDR_SIZE	16	/* sys_read plaintext header */
+
+/* SYS Command Structures */
+
+struct sys_cmd_new {
+	u64 cid;	/* caller id (name) for the object */
+	u64 ref;	/* DMA address -- CMH eSW writes back reference here */
+	u32 len;	/* size of the new object in bytes */
+};
+
+struct sys_cmd_write {
+	u64 ref;	/* object datastore reference */
+	u64 src;	/* DMA source address of key data */
+	u64 key;	/* wrapping key reference (SYS_REF_NONE = plaintext) */
+	u32 len;	/* source buffer length */
+	u32 type;	/* SYS_TYPE_SET(flags, core_id) */
+};
+
+struct sys_cmd_read {
+	u64 ref;	/* object datastore reference */
+	u64 dst;	/* DMA destination for key data */
+	u64 key;	/* wrapping key reference (SYS_REF_NONE = plaintext) */
+	u32 len;	/* destination buffer length */
+};
+
+struct sys_cmd_data {
+	u64 ref;	/* object datastore reference */
+	u64 dst;	/* DMA destination for object data */
+	u32 len;	/* destination buffer length */
+};
+
+struct sys_cmd_find {
+	u64 cid;	/* caller id to search for */
+	u64 dst;	/* DMA destination for struct sys_list_item */
+	u32 len;	/* destination buffer length */
+};
+
+struct sys_cmd_list {
+	u64 ref;	/* starting DS reference (SYS_REF_NONE = first) */
+	u64 dst;	/* DMA destination for struct sys_list_item */
+	u32 len;	/* destination buffer length */
+};
+
+struct sys_cmd_grant {
+	u64 ref;	/* object datastore reference */
+	u64 read;	/* bitfield: allow read for mailboxes */
+	u64 write;	/* bitfield: allow write for mailboxes */
+	u64 execute;	/* bitfield: allow use for mailboxes */
+};
+
+struct sys_cmd_export {
+	u64 cid;	/* caller id for the response */
+	u64 dst;	/* DMA destination for the export blob */
+	u64 key;	/* wrapping key datastore reference */
+	u32 len;	/* destination buffer length */
+};
+
+struct sys_cmd_import {
+	u64 src;	/* DMA source address of import blob */
+	u64 key;	/* wrapping key datastore reference */
+	u32 len;	/* source buffer length */
+};
+
+/* SYS List/Find Response Item */
+
+struct sys_list_item {
+	u64 ref;	/* object datastore reference */
+	u64 cid;	/* caller id */
+	u32 len;	/* object length */
+	u32 type;	/* object type (SYS_TYPE_SET packed) */
+};
+
+/* Wrapped-read header (prepended to SYS_CMD_READ responses) */
+
+struct sys_wrap_hdr {
+	u64 cid;	/* caller id */
+	u32 wrap;	/* wrap data length following this header */
+	u32 len;	/* object data length following wrap data */
+};
+
+/* SYS Command Union */
+
+union sys_cmd {
+	struct sys_cmd_new	cmd_new;
+	struct sys_cmd_write	cmd_write;
+	struct sys_cmd_read	cmd_read;
+	struct sys_cmd_data	cmd_data;
+	struct sys_cmd_find	cmd_find;
+	struct sys_cmd_list	cmd_list;
+	struct sys_cmd_grant	cmd_grant;
+	struct sys_cmd_export	cmd_export;
+	struct sys_cmd_import	cmd_import;
+};
+
+#endif /* CMH_SYS_ABI_H */
diff --git a/drivers/crypto/cmh/include/cmh_sysfs.h b/drivers/crypto/cmh/include/cmh_sysfs.h
new file mode 100644
index 000000000000..864cf1c8fa00
--- /dev/null
+++ b/drivers/crypto/cmh/include/cmh_sysfs.h
@@ -0,0 +1,14 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- sysfs Device Attributes
+ */
+
+#ifndef CMH_SYSFS_H
+#define CMH_SYSFS_H
+
+struct attribute_group;
+
+extern const struct attribute_group *cmh_sysfs_groups[];
+
+#endif /* CMH_SYSFS_H */
diff --git a/drivers/crypto/cmh/include/cmh_txn.h b/drivers/crypto/cmh/include/cmh_txn.h
new file mode 100644
index 000000000000..b50ac29e6625
--- /dev/null
+++ b/drivers/crypto/cmh/include/cmh_txn.h
@@ -0,0 +1,666 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- Transaction Manager
+ *
+ * Dedicated kthread managing concurrent VCQ submissions.
+ *
+ * Callers post command_msg objects into the Command Message Queue (CMQ).
+ * The TM thread dequeues them, selects a mailbox, builds VCQ(s) in the
+ * DMA queue slot, creates a transaction_obj, and rings the doorbell.
+ *
+ * The Response Handler (cmh_rh.c) walks per-mailbox transaction queues
+ * when an IRQ fires and fires completion callbacks.
+ */
+
+#ifndef CMH_TXN_H
+#define CMH_TXN_H
+
+#include <linux/types.h>
+#include <linux/dma-direction.h>
+#include <linux/list.h>
+#include <linux/spinlock.h>
+#include <linux/completion.h>
+#include <linux/jiffies.h>
+#include <linux/refcount.h>
+#include <linux/mutex.h>
+#include <linux/timer.h>
+#include <crypto/algapi.h>
+
+#include "cmh_config.h"
+#include "cmh_vcq.h"
+
+/* Request DMA Set */
+
+struct cmh_sg_map;
+
+#define CMH_REQ_DMA_MAX		8
+
+struct cmh_req_dma_ent {
+	void			*buf;		/* kmalloc'd CPU buffer, or NULL */
+	dma_addr_t		 dma;
+	size_t			 len;
+	enum dma_data_direction	 dir;
+	bool			 mapped;
+	bool			 sensitive;	/* free with kfree_sensitive() */
+	bool			 sg_src;	/* mapped by the set's @sgm */
+};
+
+/**
+ * struct cmh_req_dma - DMA buffers of one asynchronous request
+ * @ent: Mapped (or still to be freed) CPU buffers
+ * @sgm: Scatter-gather chain built by cmh_dma_build_sg(), or NULL
+ * @n: Number of valid entries in @ent
+ *
+ * Every device-reachable buffer of an asynchronous request is recorded
+ * here, and the set is handed to the transaction manager with the
+ * submission.  The completion path, not the algorithm, decides when the
+ * buffers may be released: if the device may still access them when the
+ * request completes (a mailbox FLUSH that was never acknowledged), the
+ * transaction manager quarantines the whole set before the completion
+ * callback runs.  That empties the set, so the callback's
+ * cmh_req_dma_unmap() and cmh_req_dma_free() release nothing, and the
+ * buffers are held until the device is known to be quiescent.  On every
+ * other completion the callback unmaps the set, reads its output and
+ * frees it as usual.
+ */
+struct cmh_req_dma {
+	struct cmh_req_dma_ent	 ent[CMH_REQ_DMA_MAX];
+	struct cmh_sg_map	*sgm;
+	unsigned int		 n;
+};
+
+/**
+ * cmh_req_dma_init() - Initialise an empty request DMA set
+ * @rd: Set to initialise
+ */
+void cmh_req_dma_init(struct cmh_req_dma *rd);
+
+/**
+ * cmh_req_dma_add() - Record and DMA-map a request buffer
+ * @rd: Request DMA set
+ * @buf: kmalloc'd buffer; the set owns it from this call on
+ * @len: Length to map
+ * @dir: DMA direction
+ * @sensitive: Free with kfree_sensitive() rather than kfree()
+ *
+ * The set takes ownership of @buf even when the mapping fails, so the
+ * caller unwinds with cmh_req_dma_release() alone.
+ *
+ * Return: The DMA address, or a mapping error (cmh_dma_map_error()).
+ */
+dma_addr_t cmh_req_dma_add(struct cmh_req_dma *rd, void *buf, size_t len,
+			   enum dma_data_direction dir, bool sensitive);
+
+/**
+ * cmh_req_dma_add_sg() - Record a scatter-gather chain
+ * @rd: Request DMA set
+ * @sgm: Chain from cmh_dma_build_sg(); the set owns it from this call on
+ */
+void cmh_req_dma_add_sg(struct cmh_req_dma *rd, struct cmh_sg_map *sgm);
+
+/**
+ * cmh_req_dma_own() - Record a source buffer of the scatter-gather chain
+ * @rd: Request DMA set
+ * @buf: kmalloc'd buffer passed to cmh_dma_build_sg(); the set owns it
+ *       from this call on
+ * @sensitive: Free with kfree_sensitive() rather than kfree()
+ *
+ * The chain maps and unmaps @buf itself, so the set only frees it, after
+ * the chain.  Quarantining the set holds @buf together with the chain.
+ * Record @buf even when cmh_dma_build_sg() fails, so the caller unwinds
+ * with cmh_req_dma_release() alone.
+ */
+void cmh_req_dma_own(struct cmh_req_dma *rd, void *buf, bool sensitive);
+
+/**
+ * cmh_req_dma_unmap() - Unmap every mapped buffer for CPU access
+ * @rd: Request DMA set
+ */
+void cmh_req_dma_unmap(struct cmh_req_dma *rd);
+
+/**
+ * cmh_req_dma_free() - Free every buffer of the set and empty it
+ * @rd: Request DMA set; call cmh_req_dma_unmap() first
+ */
+void cmh_req_dma_free(struct cmh_req_dma *rd);
+
+/**
+ * cmh_req_dma_release() - Unmap and free the whole set
+ * @rd: Request DMA set
+ */
+void cmh_req_dma_release(struct cmh_req_dma *rd);
+
+/* DMA Quarantine */
+
+/**
+ * struct cmh_dma_orphan - A DMA buffer held back from release
+ * @buf: CPU buffer (freed with kfree_sensitive()), or NULL
+ * @addr: Its DMA mapping
+ * @len: Mapped length
+ * @dir: DMA direction of the mapping, or DMA_NONE if @buf has no mapping
+ *       of its own (a scatter-gather source, mapped by its chain)
+ * @sgm: Scatter-gather chain to free, or NULL
+ * @node: Quarantine list linkage
+ *
+ * Describes a buffer the device may still access.  Allocate it zeroed.
+ * It is either released by cmh_dma_orphan_free() once the owning
+ * transfer is known to be finished, or quarantined: held, never freed
+ * at runtime, and released at module unload only if every mailbox
+ * then acknowledges a FLUSH (otherwise deliberately leaked).
+ */
+struct cmh_dma_orphan {
+	void                    *buf;
+	dma_addr_t               addr;
+	size_t                   len;
+	enum dma_data_direction  dir;
+	struct cmh_sg_map       *sgm;
+	struct list_head         node;
+};
+
+/**
+ * cmh_dma_orphan_free() - Release or quarantine an orphaned DMA buffer
+ * @data: Pointer to a struct cmh_dma_orphan
+ * @error: Completion status of the owning VCQ (0 = clean completion)
+ *
+ * Callback for cmh_tm_submit_sync_noabort().  A clean completion means
+ * the eSW finished the transfer, so the buffer is unmapped and freed; any
+ * other status quarantines it.
+ */
+void cmh_dma_orphan_free(void *data, int error);
+
+/**
+ * cmh_dma_free_out() - Dispose of a synchronous op's DMA output buffer
+ * @buf: kmalloc'd CPU buffer the eSW writes into
+ * @dma: Its DMA mapping
+ * @len: Mapped length
+ * @dir: DMA direction of the mapping
+ * @park: Quarantine instead of freeing (the submit timed out)
+ *
+ * Pass @park for -ETIMEDOUT: the device then never confirmed it was done
+ * with the buffer.  Input-only (DMA_TO_DEVICE) buffers are released by the
+ * caller; a late device read of one cannot corrupt host memory, and its
+ * result lands in a quarantined output.
+ */
+void cmh_dma_free_out(void *buf, dma_addr_t dma, size_t len,
+		      enum dma_data_direction dir, bool park);
+
+/**
+ * cmh_tm_dma_quarantine_buf() - Quarantine a buffer the device may access
+ * @buf: kmalloc'd CPU buffer (freed with kfree_sensitive()), or NULL
+ * @dma: Its DMA mapping
+ * @len: Mapped length
+ * @dir: DMA direction of the mapping
+ *
+ * Safe from any non-hardirq context.  If no tracking record can be
+ * allocated the buffer is leaked, never freed.
+ */
+void cmh_tm_dma_quarantine_buf(void *buf, dma_addr_t dma, size_t len,
+			       enum dma_data_direction dir);
+
+/**
+ * cmh_tm_dma_quiescent() - Whether all device DMA is known to be finished
+ *
+ * Return: false once any transaction has completed without the device
+ *         acknowledging the FLUSH that ended it, true otherwise.
+ */
+bool cmh_tm_dma_quiescent(void);
+
+/* Command Message (caller -> TM) */
+
+typedef void (*cmh_completion_fn)(void *data, int error);
+
+struct command_msg {
+	struct list_head    list;           /* CMQ linked list node */
+	u32                 command_id;     /* VCQ_CMD_ID(core, flags, span, cmd) */
+	void               *vcq_data;      /* heap-owned copy of VCQ entries */
+	u32                 vcq_count;      /* total vcq_cmd entries across all VCQs */
+	u32                 num_vcqs;       /* how many VCQs in vcq_data (0 or 1 = single) */
+	s32                 target_mbx;     /* MBX index from core affinity, or -1 fallback */
+	s32                 actual_mbx;     /* MBX selected by TM thread, -1 until dispatched */
+	u32                 first_vcq_id;   /* HW VCQ id of first slot, U32_MAX until submitted */
+	cmh_completion_fn   complete;       /* completion callback (may be NULL) */
+	void               *completion_data;
+	struct cmh_req_dma *rdma;           /* async request DMA set, or NULL */
+	refcount_t          refs;           /* submit_sync: 2 = waiter + TM */
+	bool                backlog_ok;     /* accept into backlog when CMQ is full */
+	unsigned long       timeout_jiffies;/* per-txn async timeout (0 = none) */
+};
+
+/* Transaction Object (TM -> RH) */
+
+/* Per-transaction FSM states for async timeout resolution */
+#define TXN_INFLIGHT	0
+#define TXN_COMPLETE	1
+#define TXN_TIMED_OUT	2
+
+struct transaction_obj {
+	struct list_head    list;           /* per-mailbox txn queue node */
+	u32                 first_vcq_id;
+	u32                 last_vcq_id;
+	u32                 mailbox_idx;    /* index into cfg->mailboxes[] */
+	u32                 command_id;     /* VCQ_CMD_ID from first payload cmd */
+	int                 error_code;
+	cmh_completion_fn   complete;
+	void               *completion_data;
+	struct cmh_req_dma *rdma;           /* async request DMA set, or NULL */
+	atomic_t            state;          /* TXN_INFLIGHT / COMPLETE / TIMED_OUT */
+	struct timer_list   timeout_timer;  /* per-request async timeout */
+	refcount_t          refs;           /* owner + timer (if armed) */
+};
+
+/* Per-Mailbox Transaction Queue */
+
+struct cmh_mbx_txq {
+	struct list_head    head;
+	spinlock_t          lock;           /* protects head list + depth */
+	u32                 depth;          /* number of in-flight transactions */
+	bool                closed;         /* FLUSH pending: no new publication */
+	struct mutex        dispatch_lock;  /* serialises VCQ dispatch + MBX flush */
+};
+
+/* Public Interface */
+
+/**
+ * cmh_tm_init() - Initialise the Transaction Manager
+ * @cfg: Global device configuration (mailbox layout, IRQ, etc.)
+ *
+ * Starts the TM kthread and initialises per-mailbox transaction queues.
+ *
+ * Return: 0 on success, negative errno on failure.
+ */
+int  cmh_tm_init(struct cmh_config *cfg);
+
+/**
+ * cmh_tm_cleanup() - Stop the TM kthread and drain all queues
+ */
+void cmh_tm_cleanup(void);
+
+/**
+ * cmh_tm_stop() - Stop accepting and dispatching new work
+ *
+ * Stops the TM kthread and cancels everything still queued in the CMQ
+ * and backlog with -ECANCELED.  In-flight transactions are left to
+ * complete through the Response Handler.  Idempotent.
+ */
+void cmh_tm_stop(void);
+
+/**
+ * cmh_tm_quiesce() - Stop TM kthread and drain in-flight transactions
+ *
+ * Stops the TM kthread, rejects new posts, then waits (with a
+ * configurable timeout) for all per-MBX transaction queues to drain.
+ * If work is still in flight at the deadline, the TM is restarted and
+ * the in-flight work keeps running.
+ *
+ * Return: 0 once drained, -EBUSY if work is still in flight.
+ */
+int  cmh_tm_quiesce(void);
+
+/**
+ * cmh_tm_resume() - Restart the TM kthread after resume
+ *
+ * Return: 0 on success, negative errno if the kthread fails to start.
+ */
+int  cmh_tm_resume(void);
+
+/**
+ * cmh_tm_post_command() - Post a command to the TM for submission
+ * @msg: Command message with pre-built VCQ data and completion callback
+ *
+ * Round-robin selects the next MBX with enough free slots for
+ * msg->num_vcqs VCQs.  All VCQs in a message are written to
+ * consecutive slots on the same MBX (back-to-back).
+ * The caller retains ownership of @msg until the completion callback fires.
+ *
+ * Return: 0 on success, -EBUSY if backlogged, -ENOSPC if the queue is
+ *         full and @msg may not be backlogged, -ENODEV if TM stopped.
+ */
+int  cmh_tm_post_command(struct command_msg *msg);
+
+/*
+ * Synchronous submit -- post one or more VCQs and wait for completion.
+ *
+ * Combines post_command + refcounted wait + timeout + cancel into one
+ * call.  This is the standard pattern for all synchronous crypto ops.
+ *
+ * Context: must be called from a sleepable (task) context.
+ *          Performs GFP_KERNEL allocations and sleeps on
+ *          wait_for_completion_timeout().  A WARN_ON_ONCE fires
+ *          if called from atomic / IRQ / softirq context.
+ *
+ * vcq_cmds:   pre-built VCQ array (headers + commands, contiguous)
+ * vcq_count:  total number of vcq_cmd entries across all VCQs
+ * num_vcqs:   number of VCQs in the array (0 or 1 = single VCQ)
+ *
+ * For multi-VCQ submissions, the array contains multiple VCQs laid
+ * out contiguously, each starting with its own header.  All VCQs are
+ * written to consecutive MBX slots and share one transaction object.
+ *
+ * Returns 0 on success, -ETIMEDOUT, or CMH eSW error code.
+ */
+int  cmh_tm_submit_sync(struct vcq_cmd *vcq_cmds, u32 vcq_count,
+			u32 num_vcqs);
+
+/*
+ * Synchronous submit pinned to a specific mailbox.
+ * target_mbx: -1 = round-robin, >= 0 = pin to that MBX index.
+ */
+int  cmh_tm_submit_sync_mbx(struct vcq_cmd *vcq_cmds, u32 vcq_count,
+			    u32 num_vcqs, s32 target_mbx);
+
+/*
+ * Synchronous submit with explicit timeout.
+ * timeout_hz: completion timeout in jiffies (use msecs_to_jiffies()).
+ */
+
+/*
+ * Extended timeout for slow crypto operations such as key generation,
+ * tunable via debugfs config/slow_op_timeout_ms.
+ */
+unsigned long cmh_tm_slow_op_timeout_jiffies(void);
+
+int  cmh_tm_submit_sync_tmo(struct vcq_cmd *vcq_cmds, u32 vcq_count,
+			    u32 num_vcqs, s32 target_mbx,
+			    unsigned long timeout_hz);
+
+/*
+ * Synchronous submit that never issues MBX_COMMAND_ABORT on timeout.
+ * Returns -EAGAIN if cancelled from queue, -EINPROGRESS if the VCQ is
+ * left in-flight.  On -EINPROGRESS, @orphan_cb(@orphan_data, error) will
+ * be called when the VCQ eventually completes (RH callback fires and the
+ * last sync_ctx ref drops); @error is the completion status so the
+ * callback can free a clean buffer but park one the eSW may still be
+ * writing.  Use this to defer DMA cleanup.
+ * Safe for background/kthread callers that must not disrupt other MBX work.
+ */
+int  cmh_tm_submit_sync_noabort(struct vcq_cmd *vcq_cmds, u32 vcq_count,
+				u32 num_vcqs, unsigned long timeout_hz,
+				void (*orphan_cb)(void *, int),
+				void *orphan_data);
+
+/*
+ * Asynchronous submit -- post VCQs and return immediately.
+ *
+ * On successful return (0), the provided @callback may be invoked from
+ * either the RH threaded IRQ context (normal completion path) or the TM
+ * kthread (if VCQ dispatch to the HW ring fails after the message was
+ * posted to the CMQ).  The caller must not assume a specific callback
+ * context.
+ *
+ * After a successful post, the caller must NOT touch VCQ buffers --
+ * ownership transfers to the TM.  If this function returns non-zero,
+ * the message was not posted, the callback will NOT fire, and the caller
+ * must perform cleanup.
+ *
+ * @rdma, if not NULL, records the request's DMA buffers.  It must stay
+ * valid until the callback delivers the final status; if the device may
+ * still access the buffers then, the TM quarantines the set first (see
+ * struct cmh_req_dma).
+ *
+ * Uses GFP_ATOMIC internally -- the crypto API may invoke driver ops
+ * from softirq context (e.g. IPsec), so GFP_KERNEL would deadlock.
+ *
+ * If @backlog_ok is true and the CMQ is full, the message is placed on
+ * the unbounded backlog queue and -EBUSY is returned.  The caller must
+ * treat -EBUSY as "accepted" (like -EINPROGRESS): the callback WILL
+ * fire once the request is promoted from backlog and completes.  When
+ * @backlog_ok is false, CMQ-full returns -ENOSPC (caller must clean up).
+ *
+ * Returns: 0 on successful post, -EBUSY (backlogged -- callback will
+ *          fire), -ENOMEM, -EINVAL (bad vcq_count), -ENOSPC (CMQ full,
+ *          no backlog), -ENODEV.
+ */
+int  cmh_tm_submit_async(struct vcq_cmd *vcq_cmds, u32 vcq_count,
+			 u32 num_vcqs, s32 target_mbx,
+			 cmh_completion_fn callback, void *callback_data,
+			 struct cmh_req_dma *rdma,
+			 bool backlog_ok, unsigned long timeout_jiffies);
+
+/**
+ * cmh_tm_async_timeout_jiffies() - Default per-request async timeout
+ *
+ * Returns the debugfs-configurable timeout for symmetric data-path
+ * ops (async_timeout_ms converted to jiffies).  Akcipher/kpp callers
+ * should pass 0 instead (no per-request timeout; vcq_timeout_ms is the
+ * safety net).
+ */
+unsigned long cmh_tm_async_timeout_jiffies(void);
+
+/**
+ * cmh_tm_poke_tail() - Re-write R_MBX_QUEUE_TAIL to wake the eSW
+ * @base: Mailbox register base
+ *
+ * Serialised against the submit_vcq() doorbell so a re-poke cannot roll
+ * back a concurrent submission.  Safe from softirq/timer context.
+ */
+void cmh_tm_poke_tail(void __iomem *base);
+
+/**
+ * cmh_tm_try_cancel_command() - Try to cancel a queued command
+ * @msg: Command message to cancel
+ *
+ * Return: true if removed from CMQ, false if already consumed by the TM thread.
+ */
+bool cmh_tm_try_cancel_command(struct command_msg *msg);
+
+/**
+ * cmh_tm_peek_transaction() - Peek at the oldest transaction on a mailbox
+ * @mbx_idx: Mailbox index
+ *
+ * For use by the Response Handler.  Caller must hold txq->lock or call
+ * from a context where no concurrent pop is possible (e.g. threaded IRQ).
+ *
+ * Return: Pointer to the oldest transaction_obj, or NULL if empty.
+ */
+struct transaction_obj *cmh_tm_peek_transaction(u32 mbx_idx);
+
+/**
+ * cmh_tm_pop_transaction() - Remove and return the oldest transaction
+ * @mbx_idx: Mailbox index
+ *
+ * Return: Pointer to the removed transaction_obj, or NULL if empty.
+ */
+struct transaction_obj *cmh_tm_pop_transaction(u32 mbx_idx);
+
+/**
+ * cmh_txn_finish() - Complete a transaction with FSM + timer handling
+ * @txn: Transaction popped from the TXQ
+ * @error: Error code (0 for success, negative errno)
+ * @dma_live: The device may still access the transaction's DMA buffers
+ *
+ * Resolves the timer-vs-completion race via atomic cmpxchg, cancels
+ * the per-txn timeout timer if still pending, quarantines the request's
+ * DMA set if @dma_live, fires the completion callback (if this path wins
+ * the race), and drops the owner reference.  The transaction is freed
+ * when the last reference is dropped.
+ *
+ * Called by the Response Handler after popping a transaction.
+ */
+void cmh_txn_finish(struct transaction_obj *txn, int error, bool dma_live);
+
+/**
+ * cmh_tm_mbx_admit() - Open or close a mailbox to new submissions
+ * @mbx_idx: Mailbox index
+ * @open: true to accept submissions again, false to stop them
+ *
+ * Closed while the Response Handler waits for the eSW to acknowledge a
+ * FLUSH, so that no VCQ is published that the FLUSH could discard or the
+ * post-FLUSH drain could pop.  Requests for a closed mailbox wait in the
+ * CMQ.  Safe from softirq context.
+ */
+void cmh_tm_mbx_admit(u32 mbx_idx, bool open);
+
+/**
+ * cmh_tm_max_cmds_per_vcq() - Max vcq_cmd entries per MBX slot
+ *
+ * Returns the minimum across all configured MBXes so callers can pack
+ * VCQs without knowing which MBX will be selected.
+ *
+ * Return: At least MIN_VCQ_CMDS (2).
+ */
+u32  cmh_tm_max_cmds_per_vcq(void);
+
+/**
+ * cmh_tm_mbx_count() - Return the number of configured mailboxes
+ *
+ * Return: cfg->mbx_count.
+ */
+u32  cmh_tm_mbx_count(void);
+
+/**
+ * cmh_core_default_id() - Return the default core_id for a core type
+ * @type: Logical core type enum
+ *
+ * Returns the core_id of the first (index-0) instance without advancing
+ * the round-robin counter.  Intended for callers pinned to a fixed MBX
+ * that only need the VCQ core_id field.
+ *
+ * In multi-instance configurations the returned core_id is always that
+ * of instance[0], regardless of which MBX instance[0] is assigned to;
+ * the eSW accepts any valid core_id on any MBX for command dispatch.
+ *
+ * Return: u32 core_id.
+ */
+u32  cmh_core_default_id(enum cmh_core_type type);
+
+/**
+ * cmh_core_select_instance() - Multi-instance core dispatch selection
+ * @type: Logical core type enum
+ *
+ * Returns the next (core_id, mbx_idx) pair for @type using round-robin
+ * across configured instances.  On first use for an instance whose MBX
+ * is not pre-assigned, atomically assigns the next available MBX.
+ *
+ * With single-instance defaults, this degenerates to the same behaviour
+ * as the old single-entry core_to_mbx[] table -- one core type, one MBX.
+ *
+ * Return: struct core_dispatch with core_id and mbx_idx.
+ */
+struct core_dispatch cmh_core_select_instance(enum cmh_core_type type);
+
+/**
+ * cmh_core_num_instances() - Return count of configured instances
+ * @type: Logical core type enum
+ *
+ * Return: Number of instances for @type, or 0 if the core is absent from
+ *         the CORE_ENABLE register (not present in this hardware build).
+ */
+u32  cmh_core_num_instances(enum cmh_core_type type);
+
+/**
+ * cmh_core_present() - Test whether a core type was discovered
+ * @type: Logical core type enum
+ *
+ * Return: true if at least one instance of @type is present in hardware,
+ *         false if the core is absent.  Used to gate crypto-API
+ *         registration so an absent core advertises no algorithms.
+ */
+static inline bool cmh_core_present(enum cmh_core_type type)
+{
+	return cmh_core_num_instances(type) > 0;
+}
+
+/**
+ * cmh_core_get_instance() - Get a specific instance by index
+ * @type: Logical core type enum
+ * @idx: Instance index (0-based, must be < cmh_core_num_instances())
+ *
+ * Returns (core_id, mbx_idx) for the given instance without advancing
+ * the round-robin counter.  Triggers auto-assign if the instance has
+ * no MBX yet.
+ *
+ * Return: struct core_dispatch with core_id and mbx_idx.
+ */
+struct core_dispatch cmh_core_get_instance(enum cmh_core_type type, u32 idx);
+
+/**
+ * cmh_tm_affinity_reset() - Reset all core-to-MBX assignments
+ *
+ * Called during init and cleanup.
+ */
+void cmh_tm_affinity_reset(void);
+
+/**
+ * cmh_tm_txq_completion_notify() - Wake TM thread after TXQ completion
+ *
+ * Called by the Response Handler after completing a transaction to
+ * unblock the TM thread if it is waiting for a free MBX slot.
+ */
+void cmh_tm_txq_completion_notify(void);
+
+/**
+ * cmh_vcq_pack_and_submit_async() - Pack payload commands and submit async
+ * @payload: Flat array of VCQ command entries (no headers)
+ * @count: Number of entries in @payload
+ * @packed: Caller-provided scratch buffer for packed output
+ * @max_packed: Size of @packed in vcq_cmd entries
+ * @target_mbx: Mailbox index (-1 for round-robin)
+ * @callback: Completion callback
+ * @callback_data: Opaque data passed to @callback
+ * @rdma: Request DMA set, or NULL (see cmh_tm_submit_async())
+ * @backlog_ok: If true, accept into backlog when CMQ is full
+ * @timeout_jiffies: Per-request timeout (0 to disable)
+ *
+ * Splits @payload into VCQ-sized chunks with their own headers and
+ * submits them as one transaction.  Returns 0 on successful post; after
+ * a successful post, @callback may run from RH threaded IRQ context on
+ * normal completion, from the TM kthread if VCQ dispatch fails after
+ * posting, or from TM teardown paths such as
+ * cmh_tm_cleanup() / cmh_tm_quiesce() when queued or in-flight work is
+ * cancelled.  Callers must not assume a single callback context.  On
+ * non-zero return, the callback will NOT fire.
+ *
+ * Return: 0 on successful post, -EBUSY (backlogged), negative errno on failure.
+ */
+int  cmh_vcq_pack_and_submit_async(const struct vcq_cmd *payload, u32 count,
+				   struct vcq_cmd *packed, u32 max_packed,
+				   s32 target_mbx,
+				   cmh_completion_fn callback,
+				   void *callback_data,
+				   struct cmh_req_dma *rdma,
+				   bool backlog_ok,
+				   unsigned long timeout_jiffies);
+
+/* debugfs timeout accessors (debug builds only) */
+#ifdef CONFIG_CRYPTO_DEV_CMH_DEBUG
+unsigned int *cmh_tm_timeout_async_ptr(void);
+unsigned int *cmh_tm_timeout_vcq_ptr(void);
+unsigned int *cmh_tm_timeout_slow_op_ptr(void);
+unsigned int *cmh_tm_timeout_drain_ptr(void);
+unsigned int *cmh_tm_cmq_max_depth_ptr(void);
+#endif
+
+/* -- Crypto request completion helper ---------------------------------- */
+
+struct device *cmh_dev(void);
+
+/**
+ * cmh_complete() - Complete a crypto request with optional error logging
+ * @req: The async crypto request to complete
+ * @err: Completion code: 0 = success, < 0 = errno, -EINPROGRESS = backlog
+ *	 promotion signal, > 0 = byte count (ahash BLOCK_ONLY leftover the
+ *	 crypto API must re-buffer)
+ *
+ * Logs a rate-limited diagnostic on genuine errors (err < 0), then hands
+ * the request back to the crypto framework.  -EINPROGRESS and non-negative
+ * completions (success, or a positive ahash remainder) are not errors and
+ * are not logged.  Centralizes error reporting so individual algorithm
+ * drivers do not need per-callback logging.
+ */
+static inline void cmh_complete(struct crypto_async_request *req, int err)
+{
+	if (err < 0 && err != -EINPROGRESS) {
+		/*
+		 * For template instances (e.g. hmac(sha3-512-cmh)) the
+		 * driver name will be the outer template's, not ours.
+		 * Still useful for triage -- identifies the failing tfm.
+		 */
+		dev_dbg_ratelimited(cmh_dev(), "op error: alg=%s err=%d\n",
+				    crypto_tfm_alg_driver_name(req->tfm),
+				    err);
+	}
+	crypto_request_complete(req, err);
+}
+
+#endif /* CMH_TXN_H */
diff --git a/drivers/crypto/cmh/include/cmh_vcq.h b/drivers/crypto/cmh/include/cmh_vcq.h
new file mode 100644
index 000000000000..c00fa2fdff92
--- /dev/null
+++ b/drivers/crypto/cmh/include/cmh_vcq.h
@@ -0,0 +1,201 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (c) 2026 Cryptography Research, Inc. (CRI).
+ * CMH LKM -- VCQ (Virtual Command Queue) Definitions
+ *
+ * Kernel-side definitions for the CMH VCQ and DMA scatter-gather ABI,
+ * so the LKM can build VCQs without depending on CMH eSW headers.
+ *
+ * All constants and layouts are derived from the CMH eSW ABI.
+ *
+ * This ABI is little-endian only: the VCQ command and descriptor fields
+ * use native integer types and the CMH block shares the little-endian SoC
+ * with its eSW.  The driver depends on !CPU_BIG_ENDIAN (see the CMH
+ * Kconfig).
+ *
+ * Per-core command definitions live in their own ABI headers
+ * (cmh_<core>_abi.h) and are included here to form the hwc_cmd union.
+ */
+
+#ifndef CMH_VCQ_H
+#define CMH_VCQ_H
+
+#include <linux/types.h>
+#include <linux/build_bug.h>
+#include <linux/string.h>
+#include <linux/bits.h>
+
+#include "cmh_sys_abi.h"
+
+/* VCQ Magic Numbers */
+
+#define VCQ_HDR_MAGIC           0x01514356U  /* 'V' 'C' 'Q' 0x01 */
+#define VCQ_CMD_MAGIC           0x01444D43U  /* 'C' 'M' 'D' 0x01 */
+
+/* VCQ Command ID Encoding */
+
+#define VCQ_CMD_MASK            0x000000FFU
+#define VCQ_SPAN_MASK           0x0000FF00U
+#define VCQ_FLAG_MASK           0x00FF0000U
+#define VCQ_CORE_MASK           0xFF000000U
+
+#define VCQ_CMD_ID(core, flags, span, cmd) \
+	(((u32)(core) << 24) | ((flags) & VCQ_FLAG_MASK) | \
+	 (((u32)(span) << 8) & VCQ_SPAN_MASK) | ((cmd) & VCQ_CMD_MASK))
+
+/* Core IDs (per CMH hardware specification) */
+
+#define CORE_ID_SYS             0x00U
+#define CORE_ID_DMA             0x01U
+#define CORE_ID_HC              0x02U
+#define CORE_ID_AES             0x03U
+#define CORE_ID_SM4             0x04U
+#define CORE_ID_SM3             0x05U
+#define CORE_ID_XC              0x07U
+#define CORE_ID_HCQ             0x08U
+#define CORE_ID_QSE             0x09U
+#define CORE_ID_PKE             0x0AU
+#define CORE_ID_TIC             0x0BU
+#define CORE_ID_KIC             0x0CU
+#define CORE_ID_MPU             0x0EU
+#define CORE_ID_DRBG            0x0FU
+#define CORE_ID_EMC             0x11U
+#define CORE_ID_CCP             0x18U
+#define CORE_ID_EAC             0x1EU
+#define CORE_ID_NUM             0x1FU  /* eSW g_drvs[] array size sentinel */
+#define CORE_ID_MAX             0xFFU  /* VCQ encoding limit (8-bit field) */
+
+/**
+ * enum cmh_core_type - Logical core type for multi-instance dispatch
+ * @CMH_CORE_HC:         Hash / HMAC / CSHAKE / KMAC (CORE_ID_HC)
+ * @CMH_CORE_AES:        AES (CORE_ID_AES)
+ * @CMH_CORE_SM4:        SM4 (CORE_ID_SM4)
+ * @CMH_CORE_SM3:        SM3 (CORE_ID_SM3)
+ * @CMH_CORE_CCP:        ChaCha20 / Poly1305 (CORE_ID_CCP)
+ * @CMH_CORE_PKE:        RSA / ECDSA / ECDH / EdDSA / SM2 (CORE_ID_PKE)
+ * @CMH_CORE_QSE:        ML-KEM / ML-DSA (CORE_ID_QSE)
+ * @CMH_CORE_HCQ:        SLH-DSA / LMS / XMSS (CORE_ID_HCQ)
+ * @CMH_NUM_CORE_TYPES:  Number of core types (array sizing sentinel)
+ *
+ * Algorithm drivers use this enum (not raw CORE_ID_* constants) for
+ * MBX selection and VCQ dispatch.  Each value indexes into a config
+ * table that maps to one or more (core_id, mbx) pairs.
+ *
+ * Raw CORE_ID_* defines remain for:
+ *   - SYS_TYPE_SET() key-type tags in datastore operations
+ *   - DT child node ``reg`` values (hardware core identity for config lookup)
+ *   - Singleton system cores (SYS, KIC, DRBG, EAC) not in this enum
+ */
+enum cmh_core_type {
+	CMH_CORE_HC = 0,
+	CMH_CORE_AES,
+	CMH_CORE_SM4,
+	CMH_CORE_SM3,
+	CMH_CORE_CCP,
+	CMH_CORE_PKE,
+	CMH_CORE_QSE,
+	CMH_CORE_HCQ,
+	CMH_NUM_CORE_TYPES
+};
+
+/**
+ * struct core_dispatch - VCQ dispatch target returned by core selection
+ * @core_id: Hardware core ID to encode in VCQ_CMD_ID()
+ * @mbx_idx: Mailbox index to submit the VCQ to
+ */
+struct core_dispatch {
+	u32 core_id;
+	s32 mbx_idx;
+};
+
+/* Common VCQ Command (per CMH VCQ ABI) */
+
+#define VCQ_CMD_FLUSH           0xFFU
+
+/**
+ * struct vcq_hdr - VCQ header occupying the first slot of every VCQ
+ * @cmds: Total number of commands including the header itself
+ * @rsvd: Reserved -- used internally by CMH eSW firmware
+ */
+struct vcq_hdr {
+	u32 cmds;
+	u32 rsvd[13];
+};
+
+/* DMA Scatter-Gather Item (per CMH DMAC hardware specification) */
+
+/**
+ * struct dma_scattergather_item - DMA scatter-gather descriptor node
+ * @lli: Next descriptor address (0 = end of list)
+ * @src: Source address for input particle
+ * @dst: Destination address for output particle
+ * @len: Particle length (low 32 bits used by hardware)
+ *
+ * Linked-list node walked by the DMAC hardware.  @lli chains to the
+ * next item or is zero for end-of-list.
+ */
+struct dma_scattergather_item {
+	u64 lli;
+	u64 src;
+	u64 dst;
+	u64 len;
+};
+
+/* Unified HWC Command Union */
+/*
+ * Each per-core ABI header defines a union <core>_cmd.
+ * Add new cores here as they are implemented.
+ */
+
+union hwc_cmd {
+	struct vcq_hdr          hdr;
+	union sys_cmd           sys;
+};
+
+/**
+ * struct vcq_cmd - Single VCQ command entry (always 64 bytes)
+ * @magic: VCQ_HDR_MAGIC for the header slot, VCQ_CMD_MAGIC for commands
+ * @id:    Encoded command ID built via VCQ_CMD_ID(core, flags, span, cmd)
+ * @hwc:   Per-core command payload union
+ */
+struct vcq_cmd {
+	u32 magic;
+	u32 id;
+	union hwc_cmd hwc;
+};
+
+static_assert(sizeof(struct vcq_cmd) == 64,
+	      "struct vcq_cmd must be exactly 64 bytes (one VCQ slot)");
+
+/**
+ * vcq_set_header() - Write the standard VCQ header at slot[0]
+ * @slot:       Pointer to the first VCQ slot
+ * @total_cmds: Total number of commands including the header
+ */
+static inline void vcq_set_header(struct vcq_cmd *slot, u32 total_cmds)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_HDR_MAGIC;
+	slot->id = VCQ_CMD_ID(CORE_ID_SYS, 0, 1, SYS_CMD_RUN);
+	slot->hwc.hdr.cmds = total_cmds;
+}
+
+/* VCQ Command Limits */
+
+#define MIN_VCQ_CMDS            2U   /* header + at least one command */
+#define MAX_VCQ_CMDS            15U  /* including the header */
+#define MAX_VCQ_SIZE            (MAX_VCQ_CMDS * sizeof(struct vcq_cmd))
+
+/**
+ * vcq_add_flush() - Build a generic VCQ_CMD_FLUSH command
+ * @slot:    Pointer to the VCQ slot to populate
+ * @core_id: Hardware core ID for the flush command
+ */
+static inline void vcq_add_flush(struct vcq_cmd *slot, u32 core_id)
+{
+	memset(slot, 0, sizeof(*slot));
+	slot->magic = VCQ_CMD_MAGIC;
+	slot->id = VCQ_CMD_ID(core_id, 0, 1, VCQ_CMD_FLUSH);
+}
+
+#endif /* CMH_VCQ_H */

-- 
2.43.7

