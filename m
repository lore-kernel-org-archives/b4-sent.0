From: Moritz Zielke <moritz.zielke@gmail.com>
Date: Thu, 30 Oct 2025 17:44:31 +0100
Subject: [PATCH] rust: of: replace `core::mem::zeroed` with
 `pin_init::zeroed`
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251030-zeroed-of-rs-v1-1-1c46d025128e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAO6VA2kC/x2MSQqAMAwAvyI5G+iCCn5FPGibai5WUhCx+HeDx
 xmYqVBImAqMTQWhiwvnQ8G2DYR9OTZCjsrgjOus8QYfkkwRc0IpuPS0qrc++AE0OYUS3/9umt/
 3A1BRE05eAAAA
X-Change-ID: 20251030-zeroed-of-rs-a6eb25113c37
To: Rob Herring <robh@kernel.org>, Saravana Kannan <saravanak@google.com>, 
 Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Andreas Hindborg <a.hindborg@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>, Danilo Krummrich <dakr@kernel.org>
Cc: Benno Lossin <lossin@kernel.org>, devicetree@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Moritz Zielke <moritz.zielke@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761842708; l=1541;
 i=moritz.zielke@gmail.com; s=20251030; h=from:subject:message-id;
 bh=oIbp+tyuhn5HEWfpBG4m5GYtbBRXvFJksWeRXP7Pve8=;
 b=nVSJxWlhTP77ybCN9R8/EXC779jPXMDH3CHQznrpLng3wflemW1OpE5FHX1dszUuUZPcvV7ls
 7MUgAXipLVRBqnYWafoFPWmnacrNmYI5nTBq92cthKH57XvAS0Vo+Q9
X-Developer-Key: i=moritz.zielke@gmail.com; a=ed25519;
 pk=TFwYpZ0YPwD8idGzvlafpvAW4DDA0FrkMEjcfZVXkN0=
X-Endpoint-Received: by B4 Relay for moritz.zielke@gmail.com/20251030 with auth_id=558
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

All types in `bindings` implement `Zeroable` if they can, so use
`pin_init::zeroed` instead of relying on `unsafe` code.

If this ends up not compiling in the future, something in bindgen or on
the C side changed and is most likely incorrect.

---
This patch was suggested in the linked issue. It's my first attempt
of sending a patch to the kernel mailing list.

Link: https://github.com/Rust-for-Linux/linux/issues/1189
Suggested-by: Benno Lossin <lossin@kernel.org>
Signed-off-by: Moritz Zielke <moritz.zielke@gmail.com>
---
 rust/kernel/of.rs | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/rust/kernel/of.rs b/rust/kernel/of.rs
index 58b20c367..cfcfbb1fd 100644
--- a/rust/kernel/of.rs
+++ b/rust/kernel/of.rs
@@ -35,9 +35,7 @@ impl DeviceId {
     /// Create a new device id from an OF 'compatible' string.
     pub const fn new(compatible: &'static CStr) -> Self {
         let src = compatible.to_bytes_with_nul();
-        // Replace with `bindings::of_device_id::default()` once stabilized for `const`.
-        // SAFETY: FFI type is valid to be zero-initialized.
-        let mut of: bindings::of_device_id = unsafe { core::mem::zeroed() };
+        let mut of: bindings::of_device_id = pin_init::zeroed();
 
         // TODO: Use `copy_from_slice` once stabilized for `const`.
         let mut i = 0;

---
base-commit: 3b1728b74a52e8489f0c7bfd3d682572dd9901de
change-id: 20251030-zeroed-of-rs-a6eb25113c37

Best regards,
-- 
Moritz Zielke <moritz.zielke@gmail.com>

