From: Alvin Sun <alvin.sun@linux.dev>
Date: Thu, 21 May 2026 14:57:13 +0800
Subject: [PATCH v3 7/7] rust: doctest: use vertical import style
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260521-miscdev-use-format-v3-7-56240ca70d0c@linux.dev>
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
 Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779346631; l=807;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=VBLRqj4ChOybBZhMTp5zBCaU6pJDNwNCjW29RUtQRLw=;
 b=QcsXlH4hnT+idKhT7B3U23jMM0PEsHmzqMMiWE+xKaoVssd1BspYb8wAMrz5YNZSh+ff7Z7ze
 moeSyg+d7XSDhMJUuPBOYHkqRfCIae0PSelX4W6aMGqsCxAz8gd4lnU
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert `use` imports to vertical layout for better readability and
maintainability.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 scripts/rustdoc_test_gen.rs | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/scripts/rustdoc_test_gen.rs b/scripts/rustdoc_test_gen.rs
index d61a77219a8c2..ee76e96b41eea 100644
--- a/scripts/rustdoc_test_gen.rs
+++ b/scripts/rustdoc_test_gen.rs
@@ -31,8 +31,15 @@
 use std::{
     fs,
     fs::File,
-    io::{BufWriter, Read, Write},
-    path::{Path, PathBuf},
+    io::{
+        BufWriter,
+        Read,
+        Write, //
+    },
+    path::{
+        Path,
+        PathBuf, //
+    }, //
 };
 
 /// Find the real path to the original file based on the `file` portion of the test name.

-- 
2.43.0

