From: Younes Akhouayri <git@younes.io>
Date: Thu, 30 Jul 2026 18:34:38 +0200
Subject: [PATCH v2] rust: dma: return zero for Coherent reads past EOF
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-fix-dma-coherent-eof-v2-1-8aff21054afa@younes.io>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WOQQ6CMBBFr2K6drStEcGV9zAsSjvIGG3NFIiEc
 Hdb3LhzN3/y/sufRUQmjOK8mQXjSJGCT0FvN8J2xt8QyKUstNSFPGkJLb3BPQ3Y0CGj7wFDC04
 6WdpKoVQHkaovxsSt2mv9zXFo7mj77MpEYyJCw8bbLr8c04icpIz7nxse5IeY+Y5iH3had44qe
 /9MGhUocJUuyqNrSmeKyxQGj3FHQdTLsnwAr9P7IfoAAAA=
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
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Younes Akhouayri <git@younes.io>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785429312; l=1756;
 i=git@younes.io; s=20260712; h=from:subject:message-id;
 bh=h1A+NWN2Xpe9vp3xANzc6K2B5aOY514pEP2UO1pSO+Q=;
 b=mcGqEDFd4tUQ4CKrD8JSz08ovz5d+/Zm3sLI9AXnCzTxWYEN+ol/hs34cyjMHkCifR6j40Vt/
 lvefY+a1mVkB1Zxz+H4mVDG0jt0V5fG0opzf5DxbI3DepObP5oT+fdu
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
Cc: stable@vger.kernel.org
Link: https://rust-for-linux.zulipchat.com/#narrow/channel/291566-Library/topic/.E2.9C.94.20Possible.20past-EOF.20bug.20in.20Coherent.3CT.3E.3A.3Awrite_to_slice/near/611677095
Signed-off-by: Younes Akhouayri <git@younes.io>
---
Changes in v2:
- Use ordinary subtraction after the explicit EOF check, which makes
  underflow impossible.
- Link to v1: https://patch.msgid.link/20260720-fix-dma-coherent-eof-v1-1-d92685db8da6@younes.io
---
 rust/kernel/dma.rs | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/rust/kernel/dma.rs b/rust/kernel/dma.rs
index 200def84fb69..556424b88fb9 100644
--- a/rust/kernel/dma.rs
+++ b/rust/kernel/dma.rs
@@ -1005,7 +1005,11 @@ fn write_to_slice(
             return Ok(0);
         };
 
-        let count = self.size().saturating_sub(offset_val).min(writer.len());
+        if offset_val >= self.size() {
+            return Ok(0);
+        }
+
+        let count = (self.size() - offset_val).min(writer.len());
 
         writer.write_dma(self, offset_val, count)?;
 

---
base-commit: 667d0fb32149f023b8b34a1f6f3d384556eafb5a
change-id: 20260720-fix-dma-coherent-eof-d0d08c91e013

Best regards,
--  
Younes Akhouayri <git@younes.io>

