From: Alvin Sun <alvin.sun@linux.dev>
Date: Thu, 21 May 2026 14:57:10 +0800
Subject: [PATCH v3 4/7] rust: block: mq: use vertical import style
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260521-miscdev-use-format-v3-4-56240ca70d0c@linux.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779346631; l=3793;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=ZAphU0EjCdGw+0Fm9VnI2fX2eOGjP3AWC7Pmb+1TUMI=;
 b=XSeo0tBnhXizXV7Nk+WflXtQgvWea8sorO+0ReAfL0gGMun5IB2Md7vSYxQfsT/0rlxp4YKyX
 pgMXn9NQKZ+BBHu3okQ8VkCi6FfSsbAYw4P/3SYdReboHUVS+zcAWIN
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert `use` imports to vertical layout for better readability and
maintainability.

Reviewed-by: Onur Özkan <work@onurozkan.dev>
Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 rust/kernel/block/mq/gen_disk.rs   | 21 +++++++++++++++++----
 rust/kernel/block/mq/operations.rs | 17 +++++++++++++----
 rust/kernel/block/mq/request.rs    | 14 ++++++++++----
 rust/kernel/block/mq/tag_set.rs    | 24 +++++++++++++++++++-----
 4 files changed, 59 insertions(+), 17 deletions(-)

diff --git a/rust/kernel/block/mq/gen_disk.rs b/rust/kernel/block/mq/gen_disk.rs
index 912cb805caf51..aac8ece10ae7c 100644
--- a/rust/kernel/block/mq/gen_disk.rs
+++ b/rust/kernel/block/mq/gen_disk.rs
@@ -7,14 +7,27 @@
 
 use crate::{
     bindings,
-    block::mq::{Operations, TagSet},
-    error::{self, from_err_ptr, Result},
-    fmt::{self, Write},
+    block::mq::{
+        Operations,
+        TagSet, //
+    },
+    error::{
+        self,
+        from_err_ptr,
+        Result, //
+    },
+    fmt::{
+        self,
+        Write, //
+    },
     prelude::*,
     static_lock_class,
     str::NullTerminatedFormatter,
     sync::Arc,
-    types::{ForeignOwnable, ScopeGuard},
+    types::{
+        ForeignOwnable,
+        ScopeGuard, //
+    }, //
 };
 
 /// A builder for [`GenDisk`].
diff --git a/rust/kernel/block/mq/operations.rs b/rust/kernel/block/mq/operations.rs
index 8ad46129a52c4..187b0b7791db9 100644
--- a/rust/kernel/block/mq/operations.rs
+++ b/rust/kernel/block/mq/operations.rs
@@ -6,11 +6,20 @@
 
 use crate::{
     bindings,
-    block::mq::{request::RequestDataWrapper, Request},
-    error::{from_result, Result},
+    block::mq::{
+        request::RequestDataWrapper,
+        Request, //
+    },
+    error::{
+        from_result,
+        Result, //
+    },
     prelude::*,
-    sync::{aref::ARef, Refcount},
-    types::ForeignOwnable,
+    sync::{
+        aref::ARef,
+        Refcount, //
+    },
+    types::ForeignOwnable, //
 };
 use core::marker::PhantomData;
 
diff --git a/rust/kernel/block/mq/request.rs b/rust/kernel/block/mq/request.rs
index ce3e30c81cb5e..66254d02bba65 100644
--- a/rust/kernel/block/mq/request.rs
+++ b/rust/kernel/block/mq/request.rs
@@ -9,13 +9,19 @@
     block::mq::Operations,
     error::Result,
     sync::{
-        aref::{ARef, AlwaysRefCounted},
+        aref::{
+            ARef,
+            AlwaysRefCounted, //
+        },
         atomic::Relaxed,
-        Refcount,
+        Refcount, //
     },
-    types::Opaque,
+    types::Opaque, //
+};
+use core::{
+    marker::PhantomData,
+    ptr::NonNull, //
 };
-use core::{marker::PhantomData, ptr::NonNull};
 
 /// A wrapper around a blk-mq [`struct request`]. This represents an IO request.
 ///
diff --git a/rust/kernel/block/mq/tag_set.rs b/rust/kernel/block/mq/tag_set.rs
index dae9df408a862..c1fd3e047af50 100644
--- a/rust/kernel/block/mq/tag_set.rs
+++ b/rust/kernel/block/mq/tag_set.rs
@@ -8,13 +8,27 @@
 
 use crate::{
     bindings,
-    block::mq::{operations::OperationsVTable, request::RequestDataWrapper, Operations},
-    error::{self, Result},
+    block::mq::{
+        operations::OperationsVTable,
+        request::RequestDataWrapper,
+        Operations, //
+    },
+    error::{
+        self,
+        Result, //
+    },
     prelude::try_pin_init,
-    types::Opaque,
+    types::Opaque, //
+};
+use core::{
+    convert::TryInto,
+    marker::PhantomData, //
+};
+use pin_init::{
+    pin_data,
+    pinned_drop,
+    PinInit, //
 };
-use core::{convert::TryInto, marker::PhantomData};
-use pin_init::{pin_data, pinned_drop, PinInit};
 
 /// A wrapper for the C `struct blk_mq_tag_set`.
 ///

-- 
2.43.0

