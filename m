From: =?utf-8?q?Nicol=C3=A1s_Antinori?= <nico.antinori.7@gmail.com>
Date: Thu, 29 Oct 2026 13:59:03 -0300
Subject: [PATCH v2 3/3] rust: bitmap: kunit: uncomment
 owned_bitmap_out_of_bounds panic case
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261029-rust_kunit_v6_send-v2-3-5ce551efc48e@gmail.com>
References: <20261029-rust_kunit_v6_send-v2-0-5ce551efc48e@gmail.com>
In-Reply-To: <20261029-rust_kunit_v6_send-v2-0-5ce551efc48e@gmail.com>
To: Alice Ryhl <aliceryhl@google.com>, Benno Lossin <lossin@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Brendan Higgins <brendan.higgins@linux.dev>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Danilo Krummrich <dakr@kernel.org>, David Gow <david@davidgow.net>, 
 Gary Guo <gary@garyguo.net>, Miguel Ojeda <ojeda@kernel.org>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: Alexandre Courbot <acourbot@nvidia.com>, 
 Andreas Hindborg <a.hindborg@kernel.org>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Burak Emir <burak.emir@gmail.com>, Rae Moar <raemoar63@gmail.com>, 
 Tamir Duberstein <tamird@kernel.org>, Trevor Gross <tmgross@umich.edu>, 
 Yury Norov <yury.norov@gmail.com>, kunit-dev@googlegroups.com, 
 linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, 
 =?utf-8?q?Nicol=C3=A1s_Antinori?= <nico.antinori.7@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1706;
 i=nico.antinori.7@gmail.com; h=from:subject:message-id;
 bh=iW+hZzmPpgHRkmWIVOTZYWfmFaZ6Ey/DgBI3aRQTyEA=;
 b=owGbwMvMwCV2QdXfwqNJ1YjxtFoSQ9bj6hbHjPKMLy90TIL5mWVTEuyrU/R92/XEhQuYmiRPf
 p4jGNtRysIgxsUgK6bIMpfz/WdjW/OKculNQTBzWJlAhjBwcQrAROYFMfxTi4qPPL91z/1oJeGE
 E9JezTy8bqWyIjt2Kvn6yxcWL3jB8E9/wsRvqVPdLYKF97V+z5nEVLX18qw/3d/WczBfsmxsE2A
 DAA==
X-Developer-Key: i=nico.antinori.7@gmail.com; a=openpgp;
 fpr=9D09EFF3333D3778771BB252D0254F3848822532
X-Endpoint-Received: by B4 Relay for nico.antinori.7@gmail.com/default with auth_id=1086
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Rust KUnit tests now support `#[should_panic]` attribute. Uncomment the
test so it can be run when CONFIG_RUST_BITMAP_HARDENED=y.

Signed-off-by: Nicolás Antinori <nico.antinori.7@gmail.com>
---
 rust/kernel/bitmap.rs | 21 ++++++++++-----------
 1 file changed, 10 insertions(+), 11 deletions(-)

diff --git a/rust/kernel/bitmap.rs b/rust/kernel/bitmap.rs
index 610d565535ccfba6af8f2ca4ac4028fa027a9644..8eecd669096713fc7f21431188959a921a1d5ca0 100644
--- a/rust/kernel/bitmap.rs
+++ b/rust/kernel/bitmap.rs
@@ -762,11 +762,10 @@ fn bitmap_set_clear_find() -> Result<(), AllocError> {
         Ok(())
     }
 
-    #[test]
     #[cfg(not(CONFIG_RUST_BITMAP_HARDENED))]
+    #[test]
     fn owned_bitmap_out_of_bounds() -> Result<(), AllocError> {
         let mut b = BitmapVec::new(128, GFP_KERNEL)?;
-
         b.set_bit(2048);
         b.set_bit_atomic(2048);
         b.clear_bit(2048);
@@ -777,15 +776,15 @@ fn owned_bitmap_out_of_bounds() -> Result<(), AllocError> {
         Ok(())
     }
 
-    // TODO: uncomment once kunit supports `#[should_panic]`.
-    // #[cfg(CONFIG_RUST_BITMAP_HARDENED)]
-    // #[test]
-    // #[should_panic]
-    // fn owned_bitmap_out_of_bounds() -> Result<(), AllocError> {
-    //     let mut b = BitmapVec::new(128, GFP_KERNEL)?;
-    //
-    //     b.set_bit(2048);
-    // }
+    #[cfg(CONFIG_RUST_BITMAP_HARDENED)]
+    #[test]
+    #[should_panic]
+    fn owned_bitmap_out_of_bounds() -> Result<(), AllocError> {
+        let mut b = BitmapVec::new(128, GFP_KERNEL)?;
+
+        b.set_bit(2048);
+        Ok(())
+    }
 
     #[test]
     fn bitmap_copy_and_extend() -> Result<(), AllocError> {

-- 
2.47.3

