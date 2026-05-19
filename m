From: Alvin Sun <alvin.sun@linux.dev>
Date: Tue, 19 May 2026 13:34:42 +0800
Subject: [PATCH 2/2] samples: rust_misc_device: use vertical import style
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-miscdev-use-format-v1-2-11d526ba0edc@linux.dev>
References: <20260519-miscdev-use-format-v1-0-11d526ba0edc@linux.dev>
In-Reply-To: <20260519-miscdev-use-format-v1-0-11d526ba0edc@linux.dev>
To: Arnd Bergmann <arnd@arndb.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>
Cc: rust-for-linux@vger.kernel.org, Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779168918; l=1443;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=MzOQ5Pt5s4zhpYWvG5X1Gx7JCP+doFfRKRAXWizMD0s=;
 b=PhTXsILOq2s+5tTEFUo9io3ipRSI7Enl3eczdH5Q5o/rHdAnqvAlfdiH4ZwQn2Wht5ryUdViT
 DQ2nzApDszOBT03h8KplssmKqvv+iOlyE/s8Zx0I0E/S+QAk+Z7S4Py
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert `use` imports to vertical layout for better readability and
maintainability.

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

