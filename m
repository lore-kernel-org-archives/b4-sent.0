From: Dave Airlie <airlied@redhat.com>
Date: Fri, 06 Nov 2026 15:34:03 +1000
Subject: [PATCH v5 2/2] gpu: nova-core: add support for GPU timer block.
 (v5)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261106-nova-timer-v5-2-a0cd25f3ee18@redhat.com>
References: <20261106-nova-timer-v5-0-a0cd25f3ee18@redhat.com>
In-Reply-To: <20261106-nova-timer-v5-0-a0cd25f3ee18@redhat.com>
To: Andreas Hindborg <a.hindborg@kernel.org>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, Gary Guo <gary@garyguo.net>, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Alexandre Courbot <acourbot@nvidia.com>
Cc: nova-gpu@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=15926; i=airlied@redhat.com;
 h=from:subject:message-id; bh=EDaM5XyrnEqQAtv92Aba0bwpUszPyf6uEYWadOGZ0AU=;
 b=kA0DAAoBDHTzWXnEhr4ByyZiAGrtZtCiJgMoqR+NZ48HyqlzB/BLCGlmwcjJfByQvyZ7bIkSf
 IkCMwQAAQoAHRYhBBCm2R2hsFvSn23rrAx081l5xIa+BQJq7WbQAAoJEAx081l5xIa+UsEP/0Gj
 I8/Qr3TzVDSLKxZJqBv6zWnWRGUkIBS1ja0pqOHF3OzMBZLdbBlK5McmKvu+iaBotdDMlbNZxhU
 84ZW1aTprUE5H1uVZ6ytH6bvPw3ixjL15ls5cXbn8uHCUccOQsJensh+hGwV6hxbPZGFMielf6F
 7RxykchP8+VhbMC1IfogxBTBFxvwGuvWilkp+W6Y3u3Oww+1hx2oF5gi2puCYT0tK0MJdr0CZ/z
 AFhxBc0AAjsx4c/FVd9ybsTgtp6LUtgNrIJaKUXuzemGr3GzZ8aFYYFPeauRdbVsyBwr1z+zGrI
 rsjnA2AWbbnWaS2yWu01ZvUHlhuzWoqAbSpqkr5kknpwl5wQxqbHvgFZ/2tY1lqbdXsMoUaOiJ4
 FvO4kc5KauS0kySuKCCN/6pp3C3/amqznTibeSmNcxd6GB9xWXCiBp0ZswHv4Ljgn5e0JbSQzn5
 IJfVx65Qwyhvm1rEqoThVL44NUTojYvz+pR355x5V+mQXymHlEJ3876djW0JPF7/QniHRN8nlXr
 Xy+bs7xhV8/pBuG9By1W3wufSAL7v6mvve8FRzsAmipNBaKbjsCyPjp0qXQmDYVJzrRrBUKbBEX
 1abn8BYVqZ2vesP8epFqwz6AHdAnrtRNPbTjlAO0YE6O0VlOjlj8eikt95Us1u4VPXHQ9dDWcWR
 tSxUY
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is needed to calculate the system timer offset that is passed
to GSP init.

2 HALs exist:

a) tu102 is the gv100 path from open-gpu, the priv level is checked
and the cpu time is written to the gpu timer. no offset is used.

b) gh100 is for hopper+
This is the gh100 path from open-gpu, where the secure system
timer is read, the offset is calculated.
On gh100 which need a work around to avoid sending it to registers
if the FSP firmware is too old.
Otherwise we write the offset to the offset registers.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 drivers/gpu/nova-core/fsp.rs             | 19 ++++++-
 drivers/gpu/nova-core/fsp/hal.rs         |  5 ++
 drivers/gpu/nova-core/fsp/hal/gh100.rs   |  6 ++
 drivers/gpu/nova-core/fsp/regs.rs        | 28 +++++++++
 drivers/gpu/nova-core/gpu.rs             |  8 +++
 drivers/gpu/nova-core/nova_core.rs       |  1 +
 drivers/gpu/nova-core/timer.rs           | 38 +++++++++++++
 drivers/gpu/nova-core/timer/hal.rs       | 31 ++++++++++
 drivers/gpu/nova-core/timer/hal/gh100.rs | 62 ++++++++++++++++++++
 drivers/gpu/nova-core/timer/hal/tu102.rs | 53 +++++++++++++++++
 drivers/gpu/nova-core/timer/regs.rs      | 98 ++++++++++++++++++++++++++++++++
 11 files changed, 346 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/nova-core/fsp.rs b/drivers/gpu/nova-core/fsp.rs
