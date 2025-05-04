From: Alban Kurti <kurti@invicto.ai>
Date: Sun, 04 May 2025 17:41:15 +0200
Subject: [PATCH v4 2/2] rust: samples: add missing newline to pr_info!
 calls in rust_print_main
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250504-pr_info-newline-fix-v4-2-53467c401eb6@invicto.ai>
References: <20250504-pr_info-newline-fix-v4-0-53467c401eb6@invicto.ai>
In-Reply-To: <20250504-pr_info-newline-fix-v4-0-53467c401eb6@invicto.ai>
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>, Danilo Krummrich <dakr@kernel.org>, 
 Vincenzo Palazzo <vincenzopalazzodev@gmail.com>, 
 Xiangfei Ding <dingxiangfei2009@gmail.com>
Cc: Fiona Behrens <me@kloenk.dev>, Alban Kurti <kurti@invicto.ai>, 
 rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746373294; l=937;
 i=kurti@invicto.ai; s=20250504; h=from:subject:message-id;
 bh=DSEqWE0u/GE7NzFen9Dcl1jZYuo1Vd0DtsX8YqbKu8E=;
 b=qaYzqjfuy5W+yyNJtWYK7ZNq5t4Jl79u9xQ7m/jeUVt4zs7VMoZaCVvipoAtqHHWkNQlym+xF
 ejebzOxIRscAW5pa4AN0uJ3E3Zg5j8+sBXF5ONHtW2IVocSzjZWjwM/
X-Developer-Key: i=kurti@invicto.ai; a=ed25519;
 pk=7724GF1zrN6rA3Z2xkyAmVGkoOQxv7bMUvXB4IsIPUs=
X-Endpoint-Received: by B4 Relay for kurti@invicto.ai/20250504 with auth_id=398
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes: 47cb6bf7860c ("rust: use derive(CoercePointee) on rustc >= 1.84.0")
Reported-by: Miguel Ojeda <ojeda@kernel.org>
Closes: https://github.com/Rust-for-Linux/linux/issues/1139
Signed-off-by: Alban Kurti <kurti@invicto.ai>
---
 samples/rust/rust_print_main.rs | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/samples/rust/rust_print_main.rs b/samples/rust/rust_print_main.rs
index 899a6d25f4dc0e0ccebdf4f95aaaf780b425e3af..ed90f78d0b9125f3806d6e13e5a3352dec935140 100644
--- a/samples/rust/rust_print_main.rs
+++ b/samples/rust/rust_print_main.rs
@@ -42,7 +42,7 @@ fn arc_print() -> Result {
 
         use core::fmt::Display;
         fn arc_dyn_print(arc: &Arc<dyn Display>) {
-            pr_info!("Arc<dyn Display> says {arc}");
+            pr_info!("Arc<dyn Display> says {arc}\n");
         }
 
         let a_i32_display: Arc<dyn Display> = Arc::new(42i32, GFP_KERNEL)?;

-- 
2.49.0

