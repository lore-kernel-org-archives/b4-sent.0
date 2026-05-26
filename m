From: Maurice Hieronymus <mhi@mailbox.org>
Date: Tue, 26 May 2026 19:04:58 +0200
Subject: [PATCH 2/2] pwm: th1520: Lock clock rate with
 clk_rate_exclusive_get
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260526-rate-exclusive-get-th1520-v1-2-34cf034e1764@mailbox.org>
References: <20260526-rate-exclusive-get-th1520-v1-0-34cf034e1764@mailbox.org>
In-Reply-To: <20260526-rate-exclusive-get-th1520-v1-0-34cf034e1764@mailbox.org>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Miguel Ojeda <ojeda@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Drew Fustini <fustini@kernel.org>, 
 Guo Ren <guoren@kernel.org>, Fu Wei <wefu@redhat.com>, 
 Michal Wilczynski <m.wilczynski@samsung.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>
Cc: linux-clk@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-pwm@vger.kernel.org, Maurice Hieronymus <mhi@mailbox.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779815100; l=1525;
 i=mhi@mailbox.org; s=20260525; h=from:subject:message-id;
 bh=ijdGRfoTVRxXfNyIw+J4I55qYh5/j8fCJaQQLZ2ik/o=;
 b=FPRu4JUed3iOmruEs1DxB2Ies0lJTysltEPmsJb+yRb3RbZgYri/ak4s5sUuEOq5AhAWxdm6S
 5ZDPX57xtalDvqgMwlQkE/6IdDfz4ZwAwsotRXKRDMAcrokkQv8J2PE
X-Developer-Key: i=mhi@mailbox.org; a=ed25519;
 pk=AHlEkGG3hpXZHntlEzF42Ip/LFyXWOgsNUvaHqAnV80=
X-Endpoint-Received: by B4 Relay for mhi@mailbox.org/20260525 with auth_id=790
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver derives period and duty cycle from the clock rate read at
probe, so a later rate change would silently miscompute waveforms.
Switch to the new ExclusiveClk wrapper to hold the rate for the lifetime
of the driver data and drop the corresponding TODO.

Signed-off-by: Maurice Hieronymus <mhi@mailbox.org>
---
 drivers/pwm/pwm_th1520.rs | 8 +++-----
 1 file changed, 3 insertions(+), 5 deletions(-)

diff --git a/drivers/pwm/pwm_th1520.rs b/drivers/pwm/pwm_th1520.rs
index ddd44a5ce497..19e8621bc52c 100644
--- a/drivers/pwm/pwm_th1520.rs
+++ b/drivers/pwm/pwm_th1520.rs
@@ -22,7 +22,7 @@
 
 use core::ops::Deref;
 use kernel::{
-    clk::Clk,
+    clk::{Clk, ExclusiveClk},
     device::{Bound, Core, Device},
     devres,
     io::{
@@ -93,7 +93,7 @@ struct Th1520WfHw {
 struct Th1520PwmDriverData {
     #[pin]
     iomem: devres::Devres<IoMem<TH1520_PWM_REG_SIZE>>,
-    clk: Clk,
+    clk: ExclusiveClk,
 }
 
 impl pwm::PwmOps for Th1520PwmDriverData {
@@ -328,10 +328,8 @@ fn probe(
         let clk = Clk::get(dev, None)?;
 
         clk.prepare_enable()?;
+        let clk = clk.rate_exclusive_get()?;
 
-        // TODO: Get exclusive ownership of the clock to prevent rate changes.
-        // The Rust equivalent of `clk_rate_exclusive_get()` is not yet available.
-        // This should be updated once it is implemented.
         let rate_hz = clk.rate().as_hz();
         if rate_hz == 0 {
             dev_err!(dev, "Clock rate is zero\n");

-- 
2.51.2