index 3a4a10487f33..a2ea50465a55 100644
--- a/drivers/gpu/nova-core/fsp.rs
+++ b/drivers/gpu/nova-core/fsp.rs
@@ -50,10 +50,11 @@
         NvdmHeader,
         NvdmType, //
     },
-    regs, //
+    regs as bootregs, //
 };
 
 mod hal;
+mod regs;
 
 /// PRC message sub-command.
 #[derive(Debug, Clone, Copy, PartialEq, Eq)]
@@ -389,6 +390,7 @@ pub(crate) fn boot_params(&self) -> &Coherent<'_, GspFmcBootParams> {
 pub(crate) struct Fsp<'a> {
     falcon: Falcon<'a, FspEngine>,
     fmc_fw: GspFmcFirmware<'a>,
+    chipset: Chipset,
 }
 
 impl<'a> Fsp<'a> {
@@ -428,7 +430,7 @@ fn wait_secure_boot(
 
         read_poll_timeout(
             || Ok(hal.fsp_boot_status(bar)),
-            |&status| status == regs::NV_THERM_I2CS_SCRATCH_FSP_BOOT_COMPLETE_STATUS_SUCCESS,
+            |&status| status == bootregs::NV_THERM_I2CS_SCRATCH_FSP_BOOT_COMPLETE_STATUS_SUCCESS,
             Delta::from_millis(10),
             Delta::from_millis(FSP_SECURE_BOOT_TIMEOUT_MS),
         )
@@ -436,7 +438,11 @@ fn wait_secure_boot(
             dev_err!(dev, "FSP secure boot completion error: {:?}\n", e);
         })?;
 
-        Ok(Fsp { falcon, fmc_fw })
+        Ok(Fsp {
+            falcon,
+            fmc_fw,
+            chipset,
+        })
     }
 
     /// Sends a message to FSP and waits for the response.
@@ -549,4 +555,11 @@ pub(crate) fn boot_fmc(
         dev_dbg!(dev, "FSP Chain of Trust completed successfully\n");
         Ok(())
     }
+
+    pub(crate) fn is_bug_3957833_affected(&self, bar: Bar0<'_>) -> bool {
+        match hal::fsp_hal(self.chipset) {
+            Some(hal) => hal.is_bug_3957833_affected(bar),
+            None => false,
+        }
+    }
 }
diff --git a/drivers/gpu/nova-core/fsp/hal.rs b/drivers/gpu/nova-core/fsp/hal.rs
index eaf5837ac5a8..8bcc8f71cf8f 100644
--- a/drivers/gpu/nova-core/fsp/hal.rs
+++ b/drivers/gpu/nova-core/fsp/hal.rs
@@ -23,6 +23,11 @@ pub(super) trait FspHal {
     // TODO: consider moving this into the TLV firmware metadata when ready
     /// Returns the size reserved at the end of the framebuffer, in bytes.
     fn fb_end_reserved_size(&self) -> u64;
+
+    /// Return if the bug 3957833 is affected
+    fn is_bug_3957833_affected(&self, _bar: Bar0<'_>) -> bool {
+        false
+    }
 }
 
 /// Returns the FSP HAL, or `None` if the architecture doesn't support FSP.
diff --git a/drivers/gpu/nova-core/fsp/hal/gh100.rs b/drivers/gpu/nova-core/fsp/hal/gh100.rs
index 9a8563799da8..538870566b8c 100644
--- a/drivers/gpu/nova-core/fsp/hal/gh100.rs
+++ b/drivers/gpu/nova-core/fsp/hal/gh100.rs
@@ -9,6 +9,7 @@
 use crate::{
     driver::Bar0,
     fsp::hal::FspHal,
+    fsp::regs as fspregs,
     regs, //
 };
 
