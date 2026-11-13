From: =?utf-8?q?Nicol=C3=A1s_Antinori?= <nico.antinori.7@gmail.com>
Date: Fri, 13 Nov 2026 15:20:57 -0300
Subject: [PATCH v3 3/3] rust: bitmap: kunit: uncomment
 owned_bitmap_out_of_bounds panic case
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261113-rust_kunit_v6_send-v3-3-0d7832c07166@gmail.com>
References: <20261113-rust_kunit_v6_send-v3-0-0d7832c07166@gmail.com>
In-Reply-To: <20261113-rust_kunit_v6_send-v3-0-0d7832c07166@gmail.com>
To: Alice Ryhl <aliceryhl@google.com>, Benno Lossin <lossin@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Brendan Higgins <brendan.higgins@linux.dev>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Danilo Krummrich <dakr@kernel.org>, David Gow <david@davidgow.net>, 
 Gary Guo <gary@garyguo.net>, Miguel Ojeda <ojeda@kernel.org>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: Shuah Khan <skhan@linuxfoundation.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 Andreas Hindborg <a.hindborg@kernel.org>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Burak Emir <burak.emir@gmail.com>, Rae Moar <raemoar63@gmail.com>, 
 Tamir Duberstein <tamird@kernel.org>, Trevor Gross <tmgross@umich.edu>, 
 Yury Norov <yury.norov@gmail.com>, kunit-dev@googlegroups.com, 
 linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, linux-doc@vger.kernel.org, 
 =?utf-8?q?Nicol=C3=A1s_Antinori?= <nico.antinori.7@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1480;
 i=nico.antinori.7@gmail.com; h=from:subject:message-id;
 bh=tmjPblT/cEvVX5DBd0p9G+nF43mFr4W8rW5Nta9eEJ4=;
 b=owGbwMvMwCV2QdXfwqNJ1YjxtFoSQ9b3UPPdbpouHCf/1n+S3LdV+9nR1lTFLVe26kX+UdB03
 DrTw/ldRykLgxgXg6yYIstczvefjW3NK8qlNwXBzGFlAhnCwMUpABPpNWb4xTTnTmId0+RNbSpr
 yxe2+UUmltUq3Mvc/6TOac+574++hTIy9J5x+vCs93iZtFlzXYrk64Z+8YtFvgfzLmyWSSpMsNj
 ACAA=
X-Developer-Key: i=nico.antinori.7@gmail.com; a=openpgp;
 fpr=9D09EFF3333D3778771BB252D0254F3848822532
X-Endpoint-Received: by B4 Relay for nico.antinori.7@gmail.com/default with auth_id=1086
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Rust KUnit tests now support `#[should_panic]` attribute. Uncomment the
test so it can be run when CONFIG_RUST_BITMAP_HARDENED=y.

Also, move the #[test] attribute above other attributes to match
existing tests.

Acked-by: David Gow <david@davidgow.net>
Reviewed-by: Burak Emir <burak.emir@gmail.com>
Signed-off-by: Nicolás Antinori <nico.antinori.7@gmail.com>
---
 rust/kernel/bitmap.rs | 18 +++++++++---------
 1 file changed, 9 insertions(+), 9 deletions(-)

diff --git a/rust/kernel/bitmap.rs b/rust/kernel/bitmap.rs
index 610d565535ccfba6af8f2ca4ac4028fa027a9644..942c0cbc994b80d71bc4b3de67e5730c914e4a7f 100644
--- a/rust/kernel/bitmap.rs
+++ b/rust/kernel/bitmap.rs
@@ -777,15 +777,15 @@ fn owned_bitmap_out_of_bounds() -> Result<(), AllocError> {
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
+    #[test]
+    #[cfg(CONFIG_RUST_BITMAP_HARDENED)]
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

