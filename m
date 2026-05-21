From: Alvin Sun <alvin.sun@linux.dev>
Date: Thu, 21 May 2026 14:57:08 +0800
Subject: [PATCH v3 2/7] samples: rust_misc_device: use vertical import
 style
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260521-miscdev-use-format-v3-2-56240ca70d0c@linux.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779346631; l=1490;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=puXfGCYwKj9KZoqq4lAslLMOxSLli8QKF89rbO5bupk=;
 b=AHgTxDJT97Y3J5pfw7L4ai9jDzXQPeuD8oxvnNpuHwocaCFUY9cWa78C33eUNr5/SwKw8TUGb
 duAVp36AC8eDUZ18UbQSfyrRvO36UgWBjNI+JapNeyZZhjXX8juPNhk
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert `use` imports to vertical layout for better readability and
maintainability.

Reviewed-by: Onur Özkan <work@onurozkan.dev>
Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 samples/rust/rust_misc_device.rs | 34 ++++++++++++++++++++++++++++------
 1 file changed, 28 insertions(+), 6 deletions(-)

diff --git a/samples/rust/rust_misc_device.rs b/samples/rust/rust_misc_device.rs
index 87a1fe63533ae..41e26c825060b 100644
--- a/samples/rust/rust_misc_device.rs
+++ b/samples/rust/rust_misc_device.rs
@@ -97,14 +97,36 @@
 
 use kernel::{
     device::Device,
-    fs::{File, Kiocb},
-    ioctl::{_IO, _IOC_SIZE, _IOR, _IOW},
-    iov::{IovIterDest, IovIterSource},
-    miscdevice::{MiscDevice, MiscDeviceOptions, MiscDeviceRegistration},
+    fs::{
+        File,
+        Kiocb, //
+    },
+    ioctl::{
+        _IO,
+        _IOC_SIZE,
+        _IOR,
+        _IOW, //
+    },
+    iov::{
+        IovIterDest,
+        IovIterSource, //
+    },
+    miscdevice::{
+        MiscDevice,
+        MiscDeviceOptions,
+        MiscDeviceRegistration, //
+    },
     new_mutex,
     prelude::*,
-    sync::{aref::ARef, Mutex},
-    uaccess::{UserSlice, UserSliceReader, UserSliceWriter},
+    sync::{
+        aref::ARef,
+        Mutex, //
+    },
+    uaccess::{
+        UserSlice,
+        UserSliceReader,
+        UserSliceWriter, //
+    },
 };
 
 const RUST_MISC_DEV_HELLO: u32 = _IO('|' as u32, 0x80);

-- 
2.43.0

