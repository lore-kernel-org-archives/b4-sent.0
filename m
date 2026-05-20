From: Alvin Sun <alvin.sun@linux.dev>
Date: Wed, 20 May 2026 10:40:10 +0800
Subject: [PATCH v2 3/5] rust: miscdevice: remove redundant imports
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260520-miscdev-use-format-v2-3-64dc48fc1345@linux.dev>
References: <20260520-miscdev-use-format-v2-0-64dc48fc1345@linux.dev>
In-Reply-To: <20260520-miscdev-use-format-v2-0-64dc48fc1345@linux.dev>
To: Arnd Bergmann <arnd@arndb.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>
Cc: rust-for-linux@vger.kernel.org, linux-block@vger.kernel.org, 
 Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779244810; l=994;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=uxbSDDBiUmtFEUXe6RQ/fhwb3WKp/e+Dv491N2iFhjE=;
 b=nIiEQpCRCQxzwxU7nG8LskCvHlORHcgEBXMHXdnjmMhAt7hAPeeUSnksZbGkz+soNZAceM2eE
 CV4phwJU0crBEEDl3toGGxGMm9hFCmhv1pvmoMX+XiuCQGdke2yia+8
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Drop `Error`, `Result`, `Pin`, `c_int`, `c_long`, `c_uint`, and
`c_ulong` imports already provided by `kernel::prelude`.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 rust/kernel/miscdevice.rs | 13 +------------
 1 file changed, 1 insertion(+), 12 deletions(-)

diff --git a/rust/kernel/miscdevice.rs b/rust/kernel/miscdevice.rs
index 05a6b6b9770f2..83ce50def5ac9 100644
--- a/rust/kernel/miscdevice.rs
+++ b/rust/kernel/miscdevice.rs
@@ -13,16 +13,8 @@
     device::Device,
     error::{
         to_result,
-        Error,
-        Result,
         VTABLE_DEFAULT_ERROR, //
     },
-    ffi::{
-        c_int,
-        c_long,
-        c_uint,
-        c_ulong, //
-    },
     fs::{
         File,
         Kiocb, //
@@ -39,10 +31,7 @@
         Opaque, //
     },
 };
-use core::{
-    marker::PhantomData,
-    pin::Pin, //
-};
+use core::marker::PhantomData;
 
 /// Options for creating a misc device.
 #[derive(Copy, Clone)]

-- 
2.43.0