@@ -33,6 +34,11 @@ fn cot_version(&self) -> u16 {
     fn fb_end_reserved_size(&self) -> u64 {
         u64::SZ_2M
     }
+
+    fn is_bug_3957833_affected(&self, bar: Bar0<'_>) -> bool {
+        bar.read(fspregs::NV_GFW_FSP_UCODE_VERSION)
+            .is_bug3957833_affected()
+    }
 }
 
 const GH100: Gh100 = Gh100;
diff --git a/drivers/gpu/nova-core/fsp/regs.rs b/drivers/gpu/nova-core/fsp/regs.rs
new file mode 100644
index 000000000000..de69d5bed427
--- /dev/null
+++ b/drivers/gpu/nova-core/fsp/regs.rs
@@ -0,0 +1,28 @@
+// SPDX-License-Identifier: GPL-2.0
+
+use kernel::io::register;
+
+use crate::driver::NovaRegisters;
+
+register! {
+    base: NovaRegisters;
+
+    /// FSP ucode version, encoded as `major.minor` in bits 11:8 and 7:0, written by the FSP
+    /// during boot. (`NV_PFSP_FALCON_COMMON_SCRATCH_GROUP_3(1)` in the hardware headers.)
+    pub(super) NV_GFW_FSP_UCODE_VERSION(u32) @ 0x008f0334 {
+        11:0 full;
+    }
+}
+
+impl NV_GFW_FSP_UCODE_VERSION {
+    /// OpenRM kfspRequiresBug3957833WAR_HAL:
+    /// returns `true` if the FSP ucode predates the fix for
+    /// bug 3957833 and hence the sys timer offset must not be programmed.
+    /// Can only be true on GH100 with older FSP.
+    pub(super) fn is_bug3957833_affected(self) -> bool {
+        /// FSP ucode version from which on the fix for bug 3957833 is included.
+        const FSP_BUG_3957833_FIX_VERSION: u32 = 0x44c;
+
+        self.full() < FSP_BUG_3957833_FIX_VERSION
+    }
+}
diff --git a/drivers/gpu/nova-core/gpu.rs b/drivers/gpu/nova-core/gpu.rs
index ac5305d7ff5e..cd281460c509 100644
--- a/drivers/gpu/nova-core/gpu.rs
+++ b/drivers/gpu/nova-core/gpu.rs
@@ -53,6 +53,10 @@
         GpuMm,
         VramAddress, //
     },
+    timer::{
+        Timer,
+        TimerState, //
+    },
     vgpu::VgpuManager, //
 };
 
@@ -331,6 +335,8 @@ struct GspResources<'gpu> {
     // TODO: use different resource types for each boot method, and make the relevant Gsp methods
     // generic against them.
     fsp: Option<Fsp<'gpu>>,
+    /// Timer state - contains system timer offset
+    timer: TimerState,
     /// vGPU state detected before GSP boot.
     vgpu: VgpuManager,
     /// GSP runtime data.
@@ -497,6 +503,8 @@ pub(crate) fn new<'a>(
 
                 fsp: Fsp::try_new(dev, bar, spec.chipset)?,
 
+                timer: Timer::setup(bar, spec.chipset, fsp.as_ref())?,
+
                 vgpu: VgpuManager::new(pdev, spec.chipset, fsp.as_mut()),
 
                 gsp <- Gsp::new(pdev, bar),
diff --git a/drivers/gpu/nova-core/nova_core.rs b/drivers/gpu/nova-core/nova_core.rs
index a8f6dc22057b..ee59d81e5105 100644
--- a/drivers/gpu/nova-core/nova_core.rs
+++ b/drivers/gpu/nova-core/nova_core.rs
@@ -27,6 +27,7 @@
 mod sbuffer;
 #[cfg(CONFIG_NOVA_CORE_SELFTESTS)]
 mod selftest;
