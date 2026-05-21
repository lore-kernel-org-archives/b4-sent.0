From: Alvin Sun <alvin.sun@linux.dev>
Date: Thu, 21 May 2026 14:57:07 +0800
Subject: [PATCH v3 1/7] rust: miscdevice: use vertical import style
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260521-miscdev-use-format-v3-1-56240ca70d0c@linux.dev>
References: <20260521-miscdev-use-format-v3-0-56240ca70d0c@linux.dev>
In-Reply-To: <20260521-miscdev-use-format-v3-0-56240ca70d0c@linux.dev>
To: Arnd Bergmann <arnd@arndb.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Brendan Higgins <brendan.higgins@linux.dev>, David Gow <david@davidgow.net>, 
 Rae Moar <raemoar63@gmail.com>
Cc: rust-for-linux@vger.kernel.org, linux-block@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, kunit-dev@googlegroups.com, 
 Alvin Sun <alvin.sun@linux.dev>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779346631; l=1454;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=m1EAr4ayyi4PZbyexLDSnvqug8qI7CL7WNOpMU9eF+A=;
 b=8T1vx1s1VmH35F1FrgNNRC6xE9XlmnV7pJAOkySzqQ2GoLAZ37pb3nRmBzuA26PUPfYJlTJCp
 Re7cVT6TddCAgHDS2FQK2dj/2OHnIREGXSsbh3u+/0l0S3Y9HXXxPpd
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert `use` imports to vertical layout for better readability and
maintainability.

Reviewed-by: Onur Özkan <work@onurozkan.dev>
Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 rust/kernel/miscdevice.rs | 34 ++++++++++++++++++++++++++++------
 1 file changed, 28 insertions(+), 6 deletions(-)

diff --git a/rust/kernel/miscdevice.rs b/rust/kernel/miscdevice.rs
index c3c2052c92069..05a6b6b9770f2 100644
--- a/rust/kernel/miscdevice.rs
+++ b/rust/kernel/miscdevice.rs
@@ -11,16 +11,38 @@
 use crate::{
     bindings,
     device::Device,
-    error::{to_result, Error, Result, VTABLE_DEFAULT_ERROR},
-    ffi::{c_int, c_long, c_uint, c_ulong},
-    fs::{File, Kiocb},
-    iov::{IovIterDest, IovIterSource},
+    error::{
+        to_result,
+        Error,
+        Result,
+        VTABLE_DEFAULT_ERROR, //
+    },
+    ffi::{
+        c_int,
+        c_long,
+        c_uint,
+        c_ulong, //
+    },
+    fs::{
+        File,
+        Kiocb, //
+    },
+    iov::{
+        IovIterDest,
+        IovIterSource, //
+    },
     mm::virt::VmaNew,
     prelude::*,
     seq_file::SeqFile,
-    types::{ForeignOwnable, Opaque},
+    types::{
+        ForeignOwnable,
+        Opaque, //
+    },
+};
+use core::{
+    marker::PhantomData,
+    pin::Pin, //
 };
-use core::{marker::PhantomData, pin::Pin};
 
 /// Options for creating a misc device.
 #[derive(Copy, Clone)]

-- 
2.43.0

