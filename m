From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Date: Wed, 23 Sep 2026 03:09:28 +0200
Subject: [PATCH v3 4/4] gpu: nova-core: Extract PFALCON register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-b4-extract-pfsp-registers-to-falcon-mod-v3-4-cd26aa94c021@nanonej.com>
References: <20260923-b4-extract-pfsp-registers-to-falcon-mod-v3-0-cd26aa94c021@nanonej.com>
In-Reply-To: <20260923-b4-extract-pfsp-registers-to-falcon-mod-v3-0-cd26aa94c021@nanonej.com>
To: Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Alexandre Courbot <acourbot@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>
Cc: linux-kernel@vger.kernel.org, nova-gpu@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, Antonin Malzieu Ridolfi <dev@nanonej.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=23772; i=dev@nanonej.com;
 h=from:subject:message-id; bh=5IQGmfFyBKL63zr9iyUnbJ5k2LazHXZuCUjqMieIZ5M=;
 b=owEBbQKS/ZANAwAKAWaH8SMKFRX9AcsmYgBqsybULdxUQRW7eIQFtqL+iAg3KTSS4tUjxWpmb
 XwlCWw40NaJAjMEAAEKAB0WIQSDtk+wfJEhL1KFIn1mh/EjChUV/QUCarMm1AAKCRBmh/EjChUV
 /TpWD/0aarudkKo9iy3gKWK+QADIpze8EF10nCmwmAXA5BfbEezi8b9EcEbfD3bjJwUfs3ZrLGO
 JqFN6v4KfyG7ZvHYWuNavTpD1I2I4/DKf46NNxz8ez5vrME0/y/6bpAG0JCd6cJ3EkCh0oxZz7H
 jLW/KovfkbjAmxckicJO7YlidH2SU/APbCp392P8tWTY3KHE+RBsadldZfl45T7lwEF0uNdpHlB
 yXwmUKw94TLkdQv6GmUxbWXu7jFooogU3XTpt9ZeT9R2govWtCURxHZ5YLmcBasxsdwz2Cw8pKS
 tOT6J5mSuJwh4jIOuYK0HnNzEcclDPpRSfBsRV2eeCzoErjpV2Mh0mHJUOAvqXKJKtRV/Lty/Hv
 U48MMVDBxuyrw1hVAi/G6ZNZ9sL3bkVhLdn/5lP5VjegdwrDybXQoKj+HOAqXzyzp0btCmSLNmK
 r9EDM9EDnJDlPbyzNaU9Dmip1cCKHWHEn/V8FsFAeREJP39F/8M5XbeTG8xFTteH0q3ZEs/3g3J
 93xmzjaYcjPJfUFX/I0a6qUqHFRkoltve//g7dbmDT1ABaST8IcmboHGuc2SNZcnhX7qJmSZ/0y
 529hhCRzLVtqbI9fPhz/vblzGj1G1vcaRtmCUvRp5k1VuNC0r75UN5qiCz4pfq+/VMz0QIr2wcC
 5JLYemV9OCKg2Hw==
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
the falcon module now exposes a set_fbif_transcfg() helper on
Falcon<Gsp> to access the NV_PFALCON_FBIF_TRANSCFG register.

As the bootloader was the only user of the pfalcon field from outside
the falcon module, the field can now be made private, resolving the
corresponding TODO.

Suggested-by: Alexandre Courbot <acourbot@nvidia.com>
Suggested-by: Danilo Krummrich <dakr@kernel.org>
Signed-off-by: Antonin Malzieu Ridolfi <dev@nanonej.com>
---
 drivers/gpu/nova-core/falcon.rs                    |  13 +-
 drivers/gpu/nova-core/falcon/gsp.rs                |  23 +-
 drivers/gpu/nova-core/falcon/regs.rs               | 250 +++++++++++++++++++--
 drivers/gpu/nova-core/firmware/fwsec/bootloader.rs |  18 +-
 drivers/gpu/nova-core/regs.rs                      | 222 +-----------------
 5 files changed, 263 insertions(+), 263 deletions(-)

