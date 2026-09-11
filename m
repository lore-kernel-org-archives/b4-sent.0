From: Jaemyung Lee <jaemyung.lee@samsung.com>
Date: Sat, 12 Sep 2026 00:52:55 +0900
Subject: [PATCH RFC] drivers/rufs: add Rust UFS host controller driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260912-rufs-private-v1-1-716db733e655@samsung.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDSwNL3aLStGLdgqLMssSSVF0Lc/MUc0NTkzSjJAsloJaCotS0zAqwcdF
 KQW7OSrG1tQCWQY7nYwAAAA==
X-Change-ID: 20260909-rufs-private-877d7154f2b8
To: Andreas Hindborg <a.hindborg@kernel.org>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>, Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 linux-block@vger.kernel.org, linux-scsi@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Jaemyung Lee <jaemyung.lee@samsung.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789141986; l=330077;
 i=jaemyung.lee@samsung.com; s=rufs-rfc; h=from:subject:message-id;
 bh=iRsBVmBGomUqx54zx0l26Z+LJsiBWtqqYCSvD0bh42E=;
 b=MFqg9UaFf7h3BaQA7JYI1cKOlGPVRXnpwRcqf5WxuM4dvkkxIYole+bpenzUHpObEkxp5sjaR
 vDcActTe0QEANLMKW+ISaTMsZfKXSlnSYze+NKZLpjEpprDUPKwIMu8
X-Developer-Key: i=jaemyung.lee@samsung.com; a=ed25519;
 pk=FxhB9SmYqZy9ICgX/S/g2aHSPo2T2rxeW8GWmmbcPgc=
X-Endpoint-Received: by B4 Relay for jaemyung.lee@samsung.com/rufs-rfc with auth_id=1025
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a Rust UFS host controller driver that exposes UFS logical units as
native blk-mq block devices without depending on the SCSI midlayer.

Implement host controller setup, UIC link startup and power-mode
configuration, device and unit descriptor discovery, query operations, and
SCSI protocol command construction. Support normal read, write, flush, and
discard I/O with coherent UTP descriptors and owned streaming DMA mappings.

Provide both single-doorbell and multi-circular-queue transfer backends.
Map shared blk-mq tags directly to UFS task tags, retain request ownership
while commands are in flight, dispatch completion per MCQ completion queue,
and return polled completions through the blk-mq completion batch.

Add PCI and Qualcomm platform frontends. The PCI frontend supports the QEMU
UFS controller and existing Intel and Samsung IDs. The Qualcomm frontend
provides the clocks, PHY, reset, interconnect, power-domain, OPP, GPIO, and
controller-specific initialization needed by supported SoCs.

This establishes normal-I/O support for UFSHCI single-doorbell and MCQ
controllers. Full timeout recovery, error handling, and power management
are left for follow-up work.

Signed-off-by: Jaemyung Lee <jaemyung.lee@samsung.com>
---
This RFC introduces RUFS, a UFS host controller driver that sits directly
on the block layer and does not use the SCSI midlayer. UFS logical units
are exposed as native blk-mq block devices, the same way NVMe namespaces
are. The driver is written in Rust.

Why decouple UFS from SCSI
--------------------------

The existing UFS driver is built on the SCSI subsystem. That made sense
historically: UFS adopted the SCSI Architecture Model as its application
layer, so reusing the SCSI midlayer's command queuing, error handling,
power management, and logical-unit addressing let UFS reach Linux quickly
and reliably. ufshcd bridges the SCSI midlayer to UFS Protocol Information
Units.

That foundation has become a source of friction. The evolution of UFS is
governed by JEDEC and increasingly includes UFS-specific features outside
the SCSI command set standardized by T10. These features must still be
expressed through, and constrained by, a SCSI-shaped driver. Features that
are meaningful only to UFS are difficult to land in a subsystem whose
maintainers reasonably want to keep SCSI focused on SCSI, and block layer
or shared infrastructure changes that UFS needs end up mediated through
SCSI's priorities. In practice UFS is treated as an add-on to SCSI rather
than as a first-class storage interface, and a significant amount of UFS
functionality lives off-tree as a result, with the back- and forward-
porting cost that implies.

We propose to decouple UFS from SCSI with a standalone driver that sits
directly on the block layer, alongside drivers like NVMe. This lets
JEDEC-specific features evolve independently of T10, gives UFS
its own dedicated review surface, and removes the impedance mismatch
between the UFS data model and the SCSI command model. UFS uses a subset of
the SCSI command set within command UPIUs, so the driver can construct the
required CDBs directly without depending on the SCSI midlayer.

The driver is designed around the UFS and UFSHCI specifications rather than
as a line-by-line translation of ufshcd. Its target is JEDEC UFS 4.1 and
UFSHCI 4.1.

Why Rust
--------

The architectural question above would be the same for a C driver. We chose
Rust because UFS features arrive at a high pace, and turning new
specification features into stable, validated code on tight timelines is
where memory- and concurrency-safety guarantees pay off: fewer classes of
bugs reach production, and iteration is faster. Rust's growing acceptance
in the kernel makes a block-layer-native UFS driver a realistic
architecture to evaluate.

Initial feature set
--------------------

The new driver supports single-doorbell and multi-circular-queue operation,
PCI and Qualcomm platform frontends, logical-unit discovery, and normal
read, write, flush, and discard I/O. It uses shared blk-mq tags as UFS task
tags, keeps request ownership through completion, and uses owned DMA
mappings for the complete I/O lifetime.

Full timeout recovery, error handling, and power management remain
follow-up work.

Patch layout and dependencies
-----------------------------

The single patch contains the complete driver. This keeps review focused on
the RUFS architecture and the SCSI-independent blk-mq model.

The driver depends on Rust block, DMA, IRQ, and platform abstractions that
are intentionally excluded from this posting. Some of these abstractions
have already been posted to the list, most notably in the Rust null block
driver v2 series, the Ownable/OwnableRefCounted page series, and the
impl_flags extensions. The remaining abstractions are new and will be
posted as separate series before the first non-RFC version of this driver.

A buildable tree based on v7.3-rc2 with all dependencies and this patch is
at:

https://github.com/SamsungDS/rufs/tree/rfc/rufs-public

Testing
-------

The v7.2 development version has been exercised with SDB and MCQ on the
QEMU UFS model, including ext4 fio workloads and module load/unload cycles.
SDB probe and normal I/O have also been exercised on Intel PCI and Qualcomm
UFS hardware. The current port has been compile-tested independently with
PCI-only and Qualcomm-platform-only configurations.

The exact v7.2 tree used for the hardware measurements is available at:

https://github.com/SamsungDS/rufs/tree/rufs-7.2

On Intel UFS 2.1 hardware, 4 KiB direct io_uring at QD32/job gave
these optimized-mode ranges over 1/2/4 jobs (three samples):

  Workload  Op     RUFS kIOPS   C kIOPS      Difference
  --------  -----  -----------  -----------  ---------------
  randread  read   48.91-61.26  41.56-41.60  +17.6% to +47.4%
  randwrite write  8.19-8.30    8.21-8.22    -0.4% to +1.1%
  randrw    read   5.26-5.34    5.28-5.38    -0.9% to -0.4%
  randrw    write  5.27-5.34    5.29-5.37    -0.8% to -0.5%

The coefficient of variation (CV), calculated as the sample standard
deviation divided by the sample mean, measures run-to-run variability
relative to the mean. CV is a descriptive statistic; no normal or other
distribution was fitted to model the variation. The accompanying
two-sided 95% confidence intervals for the mean used Student's
t-distribution because each point contains only three samples. Those
intervals assume independent, approximately normally distributed sample
means and should be interpreted cautiously at this sample count.

RUFS randread had a CV of 28-57%, versus below 0.8% for C. Its apparent
gain therefore has low confidence and should be treated as preliminary.
Both drivers also logged platform UIC errors. Stable write and mixed
points differed by no more than 1.1%.

Feedback
--------

Comments on the decision to bypass the SCSI midlayer, the blk-mq model used
in its place, and the proposed prerequisite API boundaries would be
especially welcome.
---
 MAINTAINERS                    |   10 +
 drivers/Kconfig                |    2 +
 drivers/Makefile               |    1 +
 drivers/rufs/Kconfig           |   41 ++
 drivers/rufs/Makefile          |    5 +
 drivers/rufs/command.rs        |   28 +
 drivers/rufs/device.rs         |  283 ++++++++
 drivers/rufs/dma.rs            |  275 ++++++++
 drivers/rufs/dma/prdt.rs       |  211 ++++++
 drivers/rufs/frontend.rs       |    8 +
 drivers/rufs/frontend/pci.rs   |  170 +++++
 drivers/rufs/frontend/qcom.rs  |  718 +++++++++++++++++++
 drivers/rufs/hci.rs            |    5 +
 drivers/rufs/hci/descriptor.rs |  276 ++++++++
 drivers/rufs/host.rs           |  340 +++++++++
 drivers/rufs/irq.rs            |  402 +++++++++++
 drivers/rufs/lu.rs             |  564 +++++++++++++++
 drivers/rufs/protocol.rs       |   28 +
 drivers/rufs/protocol/query.rs |  645 +++++++++++++++++
 drivers/rufs/protocol/scsi.rs  |  280 ++++++++
 drivers/rufs/protocol/upiu.rs  |  873 +++++++++++++++++++++++
 drivers/rufs/queue.rs          | 1516 ++++++++++++++++++++++++++++++++++++++++
 drivers/rufs/reg.rs            | 1445 ++++++++++++++++++++++++++++++++++++++
 drivers/rufs/resource.rs       |  136 ++++
 drivers/rufs/transport.rs      |  354 ++++++++++
 drivers/rufs/transport/mcq.rs  |  655 +++++++++++++++++
 drivers/rufs/transport/sdb.rs  |  162 +++++
 drivers/rufs/ufs.rs            |   63 ++
 drivers/rufs/uic.rs            |  440 ++++++++++++
 drivers/rufs/variant.rs        |   69 ++
 30 files changed, 10005 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 6215fcb077705..463da88fbd9cb 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -24036,6 +24036,16 @@ T:	git git://git.kernel.org/pub/scm/linux/kernel/git/boqun/linux.git rust-sync
 F:	rust/kernel/sync.rs
 F:	rust/kernel/sync/
 
+RUST UFS HOST CONTROLLER DRIVER
+M:	Jaemyung Lee <jaemyung.lee@samsung.com>
+M:	Andreas Hindborg <a.hindborg@kernel.org>
+L:	rust-for-linux@vger.kernel.org
+L:	linux-block@vger.kernel.org
+L:	linux-scsi@vger.kernel.org
+S:	Maintained
+T:	git https://github.com/SamsungDS/RUFS.git rfc/rufs-public
+F:	drivers/rufs/
+
 RXRPC SOCKETS (AF_RXRPC)
 M:	David Howells <dhowells@redhat.com>
 M:	Marc Dionne <marc.dionne@auristor.com>
diff --git a/drivers/Kconfig b/drivers/Kconfig
index f2bed2ddeb662..9baa3ad0ee054 100644
--- a/drivers/Kconfig
+++ b/drivers/Kconfig
@@ -121,6 +121,8 @@ source "drivers/mmc/Kconfig"
 
 source "drivers/ufs/Kconfig"
 
+source "drivers/rufs/Kconfig"
+
 source "drivers/memstick/Kconfig"
 
 source "drivers/leds/Kconfig"
diff --git a/drivers/Makefile b/drivers/Makefile
index 0841ea851847e..01f0f02ba7627 100644
--- a/drivers/Makefile
+++ b/drivers/Makefile
@@ -131,6 +131,7 @@ obj-$(CONFIG_CPU_FREQ)		+= cpufreq/
 obj-$(CONFIG_CPU_IDLE)		+= cpuidle/
 obj-y				+= mmc/
 obj-y				+= ufs/
+obj-y				+= rufs/
 obj-$(CONFIG_MEMSTICK)		+= memstick/
 obj-$(CONFIG_INFINIBAND)	+= infiniband/
 obj-y				+= firmware/
diff --git a/drivers/rufs/Kconfig b/drivers/rufs/Kconfig
new file mode 100644
index 0000000000000..caa00cbe934ac
--- /dev/null
+++ b/drivers/rufs/Kconfig
@@ -0,0 +1,41 @@
+# SPDX-License-Identifier: GPL-2.0-only
+
+menuconfig RUFS
+	tristate "Rust UFS host controller driver"
+	depends on RUST
+	help
+	  Enable the experimental Rust UFS host controller driver. RUFS exposes
+	  UFS logical units as native blk-mq block devices without depending on
+	  the SCSI midlayer. The driver supports UFSHCI single-doorbell and
+	  multi-circular-queue controllers.
+
+if RUFS
+
+config RUFS_PCI
+	bool "PCI bus frontend"
+	depends on PCI
+	default y if PCI
+	help
+	  Build the PCI frontend for RUFS. This supports the QEMU UFS controller
+	  and PCI-attached UFS controllers using the IDs listed by the driver.
+	  Select this option when RUFS should probe UFS host controllers exposed
+	  through the PCI bus.
+
+config RUFS_QCOM
+	bool "Qualcomm platform frontend"
+	depends on OF
+	depends on COMMON_CLK
+	depends on GENERIC_PHY
+	depends on GPIOLIB
+	depends on INTERCONNECT
+	depends on PM_OPP
+	depends on RESET_CONTROLLER
+	depends on ARCH_QCOM || COMPILE_TEST
+	help
+	  Build the Qualcomm platform frontend. The frontend maps the UFSHCI
+	  resource and configures the clocks, PHY, reset and interconnect paths
+	  needed by supported Qualcomm UFS controllers. Select this option when
+	  RUFS should probe UFS host controllers described by Qualcomm device
+	  tree bindings.
+
+endif
diff --git a/drivers/rufs/Makefile b/drivers/rufs/Makefile
new file mode 100644
index 0000000000000..d73eb830d677c
--- /dev/null
+++ b/drivers/rufs/Makefile
@@ -0,0 +1,5 @@
+# SPDX-License-Identifier: GPL-2.0-only
+
+obj-$(CONFIG_RUFS) += rufs.o
+
+rufs-y := ufs.o
diff --git a/drivers/rufs/command.rs b/drivers/rufs/command.rs
new file mode 100644
index 0000000000000..ad9a3fc780d6e
--- /dev/null
+++ b/drivers/rufs/command.rs
@@ -0,0 +1,28 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! UFS command tag representation.
+
+use kernel::prelude::*;
+
+pub(crate) const TASK_TAG_COUNT: usize = 1usize << u8::BITS;
+
+#[derive(Clone, Copy, Debug, Eq, PartialEq)]
+pub(crate) struct TaskTag(u8);
+
+impl TaskTag {
+    pub(crate) const fn from_value(tag: u8) -> Self {
+        Self(tag)
+    }
+
+    pub(crate) fn new(tag: u32) -> Result<Self> {
+        Ok(Self(u8::try_from(tag).map_err(|_| EINVAL)?))
+    }
+
+    pub(crate) fn value(self) -> u8 {
+        self.0
+    }
+
+    pub(crate) fn index(self) -> usize {
+        usize::from(self.0)
+    }
+}
diff --git a/drivers/rufs/device.rs b/drivers/rufs/device.rs
new file mode 100644
index 0000000000000..e985e65cac48b
--- /dev/null
+++ b/drivers/rufs/device.rs
@@ -0,0 +1,283 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#![allow(dead_code)]
+#![allow(unused_imports)]
+#![allow(unused_variables)]
+
+use crate::dma::MAX_PRD_ENTRIES;
+use crate::lu::{QueueData, UfsLuBlockOps};
+use crate::protocol::query::*;
+use crate::protocol::UfsCmd;
+use crate::queue::*;
+use kernel::alloc::mempool::MemPool;
+use kernel::block::error::BlkResult;
+use kernel::block::mq::dma_map_iter::DmaMapMempool;
+use kernel::block::mq::{
+    self, BoundRequestQueue, IdleRequest, LimitsBuilder, Request, RequestQueue,
+};
+use kernel::error::{from_err_ptr, to_result};
+use kernel::io::poll::read_poll_timeout;
+use kernel::sync::{aref::ARef, Arc, Mutex};
+use kernel::time::{delay, Delta};
+use kernel::types::Owned;
+use kernel::uapi::NUMA_NO_NODE;
+use kernel::{bindings, kvec, new_mutex, prelude::*};
+
+const FDEVICE_COMPL_TIMEOUT_MS: i64 = 1500;
+const FDEVICE_COMPL_TICK_US: i64 = 500;
+
+struct TaskManagementOps {}
+
+#[vtable]
+impl mq::Operations for TaskManagementOps {
+    const MODULE: &'static kernel::ThisModule = crate::RUFS_MODULE;
+
+    type RequestData = ();
+    type QueueData = ();
+    type HwData = ();
+    type TagSetData = ();
+    type GenDiskData = ();
+
+    fn new_request_data() -> impl PinInit<Self::RequestData> {}
+
+    fn queue_rq(
+        hw_data: (),
+        queue_data: (),
+        rq: Owned<IdleRequest<Self>>,
+        is_last: bool,
+    ) -> BlkResult {
+        todo!()
+    }
+
+    fn commit_rqs(hw_data: (), queue_data: ()) {
+        todo!()
+    }
+
+    fn init_hctx(tagset_data: (), hctx_idx: u32) -> Result<Self::HwData> {
+        Ok(())
+    }
+
+    fn complete(rq: ARef<Request<Self>>) {
+        todo!()
+    }
+}
+
+// This queue is scaffolding for future task-management/error-recovery support.
+// RUFS does not issue TMF requests yet; `queue_tmf()` is only a guard callback
+// so accidental dispatch is rejected instead of silently completing.
+struct TmfQueue {
+    tag_set: Arc<mq::TagSet<TaskManagementOps>>,
+    queue: BoundRequestQueue<TaskManagementOps>,
+}
+
+impl TmfQueue {
+    fn new(depth: usize) -> Result<Self> {
+        let tag_set = Arc::pin_init(
+            mq::TagSet::new(
+                1,
+                (),
+                depth.try_into()?,
+                1,
+                kernel::alloc::NumaNode::NO_NODE,
+                mq::tag_set::Flags::empty(),
+            ),
+            GFP_KERNEL,
+        )?;
+
+        let queue = mq::RequestQueue::new(
+            tag_set.clone(),
+            LimitsBuilder::<TaskManagementOps>::new().build()?,
+            (),
+            depth as u32,
+        )?;
+
+        Ok(Self { tag_set, queue })
+    }
+}
+
+#[derive(Default)]
+pub(crate) struct UfsDevInfo {
+    max_lu: usize,
+    num_lu: usize,
+    num_wlu: usize,
+    manufacturer_id: u16,
+    spec_version: u16,
+    queue_depth: usize,
+    rtt_cap: u8,
+    luns_avail: usize,
+}
+
+#[pin_data]
+pub(crate) struct UfsDev {
+    ufs_queue: Arc<UfsQueue>,
+    pub(crate) request_queue: BoundRequestQueue<UfsLuBlockOps>,
+
+    #[pin]
+    pub(crate) info: Mutex<UfsDevInfo>,
+
+    #[pin]
+    tmf_queue: Mutex<Option<TmfQueue>>,
+}
+
+impl UfsDev {
+    pub(crate) fn new(ufs_queue: Arc<UfsQueue>) -> Result<Arc<Self>> {
+        let limits = LimitsBuilder::<UfsLuBlockOps>::new().build()?;
+
+        let request_queue = RequestQueue::new(
+            ufs_queue.tags.clone(),
+            limits,
+            KBox::new(QueueData::dev(ufs_queue.clone()), GFP_KERNEL)?,
+            ufs_queue.tags.queue_depth(),
+        )?;
+
+        let this = Arc::pin_init(
+            try_pin_init!(Self {
+                ufs_queue,
+                request_queue,
+                info <- new_mutex!(UfsDevInfo::default()),
+                tmf_queue <- new_mutex!(None),
+            }),
+            GFP_KERNEL,
+        )?;
+
+        Ok(this)
+    }
+
+    // Allocate the placeholder TMF blk-mq objects early so the ownership and
+    // cleanup path are exercised, but do not treat this as functional TMF
+    // support. Real TMF request composition/completion belongs with error
+    // recovery.
+    pub(crate) fn alloc_tmf_queue(&self, depth: usize) -> Result<()> {
+        let mut tmf_queue = self.tmf_queue.lock();
+        if tmf_queue.is_some() {
+            return Err(EBUSY);
+        }
+
+        tmf_queue.replace(TmfQueue::new(depth)?);
+        Ok(())
+    }
+
+    fn submit(&self, cmd: UfsCmd) -> Result<UfsCmd> {
+        let mut rq = self
+            .request_queue
+            .alloc_sync_request(mq::Command::DriverOut)?;
+        rq.data_ref().inner.lock().prepare_device(cmd)?;
+        rq.as_pin_mut().execute(true)?;
+        let result = rq.data_ref().inner.lock().take_device_completion();
+        result
+    }
+
+    fn nop(&self) -> Result<()> {
+        let cmd = self.submit(UfsDevCmd::nop())?;
+        Ok(())
+    }
+
+    pub(crate) fn verify_dev_init(&self) -> Result<()> {
+        self.nop()
+    }
+
+    fn read_desc(&self, idn: DescIdn, index: u8, selector: u8) -> Result<Desc> {
+        let cmd = self.submit(UfsDevCmd::query().read_desc(idn, index, selector))?;
+        Ok(cmd.get_device()?.get_query()?.get_read_desc()?.desc)
+    }
+
+    fn read_attr(&self, idn: AttrIdn, index: u8, selector: u8) -> Result<u64> {
+        let cmd = self.submit(UfsDevCmd::query().read_attr(idn, index, selector))?;
+        cmd.get_device()?.get_query()?.get_attr_value()
+    }
+
+    pub(crate) fn read_unit_desc(&self, lun: u8) -> Result<UnitDesc> {
+        self.read_desc(DescIdn::Unit, lun, 0)?.get_unit()
+    }
+
+    pub(crate) fn num_lu(&self) -> usize {
+        self.info.lock().num_lu
+    }
+
+    fn write_attr(&self, idn: AttrIdn, index: u8, selector: u8, value: u64) -> Result<()> {
+        let cmd = self.submit(UfsDevCmd::query().write_attr(idn, index, selector, value))?;
+        if cmd.get_device()?.get_query()?.get_attr_value()? == value {
+            Ok(())
+        } else {
+            Err(EIO)
+        }
+    }
+
+    fn read_flag(&self, idn: FlagIdn, index: u8, selector: u8) -> Result<u8> {
+        let cmd = self.submit(UfsDevCmd::query().read_flag(idn, index, selector))?;
+        cmd.get_device()?.get_query()?.get_flag_value()
+    }
+
+    fn set_flag(&self, idn: FlagIdn, index: u8, selector: u8) -> Result<()> {
+        self.submit(UfsDevCmd::query().set_flag(idn, index, selector))?;
+        Ok(())
+    }
+
+    fn clear_flag(&self, idn: FlagIdn, index: u8, selector: u8) -> Result<()> {
+        self.submit(UfsDevCmd::query().clear_flag(idn, index, selector))?;
+        Ok(())
+    }
+
+    fn toggle_flag(&self, idn: FlagIdn, index: u8, selector: u8) -> Result<u8> {
+        let cmd = self.submit(UfsDevCmd::query().toggle_flag(idn, index, selector))?;
+        cmd.get_device()?.get_query()?.get_flag_value()
+    }
+
+    pub(crate) fn complete_dev_init(&self) -> Result<()> {
+        self.set_flag(FlagIdn::FDeviceInit, 0, 0)?;
+
+        let result = read_poll_timeout(
+            || self.read_flag(FlagIdn::FDeviceInit, 0, 0),
+            |flag: &u8| *flag == 0,
+            Delta::from_micros(FDEVICE_COMPL_TICK_US),
+            Delta::from_millis(FDEVICE_COMPL_TIMEOUT_MS),
+        );
+        match result {
+            Ok(_) => Ok(()),
+            Err(ETIMEDOUT) => {
+                pr_err!("[RUFS] ufs_dev: fDeviceInit was not cleared\n");
+                Err(EBUSY)
+            }
+            Err(e) => {
+                pr_err!(
+                    "[RUFS] ufs_dev: failed to read fDeviceInit errno={}\n",
+                    e.to_errno(),
+                );
+                Err(e)
+            }
+        }
+    }
+
+    pub(crate) fn device_params_init(&self) -> Result<()> {
+        self.get_geometry_info()?;
+        self.get_device_info()?;
+        Ok(())
+    }
+
+    fn get_geometry_info(&self) -> Result<GeometryDesc> {
+        let desc = self.read_desc(DescIdn::Geometry, 0, 0)?.get_geometry()?;
+        match desc.max_number_lu() {
+            1 => {
+                self.info.lock().max_lu = 32;
+            }
+            _ => {
+                self.info.lock().max_lu = 8;
+            }
+        }
+
+        Ok(desc)
+    }
+
+    fn get_device_info(&self) -> Result<DeviceDesc> {
+        let desc = self.read_desc(DescIdn::Device, 0, 0)?.get_device()?;
+        self.info.lock().manufacturer_id = desc.manufacturer_id();
+        self.info.lock().spec_version = desc.spec_version();
+        self.info.lock().queue_depth = desc.queue_depth();
+        self.info.lock().rtt_cap = desc.device_rtt_cap();
+        self.info.lock().num_lu = desc.number_lu() as usize;
+        self.info.lock().num_wlu = desc.number_wlu() as usize;
+        self.info.lock().luns_avail = (desc.number_lu() + desc.number_wlu()) as usize;
+
+        Ok(desc)
+    }
+}
diff --git a/drivers/rufs/dma.rs b/drivers/rufs/dma.rs
new file mode 100644
index 0000000000000..8333317e2aea2
--- /dev/null
+++ b/drivers/rufs/dma.rs
@@ -0,0 +1,275 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#![allow(dead_code)]
+#![allow(unused_variables)]
+
+mod prdt;
+
+use crate::lu::UfsLuBlockOps;
+use crate::protocol::query::*;
+use crate::protocol::scsi::*;
+use crate::protocol::upiu::Upiu;
+use crate::protocol::UfsCmd;
+use crate::reg::*;
+use kernel::block::mq::dma_map_iter::DmaMapMempool;
+use kernel::block::mq::dma_map_single::{DetachedStreaming, DetachedStreamingInFlight};
+use kernel::dma;
+use kernel::io::io_project;
+use kernel::io::Io;
+use kernel::sync::{aref::ARef, Arc};
+use kernel::types::Owned;
+use kernel::{
+    block::mq,
+    device::{self, Bound},
+    prelude::*,
+};
+
+pub(crate) use crate::hci::descriptor::{CqEntry, MAX_PRD_ENTRIES};
+use crate::hci::descriptor::{PrdEntry, Ucd, Utmrd, UtpOcs, Utrd};
+use prdt::UfsPrdt;
+pub(crate) use prdt::{UfsActiveMapping, UfsPreparedMapping, PRDT_DATA_BYTE_COUNT_MAX};
+
+pub(crate) struct UfsDma {
+    reg: Arc<UfsReg>,
+    dev: ARef<device::Device>,
+    transfer_slots: usize,
+    ucdl: dma::Coherent<[Ucd]>,
+    utrdl: dma::Coherent<[Utrd]>,
+    utmrdl: dma::Coherent<[Utmrd]>,
+}
+
+impl UfsDma {
+    pub(crate) fn dev(&self) -> &device::Device<Bound> {
+        // SAFETY: `UfsDma` is owned by the bound RUFS driver instance. MCQ queue
+        // allocations only use this reference while the driver owns the device.
+        unsafe { self.dev.as_bound() }
+    }
+
+    pub(crate) fn new(
+        dev: &device::Device<Bound>,
+        reg: Arc<UfsReg>,
+        transfer_slots: usize,
+    ) -> Result<Arc<Self>> {
+        if transfer_slots == 0 {
+            return Err(EINVAL);
+        }
+        let ucdl = dma::Coherent::<Ucd>::zeroed_slice_zerocopy(dev, transfer_slots, GFP_KERNEL)?;
+
+        let utrdl = dma::Coherent::<Utrd>::zeroed_slice_zerocopy(dev, transfer_slots, GFP_KERNEL)?;
+
+        for tag in 0..transfer_slots {
+            // The controller DMA-reads the UTP command descriptor for this tag,
+            // so this must be the descriptor's DMA (bus) address, not its CPU
+            // virtual address. `ucdl` is a contiguous slice, so element `tag`
+            // sits at `tag * size_of::<Ucd>()` bytes from the DMA base.
+            let command_desc_base_addr = io_project!(ucdl, [try: tag]).dma_address();
+
+            let utrd = io_project!(utrdl, [try: tag])
+                .copy_read()
+                .set_command_descriptor(command_desc_base_addr);
+            io_project!(
+                utrdl,
+                [try: tag]
+            )
+            .copy_write(utrd);
+        }
+
+        let nutmrs = reg.nutmrs();
+        let utmrdl = dma::Coherent::<Utmrd>::zeroed_slice_zerocopy(dev, nutmrs, GFP_KERNEL)?;
+
+        Ok(Arc::new(
+            Self {
+                reg,
+                dev: dev.into(),
+                transfer_slots,
+                ucdl,
+                utrdl,
+                utmrdl,
+            },
+            GFP_KERNEL,
+        )?)
+    }
+
+    pub(crate) fn transfer_slots(&self) -> usize {
+        self.transfer_slots
+    }
+
+    pub(crate) fn make_hba_operational(&self) -> Result<()> {
+        // Keep transfer interrupts disabled until the queue and its handler
+        // have both been installed by the host initialization path.
+        self.reg.disable_transfer_req_int_aggr();
+
+        self.reg.set_utrdl_base(self.utrdl.dma_address());
+        self.reg.set_utmrdl_base(self.utmrdl.dma_address());
+
+        self.reg.wait_for_request_ready(1000, 50)?;
+        self.reg.enable_run_stop();
+
+        Ok(())
+    }
+
+    pub(crate) fn compose_devman_upiu(&self, cmd: UfsDevCmd, tag: u32) -> Result<()> {
+        let tag = tag as usize;
+        io_project!(self.ucdl, [try: tag].cmd_upiu).copy_write(Upiu::device(cmd, tag));
+        io_project!(self.ucdl, [try: tag].rsp_upiu).copy_write(Upiu::default());
+
+        let utrd = io_project!(self.utrdl, [try: tag]).copy_read();
+        io_project!(self.utrdl, [try: tag]).copy_write(utrd.build(UfsCmd::Device(cmd)));
+        Ok(())
+    }
+
+    pub(crate) fn compose_scsi_upiu(
+        &self,
+        rq: &Owned<mq::Request<UfsLuBlockOps>>,
+        cmd: UfsSCSICmd,
+        task_tag: u8,
+        mempool: &DmaMapMempool<MAX_PRD_ENTRIES>,
+    ) -> Result<UfsPreparedMapping> {
+        let tag = usize::from(task_tag);
+        let mut write_entry = |index, entry| {
+            io_project!(self.ucdl, [try: tag].prdt[try: index]).copy_write(entry);
+            Ok(())
+        };
+        let prdt = if cmd.is_unmap() {
+            let mapping = self.prepare_unmap(cmd)?;
+            let dma_handle = mapping.dma_handle();
+            let dma_size = mapping.size() as u32;
+            let prdt = UfsPrdt::single(mapping);
+            let entry = PrdEntry::new(dma_handle, dma_size)?;
+            write_entry(0, entry)?;
+            prdt
+        } else {
+            UfsPrdt::map(&self.dev, cmd, rq, mempool, &mut write_entry)?
+        };
+
+        io_project!(self.ucdl, [try: tag].cmd_upiu).copy_write(Upiu::command(cmd, tag));
+        io_project!(self.ucdl, [try: tag].rsp_upiu).copy_write(Upiu::default());
+
+        let prd_entries = prdt.entry_count();
+        let utrd = io_project!(self.utrdl, [try: tag]).copy_read();
+        let utrd = utrd
+            .build(UfsCmd::Scsi(cmd))
+            .set_prd_table_length(prd_entries)?;
+        io_project!(self.utrdl, [try: tag]).copy_write(utrd);
+
+        Ok(prdt.into_mapping())
+    }
+
+    fn prepare_unmap(
+        &self,
+        cmd: UfsSCSICmd,
+    ) -> Result<DetachedStreamingInFlight<KBox<UfsUnmapParameterList>>> {
+        let params = UfsUnmapParameterList::new(cmd.unmap_lba(), cmd.unmap_blocks())?;
+        let buffer = KBox::new(params, GFP_ATOMIC).map_err(|_| EBUSY)?;
+
+        // SAFETY: RUFS drains or safely abandons every request mapping before
+        // its bound frontend instance is dropped. An in-flight mapping whose
+        // controller cannot be stopped leaks its storage and device reference.
+        let mapping =
+            unsafe { DetachedStreaming::new(&self.dev, buffer, dma::DataDirection::ToDevice) }
+                .map_err(map_single_dma_error)?;
+
+        Ok(mapping.submit())
+    }
+
+    pub(crate) fn transfer_request_desc(&self, tag: usize) -> Result<Utrd> {
+        Ok(io_project!(self.utrdl, [try: tag]).copy_read())
+    }
+
+    pub(crate) fn validate_cq_entry(&self, cqe: &CqEntry, queue_id: u32) -> Result<()> {
+        let tag = usize::from(cqe.task_tag());
+        if tag >= self.transfer_slots {
+            return Err(EINVAL);
+        }
+        if u32::from(cqe.submission_queue_id()) != queue_id {
+            return Err(EINVAL);
+        }
+
+        let expected = io_project!(self.ucdl, [try: tag]).dma_address();
+        if !cqe.matches_ucd_base_addr(expected) {
+            return Err(EIO);
+        }
+
+        Ok(())
+    }
+
+    pub(crate) fn fetch_devman_upiu(&self, cmd: UfsDevCmd, tag: usize) -> Result<UfsCmd> {
+        let utrd = io_project!(self.utrdl, [try: tag]).copy_read();
+        utrd.check_response()?;
+
+        let rsp_upiu = io_project!(self.ucdl, [try: tag].rsp_upiu).copy_read();
+        let cmd = rsp_upiu.fetch_dev(cmd)?;
+
+        Ok(UfsCmd::Device(cmd))
+    }
+
+    pub(crate) fn fetch_mcq_devman_upiu(
+        &self,
+        cmd: UfsDevCmd,
+        tag: usize,
+        cqe: CqEntry,
+    ) -> Result<UfsCmd> {
+        match cqe.overall_status().into() {
+            UtpOcs::Success => {}
+            UtpOcs::InvalidCmdTableAttr => return Err(EINVAL),
+            UtpOcs::InvalidPrdtAttr => return Err(EINVAL),
+            UtpOcs::MismatchDataBufSize => return Err(EINVAL),
+            UtpOcs::MisMatchRespUpiuSize => return Err(EINVAL),
+            UtpOcs::InvalidCryptoConfig => return Err(EINVAL),
+            UtpOcs::GeneralCryptoError => return Err(EINVAL),
+            _ => return Err(EIO),
+        }
+
+        let rsp_upiu = io_project!(self.ucdl, [try: tag].rsp_upiu).copy_read();
+        let cmd = rsp_upiu.fetch_dev(cmd)?;
+
+        Ok(UfsCmd::Device(cmd))
+    }
+
+    pub(crate) fn fetch_scsi_completion(&self, tag: usize) -> UfsScsiResult {
+        let utrd = match (|| -> Result<_> { Ok(io_project!(self.utrdl, [try: tag]).copy_read()) })()
+        {
+            Ok(utrd) => utrd,
+            Err(_) => return UfsScsiResult::error(UtpOcs::InvalidCommandStatus as u8),
+        };
+        let ocs = utrd.ocs();
+
+        if utrd.check_response().is_err() {
+            return match utrd.ocs().into() {
+                UtpOcs::Aborted | UtpOcs::InvalidCommandStatus => UfsScsiResult::requeue(ocs),
+                _ => UfsScsiResult::error(ocs),
+            };
+        }
+
+        match (|| -> Result<_> { Ok(io_project!(self.ucdl, [try: tag].rsp_upiu).copy_read()) })() {
+            Ok(rsp_upiu) => rsp_upiu.scsi_result(ocs),
+            Err(_) => UfsScsiResult::error(ocs),
+        }
+    }
+
+    pub(crate) fn fetch_mcq_scsi_completion(&self, tag: usize, cqe: CqEntry) -> UfsScsiResult {
+        let ocs = cqe.overall_status();
+
+        if !matches!(ocs.into(), UtpOcs::Success) {
+            return match ocs.into() {
+                UtpOcs::Aborted | UtpOcs::InvalidCommandStatus => UfsScsiResult::requeue(ocs),
+                _ => UfsScsiResult::error(ocs),
+            };
+        }
+
+        match (|| -> Result<_> { Ok(io_project!(self.ucdl, [try: tag].rsp_upiu).copy_read()) })() {
+            Ok(rsp_upiu) => rsp_upiu.scsi_result(ocs),
+            Err(_) => UfsScsiResult::error(UtpOcs::InvalidCommandStatus as u8),
+        }
+    }
+}
+
+fn map_single_dma_error(error: Error) -> Error {
+    if error == EIO {
+        // Match the block DMA iterator: a DMA API mapping failure is a
+        // transient resource shortage and should be retried by blk-mq.
+        EBUSY
+    } else {
+        error
+    }
+}
diff --git a/drivers/rufs/dma/prdt.rs b/drivers/rufs/dma/prdt.rs
new file mode 100644
index 0000000000000..d7aca2781249c
--- /dev/null
+++ b/drivers/rufs/dma/prdt.rs
@@ -0,0 +1,211 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! UFS physical region descriptor table mapping.
+
+use core::mem::ManuallyDrop;
+
+use crate::hci::descriptor::{PrdEntry, MAX_PRD_ENTRIES};
+use crate::lu::UfsLuBlockOps;
+use crate::protocol::scsi::{UfsSCSICmd, UfsUnmapParameterList};
+use kernel::bindings;
+use kernel::block::error::BlkError;
+use kernel::block::mq::dma_map_iter::{DmaMapIterMapped, DmaMapMempool};
+use kernel::block::mq::dma_map_single::DetachedStreamingInFlight;
+use kernel::sync::aref::ARef;
+use kernel::types::Owned;
+use kernel::{block::mq, device, prelude::*};
+
+pub(crate) const PRDT_DATA_BYTE_COUNT_MAX: u32 = 0x00040000;
+
+const PRDT_DATA_BYTE_COUNT_PAD: usize = 4;
+pub(crate) enum UfsPreparedMapping {
+    None,
+    Sg(DmaMapIterMapped<MAX_PRD_ENTRIES>),
+    Single(Option<DetachedStreamingInFlight<KBox<UfsUnmapParameterList>>>),
+}
+
+impl UfsPreparedMapping {
+    /// Marks the descriptor containing this mapping visible to hardware.
+    pub(crate) fn publish(self) -> UfsActiveMapping {
+        UfsActiveMapping {
+            mapping: ManuallyDrop::new(self),
+        }
+    }
+
+    /// Reclaims a single-buffer mapping after device access has ended.
+    ///
+    /// # Safety
+    ///
+    /// The mapping must not have been published or the device must have
+    /// finished accessing it.
+    unsafe fn reclaim_single(&mut self) {
+        if let Self::Single(mapping) = self {
+            if let Some(mapping) = mapping.take() {
+                // SAFETY: Forwarded from this function's safety requirements.
+                let mapping = unsafe { mapping.complete() };
+                drop(mapping);
+            }
+        }
+    }
+}
+
+impl Drop for UfsPreparedMapping {
+    fn drop(&mut self) {
+        // SAFETY: A mapping that remains in this prepared type has never
+        // crossed the hardware publication boundary.
+        unsafe { self.reclaim_single() };
+    }
+}
+
+/// A data mapping owned by a command that may be visible to hardware.
+pub(crate) struct UfsActiveMapping {
+    mapping: ManuallyDrop<UfsPreparedMapping>,
+}
+
+impl UfsActiveMapping {
+    /// Reclaims a mapping after hardware can no longer access it.
+    ///
+    /// # Safety
+    ///
+    /// The device must have completed the command or the controller must have
+    /// invalidated every command that could refer to this mapping.
+    pub(crate) unsafe fn complete(self) {
+        let mut this = ManuallyDrop::new(self);
+
+        // SAFETY: `this` cannot run `Drop`, so the mapping is moved exactly
+        // once and is not accessed again.
+        let mut mapping = unsafe { ManuallyDrop::take(&mut this.mapping) };
+        // SAFETY: Forwarded from this function's safety requirements.
+        unsafe { mapping.reclaim_single() };
+        drop(mapping);
+    }
+}
+
+impl Drop for UfsActiveMapping {
+    fn drop(&mut self) {
+        if matches!(&*self.mapping, UfsPreparedMapping::None) {
+            // SAFETY: The None variant contains no DMA mapping and can be
+            // released without proving that hardware access has ended.
+            unsafe { ManuallyDrop::drop(&mut self.mapping) };
+            return;
+        }
+
+        // Do not release an active mapping without proof that device access
+        // has ended. Leaking is safer than allowing DMA into reused memory.
+        pr_warn!("rufs: active DMA mapping dropped without completion; leaking the mapping\n");
+    }
+}
+
+pub(crate) struct UfsPrdt {
+    mapping: UfsPreparedMapping,
+    entry_count: usize,
+}
+
+impl UfsPrdt {
+    pub(crate) fn map<F>(
+        dev: &ARef<device::Device>,
+        cmd: UfsSCSICmd,
+        rq: &Owned<mq::Request<UfsLuBlockOps>>,
+        mempool: &DmaMapMempool<MAX_PRD_ENTRIES>,
+        mut write_entry: F,
+    ) -> Result<Self>
+    where
+        F: FnMut(usize, PrdEntry) -> Result,
+    {
+        if cmd.data_len() == 0 {
+            return Ok(Self {
+                mapping: UfsPreparedMapping::None,
+                entry_count: 0,
+            });
+        }
+
+        let mut iter = rq
+            .dma_map_iter(dev, mempool.clone())
+            .map_err(map_dma_error)?;
+        let mut remaining = cmd.data_len();
+        let mut entry_count = 0;
+
+        loop {
+            let segment_address = iter.address();
+            let segment_length = iter.length();
+            if segment_length == 0 || segment_length > remaining {
+                return Err(EINVAL);
+            }
+
+            append_entries(
+                &mut entry_count,
+                segment_address,
+                segment_length,
+                &mut write_entry,
+            )?;
+
+            remaining -= segment_length;
+            if remaining == 0 {
+                break;
+            }
+
+            iter.next().map_err(map_dma_error)?;
+        }
+
+        let iter = iter.finish();
+
+        Ok(Self {
+            mapping: UfsPreparedMapping::Sg(iter),
+            entry_count,
+        })
+    }
+
+    pub(crate) fn single(mapping: DetachedStreamingInFlight<KBox<UfsUnmapParameterList>>) -> Self {
+        Self {
+            mapping: UfsPreparedMapping::Single(Some(mapping)),
+            entry_count: 1,
+        }
+    }
+
+    pub(crate) fn entry_count(&self) -> usize {
+        self.entry_count
+    }
+
+    pub(crate) fn into_mapping(self) -> UfsPreparedMapping {
+        self.mapping
+    }
+}
+
+fn map_dma_error(error: BlkError) -> Error {
+    match error.to_blk_status() {
+        bindings::BLK_STS_RESOURCE | bindings::BLK_STS_DEV_RESOURCE => EBUSY,
+        _ => EIO,
+    }
+}
+
+fn append_entries<F>(
+    entry_count: &mut usize,
+    segment_address: u64,
+    segment_length: u32,
+    write_entry: &mut F,
+) -> Result<()>
+where
+    F: FnMut(usize, PrdEntry) -> Result,
+{
+    if segment_length == 0 || segment_length % PRDT_DATA_BYTE_COUNT_PAD as u32 != 0 {
+        return Err(EINVAL);
+    }
+
+    let mut segment_offset = 0;
+    while segment_offset < segment_length {
+        if *entry_count == MAX_PRD_ENTRIES {
+            return Err(EINVAL);
+        }
+
+        let length = core::cmp::min(PRDT_DATA_BYTE_COUNT_MAX, segment_length - segment_offset);
+        let address = segment_address
+            .checked_add(u64::from(segment_offset))
+            .ok_or(EOVERFLOW)?;
+
+        write_entry(*entry_count, PrdEntry::new(address, length)?)?;
+        *entry_count += 1;
+        segment_offset += length;
+    }
+
+    Ok(())
+}
diff --git a/drivers/rufs/frontend.rs b/drivers/rufs/frontend.rs
new file mode 100644
index 0000000000000..4c670e13dce75
--- /dev/null
+++ b/drivers/rufs/frontend.rs
@@ -0,0 +1,8 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! UFS host-controller bus frontends.
+
+#[cfg(CONFIG_RUFS_PCI)]
+pub(crate) mod pci;
+#[cfg(CONFIG_RUFS_QCOM)]
+pub(crate) mod qcom;
diff --git a/drivers/rufs/frontend/pci.rs b/drivers/rufs/frontend/pci.rs
new file mode 100644
index 0000000000000..61fbdce484c59
--- /dev/null
+++ b/drivers/rufs/frontend/pci.rs
@@ -0,0 +1,170 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! PCI frontend for the UFS driver.
+
+use kernel::{device::Core, pci, prelude::*};
+
+use crate::host::UfsHost;
+use crate::resource::{HciMmio, HostResources};
+use crate::variant::UfsVariantOps;
+
+#[derive(Clone, Copy)]
+pub(crate) enum UfsPciVariant {
+    Qemu,
+    Samsung,
+    IntelCnl,
+    IntelEhl,
+    IntelLkf,
+    IntelAdl,
+    IntelMtl,
+}
+
+impl UfsPciVariant {
+    const fn name(self) -> &'static str {
+        match self {
+            Self::Qemu => "qemu",
+            Self::Samsung => "samsung",
+            Self::IntelCnl => "intel-cnl",
+            Self::IntelEhl => "intel-ehl",
+            Self::IntelLkf => "intel-lkf",
+            Self::IntelAdl => "intel-adl",
+            Self::IntelMtl => "intel-mtl",
+        }
+    }
+}
+
+impl UfsVariantOps for UfsPciVariant {}
+
+kernel::pci_device_table!(
+    PCI_TABLE,
+    <UfsPci as pci::Driver>::IdInfo,
+    [
+        // Match the PCI IDs handled by drivers/ufs/host/ufshcd-pci.c.
+        (
+            pci::DeviceId::from_id(pci::Vendor::REDHAT, 0x0013),
+            UfsPciVariant::Qemu,
+        ),
+        (
+            pci::DeviceId::from_id(pci::Vendor::SAMSUNG, 0xc00c),
+            UfsPciVariant::Samsung,
+        ),
+        (
+            pci::DeviceId::from_id(pci::Vendor::INTEL, 0x9dfa),
+            UfsPciVariant::IntelCnl,
+        ),
+        (
+            pci::DeviceId::from_id(pci::Vendor::INTEL, 0x4b41),
+            UfsPciVariant::IntelEhl,
+        ),
+        (
+            pci::DeviceId::from_id(pci::Vendor::INTEL, 0x4b43),
+            UfsPciVariant::IntelEhl,
+        ),
+        (
+            pci::DeviceId::from_id(pci::Vendor::INTEL, 0x98fa),
+            UfsPciVariant::IntelLkf,
+        ),
+        (
+            pci::DeviceId::from_id(pci::Vendor::INTEL, 0x51ff),
+            UfsPciVariant::IntelAdl,
+        ),
+        (
+            pci::DeviceId::from_id(pci::Vendor::INTEL, 0x54ff),
+            UfsPciVariant::IntelAdl,
+        ),
+        (
+            pci::DeviceId::from_id(pci::Vendor::INTEL, 0x7e47),
+            UfsPciVariant::IntelMtl,
+        ),
+        (
+            pci::DeviceId::from_id(pci::Vendor::INTEL, 0xa847),
+            UfsPciVariant::IntelMtl,
+        ),
+        (
+            pci::DeviceId::from_id(pci::Vendor::INTEL, 0x7747),
+            UfsPciVariant::IntelMtl,
+        ),
+        (
+            pci::DeviceId::from_id(pci::Vendor::INTEL, 0xe447),
+            UfsPciVariant::IntelMtl,
+        ),
+        (
+            pci::DeviceId::from_id(pci::Vendor::INTEL, 0x4d47),
+            UfsPciVariant::IntelMtl,
+        ),
+        (
+            pci::DeviceId::from_id(pci::Vendor::INTEL, 0xd335),
+            UfsPciVariant::IntelMtl,
+        ),
+    ]
+);
+
+pub(crate) struct UfsPci;
+
+#[pin_data]
+pub(crate) struct UfsPciData<'a> {
+    pdev: &'a pci::Device,
+    #[pin]
+    host: UfsHost<'a>,
+    irq_vectors: pci::IrqVectorRegistration<'a>,
+}
+
+impl pci::Driver for UfsPci {
+    type IdInfo = UfsPciVariant;
+    type Data<'a> = UfsPciData<'a>;
+    const ID_TABLE: pci::IdTable<Self::IdInfo> = &PCI_TABLE;
+
+    fn probe<'a>(
+        pdev: &'a pci::Device<Core<'_>>,
+        platform: Option<&'a Self::IdInfo>,
+    ) -> impl PinInit<Self::Data<'a>, Error> + 'a {
+        pin_init::pin_init_scope(move || {
+            let platform = platform.ok_or(ENODEV)?;
+            pr_info!(
+                "rufs: probe: platform={} vendor={} device=0x{:04x}\n",
+                platform.name(),
+                pdev.vendor_id(),
+                pdev.device_id(),
+            );
+
+            pdev.enable_device_mem()?;
+            pdev.set_master();
+
+            let variant = KBox::new(*platform, GFP_KERNEL)? as KBox<dyn UfsVariantOps>;
+            let resources = HostResources::new(
+                pdev.as_ref().into(),
+                HciMmio::from_pci(pdev)?,
+                None,
+                variant,
+            )?;
+            // Until MCQ ESI routing is implemented, all independently
+            // registered handlers share the controller IRQ. Per-CQ actions
+            // still provide queue-local completion dispatch for MCQ.
+            let irq_vectors = pdev.alloc_irq_vectors(1, 1, pci::IrqTypes::all())?;
+            // SAFETY: `irq_vectors` is stored after `host`, so the host drops
+            // all IRQ registrations before the vector allocation is freed.
+            let uic_irq = unsafe { irq_vectors.request(0)? };
+            // SAFETY: Same lifetime and field-order guarantee as above.
+            let queue_irq = unsafe { irq_vectors.request(0)? };
+            // SAFETY: Same lifetime and field-order guarantee as above.
+            let mcq_irq = unsafe { irq_vectors.request(0)? };
+            let host = UfsHost::new(resources, uic_irq, queue_irq).pin_chain(move |host| {
+                host.request_mcq_queue_irqs(|| {
+                    // SAFETY: `irq_vectors` remains stored after `host`, so
+                    // this IRQ stays allocated for every per-CQ registration.
+                    Ok(unsafe { mcq_irq.duplicate() })
+                })
+            });
+
+            Ok(try_pin_init!(UfsPciData {
+                pdev,
+                host <- host,
+                irq_vectors,
+            }))
+        })
+    }
+
+    fn unbind(_pdev: &pci::Device<Core<'_>>, this: Pin<&Self::Data<'_>>) {
+        this.host.shutdown();
+    }
+}
diff --git a/drivers/rufs/frontend/qcom.rs b/drivers/rufs/frontend/qcom.rs
new file mode 100644
index 0000000000000..f33734ec933fd
--- /dev/null
+++ b/drivers/rufs/frontend/qcom.rs
@@ -0,0 +1,718 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! Qualcomm platform frontend for the UFS driver.
+
+use core::sync::atomic::{AtomicBool, AtomicU32, Ordering};
+
+use kernel::{
+    clk::{Clk, Hertz},
+    device,
+    device::Core,
+    gpio::OptionalOutput,
+    interconnect::Path,
+    io::{poll::read_poll_timeout, register, Io},
+    macros::vtable,
+    new_mutex, of, opp,
+    phy::{Phy, UfsMode},
+    platform,
+    prelude::*,
+    regulator,
+    reset::OptionalExclusive,
+    str::CString,
+    sync::{aref::ARef, Arc, Mutex},
+    time::{delay::fsleep, Delta},
+};
+
+use crate::host::UfsHost;
+use crate::reg::{
+    McqQueueConfigLayout, McqRegisterLayout, McqRegisterRegion, UfsMcqOprInfo, UfsMcqOprSet, UfsReg,
+};
+use crate::resource::{HciMmio, HostResources, McqMmio};
+use crate::uic::{UfsPaLayerAttr, UfsUic};
+use crate::variant::{NotifyPhase, UfsVariantOps};
+
+pub(crate) struct UfsQcom;
+
+#[derive(Clone, Copy)]
+pub(crate) enum UfsQcomVariant {
+    Eliza,
+    Kaanapali,
+    Sm8550,
+    Sm8650,
+    Sm8750,
+    X1e80100,
+}
+
+impl UfsQcomVariant {
+    const fn name(self) -> &'static str {
+        match self {
+            Self::Eliza => "eliza",
+            Self::Kaanapali => "kaanapali",
+            Self::Sm8550 => "sm8550",
+            Self::Sm8650 => "sm8650",
+            Self::Sm8750 => "sm8750",
+            Self::X1e80100 => "x1e80100",
+        }
+    }
+
+    fn max_clock_rate(self) -> Result<Hertz> {
+        match self {
+            Self::Sm8550 | Self::X1e80100 => Ok(Hertz::from_mhz(300)),
+            Self::Eliza | Self::Kaanapali | Self::Sm8650 | Self::Sm8750 => Ok(Hertz::from_mhz(403)),
+        }
+    }
+
+    const fn has_mcq_resource(self) -> bool {
+        matches!(self, Self::Eliza)
+    }
+}
+
+const CLOCK_NAMES: [&CStr; 8] = [
+    c"core_clk",
+    c"bus_aggr_clk",
+    c"iface_clk",
+    c"core_clk_unipro",
+    c"ref_clk",
+    c"tx_lane0_sync_clk",
+    c"rx_lane0_sync_clk",
+    c"rx_lane1_sync_clk",
+];
+
+const CORE_CLOCK_INDEX: usize = 0;
+const UNIPRO_CORE_CLOCK_INDEX: usize = 3;
+const CONTROL_CLOCK_COUNT: usize = 5;
+
+const MAX_MEMORY_BANDWIDTH: u32 = 7_643_136;
+const MAX_CONFIG_BANDWIDTH: u32 = 819_200;
+
+const MCQ_CONFIG_BASE: usize = 0x1c000;
+const MCQ_QUEUE_CONFIG_STRIDE: usize = 0x40;
+const MCQ_SQD_OFFSET: usize = 0x5000;
+const MCQ_SQIS_OFFSET: usize = 0x5040;
+const MCQ_CQD_OFFSET: usize = 0x5080;
+const MCQ_CQIS_OFFSET: usize = 0x50c0;
+const MCQ_OPERATION_STRIDE: usize = 0x100;
+const QCOM_MAX_MCQ_ACTIVE_COMMANDS: usize = 64;
+
+const MPHY_TX_FSM_STATE: u32 = 0x41;
+const TX_FSM_HIBERN8: u32 = 0x1;
+const PA_LOCAL_TX_LCC_ENABLE: u32 = 0x155e;
+const PA_TXHSADAPTTYPE: u32 = 0x15d4;
+const PA_INITIAL_ADAPT: u32 = 0x1;
+const PA_NO_ADAPT: u32 = 0x3;
+const UFS_HS_G4: u32 = 4;
+const PA_VS_CLK_CFG: u32 = 0x9004;
+const PA_VS_CLK_CFG_MASK: u32 = 0x1ff;
+const DL_VS_CLK_CFG: u32 = 0xa00b;
+const DL_VS_CLK_CFG_MASK: u32 = 0x3ff;
+const PA_VS_CORE_CLK_40NS_CYCLES: u32 = 0x9007;
+const DME_VS_CORE_CLK_CTRL: u32 = 0xd002;
+
+const PA_HS_MODE_A: u32 = 1;
+const CORE_CLK_DIV_EN: u32 = 1 << 8;
+const DME_HW_CGC_EN: u32 = 1 << 9;
+const CORE_CLK_CYCLES_MASK: u32 = 0xff;
+const CORE_CLK_CYCLES_MASK_V4: u32 = 0x0fff << 16;
+const CORE_CLK_40NS_CYCLES_MASK: u32 = 0x7f;
+
+#[derive(Default)]
+struct UfsQcomOppOps;
+
+#[vtable]
+impl opp::ConfigOps for UfsQcomOppOps {
+    fn config_clks(
+        dev: &device::Device,
+        _table: &opp::Table,
+        selected: &opp::OPP,
+        _scaling_down: bool,
+    ) -> Result {
+        for (index, name) in CLOCK_NAMES.into_iter().enumerate() {
+            let rate = selected.freq(Some(u32::try_from(index).map_err(|_| EOVERFLOW)?));
+            if rate.as_hz() == 0 {
+                continue;
+            }
+
+            Clk::get(dev, Some(name))?.set_rate(rate)?;
+        }
+        Ok(())
+    }
+}
+
+struct UfsQcomOpp {
+    _table: opp::Table,
+    _config: opp::ConfigToken,
+}
+
+impl UfsQcomOpp {
+    fn new(dev: &device::Device<device::Bound>, max_rate: Hertz) -> Result<Self> {
+        let mut names = KVec::new();
+        for name in CLOCK_NAMES {
+            names.push(CString::try_from(name)?, GFP_KERNEL)?;
+        }
+
+        let config = opp::Config::<UfsQcomOppOps>::new()
+            .set_clk_names(names)?
+            .set(dev)?;
+        let dev_ref: ARef<device::Device> = dev.into();
+        let table = opp::Table::from_of(&dev_ref, 0)?;
+        let selected =
+            table.opp_from_freq(max_rate, Some(true), Some(0), opp::SearchType::Exact)?;
+        table.set_opp(&selected)?;
+
+        Ok(Self {
+            _table: table,
+            _config: config,
+        })
+    }
+}
+
+register! {
+    QCOM_SYS1CLK_1US(u32) @ 0xc0 { 31:0 value; }
+    QCOM_PARAM0(u32) @ 0xd0 { 6:4 max_hs_gear; }
+    QCOM_CFG0(u32) @ 0xd8 { 5:5 qunipro_g4_select => bool; }
+    QCOM_CFG1(u32) @ 0xdc {
+        26:26 device_ref_clock_enable => bool;
+        0:0 qunipro_select => bool;
+    }
+    QCOM_CFG2(u32) @ 0xe0 { 7:0 clock_gating; }
+    QCOM_HW_VERSION(u32) @ 0xe4 {
+        31:28 major;
+        27:16 minor;
+        15:0 step;
+    }
+}
+
+struct UfsQcomClocks {
+    clocks: KVec<Clk>,
+    control_enabled: usize,
+    lanes_enabled: AtomicBool,
+}
+
+impl UfsQcomClocks {
+    fn new(dev: &device::Device<device::Bound>) -> Result<Self> {
+        let mut this = Self {
+            clocks: KVec::new(),
+            control_enabled: 0,
+            lanes_enabled: AtomicBool::new(false),
+        };
+
+        for name in CLOCK_NAMES {
+            let clock = Clk::get(dev, Some(name))?;
+            this.clocks.push(clock, GFP_KERNEL)?;
+        }
+
+        while this.control_enabled < CONTROL_CLOCK_COUNT {
+            this.clocks[this.control_enabled].prepare_enable()?;
+            this.control_enabled += 1;
+        }
+
+        Ok(this)
+    }
+
+    fn enable_lanes(&self) -> Result {
+        if self.lanes_enabled.load(Ordering::Acquire) {
+            return Ok(());
+        }
+
+        for (enabled, clock) in self.clocks[CONTROL_CLOCK_COUNT..].iter().enumerate() {
+            if let Err(e) = clock.prepare_enable() {
+                for clock in self.clocks[CONTROL_CLOCK_COUNT..CONTROL_CLOCK_COUNT + enabled]
+                    .iter()
+                    .rev()
+                {
+                    clock.disable_unprepare();
+                }
+                return Err(e);
+            }
+        }
+
+        self.lanes_enabled.store(true, Ordering::Release);
+        Ok(())
+    }
+
+    fn disable_lanes(&self) {
+        if !self.lanes_enabled.swap(false, Ordering::AcqRel) {
+            return;
+        }
+
+        for clock in self.clocks[CONTROL_CLOCK_COUNT..].iter().rev() {
+            clock.disable_unprepare();
+        }
+    }
+
+    fn cycles_per_microsecond(&self, index: usize) -> u32 {
+        let hz = self.clocks[index].rate().as_hz() as u64;
+        let hz = core::cmp::max(hz, 1_000_000);
+
+        hz.div_ceil(1_000_000) as u32
+    }
+}
+
+impl Drop for UfsQcomClocks {
+    fn drop(&mut self) {
+        self.disable_lanes();
+        for clock in self.clocks[..self.control_enabled].iter().rev() {
+            clock.disable_unprepare();
+        }
+    }
+}
+
+struct UfsQcomInterconnect {
+    _ddr: Path,
+    _cpu: Path,
+}
+
+impl UfsQcomInterconnect {
+    fn new(dev: &device::Device<device::Bound>) -> Result<Self> {
+        let ddr = Path::get(dev, c"ufs-ddr")?;
+        let cpu = Path::get(dev, c"cpu-ufs")?;
+
+        ddr.set_bw(0, MAX_MEMORY_BANDWIDTH)?;
+        if let Err(e) = cpu.set_bw(0, MAX_CONFIG_BANDWIDTH) {
+            let _ = ddr.set_bw(0, 0);
+            return Err(e);
+        }
+
+        Ok(Self {
+            _ddr: ddr,
+            _cpu: cpu,
+        })
+    }
+}
+
+struct UfsQcomPlatform {
+    has_mcq_resource: bool,
+    expected_lanes: u32,
+    // Serialize PHY transitions and retain OPP resources until shutdown.
+    lifecycle: Arc<Mutex<Option<KBox<UfsQcomOpp>>>>,
+    clocks: UfsQcomClocks,
+    _interconnect: UfsQcomInterconnect,
+    reset: OptionalExclusive,
+    device_reset: OptionalOutput,
+    phy: Phy,
+    hardware_major: AtomicU32,
+    phy_gear: AtomicU32,
+}
+
+impl UfsQcomPlatform {
+    fn enable_supplies(dev: &device::Device<device::Bound>) -> Result {
+        let Some(fwnode) = dev.fwnode() else {
+            return Ok(());
+        };
+
+        for (property, supply) in [
+            (c"vcc-supply", c"vcc"),
+            (c"vccq-supply", c"vccq"),
+            (c"vccq2-supply", c"vccq2"),
+        ] {
+            if fwnode.property_present(property) {
+                regulator::devm_enable(dev, supply)?;
+            }
+        }
+        Ok(())
+    }
+
+    fn new(dev: &device::Device<device::Bound>, variant: UfsQcomVariant) -> Result<Self> {
+        Self::enable_supplies(dev)?;
+        let opp = UfsQcomOpp::new(dev, variant.max_clock_rate()?)?;
+        let expected_lanes = dev
+            .fwnode()
+            .map(|fwnode| fwnode.property_read::<u32>(c"lanes-per-direction").or(2))
+            .unwrap_or(2);
+        if expected_lanes == 0 || expected_lanes > 2 {
+            return Err(EINVAL);
+        }
+
+        Ok(Self {
+            has_mcq_resource: variant.has_mcq_resource(),
+            expected_lanes,
+            lifecycle: Arc::pin_init(new_mutex!(Some(KBox::new(opp, GFP_KERNEL)?)), GFP_KERNEL)?,
+            clocks: UfsQcomClocks::new(dev)?,
+            _interconnect: UfsQcomInterconnect::new(dev)?,
+            reset: OptionalExclusive::get(dev, c"rst")?,
+            // Hold the attached device in reset until `device_reset()` runs.
+            device_reset: OptionalOutput::get(dev, c"reset", true)?,
+            phy: Phy::get(dev, c"ufsphy")?,
+            hardware_major: AtomicU32::new(0),
+            phy_gear: AtomicU32::new(0),
+        })
+    }
+
+    fn hardware_major(&self, reg: &UfsReg) -> Result<u32> {
+        Ok(reg.hci_access()?.read(QCOM_HW_VERSION).major().get())
+    }
+
+    fn initial_phy_config(&self, reg: &UfsReg) -> Result<(u32, UfsMode)> {
+        let access = reg.hci_access()?;
+        let major = access.read(QCOM_HW_VERSION).major().get();
+        let gear = if major < 4 {
+            2
+        } else {
+            access.read(QCOM_PARAM0).max_hs_gear().get()
+        };
+        if gear == 0 {
+            return Err(EINVAL);
+        }
+
+        let mode = if major == 5 && gear == 5 {
+            UfsMode::HighSpeedA
+        } else {
+            UfsMode::HighSpeedB
+        };
+        Ok((gear, mode))
+    }
+
+    fn select_qunipro(&self, reg: &UfsReg, hardware_major: u32) -> Result {
+        let access = reg.hci_access()?;
+        access.update(QCOM_CFG1, |value| {
+            value
+                .with_qunipro_select(true)
+                .with_device_ref_clock_enable(true)
+        });
+        access.read(QCOM_CFG1);
+
+        if hardware_major >= 5 {
+            access.update(QCOM_CFG0, |value| value.with_qunipro_g4_select(false));
+            access.read(QCOM_CFG0);
+        }
+
+        Ok(())
+    }
+
+    fn power_up(&self, reg: &UfsReg) -> Result {
+        let _lifecycle = self.lifecycle.lock();
+
+        self.clocks.disable_lanes();
+        self.phy.shutdown();
+
+        self.reset.assert()?;
+        fsleep(Delta::from_micros(200));
+        self.reset.deassert()?;
+        fsleep(Delta::from_millis(1));
+
+        let hardware_major = self.hardware_major(reg)?;
+        let (gear, mode) = self.initial_phy_config(reg)?;
+        if let Err(e) = (|| {
+            self.phy.init()?;
+            self.phy.set_ufs_mode(mode, gear as i32)?;
+            self.phy.power_on()?;
+            self.phy.calibrate()?;
+            self.select_qunipro(reg, hardware_major)?;
+            self.clocks.enable_lanes()
+        })() {
+            self.clocks.disable_lanes();
+            self.phy.shutdown();
+            return Err(e);
+        }
+
+        self.hardware_major.store(hardware_major, Ordering::Release);
+        self.phy_gear.store(gear, Ordering::Release);
+        Ok(())
+    }
+
+    fn check_hibern8(&self, uic: &UfsUic) -> Result {
+        read_poll_timeout(
+            || uic.dme_get_sel(MPHY_TX_FSM_STATE, 0),
+            |state| *state == TX_FSM_HIBERN8,
+            Delta::from_micros(100),
+            Delta::from_millis(100),
+        )?;
+        Ok(())
+    }
+
+    fn set_unipro_clock_cycles(&self, uic: &UfsUic, hardware_major: u32) -> Result {
+        let cycles = self.clocks.cycles_per_microsecond(UNIPRO_CORE_CLOCK_INDEX);
+        let (mask, value) = if hardware_major >= 4 {
+            (CORE_CLK_CYCLES_MASK_V4, cycles << 16)
+        } else {
+            (CORE_CLK_CYCLES_MASK, cycles)
+        };
+        if value & !mask != 0 {
+            return Err(ERANGE);
+        }
+
+        let mut register = uic.dme_get(DME_VS_CORE_CLK_CTRL)?;
+        register &= !(mask | CORE_CLK_DIV_EN);
+        register |= value;
+        uic.dme_set(DME_VS_CORE_CLK_CTRL, register)?;
+
+        if hardware_major < 4 {
+            return Ok(());
+        }
+
+        let cycles_40ns = match cycles {
+            403 => 16,
+            300 => 12,
+            202 => 8,
+            150 => 6,
+            100 => 4,
+            75 => 3,
+            38 => 2,
+            _ => return Err(EINVAL),
+        };
+        let mut register = uic.dme_get(PA_VS_CORE_CLK_40NS_CYCLES)?;
+        register &= !CORE_CLK_40NS_CYCLES_MASK;
+        register |= cycles_40ns;
+        uic.dme_set(PA_VS_CORE_CLK_40NS_CYCLES, register)
+    }
+
+    fn configure_link_startup(&self, reg: &UfsReg, uic: &UfsUic) -> Result {
+        self.check_hibern8(uic)?;
+        self.enable_unipro_clock_gating(uic);
+
+        let core_cycles = self.clocks.cycles_per_microsecond(CORE_CLOCK_INDEX);
+        reg.hci_access()?
+            .write_reg(QCOM_SYS1CLK_1US::zeroed().with_value(core_cycles));
+        reg.hci_access()?.read(QCOM_SYS1CLK_1US);
+
+        self.set_unipro_clock_cycles(uic, self.hardware_major(reg)?)?;
+        uic.dme_set(PA_LOCAL_TX_LCC_ENABLE, 0)
+    }
+
+    fn dme_set_bits(&self, uic: &UfsUic, attr: u32, mask: u32) -> Result {
+        let value = uic.dme_get(attr)?;
+        uic.dme_set(attr, value | mask)
+    }
+
+    fn enable_unipro_clock_gating(&self, uic: &UfsUic) {
+        for (attr, mask) in [
+            (DL_VS_CLK_CFG, DL_VS_CLK_CFG_MASK),
+            (PA_VS_CLK_CFG, PA_VS_CLK_CFG_MASK),
+            (DME_VS_CORE_CLK_CTRL, DME_HW_CGC_EN),
+        ] {
+            if let Err(e) = self.dme_set_bits(uic, attr, mask) {
+                pr_warn!(
+                    "[RUFS] Qualcomm: failed to enable clock gating attr={:#x} errno={}\n",
+                    attr,
+                    e.to_errno(),
+                );
+                break;
+            }
+        }
+    }
+
+    fn configure_adaptation(&self, uic: &UfsUic, gear: u32) {
+        let adapt = if gear >= UFS_HS_G4 {
+            PA_INITIAL_ADAPT
+        } else {
+            PA_NO_ADAPT
+        };
+        if let Err(e) = uic.dme_set(PA_TXHSADAPTTYPE, adapt) {
+            pr_warn!(
+                "[RUFS] Qualcomm: failed to configure PA adaptation errno={}\n",
+                e.to_errno(),
+            );
+        }
+    }
+
+    fn connected_lanes_valid(&self, uic: &UfsUic) -> Result<bool> {
+        let (rx_lanes, tx_lanes) = uic.connected_lanes()?;
+        if rx_lanes == self.expected_lanes && tx_lanes == self.expected_lanes {
+            return Ok(true);
+        }
+
+        pr_err!(
+            "[RUFS] Qualcomm: connected lane mismatch expected={} rx={} tx={}\n",
+            self.expected_lanes,
+            rx_lanes,
+            tx_lanes,
+        );
+        Ok(false)
+    }
+}
+
+impl UfsVariantOps for UfsQcomPlatform {
+    fn mcq_register_layout(&self, _reg: &UfsReg) -> Result<McqRegisterLayout> {
+        if !self.has_mcq_resource {
+            return Err(ENODEV);
+        }
+
+        let operation = |offset| {
+            UfsMcqOprInfo::new(
+                McqRegisterRegion::Mcq,
+                offset,
+                MCQ_CONFIG_BASE + offset,
+                MCQ_OPERATION_STRIDE,
+            )
+        };
+
+        Ok(McqRegisterLayout::new(
+            McqQueueConfigLayout::new(McqRegisterRegion::Mcq, 0, MCQ_QUEUE_CONFIG_STRIDE),
+            UfsMcqOprSet::new(
+                operation(MCQ_SQD_OFFSET),
+                operation(MCQ_SQIS_OFFSET),
+                operation(MCQ_CQD_OFFSET),
+                operation(MCQ_CQIS_OFFSET),
+            ),
+        ))
+    }
+
+    fn mcq_enabled(&self) -> bool {
+        self.has_mcq_resource
+    }
+
+    fn constrain_mcq_active_commands(&self, reported: usize) -> usize {
+        core::cmp::min(reported, QCOM_MAX_MCQ_ACTIVE_COMMANDS)
+    }
+
+    fn device_reset(&self) -> Result<()> {
+        if !self.device_reset.is_present() {
+            return Ok(());
+        }
+
+        self.device_reset.set_value(true)?;
+        fsleep(Delta::from_micros(10));
+        self.device_reset.set_value(false)?;
+        fsleep(Delta::from_micros(10));
+        Ok(())
+    }
+
+    fn hce_enable_notify(&self, reg: &UfsReg, phase: NotifyPhase) -> Result<()> {
+        match phase {
+            NotifyPhase::Pre => self.power_up(reg),
+            NotifyPhase::Post => {
+                reg.hci_access()?
+                    .update(QCOM_CFG2, |value| value.with_clock_gating(0xff));
+                reg.hci_access()?.read(QCOM_CFG2);
+                Ok(())
+            }
+        }
+    }
+
+    fn link_startup_notify(&self, reg: &UfsReg, uic: &UfsUic, phase: NotifyPhase) -> Result<()> {
+        match phase {
+            NotifyPhase::Pre => self.configure_link_startup(reg, uic),
+            NotifyPhase::Post => Ok(()),
+        }
+    }
+
+    fn link_startup_valid(&self, uic: &UfsUic) -> Result<bool> {
+        self.connected_lanes_valid(uic)
+    }
+
+    fn constrain_power_mode(&self, mut desired: UfsPaLayerAttr) -> Result<UfsPaLayerAttr> {
+        let phy_gear = self.phy_gear.load(Ordering::Acquire);
+        if phy_gear == 0 {
+            return Err(EINVAL);
+        }
+
+        desired.gear_rx = core::cmp::min(desired.gear_rx, phy_gear);
+        desired.gear_tx = core::cmp::min(desired.gear_tx, phy_gear);
+        if self.hardware_major.load(Ordering::Acquire) == 5 && phy_gear == 5 {
+            desired.hs_rate = PA_HS_MODE_A;
+        }
+        Ok(desired)
+    }
+
+    fn power_mode_notify(
+        &self,
+        _reg: &UfsReg,
+        uic: &UfsUic,
+        mode: UfsPaLayerAttr,
+        phase: NotifyPhase,
+    ) -> Result<()> {
+        if matches!(phase, NotifyPhase::Pre) && self.hardware_major.load(Ordering::Acquire) >= 4 {
+            self.configure_adaptation(uic, mode.gear_tx);
+        }
+        Ok(())
+    }
+
+    fn shutdown(&self, _reg: &UfsReg) {
+        let mut lifecycle = self.lifecycle.lock();
+
+        self.clocks.disable_lanes();
+        self.phy.shutdown();
+
+        // Remove static OPPs before generic PM-domain detach so a later bind
+        // can configure the device's OPP table again.
+        let opp = lifecycle.take();
+        drop(lifecycle);
+        drop(opp);
+    }
+}
+
+kernel::of_device_table!(
+    OF_TABLE,
+    <UfsQcom as platform::Driver>::IdInfo,
+    [
+        (
+            of::DeviceId::new(c"qcom,eliza-ufshc"),
+            UfsQcomVariant::Eliza,
+        ),
+        (
+            of::DeviceId::new(c"qcom,kaanapali-ufshc"),
+            UfsQcomVariant::Kaanapali,
+        ),
+        (
+            of::DeviceId::new(c"qcom,x1e80100-ufshc"),
+            UfsQcomVariant::X1e80100,
+        ),
+        (
+            of::DeviceId::new(c"qcom,sm8550-ufshc"),
+            UfsQcomVariant::Sm8550,
+        ),
+        (
+            of::DeviceId::new(c"qcom,sm8650-ufshc"),
+            UfsQcomVariant::Sm8650,
+        ),
+        (
+            of::DeviceId::new(c"qcom,sm8750-ufshc"),
+            UfsQcomVariant::Sm8750,
+        ),
+    ]
+);
+
+#[pin_data]
+pub(crate) struct UfsQcomData<'a> {
+    pdev: &'a platform::Device,
+    #[pin]
+    host: UfsHost<'a>,
+}
+
+impl platform::Driver for UfsQcom {
+    type IdInfo = UfsQcomVariant;
+    type Data<'bound> = UfsQcomData<'bound>;
+
+    const OF_ID_TABLE: Option<of::IdTable<Self::IdInfo>> = Some(&OF_TABLE);
+
+    fn probe<'bound>(
+        pdev: &'bound platform::Device<Core<'_>>,
+        variant: Option<&'bound Self::IdInfo>,
+    ) -> impl PinInit<Self::Data<'bound>, Error> + 'bound {
+        pin_init::pin_init_scope(move || {
+            let variant = *variant.ok_or(ENODEV)?;
+            let hci = HciMmio::from_platform(pdev)?;
+            let mcq = if variant.has_mcq_resource() {
+                let request = pdev.io_request_by_name(c"mcq").ok_or(ENODEV)?;
+                Some(McqMmio::from_platform(request.iomap()?.into_devres()?))
+            } else {
+                None
+            };
+            let platform = UfsQcomPlatform::new(pdev.as_ref(), variant)?;
+
+            dev_info!(
+                pdev.as_ref(),
+                "RUFS Qualcomm frontend: variant={}\n",
+                variant.name(),
+            );
+
+            let resources = HostResources::new(
+                pdev.as_ref().into(),
+                hci,
+                mcq,
+                KBox::new(platform, GFP_KERNEL)? as KBox<dyn UfsVariantOps>,
+            )?;
+            // The UIC and transfer handlers are independent shared actions on
+            // the controller's global interrupt.
+            let uic_irq = pdev.irq_by_index(0)?;
+            let queue_irq = pdev.irq_by_index(0)?;
+            let host = UfsHost::new(resources, uic_irq, queue_irq);
+
+            Ok(try_pin_init!(UfsQcomData { pdev, host <- host }))
+        })
+    }
+
+    fn unbind(_pdev: &platform::Device<Core<'_>>, this: Pin<&Self::Data<'_>>) {
+        this.host.shutdown();
+    }
+}
diff --git a/drivers/rufs/hci.rs b/drivers/rufs/hci.rs
new file mode 100644
index 0000000000000..43cfa3f3ba226
--- /dev/null
+++ b/drivers/rufs/hci.rs
@@ -0,0 +1,5 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! UFS host controller interface definitions.
+
+pub(crate) mod descriptor;
diff --git a/drivers/rufs/hci/descriptor.rs b/drivers/rufs/hci/descriptor.rs
new file mode 100644
index 0000000000000..e949576aec344
--- /dev/null
+++ b/drivers/rufs/hci/descriptor.rs
@@ -0,0 +1,276 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! UFSHCI request and queue descriptor layouts.
+
+use crate::protocol::scsi::*;
+use crate::protocol::upiu::{Upiu, UpiuTmReq, UpiuTmRsp};
+use crate::protocol::UfsCmd;
+use kernel::bits::{genmask_u64, genmask_u8};
+use kernel::{dma, prelude::*};
+
+pub(crate) const MAX_PRD_ENTRIES: usize = 256;
+
+const MASK_OCS: u8 = 0x0f;
+const CQE_UCD_BASE_ADDR: u64 = genmask_u64(7..=63);
+const CQE_SQ_ID: u64 = genmask_u64(0..=4);
+const ALIGNED_UPIU_SIZE: usize = 512;
+
+enum UtpCmdType {
+    UfsStorage = 0x1,
+}
+
+enum UtpDataDirection {
+    NoDataTransfer = 0,
+    HostToDevice = 1,
+    DeviceToHost = 2,
+}
+
+impl From<dma::DataDirection> for UtpDataDirection {
+    fn from(direction: dma::DataDirection) -> Self {
+        match direction {
+            dma::DataDirection::ToDevice => Self::HostToDevice,
+            dma::DataDirection::FromDevice => Self::DeviceToHost,
+            _ => Self::NoDataTransfer,
+        }
+    }
+}
+
+impl From<UfsScsiDataDirection> for UtpDataDirection {
+    fn from(direction: UfsScsiDataDirection) -> Self {
+        match direction {
+            UfsScsiDataDirection::Read => Self::DeviceToHost,
+            UfsScsiDataDirection::Write => Self::HostToDevice,
+            UfsScsiDataDirection::None => Self::NoDataTransfer,
+        }
+    }
+}
+
+#[repr(C, packed)]
+#[derive(Default, Clone, Copy, FromBytes, IntoBytes)]
+pub(crate) struct PrdEntry {
+    pub(crate) addr: u64,
+    pub(crate) reserved: u32,
+    pub(crate) size: u32,
+}
+
+impl PrdEntry {
+    pub(crate) fn new(addr: u64, length: u32) -> Result<Self> {
+        if length == 0 {
+            return Err(EINVAL);
+        }
+
+        Ok(Self {
+            addr: addr.to_le(),
+            reserved: 0,
+            size: (length - 1).to_le(),
+        })
+    }
+}
+
+#[repr(C, packed)]
+#[derive(Clone, Copy, FromBytes, IntoBytes)]
+pub(crate) struct Ucd {
+    pub(crate) cmd_upiu: Upiu,
+    pub(crate) rsp_upiu: Upiu,
+    pub(crate) prdt: [PrdEntry; MAX_PRD_ENTRIES],
+}
+
+#[derive(Clone, Copy)]
+pub(crate) enum UtpOcs {
+    Success = 0x0,
+    InvalidCmdTableAttr = 0x1,
+    InvalidPrdtAttr = 0x2,
+    MismatchDataBufSize = 0x3,
+    MisMatchRespUpiuSize = 0x4,
+    PeerCommFailure = 0x5,
+    Aborted = 0x6,
+    FatalError = 0x7,
+    DeviceFatalError = 0x8,
+    InvalidCryptoConfig = 0x9,
+    GeneralCryptoError = 0xa,
+    InvalidCommandStatus = 0xf,
+}
+
+impl From<u8> for UtpOcs {
+    fn from(ocs: u8) -> Self {
+        match ocs {
+            0x0 => Self::Success,
+            0x1 => Self::InvalidCmdTableAttr,
+            0x2 => Self::InvalidPrdtAttr,
+            0x3 => Self::MismatchDataBufSize,
+            0x4 => Self::MisMatchRespUpiuSize,
+            0x5 => Self::PeerCommFailure,
+            0x6 => Self::Aborted,
+            0x7 => Self::FatalError,
+            0x8 => Self::DeviceFatalError,
+            0x9 => Self::InvalidCryptoConfig,
+            0xa => Self::GeneralCryptoError,
+            _ => Self::InvalidCommandStatus,
+        }
+    }
+}
+
+#[repr(C, packed)]
+#[derive(Default, Clone, Copy, FromBytes, IntoBytes)]
+struct ReqDescHeader {
+    cci: u8,
+    ehs_length: u8,
+    flags: u8,
+    ctrl: u8,
+    dunl: u32,
+    ocs: u8,
+    cds: u8,
+    ldbc: u16,
+    dunu: u32,
+}
+
+impl ReqDescHeader {
+    fn set_cmd_type(&mut self, cmd_type: UtpCmdType) {
+        self.ctrl &= !genmask_u8(4..=7);
+        self.ctrl |= ((cmd_type as u8) << 4) & genmask_u8(4..=7);
+    }
+
+    fn set_direction(&mut self, direction: UtpDataDirection) {
+        self.ctrl &= !genmask_u8(1..=2);
+        self.ctrl |= ((direction as u8) << 1) & genmask_u8(1..=2);
+    }
+
+    fn set_interrupt(&mut self, interrupt: bool) {
+        self.ctrl &= !genmask_u8(0..=0);
+        self.ctrl |= u8::from(interrupt) & genmask_u8(0..=0);
+    }
+
+    fn device() -> Self {
+        let mut header = Self::default();
+        header.set_cmd_type(UtpCmdType::UfsStorage);
+        header.set_direction(UtpDataDirection::NoDataTransfer);
+        header.set_interrupt(true);
+        header.ocs = UtpOcs::InvalidCommandStatus as u8;
+        header
+    }
+
+    fn scsi(cmd: UfsSCSICmd) -> Self {
+        let mut header = Self::default();
+        header.set_cmd_type(UtpCmdType::UfsStorage);
+        header.set_direction(cmd.direction().into());
+        header.set_interrupt(true);
+        header.ocs = UtpOcs::InvalidCommandStatus as u8;
+        header
+    }
+}
+
+#[repr(C, packed)]
+#[derive(Default, FromBytes, IntoBytes)]
+pub(crate) struct Utrd {
+    header: ReqDescHeader,
+    command_desc_base_addr: u64,
+    rsp_upiu_length: u16,
+    rsp_upiu_offset: u16,
+    prd_table_length: u16,
+    prd_table_offset: u16,
+}
+
+pub(crate) type SqEntry = Utrd;
+
+#[repr(C, packed)]
+#[derive(Default, Clone, Copy, FromBytes, IntoBytes)]
+pub(crate) struct CqEntry {
+    command_desc_base_addr: u64,
+    rsp_upiu_length: u16,
+    rsp_upiu_offset: u16,
+    prd_table_length: u16,
+    prd_table_offset: u16,
+    overall_status: u8,
+    extended_error_code: u8,
+    reserved_1: u16,
+    task_tag: u8,
+    lun: u8,
+    iid_ext_iid: u8,
+    reserved_2: u8,
+    reserved_3: [u32; 2],
+}
+
+impl CqEntry {
+    pub(crate) fn command_desc_base_addr(&self) -> u64 {
+        u64::from_le(self.command_desc_base_addr)
+    }
+
+    pub(crate) fn ucd_base_addr(&self) -> u64 {
+        self.command_desc_base_addr() & CQE_UCD_BASE_ADDR
+    }
+
+    pub(crate) fn matches_ucd_base_addr(&self, addr: u64) -> bool {
+        self.ucd_base_addr() == addr & CQE_UCD_BASE_ADDR
+    }
+
+    pub(crate) fn is_empty(&self) -> bool {
+        self.command_desc_base_addr() == 0
+    }
+
+    pub(crate) fn task_tag(&self) -> u8 {
+        self.task_tag
+    }
+
+    pub(crate) fn submission_queue_id(&self) -> u8 {
+        (self.command_desc_base_addr() & CQE_SQ_ID) as u8
+    }
+
+    pub(crate) fn overall_status(&self) -> u8 {
+        self.overall_status
+    }
+}
+
+impl Utrd {
+    pub(crate) fn set_command_descriptor(mut self, command_desc_base_addr: u64) -> Self {
+        self.command_desc_base_addr = command_desc_base_addr.to_le();
+        self.rsp_upiu_length = ((ALIGNED_UPIU_SIZE >> 2) as u16).to_le();
+        self.rsp_upiu_offset = ((ALIGNED_UPIU_SIZE >> 2) as u16).to_le();
+        self.prd_table_offset = ((ALIGNED_UPIU_SIZE >> 1) as u16).to_le();
+        self
+    }
+
+    pub(crate) fn set_prd_table_length(mut self, entries: usize) -> Result<Self> {
+        self.prd_table_length = u16::try_from(entries).map_err(|_| EINVAL)?.to_le();
+        Ok(self)
+    }
+
+    pub(crate) fn build(&self, cmd: UfsCmd) -> Self {
+        let header = match cmd {
+            UfsCmd::Device(_) => ReqDescHeader::device(),
+            UfsCmd::Scsi(cmd) => ReqDescHeader::scsi(cmd),
+        };
+        Self { header, ..*self }
+    }
+
+    pub(crate) fn check_response(&self) -> Result<()> {
+        match self.ocs().into() {
+            UtpOcs::Success => Ok(()),
+            UtpOcs::InvalidCmdTableAttr
+            | UtpOcs::InvalidPrdtAttr
+            | UtpOcs::MismatchDataBufSize
+            | UtpOcs::MisMatchRespUpiuSize
+            | UtpOcs::InvalidCryptoConfig
+            | UtpOcs::GeneralCryptoError => Err(EINVAL),
+            _ => Err(EIO),
+        }
+    }
+
+    pub(crate) fn ocs(&self) -> u8 {
+        self.header.ocs & MASK_OCS
+    }
+}
+
+#[repr(C, packed)]
+#[derive(FromBytes, IntoBytes)]
+pub(crate) struct Utmrd {
+    header: ReqDescHeader,
+    upiu_req: UpiuTmReq,
+    upiu_rsp: UpiuTmRsp,
+}
+
+const _: () = assert!(size_of::<ReqDescHeader>() == 16);
+const _: () = assert!(size_of::<PrdEntry>() == 16);
+const _: () = assert!(size_of::<CqEntry>() == 32);
+const _: () = assert!(size_of::<Ucd>() == 5120);
+const _: () = assert!(size_of::<Utrd>() == 32);
+const _: () = assert!(size_of::<Utmrd>() == 80);
diff --git a/drivers/rufs/host.rs b/drivers/rufs/host.rs
new file mode 100644
index 0000000000000..f813a4b26da85
--- /dev/null
+++ b/drivers/rufs/host.rs
@@ -0,0 +1,340 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! UfsHost: Top-level host controller manager.
+
+#![allow(dead_code)]
+
+use kernel::io::poll::read_poll_timeout;
+use kernel::sync::{Arc, Mutex, SpinLock};
+use kernel::time::{delay::*, Delta};
+use kernel::types::ScopeGuard;
+use kernel::{irq, new_mutex, new_spinlock, prelude::*};
+use pin_init::pin_init_scope;
+
+use crate::device::*;
+use crate::dma::*;
+use crate::irq::*;
+use crate::lu::*;
+use crate::queue::*;
+use crate::reg::*;
+use crate::resource::HostResources;
+use crate::transport::UfsTransferConfig;
+use crate::uic::*;
+use crate::variant::NotifyPhase;
+
+const HBA_ENABLE_DELAY_US: i64 = 1000;
+const LINK_STARTUP_RETRIES: usize = 3;
+const SHUTDOWN_DRAIN_INTERVAL_MS: i64 = 1;
+const SHUTDOWN_DRAIN_TIMEOUT_SECS: i64 = 30;
+
+fn stop_hba_controller(reg: &UfsReg) {
+    if !reg.ctrl_enabled() {
+        return;
+    }
+
+    reg.disable_interrupts();
+    reg.clear_all_interrupts();
+    reg.disable_run_stop();
+    reg.ctrl_disable();
+    if let Err(e) = reg.wait_for_ctrl_disable(10, 1) {
+        pr_err!(
+            "[RUFS] ufs_host: controller disable failed errno={}\n",
+            e.to_errno()
+        );
+    }
+}
+
+fn enable_hba_controller(resources: &HostResources, reg: &UfsReg) -> Result {
+    resources.variant().device_reset()?;
+    resources
+        .variant()
+        .hce_enable_notify(reg, NotifyPhase::Pre)?;
+    reg.ctrl_enable();
+    fsleep(Delta::from_micros(HBA_ENABLE_DELAY_US));
+    reg.wait_for_ctrl_enable(1000, 50)?;
+    resources
+        .variant()
+        .hce_enable_notify(reg, NotifyPhase::Post)
+}
+
+fn start_link(resources: &HostResources, reg: &UfsReg, uic: &Arc<UfsUic>) -> Result<bool> {
+    resources
+        .variant()
+        .link_startup_notify(reg, uic, NotifyPhase::Pre)?;
+    uic.link_startup()?;
+    resources
+        .variant()
+        .link_startup_notify(reg, uic, NotifyPhase::Post)?;
+    resources.variant().link_startup_valid(uic)
+}
+
+#[derive(Clone, Copy, Debug, PartialEq, Eq)]
+pub(crate) enum HostState {
+    Starting,
+    Operational,
+    Stopping,
+    Stopped,
+}
+
+#[pin_data(PinnedDrop)]
+pub(crate) struct UfsHost<'a> {
+    resources: Arc<HostResources>,
+    reg: Arc<UfsReg>,
+    dma: Arc<UfsDma>,
+    irq: Arc<UfsIrq<'a>>,
+    uic: Arc<UfsUic>,
+    queue: Arc<UfsQueue>,
+    dev: Arc<UfsDev>,
+
+    #[pin]
+    luns: Mutex<KVec<Arc<UfsLu>>>,
+
+    max_hw_queues: u16,
+    max_prdt_entries: u16,
+
+    #[pin]
+    state: SpinLock<HostState>,
+}
+
+impl<'a> UfsHost<'a> {
+    pub(crate) fn new(
+        resources: Arc<HostResources>,
+        uic_irq: irq::IrqRequest<'a>,
+        queue_irq: irq::IrqRequest<'a>,
+    ) -> impl PinInit<Self, Error> + 'a {
+        pin_init_scope(move || {
+            let reg = UfsReg::new(resources.clone())?;
+            resources.variant().initialize(&reg)?;
+
+            let cleanup_resources = resources.clone();
+            let cleanup_reg = reg.clone();
+            let init_guard = ScopeGuard::new(move || {
+                stop_hba_controller(&cleanup_reg);
+                cleanup_resources.variant().shutdown(&cleanup_reg);
+            });
+
+            let transfer_config = UfsTransferConfig::new(&reg)?;
+            let dma = UfsDma::new(
+                resources.device(),
+                reg.clone(),
+                transfer_config.queue_depth(),
+            )?;
+
+            reg.clear_all_interrupts();
+            reg.disable_interrupts();
+
+            let irq = UfsIrq::new()?;
+            let uic = UfsUic::new(reg.clone())?;
+            let interrupt_policy = match transfer_config {
+                UfsTransferConfig::Sdb { .. } => UfsInterruptPolicy::EagerAck,
+                UfsTransferConfig::Mcq(_) => UfsInterruptPolicy::ThreadedAck,
+            };
+
+            if reg.ctrl_enabled() {
+                stop_hba_controller(&reg);
+            }
+
+            enable_hba_controller(&resources, &reg)?;
+
+            /* ufshcd_link_startup() */
+            irq.request_uic_irq(uic_irq, reg.clone(), uic.clone(), interrupt_policy)?;
+            let mut retries = LINK_STARTUP_RETRIES;
+            loop {
+                match start_link(&resources, &reg, &uic)? {
+                    true => break,
+                    false if retries > 0 => {
+                        pr_warn!(
+                            "[RUFS] ufs_host: retry degraded link, retries_left={}\n",
+                            retries,
+                        );
+                        retries -= 1;
+                        stop_hba_controller(&reg);
+                        enable_hba_controller(&resources, &reg)?;
+                    }
+                    false => return Err(EIO),
+                }
+            }
+            dma.make_hba_operational()?;
+
+            let ufs_queue = UfsQueue::new(
+                transfer_config,
+                resources.clone(),
+                reg.clone(),
+                dma.clone(),
+                uic.clone(),
+            )?;
+            let dev = UfsDev::new(ufs_queue.clone())?;
+            let host = try_pin_init!(Self {
+                resources,
+                reg,
+                dma,
+                irq,
+                uic,
+                queue: ufs_queue,
+                dev,
+                luns <- new_mutex!(KVec::new()),
+                state <- new_spinlock!(HostState::Starting),
+                max_hw_queues: 1,
+                max_prdt_entries: 256,
+            })
+            .pin_chain(move |host| {
+                init_guard.dismiss();
+
+                /* ufshcd_verify_dev_init */
+                host.irq.request_queue_irq(
+                    queue_irq,
+                    host.reg.clone(),
+                    host.queue.clone(),
+                    interrupt_policy,
+                )?;
+                // Transfer and backend completion interrupts must not become
+                // visible before their handler owns a live queue.
+                host.queue.enable_interrupts();
+                host.dev.verify_dev_init()?;
+                host.dev.complete_dev_init()?;
+                host.dev.device_params_init()?;
+                if let Err(e) = host.configure_power_mode() {
+                    pr_warn!("rufs: power mode configuration failed: {}\n", e.to_errno(),);
+                }
+                host.alloc_luns()?;
+                host.dev.alloc_tmf_queue(host.reg.nutmrs())?;
+                host.promote_to_operational()?;
+                Ok(())
+            });
+
+            Ok(host)
+        })
+    }
+
+    fn configure_power_mode(&self) -> Result<()> {
+        let variant = self.resources.variant();
+        let mode = variant.constrain_power_mode(self.uic.max_power_mode()?)?;
+
+        variant.power_mode_notify(&self.reg, &self.uic, mode, NotifyPhase::Pre)?;
+        self.uic.change_power_mode(mode)?;
+        variant.power_mode_notify(&self.reg, &self.uic, mode, NotifyPhase::Post)
+    }
+
+    fn alloc_luns(&self) -> Result<()> {
+        let num_lu = self.dev.num_lu();
+        let mut luns = self.luns.lock();
+        let mut lun = 0;
+
+        while lun < num_lu {
+            let lun_id = u8::try_from(lun).map_err(|_| EOVERFLOW)?;
+            let desc = self.dev.read_unit_desc(lun_id)?;
+
+            if !desc.enabled() {
+                lun = lun.checked_add(1).ok_or(EOVERFLOW)?;
+                continue;
+            }
+
+            let geometry = UfsLuGeometry::from_logical_block_shift(
+                desc.logical_block_shift(),
+                desc.logical_block_count(),
+            )?;
+            let queue_depth = match desc.lu_queue_depth() {
+                0 => self.queue.tags.queue_depth(),
+                depth => core::cmp::min(depth as u32, self.queue.tags.queue_depth()),
+            };
+            let lu = UfsLu::new(self.queue.clone(), lun_id, geometry, queue_depth)?;
+            lu.init_disk()?;
+
+            pr_info!(
+                "rufs: LU {} capacity={} block_size={} queue_depth={}\n",
+                lun,
+                geometry.capacity_blocks(),
+                geometry.logical_block_size(),
+                queue_depth,
+            );
+
+            luns.push(lu, GFP_KERNEL)?;
+            lun = lun.checked_add(1).ok_or(EOVERFLOW)?;
+        }
+
+        Ok(())
+    }
+
+    pub(crate) fn request_mcq_queue_irqs<F>(&self, request: F) -> Result<()>
+    where
+        F: FnMut() -> Result<irq::IrqRequest<'a>>,
+    {
+        self.irq
+            .request_mcq_queue_irqs(self.queue.clone(), self.queue.interrupt_queues(), request)
+    }
+
+    pub(crate) fn shutdown(&self) {
+        if !self.begin_shutdown() {
+            return;
+        }
+
+        // Removing a disk may submit final filesystem writeback. Keep the
+        // request queues and completion path operational until every disk has
+        // been marked dead and its final I/O has completed.
+        self.remove_luns();
+
+        self.queue.begin_shutdown();
+        if let Err(e) = read_poll_timeout(
+            || Ok(self.queue.busy_requests()),
+            |active| *active == 0,
+            Delta::from_millis(SHUTDOWN_DRAIN_INTERVAL_MS),
+            Delta::from_secs(SHUTDOWN_DRAIN_TIMEOUT_SECS),
+        ) {
+            pr_err!(
+                "[RUFS] ufs_host: timed out draining {} commands errno={}\n",
+                self.queue.busy_requests(),
+                e.to_errno(),
+            );
+        }
+        self.queue.wait_completed_requests();
+
+        self.reg.disable_interrupts();
+        self.irq.shutdown();
+        self.queue.flush_recovery_work();
+        stop_hba_controller(&self.reg);
+        self.resources.variant().shutdown(&self.reg);
+        self.finish_shutdown();
+    }
+
+    fn remove_luns(&self) {
+        let mut luns = self.luns.lock();
+        for lu in luns.iter() {
+            lu.remove_disk();
+        }
+        luns.clear();
+    }
+
+    fn promote_to_operational(&self) -> Result<()> {
+        let mut state = self.state.lock();
+        if *state != HostState::Starting {
+            return Err(EINVAL);
+        }
+        *state = HostState::Operational;
+        Ok(())
+    }
+
+    fn begin_shutdown(&self) -> bool {
+        let mut state = self.state.lock();
+        match *state {
+            HostState::Starting | HostState::Operational => {
+                *state = HostState::Stopping;
+                true
+            }
+            HostState::Stopping | HostState::Stopped => false,
+        }
+    }
+
+    fn finish_shutdown(&self) {
+        let mut state = self.state.lock();
+        if *state == HostState::Stopping {
+            *state = HostState::Stopped;
+        }
+    }
+}
+
+#[pinned_drop]
+impl PinnedDrop for UfsHost<'_> {
+    fn drop(self: Pin<&mut Self>) {
+        self.shutdown();
+    }
+}
diff --git a/drivers/rufs/irq.rs b/drivers/rufs/irq.rs
new file mode 100644
index 0000000000000..4a1b5bcacaff0
--- /dev/null
+++ b/drivers/rufs/irq.rs
@@ -0,0 +1,402 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#![allow(dead_code)]
+
+use crate::queue::*;
+use crate::reg::*;
+use crate::transport::McqInterruptQueue;
+use crate::uic::*;
+use kernel::irq::{self, Flags, IrqRequest, IrqReturn, ThreadedIrqReturn};
+use kernel::sync::atomic::{Acquire, Atomic, Relaxed, Release};
+use kernel::sync::{Arc, Mutex};
+use kernel::{c_str, new_mutex, prelude::*};
+
+#[derive(Clone, Copy)]
+pub(crate) enum UfsInterruptPolicy {
+    EagerAck,
+    ThreadedAck,
+}
+
+#[pin_data]
+struct UfsUicHandler {
+    reg: Arc<UfsReg>,
+    uic: Arc<UfsUic>,
+    policy: UfsInterruptPolicy,
+    pending_interrupts: Atomic<u32>,
+}
+
+#[pin_data]
+struct UfsQueueHandler {
+    reg: Arc<UfsReg>,
+    queue: Arc<UfsQueue>,
+    policy: UfsInterruptPolicy,
+    pending_interrupts: Atomic<u32>,
+    per_queue_irqs_active: Atomic<bool>,
+}
+
+#[pin_data]
+struct UfsMcqQueueHandler {
+    queue: Arc<UfsQueue>,
+    interrupt_queue: McqInterruptQueue,
+}
+
+impl UfsMcqQueueHandler {
+    fn new(queue: Arc<UfsQueue>, interrupt_queue: McqInterruptQueue) -> impl PinInit<Self, Error> {
+        try_pin_init!(Self {
+            queue,
+            interrupt_queue,
+        })
+    }
+}
+
+fn record_pending_interrupts(pending_interrupts: &Atomic<u32>, interrupt_status: u32) {
+    let mut pending = pending_interrupts.load(Relaxed);
+    loop {
+        match pending_interrupts.cmpxchg(pending, pending | interrupt_status, Release) {
+            Ok(_) => break,
+            Err(current) => pending = current,
+        }
+    }
+}
+
+fn registration_flags(policy: UfsInterruptPolicy) -> Flags {
+    match policy {
+        UfsInterruptPolicy::EagerAck => Flags::SHARED,
+        UfsInterruptPolicy::ThreadedAck => Flags::SHARED | Flags::ONESHOT,
+    }
+}
+
+fn warn_mcq_irq_fallback(stage: &str, error: Error) {
+    pr_warn!(
+        "[RUFS] ufs_irq: per-CQ IRQ {} failed errno={}, use global completion handler\n",
+        stage,
+        error.to_errno(),
+    );
+}
+
+impl irq::ThreadedHandler for UfsUicHandler {
+    fn handle(&self) -> ThreadedIrqReturn {
+        let interrupt_status = self.reg.read_uic_interrupts();
+        if interrupt_status == 0 {
+            return ThreadedIrqReturn::None;
+        }
+
+        record_pending_interrupts(&self.pending_interrupts, interrupt_status);
+
+        if matches!(self.policy, UfsInterruptPolicy::EagerAck) {
+            self.reg.confirm_uic_interrupts(interrupt_status);
+        }
+
+        ThreadedIrqReturn::WakeThread
+    }
+
+    fn handle_threaded(&self) -> IrqReturn {
+        loop {
+            let interrupt_status = self.pending_interrupts.xchg(0, Acquire);
+            if interrupt_status == 0 {
+                break;
+            }
+
+            if matches!(self.policy, UfsInterruptPolicy::ThreadedAck) {
+                self.reg.confirm_uic_interrupts(interrupt_status);
+            }
+
+            if self.uic.handle_uic_completion(interrupt_status) {
+                self.uic.complete_uic_cmd();
+            }
+        }
+
+        IrqReturn::Handled
+    }
+}
+
+impl irq::ThreadedHandler for UfsQueueHandler {
+    fn handle(&self) -> ThreadedIrqReturn {
+        let interrupt_status = self.reg.read_transfer_interrupts();
+        if interrupt_status == 0 {
+            return ThreadedIrqReturn::None;
+        }
+
+        match self.policy {
+            UfsInterruptPolicy::EagerAck => {
+                // SDB completion identity remains available in the doorbell
+                // and outstanding bitmap after global status is cleared.
+                self.reg.confirm_transfer_interrupts(interrupt_status);
+            }
+            UfsInterruptPolicy::ThreadedAck => {
+                // Latch and clear the global MCQ event before any threaded
+                // action runs. A later CQ event can then assert a new IRQ.
+                self.reg.confirm_mcq_cq_events(interrupt_status);
+
+                // Per-CQ handlers own normal MCQ completion processing after
+                // activation. Keep the global action handled for controllers
+                // that also report CQES for poll queues, but do not wake its
+                // thread unless a deferred transfer or error event needs it.
+                if self.per_queue_irqs_active.load(Acquire)
+                    && !has_deferred_transfer_interrupts(interrupt_status)
+                {
+                    return ThreadedIrqReturn::Handled;
+                }
+            }
+        }
+
+        record_pending_interrupts(&self.pending_interrupts, interrupt_status);
+
+        if is_error_interrupt(interrupt_status) {
+            pr_warn!(
+                "[RUFS] ufs_irq: transfer/error interrupt status=0x{:x}\n",
+                interrupt_status
+            );
+        }
+
+        ThreadedIrqReturn::WakeThread
+    }
+
+    fn handle_threaded(&self) -> IrqReturn {
+        loop {
+            let interrupt_status = self.pending_interrupts.xchg(0, Acquire);
+            if interrupt_status == 0 {
+                break;
+            }
+
+            let uic_errors = if is_uic_error_interrupt(interrupt_status) {
+                Some(self.reg.read_uic_errors())
+            } else {
+                None
+            };
+
+            if matches!(self.policy, UfsInterruptPolicy::ThreadedAck) {
+                self.reg
+                    .confirm_deferred_transfer_interrupts(interrupt_status);
+            }
+
+            if let Some(errors) = uic_errors {
+                pr_warn!(
+                    "[RUFS] ufs_irq: UIC error phy=0x{:08x} dl=0x{:08x} nl=0x{:08x} tl=0x{:08x} dme=0x{:08x}\n",
+                    errors.phy,
+                    errors.data_link,
+                    errors.network,
+                    errors.transport,
+                    errors.dme,
+                );
+                if errors.requires_recovery() {
+                    self.queue.require_uic_recovery(errors);
+                }
+            }
+            if is_transfer_recovery_interrupt(interrupt_status) {
+                self.queue.require_recovery("transfer error interrupt", 0);
+            }
+            if !self.per_queue_irqs_active.load(Acquire) {
+                self.queue.complete();
+            }
+        }
+
+        IrqReturn::Handled
+    }
+}
+
+impl irq::ThreadedHandler for UfsMcqQueueHandler {
+    fn handle(&self) -> ThreadedIrqReturn {
+        match self.interrupt_queue.acknowledge_completion() {
+            Ok(true) | Err(_) => ThreadedIrqReturn::WakeThread,
+            Ok(false) => ThreadedIrqReturn::None,
+        }
+    }
+
+    fn handle_threaded(&self) -> IrqReturn {
+        self.queue.complete_queue(&self.interrupt_queue);
+        IrqReturn::Handled
+    }
+}
+
+#[pin_data]
+pub(crate) struct UfsIrq<'a> {
+    #[pin]
+    uic: Mutex<Option<Arc<irq::ThreadedRegistration<'a, UfsUicHandler>>>>,
+    #[pin]
+    queue: Mutex<Option<Arc<irq::ThreadedRegistration<'a, UfsQueueHandler>>>>,
+    #[pin]
+    mcq_queues: Mutex<KVec<Arc<irq::ThreadedRegistration<'a, UfsMcqQueueHandler>>>>,
+}
+
+impl<'a> UfsIrq<'a> {
+    pub(crate) fn new() -> Result<Arc<Self>> {
+        Arc::pin_init(
+            try_pin_init!(Self {
+                uic <- new_mutex!(None),
+                queue <- new_mutex!(None),
+                mcq_queues <- new_mutex!(KVec::new()),
+            }),
+            GFP_KERNEL,
+        )
+    }
+
+    pub(crate) fn request_uic_irq(
+        &self,
+        request: IrqRequest<'a>,
+        reg: Arc<UfsReg>,
+        uic: Arc<UfsUic>,
+        policy: UfsInterruptPolicy,
+    ) -> Result<()> {
+        let handler = try_pin_init!(UfsUicHandler {
+            reg,
+            uic,
+            policy,
+            pending_interrupts: Atomic::new(0),
+        });
+
+        // SAFETY: The registration is stored until shutdown and cannot be
+        // forgotten while its handler is registered.
+        let irq = unsafe {
+            irq::ThreadedRegistration::new(
+                request,
+                registration_flags(policy),
+                c_str!("rufs-uic"),
+                handler,
+            )
+        };
+
+        let reg = Arc::pin_init(irq, GFP_KERNEL)?;
+        self.uic.lock().replace(reg);
+
+        Ok(())
+    }
+
+    pub(crate) fn request_queue_irq(
+        &self,
+        request: IrqRequest<'a>,
+        reg: Arc<UfsReg>,
+        queue: Arc<UfsQueue>,
+        policy: UfsInterruptPolicy,
+    ) -> Result<()> {
+        let handler = try_pin_init!(UfsQueueHandler {
+            reg,
+            queue,
+            policy,
+            pending_interrupts: Atomic::new(0),
+            per_queue_irqs_active: Atomic::new(false),
+        });
+
+        // SAFETY: The registration is stored until shutdown and cannot be
+        // forgotten while its handler is registered.
+        let irq = unsafe {
+            irq::ThreadedRegistration::new(
+                request,
+                registration_flags(policy),
+                c_str!("rufs-queue"),
+                handler,
+            )
+        };
+
+        let reg = Arc::pin_init(irq, GFP_KERNEL)?;
+        self.queue.lock().replace(reg);
+
+        Ok(())
+    }
+
+    pub(crate) fn request_mcq_queue_irqs<F>(
+        &self,
+        queue: Arc<UfsQueue>,
+        interrupt_queues: &[McqInterruptQueue],
+        mut request: F,
+    ) -> Result<()>
+    where
+        F: FnMut() -> Result<IrqRequest<'a>>,
+    {
+        if interrupt_queues.is_empty() {
+            return Ok(());
+        }
+
+        let queue_irq = self.queue.lock().as_ref().cloned().ok_or(ENODEV)?;
+        if !self.mcq_queues.lock().is_empty() {
+            return Err(EBUSY);
+        }
+        let mut registrations = KVec::new();
+
+        for interrupt_queue in interrupt_queues {
+            let handler =
+                UfsMcqQueueHandler::new(queue.clone(), McqInterruptQueue::clone(interrupt_queue));
+            let request = match request() {
+                Ok(request) => request,
+                Err(e) => {
+                    warn_mcq_irq_fallback("setup", e);
+                    return Ok(());
+                }
+            };
+            // SAFETY: The registration is stored until shutdown and cannot be
+            // forgotten while its handler is registered.
+            let irq = unsafe {
+                irq::ThreadedRegistration::new(
+                    request,
+                    Flags::SHARED | Flags::ONESHOT,
+                    c_str!("rufs-mcq-cq"),
+                    handler,
+                )
+            };
+            let registration = match Arc::pin_init(irq, GFP_KERNEL) {
+                Ok(registration) => registration,
+                Err(e) => {
+                    warn_mcq_irq_fallback("setup", e);
+                    return Ok(());
+                }
+            };
+            if let Err(e) = registrations.push(registration, GFP_KERNEL) {
+                warn_mcq_irq_fallback("setup", e.into());
+                return Ok(());
+            }
+        }
+
+        {
+            let mut mcq_queues = self.mcq_queues.lock();
+            if !mcq_queues.is_empty() {
+                return Err(EBUSY);
+            }
+            *mcq_queues = registrations;
+        }
+        queue_irq
+            .handler()
+            .per_queue_irqs_active
+            .store(true, Release);
+
+        // Close the transition race with completions that became pending
+        // before their per-CQ action was visible on the shared IRQ.
+        let wake_result = {
+            let mcq_queues = self.mcq_queues.lock();
+            let mut result = Ok(());
+            for registration in mcq_queues.iter() {
+                if let Err(e) = registration.wake_thread() {
+                    result = Err(e);
+                    break;
+                }
+            }
+            result
+        };
+        if let Err(e) = wake_result {
+            queue_irq
+                .handler()
+                .per_queue_irqs_active
+                .store(false, Release);
+            let registrations = core::mem::take(&mut *self.mcq_queues.lock());
+            drop(registrations);
+            warn_mcq_irq_fallback("activation", e);
+            return Ok(());
+        }
+
+        pr_info!(
+            "[RUFS] ufs_irq: registered {} per-CQ handlers on shared IRQ\n",
+            interrupt_queues.len(),
+        );
+        Ok(())
+    }
+
+    pub(crate) fn shutdown(&self) {
+        // Drop outside the registration locks because `free_irq()` waits for
+        // the corresponding primary and threaded handlers to finish.
+        let mcq_queues = core::mem::take(&mut *self.mcq_queues.lock());
+        let queue = self.queue.lock().take();
+        let uic = self.uic.lock().take();
+        drop(mcq_queues);
+        drop(queue);
+        drop(uic);
+    }
+}
diff --git a/drivers/rufs/lu.rs b/drivers/rufs/lu.rs
new file mode 100644
index 0000000000000..4363ac92a70f8
--- /dev/null
+++ b/drivers/rufs/lu.rs
@@ -0,0 +1,564 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! Per-logical-unit state for the Rust UFS driver.
+
+#![allow(dead_code)]
+
+use crate::dma::{MAX_PRD_ENTRIES, PRDT_DATA_BYTE_COUNT_MAX};
+use crate::protocol::scsi::UfsSCSICmd;
+use crate::queue::*;
+use crate::transport::UfsHwQueue;
+use kernel::bindings;
+use kernel::block::error::code::BLK_STS_IOERR;
+use kernel::block::mq::gen_disk::BoundGenDisk;
+use kernel::block::mq::LimitsBuilder;
+use kernel::sync::{Arc, Mutex, SpinLock, SpinLockIrq};
+use kernel::types::{OwnableRefCounted, Owned};
+use kernel::{
+    block::{
+        error::BlkResult,
+        mq::{
+            self, dma_map_iter::DmaMapMempool, gen_disk::GenDisk, IdleRequest, Operations,
+            RequestQueue, TagSet,
+        },
+        SECTOR_SIZE,
+    },
+    sync::aref::ARef,
+};
+use kernel::{new_mutex, new_spinlock, new_spinlock_irq, prelude::*};
+
+const SECTOR_SIZE_U64: u64 = SECTOR_SIZE as u64;
+const MAX_DISCARD_SEGMENTS: u16 = 1;
+const MAX_SECTORS: u32 = 1024 * 1024 / 512;
+
+#[derive(Clone, Copy, Debug, Eq, PartialEq)]
+pub(crate) enum UfsLuState {
+    Reset,
+    Operational,
+    Error,
+}
+
+#[derive(Clone, Copy, Debug)]
+pub(crate) struct UfsLuGeometry {
+    logical_block_size: u32,
+    physical_block_size: u32,
+    alignment: u32,
+    capacity_blocks: u64,
+    sectors_per_block: u64,
+}
+
+impl UfsLuGeometry {
+    pub(crate) fn new(
+        logical_block_size: u32,
+        physical_block_size: u32,
+        alignment: u32,
+        capacity_blocks: u64,
+    ) -> Result<Self> {
+        if logical_block_size < SECTOR_SIZE
+            || logical_block_size % SECTOR_SIZE != 0
+            || !logical_block_size.is_power_of_two()
+        {
+            return Err(EINVAL);
+        }
+
+        if physical_block_size != 0
+            && (physical_block_size < logical_block_size
+                || physical_block_size % logical_block_size != 0)
+        {
+            return Err(EINVAL);
+        }
+
+        Ok(Self {
+            logical_block_size,
+            physical_block_size: if physical_block_size == 0 {
+                logical_block_size
+            } else {
+                physical_block_size
+            },
+            alignment,
+            capacity_blocks,
+            sectors_per_block: u64::from(logical_block_size / SECTOR_SIZE),
+        })
+    }
+
+    pub(crate) fn from_logical_block_shift(
+        logical_block_shift: u8,
+        capacity_blocks: u64,
+    ) -> Result<Self> {
+        let logical_block_size = 1u32
+            .checked_shl(u32::from(logical_block_shift))
+            .ok_or(EINVAL)?;
+
+        Self::new(logical_block_size, logical_block_size, 0, capacity_blocks)
+    }
+
+    pub(crate) fn logical_block_size(&self) -> u32 {
+        self.logical_block_size
+    }
+
+    pub(crate) fn physical_block_size(&self) -> u32 {
+        self.physical_block_size
+    }
+
+    pub(crate) fn alignment(&self) -> u32 {
+        self.alignment
+    }
+
+    pub(crate) fn capacity_blocks(&self) -> u64 {
+        self.capacity_blocks
+    }
+
+    pub(crate) fn sectors_per_block(&self) -> u64 {
+        self.sectors_per_block
+    }
+
+    pub(crate) fn capacity_sectors(&self) -> Option<u64> {
+        self.capacity_blocks.checked_mul(self.sectors_per_block)
+    }
+
+    pub(crate) fn max_discard_sectors(&self) -> Result<u32> {
+        let sectors_per_block = u32::try_from(self.sectors_per_block).map_err(|_| EOVERFLOW)?;
+        let remainder = u32::MAX.checked_rem(sectors_per_block).ok_or(EINVAL)?;
+
+        u32::MAX.checked_sub(remainder).ok_or(EOVERFLOW)
+    }
+
+    pub(crate) fn sectors_to_logical(&self, sectors: u64) -> u64 {
+        sectors / self.sectors_per_block
+    }
+
+    pub(crate) fn logical_to_sectors(&self, blocks: u64) -> Option<u64> {
+        blocks.checked_mul(self.sectors_per_block)
+    }
+
+    pub(crate) fn bytes_to_logical(&self, bytes: u64) -> u64 {
+        self.sectors_to_logical(bytes / SECTOR_SIZE_U64)
+    }
+
+    pub(crate) fn logical_to_bytes(&self, blocks: u64) -> Option<u64> {
+        self.logical_to_sectors(blocks)?
+            .checked_mul(SECTOR_SIZE_U64)
+    }
+}
+
+#[pin_data]
+pub(crate) struct UfsLu {
+    pub(crate) queue: Arc<UfsQueue>,
+    lun: u8,
+    geometry: UfsLuGeometry,
+    queue_depth: u32,
+
+    #[pin]
+    state: SpinLock<UfsLuState>,
+
+    #[pin]
+    disk: Mutex<Option<BoundGenDisk<UfsLuBlockOps>>>,
+}
+
+impl UfsLu {
+    pub(crate) fn new(
+        queue: Arc<UfsQueue>,
+        lun: u8,
+        geometry: UfsLuGeometry,
+        queue_depth: u32,
+    ) -> Result<Arc<Self>> {
+        Arc::pin_init(
+            try_pin_init!(Self {
+                queue,
+                lun,
+                geometry,
+                queue_depth,
+                state <- new_spinlock!(UfsLuState::Reset),
+                disk <- new_mutex!(None),
+            }),
+            GFP_KERNEL,
+        )
+    }
+
+    pub(crate) fn init_disk(self: &Arc<Self>) -> Result<()> {
+        let capacity_sectors = self.geometry.capacity_sectors().ok_or(EOVERFLOW)?;
+
+        let limits = LimitsBuilder::<UfsLuBlockOps>::new()
+            .logical_block_size(self.geometry.logical_block_size())?
+            .physical_block_size(self.geometry.physical_block_size())?
+            .max_hw_discard_sectors(self.geometry.max_discard_sectors()?)
+            .discard_granularity(self.geometry.logical_block_size())
+            .max_discard_segments(MAX_DISCARD_SEGMENTS)
+            .max_hw_sectors(MAX_SECTORS)
+            .max_segments(u16::try_from(MAX_PRD_ENTRIES).map_err(|_| EOVERFLOW)?)
+            .max_segment_size(PRDT_DATA_BYTE_COUNT_MAX)
+            .build()?;
+
+        let request_queue = RequestQueue::new(
+            self.queue.tags.clone(),
+            limits,
+            KBox::new(QueueData::lu(self.clone()), GFP_KERNEL)?,
+            self.queue_depth,
+        )?;
+
+        let disk =
+            GenDisk::new_for_queue(fmt!("ufs{}", self.lun), request_queue, capacity_sectors, ())?;
+
+        let mut current = self.disk.lock();
+        if current.is_some() {
+            return Err(EBUSY);
+        }
+
+        current.replace(disk);
+        self.set_state(UfsLuState::Operational);
+        Ok(())
+    }
+
+    pub(crate) fn remove_disk(&self) {
+        self.set_state(UfsLuState::Reset);
+        let disk = self.disk.lock().take();
+        drop(disk);
+    }
+
+    pub(crate) fn lun(&self) -> u8 {
+        self.lun
+    }
+
+    pub(crate) fn geometry(&self) -> UfsLuGeometry {
+        self.geometry
+    }
+
+    pub(crate) fn state(&self) -> UfsLuState {
+        *self.state.lock()
+    }
+
+    pub(crate) fn set_state(&self, state: UfsLuState) {
+        *self.state.lock() = state;
+    }
+
+    pub(crate) fn is_operational(&self) -> bool {
+        self.state() == UfsLuState::Operational
+    }
+
+    fn build_scsi_cmd(&self, command: mq::Command, lba: u64, blocks: u64) -> Result<UfsSCSICmd> {
+        let blocks = u32::try_from(blocks).map_err(|_| EINVAL)?;
+        let data_len = u32::try_from(
+            u64::from(self.geometry.logical_block_size())
+                .checked_mul(u64::from(blocks))
+                .ok_or(EOVERFLOW)?,
+        )
+        .map_err(|_| EOVERFLOW)?;
+
+        match command {
+            mq::Command::Read => Ok(UfsSCSICmd::read_write(
+                self.lun, false, lba, blocks, data_len, false,
+            )),
+            mq::Command::Write => Ok(UfsSCSICmd::read_write(
+                self.lun, true, lba, blocks, data_len, false,
+            )),
+            mq::Command::Flush => Ok(UfsSCSICmd::flush(self.lun)),
+            mq::Command::Discard => Ok(UfsSCSICmd::unmap(self.lun, lba, blocks)),
+            _ => Err(ENOTSUPP),
+        }
+    }
+}
+
+pub(crate) struct UfsLuBlockOps;
+
+// Hand a request that never reached the device back to the block layer.
+//
+// Because the command was not submitted, no hardware completion can race with
+// returning the request to blk-mq.
+fn complete_unsubmitted(rq: Owned<mq::Request<UfsLuBlockOps>>, e: Error) {
+    rq.data_ref().inner.lock().reset();
+
+    if e == EBUSY {
+        rq.requeue(true);
+    } else {
+        rq.end(bindings::BLK_STS_IOERR);
+    }
+}
+
+#[pin_data]
+pub(crate) struct UfsRequestData {
+    #[pin]
+    pub(crate) inner: SpinLockIrq<UfsRequestInner>,
+}
+
+pub(crate) struct TagSetData {
+    pub(crate) dma_vec_mempool: DmaMapMempool<MAX_PRD_ENTRIES>,
+    pub(crate) queue_map: UfsQueueMap,
+    pub(crate) hw_queues: KVec<UfsHwQueue>,
+}
+
+enum QueueOwner {
+    Dev(Arc<UfsQueue>),
+    Lu(Arc<UfsLu>),
+}
+
+pub(crate) struct QueueData {
+    owner: QueueOwner,
+}
+
+impl QueueData {
+    pub(crate) fn dev(queue: Arc<UfsQueue>) -> Self {
+        Self {
+            owner: QueueOwner::Dev(queue),
+        }
+    }
+
+    pub(crate) fn lu(lu: Arc<UfsLu>) -> Self {
+        Self {
+            owner: QueueOwner::Lu(lu),
+        }
+    }
+
+    pub(crate) fn queue(&self) -> &UfsQueue {
+        self.queue_arc()
+    }
+
+    pub(crate) fn queue_arc(&self) -> &Arc<UfsQueue> {
+        match &self.owner {
+            QueueOwner::Dev(queue) => queue,
+            QueueOwner::Lu(lu) => &lu.queue,
+        }
+    }
+
+    pub(crate) fn dev_queue(&self) -> Option<&Arc<UfsQueue>> {
+        match &self.owner {
+            QueueOwner::Dev(queue) => Some(queue),
+            QueueOwner::Lu(_) => None,
+        }
+    }
+
+    pub(crate) fn logical_unit(&self) -> Option<&Arc<UfsLu>> {
+        match &self.owner {
+            QueueOwner::Dev(_) => None,
+            QueueOwner::Lu(lu) => Some(lu),
+        }
+    }
+}
+
+#[vtable]
+impl Operations for UfsLuBlockOps {
+    const MODULE: &'static kernel::ThisModule = crate::RUFS_MODULE;
+
+    type RequestData = UfsRequestData;
+    type QueueData = KBox<QueueData>;
+    type HwData = KBox<UfsHwQueue>;
+    type TagSetData = KBox<TagSetData>;
+    type GenDiskData = ();
+
+    fn new_request_data() -> impl PinInit<Self::RequestData> {
+        pin_init!(UfsRequestData {
+            inner <- new_spinlock_irq!(UfsRequestInner::default()),
+        })
+    }
+
+    fn queue_rq(
+        hw_queue: &UfsHwQueue,
+        lu: &QueueData,
+        rq: Owned<IdleRequest<Self>>,
+        _is_last: bool,
+    ) -> BlkResult {
+        let command = rq.command();
+        let sector = rq.sector();
+        let sectors = rq.sectors();
+
+        let cmd = match command {
+            mq::Command::Read | mq::Command::Write => {
+                let Some(lu) = lu.logical_unit() else {
+                    return Err(BLK_STS_IOERR);
+                };
+                let geometry = lu.geometry();
+                let mask = geometry.sectors_per_block() - 1;
+                if sectors == 0 {
+                    rq.start().end_ok();
+                    return Ok(());
+                }
+
+                if sector.checked_add(u64::from(sectors)).ok_or(EINVAL)?
+                    > geometry.capacity_sectors().ok_or(EOVERFLOW)?
+                {
+                    pr_warn!(
+                        "[RUFS] ufs_lu: request exceeds LU {} capacity sector={} sectors={}\n",
+                        lu.lun(),
+                        sector,
+                        sectors,
+                    );
+                    rq.start().end(bindings::BLK_STS_INVAL);
+                    return Ok(());
+                }
+
+                if (sector & mask) != 0 || (u64::from(sectors) & mask) != 0 {
+                    pr_warn!(
+                        "[RUFS] ufs_lu: unaligned request on LU {} sector={} sectors={} spb={}\n",
+                        lu.lun(),
+                        sector,
+                        sectors,
+                        geometry.sectors_per_block(),
+                    );
+                    rq.start().end(bindings::BLK_STS_INVAL);
+                    return Ok(());
+                }
+
+                let lba = geometry.sectors_to_logical(sector);
+                let blocks = geometry.sectors_to_logical(u64::from(sectors));
+                lu.build_scsi_cmd(command, lba, blocks)?
+            }
+            mq::Command::Flush => {
+                let Some(lu) = lu.logical_unit() else {
+                    return Err(BLK_STS_IOERR);
+                };
+                lu.build_scsi_cmd(command, 0, 0)?
+            }
+            mq::Command::Discard => {
+                let Some(lu) = lu.logical_unit() else {
+                    return Err(BLK_STS_IOERR);
+                };
+                let geometry = lu.geometry();
+                let mask = geometry.sectors_per_block() - 1;
+                if sectors == 0 {
+                    rq.start().end_ok();
+                    return Ok(());
+                }
+
+                if sector.checked_add(u64::from(sectors)).ok_or(EINVAL)?
+                    > geometry.capacity_sectors().ok_or(EOVERFLOW)?
+                {
+                    pr_warn!(
+                        "[RUFS] ufs_lu: discard exceeds LU {} capacity sector={} sectors={}\n",
+                        lu.lun(),
+                        sector,
+                        sectors,
+                    );
+                    rq.start().end(bindings::BLK_STS_INVAL);
+                    return Ok(());
+                }
+
+                if (sector & mask) != 0 || (u64::from(sectors) & mask) != 0 {
+                    pr_warn!(
+                        "[RUFS] ufs_lu: unaligned discard on LU {} sector={} sectors={} spb={}\n",
+                        lu.lun(),
+                        sector,
+                        sectors,
+                        geometry.sectors_per_block(),
+                    );
+                    rq.start().end(bindings::BLK_STS_INVAL);
+                    return Ok(());
+                }
+
+                let lba = geometry.sectors_to_logical(sector);
+                let blocks = geometry.sectors_to_logical(u64::from(sectors));
+                lu.build_scsi_cmd(command, lba, blocks)?
+            }
+            mq::Command::DriverIn | mq::Command::DriverOut => {
+                let rq = rq.start();
+                if let Err(e) = UfsRequestData::compose_dev_request(&rq) {
+                    complete_unsubmitted(rq, e);
+                    return Ok(());
+                }
+                if let Err((rq, e)) = UfsRequestData::submit(rq, hw_queue) {
+                    complete_unsubmitted(rq, e);
+                }
+                return Ok(());
+            }
+            _ => {
+                pr_warn!("[RUFS] ufs_lu: unsupported request command={:?}\n", command,);
+                rq.start().end(bindings::BLK_STS_NOTSUPP);
+                return Ok(());
+            }
+        };
+
+        let rq = rq.start();
+
+        if let Err(e) = UfsRequestData::compose_scsi_cmd(&rq, cmd) {
+            complete_unsubmitted(rq, e);
+            return Ok(());
+        }
+
+        if let Err((rq, e)) = UfsRequestData::submit(rq, hw_queue) {
+            complete_unsubmitted(rq, e);
+        }
+
+        Ok(())
+    }
+
+    fn commit_rqs(_hw_data: &UfsHwQueue, _queue_data: &QueueData) {}
+
+    fn init_hctx(tagset_data: &TagSetData, hctx_idx: u32) -> Result<Self::HwData> {
+        let hw_queue = tagset_data
+            .hw_queues
+            .get(hctx_idx as usize)
+            .ok_or(EINVAL)?
+            .clone();
+        Ok(KBox::new(hw_queue, GFP_KERNEL)?)
+    }
+
+    fn complete(rq: ARef<mq::Request<Self>>) {
+        let queue = rq.queue_data().queue_arc().clone();
+        let tag = rq.tag() as usize;
+        let rq = match OwnableRefCounted::try_from_shared(rq) {
+            Ok(rq) => rq,
+            Err(_rq) => {
+                pr_err!("[RUFS] ufs_lu: scheduled completion ownership conflict\n");
+                queue.require_recovery("scheduled completion ownership conflict", tag);
+                return;
+            }
+        };
+        let disposition = match rq.data_ref().inner.lock().take_scheduled_completion() {
+            Ok(disposition) => disposition,
+            Err(_) => {
+                pr_err!("[RUFS] ufs_lu: invalid scheduled completion state\n");
+                rq.data_ref().inner.lock().reset();
+                queue.require_recovery("invalid scheduled completion state", tag);
+                CompletionDisposition::End(u32::from(bindings::BLK_STS_IOERR))
+            }
+        };
+
+        match disposition {
+            CompletionDisposition::End(status) => {
+                rq.end(u8::try_from(status).unwrap_or(bindings::BLK_STS_IOERR))
+            }
+            CompletionDisposition::Requeue => rq.requeue(true),
+        }
+    }
+
+    fn request_timeout(
+        tag_set: &TagSet<Self>,
+        _queue_id: u32,
+        tag: u32,
+    ) -> mq::RequestTimeoutStatus {
+        let request = match tag_set.try_shared_tag_to_rq(tag) {
+            Ok(Some(request)) => request,
+            Ok(None) | Err(_) => return mq::RequestTimeoutStatus::RetryLater,
+        };
+        let status = UfsRequestData::timeout(&request, tag);
+
+        if status {
+            mq::RequestTimeoutStatus::Completed
+        } else {
+            mq::RequestTimeoutStatus::RetryLater
+        }
+    }
+
+    fn poll(
+        hw_queue: &UfsHwQueue,
+        queue_data: &QueueData,
+        batch: &mut mq::IoCompletionBatch<Self>,
+    ) -> Result<bool> {
+        let Some(lu) = queue_data.logical_unit() else {
+            return Err(EIO);
+        };
+        Ok(lu.queue.poll(hw_queue, batch))
+    }
+
+    fn map_queues(tag_set: Pin<&mut TagSet<Self>>) {
+        let layout = tag_set.data().queue_map;
+        let result = tag_set.update_maps(|mut qmap| {
+            let range = layout.range(qmap.kind());
+            qmap.set_queue_count(range.count() as u32);
+            qmap.set_offset(range.offset() as u32);
+            qmap.map_queues();
+        });
+
+        if result.is_err() {
+            pr_err!("[RUFS] ufs_lu: failed to update blk-mq queue maps\n");
+        }
+    }
+}
diff --git a/drivers/rufs/protocol.rs b/drivers/rufs/protocol.rs
new file mode 100644
index 0000000000000..e73228a2ce466
--- /dev/null
+++ b/drivers/rufs/protocol.rs
@@ -0,0 +1,28 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! UFS device protocol definitions.
+
+use kernel::prelude::*;
+
+use self::query::UfsDevCmd;
+use self::scsi::UfsSCSICmd;
+
+pub(crate) mod query;
+pub(crate) mod scsi;
+pub(crate) mod upiu;
+
+#[derive(Copy, Clone)]
+#[expect(clippy::large_enum_variant)]
+pub(crate) enum UfsCmd {
+    Device(UfsDevCmd),
+    Scsi(UfsSCSICmd),
+}
+
+impl UfsCmd {
+    pub(crate) fn get_device(&self) -> Result<UfsDevCmd> {
+        match *self {
+            Self::Device(cmd) => Ok(cmd),
+            _ => Err(EINVAL),
+        }
+    }
+}
diff --git a/drivers/rufs/protocol/query.rs b/drivers/rufs/protocol/query.rs
new file mode 100644
index 0000000000000..7c8e4e15827a6
--- /dev/null
+++ b/drivers/rufs/protocol/query.rs
@@ -0,0 +1,645 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! UFS query commands and descriptor definitions.
+
+#![allow(dead_code)]
+
+use super::UfsCmd;
+use kernel::{prelude::*, time::Delta};
+use zerocopy_derive::Immutable;
+
+pub(crate) const QUERY_DESC_MAX_SIZE: usize = 255;
+pub(crate) const UFS_DEV_WRITE_BOOSTER_SUP: u32 = 1 << 8;
+pub(crate) const WB_BUF_MODE_LU_DEDICATED: u8 = 0;
+pub(crate) const WB_BUF_MODE_SHARED: u8 = 1;
+
+#[repr(C)]
+#[derive(Clone, Copy, FromBytes, IntoBytes, Immutable)]
+pub(crate) struct DescBuffer {
+    pub(crate) data: [u8; QUERY_DESC_MAX_SIZE],
+}
+
+const NOP_OUT_TIMEOUT_MS: i64 = 50;
+const QUERY_DEFAULT_TIMEOUT_MS: i64 = 1500;
+const ADVANCDE_RPMB_TIMEOUT_MS: i64 = 3000;
+
+#[derive(Copy, Clone)]
+pub(crate) enum DescIdn {
+    Device = 0x0,
+    Config = 0x1,
+    Unit = 0x2,
+    RFU0 = 0x3,
+    Interconn = 0x4,
+    String = 0x5,
+    RFU1 = 0x6,
+    Geometry = 0x7,
+    Power = 0x8,
+    Health = 0x9,
+    Reserved = 0xFF,
+}
+
+impl From<u8> for DescIdn {
+    fn from(idn: u8) -> Self {
+        match idn {
+            0x0 => Self::Device,
+            0x1 => Self::Config,
+            0x2 => Self::Unit,
+            0x3 => Self::RFU0,
+            0x4 => Self::Interconn,
+            0x5 => Self::String,
+            0x6 => Self::RFU1,
+            0x7 => Self::Geometry,
+            0x8 => Self::Power,
+            0x9 => Self::Health,
+            _ => Self::Reserved,
+        }
+    }
+}
+
+#[repr(C, packed)]
+#[derive(Clone, Copy, Debug, FromBytes)]
+pub(crate) struct DeviceDesc {
+    length: u8,
+    descriptor_idn: u8,
+    device: u8,
+    device_class: u8,
+    device_sub_class: u8,
+    protocol: u8,
+    number_lu: u8,
+    number_wlu: u8,
+    boot_enable: u8,
+    descr_access_en: u8,
+    init_power_mode: u8,
+    high_priority_lun: u8,
+    secure_removal_type: u8,
+    security_lu: u8,
+    background_ops_term_lat: u8,
+    init_active_icc_level: u8,
+    spec_version: u16,
+    manufacture_date: u16,
+    manufacturer_name: u8,
+    product_name: u8,
+    serial_number: u8,
+    oem_id: u8,
+    manufacturer_id: u16,
+    ud_0_base_offset: u8,
+    ud_config_p_length: u8,
+    device_rtt_cap: u8,
+    periodic_rtc_update: u16,
+    ufs_features_support: u8,
+    ffu_timeout: u8,
+    queue_depth: u8,
+    device_version: u16,
+    num_secure_wp_area: u8,
+    psa_max_data_size: u32,
+    psa_state_timeout: u8,
+    product_revision_level: u8,
+    reserved: [u8; 34],
+    extended_wb_support: u16,
+    extended_ufs_features_support: u32,
+    write_booster_buffer_preserve_user_space_en: u8,
+    write_booster_buffer_type: u8,
+    num_shared_write_booster_buffer_alloc_units: u32,
+    _padding: [u8; 166],
+}
+
+impl DeviceDesc {
+    fn from_buffer(buffer: DescBuffer) -> Self {
+        Self::read_from_bytes(&buffer.data).expect("UFS device descriptor size mismatch")
+    }
+
+    pub(crate) fn number_lu(&self) -> u8 {
+        self.number_lu
+    }
+
+    pub(crate) fn number_wlu(&self) -> u8 {
+        self.number_wlu
+    }
+
+    pub(crate) fn spec_version(&self) -> u16 {
+        u16::from_be(self.spec_version)
+    }
+
+    pub(crate) fn manufacturer_id(&self) -> u16 {
+        u16::from_be(self.manufacturer_id)
+    }
+
+    pub(crate) fn device_rtt_cap(&self) -> u8 {
+        self.device_rtt_cap
+    }
+
+    pub(crate) fn queue_depth(&self) -> usize {
+        self.queue_depth as usize
+    }
+
+    pub(crate) fn extended_wb_support(&self) -> u16 {
+        u16::from_be(self.extended_wb_support)
+    }
+
+    pub(crate) fn extended_ufs_features_support(&self) -> u32 {
+        u32::from_be(self.extended_ufs_features_support)
+    }
+
+    pub(crate) fn write_booster_buffer_preserve_user_space_en(&self) -> u8 {
+        self.write_booster_buffer_preserve_user_space_en
+    }
+
+    pub(crate) fn write_booster_buffer_type(&self) -> u8 {
+        self.write_booster_buffer_type
+    }
+
+    pub(crate) fn num_shared_write_booster_buffer_alloc_units(&self) -> u32 {
+        u32::from_be(self.num_shared_write_booster_buffer_alloc_units)
+    }
+}
+
+#[repr(C, packed)]
+#[derive(Clone, Copy, FromBytes)]
+pub(crate) struct GeometryDesc {
+    length: u8,
+    descriptor_idn: u8,
+    media_technology: u8,
+    reserved: u8,
+    total_raw_device_capacity: u64,
+    max_number_lu: u8,
+    segment_size: u32,
+    allocation_unit_size: u8,
+    min_addr_block_size: u8,
+    optimal_read_block_size: u8,
+    optimal_write_block_size: u8,
+    max_in_buffer_size: u8,
+    max_out_buffer_size: u8,
+    rpmb_read_write_size: u8,
+    dynamic_capacity_resource_policy: u8,
+    data_ordering: u8,
+    max_context_id_number: u8,
+    sys_data_tag_unit_size: u8,
+    sys_data_tag_res_size: u8,
+    supported_sec_r_types: u8,
+    supported_memory_types: u16,
+    system_code_max_n_alloc_u: u32,
+    system_code_cap_adj_fac: u16,
+    non_persist_max_n_alloc_u: u32,
+    non_persist_cap_adj_fac: u16,
+    enhanced_1_max_n_alloc_u: u32,
+    enhanced_1_cap_adj_fac: u16,
+    enhanced_2_max_n_alloc_u: u32,
+    enhanced_2_cap_adj_fac: u16,
+    enhanced_3_max_n_alloc_u: u32,
+    enhanced_3_cap_adj_fac: u16,
+    enhanced_4_max_n_alloc_u: u32,
+    enhanced_4_cap_adj_fac: u16,
+    optimal_logical_block_size: u32,
+    reserved2: [u8; 7],
+    write_booster_buffer_max_n_alloc_units: u32,
+    device_max_write_booster_l_us: u8,
+    write_booster_buffer_cap_adj_fac: u8,
+    supported_write_booster_buffer_user_space_reduction_types: u8,
+    supported_write_booster_buffer_types: u8,
+    reserved3: [u8; 17],
+    cap_adj_fac_representation: u8,
+    _padding: [u8; 150],
+}
+
+impl GeometryDesc {
+    fn from_buffer(buffer: DescBuffer) -> Self {
+        Self::read_from_bytes(&buffer.data).expect("UFS geometry descriptor size mismatch")
+    }
+
+    pub(crate) fn max_number_lu(&self) -> u8 {
+        self.max_number_lu
+    }
+
+    pub(crate) fn write_booster_buffer_max_n_alloc_units(&self) -> u32 {
+        u32::from_be(self.write_booster_buffer_max_n_alloc_units)
+    }
+
+    pub(crate) fn device_max_write_booster_l_us(&self) -> u8 {
+        self.device_max_write_booster_l_us
+    }
+
+    pub(crate) fn write_booster_buffer_cap_adj_fac(&self) -> u8 {
+        self.write_booster_buffer_cap_adj_fac
+    }
+
+    pub(crate) fn supported_write_booster_buffer_types(&self) -> u8 {
+        self.supported_write_booster_buffer_types
+    }
+}
+
+#[repr(C, packed)]
+#[derive(Clone, Copy, FromBytes)]
+pub(crate) struct UnitDesc {
+    length: u8,
+    descriptor_idn: u8,
+    unit_index: u8,
+    lu_enable: u8,
+    boot_lun_id: u8,
+    lu_write_protect: u8,
+    lu_queue_depth: u8,
+    psa_sensitive: u8,
+    memory_type: u8,
+    data_reliability: u8,
+    logical_block_size: u8,
+    logical_block_count: u64,
+    erase_block_size: u32,
+    provisioning_type: u8,
+    phy_mem_resource_count: u64,
+    context_capabilities: u16,
+    large_unit_granularity_m1: u8,
+    reserved: [u8; 6],
+    lu_num_write_booster_buffer_alloc_units: u32,
+    _padding: [u8; 210],
+}
+
+impl UnitDesc {
+    fn from_buffer(buffer: DescBuffer) -> Self {
+        Self::read_from_bytes(&buffer.data).expect("UFS unit descriptor size mismatch")
+    }
+
+    pub(crate) fn enabled(&self) -> bool {
+        self.lu_enable != 0
+    }
+
+    pub(crate) fn logical_block_shift(&self) -> u8 {
+        self.logical_block_size
+    }
+
+    pub(crate) fn logical_block_count(&self) -> u64 {
+        u64::from_be(self.logical_block_count)
+    }
+
+    pub(crate) fn lu_queue_depth(&self) -> usize {
+        self.lu_queue_depth as usize
+    }
+
+    pub(crate) fn lu_num_write_booster_buffer_alloc_units(&self) -> u32 {
+        u32::from_be(self.lu_num_write_booster_buffer_alloc_units)
+    }
+}
+
+pub(crate) type DefaultDesc = DescBuffer;
+
+#[derive(Clone, Copy)]
+pub(crate) enum Desc {
+    Device(DeviceDesc),
+    Config(DefaultDesc),
+    Unit(UnitDesc),
+    RFU0(DefaultDesc),
+    Interconn(DefaultDesc),
+    String(DefaultDesc),
+    RFU1(DefaultDesc),
+    Geometry(GeometryDesc),
+    Power(DefaultDesc),
+    Health(DefaultDesc),
+    Reserved,
+}
+
+impl Desc {
+    pub(crate) fn get_device(&self) -> Result<DeviceDesc> {
+        match *self {
+            Self::Device(desc) => Ok(desc),
+            _ => Err(EINVAL),
+        }
+    }
+
+    pub(crate) fn get_geometry(&self) -> Result<GeometryDesc> {
+        match *self {
+            Self::Geometry(desc) => Ok(desc),
+            _ => Err(EINVAL),
+        }
+    }
+
+    pub(crate) fn get_unit(&self) -> Result<UnitDesc> {
+        match *self {
+            Self::Unit(desc) => Ok(desc),
+            _ => Err(EINVAL),
+        }
+    }
+
+    pub(crate) fn from_buffer(idn: u8, buffer: DescBuffer) -> Self {
+        let idn: DescIdn = idn.into();
+        match idn {
+            DescIdn::Device => Self::Device(DeviceDesc::from_buffer(buffer)),
+            DescIdn::Config => Self::Config(buffer),
+            DescIdn::Unit => Self::Unit(UnitDesc::from_buffer(buffer)),
+            DescIdn::RFU0 => Self::RFU0(buffer),
+            DescIdn::Interconn => Self::Interconn(buffer),
+            DescIdn::String => Self::String(buffer),
+            DescIdn::RFU1 => Self::RFU1(buffer),
+            DescIdn::Geometry => Self::Geometry(GeometryDesc::from_buffer(buffer)),
+            DescIdn::Power => Self::Power(buffer),
+            DescIdn::Health => Self::Health(buffer),
+            _ => Self::Reserved,
+        }
+    }
+}
+
+// Query Command
+#[derive(Copy, Clone)]
+pub(crate) struct UfsDescCmd {
+    pub(crate) idn: DescIdn,
+    pub(crate) index: u8,
+    pub(crate) selector: u8,
+    pub(crate) length: u16,
+    pub(crate) desc: Desc,
+}
+
+impl UfsDescCmd {
+    fn build(idn: DescIdn, index: u8, selector: u8) -> Self {
+        Self {
+            idn,
+            index,
+            selector,
+            length: QUERY_DESC_MAX_SIZE as u16,
+            desc: Desc::Reserved,
+        }
+    }
+}
+
+#[derive(Copy, Clone)]
+pub(crate) enum AttrIdn {
+    BootLuEn = 0x00,
+    MaxHPBSingleCmd = 0x01,
+    PowerMode = 0x02,
+    ActiveICCLevel = 0x03,
+    OOODataEn = 0x04,
+    BkOpsStatus = 0x05,
+    PurgeStatus = 0x06,
+    MaxDataIn = 0x07,
+    MaxDataOut = 0x08,
+    DynCapNeeded = 0x09,
+    RefClkFreq = 0x0A,
+    ConfDescLock = 0x0B,
+    MaxNumOfRTT = 0x0C,
+    EEControl = 0x0D,
+    EEStatus = 0x0E,
+    SecondsPassed = 0x0F,
+    CntxConf = 0x10,
+    CorrPrgBlkNum = 0x11,
+    FFUStatus = 0x14,
+    PSAState = 0x15,
+    PSADataSize = 0x16,
+    RefClkGatingWaitTime = 0x17,
+    CaseRoughTemp = 0x18,
+    HighTempBound = 0x19,
+    LowTempBound = 0x1A,
+    WBFlushStatus = 0x1C,
+    AvailWBBuffSize = 0x1D,
+    WBBuffLifeTimeEst = 0x1E,
+    CurrWBBuffSize = 0x1F,
+    Timestamp = 0x30,
+    DevLvlExceptionID = 0x34,
+    HIDDefragOperation = 0x35,
+    HIDAvailableSize = 0x36,
+    HIDSize = 0x37,
+    HIDProgressRatio = 0x38,
+    HIDState = 0x39,
+    WBBuffResizeHint = 0x3C,
+    WBBuffResizeEn = 0x3D,
+    WBBuffResizeStatus = 0x3E,
+    Reserved = 0xFF,
+}
+
+impl From<u8> for AttrIdn {
+    fn from(idn: u8) -> Self {
+        match idn {
+            0x00 => Self::BootLuEn,
+            0x01 => Self::MaxHPBSingleCmd,
+            0x02 => Self::PowerMode,
+            0x03 => Self::ActiveICCLevel,
+            0x04 => Self::OOODataEn,
+            0x05 => Self::BkOpsStatus,
+            0x06 => Self::PurgeStatus,
+            0x07 => Self::MaxDataIn,
+            0x08 => Self::MaxDataOut,
+            0x09 => Self::DynCapNeeded,
+            0x0A => Self::RefClkFreq,
+            0x0B => Self::ConfDescLock,
+            0x0C => Self::MaxNumOfRTT,
+            0x0D => Self::EEControl,
+            0x0E => Self::EEStatus,
+            0x0F => Self::SecondsPassed,
+            0x10 => Self::CntxConf,
+            0x11 => Self::CorrPrgBlkNum,
+            0x14 => Self::FFUStatus,
+            0x15 => Self::PSAState,
+            0x16 => Self::PSADataSize,
+            0x17 => Self::RefClkGatingWaitTime,
+            0x18 => Self::CaseRoughTemp,
+            0x19 => Self::HighTempBound,
+            0x1A => Self::LowTempBound,
+            0x1C => Self::WBFlushStatus,
+            0x1D => Self::AvailWBBuffSize,
+            0x1E => Self::WBBuffLifeTimeEst,
+            0x1F => Self::CurrWBBuffSize,
+            0x30 => Self::Timestamp,
+            0x34 => Self::DevLvlExceptionID,
+            0x35 => Self::HIDDefragOperation,
+            0x36 => Self::HIDAvailableSize,
+            0x37 => Self::HIDSize,
+            0x38 => Self::HIDProgressRatio,
+            0x39 => Self::HIDState,
+            0x3C => Self::WBBuffResizeHint,
+            0x3D => Self::WBBuffResizeEn,
+            0x3E => Self::WBBuffResizeStatus,
+            _ => Self::Reserved,
+        }
+    }
+}
+
+#[derive(Copy, Clone)]
+pub(crate) struct UfsAttrCmd {
+    pub(crate) idn: AttrIdn,
+    pub(crate) index: u8,
+    pub(crate) selector: u8,
+    pub(crate) value: u64,
+}
+
+impl UfsAttrCmd {
+    fn build(idn: AttrIdn, index: u8, selector: u8, value: u64) -> Self {
+        Self {
+            idn,
+            index,
+            selector,
+            value,
+        }
+    }
+}
+
+#[derive(Copy, Clone)]
+pub(crate) enum FlagIdn {
+    Reserved = 0x00,
+    FDeviceInit = 0x01,
+    PermanentWPE = 0x02,
+    PwrOnWPE = 0x03,
+    BkOpsEn = 0x04,
+    LifeSpanModeEnable = 0x05,
+    PurgeEnable = 0x06,
+    FPhyResourceRemoval = 0x08,
+    BusyRTC = 0x09,
+    PermanentlyDisableFWUpdate = 0x0B,
+    WBEn = 0x0E,
+    WBBuffFlushEn = 0x0F,
+    WBBuffFlushDuringHibern8 = 0x10,
+    HPBReset = 0x11,
+    HPBEn = 0x12,
+    UnpinEn = 0x13,
+}
+
+impl From<u8> for FlagIdn {
+    fn from(idn: u8) -> Self {
+        match idn {
+            0x01 => Self::FDeviceInit,
+            0x02 => Self::PermanentWPE,
+            0x03 => Self::PwrOnWPE,
+            0x04 => Self::BkOpsEn,
+            0x05 => Self::LifeSpanModeEnable,
+            0x06 => Self::PurgeEnable,
+            0x08 => Self::FPhyResourceRemoval,
+            0x09 => Self::BusyRTC,
+            0x0B => Self::PermanentlyDisableFWUpdate,
+            0x0E => Self::WBEn,
+            0x0F => Self::WBBuffFlushEn,
+            0x10 => Self::WBBuffFlushDuringHibern8,
+            0x11 => Self::HPBReset,
+            0x12 => Self::HPBEn,
+            0x13 => Self::UnpinEn,
+            _ => Self::Reserved,
+        }
+    }
+}
+
+#[derive(Copy, Clone)]
+pub(crate) struct UfsFlagCmd {
+    pub(crate) idn: FlagIdn,
+    pub(crate) index: u8,
+    pub(crate) selector: u8,
+    pub(crate) value: u8,
+}
+
+impl UfsFlagCmd {
+    fn build(idn: FlagIdn, index: u8, selector: u8) -> Self {
+        Self {
+            idn,
+            index,
+            selector,
+            value: 0,
+        }
+    }
+}
+
+#[derive(Copy, Clone, Default)]
+pub(crate) enum UfsQueryCmd {
+    #[default]
+    Nop,
+    ReadDesc(UfsDescCmd),
+    WriteDesc(UfsDescCmd),
+    ReadAttr(UfsAttrCmd),
+    WriteAttr(UfsAttrCmd),
+    ReadFlag(UfsFlagCmd),
+    SetFlag(UfsFlagCmd),
+    ClearFlag(UfsFlagCmd),
+    ToggleFlag(UfsFlagCmd),
+}
+
+impl UfsQueryCmd {
+    pub(crate) fn read_desc(&self, idn: DescIdn, index: u8, selector: u8) -> UfsCmd {
+        let cmd = UfsDescCmd::build(idn, index, selector);
+        UfsCmd::Device(UfsDevCmd::Query(Self::ReadDesc(cmd)))
+    }
+
+    pub(crate) fn read_attr(&self, idn: AttrIdn, index: u8, selector: u8) -> UfsCmd {
+        let cmd = UfsAttrCmd::build(idn, index, selector, 0);
+        UfsCmd::Device(UfsDevCmd::Query(Self::ReadAttr(cmd)))
+    }
+
+    pub(crate) fn write_attr(&self, idn: AttrIdn, index: u8, selector: u8, value: u64) -> UfsCmd {
+        let cmd = UfsAttrCmd::build(idn, index, selector, value);
+        UfsCmd::Device(UfsDevCmd::Query(Self::WriteAttr(cmd)))
+    }
+
+    pub(crate) fn read_flag(&self, idn: FlagIdn, index: u8, selector: u8) -> UfsCmd {
+        let cmd = UfsFlagCmd::build(idn, index, selector);
+        UfsCmd::Device(UfsDevCmd::Query(Self::ReadFlag(cmd)))
+    }
+
+    pub(crate) fn set_flag(&self, idn: FlagIdn, index: u8, selector: u8) -> UfsCmd {
+        let cmd = UfsFlagCmd::build(idn, index, selector);
+        UfsCmd::Device(UfsDevCmd::Query(Self::SetFlag(cmd)))
+    }
+
+    pub(crate) fn clear_flag(&self, idn: FlagIdn, index: u8, selector: u8) -> UfsCmd {
+        let cmd = UfsFlagCmd::build(idn, index, selector);
+        UfsCmd::Device(UfsDevCmd::Query(Self::ClearFlag(cmd)))
+    }
+
+    pub(crate) fn toggle_flag(&self, idn: FlagIdn, index: u8, selector: u8) -> UfsCmd {
+        let cmd = UfsFlagCmd::build(idn, index, selector);
+        UfsCmd::Device(UfsDevCmd::Query(Self::ToggleFlag(cmd)))
+    }
+
+    pub(crate) fn get_read_desc(&self) -> Result<UfsDescCmd> {
+        match *self {
+            Self::ReadDesc(cmd) => Ok(cmd),
+            _ => Err(EINVAL),
+        }
+    }
+
+    pub(crate) fn get_attr_value(&self) -> Result<u64> {
+        match *self {
+            Self::ReadAttr(cmd) => Ok(cmd.value),
+            Self::WriteAttr(cmd) => Ok(cmd.value),
+            _ => Err(EINVAL),
+        }
+    }
+
+    pub(crate) fn get_flag_value(&self) -> Result<u8> {
+        match *self {
+            Self::ReadFlag(cmd) => Ok(cmd.value),
+            Self::SetFlag(cmd) => Ok(cmd.value),
+            Self::ClearFlag(cmd) => Ok(cmd.value),
+            Self::ToggleFlag(cmd) => Ok(cmd.value),
+            _ => Err(EINVAL),
+        }
+    }
+}
+
+#[derive(Copy, Clone)]
+pub(crate) struct UfsRPMBCmd {}
+
+#[derive(Copy, Clone)]
+#[expect(clippy::large_enum_variant)]
+pub(crate) enum UfsDevCmd {
+    Nop,
+    Query(UfsQueryCmd),
+    Rpmb(UfsRPMBCmd),
+}
+
+impl UfsDevCmd {
+    pub(crate) fn nop() -> UfsCmd {
+        UfsCmd::Device(Self::Nop)
+    }
+    pub(crate) fn query() -> UfsQueryCmd {
+        UfsQueryCmd::default()
+    }
+
+    pub(crate) fn timeout(&self) -> Delta {
+        match *self {
+            Self::Nop => Delta::from_millis(NOP_OUT_TIMEOUT_MS),
+            Self::Query(_) => Delta::from_millis(QUERY_DEFAULT_TIMEOUT_MS),
+            Self::Rpmb(_) => Delta::from_millis(ADVANCDE_RPMB_TIMEOUT_MS),
+        }
+    }
+
+    pub(crate) fn get_query(&self) -> Result<UfsQueryCmd> {
+        match *self {
+            Self::Query(cmd) => Ok(cmd),
+            _ => Err(EINVAL),
+        }
+    }
+}
+
+const _: () = {
+    assert!(size_of::<DescBuffer>() == QUERY_DESC_MAX_SIZE);
+};
diff --git a/drivers/rufs/protocol/scsi.rs b/drivers/rufs/protocol/scsi.rs
new file mode 100644
index 0000000000000..d6d1edb6bd685
--- /dev/null
+++ b/drivers/rufs/protocol/scsi.rs
@@ -0,0 +1,280 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! SCSI command and completion protocol definitions.
+
+use kernel::prelude::*;
+
+pub(crate) const UFS_SENSE_SIZE: usize = 18;
+
+#[derive(Clone, Copy, Debug)]
+pub(crate) enum UfsScsiCompletion {
+    Good,
+    CheckCondition,
+    Busy,
+    ReservationConflict,
+    TaskSetFull,
+    TaskAborted,
+    Requeue,
+    Error,
+}
+
+#[derive(Clone, Copy)]
+pub(crate) struct UfsScsiResult {
+    pub(crate) completion: UfsScsiCompletion,
+    pub(crate) ocs: u8,
+    pub(crate) transaction: u8,
+    pub(crate) response: u8,
+    pub(crate) status: u8,
+    pub(crate) residual_transfer_count: u32,
+    pub(crate) sense_data_len: usize,
+    pub(crate) sense_data: [u8; UFS_SENSE_SIZE],
+}
+
+impl UfsScsiResult {
+    pub(crate) fn error(ocs: u8) -> Self {
+        Self {
+            completion: UfsScsiCompletion::Error,
+            ocs,
+            transaction: 0,
+            response: 0,
+            status: 0,
+            residual_transfer_count: 0,
+            sense_data_len: 0,
+            sense_data: [0; UFS_SENSE_SIZE],
+        }
+    }
+
+    pub(crate) fn requeue(ocs: u8) -> Self {
+        Self {
+            completion: UfsScsiCompletion::Requeue,
+            ..Self::error(ocs)
+        }
+    }
+}
+
+const READ_10: u8 = 0x28;
+const WRITE_10: u8 = 0x2a;
+const SYNCHRONIZE_CACHE: u8 = 0x35;
+const UNMAP: u8 = 0x42;
+const READ_16: u8 = 0x88;
+const WRITE_16: u8 = 0x8a;
+
+#[repr(C)]
+#[derive(Clone, Copy, FromBytes, IntoBytes)]
+pub(crate) struct UfsUnmapParameterList {
+    data_length: [u8; 2],
+    block_descriptor_data_length: [u8; 2],
+    reserved_header: [u8; 4],
+    lba: [u8; 8],
+    blocks: [u8; 4],
+    reserved_descriptor: [u8; 4],
+}
+
+impl UfsUnmapParameterList {
+    pub(crate) const SIZE: usize = size_of::<Self>();
+
+    pub(crate) fn new(lba: u64, blocks: u32) -> Result<Self> {
+        if blocks == 0 {
+            return Err(EINVAL);
+        }
+
+        Ok(Self {
+            data_length: 22u16.to_be_bytes(),
+            block_descriptor_data_length: 16u16.to_be_bytes(),
+            reserved_header: [0; 4],
+            lba: lba.to_be_bytes(),
+            blocks: blocks.to_be_bytes(),
+            reserved_descriptor: [0; 4],
+        })
+    }
+}
+
+const _: () = assert!(UfsUnmapParameterList::SIZE == 24);
+
+#[derive(PartialEq, Copy, Clone, Debug)]
+pub(crate) enum UfsScsiDataDirection {
+    None,
+    Read,
+    Write,
+}
+
+pub(crate) struct ScsiSense {
+    pub(crate) response_code: u8,
+    pub(crate) sense_key: u8,
+    pub(crate) asc: u8,
+    pub(crate) ascq: u8,
+    pub(crate) additional_len: u8,
+}
+
+impl ScsiSense {
+    pub(crate) fn is_unit_attention(&self) -> bool {
+        self.sense_key == SCSI_SENSE_UNIT_ATTENTION
+    }
+
+    pub(crate) fn is_power_on_reset(&self) -> bool {
+        self.is_unit_attention()
+            && self.asc == SCSI_ASC_POWER_ON_RESET
+            && self.ascq == SCSI_ASCQ_POWER_ON_RESET
+    }
+}
+
+const SCSI_SENSE_UNIT_ATTENTION: u8 = 0x6;
+const SCSI_ASC_POWER_ON_RESET: u8 = 0x29;
+const SCSI_ASCQ_POWER_ON_RESET: u8 = 0x00;
+
+pub(crate) fn parse_scsi_sense(data: &[u8], len: usize) -> Option<ScsiSense> {
+    if len == 0 {
+        return None;
+    }
+
+    let response_code = data[0] & 0x7f;
+    match response_code {
+        // Fixed format sense data.
+        0x70 | 0x71 if len >= 14 => Some(ScsiSense {
+            response_code,
+            sense_key: data[2] & 0x0f,
+            asc: data[12],
+            ascq: data[13],
+            additional_len: data[7],
+        }),
+        // Descriptor format sense data.
+        0x72 | 0x73 if len >= 4 => Some(ScsiSense {
+            response_code,
+            sense_key: data[1] & 0x0f,
+            asc: data[2],
+            ascq: data[3],
+            additional_len: 0,
+        }),
+        _ => None,
+    }
+}
+
+pub(crate) fn sense_key_name(key: u8) -> &'static str {
+    match key {
+        0x0 => "NO_SENSE",
+        0x1 => "RECOVERED_ERROR",
+        0x2 => "NOT_READY",
+        0x3 => "MEDIUM_ERROR",
+        0x4 => "HARDWARE_ERROR",
+        0x5 => "ILLEGAL_REQUEST",
+        0x6 => "UNIT_ATTENTION",
+        0x7 => "DATA_PROTECT",
+        0x8 => "BLANK_CHECK",
+        0x9 => "VENDOR_SPECIFIC",
+        0xb => "ABORTED_COMMAND",
+        0xd => "VOLUME_OVERFLOW",
+        0xe => "MISCOMPARE",
+        _ => "UNKNOWN",
+    }
+}
+
+#[derive(Copy, Clone)]
+pub(crate) struct UfsSCSICmd {
+    lun: u8,
+    direction: UfsScsiDataDirection,
+    data_len: u32,
+    cdb: [u8; 16],
+    unmap_lba: u64,
+    unmap_blocks: u32,
+}
+
+impl UfsSCSICmd {
+    pub(crate) fn read_write(
+        lun: u8,
+        write: bool,
+        lba: u64,
+        blocks: u32,
+        data_len: u32,
+        fua: bool,
+    ) -> Self {
+        let mut cdb = [0u8; 16];
+        let direction = if write {
+            UfsScsiDataDirection::Write
+        } else {
+            UfsScsiDataDirection::Read
+        };
+        let flags = if fua { 0x8 } else { 0 };
+
+        match (u32::try_from(lba), u16::try_from(blocks)) {
+            (Ok(lba), Ok(blocks)) => {
+                cdb[0] = if write { WRITE_10 } else { READ_10 };
+                cdb[1] = flags;
+                cdb[2..6].copy_from_slice(&lba.to_be_bytes());
+                cdb[7..9].copy_from_slice(&blocks.to_be_bytes());
+            }
+            _ => {
+                cdb[0] = if write { WRITE_16 } else { READ_16 };
+                cdb[1] = flags;
+                cdb[2..10].copy_from_slice(&lba.to_be_bytes());
+                cdb[10..14].copy_from_slice(&blocks.to_be_bytes());
+            }
+        }
+
+        Self {
+            lun,
+            direction,
+            data_len,
+            cdb,
+            unmap_lba: 0,
+            unmap_blocks: 0,
+        }
+    }
+
+    pub(crate) fn flush(lun: u8) -> Self {
+        let mut cdb = [0u8; 16];
+        cdb[0] = SYNCHRONIZE_CACHE;
+
+        Self {
+            lun,
+            direction: UfsScsiDataDirection::None,
+            data_len: 0,
+            cdb,
+            unmap_lba: 0,
+            unmap_blocks: 0,
+        }
+    }
+
+    pub(crate) fn unmap(lun: u8, lba: u64, blocks: u32) -> Self {
+        let mut cdb = [0u8; 16];
+        let data_len = UfsUnmapParameterList::SIZE as u32;
+        cdb[0] = UNMAP;
+        cdb[7..9].copy_from_slice(&(data_len as u16).to_be_bytes());
+
+        Self {
+            lun,
+            direction: UfsScsiDataDirection::Write,
+            data_len,
+            cdb,
+            unmap_lba: lba,
+            unmap_blocks: blocks,
+        }
+    }
+
+    pub(crate) fn lun(&self) -> u8 {
+        self.lun
+    }
+
+    pub(crate) fn direction(&self) -> UfsScsiDataDirection {
+        self.direction
+    }
+
+    pub(crate) fn data_len(&self) -> u32 {
+        self.data_len
+    }
+
+    pub(crate) fn cdb(&self) -> [u8; 16] {
+        self.cdb
+    }
+
+    pub(crate) fn is_unmap(&self) -> bool {
+        self.cdb[0] == UNMAP
+    }
+
+    pub(crate) fn unmap_lba(&self) -> u64 {
+        self.unmap_lba
+    }
+
+    pub(crate) fn unmap_blocks(&self) -> u32 {
+        self.unmap_blocks
+    }
+}
diff --git a/drivers/rufs/protocol/upiu.rs b/drivers/rufs/protocol/upiu.rs
new file mode 100644
index 0000000000000..984c52e131813
--- /dev/null
+++ b/drivers/rufs/protocol/upiu.rs
@@ -0,0 +1,873 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! UFS Protocol Information Unit definitions.
+
+#![allow(dead_code)]
+#![allow(unused_variables)]
+
+use super::{query::*, scsi::*};
+use kernel::prelude::*;
+use zerocopy_derive::{Immutable, KnownLayout};
+
+const UFS_CDB_SIZE: usize = 16;
+const SAM_STAT_GOOD: u8 = 0x00;
+const SAM_STAT_CHECK_CONDITION: u8 = 0x02;
+const SAM_STAT_BUSY: u8 = 0x08;
+const SAM_STAT_RESERVATION_CONFLICT: u8 = 0x18;
+const SAM_STAT_TASK_SET_FULL: u8 = 0x28;
+const SAM_STAT_TASK_ABORTED: u8 = 0x40;
+
+// UPIU
+enum UpiuFlag {
+    None = 0x00,
+    CP = 0x04,
+    Write = 0x20,
+    Read = 0x40,
+}
+
+enum UpiuTransaction {
+    NopOut = 0x00,
+    Command = 0x01,
+    DataOut = 0x02,
+    TaskReq = 0x04,
+    QueryReq = 0x16,
+    NopIn = 0x20,
+    Response = 0x21,
+    DataIn = 0x22,
+    TaskRsp = 0x24,
+    ReadyXfer = 0x31,
+    QueryRsp = 0x36,
+    Reject = 0x3F,
+}
+
+impl From<u8> for UpiuTransaction {
+    fn from(code: u8) -> Self {
+        match code {
+            0x00 => Self::NopOut,
+            0x01 => Self::Command,
+            0x02 => Self::DataOut,
+            0x04 => Self::TaskReq,
+            0x16 => Self::QueryReq,
+            0x20 => Self::NopIn,
+            0x21 => Self::Response,
+            0x22 => Self::DataIn,
+            0x24 => Self::TaskRsp,
+            0x31 => Self::ReadyXfer,
+            0x36 => Self::QueryRsp,
+            _ => Self::Reject,
+        }
+    }
+}
+
+enum UpiuQueryFunction {
+    StandardRead = 0x01,
+    StandardWrite = 0x81,
+}
+
+enum UpiuResponse {
+    Success = 0x00,
+    ParamNotReadable = 0xF6,
+    ParamNotWritable = 0xF7,
+    ParamAlreadyWritten = 0xF8,
+    InvalidLen = 0xF9,
+    InvalidVal = 0xFA,
+    InvalidSel = 0xFB,
+    InvalidIndex = 0xFC,
+    InvalidIdn = 0xFD,
+    InvalidOp = 0xFE,
+    Failure = 0xFF,
+}
+
+impl From<u8> for UpiuResponse {
+    fn from(code: u8) -> Self {
+        match code {
+            0x00 => Self::Success,
+            0xF6 => Self::ParamNotReadable,
+            0xF7 => Self::ParamNotWritable,
+            0xF8 => Self::ParamAlreadyWritten,
+            0xF9 => Self::InvalidLen,
+            0xFA => Self::InvalidVal,
+            0xFB => Self::InvalidSel,
+            0xFC => Self::InvalidIndex,
+            0xFD => Self::InvalidIdn,
+            0xFE => Self::InvalidOp,
+            _ => Self::Failure,
+        }
+    }
+}
+
+#[repr(C, packed)]
+#[derive(Default, Clone, Copy, FromBytes, IntoBytes, Immutable)]
+struct UpiuHeader {
+    transaction_code: u8,
+    flags: u8,
+    lun: u8,
+    task_tag: u8,
+    cmd_set: u8,
+    query_func: u8,
+    response: u8,
+    status: u8,
+    ehs_length: u8,
+    dev_info: u8,
+    data_seg_len: u16, // (BE)
+}
+
+impl UpiuHeader {
+    pub(crate) fn nop_out(tag: usize) -> Self {
+        Self {
+            transaction_code: UpiuTransaction::NopOut as u8,
+            task_tag: tag as u8,
+            ..Default::default()
+        }
+    }
+
+    fn query_read(tag: usize) -> Self {
+        Self {
+            transaction_code: UpiuTransaction::QueryReq as u8,
+            task_tag: tag as u8,
+            query_func: UpiuQueryFunction::StandardRead as u8,
+            ..Default::default()
+        }
+    }
+
+    fn query_write(tag: usize) -> Self {
+        Self {
+            transaction_code: UpiuTransaction::QueryReq as u8,
+            task_tag: tag as u8,
+            query_func: UpiuQueryFunction::StandardWrite as u8,
+            ..Default::default()
+        }
+    }
+
+    fn query_write_data(tag: usize, length: usize) -> Self {
+        Self {
+            transaction_code: UpiuTransaction::QueryReq as u8,
+            task_tag: tag as u8,
+            query_func: UpiuQueryFunction::StandardWrite as u8,
+            data_seg_len: (length as u16).to_be(),
+            ..Default::default()
+        }
+    }
+
+    pub(crate) fn command(cmd: UfsSCSICmd, tag: usize) -> Self {
+        let flags = match cmd.direction() {
+            UfsScsiDataDirection::Read => UpiuFlag::Read,
+            UfsScsiDataDirection::Write => UpiuFlag::Write,
+            UfsScsiDataDirection::None => UpiuFlag::None,
+        };
+
+        Self {
+            transaction_code: UpiuTransaction::Command as u8,
+            flags: flags as u8,
+            lun: cmd.lun(),
+            task_tag: tag as u8,
+            cmd_set: 0,
+            ..Default::default()
+        }
+    }
+}
+
+#[repr(C, packed)]
+#[derive(Clone, Copy, FromBytes, IntoBytes, Immutable)]
+struct UpiuCmd {
+    exp_data_transfer_len: u32, // (BE)
+    cdb: [u8; UFS_CDB_SIZE],
+    _padding: [u8; 480],
+}
+
+impl Default for UpiuCmd {
+    fn default() -> Self {
+        Self {
+            exp_data_transfer_len: 0,
+            cdb: [0; UFS_CDB_SIZE],
+            _padding: [0; 480],
+        }
+    }
+}
+
+impl UpiuCmd {
+    fn command(cmd: UfsSCSICmd) -> Self {
+        Self {
+            exp_data_transfer_len: cmd.data_len().to_be(),
+            cdb: cmd.cdb(),
+            ..Default::default()
+        }
+    }
+}
+
+#[repr(C, packed)]
+#[derive(Clone, Copy, FromBytes, IntoBytes, Immutable, KnownLayout)]
+struct UpiuRsp {
+    residual_transfer_count: u32, // (BE)
+    reserved: [u32; 4],
+    sendse_data_len: u16, // (BE)
+    sense_data: [u8; UFS_SENSE_SIZE],
+    _padding: [u8; 460],
+}
+
+impl Default for UpiuRsp {
+    fn default() -> Self {
+        Self {
+            residual_transfer_count: 0,
+            reserved: [0; 4],
+            sendse_data_len: 0,
+            sense_data: [0; UFS_SENSE_SIZE],
+            _padding: [0; 460],
+        }
+    }
+}
+
+#[repr(C, packed)]
+#[derive(Default, Clone, Copy, FromBytes, IntoBytes, Immutable)]
+pub(crate) struct UpiuTmReq {
+    header: UpiuHeader,
+    input_param1: u32, // (BE)
+    input_param2: u32, // (BE)
+    input_param3: u32, // (BE)
+    reserved: [u32; 2],
+    // Task Management doesn't have padding
+    // because it is pre-allocated in UTMRD DMA aree directly
+}
+
+#[repr(C, packed)]
+#[derive(Default, Clone, Copy, FromBytes, IntoBytes, Immutable)]
+pub(crate) struct UpiuTmRsp {
+    header: UpiuHeader,
+    output_param1: u32, // (BE)
+    output_param2: u32, // (BE)
+    reserved: [u32; 3],
+    // Task Management doesn't have padding
+    // because it is pre-allocated in UTMRD DMA aree directly
+}
+
+enum QueryOpcode {
+    Nop = 0x0,
+    ReadDesc = 0x1,
+    WriteDesc = 0x2,
+    ReadAttr = 0x3,
+    WriteAttr = 0x4,
+    ReadFlag = 0x5,
+    SetFlag = 0x6,
+    ClearFlag = 0x7,
+    ToggleFlag = 0x8,
+}
+
+#[repr(C, packed)]
+#[derive(Clone, Copy, FromBytes, IntoBytes, Immutable)]
+struct UpiuReadDescReq {
+    opcode: u8,
+    idn: u8,
+    index: u8,
+    selector: u8,
+    _reserved: u16,
+    length: u16, // (BE)
+    _reserved2: [u32; 3],
+    _padding: [u8; 480],
+}
+
+impl UpiuReadDescReq {
+    fn build(cmd: UfsDescCmd) -> Self {
+        Self {
+            opcode: QueryOpcode::ReadDesc as u8,
+            idn: cmd.idn as u8,
+            index: cmd.index,
+            selector: cmd.selector,
+            _reserved: 0,
+            length: cmd.length.to_be(),
+            _reserved2: [0; 3],
+            _padding: [0; 480],
+        }
+    }
+}
+
+#[repr(C, packed)]
+#[derive(Clone, Copy, FromBytes, IntoBytes)]
+struct UpiuWriteDescReq {
+    opcode: u8,
+    idn: u8,
+    index: u8,
+    selector: u8,
+    _reserved: u16,
+    length: u16, // (BE)
+    _reserved2: [u32; 3],
+    buffer: DescBuffer,
+    _padding: [u8; 225],
+}
+
+#[repr(C, packed)]
+#[derive(Clone, Copy, FromBytes, IntoBytes, Immutable)]
+struct UpiuReadAttrReq {
+    opcode: u8,
+    idn: u8,
+    index: u8,
+    selector: u8,
+    _reserved: [u32; 4],
+    _padding: [u8; 480],
+}
+
+impl UpiuReadAttrReq {
+    fn build(cmd: UfsAttrCmd) -> Self {
+        Self {
+            opcode: QueryOpcode::ReadAttr as u8,
+            idn: cmd.idn as u8,
+            index: cmd.index,
+            selector: cmd.selector,
+            _reserved: [0; 4],
+            _padding: [0; 480],
+        }
+    }
+}
+
+#[repr(C, packed)]
+#[derive(Clone, Copy, FromBytes, IntoBytes, Immutable)]
+struct UpiuWriteAttrReq {
+    opcode: u8,
+    idn: u8,
+    index: u8,
+    selector: u8,
+    value: u64, // (BE)
+    _reserved: [u32; 2],
+    _padding: [u8; 480],
+}
+
+impl UpiuWriteAttrReq {
+    fn build(cmd: UfsAttrCmd) -> Self {
+        Self {
+            opcode: QueryOpcode::WriteAttr as u8,
+            idn: cmd.idn as u8,
+            index: cmd.index,
+            selector: cmd.selector,
+            value: cmd.value.to_be(),
+            _reserved: [0; 2],
+            _padding: [0; 480],
+        }
+    }
+}
+
+#[repr(C, packed)]
+#[derive(Clone, Copy, FromBytes, IntoBytes, Immutable)]
+struct UpiuFlagReq {
+    opcode: u8,
+    idn: u8,
+    index: u8,
+    selector: u8,
+    _reserved: [u32; 4],
+    _padding: [u8; 480],
+}
+
+impl UpiuFlagReq {
+    fn build(cmd: UfsFlagCmd, opcode: QueryOpcode) -> Self {
+        Self {
+            opcode: opcode as u8,
+            idn: cmd.idn as u8,
+            index: cmd.index,
+            selector: cmd.selector,
+            _reserved: [0; 4],
+            _padding: [0; 480],
+        }
+    }
+}
+
+#[repr(C, packed)]
+#[derive(Clone, Copy)]
+union UpiuQueryReq {
+    read_desc: UpiuReadDescReq,
+    write_desc: UpiuWriteDescReq,
+    read_attr: UpiuReadAttrReq,
+    write_attr: UpiuWriteAttrReq,
+    read_flag: UpiuFlagReq,
+    set_flag: UpiuFlagReq,
+    clear_flag: UpiuFlagReq,
+    toggle_flag: UpiuFlagReq,
+}
+
+impl UpiuQueryReq {
+    pub(crate) fn read_desc(cmd: UfsDescCmd) -> Self {
+        Self {
+            read_desc: UpiuReadDescReq::build(cmd),
+        }
+    }
+
+    pub(crate) fn read_attr(cmd: UfsAttrCmd) -> Self {
+        Self {
+            read_attr: UpiuReadAttrReq::build(cmd),
+        }
+    }
+
+    pub(crate) fn write_attr(cmd: UfsAttrCmd) -> Self {
+        Self {
+            write_attr: UpiuWriteAttrReq::build(cmd),
+        }
+    }
+
+    pub(crate) fn read_flag(cmd: UfsFlagCmd) -> Self {
+        Self {
+            read_flag: UpiuFlagReq::build(cmd, QueryOpcode::ReadFlag),
+        }
+    }
+
+    pub(crate) fn set_flag(cmd: UfsFlagCmd) -> Self {
+        Self {
+            set_flag: UpiuFlagReq::build(cmd, QueryOpcode::SetFlag),
+        }
+    }
+
+    pub(crate) fn clear_flag(cmd: UfsFlagCmd) -> Self {
+        Self {
+            clear_flag: UpiuFlagReq::build(cmd, QueryOpcode::ClearFlag),
+        }
+    }
+
+    pub(crate) fn toggle_flag(cmd: UfsFlagCmd) -> Self {
+        Self {
+            toggle_flag: UpiuFlagReq::build(cmd, QueryOpcode::ToggleFlag),
+        }
+    }
+}
+
+#[repr(C, packed)]
+#[derive(Clone, Copy, FromBytes, IntoBytes)]
+struct UpiuReadDescRsp {
+    opcode: u8,
+    idn: u8,
+    index: u8,
+    selector: u8,
+    _reserved: u16,
+    length: u16, // (BE)
+    _reserved2: [u32; 3],
+    buffer: DescBuffer,
+    _padding: [u8; 225],
+}
+
+#[repr(C, packed)]
+#[derive(Clone, Copy, FromBytes, IntoBytes)]
+struct UpiuWriteDescRsp {
+    opcode: u8,
+    idn: u8,
+    index: u8,
+    selector: u8,
+    _reserved: u16,
+    length: u16, // (BE)
+    _reserved2: [u32; 3],
+    _padding: [u8; 480],
+}
+
+#[repr(C, packed)]
+#[derive(Clone, Copy, FromBytes, IntoBytes)]
+struct UpiuAttrRsp {
+    opcode: u8,
+    idn: u8,
+    index: u8,
+    selector: u8,
+    value: u64, // (BE)
+    _reserved: [u32; 2],
+    _padding: [u8; 480],
+}
+
+#[repr(C, packed)]
+#[derive(Clone, Copy, FromBytes, IntoBytes)]
+struct UpiuFlagRsp {
+    opcode: u8,
+    idn: u8,
+    index: u8,
+    selector: u8,
+    _reserved: [u8; 7],
+    value: u8,
+    _reserved2: [u32; 2],
+    _padding: [u8; 480],
+}
+
+#[repr(C, packed)]
+#[derive(Clone, Copy)]
+union UpiuQueryRsp {
+    read_desc: UpiuReadDescRsp,
+    write_desc: UpiuWriteDescRsp,
+    attr: UpiuAttrRsp,
+    flag: UpiuFlagRsp,
+}
+
+#[repr(C, packed)]
+#[derive(Clone, Copy, FromBytes, IntoBytes, Immutable)]
+struct UpiuNop {
+    _reserved: [u32; 5],
+    _padding: [u8; 480],
+}
+
+impl UpiuNop {
+    fn build() -> Self {
+        Self {
+            _reserved: [0; 5],
+            _padding: [0; 480],
+        }
+    }
+}
+
+// DATA OUT UPIU is automatically generated by the UTP Engine.
+// It works without any involvement of software operation,
+// so DATA OUT UPIU is not declared ans used in UFS Driver.
+#[repr(C, packed)]
+#[derive(Clone, Copy)]
+union UpiuBody {
+    cmd: UpiuCmd,
+    rsp: UpiuRsp,
+    tm_req: UpiuTmReq,
+    tm_rsp: UpiuTmRsp,
+    query_req: UpiuQueryReq,
+    query_rsp: UpiuQueryRsp,
+    nop_out: UpiuNop,
+    nop_in: UpiuNop,
+}
+
+impl UpiuBody {
+    fn nop_out() -> Self {
+        Self {
+            nop_out: UpiuNop::build(),
+        }
+    }
+
+    fn read_desc(cmd: UfsDescCmd) -> Self {
+        Self {
+            query_req: UpiuQueryReq::read_desc(cmd),
+        }
+    }
+
+    fn read_attr(cmd: UfsAttrCmd) -> Self {
+        Self {
+            query_req: UpiuQueryReq::read_attr(cmd),
+        }
+    }
+
+    fn write_attr(cmd: UfsAttrCmd) -> Self {
+        Self {
+            query_req: UpiuQueryReq::write_attr(cmd),
+        }
+    }
+
+    fn read_flag(cmd: UfsFlagCmd) -> Self {
+        Self {
+            query_req: UpiuQueryReq::read_flag(cmd),
+        }
+    }
+
+    fn set_flag(cmd: UfsFlagCmd) -> Self {
+        Self {
+            query_req: UpiuQueryReq::set_flag(cmd),
+        }
+    }
+
+    fn clear_flag(cmd: UfsFlagCmd) -> Self {
+        Self {
+            query_req: UpiuQueryReq::clear_flag(cmd),
+        }
+    }
+
+    fn toggle_flag(cmd: UfsFlagCmd) -> Self {
+        Self {
+            query_req: UpiuQueryReq::toggle_flag(cmd),
+        }
+    }
+
+    fn command(cmd: UfsSCSICmd) -> Self {
+        Self {
+            cmd: UpiuCmd::command(cmd),
+        }
+    }
+}
+
+#[repr(C, packed)]
+#[derive(Clone, Copy, FromBytes, IntoBytes)]
+pub(crate) struct Upiu {
+    header: UpiuHeader,
+    body: [u8; 500],
+}
+
+impl Default for Upiu {
+    fn default() -> Self {
+        Self {
+            header: UpiuHeader::default(),
+            body: <[u8; 500]>::try_from(UpiuNop::build().as_bytes()).unwrap(),
+        }
+    }
+}
+
+impl Upiu {
+    pub(crate) fn nop_out(tag: usize) -> Self {
+        Self {
+            header: UpiuHeader::nop_out(tag),
+            body: <[u8; 500]>::try_from(UpiuNop::build().as_bytes()).unwrap(),
+        }
+    }
+
+    pub(crate) fn read_desc(cmd: UfsDescCmd, tag: usize) -> Self {
+        Self {
+            header: UpiuHeader::query_read(tag),
+            body: <[u8; 500]>::try_from(UpiuReadDescReq::build(cmd).as_bytes()).unwrap(),
+        }
+    }
+
+    pub(crate) fn read_attr(cmd: UfsAttrCmd, tag: usize) -> Self {
+        Self {
+            header: UpiuHeader::query_read(tag),
+            body: <[u8; 500]>::try_from(UpiuReadAttrReq::build(cmd).as_bytes()).unwrap(),
+        }
+    }
+
+    pub(crate) fn write_attr(cmd: UfsAttrCmd, tag: usize) -> Self {
+        Self {
+            header: UpiuHeader::query_write(tag),
+            body: <[u8; 500]>::try_from(UpiuWriteAttrReq::build(cmd).as_bytes()).unwrap(),
+        }
+    }
+
+    pub(crate) fn read_flag(cmd: UfsFlagCmd, tag: usize) -> Self {
+        Self {
+            header: UpiuHeader::query_read(tag),
+            body: <[u8; 500]>::try_from(UpiuFlagReq::build(cmd, QueryOpcode::ReadFlag).as_bytes())
+                .unwrap(),
+        }
+    }
+
+    pub(crate) fn set_flag(cmd: UfsFlagCmd, tag: usize) -> Self {
+        Self {
+            header: UpiuHeader::query_write(tag),
+            body: <[u8; 500]>::try_from(UpiuFlagReq::build(cmd, QueryOpcode::SetFlag).as_bytes())
+                .unwrap(),
+        }
+    }
+
+    pub(crate) fn clear_flag(cmd: UfsFlagCmd, tag: usize) -> Self {
+        Self {
+            header: UpiuHeader::query_write(tag),
+            body: <[u8; 500]>::try_from(UpiuFlagReq::build(cmd, QueryOpcode::ClearFlag).as_bytes())
+                .unwrap(),
+        }
+    }
+
+    pub(crate) fn toggle_flag(cmd: UfsFlagCmd, tag: usize) -> Self {
+        Self {
+            header: UpiuHeader::query_write(tag),
+            body: <[u8; 500]>::try_from(
+                UpiuFlagReq::build(cmd, QueryOpcode::ToggleFlag).as_bytes(),
+            )
+            .unwrap(),
+        }
+    }
+
+    pub(crate) fn command(cmd: UfsSCSICmd, tag: usize) -> Self {
+        Self {
+            header: UpiuHeader::command(cmd, tag),
+            body: <[u8; 500]>::try_from(UpiuCmd::command(cmd).as_bytes()).unwrap(),
+        }
+    }
+
+    pub(crate) fn device(cmd: UfsDevCmd, tag: usize) -> Self {
+        match cmd {
+            UfsDevCmd::Nop => Self::nop_out(tag),
+            UfsDevCmd::Query(cmd) => Self::query(cmd, tag),
+            UfsDevCmd::Rpmb(_) => Self::nop_out(tag),
+        }
+    }
+
+    fn query(cmd: UfsQueryCmd, tag: usize) -> Self {
+        match cmd {
+            UfsQueryCmd::Nop => Self::nop_out(tag),
+            UfsQueryCmd::ReadDesc(cmd) => Self::read_desc(cmd, tag),
+            UfsQueryCmd::WriteDesc(cmd) => Self::nop_out(tag),
+            UfsQueryCmd::ReadAttr(cmd) => Self::read_attr(cmd, tag),
+            UfsQueryCmd::WriteAttr(cmd) => Self::write_attr(cmd, tag),
+            UfsQueryCmd::ReadFlag(cmd) => Self::read_flag(cmd, tag),
+            UfsQueryCmd::SetFlag(cmd) => Self::set_flag(cmd, tag),
+            UfsQueryCmd::ClearFlag(cmd) => Self::clear_flag(cmd, tag),
+            UfsQueryCmd::ToggleFlag(cmd) => Self::toggle_flag(cmd, tag),
+        }
+    }
+
+    fn transaction(&self) -> UpiuTransaction {
+        self.header.transaction_code.into()
+    }
+
+    fn response(&self) -> UpiuResponse {
+        self.header.response.into()
+    }
+
+    pub(crate) fn scsi_result(&self, ocs: u8) -> UfsScsiResult {
+        let rsp: UpiuRsp = zerocopy::transmute!(self.body);
+        let sense_data_len = usize::from(u16::from_be(rsp.sendse_data_len)).min(UFS_SENSE_SIZE);
+
+        let mut result = UfsScsiResult {
+            completion: UfsScsiCompletion::Error,
+            ocs,
+            transaction: self.header.transaction_code,
+            response: self.header.response,
+            status: self.header.status,
+            residual_transfer_count: u32::from_be(rsp.residual_transfer_count),
+            sense_data_len,
+            sense_data: rsp.sense_data,
+        };
+
+        match self.transaction() {
+            UpiuTransaction::Response => {}
+            _ => return result,
+        }
+
+        result.completion = match self.header.status {
+            SAM_STAT_GOOD => UfsScsiCompletion::Good,
+            SAM_STAT_CHECK_CONDITION => UfsScsiCompletion::CheckCondition,
+            SAM_STAT_BUSY => UfsScsiCompletion::Busy,
+            SAM_STAT_RESERVATION_CONFLICT => UfsScsiCompletion::ReservationConflict,
+            SAM_STAT_TASK_SET_FULL => UfsScsiCompletion::TaskSetFull,
+            SAM_STAT_TASK_ABORTED => UfsScsiCompletion::TaskAborted,
+            _ => UfsScsiCompletion::Error,
+        };
+
+        result
+    }
+
+    pub(crate) fn fetch_dev(&self, cmd: UfsDevCmd) -> Result<UfsDevCmd> {
+        match cmd {
+            UfsDevCmd::Nop => match self.transaction() {
+                UpiuTransaction::NopIn => Ok(cmd),
+                _ => Err(EIO),
+            },
+            UfsDevCmd::Query(cmd) => match self.transaction() {
+                UpiuTransaction::QueryRsp => match self.response() {
+                    UpiuResponse::Success => self.fetch_query(cmd),
+                    _ => Err(EIO),
+                },
+                _ => Err(EIO),
+            },
+            UfsDevCmd::Rpmb(cmd) => match self.transaction() {
+                UpiuTransaction::Response => Ok(UfsDevCmd::Rpmb(cmd)),
+                _ => Err(EIO),
+            },
+        }
+    }
+
+    fn fetch_query(&self, cmd: UfsQueryCmd) -> Result<UfsDevCmd> {
+        match cmd {
+            UfsQueryCmd::ReadDesc(cmd) => {
+                let upiu: UpiuReadDescRsp = zerocopy::transmute!(self.body);
+                Ok(UfsDevCmd::Query(UfsQueryCmd::ReadDesc(UfsDescCmd {
+                    idn: upiu.idn.into(),
+                    index: upiu.index,
+                    selector: upiu.selector,
+                    length: u16::from_be(upiu.length),
+                    desc: Desc::from_buffer(upiu.idn, upiu.buffer),
+                })))
+            }
+            UfsQueryCmd::ReadAttr(cmd) => {
+                let upiu: UpiuAttrRsp = zerocopy::transmute!(self.body);
+                Ok(UfsDevCmd::Query(UfsQueryCmd::ReadAttr(UfsAttrCmd {
+                    idn: upiu.idn.into(),
+                    index: upiu.index,
+                    selector: upiu.selector,
+                    value: u64::from_be(upiu.value),
+                })))
+            }
+            UfsQueryCmd::WriteAttr(cmd) => {
+                let upiu: UpiuAttrRsp = zerocopy::transmute!(self.body);
+                Ok(UfsDevCmd::Query(UfsQueryCmd::WriteAttr(UfsAttrCmd {
+                    idn: upiu.idn.into(),
+                    index: upiu.index,
+                    selector: upiu.selector,
+                    value: u64::from_be(upiu.value),
+                })))
+            }
+            UfsQueryCmd::ReadFlag(cmd) => {
+                let upiu: UpiuFlagRsp = zerocopy::transmute!(self.body);
+                Ok(UfsDevCmd::Query(UfsQueryCmd::ReadFlag(UfsFlagCmd {
+                    idn: upiu.idn.into(),
+                    index: upiu.index,
+                    selector: upiu.selector,
+                    value: upiu.value,
+                })))
+            }
+            UfsQueryCmd::SetFlag(cmd) => {
+                let upiu: UpiuFlagRsp = zerocopy::transmute!(self.body);
+                Ok(UfsDevCmd::Query(UfsQueryCmd::SetFlag(UfsFlagCmd {
+                    idn: upiu.idn.into(),
+                    index: upiu.index,
+                    selector: upiu.selector,
+                    value: upiu.value,
+                })))
+            }
+            UfsQueryCmd::ClearFlag(cmd) => {
+                let upiu: UpiuFlagRsp = zerocopy::transmute!(self.body);
+                Ok(UfsDevCmd::Query(UfsQueryCmd::ClearFlag(UfsFlagCmd {
+                    idn: upiu.idn.into(),
+                    index: upiu.index,
+                    selector: upiu.selector,
+                    value: upiu.value,
+                })))
+            }
+            UfsQueryCmd::ToggleFlag(cmd) => {
+                let upiu: UpiuFlagRsp = zerocopy::transmute!(self.body);
+                Ok(UfsDevCmd::Query(UfsQueryCmd::ToggleFlag(UfsFlagCmd {
+                    idn: upiu.idn.into(),
+                    index: upiu.index,
+                    selector: upiu.selector,
+                    value: upiu.value,
+                })))
+            }
+            _ => Ok(UfsDevCmd::Query(cmd)),
+        }
+    }
+}
+
+const _: () = {
+    assert!(size_of::<UpiuHeader>() == 12);
+};
+const _: () = {
+    assert!(size_of::<UpiuCmd>() == 500);
+};
+const _: () = {
+    assert!(size_of::<UpiuRsp>() == 500);
+};
+const _: () = {
+    assert!(size_of::<UpiuTmReq>() == 32);
+};
+const _: () = {
+    assert!(size_of::<UpiuTmRsp>() == 32);
+};
+const _: () = {
+    assert!(size_of::<UpiuReadDescReq>() == 500);
+};
+const _: () = {
+    assert!(size_of::<UpiuWriteDescReq>() == 500);
+};
+const _: () = {
+    assert!(size_of::<UpiuReadAttrReq>() == 500);
+};
+const _: () = {
+    assert!(size_of::<UpiuWriteAttrReq>() == 500);
+};
+const _: () = {
+    assert!(size_of::<UpiuFlagReq>() == 500);
+};
+const _: () = {
+    assert!(size_of::<UpiuQueryReq>() == 500);
+};
+const _: () = {
+    assert!(size_of::<UpiuReadDescRsp>() == 500);
+};
+const _: () = {
+    assert!(size_of::<UpiuWriteDescRsp>() == 500);
+};
+const _: () = {
+    assert!(size_of::<UpiuAttrRsp>() == 500);
+};
+const _: () = {
+    assert!(size_of::<UpiuFlagRsp>() == 500);
+};
+const _: () = {
+    assert!(size_of::<UpiuQueryRsp>() == 500);
+};
+const _: () = {
+    assert!(size_of::<UpiuNop>() == 500);
+};
+const _: () = {
+    assert!(size_of::<UpiuBody>() == 500);
+};
+const _: () = {
+    assert!(size_of::<Upiu>() == 512);
+};
diff --git a/drivers/rufs/queue.rs b/drivers/rufs/queue.rs
new file mode 100644
index 0000000000000..d3c8040bea74b
--- /dev/null
+++ b/drivers/rufs/queue.rs
@@ -0,0 +1,1516 @@
+// SPDX-License-Identifier: GPL-2.0
+
+use crate::command::TaskTag;
+use crate::dma::*;
+use crate::lu::{TagSetData, UfsLuBlockOps, UfsRequestData};
+use crate::protocol::scsi::*;
+use crate::protocol::{query::UfsDevCmd, UfsCmd};
+use crate::reg::*;
+use crate::resource::HostResources;
+use crate::transport::*;
+use crate::uic::UfsUic;
+use crate::variant::{NotifyPhase, UfsVariantOps};
+use kernel::alloc::mempool::MemPool;
+use kernel::block::mq;
+use kernel::block::mq::dma_map_iter::DmaMapMempool;
+use kernel::block::mq::TagSet;
+use kernel::sync::{Arc, SpinLock};
+use kernel::time::{delay::fsleep, Delta};
+use kernel::types::{OwnableRefCounted, Owned};
+use kernel::workqueue::{self, impl_has_work, new_work, Work, WorkItem};
+use kernel::{bindings, new_spinlock, prelude::*};
+
+const HBA_ENABLE_DELAY_US: i64 = 1000;
+
+fn retryable_check_condition(sense: Option<&ScsiSense>) -> bool {
+    matches!(sense, Some(sense) if sense.is_unit_attention())
+}
+
+fn should_requeue_scsi(completion: UfsScsiCompletion, sense: Option<&ScsiSense>) -> bool {
+    matches!(
+        completion,
+        UfsScsiCompletion::Busy | UfsScsiCompletion::TaskSetFull | UfsScsiCompletion::Requeue
+    ) || (matches!(completion, UfsScsiCompletion::CheckCondition)
+        && retryable_check_condition(sense))
+}
+
+impl McqConfig {
+    fn queue_map(&self) -> Result<UfsQueueMap> {
+        UfsQueueMap::new(
+            self.total_queues,
+            self.default_queues,
+            self.read_queues,
+            self.poll_queues,
+        )
+    }
+}
+
+impl UfsTransferConfig {
+    fn queue_map(&self) -> Result<UfsQueueMap> {
+        match self {
+            Self::Sdb { .. } => Ok(UfsQueueMap::sdb()),
+            Self::Mcq(config) => config.queue_map(),
+        }
+    }
+}
+
+#[derive(Copy, Clone)]
+pub(crate) struct UfsQueueRange {
+    offset: usize,
+    count: usize,
+}
+
+#[derive(Copy, Clone)]
+pub(crate) struct UfsQueueMap {
+    nr_hw_queues: usize,
+    default: UfsQueueRange,
+    read: UfsQueueRange,
+    poll: UfsQueueRange,
+}
+
+impl UfsQueueMap {
+    fn sdb() -> Self {
+        Self {
+            nr_hw_queues: 1,
+            default: UfsQueueRange {
+                offset: 0,
+                count: 1,
+            },
+            read: UfsQueueRange {
+                offset: 0,
+                count: 0,
+            },
+            poll: UfsQueueRange {
+                offset: 0,
+                count: 1,
+            },
+        }
+    }
+
+    fn new(
+        nr_hw_queues: usize,
+        default_queues: usize,
+        read_queues: usize,
+        poll_queues: usize,
+    ) -> Result<Self> {
+        let mapped_queues = default_queues
+            .checked_add(read_queues)
+            .and_then(|queues| queues.checked_add(poll_queues))
+            .ok_or(EOVERFLOW)?;
+
+        if nr_hw_queues == 0 || mapped_queues != nr_hw_queues {
+            return Err(EINVAL);
+        }
+
+        let read_offset = default_queues;
+        let poll_offset = read_offset.checked_add(read_queues).ok_or(EOVERFLOW)?;
+
+        Ok(Self {
+            nr_hw_queues,
+            default: UfsQueueRange {
+                offset: 0,
+                count: default_queues,
+            },
+            read: UfsQueueRange {
+                offset: read_offset,
+                count: read_queues,
+            },
+            poll: UfsQueueRange {
+                offset: poll_offset,
+                count: poll_queues,
+            },
+        })
+    }
+
+    pub(crate) fn nr_hw_queues(&self) -> usize {
+        self.nr_hw_queues
+    }
+
+    pub(crate) fn range(&self, kind: mq::QueueType) -> UfsQueueRange {
+        match kind {
+            mq::QueueType::Default => self.default,
+            mq::QueueType::Read => self.read,
+            mq::QueueType::Poll => self.poll,
+        }
+    }
+
+    /// Number of blk-mq queue maps required to express this layout.
+    pub(crate) fn num_maps(&self) -> u32 {
+        if self.poll.count > 0 {
+            3
+        } else if self.read.count > 0 {
+            2
+        } else {
+            1
+        }
+    }
+}
+
+impl UfsQueueRange {
+    pub(crate) fn offset(&self) -> usize {
+        self.offset
+    }
+
+    pub(crate) fn count(&self) -> usize {
+        self.count
+    }
+}
+
+enum CompletionTarget<'a> {
+    Direct,
+    Poll(&'a mut mq::IoCompletionBatch<UfsLuBlockOps>),
+}
+
+#[derive(Clone, Copy, PartialEq, Eq)]
+enum CompletionOutcome {
+    Returned,
+    RetainedForRecovery,
+}
+
+impl CompletionOutcome {
+    fn returned(self) -> bool {
+        self == Self::Returned
+    }
+}
+
+pub(crate) struct UfsRequestInner {
+    state: UfsRequestState,
+}
+
+enum UfsRequestState {
+    Idle,
+    Prepared {
+        cmd: UfsCmd,
+        mapping: UfsPreparedMapping,
+    },
+    InFlight {
+        cmd: UfsCmd,
+        mapping: UfsActiveMapping,
+        queue_id: u32,
+    },
+    Recovering {
+        cmd: UfsCmd,
+        mapping: UfsActiveMapping,
+        queue_id: u32,
+    },
+    Completing,
+    CompletionReady(CompletionDisposition),
+    DeviceComplete(UfsDevCmd),
+}
+
+pub(crate) enum CompletionDisposition {
+    End(u32),
+    Requeue,
+}
+
+#[derive(Clone, Copy, Debug)]
+enum RecoveryReason {
+    Driver(&'static str),
+    Uic(UicErrorStatus),
+    InvalidMcqCompletion,
+}
+
+impl RecoveryReason {
+    fn name(&self) -> &'static str {
+        match *self {
+            Self::Driver(reason) => reason,
+            Self::Uic(_) => "fatal UIC error",
+            Self::InvalidMcqCompletion => "invalid MCQ completion descriptor",
+        }
+    }
+
+    fn uic_errors(&self) -> Option<UicErrorStatus> {
+        match *self {
+            Self::Uic(errors) => Some(errors),
+            _ => None,
+        }
+    }
+}
+
+#[derive(Clone, Copy, Debug)]
+enum RecoveryScope {
+    Controller,
+    Queue(u32),
+}
+
+impl RecoveryScope {
+    fn queue_id(&self) -> Option<u32> {
+        match *self {
+            Self::Controller => None,
+            Self::Queue(queue_id) => Some(queue_id),
+        }
+    }
+}
+
+#[derive(Clone, Copy, Debug)]
+struct RecoveryCause {
+    reason: RecoveryReason,
+    scope: RecoveryScope,
+    tag: usize,
+}
+
+/// Proof that the controller can no longer access previously published DMA
+/// mappings.
+struct DmaAccessEnded;
+
+enum RecoveryState {
+    Operational,
+    Requested(RecoveryCause),
+    Quiescing(RecoveryCause),
+    Recovering(RecoveryCause),
+    Failed(RecoveryCause),
+    Shutdown,
+}
+
+impl RecoveryState {
+    fn cause(&self) -> Option<RecoveryCause> {
+        match *self {
+            Self::Operational => None,
+            Self::Requested(cause)
+            | Self::Quiescing(cause)
+            | Self::Recovering(cause)
+            | Self::Failed(cause) => Some(cause),
+            Self::Shutdown => None,
+        }
+    }
+}
+
+enum TimeoutDisposition {
+    StartRecovery(UfsCmd),
+    Recovering(UfsCmd),
+    Pending(UfsCmd),
+    Completed,
+}
+
+impl Default for UfsRequestInner {
+    fn default() -> Self {
+        UfsRequestInner {
+            state: UfsRequestState::Idle,
+        }
+    }
+}
+
+impl UfsRequestInner {
+    pub(crate) fn prepare_device(&mut self, cmd: UfsCmd) -> Result<()> {
+        if !matches!(cmd, UfsCmd::Device(_)) || !matches!(self.state, UfsRequestState::Idle) {
+            return Err(EINVAL);
+        }
+        self.state = UfsRequestState::Prepared {
+            cmd,
+            mapping: UfsPreparedMapping::None,
+        };
+        Ok(())
+    }
+
+    fn prepare_scsi(&mut self, cmd: UfsSCSICmd, mapping: UfsPreparedMapping) -> Result<()> {
+        if !matches!(self.state, UfsRequestState::Idle) {
+            return Err(EBUSY);
+        }
+        self.state = UfsRequestState::Prepared {
+            cmd: UfsCmd::Scsi(cmd),
+            mapping,
+        };
+        Ok(())
+    }
+
+    fn prepared_command(&self) -> Result<UfsCmd> {
+        match self.state {
+            UfsRequestState::Prepared { cmd, .. } => Ok(cmd),
+            _ => Err(EIO),
+        }
+    }
+
+    fn mark_in_flight(&mut self, queue_id: u32) -> Result<()> {
+        let state = core::mem::replace(&mut self.state, UfsRequestState::Idle);
+        self.state = match state {
+            UfsRequestState::Prepared { cmd, mapping } => UfsRequestState::InFlight {
+                cmd,
+                mapping: mapping.publish(),
+                queue_id,
+            },
+            state => {
+                self.state = state;
+                return Err(EIO);
+            }
+        };
+        Ok(())
+    }
+
+    fn begin_completion(&mut self, queue_id: u32) -> Result<(UfsCmd, UfsActiveMapping)> {
+        let state = core::mem::replace(&mut self.state, UfsRequestState::Idle);
+        match state {
+            UfsRequestState::InFlight {
+                cmd,
+                mapping,
+                queue_id: submitted_queue,
+            }
+            | UfsRequestState::Recovering {
+                cmd,
+                mapping,
+                queue_id: submitted_queue,
+            } if submitted_queue == queue_id => {
+                self.state = UfsRequestState::Completing;
+                Ok((cmd, mapping))
+            }
+            state => {
+                self.state = state;
+                Err(EIO)
+            }
+        }
+    }
+
+    fn timeout(&mut self) -> TimeoutDisposition {
+        let state = core::mem::replace(&mut self.state, UfsRequestState::Idle);
+        match state {
+            UfsRequestState::Prepared { cmd, mapping } => {
+                self.state = UfsRequestState::Prepared { cmd, mapping };
+                TimeoutDisposition::Pending(cmd)
+            }
+            UfsRequestState::InFlight {
+                cmd,
+                mapping,
+                queue_id,
+            } => {
+                self.state = UfsRequestState::Recovering {
+                    cmd,
+                    mapping,
+                    queue_id,
+                };
+                TimeoutDisposition::StartRecovery(cmd)
+            }
+            UfsRequestState::Recovering {
+                cmd,
+                mapping,
+                queue_id,
+            } => {
+                self.state = UfsRequestState::Recovering {
+                    cmd,
+                    mapping,
+                    queue_id,
+                };
+                TimeoutDisposition::Recovering(cmd)
+            }
+            state => {
+                self.state = state;
+                TimeoutDisposition::Completed
+            }
+        }
+    }
+
+    fn complete_device(&mut self, cmd: UfsDevCmd) -> Result<()> {
+        if !matches!(self.state, UfsRequestState::Completing) {
+            return Err(EIO);
+        }
+        self.state = UfsRequestState::DeviceComplete(cmd);
+        Ok(())
+    }
+
+    fn schedule_completion(&mut self, disposition: CompletionDisposition) -> Result<()> {
+        if !matches!(self.state, UfsRequestState::Completing) {
+            return Err(EIO);
+        }
+        self.state = UfsRequestState::CompletionReady(disposition);
+        Ok(())
+    }
+
+    pub(crate) fn take_scheduled_completion(&mut self) -> Result<CompletionDisposition> {
+        let state = core::mem::replace(&mut self.state, UfsRequestState::Idle);
+        match state {
+            UfsRequestState::CompletionReady(disposition) => Ok(disposition),
+            state => {
+                self.state = state;
+                Err(EIO)
+            }
+        }
+    }
+
+    fn finish_direct_completion(&mut self) -> Result<()> {
+        if !matches!(self.state, UfsRequestState::Completing) {
+            return Err(EIO);
+        }
+        self.state = UfsRequestState::Idle;
+        Ok(())
+    }
+
+    pub(crate) fn take_device_completion(&mut self) -> Result<UfsCmd> {
+        let state = core::mem::replace(&mut self.state, UfsRequestState::Idle);
+        match state {
+            UfsRequestState::DeviceComplete(cmd) => Ok(UfsCmd::Device(cmd)),
+            state => {
+                self.state = state;
+                Err(EIO)
+            }
+        }
+    }
+
+    pub(crate) fn reset(&mut self) {
+        self.state = UfsRequestState::Idle;
+    }
+
+    fn prepare_recovery_disposition(
+        &mut self,
+        requeue: bool,
+        dma_ended: Option<&DmaAccessEnded>,
+    ) -> Result<()> {
+        let state = core::mem::replace(&mut self.state, UfsRequestState::Idle);
+        match state {
+            UfsRequestState::InFlight {
+                cmd,
+                mapping,
+                queue_id: _,
+            }
+            | UfsRequestState::Recovering {
+                cmd,
+                mapping,
+                queue_id: _,
+            } => {
+                if dma_ended.is_some() {
+                    // SAFETY: `DmaAccessEnded` is created only after the
+                    // controller has invalidated all previously published
+                    // commands.
+                    unsafe { mapping.complete() };
+                } else {
+                    // The controller did not stop, so dropping the active
+                    // wrapper deliberately leaks its mapping.
+                    drop(mapping);
+                }
+                if requeue && matches!(cmd, UfsCmd::Device(_)) {
+                    self.state = UfsRequestState::Prepared {
+                        cmd,
+                        mapping: UfsPreparedMapping::None,
+                    };
+                }
+                Ok(())
+            }
+            state => {
+                self.state = state;
+                Err(EIO)
+            }
+        }
+    }
+}
+
+fn complete_dma_mapping(mapping: UfsActiveMapping) {
+    // SAFETY: Callers invoke this only after consuming a hardware completion
+    // for the command that owns the mapping.
+    unsafe { mapping.complete() };
+}
+
+struct ResolvedCompletion {
+    rq: Owned<mq::Request<UfsLuBlockOps>>,
+    task_tag: TaskTag,
+    queue_id: u32,
+    completion: TransferCompletion,
+}
+
+impl ResolvedCompletion {
+    fn complete(self) -> CompletionOutcome {
+        UfsRequestData::complete(self.rq, self.task_tag, self.queue_id, self.completion)
+    }
+
+    fn complete_polled(
+        self,
+        batch: &mut mq::IoCompletionBatch<UfsLuBlockOps>,
+    ) -> CompletionOutcome {
+        UfsRequestData::complete_polled(
+            self.rq,
+            self.task_tag,
+            self.queue_id,
+            self.completion,
+            batch,
+        )
+    }
+}
+
+impl UfsRequestData {
+    fn task_tag(rq: &mq::Request<UfsLuBlockOps>) -> Result<TaskTag> {
+        TaskTag::new(rq.tag())
+    }
+
+    pub(crate) fn compose_dev_request(rq: &Owned<mq::Request<UfsLuBlockOps>>) -> Result<()> {
+        if let Some(queue) = rq.queue_data().dev_queue() {
+            let cmd = rq
+                .data_ref()
+                .inner
+                .lock()
+                .prepared_command()?
+                .get_device()?;
+            let task_tag = Self::task_tag(rq)?;
+            queue.compose_dev(cmd, task_tag)?;
+            Ok(())
+        } else {
+            Err(EIO)
+        }
+    }
+
+    pub(crate) fn compose_scsi_cmd(
+        rq: &Owned<mq::Request<UfsLuBlockOps>>,
+        cmd: UfsSCSICmd,
+    ) -> Result<()> {
+        let mempool = rq.queue().tag_set().data().dma_vec_mempool.clone();
+        let task_tag = Self::task_tag(rq)?;
+        let mapping = UfsQueue::compose_scsi(rq, cmd, task_tag, &mempool)?;
+
+        rq.data_ref().inner.lock().prepare_scsi(cmd, mapping)?;
+        Ok(())
+    }
+
+    pub(crate) fn submit(
+        rq: Owned<mq::Request<UfsLuBlockOps>>,
+        hw_queue: &UfsHwQueue,
+    ) -> core::result::Result<(), (Owned<mq::Request<UfsLuBlockOps>>, Error)> {
+        let queue = rq.queue_data().queue_arc().clone();
+        let queue_id = hw_queue.id();
+        let task_tag = match Self::task_tag(&rq) {
+            Ok(task_tag) => task_tag,
+            Err(e) => return Err((rq, e)),
+        };
+        let polled = rq.flags().contains(mq::RequestFlag::Polled);
+
+        if queue.recovery_required() {
+            return Err((rq, EBUSY));
+        }
+
+        if rq.queue_index() != queue_id {
+            return Err((rq, EINVAL));
+        }
+
+        let mut rq = Some(rq);
+        let outcome = hw_queue.submit(u32::from(task_tag.value()), polled, || {
+            let request = rq.as_mut().ok_or(EIO)?;
+            request.data_ref().inner.lock().mark_in_flight(queue_id)?;
+
+            // Park unique ownership in the blk-mq tag map at the publication
+            // boundary. No submit-side request reference remains live when
+            // hardware can observe the task tag.
+            let request = rq.take().ok_or(EIO)?;
+            drop(request);
+            Ok(())
+        });
+
+        match outcome {
+            SubmissionOutcome::Submitted => Ok(()),
+            SubmissionOutcome::NotSubmitted(e) => {
+                let Some(rq) = rq else {
+                    queue.require_recovery("invalid submission ownership", task_tag.index());
+                    return Ok(());
+                };
+                Err((rq, e))
+            }
+            SubmissionOutcome::PublishFailed(e) => {
+                pr_err!(
+                    "[RUFS] ufs_queue: submission publish failed tag={} queue={} errno={}\n",
+                    task_tag.value(),
+                    queue_id,
+                    e.to_errno(),
+                );
+                queue.require_recovery("submission publish failed", task_tag.index());
+                Ok(())
+            }
+        }
+    }
+
+    pub(crate) fn timeout(rq: &mq::Request<UfsLuBlockOps>, tag: u32) -> bool {
+        let queue = rq.queue_data().queue_arc().clone();
+        let disposition = rq.data_ref().inner.lock().timeout();
+        let cmd = match disposition {
+            TimeoutDisposition::StartRecovery(cmd) => {
+                queue.require_recovery("request timeout", tag as usize);
+                Some(cmd)
+            }
+            TimeoutDisposition::Recovering(cmd) => Some(cmd),
+            TimeoutDisposition::Pending(cmd) => Some(cmd),
+            TimeoutDisposition::Completed => return true,
+        };
+
+        if let Some(UfsCmd::Scsi(cmd)) = cmd {
+            let cdb = cmd.cdb();
+            pr_err!(
+                "[RUFS] ufs_queue: SCSI request timeout tag={} lun={} opcode=0x{:02x}\n",
+                tag,
+                cmd.lun(),
+                cdb[0],
+            );
+        } else {
+            pr_err!("[RUFS] ufs_queue: request timeout tag={}\n", tag);
+        }
+        // Do not release the tag until recovery has stopped hardware and
+        // prevented a late completion from referring to a reused request.
+        false
+    }
+
+    fn complete(
+        rq: Owned<mq::Request<UfsLuBlockOps>>,
+        task_tag: TaskTag,
+        queue_id: u32,
+        completion: TransferCompletion,
+    ) -> CompletionOutcome {
+        Self::complete_with(rq, task_tag, queue_id, completion, CompletionTarget::Direct)
+    }
+
+    fn complete_polled(
+        rq: Owned<mq::Request<UfsLuBlockOps>>,
+        task_tag: TaskTag,
+        queue_id: u32,
+        completion: TransferCompletion,
+        batch: &mut mq::IoCompletionBatch<UfsLuBlockOps>,
+    ) -> CompletionOutcome {
+        Self::complete_with(
+            rq,
+            task_tag,
+            queue_id,
+            completion,
+            CompletionTarget::Poll(batch),
+        )
+    }
+
+    fn complete_with(
+        rq: Owned<mq::Request<UfsLuBlockOps>>,
+        task_tag: TaskTag,
+        queue_id: u32,
+        completion: TransferCompletion,
+        target: CompletionTarget<'_>,
+    ) -> CompletionOutcome {
+        let request_queue = rq.queue_data().queue_arc().clone();
+        let completion_state = {
+            let mut request = rq.data_ref().inner.lock();
+            request.begin_completion(queue_id)
+        };
+        let (cmd, mapping) = match completion_state {
+            Ok(state) => state,
+            Err(_) => {
+                pr_err!(
+                    "[RUFS] ufs_queue: completion for inactive request tag={}\n",
+                    rq.tag(),
+                );
+                request_queue
+                    .require_recovery("completion for inactive request", rq.tag() as usize);
+                // Keep the request owned by the Rust blk-mq abstraction until
+                // recovery decides its final disposition.
+                drop(rq);
+                return CompletionOutcome::RetainedForRecovery;
+            }
+        };
+
+        match cmd {
+            UfsCmd::Device(cmd) => {
+                let Some(queue) = rq.queue_data().dev_queue() else {
+                    pr_err!("[RUFS] ufs_queue: device request has invalid context\n");
+                    complete_dma_mapping(mapping);
+                    let status = u32::from(bindings::BLK_STS_IOERR);
+                    rq.data_ref().inner.lock().reset();
+                    return Self::end_request(rq, status);
+                };
+                let result = queue.fetch_dev(cmd, task_tag, completion);
+                complete_dma_mapping(mapping);
+                let status = match result {
+                    Ok(UfsCmd::Device(cmd)) => {
+                        if rq.data_ref().inner.lock().complete_device(cmd).is_err() {
+                            pr_err!("[RUFS] ufs_queue: invalid device completion state\n");
+                            rq.data_ref().inner.lock().reset();
+                            u32::from(bindings::BLK_STS_IOERR)
+                        } else {
+                            u32::from(bindings::BLK_STS_OK)
+                        }
+                    }
+                    _ => {
+                        pr_err!("[RUFS] ufs_queue: failed to fetch device response\n");
+                        rq.data_ref().inner.lock().reset();
+                        u32::from(bindings::BLK_STS_IOERR)
+                    }
+                };
+                Self::end_request(rq, status)
+            }
+            UfsCmd::Scsi(cmd) => {
+                let Some(lu) = rq.queue_data().logical_unit() else {
+                    pr_err!("[RUFS] ufs_queue: SCSI request has invalid context\n");
+                    complete_dma_mapping(mapping);
+                    let status = u32::from(bindings::BLK_STS_IOERR);
+                    rq.data_ref().inner.lock().reset();
+                    return Self::end_request(rq, status);
+                };
+                let queue = &lu.queue;
+                let result = queue.fetch_scsi_completion(task_tag, completion);
+                complete_dma_mapping(mapping);
+
+                queue.clone().complete_scsi(cmd, result, rq, target)
+            }
+        }
+    }
+
+    fn end_request(rq: Owned<mq::Request<UfsLuBlockOps>>, status: u32) -> CompletionOutcome {
+        rq.end(u8::try_from(status).unwrap_or(bindings::BLK_STS_IOERR));
+        CompletionOutcome::Returned
+    }
+}
+
+#[pin_data]
+pub(crate) struct UfsQueue {
+    pub(crate) tags: Arc<TagSet<UfsLuBlockOps>>,
+    resources: Arc<HostResources>,
+    reg: Arc<UfsReg>,
+    dma: Arc<UfsDma>,
+    uic: Arc<UfsUic>,
+    backend: UfsTransferBackend,
+    #[pin]
+    recovery: SpinLock<RecoveryState>,
+    #[pin]
+    recovery_work: Work<UfsQueue>,
+}
+
+impl_has_work! {
+    impl HasWork<Self> for UfsQueue { self.recovery_work }
+}
+
+impl UfsQueue {
+    pub(crate) fn new(
+        config: UfsTransferConfig,
+        resources: Arc<HostResources>,
+        reg: Arc<UfsReg>,
+        dma: Arc<UfsDma>,
+        uic: Arc<UfsUic>,
+    ) -> Result<Arc<Self>> {
+        let backend = UfsTransferBackend::new(config, reg.clone(), dma.clone())?;
+        let hw_queues = backend.hw_queues()?;
+        let queue_map = config.queue_map()?;
+        let nr_hw_queues = queue_map.nr_hw_queues();
+        let queue_depth = config.queue_depth();
+        if queue_depth == 0 || nr_hw_queues == 0 || hw_queues.len() != nr_hw_queues {
+            return Err(EINVAL);
+        }
+
+        let tagset_data = KBox::new(
+            TagSetData {
+                queue_map,
+                hw_queues,
+                // One reserved vector array guarantees forward progress under
+                // memory pressure. Additional allocation failures are returned
+                // to blk-mq as resource shortages and retried.
+                dma_vec_mempool: MemPool::new(1)?,
+            },
+            GFP_KERNEL,
+        )?;
+
+        let mut tagset_flags = kernel::block::mq::tag_set::Flags::default();
+        tagset_flags |= kernel::block::mq::tag_set::Flag::TagHctxShared;
+        let tagset = Arc::pin_init(
+            TagSet::<UfsLuBlockOps>::new(
+                nr_hw_queues as u32,
+                tagset_data,
+                u32::try_from(queue_depth).map_err(|_| EOVERFLOW)?,
+                queue_map.num_maps(),
+                kernel::alloc::NumaNode::NO_NODE,
+                tagset_flags,
+            ),
+            GFP_KERNEL,
+        )?;
+
+        let queue = Arc::pin_init(
+            try_pin_init!(Self {
+                tags <- tagset,
+                resources,
+                reg,
+                dma,
+                uic,
+                backend,
+                recovery <- new_spinlock!(RecoveryState::Operational),
+                recovery_work <- new_work!("UfsQueue::recovery"),
+            }),
+            GFP_KERNEL,
+        )?;
+
+        Ok(queue)
+    }
+
+    pub(crate) fn begin_shutdown(&self) {
+        *self.recovery.lock() = RecoveryState::Shutdown;
+        self.tags.quiesce();
+    }
+
+    pub(crate) fn busy_requests(&self) -> usize {
+        self.tags.busy_request_count()
+    }
+
+    pub(crate) fn wait_completed_requests(&self) {
+        self.tags.wait_completed_requests();
+    }
+
+    pub(crate) fn flush_recovery_work(self: &Arc<Self>) {
+        // SAFETY: `UfsQueue` was initialized in an `Arc` with `pin_init!`.
+        // The allocation remains stable while this `Arc` is alive, so its
+        // structurally pinned recovery work cannot move.
+        let work = unsafe { Pin::new_unchecked(&self.recovery_work) };
+        work.flush();
+    }
+
+    pub(crate) fn enable_interrupts(&self) {
+        self.backend.enable_interrupts();
+    }
+
+    fn completion_pass_limit(&self) -> usize {
+        let queue_depth = self.tags.queue_depth() as usize;
+        core::cmp::max(1, queue_depth.div_ceil(CompletedRequests::capacity()))
+    }
+
+    fn recovery_required(&self) -> bool {
+        self.recovery.lock().cause().is_some()
+    }
+
+    fn stop_controller(&self) -> Result<DmaAccessEnded> {
+        self.reg.disable_interrupts();
+        self.reg.clear_all_interrupts();
+        self.reg.disable_run_stop();
+        if self.reg.ctrl_enabled() {
+            self.reg.ctrl_disable();
+            self.reg.wait_for_ctrl_disable(10, 10)?;
+        }
+        Ok(DmaAccessEnded)
+    }
+
+    fn reset_controller(&self) -> (Option<DmaAccessEnded>, Result<()>) {
+        let dma_ended = match self.stop_controller() {
+            Ok(dma_ended) => dma_ended,
+            Err(e) => return (None, Err(e)),
+        };
+
+        let result = (|| {
+            let variant = self.resources.variant();
+            variant.device_reset()?;
+            variant.hce_enable_notify(&self.reg, NotifyPhase::Pre)?;
+            self.reg.ctrl_enable();
+            fsleep(Delta::from_micros(HBA_ENABLE_DELAY_US));
+            self.reg.wait_for_ctrl_enable(1000, 50)?;
+            variant.hce_enable_notify(&self.reg, NotifyPhase::Post)?;
+
+            variant.link_startup_notify(&self.reg, &self.uic, NotifyPhase::Pre)?;
+            self.uic.link_startup()?;
+            variant.link_startup_notify(&self.reg, &self.uic, NotifyPhase::Post)?;
+
+            // Restore the common UTRL/UTMRL state and backend-specific state
+            // before re-enabling their interrupts. The queue handler remains
+            // registered throughout recovery, matching the ordering used
+            // during initial host bring-up.
+            self.dma.make_hba_operational()?;
+            self.backend.reset()?;
+            self.enable_interrupts();
+
+            if let Err(e) = self.restore_power_mode(variant) {
+                pr_warn!(
+                    "[RUFS] ufs_queue: recovery power mode restore failed errno={}, continue\n",
+                    e.to_errno(),
+                );
+            }
+            Ok(())
+        })();
+
+        (Some(dma_ended), result)
+    }
+
+    fn restore_power_mode(&self, variant: &dyn UfsVariantOps) -> Result<()> {
+        let mode = variant.constrain_power_mode(self.uic.max_power_mode()?)?;
+        variant.power_mode_notify(&self.reg, &self.uic, mode, NotifyPhase::Pre)?;
+        self.uic.change_power_mode(mode)?;
+        variant.power_mode_notify(&self.reg, &self.uic, mode, NotifyPhase::Post)
+    }
+
+    fn dispose_recovery_request(
+        &self,
+        task_tag: TaskTag,
+        requeue: bool,
+        dma_ended: Option<&DmaAccessEnded>,
+    ) -> Result<bool> {
+        let rq = match self.take_request_at_task_tag(task_tag) {
+            Ok(Some(rq)) => rq,
+            Ok(None) | Err(EBUSY) => return Ok(false),
+            Err(e) => return Err(e),
+        };
+        rq.data_ref()
+            .inner
+            .lock()
+            .prepare_recovery_disposition(requeue, dma_ended)?;
+
+        if requeue {
+            rq.requeue(true);
+        } else {
+            rq.end(bindings::BLK_STS_IOERR);
+        }
+        Ok(true)
+    }
+
+    fn dispose_recovery_requests(
+        &self,
+        requeue: bool,
+        dma_ended: Option<&DmaAccessEnded>,
+    ) -> Result<usize> {
+        self.tags.wait_completed_requests();
+        let expected = self.busy_requests();
+        let mut disposed = 0;
+        let mut failed = false;
+
+        for tag in 0..self.tags.queue_depth() {
+            let task_tag = TaskTag::new(tag)?;
+            match self.dispose_recovery_request(task_tag, requeue, dma_ended) {
+                Ok(true) => disposed += 1,
+                Ok(false) => continue,
+                Err(e) => {
+                    pr_err!(
+                        "[RUFS] ufs_queue: recovery request disposition failed tag={} errno={}\n",
+                        tag,
+                        e.to_errno(),
+                    );
+                    failed = true;
+                }
+            }
+        }
+
+        let remaining = self.busy_requests();
+        if failed || disposed != expected || remaining != 0 {
+            pr_err!(
+                "rufs: recovery mismatch: expected={} disposed={} remaining={}\n",
+                expected,
+                disposed,
+                remaining,
+            );
+            Err(EIO)
+        } else {
+            Ok(disposed)
+        }
+    }
+
+    pub(crate) fn require_recovery(self: &Arc<Self>, reason: &'static str, tag: usize) {
+        self.request_recovery(RecoveryCause {
+            reason: RecoveryReason::Driver(reason),
+            scope: RecoveryScope::Controller,
+            tag,
+        });
+    }
+
+    pub(crate) fn require_uic_recovery(self: &Arc<Self>, errors: UicErrorStatus) {
+        self.request_recovery(RecoveryCause {
+            reason: RecoveryReason::Uic(errors),
+            scope: RecoveryScope::Controller,
+            tag: 0,
+        });
+    }
+
+    fn require_mcq_recovery(self: &Arc<Self>, queue_id: u32, tag: usize) {
+        self.request_recovery(RecoveryCause {
+            reason: RecoveryReason::InvalidMcqCompletion,
+            scope: RecoveryScope::Queue(queue_id),
+            tag,
+        });
+    }
+
+    fn request_recovery(self: &Arc<Self>, cause: RecoveryCause) {
+        let schedule = {
+            let mut state = self.recovery.lock();
+            if matches!(*state, RecoveryState::Operational) {
+                *state = RecoveryState::Requested(cause);
+                true
+            } else {
+                false
+            }
+        };
+
+        if schedule {
+            pr_err!(
+                "[RUFS] ufs_queue: recovery required reason={} queue={:?} tag={}\n",
+                cause.reason.name(),
+                cause.scope.queue_id(),
+                cause.tag,
+            );
+            let _ = workqueue::system().enqueue(self.clone());
+        }
+    }
+
+    // Issuing
+    pub(crate) fn compose_dev(&self, cmd: UfsDevCmd, task_tag: TaskTag) -> Result<()> {
+        self.dma
+            .compose_devman_upiu(cmd, u32::from(task_tag.value()))
+    }
+
+    fn compose_scsi(
+        rq: &Owned<mq::Request<UfsLuBlockOps>>,
+        cmd: UfsSCSICmd,
+        task_tag: TaskTag,
+        mempool: &DmaMapMempool<MAX_PRD_ENTRIES>,
+    ) -> Result<UfsPreparedMapping> {
+        let queue = rq.queue_data().queue();
+
+        queue
+            .dma
+            .compose_scsi_upiu(rq, cmd, task_tag.value(), mempool)
+    }
+
+    fn fetch_dev(
+        &self,
+        cmd: UfsDevCmd,
+        task_tag: TaskTag,
+        completion: TransferCompletion,
+    ) -> Result<UfsCmd> {
+        match completion {
+            TransferCompletion::Sdb => self.dma.fetch_devman_upiu(cmd, task_tag.index()),
+            TransferCompletion::Mcq(cqe) => {
+                self.dma.fetch_mcq_devman_upiu(cmd, task_tag.index(), cqe)
+            }
+        }
+    }
+
+    fn fetch_scsi_completion(
+        &self,
+        task_tag: TaskTag,
+        completion: TransferCompletion,
+    ) -> UfsScsiResult {
+        match completion {
+            TransferCompletion::Sdb => self.dma.fetch_scsi_completion(task_tag.index()),
+            TransferCompletion::Mcq(cqe) => {
+                self.dma.fetch_mcq_scsi_completion(task_tag.index(), cqe)
+            }
+        }
+    }
+
+    fn collect_backend_completions(&self, completed: &mut CompletedRequests) -> Result<()> {
+        self.backend.collect_completions(completed)
+    }
+
+    pub(crate) fn interrupt_queues(&self) -> &[McqInterruptQueue] {
+        self.backend.interrupt_queues()
+    }
+
+    fn dump_backend_state(&self, tag: usize, reason: &str) {
+        self.backend.dump_state(tag, reason);
+    }
+
+    fn take_request_at_task_tag(
+        &self,
+        task_tag: TaskTag,
+    ) -> Result<Option<Owned<mq::Request<UfsLuBlockOps>>>> {
+        let Some(rq) = self
+            .tags
+            .try_shared_tag_to_rq(u32::from(task_tag.value()))?
+        else {
+            return Ok(None);
+        };
+
+        OwnableRefCounted::try_from_shared(rq)
+            .map(Some)
+            .map_err(|_| EBUSY)
+    }
+
+    fn resolve_completion(
+        self: &Arc<Self>,
+        request: CompletedRequest,
+    ) -> Option<ResolvedCompletion> {
+        let task_tag = request.task_tag();
+        let queue_id = request.queue_id();
+        match self.take_request_at_task_tag(task_tag) {
+            Ok(Some(rq)) => {
+                if rq.tag() != u32::from(task_tag.value()) || rq.queue_index() != queue_id {
+                    self.require_recovery("completion queue mismatch", task_tag.index());
+                    return None;
+                }
+                Some(ResolvedCompletion {
+                    rq,
+                    task_tag,
+                    queue_id,
+                    completion: request.completion(),
+                })
+            }
+            Ok(None) => {
+                self.require_recovery("completion tag has no request", task_tag.index());
+                None
+            }
+            Err(EBUSY) => {
+                self.require_recovery("completion ownership conflict", task_tag.index());
+                None
+            }
+            Err(_) => {
+                self.require_recovery("completion request lookup failed", task_tag.index());
+                None
+            }
+        }
+    }
+
+    fn complete_from<F>(self: &Arc<Self>, mut collect: F, queue_id: Option<u32>) -> bool
+    where
+        F: FnMut(&mut CompletedRequests) -> Result<()>,
+    {
+        if self.recovery_required() {
+            return false;
+        }
+        // Completion is tag-driven: the backend collects completed tags, then
+        // the queue finalizes exactly those requests. Finalization still runs
+        // from the threaded IRQ path because it takes request, backend, and DMA
+        // locks that are shared with submission and hands requests back to
+        // blk-mq. Once those lock domains are IRQ-safe, this path can move into
+        // hard IRQ context.
+        let mut any_completed = false;
+        for _ in 0..self.completion_pass_limit() {
+            let mut requests = CompletedRequests::new();
+            let collect_result = collect(&mut requests);
+
+            let batch_full = requests.is_full();
+            while let Some(request) = requests.take_next() {
+                if let Some(completion) = self.resolve_completion(request) {
+                    any_completed |= completion.complete().returned();
+                }
+            }
+
+            if let Some(fault) = requests.take_fault() {
+                if let Some(queue_id) = fault.queue_id {
+                    self.require_mcq_recovery(queue_id, fault.tag);
+                } else {
+                    self.require_recovery(fault.reason, fault.tag);
+                }
+                return any_completed;
+            }
+            if let Err(e) = collect_result {
+                if let Some(queue_id) = queue_id {
+                    pr_err!(
+                        "[RUFS] ufs_queue: collect queue {} completions failed errno={}\n",
+                        queue_id,
+                        e.to_errno(),
+                    );
+                    self.dump_backend_state(0, "collect queue failed");
+                    self.require_mcq_recovery(queue_id, 0);
+                } else {
+                    pr_err!(
+                        "[RUFS] ufs_queue: collect completions failed errno={}\n",
+                        e.to_errno(),
+                    );
+                    self.dump_backend_state(0, "collect completions failed");
+                    self.require_recovery("completion collection failed", 0);
+                }
+                return any_completed;
+            }
+            if !batch_full {
+                break;
+            }
+        }
+
+        any_completed
+    }
+
+    pub(crate) fn complete(self: &Arc<Self>) -> bool {
+        self.complete_from(|requests| self.collect_backend_completions(requests), None)
+    }
+
+    pub(crate) fn complete_queue(self: &Arc<Self>, interrupt_queue: &McqInterruptQueue) -> bool {
+        let queue_id = interrupt_queue.id();
+        self.complete_from(
+            |requests| interrupt_queue.collect_completions(requests),
+            Some(queue_id),
+        )
+    }
+
+    pub(crate) fn poll(
+        self: &Arc<Self>,
+        hw_queue: &UfsHwQueue,
+        batch: &mut mq::IoCompletionBatch<UfsLuBlockOps>,
+    ) -> bool {
+        if self.recovery_required() {
+            return false;
+        }
+        let mut any_completed = false;
+        for _ in 0..self.completion_pass_limit() {
+            let mut requests = CompletedRequests::new();
+            let poll_result = hw_queue.poll(&mut requests);
+
+            let batch_full = requests.is_full();
+            while let Some(request) = requests.take_next() {
+                if let Some(completion) = self.resolve_completion(request) {
+                    any_completed |= completion.complete_polled(batch).returned();
+                }
+            }
+
+            if let Some(fault) = requests.take_fault() {
+                if let Some(queue_id) = fault.queue_id {
+                    self.require_mcq_recovery(queue_id, fault.tag);
+                } else {
+                    self.require_recovery(fault.reason, fault.tag);
+                }
+                return any_completed;
+            }
+            if let Err(e) = poll_result {
+                pr_err!(
+                    "[RUFS] ufs_queue: poll queue {} failed errno={}\n",
+                    hw_queue.id(),
+                    e.to_errno(),
+                );
+                self.require_recovery(
+                    "polled completion collection failed",
+                    hw_queue.id() as usize,
+                );
+                return any_completed;
+            }
+            if !batch_full {
+                break;
+            }
+        }
+
+        any_completed
+    }
+
+    fn complete_scsi(
+        self: &Arc<Self>,
+        cmd: UfsSCSICmd,
+        result: UfsScsiResult,
+        rq: Owned<mq::Request<UfsLuBlockOps>>,
+        target: CompletionTarget<'_>,
+    ) -> CompletionOutcome {
+        let tag = rq.tag();
+        let sense_len = result.sense_data_len.min(result.sense_data.len());
+        let sense = parse_scsi_sense(&result.sense_data, sense_len);
+        let suppress_log = matches!(result.completion, UfsScsiCompletion::CheckCondition)
+            && matches!(sense.as_ref(), Some(sense) if sense.is_power_on_reset());
+        let requeue = should_requeue_scsi(result.completion, sense.as_ref());
+
+        if !matches!(result.completion, UfsScsiCompletion::Good) && !suppress_log {
+            let cdb = cmd.cdb();
+            pr_err!(
+                "[RUFS] ufs_queue: SCSI request completion error: tag={} lun={} \
+                 opcode=0x{:02x} dir={:?} data_len={} completion={:?} ocs=0x{:x} \
+                 transaction=0x{:02x} response=0x{:02x} status=0x{:02x} residual={} \
+                 cdb={:02x} {:02x} {:02x} {:02x} {:02x} {:02x} {:02x} {:02x} \
+                 {:02x} {:02x} {:02x} {:02x} {:02x} {:02x} {:02x} {:02x}\n",
+                tag,
+                cmd.lun(),
+                cdb[0],
+                cmd.direction(),
+                cmd.data_len(),
+                result.completion,
+                result.ocs,
+                result.transaction,
+                result.response,
+                result.status,
+                result.residual_transfer_count,
+                cdb[0],
+                cdb[1],
+                cdb[2],
+                cdb[3],
+                cdb[4],
+                cdb[5],
+                cdb[6],
+                cdb[7],
+                cdb[8],
+                cdb[9],
+                cdb[10],
+                cdb[11],
+                cdb[12],
+                cdb[13],
+                cdb[14],
+                cdb[15],
+            );
+
+            if let Some(sense) = sense.as_ref() {
+                pr_err!(
+                    "[RUFS] ufs_queue: SCSI sense tag={} response_code=0x{:02x} \
+                     sense_key=0x{:x}({}) asc=0x{:02x} ascq=0x{:02x} \
+                     additional_len={}\n",
+                    tag,
+                    sense.response_code,
+                    sense.sense_key,
+                    sense_key_name(sense.sense_key),
+                    sense.asc,
+                    sense.ascq,
+                    sense.additional_len,
+                );
+            } else if sense_len > 0 {
+                pr_err!(
+                    "[RUFS] ufs_queue: SCSI sense tag={} unable to parse \
+                     sense_len={} raw={:02x} {:02x} {:02x} {:02x} {:02x} \
+                     {:02x} {:02x} {:02x} {:02x} {:02x} {:02x} {:02x} \
+                     {:02x} {:02x} {:02x} {:02x} {:02x} {:02x}\n",
+                    tag,
+                    sense_len,
+                    result.sense_data[0],
+                    result.sense_data[1],
+                    result.sense_data[2],
+                    result.sense_data[3],
+                    result.sense_data[4],
+                    result.sense_data[5],
+                    result.sense_data[6],
+                    result.sense_data[7],
+                    result.sense_data[8],
+                    result.sense_data[9],
+                    result.sense_data[10],
+                    result.sense_data[11],
+                    result.sense_data[12],
+                    result.sense_data[13],
+                    result.sense_data[14],
+                    result.sense_data[15],
+                    result.sense_data[16],
+                    result.sense_data[17],
+                );
+            } else {
+                pr_err!(
+                    "[RUFS] ufs_queue: SCSI sense tag={} no sense data reported\n",
+                    tag,
+                );
+            }
+        }
+
+        let status = match result.completion {
+            UfsScsiCompletion::Good => bindings::BLK_STS_OK,
+            UfsScsiCompletion::Busy
+            | UfsScsiCompletion::TaskSetFull
+            | UfsScsiCompletion::Requeue => bindings::BLK_STS_RESOURCE,
+            UfsScsiCompletion::TaskAborted => bindings::BLK_STS_TARGET,
+            UfsScsiCompletion::ReservationConflict => bindings::BLK_STS_RESV_CONFLICT,
+            UfsScsiCompletion::CheckCondition => {
+                if retryable_check_condition(sense.as_ref()) {
+                    bindings::BLK_STS_RESOURCE
+                } else {
+                    bindings::BLK_STS_IOERR
+                }
+            }
+            UfsScsiCompletion::Error => bindings::BLK_STS_IOERR,
+        };
+
+        let status = u32::from(status);
+        let disposition = if requeue {
+            CompletionDisposition::Requeue
+        } else {
+            CompletionDisposition::End(status)
+        };
+        match target {
+            CompletionTarget::Direct => {
+                if rq
+                    .data_ref()
+                    .inner
+                    .lock()
+                    .schedule_completion(disposition)
+                    .is_err()
+                {
+                    self.require_recovery("invalid SCSI completion state", tag as usize);
+                    rq.data_ref().inner.lock().reset();
+                    rq.end(bindings::BLK_STS_IOERR);
+                    return CompletionOutcome::Returned;
+                }
+                mq::Request::complete(OwnableRefCounted::into_shared(rq));
+                CompletionOutcome::Returned
+            }
+            CompletionTarget::Poll(batch) => {
+                if rq
+                    .data_ref()
+                    .inner
+                    .lock()
+                    .finish_direct_completion()
+                    .is_err()
+                {
+                    self.require_recovery("invalid polled completion state", tag as usize);
+                    rq.data_ref().inner.lock().reset();
+                    rq.end(bindings::BLK_STS_IOERR);
+                    return CompletionOutcome::Returned;
+                }
+                if requeue {
+                    rq.requeue(true);
+                    return CompletionOutcome::Returned;
+                }
+                if status != u32::from(bindings::BLK_STS_OK) {
+                    rq.end(u8::try_from(status).unwrap_or(bindings::BLK_STS_IOERR));
+                    return CompletionOutcome::Returned;
+                }
+
+                if let Err(rq) = batch.add_request(rq, false) {
+                    rq.end(status as u8);
+                }
+                CompletionOutcome::Returned
+            }
+        }
+    }
+}
+
+impl WorkItem for UfsQueue {
+    type Pointer = Arc<Self>;
+
+    fn run(this: Arc<Self>) {
+        let cause = {
+            let mut state = this.recovery.lock();
+            let RecoveryState::Requested(cause) = *state else {
+                return;
+            };
+            *state = RecoveryState::Quiescing(cause);
+            cause
+        };
+
+        this.tags.quiesce();
+
+        {
+            let mut state = this.recovery.lock();
+            if matches!(*state, RecoveryState::Quiescing(_)) {
+                *state = RecoveryState::Recovering(cause);
+            } else {
+                return;
+            }
+        }
+
+        pr_info!(
+            "[RUFS] ufs_queue: controller recovery started reason={} queue={:?} tag={}\n",
+            cause.reason.name(),
+            cause.scope.queue_id(),
+            cause.tag,
+        );
+        if let Some(errors) = cause.reason.uic_errors() {
+            pr_err!(
+                "rufs: UIC error: phy={:08x} dl={:08x} nl={:08x} tl={:08x} dme={:08x}\n",
+                errors.phy,
+                errors.data_link,
+                errors.network,
+                errors.transport,
+                errors.dme,
+            );
+        }
+        // A controller reset makes every command that was visible to the old
+        // controller instance unreachable. Only after that boundary may RUFS
+        // return their blk-mq tags: requeue them when the new link is usable,
+        // or finish them with I/O error when reset failed.
+        let (mut dma_ended, reset) = this.reset_controller();
+        let requeue = reset.is_ok();
+        if reset.is_err() {
+            if let Ok(stopped) = this.stop_controller() {
+                dma_ended = Some(stopped);
+            }
+        }
+        let disposition = this.dispose_recovery_requests(requeue, dma_ended.as_ref());
+
+        match (reset, disposition) {
+            (Ok(()), Ok(disposed)) => {
+                let resume = {
+                    let mut state = this.recovery.lock();
+                    if matches!(*state, RecoveryState::Recovering(_)) {
+                        *state = RecoveryState::Operational;
+                        true
+                    } else {
+                        false
+                    }
+                };
+                if resume {
+                    this.tags.unquiesce();
+                    pr_info!(
+                        "[RUFS] ufs_queue: controller recovery completed requeued={}\n",
+                        disposed,
+                    );
+                }
+            }
+            (reset, disposition) => {
+                if let Err(e) = reset {
+                    pr_err!(
+                        "[RUFS] ufs_queue: controller recovery reset failed errno={}\n",
+                        e.to_errno(),
+                    );
+                }
+                if let Err(e) = disposition {
+                    pr_err!(
+                        "[RUFS] ufs_queue: recovery request cleanup failed errno={}\n",
+                        e.to_errno(),
+                    );
+                }
+                let mut state = this.recovery.lock();
+                if matches!(*state, RecoveryState::Recovering(_)) {
+                    *state = RecoveryState::Failed(cause);
+                }
+            }
+        }
+    }
+}
diff --git a/drivers/rufs/reg.rs b/drivers/rufs/reg.rs
new file mode 100644
index 0000000000000..afa86237c63c1
--- /dev/null
+++ b/drivers/rufs/reg.rs
@@ -0,0 +1,1445 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#![allow(dead_code)]
+
+use kernel::io::{poll::read_poll_timeout, register, register::Register, Io};
+use kernel::time::Delta;
+use kernel::{prelude::*, sync::Arc};
+
+use crate::resource::HostResources;
+
+register! {
+    CONTROLLER_CAPABILITIES(u32) @ 0x00 {
+        30:30 mcq_supported => bool;
+        23:23 auto_hibern8_supported => bool;
+        18:16 task_management_request_slots;
+        15:8 number_outstanding_rtt;
+        4:0 transfer_request_slots_sdb;
+    }
+    CONTROLLER_CAPABILITIES_MCQ(u32) => CONTROLLER_CAPABILITIES {
+        7:0 transfer_request_slots;
+    }
+    MCQCAP(u32) @ 0x04 {
+        23:16 queue_config_pointer;
+        7:0 max_queue_supported;
+    }
+    CONTROLLER_CAPABILITIES_H(u32) @ 0x04 {
+        31:0 value;
+    }
+    UFS_VERSION(u32) @ 0x08 {
+        31:0 value;
+    }
+    INTERRUPT_STATUS(u32) @ 0x20 {
+        31:0 value;
+    }
+    INTERRUPT_ENABLE(u32) @ 0x24 {
+        31:0 value;
+    }
+    CONTROLLER_STATUS(u32) @ 0x30 {
+        10:8 power_mode_change_request_status;
+        5:5 device_error_indicator => bool;
+        4:4 host_error_indicator => bool;
+        3:3 uic_command_ready => bool;
+        2:2 task_request_list_ready => bool;
+        1:1 transfer_request_list_ready => bool;
+        0:0 device_present => bool;
+    }
+    CONTROLLER_ENABLE_REG(u32) @ 0x34 {
+        1:1 crypto_general_enable => bool;
+        0:0 controller_enable => bool;
+    }
+    UIC_ERROR_CODE_PHY_ADAPTER_LAYER(u32) @ 0x38 {
+        31:0 value;
+    }
+    UIC_ERROR_CODE_DATA_LINK_LAYER(u32) @ 0x3C {
+        31:0 value;
+    }
+    UIC_ERROR_CODE_NETWORK_LAYER(u32) @ 0x40 {
+        31:0 value;
+    }
+    UIC_ERROR_CODE_TRANSPORT_LAYER(u32) @ 0x44 {
+        31:0 value;
+    }
+    UIC_ERROR_CODE_DME(u32) @ 0x48 {
+        31:0 value;
+    }
+    UTP_TRANSFER_REQ_INT_AGG_CONTROL(u32) @ 0x4C {
+        31:0 value;
+    }
+    UTP_TRANSFER_REQ_LIST_BASE_L(u32) @ 0x50 {
+        31:0 value;
+    }
+    UTP_TRANSFER_REQ_LIST_BASE_H(u32) @ 0x54 {
+        31:0 value;
+    }
+    UTP_TRANSFER_REQ_DOOR_BELL(u32) @ 0x58 {
+        31:0 value;
+    }
+    UTP_TRANSFER_REQ_LIST_CLEAR(u32) @ 0x5C {
+        31:0 value;
+    }
+    UTP_TRANSFER_REQ_LIST_RUN_STOP(u32) @ 0x60 {
+        31:0 value;
+    }
+    UTP_TRANSFER_REQ_LIST_COMPLETION_NOTIFICATION(u32) @ 0x64 {
+        31:0 value;
+    }
+    UTP_TASK_REQ_LIST_BASE_L(u32) @ 0x70 {
+        31:0 value;
+    }
+    UTP_TASK_REQ_LIST_BASE_H(u32) @ 0x74 {
+        31:0 value;
+    }
+    UTP_TASK_REQ_DOOR_BELL(u32) @ 0x78 {
+        31:0 value;
+    }
+    UTP_TASK_REQ_LIST_CLEAR(u32) @ 0x7C {
+        31:0 value;
+    }
+    UTP_TASK_REQ_LIST_RUN_STOP(u32) @ 0x80 {
+        31:0 value;
+    }
+    UIC_COMMAND(u32) @ 0x90 {
+        31:0 value;
+    }
+    UIC_ARG1(u32) @ 0x94 {
+        31:0 value;
+    }
+    UIC_ARG2(u32) @ 0x98 {
+        7:0 command_result;
+    }
+    UIC_ARG3(u32) @ 0x9C {
+        31:0 value;
+    }
+    UFS_MEM_CFG(u32) @ 0x300 {
+        1:1 esi_enable => bool;
+        0:0 mcq_mode_select => bool;
+    }
+    UFS_MCQ_CFG(u32) @ 0x380 {
+        16:8 max_active_cmds;
+    }
+    UFS_ESILBA(u32) @ 0x384 {
+        31:0 value;
+    }
+    UFS_ESIUBA(u32) @ 0x388 {
+        31:0 value;
+    }
+}
+
+struct McqQueueCfgBase;
+
+register! {
+    MCQ_SQATTR(u32) @ McqQueueCfgBase + 0x00 {
+        31:31 enable => bool;
+        23:16 cq_id;
+        15:0 size;
+    }
+    MCQ_SQLBA(u32) @ McqQueueCfgBase + 0x04 { 31:0 value; }
+    MCQ_SQUBA(u32) @ McqQueueCfgBase + 0x08 { 31:0 value; }
+    MCQ_SQDAO(u32) @ McqQueueCfgBase + 0x0c { 31:0 value; }
+    MCQ_SQISAO(u32) @ McqQueueCfgBase + 0x10 { 31:0 value; }
+    MCQ_CQATTR(u32) @ McqQueueCfgBase + 0x20 {
+        31:31 enable => bool;
+        15:0 size;
+    }
+    MCQ_CQLBA(u32) @ McqQueueCfgBase + 0x24 { 31:0 value; }
+    MCQ_CQUBA(u32) @ McqQueueCfgBase + 0x28 { 31:0 value; }
+    MCQ_CQDAO(u32) @ McqQueueCfgBase + 0x2c { 31:0 value; }
+    MCQ_CQISAO(u32) @ McqQueueCfgBase + 0x30 { 31:0 value; }
+}
+
+struct McqOprBase;
+
+register! {
+    MCQ_SQHP(u32) @ McqOprBase + 0x00 { 31:0 value; }
+    MCQ_SQTP(u32) @ McqOprBase + 0x04 { 31:0 value; }
+    MCQ_SQRTC(u32) @ McqOprBase + 0x08 {
+        2:2 initiate_cleanup => bool;
+        1:0 operation;
+    }
+    MCQ_SQCTI(u32) @ McqOprBase + 0x0c {
+        15:8 lun;
+        7:0 task_tag;
+    }
+    MCQ_SQRTS(u32) @ McqOprBase + 0x10 {
+        7:4 cleanup_error_code;
+        1:1 cleanup_in_progress => bool;
+        0:0 stopped => bool;
+    }
+    MCQ_CQHP(u32) @ McqOprBase + 0x00 { 31:0 value; }
+    MCQ_CQTP(u32) @ McqOprBase + 0x04 { 31:0 value; }
+    MCQ_CQIS(u32) @ McqOprBase + 0x00 {
+        0:0 tail_entry_pushed => bool;
+    }
+    MCQ_CQIE(u32) @ McqOprBase + 0x04 {
+        0:0 tail_entry_push_enable => bool;
+    }
+}
+
+const MCQ_QCFG_STRIDE: usize = 0x40;
+const MCQ_QCFGPTR_UNIT: usize = 0x200;
+const MCQ_ENTRY_SIZE_IN_DWORD: u32 = 8;
+const MCQ_DEFAULT_OPR_STRIDE: usize = 48;
+const MCQ_POLL_INTERVAL_US: i64 = 20;
+const MCQ_POLL_TIMEOUT_US: i64 = 500000;
+
+const MCQ_SQ_START: u32 = 0x0;
+const MCQ_SQ_STOP: u32 = 0x1;
+
+// IS - Interrupt Status
+const UTP_TRANSFER_REQ_COMPL: u32 = 0x00000001;
+const UIC_DME_END_PT_RESET: u32 = 0x00000002;
+const UIC_ERROR: u32 = 0x00000004;
+const UIC_TEST_MODE: u32 = 0x00000008;
+const UIC_POWER_MODE: u32 = 0x00000010;
+const UIC_HIBERNATE_EXIT: u32 = 0x00000020;
+const UIC_HIBERNATE_ENTER: u32 = 0x00000040;
+const UIC_LINK_LOST: u32 = 0x00000080;
+const UIC_LINK_STARTUP: u32 = 0x00000100;
+const UTP_TASK_REQ_COMPL: u32 = 0x00000200;
+const UIC_COMMAND_COMPL: u32 = 0x00000400;
+const DEVICE_FATAL_ERROR: u32 = 0x00000800;
+const UTP_ERROR: u32 = 0x00001000;
+const CONTROLLER_FATAL_ERROR: u32 = 0x00010000;
+const SYSTEM_BUS_FATAL_ERROR: u32 = 0x00020000;
+const CRYPTO_ENGINE_FATAL_ERROR: u32 = 0x00040000;
+const MCQ_CQ_EVENT_STATUS: u32 = 0x00100000;
+
+const UIC_INTR_HIBERNATE_MASK: u32 = UIC_HIBERNATE_EXIT | UIC_HIBERNATE_ENTER;
+const UIC_INTR_POWER_MASK: u32 = UIC_POWER_MODE | UIC_INTR_HIBERNATE_MASK;
+const UIC_INTR_MASK: u32 = UIC_INTR_POWER_MASK | UIC_COMMAND_COMPL;
+
+const UTP_REQ_COMPL_MASK: u32 = UTP_TRANSFER_REQ_COMPL;
+const ERROR_MASK: u32 = UIC_ERROR
+    | UIC_LINK_LOST
+    | DEVICE_FATAL_ERROR
+    | CONTROLLER_FATAL_ERROR
+    | SYSTEM_BUS_FATAL_ERROR
+    | CRYPTO_ENGINE_FATAL_ERROR
+    | UTP_ERROR;
+
+const UIC_ERROR_FLAG: u32 = 1 << 31;
+const UIC_DL_PA_INIT_ERROR: u32 = 1 << 13;
+const UIC_NL_ERROR_CODE_MASK: u32 = 0x7;
+const UIC_TL_ERROR_CODE_MASK: u32 = 0x7f;
+const UIC_DME_ERROR_CODE_MASK: u32 = 0x1;
+
+#[derive(Copy, Clone, Debug)]
+pub(crate) struct UicErrorStatus {
+    pub(crate) phy: u32,
+    pub(crate) data_link: u32,
+    pub(crate) network: u32,
+    pub(crate) transport: u32,
+    pub(crate) dme: u32,
+}
+
+impl UicErrorStatus {
+    pub(crate) fn requires_recovery(&self) -> bool {
+        self.data_link & (UIC_ERROR_FLAG | UIC_DL_PA_INIT_ERROR)
+            == UIC_ERROR_FLAG | UIC_DL_PA_INIT_ERROR
+            || self.network & (UIC_ERROR_FLAG | UIC_NL_ERROR_CODE_MASK) > UIC_ERROR_FLAG
+            || self.transport & (UIC_ERROR_FLAG | UIC_TL_ERROR_CODE_MASK) > UIC_ERROR_FLAG
+            || self.dme & (UIC_ERROR_FLAG | UIC_DME_ERROR_CODE_MASK) > UIC_ERROR_FLAG
+    }
+}
+
+pub(crate) enum PowerMode {
+    OK = 0x00,
+    Local = 0x01,
+    Remote = 0x02,
+    Busy = 0x03,
+    ErrorCap = 0x04,
+    FatalError = 0x05,
+}
+
+#[derive(Clone, Copy)]
+pub(crate) enum McqRegisterRegion {
+    Hci,
+    Mcq,
+}
+
+#[derive(Clone, Copy)]
+pub(crate) enum UfsMcqOprRegion {
+    Sqd,
+    Sqis,
+    Cqd,
+    Cqis,
+}
+
+#[derive(Clone, Copy)]
+pub(crate) struct UfsMcqOprInfo {
+    region: McqRegisterRegion,
+    register_offset: usize,
+    config_offset: usize,
+    stride: usize,
+}
+
+impl UfsMcqOprInfo {
+    pub(crate) fn new(
+        region: McqRegisterRegion,
+        register_offset: usize,
+        config_offset: usize,
+        stride: usize,
+    ) -> Self {
+        Self {
+            region,
+            register_offset,
+            config_offset,
+            stride,
+        }
+    }
+
+    fn register_offset(&self, queue: usize) -> usize {
+        self.register_offset + self.stride * queue
+    }
+
+    fn config_offset(&self, queue: usize) -> usize {
+        self.config_offset + self.stride * queue
+    }
+}
+
+#[derive(Clone, Copy)]
+pub(crate) struct UfsMcqOprSet {
+    sqd: UfsMcqOprInfo,
+    sqis: UfsMcqOprInfo,
+    cqd: UfsMcqOprInfo,
+    cqis: UfsMcqOprInfo,
+}
+
+impl UfsMcqOprSet {
+    pub(crate) fn new(
+        sqd: UfsMcqOprInfo,
+        sqis: UfsMcqOprInfo,
+        cqd: UfsMcqOprInfo,
+        cqis: UfsMcqOprInfo,
+    ) -> Self {
+        Self {
+            sqd,
+            sqis,
+            cqd,
+            cqis,
+        }
+    }
+
+    fn get(&self, region: UfsMcqOprRegion) -> UfsMcqOprInfo {
+        match region {
+            UfsMcqOprRegion::Sqd => self.sqd,
+            UfsMcqOprRegion::Sqis => self.sqis,
+            UfsMcqOprRegion::Cqd => self.cqd,
+            UfsMcqOprRegion::Cqis => self.cqis,
+        }
+    }
+}
+
+#[derive(Clone, Copy)]
+pub(crate) struct McqQueueConfigLayout {
+    region: McqRegisterRegion,
+    offset: usize,
+    stride: usize,
+}
+
+impl McqQueueConfigLayout {
+    pub(crate) fn new(region: McqRegisterRegion, offset: usize, stride: usize) -> Self {
+        Self {
+            region,
+            offset,
+            stride,
+        }
+    }
+}
+
+#[derive(Clone, Copy)]
+pub(crate) struct McqRegisterLayout {
+    queue_config: McqQueueConfigLayout,
+    oprs: UfsMcqOprSet,
+}
+
+impl McqRegisterLayout {
+    pub(crate) fn new(queue_config: McqQueueConfigLayout, oprs: UfsMcqOprSet) -> Self {
+        Self { queue_config, oprs }
+    }
+
+    pub(crate) fn oprs(&self) -> UfsMcqOprSet {
+        self.oprs
+    }
+}
+
+pub(crate) struct UfsReg {
+    resources: Arc<HostResources>,
+}
+
+impl UfsReg {
+    pub(crate) fn new(resources: Arc<HostResources>) -> Result<Arc<Self>> {
+        Ok(Arc::new(Self { resources }, GFP_KERNEL)?)
+    }
+
+    pub(crate) fn hci_access(&self) -> Result<crate::resource::HciMmioAccess<'_>> {
+        self.resources.hci_access()
+    }
+
+    #[inline(always)]
+    fn dma_addr_lo(dma_addr: u64) -> u32 {
+        dma_addr as u32
+    }
+
+    #[inline(always)]
+    fn dma_addr_hi(dma_addr: u64) -> u32 {
+        (dma_addr >> 32) as u32
+    }
+
+    // Basic Controller/Version/Interrupt
+    #[inline]
+    pub(crate) fn read_cap_lo(&self) -> u32 {
+        let access = self.resources.hci_access().unwrap();
+        access.read(CONTROLLER_CAPABILITIES).into_raw()
+    }
+
+    #[inline]
+    pub(crate) fn read_cap_hi(&self) -> u32 {
+        let access = self.resources.hci_access().unwrap();
+        access.read(CONTROLLER_CAPABILITIES_H).value().get()
+    }
+
+    #[inline]
+    pub(crate) fn read_version(&self) -> u32 {
+        let access = self.resources.hci_access().unwrap();
+        access.read(UFS_VERSION).value().get()
+    }
+
+    #[inline]
+    pub(crate) fn read_is(&self) -> u32 {
+        let access = self.resources.hci_access().unwrap();
+        access.read(INTERRUPT_STATUS).value().get()
+    }
+
+    #[inline]
+    pub(crate) fn write_is(&self, value: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(INTERRUPT_STATUS::zeroed().with_value(value))
+    }
+
+    #[inline]
+    pub(crate) fn read_ie(&self) -> u32 {
+        let access = self.resources.hci_access().unwrap();
+        access.read(INTERRUPT_ENABLE).value().get()
+    }
+
+    #[inline]
+    pub(crate) fn write_ie(&self, value: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(INTERRUPT_ENABLE::zeroed().with_value(value))
+    }
+
+    #[inline]
+    pub(crate) fn read_hcs(&self) -> u32 {
+        let access = self.resources.hci_access().unwrap();
+        access.read(CONTROLLER_STATUS).into_raw()
+    }
+
+    #[inline]
+    pub(crate) fn read_hce(&self) -> u32 {
+        let access = self.resources.hci_access().unwrap();
+        access.read(CONTROLLER_ENABLE_REG).into_raw()
+    }
+
+    #[inline]
+    pub(crate) fn write_hce(&self, value: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(CONTROLLER_ENABLE_REG::from_raw(value))
+    }
+
+    #[inline]
+    pub(crate) fn read_uic_error_phy(&self) -> u32 {
+        let access = self.resources.hci_access().unwrap();
+        access.read(UIC_ERROR_CODE_PHY_ADAPTER_LAYER).value().get()
+    }
+
+    #[inline]
+    pub(crate) fn confirm_uic_error(&self) {
+        self.write_is(UIC_ERROR);
+    }
+
+    pub(crate) fn read_uic_errors(&self) -> UicErrorStatus {
+        let access = self.resources.hci_access().unwrap();
+        UicErrorStatus {
+            phy: access.read(UIC_ERROR_CODE_PHY_ADAPTER_LAYER).value().get(),
+            data_link: access.read(UIC_ERROR_CODE_DATA_LINK_LAYER).value().get(),
+            network: access.read(UIC_ERROR_CODE_NETWORK_LAYER).value().get(),
+            transport: access.read(UIC_ERROR_CODE_TRANSPORT_LAYER).value().get(),
+            dme: access.read(UIC_ERROR_CODE_DME).value().get(),
+        }
+    }
+
+    #[inline]
+    pub(crate) fn write_uic_error_phy(&self, value: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(UIC_ERROR_CODE_PHY_ADAPTER_LAYER::zeroed().with_value(value))
+    }
+
+    // UTRL(Transfer)
+    #[inline]
+    pub(crate) fn write_utrlba(&self, low: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(UTP_TRANSFER_REQ_LIST_BASE_L::zeroed().with_value(low))
+    }
+
+    #[inline]
+    pub(crate) fn write_utrlbau(&self, high: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(UTP_TRANSFER_REQ_LIST_BASE_H::zeroed().with_value(high))
+    }
+
+    #[inline]
+    pub(crate) fn read_utrl_doorbell(&self) -> u32 {
+        let access = self.resources.hci_access().unwrap();
+        access.read(UTP_TRANSFER_REQ_DOOR_BELL).value().get()
+    }
+
+    #[inline]
+    pub(crate) fn ring_utrl_doorbell(&self, tag: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(UTP_TRANSFER_REQ_DOOR_BELL::zeroed().with_value(1u32 << tag))
+    }
+
+    #[inline]
+    pub(crate) fn write_utrl_runstop(&self, value: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(UTP_TRANSFER_REQ_LIST_RUN_STOP::zeroed().with_value(value))
+    }
+
+    #[inline]
+    pub(crate) fn clear_utrl_slots(&self, mask: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(UTP_TRANSFER_REQ_LIST_CLEAR::zeroed().with_value(mask))
+    }
+
+    // UTMRL(Task Management)
+    #[inline]
+    pub(crate) fn write_utmrlba(&self, low: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(UTP_TASK_REQ_LIST_BASE_L::zeroed().with_value(low))
+    }
+
+    #[inline]
+    pub(crate) fn write_utmrlbau(&self, high: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(UTP_TASK_REQ_LIST_BASE_H::zeroed().with_value(high))
+    }
+
+    #[inline]
+    pub(crate) fn read_utmrl_doorbell(&self) -> u32 {
+        let access = self.resources.hci_access().unwrap();
+        access.read(UTP_TASK_REQ_DOOR_BELL).value().get()
+    }
+
+    #[inline]
+    pub(crate) fn ring_utmrl_doorbell(&self, mask: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(UTP_TASK_REQ_DOOR_BELL::zeroed().with_value(mask))
+    }
+
+    #[inline]
+    pub(crate) fn write_utmrl_runstop(&self, value: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(UTP_TASK_REQ_LIST_RUN_STOP::zeroed().with_value(value))
+    }
+
+    #[inline]
+    pub(crate) fn clear_utmrl_slots(&self, mask: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(UTP_TASK_REQ_LIST_CLEAR::zeroed().with_value(mask))
+    }
+
+    // UIC command
+    #[inline]
+    pub(crate) fn read_uic_cmd(&self) -> u32 {
+        let access = self.resources.hci_access().unwrap();
+        access.read(UIC_COMMAND).value().get()
+    }
+
+    #[inline]
+    pub(crate) fn write_uic_cmd(&self, value: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(UIC_COMMAND::zeroed().with_value(value))
+    }
+
+    #[inline]
+    pub(crate) fn read_uic_arg1(&self) -> u32 {
+        let access = self.resources.hci_access().unwrap();
+        access.read(UIC_ARG1).value().get()
+    }
+
+    #[inline]
+    pub(crate) fn write_uic_arg1(&self, value: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(UIC_ARG1::zeroed().with_value(value))
+    }
+
+    #[inline]
+    pub(crate) fn read_uic_arg2(&self) -> u32 {
+        let access = self.resources.hci_access().unwrap();
+        access.read(UIC_ARG2).into_raw()
+    }
+
+    #[inline]
+    pub(crate) fn write_uic_arg2(&self, value: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(UIC_ARG2::from_raw(value))
+    }
+
+    #[inline]
+    pub(crate) fn read_uic_arg3(&self) -> u32 {
+        let access = self.resources.hci_access().unwrap();
+        access.read(UIC_ARG3).value().get()
+    }
+
+    #[inline]
+    pub(crate) fn write_uic_arg3(&self, value: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(UIC_ARG3::zeroed().with_value(value))
+    }
+
+    // MCQ global configuration
+    #[inline]
+    pub(crate) fn read_mcq_cap(&self) -> u32 {
+        let access = self.resources.hci_access().unwrap();
+        access.read(MCQCAP).into_raw()
+    }
+
+    #[inline]
+    pub(crate) fn mcq_max_queues(&self) -> usize {
+        let access = self.resources.hci_access().unwrap();
+        access.read(MCQCAP).max_queue_supported().get() as usize + 1
+    }
+
+    #[inline]
+    pub(crate) fn mcq_queue_cfg_base(&self) -> usize {
+        let access = self.resources.hci_access().unwrap();
+        access.read(MCQCAP).queue_config_pointer().get() as usize * MCQ_QCFGPTR_UNIT
+    }
+
+    pub(crate) fn mcq_register_layout(&self) -> Result<McqRegisterLayout> {
+        self.resources.variant().mcq_register_layout(self)
+    }
+
+    pub(crate) fn standard_mcq_register_layout(&self) -> Result<McqRegisterLayout> {
+        let queue_config = McqQueueConfigLayout::new(
+            McqRegisterRegion::Hci,
+            self.mcq_queue_cfg_base(),
+            MCQ_QCFG_STRIDE,
+        );
+        let sqd = self
+            .read_mcq_queue_cfg_at::<MCQ_SQDAO>(&queue_config, 0)?
+            .value()
+            .get() as usize;
+        let sqis = self
+            .read_mcq_queue_cfg_at::<MCQ_SQISAO>(&queue_config, 0)?
+            .value()
+            .get() as usize;
+        let cqd = self
+            .read_mcq_queue_cfg_at::<MCQ_CQDAO>(&queue_config, 0)?
+            .value()
+            .get() as usize;
+        let cqis = self
+            .read_mcq_queue_cfg_at::<MCQ_CQISAO>(&queue_config, 0)?
+            .value()
+            .get() as usize;
+
+        Ok(McqRegisterLayout::new(
+            queue_config,
+            UfsMcqOprSet::new(
+                UfsMcqOprInfo::new(McqRegisterRegion::Hci, sqd, sqd, MCQ_DEFAULT_OPR_STRIDE),
+                UfsMcqOprInfo::new(McqRegisterRegion::Hci, sqis, sqis, MCQ_DEFAULT_OPR_STRIDE),
+                UfsMcqOprInfo::new(McqRegisterRegion::Hci, cqd, cqd, MCQ_DEFAULT_OPR_STRIDE),
+                UfsMcqOprInfo::new(McqRegisterRegion::Hci, cqis, cqis, MCQ_DEFAULT_OPR_STRIDE),
+            ),
+        ))
+    }
+
+    #[inline]
+    pub(crate) fn read_ufs_mem_cfg(&self) -> u32 {
+        let access = self.resources.hci_access().unwrap();
+        access.read(UFS_MEM_CFG).into_raw()
+    }
+
+    #[inline]
+    pub(crate) fn write_ufs_mem_cfg(&self, value: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(UFS_MEM_CFG::from_raw(value))
+    }
+
+    #[inline]
+    pub(crate) fn enable_mcq_mode(&self) {
+        let access = self.resources.hci_access().unwrap();
+        access.update(UFS_MEM_CFG, |reg| reg.with_mcq_mode_select(true));
+    }
+
+    #[inline]
+    pub(crate) fn disable_mcq_mode(&self) {
+        let access = self.resources.hci_access().unwrap();
+        access.update(UFS_MEM_CFG, |reg| reg.with_mcq_mode_select(false));
+    }
+
+    #[inline]
+    pub(crate) fn enable_mcq_esi(&self) {
+        let access = self.resources.hci_access().unwrap();
+        access.update(UFS_MEM_CFG, |reg| reg.with_esi_enable(true));
+    }
+
+    #[inline]
+    pub(crate) fn config_mcq_esi(&self, addr: u64) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(UFS_ESILBA::zeroed().with_value(Self::dma_addr_lo(addr)));
+        access.write_reg(UFS_ESIUBA::zeroed().with_value(Self::dma_addr_hi(addr)));
+    }
+
+    #[inline]
+    pub(crate) fn read_mcq_cfg(&self) -> u32 {
+        let access = self.resources.hci_access().unwrap();
+        access.read(UFS_MCQ_CFG).into_raw()
+    }
+
+    #[inline]
+    pub(crate) fn write_mcq_cfg(&self, value: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(UFS_MCQ_CFG::from_raw(value))
+    }
+
+    pub(crate) fn config_mcq_max_active_cmds(&self, max_active_cmds: u32) -> Result<()> {
+        if max_active_cmds == 0 {
+            return Err(EINVAL);
+        }
+
+        let access = self.resources.hci_access()?;
+        let value = access
+            .read(UFS_MCQ_CFG)
+            .try_with_max_active_cmds(max_active_cmds - 1)?;
+        access.write_reg(value);
+        Ok(())
+    }
+
+    // MCQ queue configuration registers
+    #[inline]
+    fn read_mcq_region(&self, region: McqRegisterRegion, offset: usize) -> Result<u32> {
+        match region {
+            McqRegisterRegion::Hci => self.resources.hci_access()?.try_read32(offset),
+            McqRegisterRegion::Mcq => self.resources.mcq_access()?.try_read32(offset),
+        }
+    }
+
+    #[inline]
+    fn write_mcq_region(&self, region: McqRegisterRegion, offset: usize, value: u32) -> Result<()> {
+        match region {
+            McqRegisterRegion::Hci => self.resources.hci_access()?.try_write32(value, offset),
+            McqRegisterRegion::Mcq => self.resources.mcq_access()?.try_write32(value, offset),
+        }
+    }
+
+    #[inline]
+    fn mcq_queue_cfg_offset<T>(layout: &McqQueueConfigLayout, queue: usize) -> usize
+    where
+        T: Register<Storage = u32> + From<u32>,
+        u32: From<T>,
+    {
+        layout.offset + layout.stride * queue + T::OFFSET
+    }
+
+    #[inline]
+    fn read_mcq_queue_cfg_at<T>(&self, layout: &McqQueueConfigLayout, queue: usize) -> Result<T>
+    where
+        T: Register<Storage = u32> + From<u32>,
+        u32: From<T>,
+    {
+        Ok(T::from(self.read_mcq_region(
+            layout.region,
+            Self::mcq_queue_cfg_offset::<T>(layout, queue),
+        )?))
+    }
+
+    #[inline]
+    fn write_mcq_queue_cfg<T>(
+        &self,
+        layout: &McqRegisterLayout,
+        queue: usize,
+        value: T,
+    ) -> Result<()>
+    where
+        T: Register<Storage = u32> + From<u32>,
+        u32: From<T>,
+    {
+        self.write_mcq_region(
+            layout.queue_config.region,
+            Self::mcq_queue_cfg_offset::<T>(&layout.queue_config, queue),
+            value.into(),
+        )
+    }
+
+    fn mcq_queue_attr(max_entries: usize) -> Result<u32> {
+        let dwords = u32::try_from(max_entries)
+            .map_err(|_| EINVAL)?
+            .checked_mul(MCQ_ENTRY_SIZE_IN_DWORD)
+            .ok_or(EOVERFLOW)?;
+
+        dwords.checked_sub(1).ok_or(EINVAL)
+    }
+
+    #[inline]
+    pub(crate) fn write_mcq_sqlba(
+        &self,
+        layout: &McqRegisterLayout,
+        queue: usize,
+        dma_addr: u64,
+    ) -> Result<()> {
+        self.write_mcq_queue_cfg(
+            layout,
+            queue,
+            MCQ_SQLBA::zeroed().with_value(Self::dma_addr_lo(dma_addr)),
+        )
+    }
+
+    #[inline]
+    pub(crate) fn write_mcq_squba(
+        &self,
+        layout: &McqRegisterLayout,
+        queue: usize,
+        dma_addr: u64,
+    ) -> Result<()> {
+        self.write_mcq_queue_cfg(
+            layout,
+            queue,
+            MCQ_SQUBA::zeroed().with_value(Self::dma_addr_hi(dma_addr)),
+        )
+    }
+
+    #[inline]
+    pub(crate) fn set_mcq_sq_base_addr(
+        &self,
+        layout: &McqRegisterLayout,
+        queue: usize,
+        dma_addr: u64,
+    ) -> Result<()> {
+        self.write_mcq_sqlba(layout, queue, dma_addr)?;
+        self.write_mcq_squba(layout, queue, dma_addr)
+    }
+
+    #[inline]
+    pub(crate) fn write_mcq_sqdao(
+        &self,
+        layout: &McqRegisterLayout,
+        queue: usize,
+        offset: usize,
+    ) -> Result<()> {
+        self.write_mcq_queue_cfg(layout, queue, MCQ_SQDAO::zeroed().with_value(offset as u32))
+    }
+
+    #[inline]
+    pub(crate) fn write_mcq_sqisao(
+        &self,
+        layout: &McqRegisterLayout,
+        queue: usize,
+        offset: usize,
+    ) -> Result<()> {
+        self.write_mcq_queue_cfg(
+            layout,
+            queue,
+            MCQ_SQISAO::zeroed().with_value(offset as u32),
+        )
+    }
+
+    #[inline]
+    pub(crate) fn write_mcq_cqlba(
+        &self,
+        layout: &McqRegisterLayout,
+        queue: usize,
+        dma_addr: u64,
+    ) -> Result<()> {
+        self.write_mcq_queue_cfg(
+            layout,
+            queue,
+            MCQ_CQLBA::zeroed().with_value(Self::dma_addr_lo(dma_addr)),
+        )
+    }
+
+    #[inline]
+    pub(crate) fn write_mcq_cquba(
+        &self,
+        layout: &McqRegisterLayout,
+        queue: usize,
+        dma_addr: u64,
+    ) -> Result<()> {
+        self.write_mcq_queue_cfg(
+            layout,
+            queue,
+            MCQ_CQUBA::zeroed().with_value(Self::dma_addr_hi(dma_addr)),
+        )
+    }
+
+    #[inline]
+    pub(crate) fn set_mcq_cq_base_addr(
+        &self,
+        layout: &McqRegisterLayout,
+        queue: usize,
+        dma_addr: u64,
+    ) -> Result<()> {
+        self.write_mcq_cqlba(layout, queue, dma_addr)?;
+        self.write_mcq_cquba(layout, queue, dma_addr)
+    }
+
+    #[inline]
+    pub(crate) fn write_mcq_cqdao(
+        &self,
+        layout: &McqRegisterLayout,
+        queue: usize,
+        offset: usize,
+    ) -> Result<()> {
+        self.write_mcq_queue_cfg(layout, queue, MCQ_CQDAO::zeroed().with_value(offset as u32))
+    }
+
+    #[inline]
+    pub(crate) fn write_mcq_cqisao(
+        &self,
+        layout: &McqRegisterLayout,
+        queue: usize,
+        offset: usize,
+    ) -> Result<()> {
+        self.write_mcq_queue_cfg(
+            layout,
+            queue,
+            MCQ_CQISAO::zeroed().with_value(offset as u32),
+        )
+    }
+
+    pub(crate) fn enable_mcq_sq(
+        &self,
+        layout: &McqRegisterLayout,
+        queue: usize,
+        max_entries: usize,
+        cq_id: usize,
+    ) -> Result<()> {
+        let attr = MCQ_SQATTR::zeroed()
+            .with_enable(true)
+            .try_with_cq_id(u32::try_from(cq_id).map_err(|_| EINVAL)?)?
+            .try_with_size(Self::mcq_queue_attr(max_entries)?)?;
+        self.write_mcq_queue_cfg(layout, queue, attr)
+    }
+
+    pub(crate) fn enable_mcq_cq(
+        &self,
+        layout: &McqRegisterLayout,
+        queue: usize,
+        max_entries: usize,
+    ) -> Result<()> {
+        let attr = MCQ_CQATTR::zeroed()
+            .with_enable(true)
+            .try_with_size(Self::mcq_queue_attr(max_entries)?)?;
+        self.write_mcq_queue_cfg(layout, queue, attr)
+    }
+
+    // MCQ operation and runtime registers
+    #[inline]
+    pub(crate) fn mcq_opr_region_offset(
+        &self,
+        oprs: &UfsMcqOprSet,
+        region: UfsMcqOprRegion,
+        queue: usize,
+    ) -> usize {
+        oprs.get(region).config_offset(queue)
+    }
+
+    #[inline]
+    fn read_mcq_opr<T>(
+        &self,
+        oprs: &UfsMcqOprSet,
+        region: UfsMcqOprRegion,
+        queue: usize,
+    ) -> Result<T>
+    where
+        T: Register<Storage = u32> + From<u32>,
+        u32: From<T>,
+    {
+        let info = oprs.get(region);
+        Ok(T::from(self.read_mcq_region(
+            info.region,
+            info.register_offset(queue) + T::OFFSET,
+        )?))
+    }
+
+    #[inline]
+    fn write_mcq_opr<T>(
+        &self,
+        oprs: &UfsMcqOprSet,
+        region: UfsMcqOprRegion,
+        queue: usize,
+        value: T,
+    ) -> Result<()>
+    where
+        T: Register<Storage = u32> + From<u32>,
+        u32: From<T>,
+    {
+        let info = oprs.get(region);
+        self.write_mcq_region(
+            info.region,
+            info.register_offset(queue) + T::OFFSET,
+            value.into(),
+        )
+    }
+
+    #[inline]
+    pub(crate) fn read_mcq_sq_head(&self, oprs: &UfsMcqOprSet, queue: usize) -> Result<u32> {
+        Ok(self
+            .read_mcq_opr::<MCQ_SQHP>(oprs, UfsMcqOprRegion::Sqd, queue)?
+            .value()
+            .get())
+    }
+
+    #[inline]
+    pub(crate) fn read_mcq_sq_tail(&self, oprs: &UfsMcqOprSet, queue: usize) -> Result<u32> {
+        Ok(self
+            .read_mcq_opr::<MCQ_SQTP>(oprs, UfsMcqOprRegion::Sqd, queue)?
+            .value()
+            .get())
+    }
+
+    #[inline]
+    pub(crate) fn write_mcq_sq_tail(
+        &self,
+        oprs: &UfsMcqOprSet,
+        queue: usize,
+        tail: u32,
+    ) -> Result<()> {
+        self.write_mcq_opr(
+            oprs,
+            UfsMcqOprRegion::Sqd,
+            queue,
+            MCQ_SQTP::zeroed().with_value(tail),
+        )
+    }
+
+    #[inline]
+    pub(crate) fn write_mcq_sq_runtime_control(
+        &self,
+        oprs: &UfsMcqOprSet,
+        queue: usize,
+        value: u32,
+    ) -> Result<()> {
+        let value = MCQ_SQRTC::zeroed().try_with_operation(value)?;
+        self.write_mcq_opr(oprs, UfsMcqOprRegion::Sqd, queue, value)
+    }
+
+    #[inline]
+    pub(crate) fn read_mcq_sq_runtime_status(
+        &self,
+        oprs: &UfsMcqOprSet,
+        queue: usize,
+    ) -> Result<u32> {
+        Ok(self
+            .read_mcq_opr::<MCQ_SQRTS>(oprs, UfsMcqOprRegion::Sqd, queue)?
+            .into_raw())
+    }
+
+    fn wait_mcq_sq_stopped(&self, oprs: &UfsMcqOprSet, queue: usize, stopped: bool) -> Result<()> {
+        read_poll_timeout(
+            || self.read_mcq_opr::<MCQ_SQRTS>(oprs, UfsMcqOprRegion::Sqd, queue),
+            |v: &MCQ_SQRTS| v.stopped() == stopped,
+            Delta::from_micros(MCQ_POLL_INTERVAL_US),
+            Delta::from_micros(MCQ_POLL_TIMEOUT_US),
+        )
+        .map(|_| ())
+    }
+
+    pub(crate) fn stop_mcq_sq(&self, oprs: &UfsMcqOprSet, queue: usize) -> Result<()> {
+        self.write_mcq_sq_runtime_control(oprs, queue, MCQ_SQ_STOP)?;
+        self.wait_mcq_sq_stopped(oprs, queue, true)
+    }
+
+    pub(crate) fn start_mcq_sq(&self, oprs: &UfsMcqOprSet, queue: usize) -> Result<()> {
+        self.write_mcq_sq_runtime_control(oprs, queue, MCQ_SQ_START)?;
+        self.wait_mcq_sq_stopped(oprs, queue, false)
+    }
+
+    #[inline]
+    pub(crate) fn write_mcq_sq_cleanup_target(
+        &self,
+        oprs: &UfsMcqOprSet,
+        queue: usize,
+        lun: u8,
+        tag: u8,
+    ) -> Result<()> {
+        let target = MCQ_SQCTI::zeroed().with_lun(lun).with_task_tag(tag);
+        self.write_mcq_opr(oprs, UfsMcqOprRegion::Sqd, queue, target)
+    }
+
+    pub(crate) fn initiate_mcq_sq_cleanup(&self, oprs: &UfsMcqOprSet, queue: usize) -> Result<()> {
+        let rtc = self
+            .read_mcq_opr::<MCQ_SQRTC>(oprs, UfsMcqOprRegion::Sqd, queue)?
+            .with_initiate_cleanup(true);
+        self.write_mcq_opr(oprs, UfsMcqOprRegion::Sqd, queue, rtc)?;
+        read_poll_timeout(
+            || self.read_mcq_opr::<MCQ_SQRTS>(oprs, UfsMcqOprRegion::Sqd, queue),
+            |v: &MCQ_SQRTS| v.cleanup_in_progress(),
+            Delta::from_micros(MCQ_POLL_INTERVAL_US),
+            Delta::from_micros(MCQ_POLL_TIMEOUT_US),
+        )
+        .map(|_| ())
+    }
+
+    #[inline]
+    pub(crate) fn mcq_sq_cleanup_error_code(
+        &self,
+        oprs: &UfsMcqOprSet,
+        queue: usize,
+    ) -> Result<u32> {
+        Ok(self
+            .read_mcq_opr::<MCQ_SQRTS>(oprs, UfsMcqOprRegion::Sqd, queue)?
+            .cleanup_error_code()
+            .get())
+    }
+
+    #[inline]
+    pub(crate) fn read_mcq_cq_head(&self, oprs: &UfsMcqOprSet, queue: usize) -> Result<u32> {
+        Ok(self
+            .read_mcq_opr::<MCQ_CQHP>(oprs, UfsMcqOprRegion::Cqd, queue)?
+            .value()
+            .get())
+    }
+
+    #[inline]
+    pub(crate) fn write_mcq_cq_head(
+        &self,
+        oprs: &UfsMcqOprSet,
+        queue: usize,
+        head: u32,
+    ) -> Result<()> {
+        self.write_mcq_opr(
+            oprs,
+            UfsMcqOprRegion::Cqd,
+            queue,
+            MCQ_CQHP::zeroed().with_value(head),
+        )
+    }
+
+    #[inline]
+    pub(crate) fn read_mcq_cq_tail(&self, oprs: &UfsMcqOprSet, queue: usize) -> Result<u32> {
+        Ok(self
+            .read_mcq_opr::<MCQ_CQTP>(oprs, UfsMcqOprRegion::Cqd, queue)?
+            .value()
+            .get())
+    }
+
+    #[inline]
+    pub(crate) fn read_mcq_cqis(&self, oprs: &UfsMcqOprSet, queue: usize) -> Result<u32> {
+        Ok(self
+            .read_mcq_opr::<MCQ_CQIS>(oprs, UfsMcqOprRegion::Cqis, queue)?
+            .into_raw())
+    }
+
+    #[inline]
+    pub(crate) fn write_mcq_cqis(
+        &self,
+        oprs: &UfsMcqOprSet,
+        queue: usize,
+        value: u32,
+    ) -> Result<()> {
+        self.write_mcq_opr(
+            oprs,
+            UfsMcqOprRegion::Cqis,
+            queue,
+            MCQ_CQIS::from_raw(value),
+        )
+    }
+
+    #[inline]
+    pub(crate) fn enable_mcq_cq_tail_push_intr(
+        &self,
+        oprs: &UfsMcqOprSet,
+        queue: usize,
+    ) -> Result<()> {
+        self.write_mcq_opr(
+            oprs,
+            UfsMcqOprRegion::Cqis,
+            queue,
+            MCQ_CQIE::zeroed().with_tail_entry_push_enable(true),
+        )
+    }
+
+    // Helpers
+    #[inline]
+    pub(crate) fn nutrs(&self) -> usize {
+        let access = self.resources.hci_access().unwrap();
+        access
+            .read(CONTROLLER_CAPABILITIES)
+            .transfer_request_slots_sdb()
+            .get() as usize
+            + 1
+    }
+
+    #[inline]
+    pub(crate) fn mcq_hardware_supported(&self) -> bool {
+        let access = self.resources.hci_access().unwrap();
+        access.read(CONTROLLER_CAPABILITIES).mcq_supported()
+    }
+
+    #[inline]
+    pub(crate) fn mcq_variant_enabled(&self) -> bool {
+        self.resources.variant().mcq_enabled()
+    }
+
+    #[inline]
+    pub(crate) fn constrain_mcq_active_commands(&self, reported: usize) -> usize {
+        self.resources
+            .variant()
+            .constrain_mcq_active_commands(reported)
+    }
+
+    #[inline]
+    pub(crate) fn nutrs_mcq(&self) -> usize {
+        let access = self.resources.hci_access().unwrap();
+        access
+            .read(CONTROLLER_CAPABILITIES_MCQ)
+            .transfer_request_slots()
+            .get() as usize
+            + 1
+    }
+
+    #[inline]
+    pub(crate) fn nutmrs(&self) -> usize {
+        let access = self.resources.hci_access().unwrap();
+        access
+            .read(CONTROLLER_CAPABILITIES)
+            .task_management_request_slots()
+            .get() as usize
+            + 1
+    }
+
+    #[inline]
+    pub(crate) fn autoh8(&self) -> bool {
+        let access = self.resources.hci_access().unwrap();
+        access
+            .read(CONTROLLER_CAPABILITIES)
+            .auto_hibern8_supported()
+    }
+
+    #[inline]
+    pub(crate) fn ctrl_enable(&self) {
+        let access = self.resources.hci_access().unwrap();
+        access.update(CONTROLLER_ENABLE_REG, |reg| {
+            reg.with_controller_enable(true)
+        });
+    }
+
+    #[inline]
+    pub(crate) fn ctrl_disable(&self) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(CONTROLLER_ENABLE_REG::zeroed());
+    }
+
+    #[inline]
+    pub(crate) fn ctrl_enabled(&self) -> bool {
+        let access = self.resources.hci_access().unwrap();
+        access.read(CONTROLLER_ENABLE_REG).controller_enable()
+    }
+
+    #[inline]
+    pub(crate) fn clear_all_interrupts(&self) {
+        let isb = self.read_is();
+        if isb != 0 {
+            self.write_is(isb)
+        }
+    }
+
+    #[inline]
+    pub(crate) fn disable_interrupts(&self) {
+        self.write_ie(0);
+    }
+
+    #[inline]
+    pub(crate) fn set_utrdl_base(&self, dma_addr: u64) {
+        self.write_utrlba(dma_addr as u32);
+        self.write_utrlbau((dma_addr >> 32) as u32);
+    }
+
+    #[inline]
+    pub(crate) fn set_utmrdl_base(&self, dma_addr: u64) {
+        self.write_utmrlba(dma_addr as u32);
+        self.write_utmrlbau((dma_addr >> 32) as u32);
+    }
+
+    #[inline]
+    pub(crate) fn wait_for_ctrl_enable(&self, interval_us: i64, timeout_ms: i64) -> Result<()> {
+        match read_poll_timeout(
+            || {
+                let access = self.resources.hci_access()?;
+                Ok(access.read(CONTROLLER_ENABLE_REG))
+            },
+            |v: &CONTROLLER_ENABLE_REG| v.controller_enable(),
+            Delta::from_micros(interval_us),
+            Delta::from_millis(timeout_ms),
+        ) {
+            Ok(_) => Ok(()),
+            Err(e) => Err(e),
+        }
+    }
+
+    #[inline]
+    pub(crate) fn wait_for_ctrl_disable(&self, interval_us: i64, timeout_ms: i64) -> Result<()> {
+        match read_poll_timeout(
+            || {
+                let access = self.resources.hci_access()?;
+                Ok(access.read(CONTROLLER_ENABLE_REG))
+            },
+            |v: &CONTROLLER_ENABLE_REG| !v.controller_enable(),
+            Delta::from_micros(interval_us),
+            Delta::from_millis(timeout_ms),
+        ) {
+            Ok(_) => Ok(()),
+            Err(e) => Err(e),
+        }
+    }
+
+    pub(crate) fn enable_uic_interrupts(&self) {
+        self.write_ie(self.read_ie() | UIC_INTR_MASK);
+    }
+
+    pub(crate) fn read_uic_interrupts(&self) -> u32 {
+        self.read_is() & self.read_ie() & UIC_INTR_MASK
+    }
+
+    pub(crate) fn confirm_uic_interrupts(&self, value: u32) {
+        self.write_is(value & UIC_INTR_MASK);
+    }
+
+    pub(crate) fn get_uic_cmd_result(&self) -> u32 {
+        let access = self.resources.hci_access().unwrap();
+        access.read(UIC_ARG2).command_result().get()
+    }
+
+    pub(crate) fn get_dme_attr_val(&self) -> u32 {
+        self.read_uic_arg3()
+    }
+
+    pub(crate) fn get_power_mode_change_status(&self) -> u32 {
+        let access = self.resources.hci_access().unwrap();
+        access
+            .read(CONTROLLER_STATUS)
+            .power_mode_change_request_status()
+            .get()
+    }
+
+    pub(crate) fn wait_for_uic_cmd_ready(&self, interval_us: i64, timeout_ms: i64) -> Result<()> {
+        match read_poll_timeout(
+            || {
+                let access = self.resources.hci_access()?;
+                Ok(access.read(CONTROLLER_STATUS))
+            },
+            |v: &CONTROLLER_STATUS| v.uic_command_ready(),
+            Delta::from_micros(interval_us),
+            Delta::from_millis(timeout_ms),
+        ) {
+            Ok(_) => Ok(()),
+            Err(e) => Err(e),
+        }
+    }
+
+    pub(crate) fn read_transfer_interrupts(&self) -> u32 {
+        self.read_is()
+            & self.read_ie()
+            & (UTP_TRANSFER_REQ_COMPL | MCQ_CQ_EVENT_STATUS | ERROR_MASK)
+    }
+
+    pub(crate) fn confirm_transfer_interrupts(&self, value: u32) {
+        self.write_is(value & (UTP_TRANSFER_REQ_COMPL | MCQ_CQ_EVENT_STATUS | ERROR_MASK));
+    }
+
+    pub(crate) fn confirm_mcq_cq_events(&self, value: u32) {
+        self.write_is(value & MCQ_CQ_EVENT_STATUS);
+    }
+
+    pub(crate) fn confirm_deferred_transfer_interrupts(&self, value: u32) {
+        self.write_is(value & (UTP_TRANSFER_REQ_COMPL | ERROR_MASK));
+    }
+
+    pub(crate) fn enable_transfer_interrupts(&self) {
+        self.write_ie(self.read_ie() | UTP_REQ_COMPL_MASK | ERROR_MASK);
+    }
+
+    pub(crate) fn disable_transfer_req_int_aggr(&self) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(UTP_TRANSFER_REQ_INT_AGG_CONTROL::zeroed().with_value(0_u32));
+    }
+
+    pub(crate) fn enable_mcq_interrupts(&self) {
+        self.write_ie(self.read_ie() | MCQ_CQ_EVENT_STATUS);
+    }
+
+    pub(crate) fn wait_for_request_ready(&self, interval_us: i64, timeout_ms: i64) -> Result<()> {
+        match read_poll_timeout(
+            || {
+                let access = self.resources.hci_access()?;
+                Ok(access.read(CONTROLLER_STATUS))
+            },
+            |v: &CONTROLLER_STATUS| {
+                v.transfer_request_list_ready()
+                    && v.task_request_list_ready()
+                    && v.uic_command_ready()
+            },
+            Delta::from_micros(interval_us),
+            Delta::from_millis(timeout_ms),
+        ) {
+            Ok(_) => Ok(()),
+            Err(e) => Err(e),
+        }
+    }
+
+    pub(crate) fn enable_run_stop(&self) {
+        self.write_utmrl_runstop(1);
+        self.write_utrl_runstop(1);
+    }
+
+    pub(crate) fn disable_run_stop(&self) {
+        self.write_utrl_runstop(0);
+        self.write_utmrl_runstop(0);
+    }
+
+    pub(crate) fn utrlcnr(&self) -> u32 {
+        let access = self.resources.hci_access().unwrap();
+        access
+            .read(UTP_TRANSFER_REQ_LIST_COMPLETION_NOTIFICATION)
+            .value()
+            .get()
+    }
+
+    pub(crate) fn write_utrlcnr(&self, value: u32) {
+        let access = self.resources.hci_access().unwrap();
+        access.write_reg(UTP_TRANSFER_REQ_LIST_COMPLETION_NOTIFICATION::zeroed().with_value(value))
+    }
+}
+
+#[inline]
+pub(crate) fn is_uic_command_completion(interrupt_status: u32) -> bool {
+    (interrupt_status & UIC_COMMAND_COMPL) != 0
+}
+
+#[inline]
+pub(crate) fn is_uic_power_mode(interrupt_status: u32) -> bool {
+    (interrupt_status & UIC_POWER_MODE) != 0
+}
+
+#[inline]
+pub(crate) fn is_error_interrupt(interrupt_status: u32) -> bool {
+    (interrupt_status & ERROR_MASK) != 0
+}
+
+#[inline]
+pub(crate) fn has_deferred_transfer_interrupts(interrupt_status: u32) -> bool {
+    (interrupt_status & (UTP_TRANSFER_REQ_COMPL | ERROR_MASK)) != 0
+}
+
+#[inline]
+pub(crate) fn is_uic_error_interrupt(interrupt_status: u32) -> bool {
+    (interrupt_status & UIC_ERROR) != 0
+}
+
+#[inline]
+pub(crate) fn is_transfer_recovery_interrupt(interrupt_status: u32) -> bool {
+    (interrupt_status & (ERROR_MASK & !UIC_ERROR)) != 0
+}
diff --git a/drivers/rufs/resource.rs b/drivers/rufs/resource.rs
new file mode 100644
index 0000000000000..c0fd4da8c85ee
--- /dev/null
+++ b/drivers/rufs/resource.rs
@@ -0,0 +1,136 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! Resources owned by a UFS host-controller frontend.
+
+use kernel::alloc::KBox;
+use kernel::device::{self, Bound};
+use kernel::io::mem::{DevresIoMem, IoMem};
+use kernel::io::{IoBase, Mmio, MmioBackend, Region};
+#[cfg(CONFIG_RUFS_QCOM)]
+use kernel::platform;
+use kernel::prelude::*;
+use kernel::sync::{aref::ARef, Arc};
+#[cfg(CONFIG_RUFS_PCI)]
+use kernel::{c_str, pci};
+
+use crate::variant::UfsVariantOps;
+
+pub(crate) const HCI_MMIO_SIZE: usize = 0x1000;
+
+pub(crate) enum HciMmio {
+    #[cfg(CONFIG_RUFS_PCI)]
+    Pci(pci::DevresBar<HCI_MMIO_SIZE>),
+    #[cfg(CONFIG_RUFS_QCOM)]
+    Platform(DevresIoMem<HCI_MMIO_SIZE>),
+}
+
+/// An optional, separately mapped MCQ register region.
+///
+/// Some platform controllers expose MCQ queue configuration and operation
+/// registers through a named resource rather than the standard HCI region.
+pub(crate) struct McqMmio(DevresIoMem);
+
+impl McqMmio {
+    #[cfg(CONFIG_RUFS_QCOM)]
+    pub(crate) fn from_platform(mmio: DevresIoMem) -> Self {
+        Self(mmio)
+    }
+
+    fn access<'a>(&'a self, dev: &'a device::Device<Bound>) -> Result<&'a IoMem<'a>> {
+        self.0.access(dev)
+    }
+}
+
+impl HciMmio {
+    #[cfg(CONFIG_RUFS_PCI)]
+    pub(crate) fn from_pci(pdev: &pci::Device<Bound>) -> Result<Self> {
+        Ok(Self::Pci(
+            pdev.iomap_region_sized::<HCI_MMIO_SIZE>(0, c_str!("rufs_pci"))?
+                .into_devres()?,
+        ))
+    }
+
+    #[cfg(CONFIG_RUFS_QCOM)]
+    pub(crate) fn from_platform(pdev: &platform::Device<Bound>) -> Result<Self> {
+        let request = pdev.io_request_by_index(0).ok_or(ENODEV)?;
+
+        Ok(Self::Platform(
+            request.iomap_sized::<HCI_MMIO_SIZE>()?.into_devres()?,
+        ))
+    }
+
+    fn access<'a>(&'a self, dev: &'a device::Device<Bound>) -> Result<HciMmioAccess<'a>> {
+        match self {
+            #[cfg(CONFIG_RUFS_PCI)]
+            Self::Pci(mmio) => Ok(HciMmioAccess::Pci(mmio.access(dev)?)),
+            #[cfg(CONFIG_RUFS_QCOM)]
+            Self::Platform(mmio) => Ok(HciMmioAccess::Platform(mmio.access(dev)?)),
+        }
+    }
+}
+
+#[derive(Clone, Copy)]
+pub(crate) enum HciMmioAccess<'a> {
+    #[cfg(CONFIG_RUFS_PCI)]
+    Pci(&'a pci::Bar<'a, HCI_MMIO_SIZE>),
+    #[cfg(CONFIG_RUFS_QCOM)]
+    Platform(&'a IoMem<'a, HCI_MMIO_SIZE>),
+}
+
+impl<'a> IoBase<'a> for HciMmioAccess<'a> {
+    type Backend = MmioBackend;
+    type Target = Region<HCI_MMIO_SIZE>;
+
+    fn as_view(self) -> Mmio<'a, Self::Target> {
+        match self {
+            #[cfg(CONFIG_RUFS_PCI)]
+            Self::Pci(mmio) => mmio.as_view(),
+            #[cfg(CONFIG_RUFS_QCOM)]
+            Self::Platform(mmio) => mmio.as_view(),
+        }
+    }
+}
+
+pub(crate) struct HostResources {
+    device: ARef<device::Device>,
+    hci: Arc<HciMmio>,
+    mcq: Option<Arc<McqMmio>>,
+    variant: KBox<dyn UfsVariantOps>,
+}
+
+impl HostResources {
+    pub(crate) fn new(
+        device: ARef<device::Device>,
+        hci: HciMmio,
+        mcq: Option<McqMmio>,
+        variant: KBox<dyn UfsVariantOps>,
+    ) -> Result<Arc<Self>> {
+        Ok(Arc::new(
+            Self {
+                device,
+                hci: Arc::new(hci, GFP_KERNEL)?,
+                mcq: mcq.map(|mcq| Arc::new(mcq, GFP_KERNEL)).transpose()?,
+                variant,
+            },
+            GFP_KERNEL,
+        )?)
+    }
+
+    pub(crate) fn device(&self) -> &device::Device<Bound> {
+        // SAFETY: `HostResources` is owned by the bound RUFS driver instance
+        // and is dropped before the frontend finishes unbinding the device.
+        unsafe { self.device.as_bound() }
+    }
+
+    pub(crate) fn hci_access(&self) -> Result<HciMmioAccess<'_>> {
+        self.hci.access(self.device())
+    }
+
+    pub(crate) fn mcq_access(&self) -> Result<&IoMem<'_>> {
+        self.mcq.as_ref().ok_or(ENODEV)?.access(self.device())
+    }
+
+    pub(crate) fn variant(&self) -> &dyn UfsVariantOps {
+        &*self.variant
+    }
+}
diff --git a/drivers/rufs/transport.rs b/drivers/rufs/transport.rs
new file mode 100644
index 0000000000000..6e63d1478304a
--- /dev/null
+++ b/drivers/rufs/transport.rs
@@ -0,0 +1,354 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! UFS transfer transports.
+
+use crate::command::{TaskTag, TASK_TAG_COUNT};
+use crate::dma::UfsDma;
+use crate::hci::descriptor::CqEntry;
+use crate::reg::UfsReg;
+use kernel::cpu;
+use kernel::prelude::*;
+use kernel::sync::Arc;
+
+pub(crate) mod mcq;
+pub(crate) mod sdb;
+
+pub(crate) use mcq::McqInterruptQueue;
+use mcq::{McqHwQueue, McqTransferBackend};
+use sdb::{SdbHwQueue, SdbTransferBackend};
+
+const UFS_MCQ_DEFAULT_READ_QUEUES: usize = 0;
+const UFS_MCQ_DEFAULT_POLL_QUEUES: usize = 1;
+const COMPLETION_BATCH_SIZE: usize = 16;
+
+fn possible_cpus() -> usize {
+    (cpu::nr_cpu_ids() as usize).max(1)
+}
+
+#[derive(Copy, Clone)]
+pub(crate) struct McqConfig {
+    pub(crate) max_queues: usize,
+    pub(crate) total_queues: usize,
+    pub(crate) default_queues: usize,
+    pub(crate) read_queues: usize,
+    pub(crate) interrupt_queues: usize,
+    pub(crate) poll_queues: usize,
+    pub(crate) queue_depth: usize,
+    pub(crate) ring_entries: usize,
+}
+
+impl McqConfig {
+    pub(crate) fn is_poll_queue(&self, queue: usize) -> bool {
+        queue >= self.interrupt_queues && queue < self.total_queues
+    }
+}
+
+#[derive(Copy, Clone)]
+pub(crate) enum UfsTransferConfig {
+    Sdb { tag_count: usize },
+    Mcq(McqConfig),
+}
+
+impl UfsTransferConfig {
+    pub(crate) fn new(reg: &UfsReg) -> Result<Self> {
+        let hardware_mcq = reg.mcq_hardware_supported();
+        let variant_mcq = reg.mcq_variant_enabled();
+
+        if !hardware_mcq || !variant_mcq {
+            pr_info!(
+                "[RUFS] ufs_queue: SDB selected CAP.MCQ={} variant.MCQ={}\n",
+                hardware_mcq,
+                variant_mcq,
+            );
+            let tag_count = reg.nutrs();
+            if tag_count == 0 || tag_count > u32::BITS as usize {
+                return Err(EINVAL);
+            }
+            return Ok(Self::Sdb { tag_count });
+        }
+
+        let max_queues = reg.mcq_max_queues();
+        let read_queues = UFS_MCQ_DEFAULT_READ_QUEUES;
+        let poll_queues = UFS_MCQ_DEFAULT_POLL_QUEUES;
+        let reserved_queues = read_queues.checked_add(poll_queues).ok_or(EOVERFLOW)?;
+        if max_queues <= reserved_queues {
+            return Err(ENOTSUPP);
+        }
+
+        let default_queues = core::cmp::min(max_queues - reserved_queues, possible_cpus());
+        let interrupt_queues = default_queues.checked_add(read_queues).ok_or(EOVERFLOW)?;
+        let total_queues = interrupt_queues.checked_add(poll_queues).ok_or(EOVERFLOW)?;
+        let queue_depth =
+            reg.constrain_mcq_active_commands(core::cmp::min(reg.nutrs_mcq(), TASK_TAG_COUNT));
+        let ring_entries = queue_depth.checked_add(1).ok_or(EOVERFLOW)?;
+        if interrupt_queues == 0 || queue_depth == 0 {
+            return Err(EINVAL);
+        }
+
+        Ok(Self::Mcq(McqConfig {
+            max_queues,
+            total_queues,
+            default_queues,
+            read_queues,
+            interrupt_queues,
+            poll_queues,
+            queue_depth,
+            ring_entries,
+        }))
+    }
+
+    pub(crate) fn queue_depth(&self) -> usize {
+        match self {
+            Self::Sdb { tag_count } => *tag_count,
+            Self::Mcq(config) => config.queue_depth,
+        }
+    }
+}
+
+#[derive(Clone, Copy)]
+pub(crate) enum TransferCompletion {
+    Sdb,
+    Mcq(CqEntry),
+}
+
+#[derive(Clone, Copy)]
+pub(crate) enum CompletedRequest {
+    Sdb(TaskTag),
+    Mcq { queue_id: u32, cqe: CqEntry },
+}
+
+impl CompletedRequest {
+    pub(crate) fn task_tag(self) -> TaskTag {
+        match self {
+            Self::Sdb(task_tag) => task_tag,
+            Self::Mcq { cqe, .. } => TaskTag::from_value(cqe.task_tag()),
+        }
+    }
+
+    pub(crate) fn queue_id(self) -> u32 {
+        match self {
+            Self::Sdb(_) => 0,
+            Self::Mcq { queue_id, .. } => queue_id,
+        }
+    }
+
+    pub(crate) fn completion(self) -> TransferCompletion {
+        match self {
+            Self::Sdb(_) => TransferCompletion::Sdb,
+            Self::Mcq { cqe, .. } => TransferCompletion::Mcq(cqe),
+        }
+    }
+}
+
+#[derive(Clone, Copy)]
+pub(crate) struct CompletionFault {
+    pub(crate) reason: &'static str,
+    pub(crate) tag: usize,
+    pub(crate) queue_id: Option<u32>,
+}
+
+pub(crate) struct CompletedRequests {
+    requests: [Option<CompletedRequest>; COMPLETION_BATCH_SIZE],
+    len: usize,
+    pos: usize,
+    fault: Option<CompletionFault>,
+}
+
+impl CompletedRequests {
+    pub(crate) const fn capacity() -> usize {
+        COMPLETION_BATCH_SIZE
+    }
+
+    pub(crate) fn new() -> Self {
+        Self {
+            requests: [None; COMPLETION_BATCH_SIZE],
+            len: 0,
+            pos: 0,
+            fault: None,
+        }
+    }
+
+    fn insert(&mut self, request: CompletedRequest) -> Result<()> {
+        if self.len == self.requests.len() {
+            return Err(ENOMEM);
+        }
+
+        self.requests[self.len] = Some(request);
+        self.len += 1;
+        Ok(())
+    }
+
+    pub(crate) fn insert_mcq(&mut self, queue_id: u32, cqe: CqEntry) -> Result<()> {
+        self.insert(CompletedRequest::Mcq { queue_id, cqe })
+    }
+
+    pub(crate) fn insert_sdb_mask(&mut self, mut mask: u32) -> Result<u32> {
+        let mut inserted = 0;
+
+        while mask != 0 && !self.is_full() {
+            let tag = mask.trailing_zeros();
+            let tag_mask = 1u32 << tag;
+            mask &= !tag_mask;
+            self.insert(CompletedRequest::Sdb(TaskTag::new(tag)?))?;
+            inserted |= tag_mask;
+        }
+
+        Ok(inserted)
+    }
+
+    pub(crate) fn is_full(&self) -> bool {
+        self.len == self.requests.len()
+    }
+
+    pub(crate) fn record_fault(&mut self, reason: &'static str, tag: usize, queue_id: Option<u32>) {
+        if self.fault.is_none() {
+            self.fault = Some(CompletionFault {
+                reason,
+                tag,
+                queue_id,
+            });
+        }
+    }
+
+    pub(crate) fn take_fault(&mut self) -> Option<CompletionFault> {
+        self.fault.take()
+    }
+
+    pub(crate) fn take_next(&mut self) -> Option<CompletedRequest> {
+        if self.pos == self.len {
+            return None;
+        }
+
+        let request = self.requests[self.pos].take();
+        self.pos += 1;
+        request
+    }
+}
+
+pub(crate) enum SubmissionOutcome {
+    Submitted,
+    NotSubmitted(Error),
+    PublishFailed(Error),
+}
+
+#[derive(Clone)]
+pub(crate) struct UfsHwQueue {
+    inner: UfsHwQueueKind,
+}
+
+#[derive(Clone)]
+enum UfsHwQueueKind {
+    Sdb(SdbHwQueue),
+    Mcq(McqHwQueue),
+}
+
+impl UfsHwQueue {
+    pub(crate) fn sdb(queue: SdbHwQueue) -> Self {
+        Self {
+            inner: UfsHwQueueKind::Sdb(queue),
+        }
+    }
+
+    pub(crate) fn mcq(queue: McqHwQueue) -> Self {
+        Self {
+            inner: UfsHwQueueKind::Mcq(queue),
+        }
+    }
+
+    pub(crate) fn id(&self) -> u32 {
+        match &self.inner {
+            UfsHwQueueKind::Sdb(queue) => queue.id(),
+            UfsHwQueueKind::Mcq(queue) => queue.id(),
+        }
+    }
+
+    pub(crate) fn submit<F>(&self, tag: u32, polled: bool, publish: F) -> SubmissionOutcome
+    where
+        F: FnOnce() -> Result<()>,
+    {
+        match &self.inner {
+            UfsHwQueueKind::Sdb(queue) => queue.submit(tag, polled, publish),
+            UfsHwQueueKind::Mcq(queue) => queue.submit(tag, publish),
+        }
+    }
+
+    pub(crate) fn poll(&self, completed: &mut CompletedRequests) -> Result<()> {
+        match &self.inner {
+            UfsHwQueueKind::Sdb(queue) => queue.poll(completed),
+            UfsHwQueueKind::Mcq(queue) => queue.poll(completed),
+        }
+    }
+}
+
+pub(crate) trait UfsTransferOps: Send + Sync {
+    fn hw_queues(&self) -> Result<KVec<UfsHwQueue>>;
+    fn dump_state(&self, tag: usize, reason: &str);
+    fn collect_completions(&self, completed: &mut CompletedRequests) -> Result<()>;
+    fn enable_interrupts(&self);
+    fn reset(&self) -> Result<()>;
+}
+
+pub(crate) struct UfsTransferBackend {
+    ops: KBox<dyn UfsTransferOps>,
+    interrupt_queues: KVec<McqInterruptQueue>,
+}
+
+impl UfsTransferBackend {
+    pub(crate) fn new(
+        config: UfsTransferConfig,
+        reg: Arc<UfsReg>,
+        dma: Arc<UfsDma>,
+    ) -> Result<Self> {
+        let (ops, interrupt_queues) = match config {
+            UfsTransferConfig::Sdb { .. } => (
+                KBox::new(SdbTransferBackend::new(reg)?, GFP_KERNEL)? as KBox<dyn UfsTransferOps>,
+                KVec::new(),
+            ),
+            UfsTransferConfig::Mcq(config) => {
+                let backend = KBox::new(McqTransferBackend::new(config, reg, dma)?, GFP_KERNEL)?;
+                let interrupt_queues = backend.interrupt_queues()?;
+                backend.activate()?;
+                pr_info!(
+                    "[RUFS] ufs_queue: MCQ backend enabled queues={}/{} interrupt={} poll={} allocated={} depth={} ring_entries={}\n",
+                    config.total_queues,
+                    config.max_queues,
+                    config.interrupt_queues,
+                    config.poll_queues,
+                    backend.allocated_queues(),
+                    backend.queue_depth(),
+                    config.ring_entries,
+                );
+                (backend as KBox<dyn UfsTransferOps>, interrupt_queues)
+            }
+        };
+
+        Ok(Self {
+            ops,
+            interrupt_queues,
+        })
+    }
+
+    pub(crate) fn hw_queues(&self) -> Result<KVec<UfsHwQueue>> {
+        self.ops.hw_queues()
+    }
+
+    pub(crate) fn collect_completions(&self, completed: &mut CompletedRequests) -> Result<()> {
+        self.ops.collect_completions(completed)
+    }
+
+    pub(crate) fn interrupt_queues(&self) -> &[McqInterruptQueue] {
+        &self.interrupt_queues
+    }
+
+    pub(crate) fn enable_interrupts(&self) {
+        self.ops.enable_interrupts()
+    }
+
+    pub(crate) fn dump_state(&self, tag: usize, reason: &str) {
+        self.ops.dump_state(tag, reason)
+    }
+
+    pub(crate) fn reset(&self) -> Result<()> {
+        self.ops.reset()
+    }
+}
diff --git a/drivers/rufs/transport/mcq.rs b/drivers/rufs/transport/mcq.rs
new file mode 100644
index 0000000000000..1812eef626f04
--- /dev/null
+++ b/drivers/rufs/transport/mcq.rs
@@ -0,0 +1,655 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! UFSHCI multi-circular queue transport.
+
+use crate::dma::UfsDma;
+use crate::hci::descriptor::{CqEntry, SqEntry};
+use crate::reg::{McqRegisterLayout, UfsMcqOprRegion, UfsMcqOprSet, UfsReg};
+use crate::transport::{
+    CompletedRequests, McqConfig, SubmissionOutcome, UfsHwQueue, UfsTransferOps,
+};
+use kernel::io::{io_project, Io};
+use kernel::sync::{barrier, Arc, SpinLock};
+use kernel::{
+    device::{self, Bound},
+    dma, new_spinlock,
+    prelude::*,
+};
+
+struct UfsMcqQueue {
+    descriptor: UfsMcqQueueDescriptor,
+    submission: UfsMcqSubmissionQueue,
+    completion: UfsMcqCompletionQueue,
+}
+
+#[derive(Clone, Copy)]
+struct UfsMcqQueueDescriptor {
+    id: u32,
+    max_entries: u32,
+    oprs: UfsMcqOprSet,
+}
+
+struct UfsMcqSubmissionQueue {
+    sqe: dma::Coherent<[SqEntry]>,
+    sq_tail_slot: u32,
+}
+
+struct UfsMcqCompletionQueue {
+    cqe: dma::Coherent<[CqEntry]>,
+    cq_tail_slot: u32,
+    cq_head_slot: u32,
+}
+
+impl UfsMcqQueue {
+    fn new(
+        dev: &device::Device<Bound>,
+        id: u32,
+        max_entries: u32,
+        oprs: UfsMcqOprSet,
+    ) -> Result<Self> {
+        if max_entries == 0 {
+            return Err(EINVAL);
+        }
+
+        let entries = max_entries as usize;
+        Ok(Self {
+            descriptor: UfsMcqQueueDescriptor {
+                id,
+                max_entries,
+                oprs,
+            },
+            submission: UfsMcqSubmissionQueue {
+                sqe: dma::Coherent::<SqEntry>::zeroed_slice_zerocopy(dev, entries, GFP_KERNEL)?,
+                sq_tail_slot: 0,
+            },
+            completion: UfsMcqCompletionQueue {
+                cqe: dma::Coherent::<CqEntry>::zeroed_slice_zerocopy(dev, entries, GFP_KERNEL)?,
+                cq_tail_slot: 0,
+                cq_head_slot: 0,
+            },
+        })
+    }
+
+    fn into_parts(
+        self,
+    ) -> (
+        UfsMcqQueueDescriptor,
+        UfsMcqSubmissionQueue,
+        UfsMcqCompletionQueue,
+    ) {
+        (self.descriptor, self.submission, self.completion)
+    }
+}
+
+impl UfsMcqQueueDescriptor {
+    fn id(&self) -> u32 {
+        self.id
+    }
+
+    fn max_entries(&self) -> u32 {
+        self.max_entries
+    }
+
+    fn oprs(&self) -> &UfsMcqOprSet {
+        &self.oprs
+    }
+
+    fn acknowledge_completion_events(&self, reg: &UfsReg) -> Result<bool> {
+        let status = reg.read_mcq_cqis(self.oprs(), self.id() as usize)?;
+        if status != 0 {
+            reg.write_mcq_cqis(self.oprs(), self.id() as usize, status)?;
+        }
+
+        Ok(status != 0)
+    }
+
+    fn offset_to_slot(&self, offset: u32, entry_size: u32) -> Result<u32> {
+        if offset % entry_size != 0 {
+            return Err(EINVAL);
+        }
+
+        let slot = offset / entry_size;
+        if slot >= self.max_entries {
+            return Err(EINVAL);
+        }
+
+        Ok(slot)
+    }
+}
+
+impl UfsMcqSubmissionQueue {
+    fn dma_addr(&self) -> dma::DmaAddress {
+        self.sqe.dma_address()
+    }
+
+    fn sq_tail_slot(&self) -> u32 {
+        self.sq_tail_slot
+    }
+
+    fn set_sq_tail_slot(&mut self, slot: u32) {
+        self.sq_tail_slot = slot;
+    }
+
+    fn sq_tail_index(&self, descriptor: &UfsMcqQueueDescriptor) -> Result<usize> {
+        let index = self.sq_tail_slot as usize;
+        if index >= descriptor.max_entries as usize {
+            return Err(EINVAL);
+        }
+
+        Ok(index)
+    }
+
+    fn sq_slot_offset(slot: u32) -> u32 {
+        slot * core::mem::size_of::<SqEntry>() as u32
+    }
+
+    fn next_sq_tail_slot(&self, descriptor: &UfsMcqQueueDescriptor) -> u32 {
+        let next = self.sq_tail_slot + 1;
+        if next == descriptor.max_entries {
+            0
+        } else {
+            next
+        }
+    }
+
+    fn is_full(&self, reg: &UfsReg, descriptor: &UfsMcqQueueDescriptor) -> Result<bool> {
+        let head = descriptor.offset_to_slot(
+            reg.read_mcq_sq_head(descriptor.oprs(), descriptor.id() as usize)?,
+            core::mem::size_of::<SqEntry>() as u32,
+        )?;
+        Ok(self.next_sq_tail_slot(descriptor) == head)
+    }
+
+    fn reset(&mut self) {
+        self.sq_tail_slot = 0;
+    }
+
+    fn write_entry(&mut self, descriptor: &UfsMcqQueueDescriptor, entry: SqEntry) -> Result<u32> {
+        let index = self.sq_tail_index(descriptor)?;
+        io_project!(self.sqe, [try: index]).copy_write(entry);
+
+        self.sq_tail_slot = self.next_sq_tail_slot(descriptor);
+
+        Ok(Self::sq_slot_offset(self.sq_tail_slot))
+    }
+}
+
+impl UfsMcqCompletionQueue {
+    fn dma_addr(&self) -> dma::DmaAddress {
+        self.cqe.dma_address()
+    }
+
+    fn tail_slot(&self) -> u32 {
+        self.cq_tail_slot
+    }
+
+    fn head_slot(&self) -> u32 {
+        self.cq_head_slot
+    }
+
+    fn update_tail(&mut self, reg: &UfsReg, descriptor: &UfsMcqQueueDescriptor) -> Result<()> {
+        self.cq_tail_slot = descriptor.offset_to_slot(
+            reg.read_mcq_cq_tail(descriptor.oprs(), descriptor.id() as usize)?,
+            core::mem::size_of::<CqEntry>() as u32,
+        )?;
+        Ok(())
+    }
+
+    fn is_empty(&self) -> bool {
+        self.cq_head_slot == self.cq_tail_slot
+    }
+
+    fn reset(&mut self) {
+        self.cq_tail_slot = 0;
+        self.cq_head_slot = 0;
+    }
+
+    fn consume_entry(&mut self, descriptor: &UfsMcqQueueDescriptor) -> Result<Option<CqEntry>> {
+        let index = self.cq_head_slot as usize;
+        if index >= descriptor.max_entries as usize {
+            return Err(EINVAL);
+        }
+
+        let cqe = io_project!(self.cqe, [try: index]).copy_read();
+        if cqe.is_empty() {
+            return Ok(None);
+        }
+
+        io_project!(self.cqe, [try: index]).copy_write(CqEntry::default());
+
+        self.cq_head_slot += 1;
+        if self.cq_head_slot == descriptor.max_entries {
+            self.cq_head_slot = 0;
+        }
+
+        Ok(Some(cqe))
+    }
+
+    fn commit_head(&self, reg: &UfsReg, descriptor: &UfsMcqQueueDescriptor) -> Result<()> {
+        reg.write_mcq_cq_head(
+            descriptor.oprs(),
+            descriptor.id() as usize,
+            self.cq_head_slot * core::mem::size_of::<CqEntry>() as u32,
+        )
+    }
+}
+
+#[pin_data]
+struct McqHardwareQueue {
+    descriptor: UfsMcqQueueDescriptor,
+    #[pin]
+    submission: SpinLock<UfsMcqSubmissionQueue>,
+    #[pin]
+    completion: SpinLock<UfsMcqCompletionQueue>,
+}
+
+impl McqHardwareQueue {
+    fn new(queue: UfsMcqQueue) -> Result<Arc<Self>> {
+        let (descriptor, submission, completion) = queue.into_parts();
+        Arc::pin_init(
+            pin_init!(Self {
+                descriptor,
+                submission <- new_spinlock!(submission),
+                completion <- new_spinlock!(completion),
+            }),
+            GFP_KERNEL,
+        )
+    }
+
+    fn submit<F>(&self, reg: &UfsReg, dma: &UfsDma, tag: u32, publish: F) -> SubmissionOutcome
+    where
+        F: FnOnce() -> Result<()>,
+    {
+        let mut submission = self.submission.lock();
+        match submission.is_full(reg, &self.descriptor) {
+            Ok(true) => return SubmissionOutcome::NotSubmitted(EBUSY),
+            Err(e) => return SubmissionOutcome::NotSubmitted(e),
+            Ok(false) => {}
+        }
+
+        let sqe = match dma.transfer_request_desc(tag as usize) {
+            Ok(sqe) => sqe,
+            Err(e) => return SubmissionOutcome::NotSubmitted(e),
+        };
+        let previous_tail = submission.sq_tail_slot();
+        let tail = match submission.write_entry(&self.descriptor, sqe) {
+            Ok(tail) => tail,
+            Err(e) => return SubmissionOutcome::NotSubmitted(e),
+        };
+        if let Err(e) = publish() {
+            submission.set_sq_tail_slot(previous_tail);
+            return SubmissionOutcome::NotSubmitted(e);
+        }
+
+        barrier::dma_mb(barrier::Write);
+        match reg.write_mcq_sq_tail(self.descriptor.oprs(), self.descriptor.id() as usize, tail) {
+            Ok(()) => SubmissionOutcome::Submitted,
+            Err(e) => SubmissionOutcome::PublishFailed(e),
+        }
+    }
+
+    fn collect_completions(
+        &self,
+        reg: &UfsReg,
+        dma: &UfsDma,
+        completed_requests: &mut CompletedRequests,
+    ) -> Result<()> {
+        let mut completion = self.completion.lock();
+        self.descriptor.acknowledge_completion_events(reg)?;
+        completion.update_tail(reg, &self.descriptor)?;
+        barrier::dma_mb(barrier::Read);
+        let mut consumed = false;
+        let result = (|| {
+            while !completion.is_empty() && !completed_requests.is_full() {
+                let Some(cqe) = completion.consume_entry(&self.descriptor)? else {
+                    completed_requests.record_fault(
+                        "empty MCQ completion entry",
+                        completion.head_slot() as usize,
+                        Some(self.descriptor.id()),
+                    );
+                    break;
+                };
+
+                consumed = true;
+                match dma.validate_cq_entry(&cqe, self.descriptor.id()) {
+                    Ok(()) => completed_requests.insert_mcq(self.descriptor.id(), cqe)?,
+                    Err(_) => completed_requests.record_fault(
+                        "invalid MCQ completion descriptor",
+                        usize::from(cqe.task_tag()),
+                        Some(self.descriptor.id()),
+                    ),
+                }
+            }
+            Ok(())
+        })();
+        if consumed {
+            completion.commit_head(reg, &self.descriptor)?;
+        }
+
+        result
+    }
+}
+
+#[derive(Clone)]
+pub(crate) struct McqHwQueue {
+    reg: Arc<UfsReg>,
+    dma: Arc<UfsDma>,
+    queue: Arc<McqHardwareQueue>,
+    poll: bool,
+}
+
+impl McqHwQueue {
+    pub(crate) fn id(&self) -> u32 {
+        self.queue.descriptor.id()
+    }
+
+    pub(crate) fn submit<F>(&self, tag: u32, publish: F) -> SubmissionOutcome
+    where
+        F: FnOnce() -> Result<()>,
+    {
+        self.queue.submit(&self.reg, &self.dma, tag, publish)
+    }
+
+    pub(crate) fn poll(&self, completed: &mut CompletedRequests) -> Result<()> {
+        if !self.poll {
+            return Err(EINVAL);
+        }
+        self.queue
+            .collect_completions(&self.reg, &self.dma, completed)
+    }
+}
+
+#[derive(Clone)]
+pub(crate) struct McqInterruptQueue {
+    reg: Arc<UfsReg>,
+    dma: Arc<UfsDma>,
+    queue: Arc<McqHardwareQueue>,
+}
+
+impl McqInterruptQueue {
+    pub(crate) fn id(&self) -> u32 {
+        self.queue.descriptor.id()
+    }
+
+    pub(crate) fn acknowledge_completion(&self) -> Result<bool> {
+        self.queue
+            .descriptor
+            .acknowledge_completion_events(&self.reg)
+    }
+
+    pub(crate) fn collect_completions(&self, completed: &mut CompletedRequests) -> Result<()> {
+        self.queue
+            .collect_completions(&self.reg, &self.dma, completed)
+    }
+}
+
+#[pin_data]
+struct McqQueueSet {
+    queues: KVec<Arc<McqHardwareQueue>>,
+}
+
+impl McqQueueSet {
+    fn new(queues: KVec<Arc<McqHardwareQueue>>) -> impl PinInit<Self> {
+        pin_init!(Self { queues })
+    }
+
+    fn len(&self) -> usize {
+        self.queues.len()
+    }
+
+    fn poll_completions(
+        &self,
+        reg: &UfsReg,
+        dma: &UfsDma,
+        nr_queues: usize,
+        completed_requests: &mut CompletedRequests,
+    ) -> Result<()> {
+        for queue in self.queues.iter().take(nr_queues) {
+            queue.collect_completions(reg, dma, completed_requests)?;
+            if completed_requests.is_full() {
+                break;
+            }
+        }
+
+        Ok(())
+    }
+
+    fn dump_state(&self, reg: &UfsReg, tag: usize, reason: &str) {
+        if self.queues.is_empty() {
+            pr_err!(
+                "[RUFS] ufs_queue: MCQ dump reason={} tag={} queues=unallocated\n",
+                reason,
+                tag,
+            );
+            return;
+        }
+
+        for queue in self.queues.iter() {
+            let descriptor = &queue.descriptor;
+            let id = descriptor.id() as usize;
+            let sq_head = reg
+                .read_mcq_sq_head(descriptor.oprs(), id)
+                .unwrap_or(u32::MAX);
+            let sq_tail = reg
+                .read_mcq_sq_tail(descriptor.oprs(), id)
+                .unwrap_or(u32::MAX);
+            let cq_head = reg
+                .read_mcq_cq_head(descriptor.oprs(), id)
+                .unwrap_or(u32::MAX);
+            let cq_tail = reg
+                .read_mcq_cq_tail(descriptor.oprs(), id)
+                .unwrap_or(u32::MAX);
+            let cqis = reg.read_mcq_cqis(descriptor.oprs(), id).unwrap_or(u32::MAX);
+            let sq_tail_slot = queue.submission.lock().sq_tail_slot();
+            let completion = queue.completion.lock();
+
+            pr_err!(
+                "[RUFS] ufs_queue: MCQ state reason={} tag={} q={} sqhp={} sqtp={} cqhp={} cqtp={} cqis={:#x} sw_sq_tail={} sw_cq_head={} sw_cq_tail={}\n",
+                reason,
+                tag,
+                id,
+                sq_head,
+                sq_tail,
+                cq_head,
+                cq_tail,
+                cqis,
+                sq_tail_slot,
+                completion.head_slot(),
+                completion.tail_slot(),
+            );
+        }
+    }
+
+    fn configure_registers_with_interrupt_queues(
+        &self,
+        reg: &UfsReg,
+        layout: &McqRegisterLayout,
+        interrupt_queues: usize,
+    ) -> Result<()> {
+        if interrupt_queues > self.queues.len() {
+            return Err(EINVAL);
+        }
+
+        for queue in self.queues.iter() {
+            let descriptor = &queue.descriptor;
+            let id = descriptor.id() as usize;
+            let mut submission = queue.submission.lock();
+            let mut completion = queue.completion.lock();
+            let sq_dma_addr = submission.dma_addr();
+            let cq_dma_addr = completion.dma_addr();
+
+            reg.set_mcq_sq_base_addr(layout, id, sq_dma_addr)?;
+            reg.write_mcq_sqdao(
+                layout,
+                id,
+                reg.mcq_opr_region_offset(descriptor.oprs(), UfsMcqOprRegion::Sqd, id),
+            )?;
+            reg.write_mcq_sqisao(
+                layout,
+                id,
+                reg.mcq_opr_region_offset(descriptor.oprs(), UfsMcqOprRegion::Sqis, id),
+            )?;
+
+            reg.set_mcq_cq_base_addr(layout, id, cq_dma_addr)?;
+            reg.write_mcq_cqdao(
+                layout,
+                id,
+                reg.mcq_opr_region_offset(descriptor.oprs(), UfsMcqOprRegion::Cqd, id),
+            )?;
+            reg.write_mcq_cqisao(
+                layout,
+                id,
+                reg.mcq_opr_region_offset(descriptor.oprs(), UfsMcqOprRegion::Cqis, id),
+            )?;
+
+            submission.reset();
+            completion.reset();
+            if id < interrupt_queues {
+                reg.enable_mcq_cq_tail_push_intr(descriptor.oprs(), id)?;
+            }
+            reg.enable_mcq_cq(layout, id, descriptor.max_entries() as usize)?;
+            reg.enable_mcq_sq(layout, id, descriptor.max_entries() as usize, id)?;
+        }
+
+        Ok(())
+    }
+}
+
+pub(crate) struct McqTransferBackend {
+    reg: Arc<UfsReg>,
+    dma: Arc<UfsDma>,
+    config: McqConfig,
+    register_layout: McqRegisterLayout,
+    queues: Arc<McqQueueSet>,
+}
+
+impl McqTransferBackend {
+    pub(crate) fn new(config: McqConfig, reg: Arc<UfsReg>, dma: Arc<UfsDma>) -> Result<Self> {
+        let register_layout = reg.mcq_register_layout()?;
+        let oprs = register_layout.oprs();
+        let mut hardware_queues = KVec::new();
+        let ring_entries = u32::try_from(config.ring_entries).map_err(|_| EOVERFLOW)?;
+        for id in 0..config.total_queues {
+            let queue = UfsMcqQueue::new(
+                dma.dev(),
+                u32::try_from(id).map_err(|_| EOVERFLOW)?,
+                ring_entries,
+                oprs,
+            )?;
+            hardware_queues.push(McqHardwareQueue::new(queue)?, GFP_KERNEL)?;
+        }
+        let queues = Arc::pin_init(McqQueueSet::new(hardware_queues), GFP_KERNEL)?;
+
+        Ok(Self {
+            reg,
+            dma,
+            config,
+            register_layout,
+            queues,
+        })
+    }
+
+    pub(crate) fn queue_depth(&self) -> usize {
+        self.config.queue_depth
+    }
+
+    pub(crate) fn allocated_queues(&self) -> usize {
+        self.queues.len()
+    }
+
+    pub(crate) fn interrupt_queues(&self) -> Result<KVec<McqInterruptQueue>> {
+        let mut interrupt_queues = KVec::new();
+        for queue in self.queues.queues.iter().take(self.config.interrupt_queues) {
+            interrupt_queues.push(
+                McqInterruptQueue {
+                    reg: self.reg.clone(),
+                    dma: self.dma.clone(),
+                    queue: queue.clone(),
+                },
+                GFP_KERNEL,
+            )?;
+        }
+        if interrupt_queues.len() != self.config.interrupt_queues {
+            return Err(EINVAL);
+        }
+
+        Ok(interrupt_queues)
+    }
+
+    fn hw_queues(&self) -> Result<KVec<UfsHwQueue>> {
+        let mut hw_queues = KVec::new();
+        for queue in self.queues.queues.iter() {
+            let id = queue.descriptor.id() as usize;
+            hw_queues.push(
+                UfsHwQueue::mcq(McqHwQueue {
+                    reg: self.reg.clone(),
+                    dma: self.dma.clone(),
+                    queue: queue.clone(),
+                    poll: self.config.is_poll_queue(id),
+                }),
+                GFP_KERNEL,
+            )?;
+        }
+        Ok(hw_queues)
+    }
+
+    fn prepare(&self) -> Result<()> {
+        self.queues.configure_registers_with_interrupt_queues(
+            &self.reg,
+            &self.register_layout,
+            self.config.interrupt_queues,
+        )
+    }
+
+    fn enable(&self) {
+        self.reg.enable_mcq_mode()
+    }
+
+    pub(crate) fn activate(&self) -> Result<()> {
+        self.prepare()?;
+        self.reg.config_mcq_max_active_cmds(
+            u32::try_from(self.queue_depth()).map_err(|_| EOVERFLOW)?,
+        )?;
+        self.enable();
+        Ok(())
+    }
+
+    fn dump_state(&self, tag: usize, reason: &str) {
+        self.queues.dump_state(&self.reg, tag, reason);
+    }
+
+    // MCQ CQE consumption is destructive because the software CQ head advances.
+    // Snapshot each CQE before returning its tag so request finalization can
+    // decode the consumed CQE after the backend lock is released.
+    fn collect_completions(&self, completed: &mut CompletedRequests) -> Result<()> {
+        self.queues.poll_completions(
+            &self.reg,
+            &self.dma,
+            self.config.interrupt_queues,
+            completed,
+        )
+    }
+}
+
+impl UfsTransferOps for McqTransferBackend {
+    fn hw_queues(&self) -> Result<KVec<UfsHwQueue>> {
+        McqTransferBackend::hw_queues(self)
+    }
+
+    fn dump_state(&self, tag: usize, reason: &str) {
+        McqTransferBackend::dump_state(self, tag, reason);
+    }
+
+    fn collect_completions(&self, completed: &mut CompletedRequests) -> Result<()> {
+        McqTransferBackend::collect_completions(self, completed)
+    }
+
+    fn enable_interrupts(&self) {
+        self.reg.enable_transfer_interrupts();
+        self.reg.enable_mcq_interrupts()
+    }
+
+    fn reset(&self) -> Result<()> {
+        self.activate()
+    }
+}
diff --git a/drivers/rufs/transport/sdb.rs b/drivers/rufs/transport/sdb.rs
new file mode 100644
index 0000000000000..61ebe2974c423
--- /dev/null
+++ b/drivers/rufs/transport/sdb.rs
@@ -0,0 +1,162 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! UFSHCI single doorbell transport.
+
+use crate::reg::UfsReg;
+use crate::transport::{CompletedRequests, SubmissionOutcome, UfsHwQueue, UfsTransferOps};
+use kernel::sync::{barrier, Arc, SpinLockIrq};
+use kernel::{new_spinlock_irq, prelude::*};
+
+pub(crate) struct SdbTransferBackend {
+    reg: Arc<UfsReg>,
+    state: Arc<SdbTransferState>,
+}
+
+#[derive(Default)]
+struct SdbCompletionState {
+    outstanding: u32,
+    polled: u32,
+}
+
+#[derive(Copy, Clone)]
+enum SdbCompletionSource {
+    Interrupt,
+    Poll,
+}
+
+#[pin_data]
+struct SdbTransferState {
+    #[pin]
+    completion: SpinLockIrq<SdbCompletionState>,
+}
+
+#[derive(Clone)]
+pub(crate) struct SdbHwQueue {
+    reg: Arc<UfsReg>,
+    state: Arc<SdbTransferState>,
+}
+
+impl SdbHwQueue {
+    pub(crate) fn id(&self) -> u32 {
+        0
+    }
+
+    pub(crate) fn submit<F>(&self, tag: u32, polled: bool, publish: F) -> SubmissionOutcome
+    where
+        F: FnOnce() -> Result<()>,
+    {
+        let Some(mask) = SdbTransferBackend::tag_mask(tag) else {
+            return SubmissionOutcome::NotSubmitted(EINVAL);
+        };
+        let mut state = self.state.completion.lock();
+
+        if state.outstanding & mask != 0 {
+            return SubmissionOutcome::NotSubmitted(EBUSY);
+        }
+        if let Err(e) = publish() {
+            return SubmissionOutcome::NotSubmitted(e);
+        }
+        state.outstanding |= mask;
+        if polled {
+            state.polled |= mask;
+        } else {
+            state.polled &= !mask;
+        }
+        barrier::dma_mb(barrier::Write);
+        self.reg.ring_utrl_doorbell(tag);
+        SubmissionOutcome::Submitted
+    }
+
+    pub(crate) fn poll(&self, completed: &mut CompletedRequests) -> Result<()> {
+        SdbTransferBackend::collect_state_completions(
+            &self.reg,
+            &self.state,
+            SdbCompletionSource::Poll,
+            completed,
+        )
+    }
+}
+
+impl SdbTransferBackend {
+    pub(crate) fn new(reg: Arc<UfsReg>) -> Result<Self> {
+        let state = Arc::pin_init(
+            pin_init!(SdbTransferState {
+                completion <- new_spinlock_irq!(SdbCompletionState::default()),
+            }),
+            GFP_KERNEL,
+        )?;
+
+        Ok(Self { reg, state })
+    }
+
+    fn tag_mask(tag: u32) -> Option<u32> {
+        1u32.checked_shl(tag)
+    }
+
+    fn collect_state_completions(
+        reg: &UfsReg,
+        state: &SdbTransferState,
+        source: SdbCompletionSource,
+        requests: &mut CompletedRequests,
+    ) -> Result<()> {
+        let mut state = state.completion.lock();
+        let doorbell = reg.read_utrl_doorbell();
+        let completed = !doorbell & state.outstanding;
+        let eligible = match source {
+            SdbCompletionSource::Interrupt => completed & !state.polled,
+            SdbCompletionSource::Poll => completed & state.polled,
+        };
+        if eligible != 0 {
+            barrier::dma_mb(barrier::Read);
+        }
+        let collected = requests.insert_sdb_mask(eligible)?;
+
+        state.outstanding &= !collected;
+        state.polled &= !collected;
+        Ok(())
+    }
+}
+
+impl UfsTransferOps for SdbTransferBackend {
+    fn hw_queues(&self) -> Result<KVec<UfsHwQueue>> {
+        let mut queues = KVec::new();
+        queues.push(
+            UfsHwQueue::sdb(SdbHwQueue {
+                reg: self.reg.clone(),
+                state: self.state.clone(),
+            }),
+            GFP_KERNEL,
+        )?;
+        Ok(queues)
+    }
+
+    fn collect_completions(&self, completed: &mut CompletedRequests) -> Result<()> {
+        Self::collect_state_completions(
+            &self.reg,
+            &self.state,
+            SdbCompletionSource::Interrupt,
+            completed,
+        )
+    }
+
+    fn enable_interrupts(&self) {
+        self.reg.enable_transfer_interrupts()
+    }
+
+    fn reset(&self) -> Result<()> {
+        *self.state.completion.lock() = SdbCompletionState::default();
+        Ok(())
+    }
+
+    fn dump_state(&self, tag: usize, reason: &str) {
+        let state = self.state.completion.lock();
+
+        pr_err!(
+            "[RUFS] ufs_queue: SDB dump reason={} tag={} outstanding=0x{:x} polled=0x{:x}\n",
+            reason,
+            tag,
+            state.outstanding,
+            state.polled,
+        );
+    }
+}
diff --git a/drivers/rufs/ufs.rs b/drivers/rufs/ufs.rs
new file mode 100644
index 0000000000000..f9b90950d5df7
--- /dev/null
+++ b/drivers/rufs/ufs.rs
@@ -0,0 +1,63 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! Driver for UFS host controllers.
+//!
+//! Based on the C driver written by Santosh Yaraganavi <santosh.sy@samsung.com>.
+
+#[cfg(CONFIG_RUFS_PCI)]
+use kernel::pci;
+#[cfg(CONFIG_RUFS_QCOM)]
+use kernel::platform;
+use kernel::{c_str, driver, prelude::*, InPlaceModule};
+
+mod command;
+mod device;
+mod dma;
+mod frontend;
+mod hci;
+mod host;
+mod irq;
+mod lu;
+mod protocol;
+mod queue;
+mod reg;
+mod resource;
+mod transport;
+mod uic;
+mod variant;
+
+#[cfg(CONFIG_RUFS_PCI)]
+use frontend::pci::UfsPci;
+#[cfg(CONFIG_RUFS_QCOM)]
+use frontend::qcom::UfsQcom;
+
+#[pin_data]
+struct UfsModule {
+    #[cfg(CONFIG_RUFS_PCI)]
+    #[pin]
+    _pci_driver: driver::Registration<pci::Adapter<UfsPci>>,
+    #[cfg(CONFIG_RUFS_QCOM)]
+    #[pin]
+    _qcom_driver: driver::Registration<platform::Adapter<UfsQcom>>,
+}
+
+impl InPlaceModule for UfsModule {
+    fn init(module: &'static kernel::ThisModule) -> impl PinInit<Self, Error> {
+        try_pin_init!(Self {
+            #[cfg(CONFIG_RUFS_PCI)]
+            _pci_driver <- driver::Registration::new(c_str!("rufs"), module),
+            #[cfg(CONFIG_RUFS_QCOM)]
+            _qcom_driver <- driver::Registration::new(c_str!("rufs-qcom"), module),
+        })
+    }
+}
+
+module! {
+    type: UfsModule,
+    name: "rufs",
+    authors: ["Jaemyung Lee", "Andreas Hindborg"],
+    description: "Rust UFS host controller driver",
+    license: "GPL v2",
+}
+
+pub(crate) const RUFS_MODULE: &kernel::ThisModule = kernel::module::this_module::<UfsModule>();
diff --git a/drivers/rufs/uic.rs b/drivers/rufs/uic.rs
new file mode 100644
index 0000000000000..2d3965264d417
--- /dev/null
+++ b/drivers/rufs/uic.rs
@@ -0,0 +1,440 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#![allow(dead_code)]
+
+use crate::reg::*;
+use kernel::sync::{Arc, Completion, Mutex, SpinLock};
+use kernel::time::Delta;
+use kernel::{new_mutex, new_spinlock, prelude::*};
+
+#[derive(Copy, Clone)]
+enum UicCmdDme {
+    Get = 0x01,
+    Set = 0x02,
+    PeerGet = 0x03,
+    PeerSet = 0x04,
+    PowerOn = 0x10,
+    PowerOff = 0x11,
+    Enable = 0x12,
+    Reset = 0x14,
+    EndPtRst = 0x15,
+    LinkStartup = 0x16,
+    HibernEnter = 0x17,
+    HibernExit = 0x18,
+    TestMode = 0x1A,
+}
+
+enum UicCmdTimeoutMs {
+    Default = 500,
+    Max = 5000,
+}
+
+#[derive(Copy, Clone, Debug)]
+pub(crate) enum UfsPaPwrMode {
+    Fast = 1,
+    Slow = 2,
+}
+
+#[derive(Copy, Clone)]
+pub(crate) struct UfsPaLayerAttr {
+    pub(crate) gear_rx: u32,
+    pub(crate) gear_tx: u32,
+    pub(crate) lane_rx: u32,
+    pub(crate) lane_tx: u32,
+    pub(crate) pwr_rx: UfsPaPwrMode,
+    pub(crate) pwr_tx: UfsPaPwrMode,
+    pub(crate) hs_rate: u32,
+}
+
+#[derive(Copy, Clone)]
+struct UfsUicCmd {
+    command: UicCmdDme,
+    argument1: u32,
+    argument2: u32,
+    argument3: u32,
+    expected_completion: UicCompletion,
+}
+
+#[derive(Copy, Clone, PartialEq, Eq)]
+enum UicCompletion {
+    Command,
+    PowerMode,
+}
+
+#[derive(Copy, Clone)]
+enum UicCmdResult {
+    Success = 0x00,
+    InvalidAttr = 0x01,
+    InvalidAttrValue = 0x02,
+    ReadOnlyAttr = 0x03,
+    WriteOnlyAttr = 0x04,
+    BadIndex = 0x05,
+    LockedAttr = 0x06,
+    BadTestFeatureIndex = 0x07,
+    PeerCommFailure = 0x08,
+    Busy = 0x09,
+    DmeFailure = 0x0A,
+    PowerModeChange,
+}
+
+impl From<u32> for UicCmdResult {
+    fn from(result: u32) -> Self {
+        match result {
+            0x00 => UicCmdResult::Success,
+            0x01 => UicCmdResult::InvalidAttr,
+            0x02 => UicCmdResult::InvalidAttrValue,
+            0x03 => UicCmdResult::ReadOnlyAttr,
+            0x04 => UicCmdResult::WriteOnlyAttr,
+            0x05 => UicCmdResult::BadIndex,
+            0x06 => UicCmdResult::LockedAttr,
+            0x07 => UicCmdResult::BadTestFeatureIndex,
+            0x08 => UicCmdResult::PeerCommFailure,
+            0x09 => UicCmdResult::Busy,
+            _ => UicCmdResult::DmeFailure,
+        }
+    }
+}
+
+#[derive(Copy, Clone)]
+struct UfsUicRsp {
+    result: UicCmdResult,
+    value: u32,
+}
+
+#[derive(Default)]
+struct UicTransactionState {
+    command: Option<UfsUicCmd>,
+    response: Option<UfsUicRsp>,
+}
+
+#[pin_data]
+pub(crate) struct UfsUic {
+    reg: Arc<UfsReg>,
+
+    #[pin]
+    transaction: Mutex<()>,
+    #[pin]
+    state: SpinLock<UicTransactionState>,
+    #[pin]
+    completion: Completion,
+}
+
+impl UfsUic {
+    pub(crate) fn new(reg: Arc<UfsReg>) -> Result<Arc<Self>> {
+        Arc::pin_init(
+            try_pin_init!(Self {
+                reg,
+                transaction <- new_mutex!(()),
+                state <- new_spinlock!(UicTransactionState::default()),
+                completion <- Completion::new(),
+            }),
+            GFP_KERNEL,
+        )
+    }
+
+    pub(crate) fn link_startup(self: &Arc<Self>) -> Result<()> {
+        self.send_uic_cmd(UfsUicCmd {
+            command: UicCmdDme::LinkStartup,
+            argument1: 0,
+            argument2: 0,
+            argument3: 0,
+            expected_completion: UicCompletion::Command,
+        })?;
+
+        self.reg.read_uic_error_phy();
+        self.reg.confirm_uic_error();
+
+        Ok(())
+    }
+
+    pub(crate) fn max_power_mode(&self) -> Result<UfsPaLayerAttr> {
+        let (lane_rx, lane_tx) = self.connected_lanes()?;
+        if lane_rx == 0 || lane_tx == 0 || lane_rx != lane_tx {
+            pr_err!(
+                "[RUFS] ufs_uic: invalid connected lanes rx={} tx={}\n",
+                lane_rx,
+                lane_tx
+            );
+            return Err(EINVAL);
+        }
+
+        let mut pwr_rx = UfsPaPwrMode::Fast;
+        let mut pwr_tx = UfsPaPwrMode::Fast;
+        let mut gear_rx = self.dme_get(PA_MAXRXHSGEAR)?;
+        let mut gear_tx = self.dme_peer_get(PA_MAXRXHSGEAR)?;
+
+        if gear_rx == 0 {
+            gear_rx = self.dme_get(PA_MAXRXPWMGEAR)?;
+            pwr_rx = UfsPaPwrMode::Slow;
+        }
+        if gear_tx == 0 {
+            gear_tx = self.dme_peer_get(PA_MAXRXPWMGEAR)?;
+            pwr_tx = UfsPaPwrMode::Slow;
+        }
+        if gear_rx == 0 || gear_tx == 0 {
+            pr_err!(
+                "[RUFS] ufs_uic: invalid max gear rx={} tx={}\n",
+                gear_rx,
+                gear_tx
+            );
+            return Err(EINVAL);
+        }
+
+        Ok(UfsPaLayerAttr {
+            gear_rx,
+            gear_tx,
+            lane_rx,
+            lane_tx,
+            pwr_rx,
+            pwr_tx,
+            hs_rate: PA_HS_MODE_B,
+        })
+    }
+
+    pub(crate) fn connected_lanes(&self) -> Result<(u32, u32)> {
+        Ok((
+            self.dme_get(PA_CONNECTEDRXDATALANES)?,
+            self.dme_get(PA_CONNECTEDTXDATALANES)?,
+        ))
+    }
+
+    pub(crate) fn change_power_mode(&self, pwr_mode: UfsPaLayerAttr) -> Result<()> {
+        pr_info!(
+            "[RUFS] ufs_uic: configure power mode gear_rx={} gear_tx={} lane_rx={} lane_tx={} pwr_rx={:?} pwr_tx={:?} hs_rate={}\n",
+            pwr_mode.gear_rx,
+            pwr_mode.gear_tx,
+            pwr_mode.lane_rx,
+            pwr_mode.lane_tx,
+            pwr_mode.pwr_rx,
+            pwr_mode.pwr_tx,
+            pwr_mode.hs_rate,
+        );
+
+        self.dme_set(PA_RXGEAR, pwr_mode.gear_rx)?;
+        self.dme_set(PA_ACTIVERXDATALANES, pwr_mode.lane_rx)?;
+        self.dme_set(
+            PA_RXTERMINATION,
+            u32::from(pwr_mode.pwr_rx.uses_termination()),
+        )?;
+
+        self.dme_set(PA_TXGEAR, pwr_mode.gear_tx)?;
+        self.dme_set(PA_ACTIVETXDATALANES, pwr_mode.lane_tx)?;
+        self.dme_set(
+            PA_TXTERMINATION,
+            u32::from(pwr_mode.pwr_tx.uses_termination()),
+        )?;
+
+        if pwr_mode.pwr_rx.uses_termination() || pwr_mode.pwr_tx.uses_termination() {
+            self.dme_set(PA_HSSERIES, pwr_mode.hs_rate)?;
+        }
+
+        self.dme_set(PA_PWRMODEUSERDATA0, DL_FC0_PROTECTION_TIMEOUT_VAL_DEFAULT)?;
+        self.dme_set(PA_PWRMODEUSERDATA1, DL_TC0_REPLAY_TIMEOUT_VAL_DEFAULT)?;
+        self.dme_set(PA_PWRMODEUSERDATA2, DL_AFC0_REQ_TIMEOUT_VAL_DEFAULT)?;
+        self.dme_set(PA_PWRMODEUSERDATA3, DL_FC1_PROTECTION_TIMEOUT_VAL_DEFAULT)?;
+        self.dme_set(PA_PWRMODEUSERDATA4, DL_TC1_REPLAY_TIMEOUT_VAL_DEFAULT)?;
+        self.dme_set(PA_PWRMODEUSERDATA5, DL_AFC1_REQ_TIMEOUT_VAL_DEFAULT)?;
+
+        self.dme_set(
+            DME_LOCAL_FC0_PROTECTION_TIMEOUT_VAL,
+            DL_FC0_PROTECTION_TIMEOUT_VAL_DEFAULT,
+        )?;
+        self.dme_set(
+            DME_LOCAL_TC0_REPLAY_TIMEOUT_VAL,
+            DL_TC0_REPLAY_TIMEOUT_VAL_DEFAULT,
+        )?;
+        self.dme_set(
+            DME_LOCAL_AFC0_REQ_TIMEOUT_VAL,
+            DL_AFC0_REQ_TIMEOUT_VAL_DEFAULT,
+        )?;
+
+        self.dme_set(PA_PWRMODE, pwr_mode.pwrmode_value())
+    }
+
+    pub(crate) fn dme_get(&self, attr: u32) -> Result<u32> {
+        self.dme_get_sel(attr, 0)
+    }
+
+    pub(crate) fn dme_get_sel(&self, attr: u32, selector: u32) -> Result<u32> {
+        self.send_uic_cmd(UfsUicCmd {
+            command: UicCmdDme::Get,
+            argument1: uic_arg_mib_sel(attr, selector),
+            argument2: 0,
+            argument3: 0,
+            expected_completion: UicCompletion::Command,
+        })
+    }
+
+    fn dme_peer_get(&self, attr: u32) -> Result<u32> {
+        self.send_uic_cmd(UfsUicCmd {
+            command: UicCmdDme::PeerGet,
+            argument1: uic_arg_mib(attr),
+            argument2: 0,
+            argument3: 0,
+            expected_completion: UicCompletion::Command,
+        })
+    }
+
+    pub(crate) fn dme_set(&self, attr: u32, value: u32) -> Result<()> {
+        self.send_uic_cmd(UfsUicCmd {
+            command: UicCmdDme::Set,
+            argument1: uic_arg_mib(attr),
+            argument2: uic_arg_attr_type(0),
+            argument3: value,
+            expected_completion: if attr == PA_PWRMODE {
+                UicCompletion::PowerMode
+            } else {
+                UicCompletion::Command
+            },
+        })?;
+
+        Ok(())
+    }
+
+    fn send_uic_cmd(&self, cmd: UfsUicCmd) -> Result<u32> {
+        // Serialize command preparation, issue, wait, and response
+        // consumption. The IRQ-facing state remains under its spinlock so the
+        // completion handler never needs the sleepable transaction mutex.
+        let _transaction = self.transaction.lock();
+
+        self.completion.reinit();
+        *self.state.lock() = UicTransactionState::default();
+
+        self.reg.enable_uic_interrupts();
+        self.reg
+            .wait_for_uic_cmd_ready(500, UicCmdTimeoutMs::Default as i64)?;
+
+        self.state.lock().command = Some(cmd);
+        self.dispatch_uic_cmd(cmd);
+        let result = self.wait_for_uic_cmd();
+        self.state.lock().command = None;
+        result
+    }
+
+    fn dispatch_uic_cmd(&self, cmd: UfsUicCmd) {
+        self.reg.write_uic_arg1(cmd.argument1);
+        self.reg.write_uic_arg2(cmd.argument2);
+        self.reg.write_uic_arg3(cmd.argument3);
+        self.reg.write_uic_cmd(cmd.command as u32);
+    }
+
+    fn wait_for_uic_cmd(&self) -> Result<u32> {
+        let delta = Delta::from_millis(UicCmdTimeoutMs::Default as i64);
+        match self.completion.wait_for_completion_timeout(delta) {
+            0 => Err(ETIMEDOUT),
+            _ => {
+                let rsp = self.state.lock().response.take();
+                match rsp {
+                    Some(UfsUicRsp {
+                        result: UicCmdResult::Success,
+                        value,
+                    }) => Ok(value),
+                    Some(UfsUicRsp {
+                        result: UicCmdResult::PowerModeChange,
+                        value: PWR_LOCAL,
+                    }) => Ok(PWR_LOCAL),
+                    Some(UfsUicRsp {
+                        result: UicCmdResult::PowerModeChange,
+                        value,
+                    }) => {
+                        pr_err!(
+                            "[RUFS] ufs_uic: power mode change failed status={}\n",
+                            value
+                        );
+                        Err(EIO)
+                    }
+                    Some(_) => Err(EIO),
+                    None => Err(ENOMEM),
+                }
+            }
+        }
+    }
+
+    pub(crate) fn handle_uic_completion(&self, interrupt_status: u32) -> bool {
+        let mut state = self.state.lock();
+        let expected_completion = state.command.map(|cmd| cmd.expected_completion);
+
+        if expected_completion == Some(UicCompletion::Command)
+            && is_uic_command_completion(interrupt_status)
+        {
+            let rsp = UfsUicRsp {
+                result: self.reg.get_uic_cmd_result().into(),
+                value: self.reg.get_dme_attr_val(),
+            };
+            state.response = Some(rsp);
+            true
+        } else if expected_completion == Some(UicCompletion::PowerMode)
+            && is_uic_power_mode(interrupt_status)
+        {
+            let rsp = UfsUicRsp {
+                result: UicCmdResult::PowerModeChange,
+                value: self.reg.get_power_mode_change_status(),
+            };
+            state.response = Some(rsp);
+            true
+        } else {
+            false
+        }
+    }
+
+    pub(crate) fn complete_uic_cmd(&self) {
+        self.completion.complete();
+    }
+}
+
+impl UfsPaPwrMode {
+    fn uses_termination(self) -> bool {
+        matches!(self, Self::Fast)
+    }
+}
+
+impl UfsPaLayerAttr {
+    fn pwrmode_value(self) -> u32 {
+        ((self.pwr_rx as u32) << PWRMODE_RX_OFFSET) | self.pwr_tx as u32
+    }
+}
+
+const PA_CONNECTEDRXDATALANES: u32 = 0x1581;
+const PA_CONNECTEDTXDATALANES: u32 = 0x1561;
+const PA_MAXRXHSGEAR: u32 = 0x1587;
+const PA_MAXRXPWMGEAR: u32 = 0x1586;
+const PA_RXGEAR: u32 = 0x1583;
+const PA_ACTIVERXDATALANES: u32 = 0x1580;
+const PA_RXTERMINATION: u32 = 0x1584;
+const PA_TXGEAR: u32 = 0x1568;
+const PA_ACTIVETXDATALANES: u32 = 0x1560;
+const PA_TXTERMINATION: u32 = 0x1569;
+const PA_HSSERIES: u32 = 0x156A;
+const PA_PWRMODE: u32 = 0x1571;
+const PA_PWRMODEUSERDATA0: u32 = 0x15B0;
+const PA_PWRMODEUSERDATA1: u32 = 0x15B1;
+const PA_PWRMODEUSERDATA2: u32 = 0x15B2;
+const PA_PWRMODEUSERDATA3: u32 = 0x15B3;
+const PA_PWRMODEUSERDATA4: u32 = 0x15B4;
+const PA_PWRMODEUSERDATA5: u32 = 0x15B5;
+const PA_HS_MODE_B: u32 = 2;
+const PWRMODE_RX_OFFSET: u32 = 4;
+const PWR_LOCAL: u32 = 1;
+
+const DL_FC0_PROTECTION_TIMEOUT_VAL_DEFAULT: u32 = 8191;
+const DL_TC0_REPLAY_TIMEOUT_VAL_DEFAULT: u32 = 65535;
+const DL_AFC0_REQ_TIMEOUT_VAL_DEFAULT: u32 = 32767;
+const DL_FC1_PROTECTION_TIMEOUT_VAL_DEFAULT: u32 = 8191;
+const DL_TC1_REPLAY_TIMEOUT_VAL_DEFAULT: u32 = 65535;
+const DL_AFC1_REQ_TIMEOUT_VAL_DEFAULT: u32 = 32767;
+
+const DME_LOCAL_FC0_PROTECTION_TIMEOUT_VAL: u32 = 0xD041;
+const DME_LOCAL_TC0_REPLAY_TIMEOUT_VAL: u32 = 0xD042;
+const DME_LOCAL_AFC0_REQ_TIMEOUT_VAL: u32 = 0xD043;
+
+const fn uic_arg_mib(attr: u32) -> u32 {
+    uic_arg_mib_sel(attr, 0)
+}
+
+const fn uic_arg_mib_sel(attr: u32, selector: u32) -> u32 {
+    ((attr & 0xFFFF) << 16) | (selector & 0xFFFF)
+}
+
+const fn uic_arg_attr_type(attr_type: u32) -> u32 {
+    (attr_type & 0xFF) << 16
+}
diff --git a/drivers/rufs/variant.rs b/drivers/rufs/variant.rs
new file mode 100644
index 0000000000000..a44f88d9bab62
--- /dev/null
+++ b/drivers/rufs/variant.rs
@@ -0,0 +1,69 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! Host-controller variant operations.
+
+use crate::reg::{McqRegisterLayout, UfsReg};
+use crate::uic::{UfsPaLayerAttr, UfsUic};
+use kernel::prelude::*;
+
+#[derive(Clone, Copy)]
+pub(crate) enum NotifyPhase {
+    Pre,
+    Post,
+}
+
+pub(crate) trait UfsVariantOps: Send + Sync {
+    /// Prepare controller-specific resources before common host initialization.
+    fn initialize(&self, _reg: &UfsReg) -> Result<()> {
+        Ok(())
+    }
+
+    /// Release controller-specific resources after the common host is stopped.
+    fn shutdown(&self, _reg: &UfsReg) {}
+
+    fn mcq_register_layout(&self, reg: &UfsReg) -> Result<McqRegisterLayout> {
+        reg.standard_mcq_register_layout()
+    }
+
+    /// Return whether this variant has provided an accessible MCQ topology.
+    fn mcq_enabled(&self) -> bool {
+        true
+    }
+
+    /// Restrict the number of active MCQ commands for this variant.
+    fn constrain_mcq_active_commands(&self, reported: usize) -> usize {
+        reported
+    }
+
+    /// Reset the attached UFS device before enabling the controller.
+    fn device_reset(&self) -> Result<()> {
+        Ok(())
+    }
+
+    fn hce_enable_notify(&self, _reg: &UfsReg, _phase: NotifyPhase) -> Result<()> {
+        Ok(())
+    }
+
+    fn link_startup_notify(&self, _reg: &UfsReg, _uic: &UfsUic, _phase: NotifyPhase) -> Result<()> {
+        Ok(())
+    }
+
+    /// Return whether link startup negotiated a usable link.
+    fn link_startup_valid(&self, _uic: &UfsUic) -> Result<bool> {
+        Ok(true)
+    }
+
+    fn constrain_power_mode(&self, desired: UfsPaLayerAttr) -> Result<UfsPaLayerAttr> {
+        Ok(desired)
+    }
+
+    fn power_mode_notify(
+        &self,
+        _reg: &UfsReg,
+        _uic: &UfsUic,
+        _mode: UfsPaLayerAttr,
+        _phase: NotifyPhase,
+    ) -> Result<()> {
+        Ok(())
+    }
+}

---
base-commit: 374c47bf1ceefff82c4f82820da486de89ea71fb
change-id: 20260909-rufs-private-877d7154f2b8

Best regards,
-- 
Jaemyung Lee <jaemyung.lee@samsung.com>

