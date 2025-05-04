From: Alban Kurti <kurti@invicto.ai>
Date: Sun, 04 May 2025 17:41:14 +0200
Subject: [PATCH v4 1/2] rust: samples: add missing newline to pr_info!
 calls in rust_print_main
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250504-pr_info-newline-fix-v4-1-53467c401eb6@invicto.ai>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746373294; l=1213;
 i=kurti@invicto.ai; s=20250504; h=from:subject:message-id;
 bh=WqmT9bkLvd4AJUblF1ztL4Nd9ksadB1FIaF6HWuwtwM=;
 b=60ax0KZSu0JTP+EZvd1+mR/HafmRHqulLSczy1JexTcm9XkIAOj2Gkr3yi6SjHvNU2JtPr2xT
 GEVLEpXPZLgAs2juJZCq2slmDnoy6qiQLckZiqWhiWW3wB2uwtsxq8C
X-Developer-Key: i=kurti@invicto.ai; a=ed25519;
 pk=7724GF1zrN6rA3Z2xkyAmVGkoOQxv7bMUvXB4IsIPUs=
X-Endpoint-Received: by B4 Relay for kurti@invicto.ai/20250504 with auth_id=398
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes: f431c5c581fa ("samples: rust: print: Add sample code for Arc printing")
Reported-by: Miguel Ojeda <ojeda@kernel.org>
Closes: https://github.com/Rust-for-Linux/linux/issues/1139
Signed-off-by: Alban Kurti <kurti@invicto.ai>
---
 samples/rust/rust_print_main.rs | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/samples/rust/rust_print_main.rs b/samples/rust/rust_print_main.rs
index 8ea95e8c2f3647650577c4e9dab853e0e3a8bf20..899a6d25f4dc0e0ccebdf4f95aaaf780b425e3af 100644
--- a/samples/rust/rust_print_main.rs
+++ b/samples/rust/rust_print_main.rs
@@ -23,10 +23,10 @@ fn arc_print() -> Result {
     let b = UniqueArc::new("hello, world", GFP_KERNEL)?;
 
     // Prints the value of data in `a`.
-    pr_info!("{}", a);
+    pr_info!("{}\n", a);
 
     // Uses ":?" to print debug fmt of `b`.
-    pr_info!("{:?}", b);
+    pr_info!("{:?}\n", b);
 
     let a: Arc<&str> = b.into();
     let c = a.clone();
@@ -53,7 +53,7 @@ fn arc_dyn_print(arc: &Arc<dyn Display>) {
     }
 
     // Pretty-prints the debug formatting with lower-case hexadecimal integers.
-    pr_info!("{:#x?}", a);
+    pr_info!("{:#x?}\n", a);
 
     Ok(())
 }

-- 
2.49.0

