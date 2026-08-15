From: Ke Sun <sunke@kylinos.cn>
Date: Sat, 15 Aug 2026 13:00:31 +0800
Subject: [PATCH rust-next v2] rust: fmt: rework pointer formatting tests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260815-b4-hashedptr-followup-v2-1-6cf592ad1022@kylinos.cn>
X-B4-Tracking: v=1; b=H4sIAG7yf2oC/3WNyw6CMBREf4XctdfQhxZd+R+GBY9ibyRt0xaEE
 P7dhrh1eTIzZzaIOpCOcC82CHqmSM5m4KcCOtPYl0bqMwMv+bWsmMRWommi0b1PAQc3ju4zeeS
 qkb0SahBKQd76oAdaDu8TwhQTWr0kqHNkKCYX1uNxZkfhJ7/8kc8MGVZCcKlK3sru9nivI1kXz
 52Fet/3L532JeXGAAAA
X-Change-ID: 20260814-b4-hashedptr-followup-27a4d737f377
To: Miguel Ojeda <ojeda@kernel.org>
Cc: Gary Guo <gary@garyguo.net>, Boqun Feng <boqun@kernel.org>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ke Sun <sunke@kylinos.cn>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786770129; l=6669;
 i=sunke@kylinos.cn; s=20260317; h=from:subject:message-id;
 bh=qtnzn0XwheOjLSxI3U7X4nlXPdrx6AGWoWdmY9ulHzs=;
 b=uimAqKU6ONr2K3w/gu+yItFgjOGOseKjcOuKQccHfe0MxfB1w377WBT7+ptRBPnkrvld3Ss/2
 LHtVS8bmRT/Djg6s8g8lSI5DOvhN7xyRerlm1isnhcIlPZXFZBJrmCt
X-Developer-Key: i=sunke@kylinos.cn; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for sunke@kylinos.cn/20260317 with auth_id=950
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

`test_ptr_formatting` depended on the `no_hash_pointers` setting and
skipped the remaining checks when the CRNG was not ready. Assert the
formatted variants against the plain `{:p}` output instead, and cover
the placeholder path.

Signed-off-by: Ke Sun <sunke@kylinos.cn>
---
This is a follow-up to the applied v15 series "rust: Add safe pointer
formatting support" (on rust-next), addressing the review feedback on
the KUnit tests.
---
Changes in v2:
- Fix the KUnit failure when the CRNG is not ready: `%p` emits the
  placeholder at a fixed length, ignoring width and zero-padding.
- Link to v1: https://lore.kernel.org/r/20260815-b4-hashedptr-followup-v1-1-83324702b4c9@kylinos.cn
---
 rust/kernel/fmt.rs | 98 ++++++++++++++++++++----------------------------------
 1 file changed, 36 insertions(+), 62 deletions(-)

