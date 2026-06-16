From: Antonin Malzieu Ridolfi <dev@nanonej.com>
Date: Wed, 17 Jun 2026 01:48:14 +0200
Subject: [PATCH 3/5] gpu: nova-core: falcon: Move PFALCON2 register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260617-nova-core-regs-split-v1-3-4c7dc4450ea7@nanonej.com>
References: <20260617-nova-core-regs-split-v1-0-4c7dc4450ea7@nanonej.com>
In-Reply-To: <20260617-nova-core-regs-split-v1-0-4c7dc4450ea7@nanonej.com>
To: Danilo Krummrich <dakr@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, Alice Ryhl <aliceryhl@google.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Antonin Malzieu Ridolfi <dev@nanonej.com>
Cc: linux-kernel@vger.kernel.org, nova-gpu@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, daniel.almeida@collabora.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=19872; i=dev@nanonej.com;
 h=from:subject:message-id; bh=zJBjys72iI7wogcUqMF8TWK5sVZhXPoqsEG2dXks6LM=;
 b=owEBbQKS/ZANAwAKAWaH8SMKFRX9AcsmYgBqMeDJvFzHO1JWtu5nU9HzHvUOm9w/OIkv4cqap
 ZQwFVUPvN+JAjMEAAEKAB0WIQSDtk+wfJEhL1KFIn1mh/EjChUV/QUCajHgyQAKCRBmh/EjChUV
 /b+JD/9KdCv05KaikQ5LctSj3Sh7iIInfGpInTZmoVpeYz7+JXJIfp+uOhwt5moUBOXev5UljVn
 8Xk02nr9lxyqjbCISAjoj6blrhTpUXzR6enFd6MWdVTXMjYtodh3IY75yRB7I8EhzeDSimSzz29
 Wg6y0N269dd2nX63Bx2Ub1LbiqRTU8HfvLhnODd/DouAJOdbv5h+gT2rPeWAU357LjsZexyZ6QF
 FfIGQs8hrVTtOVS7npMgcS0xDZfnE8Vr92yJzcN7lN2kqCYyRuH2BJX4wv8L6E9azKgDM1k0C5/
 6+BEJBnGZBfHkMn+d77JlHK4tG2kwfU2Ic4qrnnFoufR3IVo4IMRfzJxO3HIbHzgGMf/7TRwDid
 akjp+HhD62eGPtkidqfKZ80mYT15/9J7TnMz1X/pA3U0MATdI1rp0AgSrO8DBnJO+j/X7C0WLtN
 cyNFm+DMO8j59g3OJhqIkLQRT4ypTsHDeTg080TjFmI3V75CrJuO5PkyncAxmA0H3QqWKV9zLYg
 DXTrmUC4OhtWKnlKSVFrrxWVRGJG9CUtIzpUtruhUT1BrGInk3//MJ3z5ZjPssCD11U23MZBbmV
 AH00QPZPh9JHBk6VPjSI1Vk7PY9xRcUGYcWYGlpPGHlk9cEXbMX1nihi5jtYJNOVzYS4fElTNGP
 E8mm+97A020J15A==
X-Developer-Key: i=dev@nanonej.com; a=openpgp;
 fpr=83B64FB07C91212F5285227D6687F1230A1515FD
X-Endpoint-Received: by B4 Relay for dev@nanonej.com/default with auth_id=825
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move PFALCON2 register definition into falcon module and update registers
visibility.

Signed-off-by: Antonin Malzieu Ridolfi <dev@nanonej.com>
---
 drivers/gpu/nova-core/falcon.rs           | 71 ++++++++++++++++++-------------
 drivers/gpu/nova-core/falcon/hal/ga102.rs | 38 +++++++++--------
 drivers/gpu/nova-core/falcon/regs.rs      | 30 +++++++++++++
 drivers/gpu/nova-core/regs.rs             | 23 ----------
 4 files changed, 92 insertions(+), 70 deletions(-)

