From: Maurice Hieronymus <mhi@mailbox.org>
Date: Tue, 26 May 2026 19:04:57 +0200
Subject: [PATCH 1/2] rust: clk: Add ExclusiveClk wrapper for
 clk_rate_exclusive_get
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260526-rate-exclusive-get-th1520-v1-1-34cf034e1764@mailbox.org>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779815100; l=3630;
 i=mhi@mailbox.org; s=20260525; h=from:subject:message-id;
 bh=eeAOAa6Y2zm3Hajnun7vvZ2u6PShjeRY9qX+W/KRP+c=;
 b=7Z8IQMFi5xKCCFeuAal3K7kJkXYyGA1HDWZvUu0uVf9KwQYky55CqLDF3yCnETma2JXvhfW9b
 CtNi39i0kGcBkhMafUkqL9gOIVXwCe6aHH0kw4epFcVmIWMtrRdEIcI
X-Developer-Key: i=mhi@mailbox.org; a=ed25519;
 pk=AHlEkGG3hpXZHntlEzF42Ip/LFyXWOgsNUvaHqAnV80=
X-Endpoint-Received: by B4 Relay for mhi@mailbox.org/20260525 with auth_id=790
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Rust bindings for clk_rate_exclusive_get() and
clk_rate_exclusive_put().

Clk::rate_exclusive_get() consumes the Clk and returns an ExclusiveClk;
the matching put is issued from its Drop impl. ExclusiveClk derefs to
Clk so existing rate / prepare / enable APIs remain available on the
locked handle.

Signed-off-by: Maurice Hieronymus <mhi@mailbox.org>
---
 rust/kernel/clk.rs | 65 ++++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 65 insertions(+)

diff --git a/rust/kernel/clk.rs b/rust/kernel/clk.rs
index 7abbd0767d8c..8cda40cb01e4 100644
--- a/rust/kernel/clk.rs
+++ b/rust/kernel/clk.rs
@@ -249,6 +249,23 @@ pub fn set_rate(&self, rate: Hertz) -> Result {
             // [`clk_set_rate`].
             to_result(unsafe { bindings::clk_set_rate(self.as_raw(), rate.as_hz()) })
         }
+
+        /// Acquire exclusive control over the clock's rate.
+        ///
+        /// Consumes the [`Clk`] and returns an [`ExclusiveClk`] that releases the exclusivity
+        /// when dropped. While held, no other consumer may change the clock's rate.
+        ///
+        /// Equivalent to the kernel's [`clk_rate_exclusive_get`] API. Must not be called from
+        /// atomic context.
+        ///
+        /// [`clk_rate_exclusive_get`]:
+        /// https://docs.kernel.org/core-api/kernel-api.html#c.clk_rate_exclusive_get
+        pub fn rate_exclusive_get(self) -> Result<ExclusiveClk> {
+            // SAFETY: By the type invariants, self.as_raw() is a valid argument for
+            // [`clk_rate_exclusive_get`].
+            to_result(unsafe { bindings::clk_rate_exclusive_get(self.as_raw()) })?;
+            Ok(ExclusiveClk(self))
+        }
     }
 
     impl Drop for Clk {
@@ -329,6 +346,54 @@ fn deref(&self) -> &Clk {
             &self.0
         }
     }
+
+    /// A [`Clk`] with exclusive control over its rate.
+    ///
+    /// While an [`ExclusiveClk`] exists, no other consumer of the same clock may change its rate.
+    /// Obtained by calling [`Clk::rate_exclusive_get`]; the exclusivity is released automatically
+    /// when the value is dropped, after which the inner [`Clk`] is dropped as usual.
+    ///
+    /// # Invariants
+    ///
+    /// An [`ExclusiveClk`] instance owns a [`Clk`] for which `clk_rate_exclusive_get` has been
+    /// called and the matching `clk_rate_exclusive_put` has not yet been called.
+    ///
+    /// # Examples
+    ///
+    /// ```
+    /// use kernel::clk::{Clk, ExclusiveClk};
+    /// use kernel::device::Device;
+    /// use kernel::error::Result;
+    ///
+    /// fn lock_rate(dev: &Device) -> Result<ExclusiveClk> {
+    ///     let clk = Clk::get(dev, None)?;
+    ///     clk.prepare_enable()?;
+    ///     clk.rate_exclusive_get()
+    /// }
+    /// ```
+    ///
+    /// [`struct clk`]: https://docs.kernel.org/driver-api/clk.html
+    pub struct ExclusiveClk(Clk);
+
+    // Make [`ExclusiveClk`] behave like [`Clk`].
+    impl Deref for ExclusiveClk {
+        type Target = Clk;
+
+        fn deref(&self) -> &Clk {
+            &self.0
+        }
+    }
+
+    impl Drop for ExclusiveClk {
+        fn drop(&mut self) {
+            // SAFETY: By the type invariants, self.as_raw() is a valid argument for
+            // [`clk_rate_exclusive_put`] and balances the [`clk_rate_exclusive_get`] call from
+            // [`Clk::rate_exclusive_get`].
+            unsafe {
+                bindings::clk_rate_exclusive_put(self.as_raw());
+            }
+        }
+    }
 }
 
 #[cfg(CONFIG_COMMON_CLK)]

-- 
2.51.2

