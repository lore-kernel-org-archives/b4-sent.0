From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Date: Wed, 26 Aug 2026 01:44:21 +0200
Subject: [PATCH 4/4] gpu: nova-core: Extract PFALCON register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260826-b4-extract-pfsp-registers-to-falcon-mod-v1-4-38351df09084@nanonej.com>
References: <20260826-b4-extract-pfsp-registers-to-falcon-mod-v1-0-38351df09084@nanonej.com>
In-Reply-To: <20260826-b4-extract-pfsp-registers-to-falcon-mod-v1-0-38351df09084@nanonej.com>
To: Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Alexandre Courbot <acourbot@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>
Cc: linux-kernel@vger.kernel.org, nova-gpu@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, Antonin Malzieu Ridolfi <dev@nanonej.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=26998; i=dev@nanonej.com;
 h=from:subject:message-id; bh=KAwbjVZ8XxdO/DV/x6lbA6DABQb7eckHT6VIDZXVjF0=;
 b=owEBbQKS/ZANAwAKAWaH8SMKFRX9AcsmYgBqjij4uEK02k6Do3CcIBFQdbM/zOiL2YEi87ylj
 8pYzuUOuReJAjMEAAEKAB0WIQSDtk+wfJEhL1KFIn1mh/EjChUV/QUCao4o+AAKCRBmh/EjChUV
 /aN4D/4whk3pkIGDH1C5Sbjbu1xJaJdOmhoj7OIny+u6RYNW1e64ESwVJas2lqVFckQROiOL9Zc
 vtfhTUH+Z0WIYymmivEbOCfjNH+aqsYewh4/qUEA234k7kbzeAzZ+wNqg1H+k1mV2lkVhcfrjf4
 dZWDxEsNlrwIq3cDGUaAON1EAPZA6y3/1nHC1GzT66NZ+HGMepjgky81M8UVVXexfvpc2n/fu53
 mPAu/Z/rRpncFFDrBemHYPPvhPA8NNj3WICtezRSdOibLEKqxpaJ/3lXYm81RkkDUr13IRqlx0l
 ltk2whcN6lES+8RyqbIXhb0gw6VaJ8luNCmXbtqvUMC1QKK5ogU+cHgXVoTzXWnUzXY2eoXa4/o
 ZdCSIEw1CUevjbyHiakfJLz2wHxzl7wKrZlVfBLQ72zBd5iY8/2sbNhGug8S8PAt8sOzAszGtBX
 2Yvr8zhkvvxrwO1/hXPrTJNlXDVo0uvknvG7lIbx/eAwC5uGWVG+3HX9tDRfYQdVQdxs7oUCmqx
 KHfthaHAeLSmbo34xNwfGKpUb+a9Fp8llZ+3ktZrJ67uBQGmpu7xj4I+A5rxh8/W/lCK37GoG2r
 WL977A76S67UGoexATcvdgg4d0y8vRvKVaMDl83ChF2Xjbq9baoffArzdC2ScOe+/9bRmmVGoME
 gTk7ba2jLvLRgqQ==
X-Developer-Key: i=dev@nanonej.com; a=openpgp;
 fpr=83B64FB07C91212F5285227D6687F1230A1515FD
X-Endpoint-Received: by B4 Relay for dev@nanonej.com/default with auth_id=825
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move PFALCON register definitions from the root regs.rs file into the
falcon module that own them, in the existing falcon/regs.rs file.

This follows the same pattern established by previous commits for
GSP, PDISP, PFB, PBUS, PMC, PFSP, PRISCV and PFALCON2 registers:
register definitions move to the module that interprets their
service, visibility changes to pub(super).

The firmware module still needs to configure the FBIF DMA index used
by the bootloader to fetch the FWSEC firmware from system memory, so
the falcon module now exposes a `set_fbif_transcfg_regs_at()` helper
to access the `NV_PFALCON_FBIF_TRANSCFG` register.

Suggested-by: Alexandre Courbot <acourbot@nvidia.com>
Suggested-by: Danilo Krummrich <dakr@kernel.org>
Signed-off-by: Antonin Malzieu Ridolfi <dev@nanonej.com>
---
 drivers/gpu/nova-core/falcon.rs                    |  30 ++-
 drivers/gpu/nova-core/falcon/gsp.rs                |  16 +-
 drivers/gpu/nova-core/falcon/regs.rs               | 248 +++++++++++++++++++--
 drivers/gpu/nova-core/firmware/fwsec/bootloader.rs |  22 +-
 drivers/gpu/nova-core/gsp/hal/tu102.rs             |   7 +-
 drivers/gpu/nova-core/regs.rs                      | 225 +------------------
 6 files changed, 263 insertions(+), 285 deletions(-)

