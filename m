From: Younes Akhouayri <git@younes.io>
Date: Mon, 20 Jul 2026 21:21:39 +0200
Subject: [PATCH] rust: dma: return zero for Coherent reads past EOF
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-fix-dma-coherent-eof-v1-1-d92685db8da6@younes.io>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMywrCMBBFf6XM2sEkgq9fkS7ymDYjmMgkFaH03
 03s8lzuOSsUEqYC92EFoQ8XzqmBPgzgo00zIYfGYJQ5q4tROPEXw8uiz5GEUkXKEwYV1NXfNCl
 9gqa+hdrvn32MO5fFPcnX3uoPZwuhE5t87FMWnjkdZSkVd3Pbfi0LylOcAAAA
X-Change-ID: 20260720-fix-dma-coherent-eof-d0d08c91e013
To: Danilo Krummrich <dakr@kernel.org>, 
 Abdiel Janulgue <abdiel.janulgue@gmail.com>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Robin Murphy <robin.murphy@arm.com>, 
 Andreas Hindborg <a.hindborg@kernel.org>, Miguel Ojeda <ojeda@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>, Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Timur Tabi <ttabi@nvidia.com>
Cc: driver-core@lists.linux.dev, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Younes Akhouayri <git@younes.io>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784575333; l=1249;
 i=git@younes.io; s=20260712; h=from:subject:message-id;
 bh=ePXYrWvX1ZJHBuWoCGi8RZ5TS9lrAyqgkzIq9B/HEy0=;
 b=NfHD8xfI5i55YLfCBe7tqm0G8oZ4a4geTGO9kWWsJ9qBfmySQKlGogGfmzkXta8XZv+0kbUQ1
 ub/u/f6nzNoCPyTyLbgzeweY6Nz3e34MrFIC8SUBDaSWDuYPTNto0yq
X-Developer-Key: i=git@younes.io; a=ed25519;
 pk=1DRfzPrQ04RQHHgGK28t+vjIAPv5oISPiAdLMU6J5dE=
X-Endpoint-Received: by B4 Relay for git@younes.io/20260712 with auth_id=866
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Coherent<T>::write_to_slice() calculates a zero-byte copy when the file
offset is beyond the allocation, but still calls
UserSliceWriter::write_dma(). The latter rejects offsets beyond the
allocation even when the copy length is zero, so a debugfs read past EOF
returns -ERANGE.

Return before calling write_dma() when the offset is at or beyond the
allocation, matching simple_read_from_buffer() EOF semantics.

Fixes: 016818513936 ("rust: dma: implement BinaryWriter for Coherent<[u8]>")
Signed-off-by: Younes Akhouayri <git@younes.io>
---
 rust/kernel/dma.rs | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/rust/kernel/dma.rs b/rust/kernel/dma.rs
index 200def84fb69..36b72fb9ab46 100644
--- a/rust/kernel/dma.rs
+++ b/rust/kernel/dma.rs
@@ -1005,6 +1005,10 @@ fn write_to_slice(
             return Ok(0);
         };
 
+        if offset_val >= self.size() {
+            return Ok(0);
+        }
+
         let count = self.size().saturating_sub(offset_val).min(writer.len());
 
         writer.write_dma(self, offset_val, count)?;

---
base-commit: 880c43b185ca52239e75bc546cc4f4d9154d0fed
change-id: 20260720-fix-dma-coherent-eof-d0d08c91e013

Best regards,
--  
Younes Akhouayri <git@younes.io>