diff --git a/drivers/gpu/nova-core/falcon.rs b/drivers/gpu/nova-core/falcon.rs
index 94c7696a6493..c2215ddd9e80 100644
--- a/drivers/gpu/nova-core/falcon.rs
+++ b/drivers/gpu/nova-core/falcon.rs
@@ -37,12 +37,12 @@
         self,
         FromSafeCast, //
     },
-    regs,
 };
 
 pub(crate) mod fsp;
 pub(crate) mod gsp;
 mod hal;
+mod regs;
 pub(crate) mod sec2;
 
 /// Alignment (in bytes) of falcon memory blocks.
@@ -99,7 +99,7 @@ pub(crate) enum FalconSecurityModel with TryFrom<Bounded<u32, 2>> {
 
 bounded_enum! {
     /// Signing algorithm for a given firmware, used in the
-    /// [`crate::regs::NV_PFALCON2_FALCON_MOD_SEL`] register. It is passed to the Falcon Boot ROM
+    /// [`super::regs::NV_PFALCON2_FALCON_MOD_SEL`] register. It is passed to the Falcon Boot ROM
     /// (BROM) as a parameter.
     #[derive(Debug, Copy, Clone)]
     pub(crate) enum FalconModSelAlgo with TryFrom<Bounded<u32, 8>> {
@@ -374,13 +374,13 @@ pub(crate) fn new(dev: &device::Device, chipset: Chipset) -> Result<Self> {
 
     /// Resets DMA-related registers.
     pub(crate) fn dma_reset(&self, bar: Bar0<'_>) {
-        bar.update(regs::NV_PFALCON_FBIF_CTL::of::<E>(), |v| {
+        bar.update(crate::regs::NV_PFALCON_FBIF_CTL::of::<E>(), |v| {
             v.with_allow_phys_no_ctx(true)
         });
 
         bar.write(
             WithBase::of::<E>(),
-            regs::NV_PFALCON_FALCON_DMACTL::zeroed(),
+            crate::regs::NV_PFALCON_FALCON_DMACTL::zeroed(),
         );
     }
 
@@ -392,7 +392,8 @@ pub(crate) fn reset(&self, bar: Bar0<'_>) -> Result {
 
         bar.write(
             WithBase::of::<E>(),
-            regs::NV_PFALCON_FALCON_RM::from(bar.read(regs::NV_PMC_BOOT_0).into_raw()),
+            crate::regs::NV_PFALCON_FALCON_RM::
+                from(bar.read(crate::regs::NV_PMC_BOOT_0).into_raw()),
         );
 
         Ok(())
@@ -417,7 +418,7 @@ fn pio_wr_imem_slice(
 
         bar.write(
             WithBase::of::<E>().at(Self::PIO_PORT),
-            regs::NV_PFALCON_FALCON_IMEMC::zeroed()
+            crate::regs::NV_PFALCON_FALCON_IMEMC::zeroed()
                 .with_secure(load_offsets.secure)
                 .with_aincw(true)
                 .with_offs(load_offsets.dst_start),
@@ -428,13 +429,14 @@ fn pio_wr_imem_slice(
             let tag: u16 = load_offsets.start_tag.checked_add(n).ok_or(ERANGE)?;
             bar.write(
                 WithBase::of::<E>().at(Self::PIO_PORT),
-                regs::NV_PFALCON_FALCON_IMEMT::zeroed().with_tag(tag),
+                crate::regs::NV_PFALCON_FALCON_IMEMT::zeroed().with_tag(tag),
             );
             for word in block.chunks_exact(4) {
                 let w = [word[0], word[1], word[2], word[3]];
                 bar.write(
                     WithBase::of::<E>().at(Self::PIO_PORT),
-                    regs::NV_PFALCON_FALCON_IMEMD::zeroed().with_data(u32::from_le_bytes(w)),
+                    crate::regs::NV_PFALCON_FALCON_IMEMD::zeroed()
+                        .with_data(u32::from_le_bytes(w)),
                 );
             }
         }
@@ -458,7 +460,7 @@ fn pio_wr_dmem_slice(
 
         bar.write(
             WithBase::of::<E>().at(Self::PIO_PORT),
-            regs::NV_PFALCON_FALCON_DMEMC::zeroed()
+            crate::regs::NV_PFALCON_FALCON_DMEMC::zeroed()
                 .with_aincw(true)
                 .with_offs(load_offsets.dst_start),
         );
@@ -467,7 +469,8 @@ fn pio_wr_dmem_slice(
             let w = [word[0], word[1], word[2], word[3]];
             bar.write(
                 WithBase::of::<E>().at(Self::PIO_PORT),
-                regs::NV_PFALCON_FALCON_DMEMD::zeroed().with_data(u32::from_le_bytes(w)),
+                crate::regs::NV_PFALCON_FALCON_DMEMD::zeroed()
+                    .with_data(u32::from_le_bytes(w)),
             );
         }
 
@@ -480,13 +483,13 @@ pub(crate) fn pio_load<F: FalconFirmware<Target = E> + FalconPioLoadable>(
         bar: Bar0<'_>,
         fw: &F,
     ) -> Result {
-        bar.update(regs::NV_PFALCON_FBIF_CTL::of::<E>(), |v| {
+        bar.update(crate::regs::NV_PFALCON_FBIF_CTL::of::<E>(), |v| {
             v.with_allow_phys_no_ctx(true)
         });
 
         bar.write(
             WithBase::of::<E>(),
-            regs::NV_PFALCON_FALCON_DMACTL::zeroed(),
+            crate::regs::NV_PFALCON_FALCON_DMACTL::zeroed(),
         );
 
         if let Some(imem_ns) = fw.imem_ns_load_params() {
@@ -501,7 +504,8 @@ pub(crate) fn pio_load<F: FalconFirmware<Target = E> + FalconPioLoadable>(
 
         bar.write(
             WithBase::of::<E>(),
-            regs::NV_PFALCON_FALCON_BOOTVEC::zeroed().with_value(fw.boot_addr()),
+            crate::regs::NV_PFALCON_FALCON_BOOTVEC::zeroed()
+                .with_value(fw.boot_addr()),
         );
 
         Ok(())
@@ -573,7 +577,7 @@ fn dma_wr(
 
         bar.write(
             WithBase::of::<E>(),
-            regs::NV_PFALCON_FALCON_DMATRFBASE::zeroed().with_base(
+            crate::regs::NV_PFALCON_FALCON_DMATRFBASE::zeroed().with_base(
                 // CAST: `as u32` is used on purpose since we do want to strip the upper bits,
                 // which will be written to `NV_PFALCON_FALCON_DMATRFBASE1`.
                 (dma_start >> 8) as u32,
@@ -581,10 +585,11 @@ fn dma_wr(
         );
         bar.write(
             WithBase::of::<E>(),
-            regs::NV_PFALCON_FALCON_DMATRFBASE1::zeroed().try_with_base(dma_start >> 40)?,
+            crate::regs::NV_PFALCON_FALCON_DMATRFBASE1::zeroed()
+                .try_with_base(dma_start >> 40)?,
         );
 
-        let cmd = regs::NV_PFALCON_FALCON_DMATRFCMD::zeroed()
+        let cmd = crate::regs::NV_PFALCON_FALCON_DMATRFCMD::zeroed()
             .with_size(DmaTrfCmdSize::Size256B)
             .with_falcon_mem(target_mem);
 
@@ -592,12 +597,13 @@ fn dma_wr(
             // Perform a transfer of size `DMA_LEN`.
             bar.write(
                 WithBase::of::<E>(),
-                regs::NV_PFALCON_FALCON_DMATRFMOFFS::zeroed()
+                crate::regs::NV_PFALCON_FALCON_DMATRFMOFFS::zeroed()
                     .try_with_offs(load_offsets.dst_start + pos)?,
             );
             bar.write(
                 WithBase::of::<E>(),
-                regs::NV_PFALCON_FALCON_DMATRFFBOFFS::zeroed().with_offs(src_start + pos),
+                crate::regs::NV_PFALCON_FALCON_DMATRFFBOFFS::zeroed()
+                    .with_offs(src_start + pos),
             );
 
             bar.write(WithBase::of::<E>(), cmd);
@@ -606,7 +612,7 @@ fn dma_wr(
             // TIMEOUT: arbitrarily large value, no DMA transfer to the falcon's small memories
             // should ever take that long.
             read_poll_timeout(
-                || Ok(bar.read(regs::NV_PFALCON_FALCON_DMATRFCMD::of::<E>())),
+                || Ok(bar.read(crate::regs::NV_PFALCON_FALCON_DMATRFCMD::of::<E>())),
                 |r| r.idle(),
                 Delta::ZERO,
                 Delta::from_secs(2),
@@ -643,7 +649,7 @@ fn dma_load<F: FalconFirmware<Target = E> + FalconDmaLoadable>(
         };
 
         self.dma_reset(bar);
-        bar.update(regs::NV_PFALCON_FBIF_TRANSCFG::of::<E>().at(0), |v| {
+        bar.update(crate::regs::NV_PFALCON_FBIF_TRANSCFG::of::<E>().at(0), |v| {
             v.with_target(FalconFbifTarget::CoherentSysmem)
                 .with_mem_type(FalconFbifMemType::Physical)
         });
@@ -661,7 +667,8 @@ fn dma_load<F: FalconFirmware<Target = E> + FalconDmaLoadable>(
         // Set `BootVec` to start of non-secure code.
         bar.write(
             WithBase::of::<E>(),
-            regs::NV_PFALCON_FALCON_BOOTVEC::zeroed().with_value(fw.boot_addr()),
+            crate::regs::NV_PFALCON_FALCON_BOOTVEC::zeroed()
+                .with_value(fw.boot_addr()),
         );
 
         Ok(())
@@ -671,7 +678,7 @@ fn dma_load<F: FalconFirmware<Target = E> + FalconDmaLoadable>(
     pub(crate) fn wait_till_halted(&self, bar: Bar0<'_>) -> Result<()> {
         // TIMEOUT: arbitrarily large value, firmwares should complete in less than 2 seconds.
         read_poll_timeout(
-            || Ok(bar.read(regs::NV_PFALCON_FALCON_CPUCTL::of::<E>())),
+            || Ok(bar.read(crate::regs::NV_PFALCON_FALCON_CPUCTL::of::<E>())),
             |r| r.halted(),
             Delta::ZERO,
             Delta::from_secs(2),
@@ -683,16 +690,18 @@ pub(crate) fn wait_till_halted(&self, bar: Bar0<'_>) -> Result<()> {
     /// Start the falcon CPU.
     pub(crate) fn start(&self, bar: Bar0<'_>) -> Result<()> {
         match bar
-            .read(regs::NV_PFALCON_FALCON_CPUCTL::of::<E>())
+            .read(crate::regs::NV_PFALCON_FALCON_CPUCTL::of::<E>())
             .alias_en()
         {
             true => bar.write(
                 WithBase::of::<E>(),
-                regs::NV_PFALCON_FALCON_CPUCTL_ALIAS::zeroed().with_startcpu(true),
+                crate::regs::NV_PFALCON_FALCON_CPUCTL_ALIAS::zeroed()
+                    .with_startcpu(true),
             ),
             false => bar.write(
                 WithBase::of::<E>(),
-                regs::NV_PFALCON_FALCON_CPUCTL::zeroed().with_startcpu(true),
+                crate::regs::NV_PFALCON_FALCON_CPUCTL::zeroed()
+                    .with_startcpu(true),
             ),
         }
 
@@ -704,27 +713,29 @@ pub(crate) fn write_mailboxes(&self, bar: Bar0<'_>, mbox0: Option<u32>, mbox1: O
         if let Some(mbox0) = mbox0 {
             bar.write(
                 WithBase::of::<E>(),
-                regs::NV_PFALCON_FALCON_MAILBOX0::zeroed().with_value(mbox0),
+                crate::regs::NV_PFALCON_FALCON_MAILBOX0::zeroed()
+                    .with_value(mbox0),
             );
         }
 
         if let Some(mbox1) = mbox1 {
             bar.write(
                 WithBase::of::<E>(),
-                regs::NV_PFALCON_FALCON_MAILBOX1::zeroed().with_value(mbox1),
+                crate::regs::NV_PFALCON_FALCON_MAILBOX1::zeroed()
+                    .with_value(mbox1),
             );
         }
     }
 
     /// Reads the value from `mbox0` register.
     pub(crate) fn read_mailbox0(&self, bar: Bar0<'_>) -> u32 {
-        bar.read(regs::NV_PFALCON_FALCON_MAILBOX0::of::<E>())
+        bar.read(crate::regs::NV_PFALCON_FALCON_MAILBOX0::of::<E>())
             .value()
     }
 
     /// Reads the value from `mbox1` register.
     pub(crate) fn read_mailbox1(&self, bar: Bar0<'_>) -> u32 {
-        bar.read(regs::NV_PFALCON_FALCON_MAILBOX1::of::<E>())
+        bar.read(crate::regs::NV_PFALCON_FALCON_MAILBOX1::of::<E>())
             .value()
     }
 
@@ -792,7 +803,7 @@ pub(crate) fn load<F: FalconFirmware<Target = E> + FalconDmaLoadable>(
     pub(crate) fn write_os_version(&self, bar: Bar0<'_>, app_version: u32) {
         bar.write(
             WithBase::of::<E>(),
-            regs::NV_PFALCON_FALCON_OS::zeroed().with_value(app_version),
+            crate::regs::NV_PFALCON_FALCON_OS::zeroed().with_value(app_version),
         );
     }
 }
diff --git a/drivers/gpu/nova-core/falcon/hal/ga102.rs b/drivers/gpu/nova-core/falcon/hal/ga102.rs
index cf6ce47e6b25..cc574fef0fbd 100644
--- a/drivers/gpu/nova-core/falcon/hal/ga102.rs
+++ b/drivers/gpu/nova-core/falcon/hal/ga102.rs
@@ -24,24 +24,25 @@
         FalconBromParams,
         FalconEngine,
         FalconModSelAlgo,
-        PeregrineCoreSelect, //
+        PeregrineCoreSelect,
+        regs, //
     },
-    regs,
 };
 
 use super::FalconHal;
 
 fn select_core_ga102<E: FalconEngine>(bar: Bar0<'_>) -> Result {
-    let bcr_ctrl = bar.read(regs::NV_PRISCV_RISCV_BCR_CTRL::of::<E>());
+    let bcr_ctrl = bar.read(crate::regs::NV_PRISCV_RISCV_BCR_CTRL::of::<E>());
     if bcr_ctrl.core_select() != PeregrineCoreSelect::Falcon {
         bar.write(
             WithBase::of::<E>(),
-            regs::NV_PRISCV_RISCV_BCR_CTRL::zeroed().with_core_select(PeregrineCoreSelect::Falcon),
+            crate::regs::NV_PRISCV_RISCV_BCR_CTRL::zeroed()
+                .with_core_select(PeregrineCoreSelect::Falcon),
         );
 
         // TIMEOUT: falcon core should take less than 10ms to report being enabled.
         read_poll_timeout(
-            || Ok(bar.read(regs::NV_PRISCV_RISCV_BCR_CTRL::of::<E>())),
+            || Ok(bar.read(crate::regs::NV_PRISCV_RISCV_BCR_CTRL::of::<E>())),
             |r| r.valid(),
             Delta::ZERO,
             Delta::from_millis(10),
@@ -59,7 +60,7 @@ fn signature_reg_fuse_version_ga102(
 ) -> Result<u32> {
     // Each engine has 16 ucode version registers numbered from 1 to 16.
     let ucode_idx = match usize::from(ucode_id) {
-        ucode_id @ 1..=regs::NV_FUSE_OPT_FPF_SIZE => ucode_id - 1,
+        ucode_id @ 1..=crate::regs::NV_FUSE_OPT_FPF_SIZE => ucode_id - 1,
         _ => {
             dev_err!(dev, "invalid ucode id {:#x}\n", ucode_id);
             return Err(EINVAL);
@@ -69,13 +70,13 @@ fn signature_reg_fuse_version_ga102(
     // `ucode_idx` is guaranteed to be in the range [0..15], making the `read` calls provable valid
     // at build-time.
     let reg_fuse_version: u16 = if engine_id_mask & 0x0001 != 0 {
-        bar.read(regs::NV_FUSE_OPT_FPF_SEC2_UCODE1_VERSION::at(ucode_idx))
+        bar.read(crate::regs::NV_FUSE_OPT_FPF_SEC2_UCODE1_VERSION::at(ucode_idx))
             .data()
     } else if engine_id_mask & 0x0004 != 0 {
-        bar.read(regs::NV_FUSE_OPT_FPF_NVDEC_UCODE1_VERSION::at(ucode_idx))
+        bar.read(crate::regs::NV_FUSE_OPT_FPF_NVDEC_UCODE1_VERSION::at(ucode_idx))
             .data()
     } else if engine_id_mask & 0x0400 != 0 {
-        bar.read(regs::NV_FUSE_OPT_FPF_GSP_UCODE1_VERSION::at(ucode_idx))
+        bar.read(crate::regs::NV_FUSE_OPT_FPF_GSP_UCODE1_VERSION::at(ucode_idx))
             .data()
     } else {
         dev_err!(dev, "unexpected engine_id_mask {:#x}\n", engine_id_mask);
@@ -89,7 +90,8 @@ fn signature_reg_fuse_version_ga102(
 fn program_brom_ga102<E: FalconEngine>(bar: Bar0<'_>, params: &FalconBromParams) {
     bar.write(
         WithBase::of::<E>().at(0),
-        regs::NV_PFALCON2_FALCON_BROM_PARAADDR::zeroed().with_value(params.pkc_data_offset),
+        regs::NV_PFALCON2_FALCON_BROM_PARAADDR::zeroed()
+            .with_value(params.pkc_data_offset),
     );
     bar.write(
         WithBase::of::<E>(),
@@ -98,11 +100,13 @@ fn program_brom_ga102<E: FalconEngine>(bar: Bar0<'_>, params: &FalconBromParams)
     );
     bar.write(
         WithBase::of::<E>(),
-        regs::NV_PFALCON2_FALCON_BROM_CURR_UCODE_ID::zeroed().with_ucode_id(params.ucode_id),
+        regs::NV_PFALCON2_FALCON_BROM_CURR_UCODE_ID::zeroed()
+            .with_ucode_id(params.ucode_id),
     );
     bar.write(
         WithBase::of::<E>(),
-        regs::NV_PFALCON2_FALCON_MOD_SEL::zeroed().with_algo(FalconModSelAlgo::Rsa3k),
+        regs::NV_PFALCON2_FALCON_MOD_SEL::zeroed()
+            .with_algo(FalconModSelAlgo::Rsa3k),
     );
 }
 
@@ -134,14 +138,14 @@ fn program_brom(&self, _falcon: &Falcon<E>, bar: Bar0<'_>, params: &FalconBromPa
     }
 
     fn is_riscv_active(&self, bar: Bar0<'_>) -> bool {
-        bar.read(regs::NV_PRISCV_RISCV_CPUCTL::of::<E>())
+        bar.read(crate::regs::NV_PRISCV_RISCV_CPUCTL::of::<E>())
             .active_stat()
     }
 
     fn reset_wait_mem_scrubbing(&self, bar: Bar0<'_>) -> Result {
         // TIMEOUT: memory scrubbing should complete in less than 20ms.
         read_poll_timeout(
-            || Ok(bar.read(regs::NV_PFALCON_FALCON_HWCFG2::of::<E>())),
+            || Ok(bar.read(crate::regs::NV_PFALCON_FALCON_HWCFG2::of::<E>())),
             |r| r.mem_scrubbing_done(),
             Delta::ZERO,
             Delta::from_millis(20),
@@ -150,18 +154,18 @@ fn reset_wait_mem_scrubbing(&self, bar: Bar0<'_>) -> Result {
     }
 
     fn reset_eng(&self, bar: Bar0<'_>) -> Result {
-        let _ = bar.read(regs::NV_PFALCON_FALCON_HWCFG2::of::<E>());
+        let _ = bar.read(crate::regs::NV_PFALCON_FALCON_HWCFG2::of::<E>());
 
         // According to OpenRM's `kflcnPreResetWait_GA102` documentation, HW sometimes does not set
         // RESET_READY so a non-failing timeout is used.
         let _ = read_poll_timeout(
-            || Ok(bar.read(regs::NV_PFALCON_FALCON_HWCFG2::of::<E>())),
+            || Ok(bar.read(crate::regs::NV_PFALCON_FALCON_HWCFG2::of::<E>())),
             |r| r.reset_ready(),
             Delta::ZERO,
             Delta::from_micros(150),
         );
 
-        regs::NV_PFALCON_FALCON_ENGINE::reset_engine::<E>(bar);
+        crate::regs::NV_PFALCON_FALCON_ENGINE::reset_engine::<E>(bar);
         self.reset_wait_mem_scrubbing(bar)?;
 
         Ok(())
diff --git a/drivers/gpu/nova-core/falcon/regs.rs b/drivers/gpu/nova-core/falcon/regs.rs
new file mode 100644
index 000000000000..be8dbb599fc9
--- /dev/null
+++ b/drivers/gpu/nova-core/falcon/regs.rs
@@ -0,0 +1,30 @@
+// SPDX-License-Identifier: GPL-2.0
+
+use kernel::io::register;
+
+use crate::falcon::{
+    PFalcon2Base,
+    FalconModSelAlgo, //
+};
+
+/* PFALCON2 */
+
+register! {
+    pub(super) NV_PFALCON2_FALCON_MOD_SEL(u32) @ PFalcon2Base + 0x00000180 {
+        7:0     algo ?=> FalconModSelAlgo;
+    }
+
+    pub(super) NV_PFALCON2_FALCON_BROM_CURR_UCODE_ID(u32) @ PFalcon2Base + 0x00000198 {
+        7:0    ucode_id => u8;
+    }
+
+    pub(super) NV_PFALCON2_FALCON_BROM_ENGIDMASK(u32) @ PFalcon2Base + 0x0000019c {
+        31:0    value => u32;
+    }
+
+    /// OpenRM defines this as a register array, but doesn't specify its size and only uses its
+    /// first element. Be conservative until we know the actual size or need to use more registers.
+    pub(super) NV_PFALCON2_FALCON_BROM_PARAADDR(u32)[1] @ PFalcon2Base + 0x00000210 {
+        31:0    value => u32;
+    }
+}
diff --git a/drivers/gpu/nova-core/regs.rs b/drivers/gpu/nova-core/regs.rs
index 59d36870b92b..0b048086f54f 100644
--- a/drivers/gpu/nova-core/regs.rs
+++ b/drivers/gpu/nova-core/regs.rs
@@ -22,7 +22,6 @@
         FalconFbifMemType,
         FalconFbifTarget,
         FalconMem,
-        FalconModSelAlgo,
         FalconSecurityModel,
         PFalcon2Base,
         PFalconBase,
@@ -494,28 +493,6 @@ pub(crate) fn mem_scrubbing_done(self) -> bool {
     }
 }
 
-/* PFALCON2 */
-
-register! {
-    pub(crate) NV_PFALCON2_FALCON_MOD_SEL(u32) @ PFalcon2Base + 0x00000180 {
-        7:0     algo ?=> FalconModSelAlgo;
-    }
-
-    pub(crate) NV_PFALCON2_FALCON_BROM_CURR_UCODE_ID(u32) @ PFalcon2Base + 0x00000198 {
-        7:0    ucode_id => u8;
-    }
-
-    pub(crate) NV_PFALCON2_FALCON_BROM_ENGIDMASK(u32) @ PFalcon2Base + 0x0000019c {
-        31:0    value => u32;
-    }
-
-    /// OpenRM defines this as a register array, but doesn't specify its size and only uses its
-    /// first element. Be conservative until we know the actual size or need to use more registers.
-    pub(crate) NV_PFALCON2_FALCON_BROM_PARAADDR(u32)[1] @ PFalcon2Base + 0x00000210 {
-        31:0    value => u32;
-    }
-}
-
 // PRISCV
 
 register! {

-- 
2.54.0