diff --git a/drivers/gpu/nova-core/falcon.rs b/drivers/gpu/nova-core/falcon.rs
index 11613a2ccb69..d2ee9876bafb 100644
--- a/drivers/gpu/nova-core/falcon.rs
+++ b/drivers/gpu/nova-core/falcon.rs
@@ -45,8 +45,8 @@
 pub(crate) const MEM_BLOCK_ALIGNMENT: usize = 256;
 
 bounded_enum! {
-    /// Revision number of a falcon core, used in the [`crate::regs::NV_PFALCON_FALCON_HWCFG1`]
-    /// register.
+    /// Revision number of a falcon core, used in the
+    /// [`crate::falcon::regs::NV_PFALCON_FALCON_HWCFG1`] register.
     #[derive(Debug, Copy, Clone)]
     pub(crate) enum FalconCoreRev with TryFrom<Bounded<u32, 4>> {
         Rev1 = 1,
@@ -61,7 +61,7 @@ pub(crate) enum FalconCoreRev with TryFrom<Bounded<u32, 4>> {
 
 bounded_enum! {
     /// Revision subversion number of a falcon core, used in the
-    /// [`crate::regs::NV_PFALCON_FALCON_HWCFG1`] register.
+    /// [`crate::falcon::regs::NV_PFALCON_FALCON_HWCFG1`] register.
     #[derive(Debug, Copy, Clone)]
     pub(crate) enum FalconCoreRevSubversion with From<Bounded<u32, 2>> {
         Subversion0 = 0,
@@ -107,8 +107,8 @@ pub(crate) enum FalconModSelAlgo with TryFrom<Bounded<u32, 8>> {
 }
 
 bounded_enum! {
-    /// Valid values for the `size` field of the [`crate::regs::NV_PFALCON_FALCON_DMATRFCMD`]
-    /// register.
+    /// Valid values for the `size` field of the
+    /// [`crate::falcon::regs::NV_PFALCON_FALCON_DMATRFCMD`] register.
     #[derive(Debug, Copy, Clone)]
     pub(crate) enum DmaTrfCmdSize with TryFrom<Bounded<u32, 3>> {
         /// 256 bytes transfer.
@@ -592,6 +592,20 @@ fn dma_wr(
         Ok(())
     }
 
+    // Configure DMA index for the bootloader to fetch the FWSEC firmware from system memory.
+    pub(crate) fn set_fbif_transcfg_regs_at(&self, ctx_dma: u32) -> Result {
+        self.bar.update(
+            regs::NV_PFALCON_FBIF_TRANSCFG::of::<E>()
+                .try_at(usize::from_safe_cast(ctx_dma))
+                .ok_or(EINVAL)?,
+            |v| {
+                v.with_target(FalconFbifTarget::CoherentSysmem)
+                    .with_mem_type(FalconFbifMemType::Physical)
+            },
+        );
+        Ok(())
+    }
+
     /// Perform a DMA load into `IMEM` and `DMEM` of `fw`, and prepare the falcon to run it.
     fn dma_load<F: FalconFirmware<Target = E> + FalconDmaLoadable>(&self, fw: &F) -> Result {
         // DMA object with firmware content as the source of the DMA engine.
@@ -614,11 +628,7 @@ fn dma_load<F: FalconFirmware<Target = E> + FalconDmaLoadable>(&self, fw: &F) ->
         };
 
         self.dma_reset();
-        self.bar
-            .update(regs::NV_PFALCON_FBIF_TRANSCFG::of::<E>().at(0), |v| {
-                v.with_target(FalconFbifTarget::CoherentSysmem)
-                    .with_mem_type(FalconFbifMemType::Physical)
-            });
+        self.set_fbif_transcfg_regs_at(0)?;
 
         self.dma_wr(&dma_obj, FalconMem::ImemSecure, fw.imem_sec_load_params())?;
         self.dma_wr(&dma_obj, FalconMem::Dmem, fw.dmem_load_params())?;
diff --git a/drivers/gpu/nova-core/falcon/gsp.rs b/drivers/gpu/nova-core/falcon/gsp.rs
index ae32f401aeb0..fec13f5e99f4 100644
--- a/drivers/gpu/nova-core/falcon/gsp.rs
+++ b/drivers/gpu/nova-core/falcon/gsp.rs
@@ -7,20 +7,18 @@
             RegisterBase,
             WithBase, //
         },
-        Io,
+        Io, //
     },
     prelude::*,
     time::Delta, //
 };
 
-use crate::{
-    falcon::{
-        Falcon,
-        FalconEngine,
-        PFalcon2Base,
-        PFalconBase, //
-    },
+use crate::falcon::{
     regs,
+    Falcon,
+    FalconEngine,
+    PFalcon2Base,
+    PFalconBase, //
 };
 
 /// Type specifying the `Gsp` falcon engine. Cannot be instantiated.
@@ -49,7 +47,7 @@ pub(crate) fn clear_swgen0_intr(&self) {
     /// Checks if GSP reload/resume has completed during the boot process.
     pub(crate) fn check_reload_completed(&self, timeout: Delta) -> Result<bool> {
         read_poll_timeout(
-            || Ok(self.bar.read(regs::NV_PGC6_BSI_SECURE_SCRATCH_14)),
+            || Ok(self.bar.read(crate::regs::NV_PGC6_BSI_SECURE_SCRATCH_14)),
             |val| val.boot_stage_3_handoff(),
             Delta::ZERO,
             timeout,
diff --git a/drivers/gpu/nova-core/falcon/regs.rs b/drivers/gpu/nova-core/falcon/regs.rs
index 446a67bdf3dd..8e82d9f439a9 100644
--- a/drivers/gpu/nova-core/falcon/regs.rs
+++ b/drivers/gpu/nova-core/falcon/regs.rs
@@ -1,13 +1,233 @@
 // SPDX-License-Identifier: GPL-2.0
 
-use kernel::io::register;
+use kernel::{
+    io::{
+        register,
+        register::WithBase,
+        Io, //
+    },
+    time, //
+};
 
-use crate::falcon::{
-    FalconModSelAlgo,
-    PFalcon2Base,
-    PeregrineCoreSelect, //
+use crate::{
+    driver::Bar0,
+    falcon::{
+        DmaTrfCmdSize,
+        FalconCoreRev,
+        FalconCoreRevSubversion,
+        FalconEngine,
+        FalconFbifMemType,
+        FalconFbifTarget,
+        FalconMem,
+        FalconModSelAlgo,
+        FalconSecurityModel,
+        PFalcon2Base,
+        PFalconBase,
+        PeregrineCoreSelect, //
+    },
 };
 
+// PFALCON
+
+register! {
+    pub(super) NV_PFALCON_FALCON_IRQSCLR(u32) @ PFalconBase + 0x00000004 {
+        6:6     swgen0 => bool;
+        4:4     halt => bool;
+    }
+
+    pub(super) NV_PFALCON_FALCON_MAILBOX0(u32) @ PFalconBase + 0x00000040 {
+        31:0    value => u32;
+    }
+
+    pub(super) NV_PFALCON_FALCON_MAILBOX1(u32) @ PFalconBase + 0x00000044 {
+        31:0    value => u32;
+    }
+
+    /// Used to store version information about the firmware running
+    /// on the Falcon processor.
+    pub(super) NV_PFALCON_FALCON_OS(u32) @ PFalconBase + 0x00000080 {
+        31:0    value => u32;
+    }
+
+    pub(super) NV_PFALCON_FALCON_RM(u32) @ PFalconBase + 0x00000084 {
+        31:0    value => u32;
+    }
+
+    pub(super) NV_PFALCON_FALCON_HWCFG2(u32) @ PFalconBase + 0x000000f4 {
+        /// Signal indicating that reset is completed (GA102+).
+        31:31   reset_ready => bool;
+        /// RISC-V branch privilege lockdown bit.
+        13:13   riscv_br_priv_lockdown => bool;
+        /// Set to 0 after memory scrubbing is completed.
+        12:12   mem_scrubbing => bool;
+        10:10   riscv => bool;
+    }
+
+    pub(super) NV_PFALCON_FALCON_CPUCTL(u32) @ PFalconBase + 0x00000100 {
+        6:6     alias_en => bool;
+        4:4     halted => bool;
+        1:1     startcpu => bool;
+    }
+
+    pub(super) NV_PFALCON_FALCON_BOOTVEC(u32) @ PFalconBase + 0x00000104 {
+        31:0    value => u32;
+    }
+
+    pub(super) NV_PFALCON_FALCON_DMACTL(u32) @ PFalconBase + 0x0000010c {
+        7:7     secure_stat => bool;
+        6:3     dmaq_num;
+        2:2     imem_scrubbing => bool;
+        1:1     dmem_scrubbing => bool;
+        0:0     require_ctx => bool;
+    }
+
+    pub(super) NV_PFALCON_FALCON_DMATRFBASE(u32) @ PFalconBase + 0x00000110 {
+        31:0    base => u32;
+    }
+
+    pub(super) NV_PFALCON_FALCON_DMATRFMOFFS(u32) @ PFalconBase + 0x00000114 {
+        23:0    offs;
+    }
+
+    pub(super) NV_PFALCON_FALCON_DMATRFCMD(u32) @ PFalconBase + 0x00000118 {
+        16:16   set_dmtag;
+        14:12   ctxdma;
+        10:8    size ?=> DmaTrfCmdSize;
+        5:5     is_write => bool;
+        4:4     imem => bool;
+        3:2     sec;
+        1:1     idle => bool;
+        0:0     full => bool;
+    }
+
+    pub(super) NV_PFALCON_FALCON_DMATRFFBOFFS(u32) @ PFalconBase + 0x0000011c {
+        31:0    offs => u32;
+    }
+
+    pub(super) NV_PFALCON_FALCON_DMATRFBASE1(u32) @ PFalconBase + 0x00000128 {
+        8:0     base;
+    }
+
+    pub(super) NV_PFALCON_FALCON_HWCFG1(u32) @ PFalconBase + 0x0000012c {
+        /// Core revision subversion.
+        7:6     core_rev_subversion => FalconCoreRevSubversion;
+        /// Security model.
+        5:4     security_model ?=> FalconSecurityModel;
+        /// Core revision.
+        3:0     core_rev ?=> FalconCoreRev;
+    }
+
+    pub(super) NV_PFALCON_FALCON_CPUCTL_ALIAS(u32) @ PFalconBase + 0x00000130 {
+        1:1     startcpu => bool;
+    }
+
+    /// IMEM access control register. Up to 4 ports are available for IMEM access.
+    pub(super) NV_PFALCON_FALCON_IMEMC(u32)[4, stride = 16] @ PFalconBase + 0x00000180 {
+        /// Access secure IMEM.
+        28:28     secure => bool;
+        /// Auto-increment on write.
+        24:24     aincw => bool;
+        /// IMEM block and word offset.
+        15:0      offs;
+    }
+
+    /// IMEM data register. Reading/writing this register accesses IMEM at the address
+    /// specified by the corresponding IMEMC register.
+    pub(super) NV_PFALCON_FALCON_IMEMD(u32)[4, stride = 16] @ PFalconBase + 0x00000184 {
+        31:0      data;
+    }
+
+    /// IMEM tag register. Used to set the tag for the current IMEM block.
+    pub(super) NV_PFALCON_FALCON_IMEMT(u32)[4, stride = 16] @ PFalconBase + 0x00000188 {
+        15:0      tag;
+    }
+
+    /// DMEM access control register. Up to 8 ports are available for DMEM access.
+    pub(super) NV_PFALCON_FALCON_DMEMC(u32)[8, stride = 8] @ PFalconBase + 0x000001c0 {
+        /// Auto-increment on write.
+        24:24     aincw => bool;
+        /// DMEM block and word offset.
+        15:0      offs;
+    }
+
+    /// DMEM data register. Reading/writing this register accesses DMEM at the address
+    /// specified by the corresponding DMEMC register.
+    pub(super) NV_PFALCON_FALCON_DMEMD(u32)[8, stride = 8] @ PFalconBase + 0x000001c4 {
+        31:0      data;
+    }
+
+    /// Actually known as `NV_PSEC_FALCON_ENGINE` and `NV_PGSP_FALCON_ENGINE` depending on the
+    /// falcon instance.
+    pub(super) NV_PFALCON_FALCON_ENGINE(u32) @ PFalconBase + 0x000003c0 {
+        0:0     reset => bool;
+    }
+
+    pub(super) NV_PFALCON_FBIF_TRANSCFG(u32)[8] @ PFalconBase + 0x00000600 {
+        2:2     mem_type => FalconFbifMemType;
+        1:0     target ?=> FalconFbifTarget;
+    }
+
+    pub(super) NV_PFALCON_FBIF_CTL(u32) @ PFalconBase + 0x00000624 {
+        7:7     allow_phys_no_ctx => bool;
+    }
+
+    // Falcon EMEM PIO registers (used by FSP on Hopper/Blackwell).
+    // These provide the falcon external memory communication interface.
+
+    pub(super) NV_PFALCON_FALCON_EMEMC(u32) @ PFalconBase + 0x00000ac0 {
+        /// EMEM byte offset (4-byte aligned) within the block.
+        7:2     offs;
+        /// EMEM block to access.
+        15:8    blk;
+        /// Auto-increment the offset after each write.
+        24:24   aincw => bool;
+        /// Auto-increment the offset after each read.
+        25:25   aincr => bool;
+    }
+
+    pub(super) NV_PFALCON_FALCON_EMEMD(u32) @ PFalconBase + 0x00000ac4 {
+        31:0    data => u32;
+    }
+}
+
+impl NV_PFALCON_FALCON_DMACTL {
+    /// Returns `true` if memory scrubbing is completed.
+    pub(super) fn mem_scrubbing_done(self) -> bool {
+        !self.dmem_scrubbing() && !self.imem_scrubbing()
+    }
+}
+
+impl NV_PFALCON_FALCON_DMATRFCMD {
+    /// Programs the `imem` and `sec` fields for the given FalconMem
+    pub(super) fn with_falcon_mem(self, mem: FalconMem) -> Self {
+        let this = self.with_imem(mem != FalconMem::Dmem);
+
+        match mem {
+            FalconMem::ImemSecure => this.with_const_sec::<1>(),
+            _ => this.with_const_sec::<0>(),
+        }
+    }
+}
+
+impl NV_PFALCON_FALCON_ENGINE {
+    /// Resets the falcon
+    pub(super) fn reset_engine<E: FalconEngine>(bar: Bar0<'_>) {
+        bar.update(Self::of::<E>(), |r| r.with_reset(true));
+
+        // TIMEOUT: falcon engine should not take more than 10us to reset.
+        time::delay::fsleep(time::Delta::from_micros(10));
+
+        bar.update(Self::of::<E>(), |r| r.with_reset(false));
+    }
+}
+
+impl NV_PFALCON_FALCON_HWCFG2 {
+    /// Returns `true` if memory scrubbing is completed.
+    pub(super) fn mem_scrubbing_done(self) -> bool {
+        !self.mem_scrubbing()
+    }
+}
+
 // PFALCON2
 
 register! {
@@ -75,20 +295,10 @@
     }
 }
 
-// PFALCON and FUSE registers are defined in the root `regs.rs` but are
-// part of the falcon interface, accessed by the whole falcon module. They
-// are re-exported here so falcon code can use a single `regs::` prefix.
-// Once these families move out of the root module, these re-exports become
-// plain definitions.
+// FUSE registers are defined in the root `regs.rs` but are part of the
+// falcon interface, accessed by the whole falcon module. They are
+// re-exported here so falcon code can use a single `regs::` prefix.
 pub(super) use crate::regs::{
     NV_FUSE_OPT_FPF_GSP_UCODE1_VERSION, NV_FUSE_OPT_FPF_NVDEC_UCODE1_VERSION,
-    NV_FUSE_OPT_FPF_SEC2_UCODE1_VERSION, NV_FUSE_OPT_FPF_SIZE, NV_PFALCON_FALCON_BOOTVEC,
-    NV_PFALCON_FALCON_CPUCTL, NV_PFALCON_FALCON_CPUCTL_ALIAS, NV_PFALCON_FALCON_DMACTL,
-    NV_PFALCON_FALCON_DMATRFBASE, NV_PFALCON_FALCON_DMATRFBASE1, NV_PFALCON_FALCON_DMATRFCMD,
-    NV_PFALCON_FALCON_DMATRFFBOFFS, NV_PFALCON_FALCON_DMATRFMOFFS, NV_PFALCON_FALCON_DMEMC,
-    NV_PFALCON_FALCON_DMEMD, NV_PFALCON_FALCON_EMEMC, NV_PFALCON_FALCON_EMEMD,
-    NV_PFALCON_FALCON_ENGINE, NV_PFALCON_FALCON_HWCFG2, NV_PFALCON_FALCON_IMEMC,
-    NV_PFALCON_FALCON_IMEMD, NV_PFALCON_FALCON_IMEMT, NV_PFALCON_FALCON_MAILBOX0,
-    NV_PFALCON_FALCON_MAILBOX1, NV_PFALCON_FALCON_OS, NV_PFALCON_FALCON_RM, NV_PFALCON_FBIF_CTL,
-    NV_PFALCON_FBIF_TRANSCFG,
+    NV_FUSE_OPT_FPF_SEC2_UCODE1_VERSION, NV_FUSE_OPT_FPF_SIZE,
 };
diff --git a/drivers/gpu/nova-core/firmware/fwsec/bootloader.rs b/drivers/gpu/nova-core/firmware/fwsec/bootloader.rs
index ec4d92317a93..6777e041c879 100644
--- a/drivers/gpu/nova-core/firmware/fwsec/bootloader.rs
+++ b/drivers/gpu/nova-core/firmware/fwsec/bootloader.rs
@@ -12,7 +12,6 @@
         Device, //
     },
     dma::Coherent,
-    io::{register::WithBase, Io},
     prelude::*,
     ptr::{
         Alignable,
@@ -23,15 +22,12 @@
 };
 
 use crate::{
-    driver::Bar0,
     falcon::{
         self,
         gsp::Gsp,
         Falcon,
         FalconBromParams,
         FalconDmaLoadable,
-        FalconFbifMemType,
-        FalconFbifTarget,
         FalconFirmware,
         FalconPioDmemLoadTarget,
         FalconPioImemLoadTarget,
@@ -46,7 +42,6 @@
     },
     gpu::Chipset,
     num::FromSafeCast, //
-    regs,
 };
 
 /// Structure used by the boot-loader to load the rest of the code.
@@ -235,12 +230,7 @@ pub(crate) fn new(
     ///
     /// The bootloader will load the FWSEC firmware and then execute it. This function returns
     /// after FWSEC has reached completion.
-    pub(crate) fn run(
-        &self,
-        dev: &Device<device::Bound>,
-        falcon: &Falcon<'_, Gsp>,
-        bar: Bar0<'_>,
-    ) -> Result<()> {
+    pub(crate) fn run(&self, dev: &Device<device::Bound>, falcon: &Falcon<'_, Gsp>) -> Result<()> {
         // Reset falcon, load the firmware, and run it.
         falcon
             .reset()
@@ -250,15 +240,7 @@ pub(crate) fn run(
             .inspect_err(|e| dev_err!(dev, "Failed to load FWSEC firmware: {:?}\n", e))?;
 
         // Configure DMA index for the bootloader to fetch the FWSEC firmware from system memory.
-        bar.update(
-            regs::NV_PFALCON_FBIF_TRANSCFG::of::<Gsp>()
-                .try_at(usize::from_safe_cast(self.dmem_desc.ctx_dma))
-                .ok_or(EINVAL)?,
-            |v| {
-                v.with_target(FalconFbifTarget::CoherentSysmem)
-                    .with_mem_type(FalconFbifMemType::Physical)
-            },
-        );
+        falcon.set_fbif_transcfg_regs_at(self.dmem_desc.ctx_dma)?;
 
         let (mbox0, _) = falcon
             .boot(Some(0), None)
diff --git a/drivers/gpu/nova-core/gsp/hal/tu102.rs b/drivers/gpu/nova-core/gsp/hal/tu102.rs
index a5c0ca355493..d2ef35080689 100644
--- a/drivers/gpu/nova-core/gsp/hal/tu102.rs
+++ b/drivers/gpu/nova-core/gsp/hal/tu102.rs
@@ -62,12 +62,11 @@ impl FwsecUnloadFirmware {
     fn run(
         &self,
         dev: &device::Device<device::Bound>,
-        bar: Bar0<'_>,
         gsp_falcon: &Falcon<'_, GspEngine>,
     ) -> Result {
         match self {
             Self::WithoutBl(fw) => fw.run(dev, gsp_falcon),
-            Self::WithBl(fw) => fw.run(dev, gsp_falcon, bar),
+            Self::WithBl(fw) => fw.run(dev, gsp_falcon),
         }
     }
 }
@@ -88,7 +87,7 @@ fn run(&self, ctx: &mut GspBootContext<'_, '_>) -> Result {
         // Log errors but keep going if it fails.
         let fwsec_sb_res = self
             .fwsec_sb
-            .run(dev, bar, ctx.gsp_falcon)
+            .run(dev, ctx.gsp_falcon)
             .inspect_err(|e| dev_err!(dev, "FWSEC-SB failed to run: {:?}\n", e));
 
         // Remove WPR2 region if set.
@@ -168,7 +167,7 @@ fn run_fwsec_frts(
         if self.needs_fwsec_bootloader {
             let fwsec_frts_bl = FwsecFirmwareWithBl::new(fwsec_frts, dev, chipset)?;
             // Load and run the bootloader, which will load FWSEC-FRTS and run it.
-            fwsec_frts_bl.run(dev, falcon, bar)?;
+            fwsec_frts_bl.run(dev, falcon)?;
         } else {
             // Load and run FWSEC-FRTS directly.
             fwsec_frts.run(dev, falcon)?;
diff --git a/drivers/gpu/nova-core/regs.rs b/drivers/gpu/nova-core/regs.rs
index c9eca3ff911f..842664428b0d 100644
--- a/drivers/gpu/nova-core/regs.rs
+++ b/drivers/gpu/nova-core/regs.rs
@@ -2,28 +2,8 @@
 // SPDX-FileCopyrightText: Copyright (c) 2025-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 
 use kernel::{
-    io::{
-        register,
-        register::WithBase,
-        Io, //
-    },
-    sizes::SizeConstants,
-    time, //
-};
-
-use crate::{
-    driver::Bar0,
-    falcon::{
-        DmaTrfCmdSize,
-        FalconCoreRev,
-        FalconCoreRevSubversion,
-        FalconEngine,
-        FalconFbifMemType,
-        FalconFbifTarget,
-        FalconMem,
-        FalconSecurityModel,
-        PFalconBase, //
-    },
+    io::register,
+    sizes::SizeConstants, //
 };
 
 // PBUS
@@ -109,207 +89,6 @@ pub(crate) fn usable_fb_size(self) -> u64 {
     }
 }
 
-// PFALCON
-
-register! {
-    pub(crate) NV_PFALCON_FALCON_IRQSCLR(u32) @ PFalconBase + 0x00000004 {
-        6:6     swgen0 => bool;
-        4:4     halt => bool;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_MAILBOX0(u32) @ PFalconBase + 0x00000040 {
-        31:0    value => u32;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_MAILBOX1(u32) @ PFalconBase + 0x00000044 {
-        31:0    value => u32;
-    }
-
-    /// Used to store version information about the firmware running
-    /// on the Falcon processor.
-    pub(crate) NV_PFALCON_FALCON_OS(u32) @ PFalconBase + 0x00000080 {
-        31:0    value => u32;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_RM(u32) @ PFalconBase + 0x00000084 {
-        31:0    value => u32;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_HWCFG2(u32) @ PFalconBase + 0x000000f4 {
-        /// Signal indicating that reset is completed (GA102+).
-        31:31   reset_ready => bool;
-        /// RISC-V branch privilege lockdown bit.
-        13:13   riscv_br_priv_lockdown => bool;
-        /// Set to 0 after memory scrubbing is completed.
-        12:12   mem_scrubbing => bool;
-        10:10   riscv => bool;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_CPUCTL(u32) @ PFalconBase + 0x00000100 {
-        6:6     alias_en => bool;
-        4:4     halted => bool;
-        1:1     startcpu => bool;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_BOOTVEC(u32) @ PFalconBase + 0x00000104 {
-        31:0    value => u32;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_DMACTL(u32) @ PFalconBase + 0x0000010c {
-        7:7     secure_stat => bool;
-        6:3     dmaq_num;
-        2:2     imem_scrubbing => bool;
-        1:1     dmem_scrubbing => bool;
-        0:0     require_ctx => bool;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_DMATRFBASE(u32) @ PFalconBase + 0x00000110 {
-        31:0    base => u32;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_DMATRFMOFFS(u32) @ PFalconBase + 0x00000114 {
-        23:0    offs;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_DMATRFCMD(u32) @ PFalconBase + 0x00000118 {
-        16:16   set_dmtag;
-        14:12   ctxdma;
-        10:8    size ?=> DmaTrfCmdSize;
-        5:5     is_write => bool;
-        4:4     imem => bool;
-        3:2     sec;
-        1:1     idle => bool;
-        0:0     full => bool;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_DMATRFFBOFFS(u32) @ PFalconBase + 0x0000011c {
-        31:0    offs => u32;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_DMATRFBASE1(u32) @ PFalconBase + 0x00000128 {
-        8:0     base;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_HWCFG1(u32) @ PFalconBase + 0x0000012c {
-        /// Core revision subversion.
-        7:6     core_rev_subversion => FalconCoreRevSubversion;
-        /// Security model.
-        5:4     security_model ?=> FalconSecurityModel;
-        /// Core revision.
-        3:0     core_rev ?=> FalconCoreRev;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_CPUCTL_ALIAS(u32) @ PFalconBase + 0x00000130 {
-        1:1     startcpu => bool;
-    }
-
-    /// IMEM access control register. Up to 4 ports are available for IMEM access.
-    pub(crate) NV_PFALCON_FALCON_IMEMC(u32)[4, stride = 16] @ PFalconBase + 0x00000180 {
-        /// Access secure IMEM.
-        28:28     secure => bool;
-        /// Auto-increment on write.
-        24:24     aincw => bool;
-        /// IMEM block and word offset.
-        15:0      offs;
-    }
-
-    /// IMEM data register. Reading/writing this register accesses IMEM at the address
-    /// specified by the corresponding IMEMC register.
-    pub(crate) NV_PFALCON_FALCON_IMEMD(u32)[4, stride = 16] @ PFalconBase + 0x00000184 {
-        31:0      data;
-    }
-
-    /// IMEM tag register. Used to set the tag for the current IMEM block.
-    pub(crate) NV_PFALCON_FALCON_IMEMT(u32)[4, stride = 16] @ PFalconBase + 0x00000188 {
-        15:0      tag;
-    }
-
-    /// DMEM access control register. Up to 8 ports are available for DMEM access.
-    pub(crate) NV_PFALCON_FALCON_DMEMC(u32)[8, stride = 8] @ PFalconBase + 0x000001c0 {
-        /// Auto-increment on write.
-        24:24     aincw => bool;
-        /// DMEM block and word offset.
-        15:0      offs;
-    }
-
-    /// DMEM data register. Reading/writing this register accesses DMEM at the address
-    /// specified by the corresponding DMEMC register.
-    pub(crate) NV_PFALCON_FALCON_DMEMD(u32)[8, stride = 8] @ PFalconBase + 0x000001c4 {
-        31:0      data;
-    }
-
-    /// Actually known as `NV_PSEC_FALCON_ENGINE` and `NV_PGSP_FALCON_ENGINE` depending on the
-    /// falcon instance.
-    pub(crate) NV_PFALCON_FALCON_ENGINE(u32) @ PFalconBase + 0x000003c0 {
-        0:0     reset => bool;
-    }
-
-    pub(crate) NV_PFALCON_FBIF_TRANSCFG(u32)[8] @ PFalconBase + 0x00000600 {
-        2:2     mem_type => FalconFbifMemType;
-        1:0     target ?=> FalconFbifTarget;
-    }
-
-    pub(crate) NV_PFALCON_FBIF_CTL(u32) @ PFalconBase + 0x00000624 {
-        7:7     allow_phys_no_ctx => bool;
-    }
-
-    // Falcon EMEM PIO registers (used by FSP on Hopper/Blackwell).
-    // These provide the falcon external memory communication interface.
-
-    pub(crate) NV_PFALCON_FALCON_EMEMC(u32) @ PFalconBase + 0x00000ac0 {
-        /// EMEM byte offset (4-byte aligned) within the block.
-        7:2     offs;
-        /// EMEM block to access.
-        15:8    blk;
-        /// Auto-increment the offset after each write.
-        24:24   aincw => bool;
-        /// Auto-increment the offset after each read.
-        25:25   aincr => bool;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_EMEMD(u32) @ PFalconBase + 0x00000ac4 {
-        31:0    data => u32;
-    }
-}
-
-impl NV_PFALCON_FALCON_DMACTL {
-    /// Returns `true` if memory scrubbing is completed.
-    pub(crate) fn mem_scrubbing_done(self) -> bool {
-        !self.dmem_scrubbing() && !self.imem_scrubbing()
-    }
-}
-
-impl NV_PFALCON_FALCON_DMATRFCMD {
-    /// Programs the `imem` and `sec` fields for the given FalconMem
-    pub(crate) fn with_falcon_mem(self, mem: FalconMem) -> Self {
-        let this = self.with_imem(mem != FalconMem::Dmem);
-
-        match mem {
-            FalconMem::ImemSecure => this.with_const_sec::<1>(),
-            _ => this.with_const_sec::<0>(),
-        }
-    }
-}
-
-impl NV_PFALCON_FALCON_ENGINE {
-    /// Resets the falcon
-    pub(crate) fn reset_engine<E: FalconEngine>(bar: Bar0<'_>) {
-        bar.update(Self::of::<E>(), |r| r.with_reset(true));
-
-        // TIMEOUT: falcon engine should not take more than 10us to reset.
-        time::delay::fsleep(time::Delta::from_micros(10));
-
-        bar.update(Self::of::<E>(), |r| r.with_reset(false));
-    }
-}
-
-impl NV_PFALCON_FALCON_HWCFG2 {
-    /// Returns `true` if memory scrubbing is completed.
-    pub(crate) fn mem_scrubbing_done(self) -> bool {
-        !self.mem_scrubbing()
-    }
-}
-
 // The modules below provide registers that are not identical on all supported chips. They should
 // only be used in HAL modules.
 

-- 
2.55.0

