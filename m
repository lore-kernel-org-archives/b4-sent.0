From: Sophon Z <aiqubits@hotmail.com>
Date: Mon, 31 Aug 2026 11:47:24 +0800
Subject: [PATCH] rust: block: Fix GenDiskBuilder block size documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260831-fix-gendisk-block-size-docs-v1-1-900546005799@hotmail.com>
X-B4-Tracking: v=1; b=H4sIAEv5lGoC/yXMQQrCMBBG4auUWTuQprSKVxEX7eS3jpVEMlqKp
 Xc36vKDx1vJkBVGx2qljFlNUyyodxXJtY8jWEMxeec7d2hqvujCI2JQm3i4J5nY9A0OSYylgfe
 97F3btVQOj4yS/+6n89/2Gm6Q53dJ2/YBZI91iX8AAAA=
X-Change-ID: 20260831-fix-gendisk-block-size-docs-c3e22ac70565
To: Andreas Hindborg <a.hindborg@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Miguel Ojeda <ojeda@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>, Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: linux-block@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sophon Z <aiqubits@hotmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788148062; l=1956;
 i=aiqubits@hotmail.com; s=20260831; h=from:subject:message-id;
 bh=bOkxOycOeNPewqeSHo0cMWhcJJczIZOzbJuJHTlpI4Q=;
 b=yuKAM79tiw8QxxMHkC1czHgpI34xIchucM2KyO6i1hjzynv4/BYooVAIAsMJcOrmHFG7s3tif
 Y1uLBw8eymKDLx5emH9O9Jt84x4Tj6bE6JY3OqtiicYqv/04clyMEE4
X-Developer-Key: i=aiqubits@hotmail.com; a=ed25519;
 pk=+mrkwQAyCCkZdVPpu+CBQr1VZQlkXa7/1WizfeSF/yg=
X-Endpoint-Received: by B4 Relay for aiqubits@hotmail.com/20260831 with auth_id=992
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

GenDiskBuilder::validate_block_size() accepts powers of two from 512
through PAGE_SIZE, but the documentation for logical_block_size() and
physical_block_size() states that the maximum is 4096.

Use PAGE_SIZE for both documented upper bounds so that the documentation
matches validation on architectures with larger page sizes.

Signed-off-by: Sophon Z <aiqubits@hotmail.com>
---
 rust/kernel/block/mq/gen_disk.rs | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/rust/kernel/block/mq/gen_disk.rs b/rust/kernel/block/mq/gen_disk.rs
index fc97dd873974..119ee522d854 100644
--- a/rust/kernel/block/mq/gen_disk.rs
+++ b/rust/kernel/block/mq/gen_disk.rs
@@ -63,7 +63,7 @@ pub fn validate_block_size(size: u32) -> Result {
     /// Set the logical block size of the device to be built.
     ///
     /// This method will check that block size is a power of two and between 512
-    /// and 4096. If not, an error is returned and the block size is not set.
+    /// and `PAGE_SIZE`. If not, an error is returned and the block size is not set.
     ///
     /// This is the smallest unit the storage device can address. It is
     /// typically 4096 bytes.
@@ -76,7 +76,7 @@ pub fn logical_block_size(mut self, block_size: u32) -> Result<Self> {
     /// Set the physical block size of the device to be built.
     ///
     /// This method will check that block size is a power of two and between 512
-    /// and 4096. If not, an error is returned and the block size is not set.
+    /// and `PAGE_SIZE`. If not, an error is returned and the block size is not set.
     ///
     /// This is the smallest unit a physical storage device can write
     /// atomically. It is usually the same as the logical block size but may be

---
base-commit: cee9395acd8043be0644b25c34bfa86623f2b935
change-id: 20260831-fix-gendisk-block-size-docs-c3e22ac70565

Best regards,
--  
Sophon Z <aiqubits@hotmail.com>