+mod timer;
 mod vbios;
 mod vgpu;
 
diff --git a/drivers/gpu/nova-core/timer.rs b/drivers/gpu/nova-core/timer.rs
new file mode 100644
index 000000000000..4c329221c674
--- /dev/null
+++ b/drivers/gpu/nova-core/timer.rs
@@ -0,0 +1,38 @@
+// SPDX-License-Identifier: GPL-2.0
+
+mod hal;
+mod regs;
+
+use kernel::{
+    prelude::*, //
+};
+
+use crate::{
+    driver::Bar0,
+    fsp::Fsp,
+    gpu::Chipset, //
+};
+
+pub(crate) struct Timer;
+
+/// Struct that holds the sys timer offset value
+/// after initialising the GPU timer block.
+pub(crate) struct TimerState {
+    /// This value is to be passed to GspInit SYS_TIMER_OFFSET_NS
+    /// It is considered an opaque value, passed from timer hal to GSP.
+    #[expect(dead_code)]
+    pub(crate) sys_timer_offset_ns: u64,
+}
+
+impl Timer {
+    /// Setup the GPU timer hardware
+    pub(crate) fn setup(
+        bar: Bar0<'_>,
+        chipset: Chipset,
+        fsp: Option<&Fsp<'_>>,
+    ) -> Result<TimerState> {
+        Ok(TimerState {
+            sys_timer_offset_ns: hal::timer_hal(chipset).setup(bar, fsp)?,
+        })
+    }
+}
diff --git a/drivers/gpu/nova-core/timer/hal.rs b/drivers/gpu/nova-core/timer/hal.rs
new file mode 100644
index 000000000000..c2f2bbcad890
--- /dev/null
+++ b/drivers/gpu/nova-core/timer/hal.rs
@@ -0,0 +1,31 @@
+// SPDX-License-Identifier: GPL-2.0
+
+use kernel::prelude::*;
+
+use crate::{
+    driver::Bar0,
+    fsp::Fsp,
+    gpu::{
+        Architecture,
+        Chipset, //
+    },
+};
+
+mod gh100;
+mod tu102;
+
+pub(super) trait TimerHal {
+    /// Setup the GPU's system timer.
+    ///
+    /// Returns the value to program into GspInitRequest.
+    fn setup(&self, bar: Bar0<'_>, fsp: Option<&Fsp<'_>>) -> Result<u64>;
+}
+
+pub(super) fn timer_hal(chipset: Chipset) -> &'static dyn TimerHal {
+    match chipset.arch() {
+        Architecture::Turing | Architecture::Ampere | Architecture::Ada => tu102::TU102_HAL,
+        Architecture::Hopper | Architecture::BlackwellGB10x | Architecture::BlackwellGB20x => {
+            gh100::GH100_HAL
+        }
+    }
+}
diff --git a/drivers/gpu/nova-core/timer/hal/gh100.rs b/drivers/gpu/nova-core/timer/hal/gh100.rs
new file mode 100644
index 000000000000..49e348c89e52
--- /dev/null
+++ b/drivers/gpu/nova-core/timer/hal/gh100.rs
@@ -0,0 +1,62 @@
+// SPDX-License-Identifier: GPL-2.0
+
+use super::TimerHal;
+
+use kernel::{
+    io::Io,
+    prelude::*,
+    time::*, //
+};
+
+use crate::{
+    driver::Bar0,
+    fsp::Fsp,
+    timer::regs, //
+};
+
+/// Timer HAL for Hopper and Blackwell.
+struct Gh100;
+
+fn sec_timer_read(bar: Bar0<'_>) -> u64 {
+    let mut hi2 = bar.read(regs::gh100::NV_PGC6_SCI_SEC_TIMER_TIME_1);
+    loop {
+        let lo = bar.read(regs::gh100::NV_PGC6_SCI_SEC_TIMER_TIME_0);
+        let hi = bar.read(regs::gh100::NV_PGC6_SCI_SEC_TIMER_TIME_1);
+        if hi == hi2 {
+            return u64::from(u32::from(hi)) << 32 | u64::from(u32::from(lo));
+        }
+        hi2 = bar.read(regs::gh100::NV_PGC6_SCI_SEC_TIMER_TIME_1);
+    }
+}
+
+fn sys_timer_offset(bar: Bar0<'_>, fsp: &Fsp<'_>, time_ns: u64) -> Result<u64> {
+    let sec_timer_ns = sec_timer_read(bar);
+
+    let sys_timer_offset_ns = time_ns.wrapping_sub(sec_timer_ns);
+
+    if !fsp.is_bug_3957833_affected(bar) {
+        bar.write_reg(regs::gh100::NV_PGC6_SCI_SYS_TIMER_OFFSET_1::from_nsec(
+            sys_timer_offset_ns,
+        ));
+        bar.write_reg(
+            regs::gh100::NV_PGC6_SCI_SYS_TIMER_OFFSET_0::from_nsec(sys_timer_offset_ns)
+                .with_update(true),
+        );
+    }
+    Ok(sys_timer_offset_ns)
+}
+
+impl TimerHal for Gh100 {
+    fn setup(&self, bar: Bar0<'_>, fsp: Option<&Fsp<'_>>) -> Result<u64> {
+        // The open drivers uses wall clock time here not monotonic
+        let sys_time_ns = Instant::<RealTime>::now().as_nanos();
+
+        // fsp is required on gh100 - return error if not available.
+        let fsp = fsp.ok_or(EINVAL)?;
+
+        sys_timer_offset(bar, fsp, sys_time_ns as u64)
+    }
+}
+
+const GH100: Gh100 = Gh100;
+pub(super) const GH100_HAL: &dyn TimerHal = &GH100;
diff --git a/drivers/gpu/nova-core/timer/hal/tu102.rs b/drivers/gpu/nova-core/timer/hal/tu102.rs
new file mode 100644
index 000000000000..629d744a4b12
--- /dev/null
+++ b/drivers/gpu/nova-core/timer/hal/tu102.rs
@@ -0,0 +1,53 @@
+// SPDX-License-Identifier: GPL-2.0
+
+use super::TimerHal;
+
+use kernel::{
+    io::Io,
+    prelude::*,
+    time::*, //
+};
+
+use crate::{
+    driver::Bar0,
+    fsp::Fsp,
+    timer::regs, //
+};
+struct Tu102;
+
+// this code will be used in the gb10b hal eventually
+#[expect(dead_code)]
+fn timer_read(bar: Bar0<'_>) -> u64 {
+    let mut hi2 = bar.read(regs::NV_PTIMER_TIME_1);
+    loop {
+        let lo = bar.read(regs::NV_PTIMER_TIME_0);
+        let hi = bar.read(regs::NV_PTIMER_TIME_1);
+        if hi == hi2 {
+            return u64::from(u32::from(hi)) << 32 | u64::from(u32::from(lo));
+        }
+        hi2 = bar.read(regs::NV_PTIMER_TIME_1);
+    }
+}
+
+fn set_time(bar: Bar0<'_>, time_ns: u64) -> Result {
+    if !bar.read(regs::NV_PTIMER_TIME_PRIV_LEVEL_MASK).level0() {
+        return Err(EINVAL);
+    }
+    bar.write_reg(regs::NV_PTIMER_TIME_1::from_nsec(time_ns));
+    bar.write_reg(regs::NV_PTIMER_TIME_0::from_nsec(time_ns));
+    Ok(())
+}
+
+impl TimerHal for Tu102 {
+    fn setup(&self, bar: Bar0<'_>, _fsp: Option<&Fsp<'_>>) -> Result<u64> {
+        // The RM uses wall clock time here (osGetSystemTime -> ktime_get_real), so the GPU time
+        // matches the host's real time, e.g. for timestamp correlation in userspace.
+        let sys_time_ns = Instant::<RealTime>::now().as_nanos();
+
+        set_time(bar, sys_time_ns as u64)?;
+        Ok(0_u64)
+    }
+}
+
+const TU102: Tu102 = Tu102;
+pub(super) const TU102_HAL: &dyn TimerHal = &TU102;
diff --git a/drivers/gpu/nova-core/timer/regs.rs b/drivers/gpu/nova-core/timer/regs.rs
new file mode 100644
index 000000000000..89dd478a37be
--- /dev/null
+++ b/drivers/gpu/nova-core/timer/regs.rs
@@ -0,0 +1,98 @@
+// SPDX-License-Identifier: GPL-2.0
+
+use kernel::io::register;
+use kernel::num::Bounded;
+
+use crate::driver::NovaRegisters;
+use pin_init::Zeroable;
+
+/// Field value for the NSEC field (31:5) of the `_0` registers: `nsec[31:5]`.
+///
+/// The GPU timer counts nanoseconds with 32 ns granularity, so `nsec[4:0]` is dropped.
+fn nsec_lo(nsec: u64) -> Bounded<u32, 27> {
+    Bounded::<u32, 32>::from(nsec as u32).shr::<5, _>()
+}
+
+/// Field value for the NSEC field (28:0) of the `_1` registers: `nsec[60:32]`.
+///
+/// The GPU timer is 61 bits wide, so `nsec[63:61]` is not representable and is
+/// truncated — the same bits the hardware discards on a raw register write.
+fn nsec_hi(nsec: u64) -> Bounded<u32, 29> {
+    Bounded::<u32, 29>::from_expr((nsec >> 32) as u32 & 0x1fff_ffff)
+}
+
+// PTIMER
+
+register! {
+    base: NovaRegisters;
+
+    pub(super) NV_PTIMER_TIME_PRIV_LEVEL_MASK(u32) @ 0x00009430 {
+        4:4 level0 => bool;
+    }
+
+    pub(super) NV_PTIMER_TIME_0(u32) @ 0x00009400 {
+        31:5 nsec;
+    }
+
+    pub(super) NV_PTIMER_TIME_1(u32) @ 0x00009410 {
+        28:0 nsec;
+    }
+}
+
+impl NV_PTIMER_TIME_0 {
+    pub(super) fn from_nsec(nsec: u64) -> Self {
+        Self::zeroed().with_nsec(nsec_lo(nsec))
+    }
+}
+
+impl NV_PTIMER_TIME_1 {
+    pub(super) fn from_nsec(nsec: u64) -> Self {
+        Self::zeroed().with_nsec(nsec_hi(nsec))
+    }
+}
+
+pub(super) mod gh100 {
+    use kernel::io::register;
+
+    use super::{
+        nsec_hi, //
+        nsec_lo,
+    };
+    use crate::driver::NovaRegisters;
+    use pin_init::Zeroable;
+
+    // PGC6/TIMER
+    register! {
+        base: NovaRegisters;
+
+        pub(in crate::timer) NV_PGC6_SCI_SEC_TIMER_TIME_0(u32) @ 0x00118f54 {
+            31:5 nsec;
+        }
+
+        pub(in crate::timer) NV_PGC6_SCI_SEC_TIMER_TIME_1(u32) @ 0x00118f58 {
+            28:0 nsec;
+        }
+
+        pub(in crate::timer) NV_PGC6_SCI_SYS_TIMER_OFFSET_0(u32) @ 0x00118df4 {
+            0:0 update;
+            31:5 nsec;
+        }
+
+        pub(in crate::timer) NV_PGC6_SCI_SYS_TIMER_OFFSET_1(u32) @ 0x00118df8 {
+            28:0 nsec;
+        }
+
+    }
+
+    impl NV_PGC6_SCI_SYS_TIMER_OFFSET_0 {
+        pub(in crate::timer) fn from_nsec(nsec: u64) -> Self {
+            Self::zeroed().with_nsec(nsec_lo(nsec))
+        }
+    }
+
+    impl NV_PGC6_SCI_SYS_TIMER_OFFSET_1 {
+        pub(in crate::timer) fn from_nsec(nsec: u64) -> Self {
+            Self::zeroed().with_nsec(nsec_hi(nsec))
+        }
+    }
+}

-- 
2.56.0