diff --git a/drivers/gpu/nova-core/falcon.rs b/drivers/gpu/nova-core/falcon.rs
index 60cbd742bad7..95b5146af5b2 100644
--- a/drivers/gpu/nova-core/falcon.rs
+++ b/drivers/gpu/nova-core/falcon.rs
@@ -44,8 +44,8 @@
 pub(crate) const MEM_BLOCK_ALIGNMENT: usize = 256;
 
 bounded_enum! {
-    /// Revision number of a falcon core, used in the [`crate::regs::NV_PFALCON_FALCON_HWCFG1`]
-    /// register.
+    /// Revision number of a falcon core, used in the
+    /// [`crate::falcon::regs::NV_PFALCON_FALCON_HWCFG1`] register.
     #[derive(Debug, Copy, Clone)]
     pub(crate) enum FalconCoreRev with TryFrom<Bounded<u32, 4>> {
         Rev1 = 1,
@@ -60,7 +60,7 @@ pub(crate) enum FalconCoreRev with TryFrom<Bounded<u32, 4>> {
 
 bounded_enum! {
     /// Revision subversion number of a falcon core, used in the
-    /// [`crate::regs::NV_PFALCON_FALCON_HWCFG1`] register.
+    /// [`crate::falcon::regs::NV_PFALCON_FALCON_HWCFG1`] register.
     #[derive(Debug, Copy, Clone)]
     pub(crate) enum FalconCoreRevSubversion with From<Bounded<u32, 2>> {
         Subversion0 = 0,
@@ -106,8 +106,8 @@ pub(crate) enum FalconModSelAlgo with TryFrom<Bounded<u32, 8>> {
 }
 
 bounded_enum! {
-    /// Valid values for the `size` field of the [`crate::regs::NV_PFALCON_FALCON_DMATRFCMD`]
-    /// register.
+    /// Valid values for the `size` field of the
+    /// [`crate::falcon::regs::NV_PFALCON_FALCON_DMATRFCMD`] register.
     #[derive(Debug, Copy, Clone)]
     pub(crate) enum DmaTrfCmdSize with TryFrom<Bounded<u32, 3>> {
         /// 256 bytes transfer.
@@ -364,8 +364,7 @@ pub(crate) struct Falcon<'a, E: FalconEngine> {
     hal: KBox<dyn FalconHal<E>>,
     dev: &'a device::Device<device::Bound>,
     bar: Bar0<'a>,
-    // TODO: make private
-    pub(crate) pfalcon: Mmio<'a, PFalconRegisters>,
+    pfalcon: Mmio<'a, PFalconRegisters>,
     pfalcon2: Mmio<'a, PFalcon2Registers>,
 }
 
diff --git a/drivers/gpu/nova-core/falcon/gsp.rs b/drivers/gpu/nova-core/falcon/gsp.rs
index 4c96ae325fda..a14795657c9e 100644
--- a/drivers/gpu/nova-core/falcon/gsp.rs
+++ b/drivers/gpu/nova-core/falcon/gsp.rs
@@ -5,6 +5,7 @@
         io_project,
         poll::read_poll_timeout,
         register,
+        register::Array,
         Io,
         Mmio, //
     },
@@ -18,10 +19,12 @@
         NovaRegisters, //
     },
     falcon::{
+        regs,
         Falcon,
-        FalconEngine, //
+        FalconEngine,
+        FalconFbifMemType,
+        FalconFbifTarget, //
     },
-    regs,
 };
 
 /// Type specifying the `Gsp` falcon engine. Cannot be instantiated.
@@ -57,7 +60,7 @@ pub(crate) fn clear_swgen0_intr(&self) {
     /// Checks if GSP reload/resume has completed during the boot process.
     pub(crate) fn check_reload_completed(&self, timeout: Delta) -> Result<bool> {
         read_poll_timeout(
-            || Ok(self.bar.read(regs::NV_PGC6_BSI_SECURE_SCRATCH_14)),
+            || Ok(self.bar.read(crate::regs::NV_PGC6_BSI_SECURE_SCRATCH_14)),
             |val| val.boot_stage_3_handoff(),
             Delta::ZERO,
             timeout,
@@ -83,4 +86,18 @@ pub(crate) fn priv_target_mask_released(&self) -> bool {
 
         hwcfg2 != 0 && (hwcfg2 & LOCKED_MASK) != LOCKED_PATTERN
     }
+
+    /// Configures the FBIF translation registers for the given DMA context.
+    pub(crate) fn set_fbif_transcfg(
+        &self,
+        ctx_dma: usize,
+        target: FalconFbifTarget,
+        mem_type: FalconFbifMemType,
+    ) -> Result {
+        self.pfalcon.update(
+            regs::NV_PFALCON_FBIF_TRANSCFG::try_at(ctx_dma).ok_or(EINVAL)?,
+            |v| v.with_target(target).with_mem_type(mem_type),
+        );
+        Ok(())
+    }
 }
diff --git a/drivers/gpu/nova-core/falcon/regs.rs b/drivers/gpu/nova-core/falcon/regs.rs
index 205baf1b8b23..6668b20b474c 100644
--- a/drivers/gpu/nova-core/falcon/regs.rs
+++ b/drivers/gpu/nova-core/falcon/regs.rs
@@ -1,14 +1,234 @@
 // SPDX-License-Identifier: GPL-2.0
 
-use crate::driver::NovaRegisters;
-use kernel::io::register;
+use kernel::{
+    io::{
+        register,
+        Io,
+        Mmio, //
+    },
+    time, //
+};
 
-use crate::falcon::{
-    FalconModSelAlgo,
-    PFalcon2Registers,
-    PeregrineCoreSelect, //
+use crate::{
+    driver::NovaRegisters,
+    falcon::{
+        DmaTrfCmdSize,
+        FalconCoreRev,
+        FalconCoreRevSubversion,
+        FalconFbifMemType,
+        FalconFbifTarget,
+        FalconMem,
+        FalconModSelAlgo,
+        FalconSecurityModel,
+        PFalcon2Registers,
+        PFalconRegisters,
+        PeregrineCoreSelect, //
+    },
 };
 
+// PFALCON
+
+register! {
+    base: PFalconRegisters;
+
+    pub(super) NV_PFALCON_FALCON_IRQSCLR(u32) @ 0x00000004 {
+        6:6     swgen0 => bool;
+        4:4     halt => bool;
+    }
+
+    pub(super) NV_PFALCON_FALCON_MAILBOX0(u32) @ 0x00000040 {
+        31:0    value => u32;
+    }
+
+    pub(super) NV_PFALCON_FALCON_MAILBOX1(u32) @ 0x00000044 {
+        31:0    value => u32;
+    }
+
+    /// Used to store version information about the firmware running
+    /// on the Falcon processor.
+    pub(super) NV_PFALCON_FALCON_OS(u32) @ 0x00000080 {
+        31:0    value => u32;
+    }
+
+    pub(super) NV_PFALCON_FALCON_RM(u32) @ 0x00000084 {
+        31:0    value => u32;
+    }
+
+    pub(super) NV_PFALCON_FALCON_HWCFG2(u32) @ 0x000000f4 {
+        /// Signal indicating that reset is completed (GA102+).
+        31:31   reset_ready => bool;
+        /// RISC-V branch privilege lockdown bit.
+        13:13   riscv_br_priv_lockdown => bool;
+        /// Set to 0 after memory scrubbing is completed.
+        12:12   mem_scrubbing => bool;
+        10:10   riscv => bool;
+    }
+
+    pub(super) NV_PFALCON_FALCON_CPUCTL(u32) @ 0x00000100 {
+        6:6     alias_en => bool;
+        4:4     halted => bool;
+        1:1     startcpu => bool;
+    }
+
+    pub(super) NV_PFALCON_FALCON_BOOTVEC(u32) @ 0x00000104 {
+        31:0    value => u32;
+    }
+
+    pub(super) NV_PFALCON_FALCON_DMACTL(u32) @ 0x0000010c {
+        7:7     secure_stat => bool;
+        6:3     dmaq_num;
+        2:2     imem_scrubbing => bool;
+        1:1     dmem_scrubbing => bool;
+        0:0     require_ctx => bool;
+    }
+
+    pub(super) NV_PFALCON_FALCON_DMATRFBASE(u32) @ 0x00000110 {
+        31:0    base => u32;
+    }
+
+    pub(super) NV_PFALCON_FALCON_DMATRFMOFFS(u32) @ 0x00000114 {
+        23:0    offs;
+    }
+
+    pub(super) NV_PFALCON_FALCON_DMATRFCMD(u32) @ 0x00000118 {
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
+    pub(super) NV_PFALCON_FALCON_DMATRFFBOFFS(u32) @ 0x0000011c {
+        31:0    offs => u32;
+    }
+
+    pub(super) NV_PFALCON_FALCON_DMATRFBASE1(u32) @ 0x00000128 {
+        8:0     base;
+    }
+
+    pub(super) NV_PFALCON_FALCON_HWCFG1(u32) @ 0x0000012c {
+        /// Core revision subversion.
+        7:6     core_rev_subversion => FalconCoreRevSubversion;
+        /// Security model.
+        5:4     security_model ?=> FalconSecurityModel;
+        /// Core revision.
+        3:0     core_rev ?=> FalconCoreRev;
+    }
+
+    pub(super) NV_PFALCON_FALCON_CPUCTL_ALIAS(u32) @ 0x00000130 {
+        1:1     startcpu => bool;
+    }
+
+    /// IMEM access control register. Up to 4 ports are available for IMEM access.
+    pub(super) NV_PFALCON_FALCON_IMEMC(u32)[4, stride = 16] @ 0x00000180 {
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
+    pub(super) NV_PFALCON_FALCON_IMEMD(u32)[4, stride = 16] @ 0x00000184 {
+        31:0      data;
+    }
+
+    /// IMEM tag register. Used to set the tag for the current IMEM block.
+    pub(super) NV_PFALCON_FALCON_IMEMT(u32)[4, stride = 16] @ 0x00000188 {
+        15:0      tag;
+    }
+
+    /// DMEM access control register. Up to 8 ports are available for DMEM access.
+    pub(super) NV_PFALCON_FALCON_DMEMC(u32)[8, stride = 8] @ 0x000001c0 {
+        /// Auto-increment on write.
+        24:24     aincw => bool;
+        /// DMEM block and word offset.
+        15:0      offs;
+    }
+
+    /// DMEM data register. Reading/writing this register accesses DMEM at the address
+    /// specified by the corresponding DMEMC register.
+    pub(super) NV_PFALCON_FALCON_DMEMD(u32)[8, stride = 8] @ 0x000001c4 {
+        31:0      data;
+    }
+
+    /// Actually known as `NV_PSEC_FALCON_ENGINE` and `NV_PGSP_FALCON_ENGINE` depending on the
+    /// falcon instance.
+    pub(super) NV_PFALCON_FALCON_ENGINE(u32) @ 0x000003c0 {
+        0:0     reset => bool;
+    }
+
+    pub(super) NV_PFALCON_FBIF_TRANSCFG(u32)[8] @ 0x00000600 {
+        2:2     mem_type => FalconFbifMemType;
+        1:0     target ?=> FalconFbifTarget;
+    }
+
+    pub(super) NV_PFALCON_FBIF_CTL(u32) @ 0x00000624 {
+        7:7     allow_phys_no_ctx => bool;
+    }
+
+    // Falcon EMEM PIO registers (used by FSP on Hopper/Blackwell).
+    // These provide the falcon external memory communication interface.
+
+    pub(super) NV_PFALCON_FALCON_EMEMC(u32) @ 0x00000ac0 {
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
+    pub(super) NV_PFALCON_FALCON_EMEMD(u32) @ 0x00000ac4 {
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
+    pub(super) fn reset_engine(pfalcon: Mmio<'_, PFalconRegisters>) {
+        pfalcon.update(NV_PFALCON_FALCON_ENGINE, |r| r.with_reset(true));
+
+        // TIMEOUT: falcon engine should not take more than 10us to reset.
+        time::delay::fsleep(time::Delta::from_micros(10));
+
+        pfalcon.update(NV_PFALCON_FALCON_ENGINE, |r| r.with_reset(false));
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
@@ -82,20 +302,10 @@
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
index a87878fe2aec..db1cb4498acd 100644
--- a/drivers/gpu/nova-core/firmware/fwsec/bootloader.rs
+++ b/drivers/gpu/nova-core/firmware/fwsec/bootloader.rs
@@ -12,10 +12,6 @@
         Device, //
     },
     dma::Coherent,
-    io::{
-        register::Array,
-        Io, //
-    },
     prelude::*,
     ptr::{
         Alignable,
@@ -48,7 +44,6 @@
     },
     gpu::Chipset,
     num::FromSafeCast, //
-    regs,
 };
 
 /// Structure used by the boot-loader to load the rest of the code.
@@ -247,14 +242,11 @@ pub(crate) fn run(&self, dev: &Device<device::Bound>, falcon: &Falcon<'_, Gsp>)
             .inspect_err(|e| dev_err!(dev, "Failed to load FWSEC firmware: {:?}\n", e))?;
 
         // Configure DMA index for the bootloader to fetch the FWSEC firmware from system memory.
-        falcon.pfalcon.update(
-            regs::NV_PFALCON_FBIF_TRANSCFG::try_at(usize::from_safe_cast(self.dmem_desc.ctx_dma))
-                .ok_or(EINVAL)?,
-            |v| {
-                v.with_target(FalconFbifTarget::CoherentSysmem)
-                    .with_mem_type(FalconFbifMemType::Physical)
-            },
-        );
+        falcon.set_fbif_transcfg(
+            usize::from_safe_cast(self.dmem_desc.ctx_dma),
+            FalconFbifTarget::CoherentSysmem,
+            FalconFbifMemType::Physical,
+        )?;
 
         let (mbox0, _) = falcon
             .boot(Some(0), None)
diff --git a/drivers/gpu/nova-core/regs.rs b/drivers/gpu/nova-core/regs.rs
index 13ccfd429e05..34cf62b4c8f8 100644
--- a/drivers/gpu/nova-core/regs.rs
+++ b/drivers/gpu/nova-core/regs.rs
@@ -2,28 +2,13 @@
 // SPDX-FileCopyrightText: Copyright (c) 2025-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 
 use kernel::{
-    io::{
-        register,
-        Io,
-        Mmio, //
-    },
-    sizes::SizeConstants,
-    time, //
+    io::register,
+    sizes::SizeConstants, //
 };
 use pin_init::Zeroable;
 
 use crate::{
     driver::NovaRegisters,
-    falcon::{
-        DmaTrfCmdSize,
-        FalconCoreRev,
-        FalconCoreRevSubversion,
-        FalconFbifMemType,
-        FalconFbifTarget,
-        FalconMem,
-        FalconSecurityModel,
-        PFalconRegisters, //
-    },
     mm::tlb::TlbAckMode, //
 };
 
@@ -116,209 +101,6 @@ pub(crate) fn usable_fb_size(self) -> u64 {
     }
 }
 
-// PFALCON
-
-register! {
-    base: PFalconRegisters;
-
-    pub(crate) NV_PFALCON_FALCON_IRQSCLR(u32) @ 0x00000004 {
-        6:6     swgen0 => bool;
-        4:4     halt => bool;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_MAILBOX0(u32) @ 0x00000040 {
-        31:0    value => u32;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_MAILBOX1(u32) @ 0x00000044 {
-        31:0    value => u32;
-    }
-
-    /// Used to store version information about the firmware running
-    /// on the Falcon processor.
-    pub(crate) NV_PFALCON_FALCON_OS(u32) @ 0x00000080 {
-        31:0    value => u32;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_RM(u32) @ 0x00000084 {
-        31:0    value => u32;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_HWCFG2(u32) @ 0x000000f4 {
-        /// Signal indicating that reset is completed (GA102+).
-        31:31   reset_ready => bool;
-        /// RISC-V branch privilege lockdown bit.
-        13:13   riscv_br_priv_lockdown => bool;
-        /// Set to 0 after memory scrubbing is completed.
-        12:12   mem_scrubbing => bool;
-        10:10   riscv => bool;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_CPUCTL(u32) @ 0x00000100 {
-        6:6     alias_en => bool;
-        4:4     halted => bool;
-        1:1     startcpu => bool;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_BOOTVEC(u32) @ 0x00000104 {
-        31:0    value => u32;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_DMACTL(u32) @ 0x0000010c {
-        7:7     secure_stat => bool;
-        6:3     dmaq_num;
-        2:2     imem_scrubbing => bool;
-        1:1     dmem_scrubbing => bool;
-        0:0     require_ctx => bool;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_DMATRFBASE(u32) @ 0x00000110 {
-        31:0    base => u32;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_DMATRFMOFFS(u32) @ 0x00000114 {
-        23:0    offs;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_DMATRFCMD(u32) @ 0x00000118 {
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
-    pub(crate) NV_PFALCON_FALCON_DMATRFFBOFFS(u32) @ 0x0000011c {
-        31:0    offs => u32;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_DMATRFBASE1(u32) @ 0x00000128 {
-        8:0     base;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_HWCFG1(u32) @ 0x0000012c {
-        /// Core revision subversion.
-        7:6     core_rev_subversion => FalconCoreRevSubversion;
-        /// Security model.
-        5:4     security_model ?=> FalconSecurityModel;
-        /// Core revision.
-        3:0     core_rev ?=> FalconCoreRev;
-    }
-
-    pub(crate) NV_PFALCON_FALCON_CPUCTL_ALIAS(u32) @ 0x00000130 {
-        1:1     startcpu => bool;
-    }
-
-    /// IMEM access control register. Up to 4 ports are available for IMEM access.
-    pub(crate) NV_PFALCON_FALCON_IMEMC(u32)[4, stride = 16] @ 0x00000180 {
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
-    pub(crate) NV_PFALCON_FALCON_IMEMD(u32)[4, stride = 16] @ 0x00000184 {
-        31:0      data;
-    }
-
-    /// IMEM tag register. Used to set the tag for the current IMEM block.
-    pub(crate) NV_PFALCON_FALCON_IMEMT(u32)[4, stride = 16] @ 0x00000188 {
-        15:0      tag;
-    }
-
-    /// DMEM access control register. Up to 8 ports are available for DMEM access.
-    pub(crate) NV_PFALCON_FALCON_DMEMC(u32)[8, stride = 8] @ 0x000001c0 {
-        /// Auto-increment on write.
-        24:24     aincw => bool;
-        /// DMEM block and word offset.
-        15:0      offs;
-    }
-
-    /// DMEM data register. Reading/writing this register accesses DMEM at the address
-    /// specified by the corresponding DMEMC register.
-    pub(crate) NV_PFALCON_FALCON_DMEMD(u32)[8, stride = 8] @ 0x000001c4 {
-        31:0      data;
-    }
-
-    /// Actually known as `NV_PSEC_FALCON_ENGINE` and `NV_PGSP_FALCON_ENGINE` depending on the
-    /// falcon instance.
-    pub(crate) NV_PFALCON_FALCON_ENGINE(u32) @ 0x000003c0 {
-        0:0     reset => bool;
-    }
-
-    pub(crate) NV_PFALCON_FBIF_TRANSCFG(u32)[8] @ 0x00000600 {
-        2:2     mem_type => FalconFbifMemType;
-        1:0     target ?=> FalconFbifTarget;
-    }
-
-    pub(crate) NV_PFALCON_FBIF_CTL(u32) @ 0x00000624 {
-        7:7     allow_phys_no_ctx => bool;
-    }
-
-    // Falcon EMEM PIO registers (used by FSP on Hopper/Blackwell).
-    // These provide the falcon external memory communication interface.
-
-    pub(crate) NV_PFALCON_FALCON_EMEMC(u32) @ 0x00000ac0 {
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
-    pub(crate) NV_PFALCON_FALCON_EMEMD(u32) @ 0x00000ac4 {
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
-    pub(crate) fn reset_engine(pfalcon: Mmio<'_, PFalconRegisters>) {
-        pfalcon.update(NV_PFALCON_FALCON_ENGINE, |r| r.with_reset(true));
-
-        // TIMEOUT: falcon engine should not take more than 10us to reset.
-        time::delay::fsleep(time::Delta::from_micros(10));
-
-        pfalcon.update(NV_PFALCON_FALCON_ENGINE, |r| r.with_reset(false));
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

