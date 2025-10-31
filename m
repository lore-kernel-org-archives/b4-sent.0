From: Moritz Zielke <moritz.zielke@gmail.com>
Date: Fri, 31 Oct 2025 10:51:41 +0100
Subject: [PATCH v2] rust: of: replace `core::mem::zeroed` with
 `pin_init::zeroed`
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251031-zeroed-of-rs-v2-1-f89ff71e943e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAKyGBGkC/3WMzQrCMBCEX6Xs2ZX8aBVPvof0EJNtu2Ab2UhQS
 97dtHeZ0zfDfAskEqYEl2YBocyJ41zB7Brwo5sHQg6VwShz1Moq/JJEChh7lISupXvttfX2BPX
 yFOr5veluXeWR0yvKZ7NnvbZ/RFljjT+0YZ3Nma7D5Pix93GCrpTyA1wqvbyoAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761904321; l=1602;
 i=moritz.zielke@gmail.com; s=20251030; h=from:subject:message-id;
 bh=OnB3GPr22kqGecRkpj0YRj3co22bJtrQhNK1vieBomQ=;
 b=Tufu5yszhlo2brG2pyeFgV4tCFZzPlNkr6s0GwoPI8AGFxG3XMtjYWQHPa0vo82qs48v2pVfR
 FfQiIru0qadDaT+DakTg6GW4g6dhFxWCKILAYH/bdgswfukqVuONS4W
X-Developer-Key: i=moritz.zielke@gmail.com; a=ed25519;
 pk=TFwYpZ0YPwD8idGzvlafpvAW4DDA0FrkMEjcfZVXkN0=
X-Endpoint-Received: by B4 Relay for moritz.zielke@gmail.com/20251030 with auth_id=558
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

All types in `bindings` implement `Zeroable` if they can, so use
`pin_init::zeroed` instead of relying on `unsafe` code.

If this ends up not compiling in the future, something in bindgen or on
the C side changed and is most likely incorrect.

Link: https://github.com/Rust-for-Linux/linux/issues/1189
Suggested-by: Benno Lossin <lossin@kernel.org>
Signed-off-by: Moritz Zielke <moritz.zielke@gmail.com>
---
Changes in v2:
- Rearrange tags and `---` so tags don't get lost when patch is applied
- Link to v1: https://lore.kernel.org/r/20251030-zeroed-of-rs-v1-1-1c46d025128e@gmail.com
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

