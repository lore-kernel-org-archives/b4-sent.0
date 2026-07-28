From: Josef Ippisch <josef.ippisch.dev@mailbox.org>
Date: Tue, 28 Jul 2026 19:31:20 +0200
Subject: [PATCH v2 2/2] rust: debugfs: remove unsafe blocks from traits
 impl for Vec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260728-migrate-binarywriter-to-zerocopy-intobytes-v2-2-0a4ec1d3ead4@mailbox.org>
References: <20260728-migrate-binarywriter-to-zerocopy-intobytes-v2-0-0a4ec1d3ead4@mailbox.org>
In-Reply-To: <20260728-migrate-binarywriter-to-zerocopy-intobytes-v2-0-0a4ec1d3ead4@mailbox.org>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785259881; l=1990;
 i=josef.ippisch.dev@mailbox.org; s=20260719; h=from:subject:message-id;
 bh=bcAB+rSJxo9ZroXVfXApmlpdpJQVs1F1L0YRpjVbQJo=;
 b=cIaBDwtw9P9BlrpZZMIhZPxeVrxUAQrsh3v/wXuylsp42yoimMv9UCHwzftLYgybgje1LCjp8
 InD76OyzfrMCU4XDG3FVgCHeP/35GRzdMIcxhADEikC5S45vChJQtTi
X-Developer-Key: i=josef.ippisch.dev@mailbox.org; a=ed25519;
 pk=M4DnWHhz9yT9BkhXKzsmw6wTVrK2U1WBK0QiEjHoo1U=
X-Endpoint-Received: by B4 Relay for josef.ippisch.dev@mailbox.org/20260719 with auth_id=884
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The previous implementation used an `unsafe` block to manually cast Vec's
slice to a &[u8] using `core::slice::from_raw_parts`.  Instead, the
implementation can be implemented in safe rust using zerocopy's trait
functions `as_bytes()` and `as_mut_bytes()`, respectively, and making use
of deref coercion to implicitly cast Vec to &[T] as `FromBytes` and
`IntoBytes` automatically are implemented on [T] when they are implemented
on T.

Signed-off-by: Josef Ippisch <josef.ippisch.dev@mailbox.org>
---
 rust/kernel/debugfs/traits.rs | 21 ++-------------------
 1 file changed, 2 insertions(+), 19 deletions(-)

diff --git a/rust/kernel/debugfs/traits.rs b/rust/kernel/debugfs/traits.rs
index b794f7dd7e14..b295f8420abd 100644
--- a/rust/kernel/debugfs/traits.rs
+++ b/rust/kernel/debugfs/traits.rs
@@ -153,14 +153,7 @@ fn write_to_slice(
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
 
@@ -261,17 +254,7 @@ fn read_from_slice_mut(
         reader: &mut UserSliceReader,
         offset: &mut file::Offset,
     ) -> Result<usize> {
-        let slice = self.as_mut_slice();
-
-        // SAFETY: `T: FromBytes + IntoBytes` allow us to treat `&mut [T]` as `&mut [u8]`.
-        let buffer = unsafe {
-            core::slice::from_raw_parts_mut(
-                slice.as_mut_ptr().cast(),
-                core::mem::size_of_val(slice),
-            )
-        };
-
-        reader.read_slice_file(buffer, offset)
+        reader.read_slice_file(self.as_mut_bytes(), offset)
     }
 }
 

-- 
2.53.0