diff --git a/rust/kernel/fmt.rs b/rust/kernel/fmt.rs
index 29582b053ab1f..cbdca7183d54b 100644
--- a/rust/kernel/fmt.rs
+++ b/rust/kernel/fmt.rs
@@ -215,83 +215,57 @@ fn fmt(&self, f: &mut Formatter<'_>) -> Result {
 #[macros::kunit_tests(rust_kernel_fmt)]
 mod tests {
     use crate::{
-        bindings,
         prelude::fmt,
         str::CString, //
     };
 
+    // Placeholder used when the CRNG is not ready.
     #[cfg(CONFIG_64BIT)]
-    mod expected {
-        pub(super) const PTR_VALUE: usize = 0xffffffffdeadbeef;
-        pub(super) const PTR_VAL_NO_CRNG: &str = "(____ptrval____)";
-        pub(super) const HASHED_PREFIX: &str = "0x00000000";
-        pub(super) const RAW_POINTER: &str = "0xffffffffdeadbeef";
-        pub(super) const PADDED_RIGHT: &str = "      0xffffffffdeadbeef";
-        pub(super) const ZERO_PADDED: &str = "0x000000ffffffffdeadbeef";
-        pub(super) const HASHED_PADDED_RIGHT_PREFIX: &str = "      ";
-        pub(super) const HASHED_ZERO_PADDED_PREFIX: &str = "0x00000000000000";
-        pub(super) const CLAMPED: &str = "0x0000000000000ffffffffdeadbeef";
-    }
+    const PTR_VAL_NO_CRNG: &str = "(____ptrval____)";
 
     #[cfg(not(CONFIG_64BIT))]
-    mod expected {
-        pub(super) const PTR_VALUE: usize = 0xdeadbeef;
-        pub(super) const PTR_VAL_NO_CRNG: &str = "(ptrval)";
-        pub(super) const HASHED_PREFIX: &str = "0x";
-        pub(super) const RAW_POINTER: &str = "0xdeadbeef";
-        pub(super) const PADDED_RIGHT: &str = "              0xdeadbeef";
-        pub(super) const ZERO_PADDED: &str = "0x00000000000000deadbeef";
-        pub(super) const HASHED_PADDED_RIGHT_PREFIX: &str = "              ";
-        pub(super) const HASHED_ZERO_PADDED_PREFIX: &str = "0x00000000000000";
-        pub(super) const CLAMPED: &str = "0x0000000000000000000000deadbeef";
-    }
+    const PTR_VAL_NO_CRNG: &str = "(ptrval)";
+
+    #[cfg(CONFIG_64BIT)]
+    const PTR_VALUE: usize = 0xffffffffdeadbeef;
+
+    #[cfg(not(CONFIG_64BIT))]
+    const PTR_VALUE: usize = 0xdeadbeef;
 
     #[test]
     fn test_ptr_formatting() -> core::result::Result<(), crate::error::Error> {
-        let ptr: *const u8 = core::ptr::without_provenance(expected::PTR_VALUE);
+        let ptr: *const u8 = core::ptr::without_provenance(PTR_VALUE);
 
-        // SAFETY: `no_hash_pointers` is a global variable that is never concurrently modified —
-        // KUnit tests may run at boot (before `mark_readonly()`) or manually afterwards (when the
-        // variable is read-only). Reading is always safe.
-        let no_hash = unsafe { bindings::no_hash_pointers };
+        let cstr = CString::try_from_fmt(fmt!("{:p}", ptr))?;
+        let formatted = cstr.to_str()?;
 
-        if no_hash {
-            let cstr = CString::try_from_fmt(fmt!("{:p}", ptr))?;
-            assert_eq!(cstr.to_str()?, expected::RAW_POINTER);
+        // If the CRNG is not ready yet, `%p` emits the placeholder at a fixed
+        // length: `f.pad` still applies, zero-padding does not (see `ptr_to_id()`).
+        let (crng_ready, expected_suffix) = if let Some(suffix) = formatted.strip_prefix("0x") {
+            (true, suffix)
+        } else {
+            (false, formatted)
+        };
+        let (zero_padded_len, clamped_len) = if crng_ready {
+            (24, 31)
+        } else {
+            (PTR_VAL_NO_CRNG.len(), PTR_VAL_NO_CRNG.len())
+        };
 
-            let cstr = CString::try_from_fmt(fmt!("{:>24p}", ptr))?;
-            assert_eq!(cstr.to_str()?, expected::PADDED_RIGHT);
+        let cstr = CString::try_from_fmt(fmt!("{:>24p}", ptr))?;
+        let padded = cstr.to_str()?;
+        assert!(padded.ends_with(expected_suffix));
+        assert_eq!(padded.len(), 24);
 
-            let cstr = CString::try_from_fmt(fmt!("{:024p}", ptr))?;
-            assert_eq!(cstr.to_str()?, expected::ZERO_PADDED);
+        let cstr = CString::try_from_fmt(fmt!("{:024p}", ptr))?;
+        let zero_padded = cstr.to_str()?;
+        assert!(zero_padded.ends_with(expected_suffix));
+        assert_eq!(zero_padded.len(), zero_padded_len);
 
-            let cstr = CString::try_from_fmt(fmt!("{:0100p}", ptr))?;
-            assert_eq!(cstr.to_str()?, expected::CLAMPED);
-        } else {
-            let cstr = CString::try_from_fmt(fmt!("{:p}", ptr))?;
-            let formatted = cstr.to_str()?;
-            // If the RNG is not yet ready, `%p` falls back to a placeholder.
-            if formatted == expected::PTR_VAL_NO_CRNG {
-                return Ok(());
-            }
-            assert!(formatted.starts_with(expected::HASHED_PREFIX));
-            assert_ne!(formatted, expected::RAW_POINTER);
-
-            let cstr = CString::try_from_fmt(fmt!("{:>24p}", ptr))?;
-            assert!(cstr
-                .to_str()?
-                .starts_with(expected::HASHED_PADDED_RIGHT_PREFIX));
-
-            let cstr = CString::try_from_fmt(fmt!("{:024p}", ptr))?;
-            assert!(cstr
-                .to_str()?
-                .starts_with(expected::HASHED_ZERO_PADDED_PREFIX));
-
-            let cstr = CString::try_from_fmt(fmt!("{:0100p}", ptr))?;
-            let output = cstr.to_str()?;
-            assert!(output.starts_with("0x"));
-            assert!(!output[2..].chars().all(|c| c == '0'));
-        }
+        let cstr = CString::try_from_fmt(fmt!("{:0100p}", ptr))?;
+        let clamped = cstr.to_str()?;
+        assert!(clamped.ends_with(expected_suffix));
+        assert_eq!(clamped.len(), clamped_len);
 
         Ok(())
     }

---
base-commit: be387b625933ee12ed230b1c2af5e14f946c3040
change-id: 20260814-b4-hashedptr-followup-27a4d737f377

Best regards,
-- 
Ke Sun <sunke@kylinos.cn>

