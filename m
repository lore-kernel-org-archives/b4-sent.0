From: Josef Ippisch <josef.ippisch.dev@mailbox.org>
Date: Sun, 19 Jul 2026 10:28:49 +0200
Subject: [PATCH 2/2] rust: debugfs: remove unsafe block from BinaryWriter
 impl for Vec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260719-migrate-binarywriter-to-zerocopy-intobytes-v1-2-27ed30512e75@mailbox.org>
References: <20260719-migrate-binarywriter-to-zerocopy-intobytes-v1-0-27ed30512e75@mailbox.org>
In-Reply-To: <20260719-migrate-binarywriter-to-zerocopy-intobytes-v1-0-27ed30512e75@mailbox.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: driver-core@lists.linux.dev, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joshua Liebow-Feeser <joshlf@google.com>, 
 Miguel Ojeda <ojeda@kernel.org>, 
 Josef Ippisch <josef.ippisch.dev@mailbox.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784449742; l=1292;
 i=josef.ippisch.dev@mailbox.org; s=20260719; h=from:subject:message-id;
 bh=CHLkAGmhpDB+02B5seMmVd9PeGaJl3leJ/BeMIes9uQ=;
 b=GA4y8gJ9Lp+CKm1ldrBBbzxlQtX88nZkcj90Se4zx5sK2yv0jYd21V0bTE4GWsQ/6k2TgVmCH
 LdReWw0uFd9C6be6gtbKjTyAj2IvNX1IbSRclr5V3Po/bBc9SRYJDCD
X-Developer-Key: i=josef.ippisch.dev@mailbox.org; a=ed25519;
 pk=M4DnWHhz9yT9BkhXKzsmw6wTVrK2U1WBK0QiEjHoo1U=
X-Endpoint-Received: by B4 Relay for josef.ippisch.dev@mailbox.org/20260719 with auth_id=884
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The previous implementation used an `unsafe` block to manually cast Vec's
slice to a &[u8] using `core::slice::from_raw_parts`.

Instead, the implementation can be implemented in safe rust using
`IntoBytes::as_bytes()` and making use of deref coercion to implicitly cast
Vec to &[T] as `IntoBytes` automatically is implemented on [T] when
`IntoBytes` is implemented on T.

Signed-off-by: Josef Ippisch <josef.ippisch.dev@mailbox.org>
---
 rust/kernel/debugfs/traits.rs | 9 +--------
 1 file changed, 1 insertion(+), 8 deletions(-)

diff --git a/rust/kernel/debugfs/traits.rs b/rust/kernel/debugfs/traits.rs
index ce030ff45a4c..4a24afbb8760 100644
--- a/rust/kernel/debugfs/traits.rs
+++ b/rust/kernel/debugfs/traits.rs
@@ -160,14 +160,7 @@ fn write_to_slice(
         writer: &mut UserSliceWriter,
         offset: &mut file::Offset,
     ) -> Result<usize> {
-        let slice = self.as_slice();
-
-        // SAFETY: `T: Immutable + IntoBytes` allows us to treat `&[T]` as `&[u8]`.
-        let buffer = unsafe {
-            core::slice::from_raw_parts(slice.as_ptr().cast(), core::mem::size_of_val(slice))
-        };
-
-        writer.write_slice_file(buffer, offset)
+        writer.write_slice_file(self.as_bytes(), offset)
     }
 }
 

-- 
2.53.0

