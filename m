From: Alvin Sun <alvin.sun@linux.dev>
Date: Tue, 19 May 2026 14:26:14 +0800
Subject: [PATCH 2/8] rust: driver: make `DriverModule` struct pub(crate) in
 `module_driver!`
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-fix-fops-owner-v1-2-2ded9830da14@linux.dev>
References: <20260519-fix-fops-owner-v1-0-2ded9830da14@linux.dev>
In-Reply-To: <20260519-fix-fops-owner-v1-0-2ded9830da14@linux.dev>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Luis Chamberlain <mcgrof@kernel.org>, 
 Petr Pavlu <petr.pavlu@suse.com>, Daniel Gomez <da.gomez@kernel.org>, 
 Sami Tolvanen <samitolvanen@google.com>, Aaron Tomlin <atomlin@atomlin.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Arnd Bergmann <arnd@arndb.de>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-modules@vger.kernel.org, driver-core@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, nova-gpu@lists.linux.dev, 
 Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779171975; l=796;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=vfc7PEfuAeEjqo+PGe1GnSXUHGllBagvhexmLDwXXe8=;
 b=iHl0SVhJNpVhuwZ7fh48egK9TuW+0iU+YW7qNL4AsNI9HBq33i2CD/EuLLetzk/gmObncqGZY
 c1YeH3GB4bhDdkz58UDUJs4GIxBetIU7CQNTcDd16LTUVxnj/j/Y7aw
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Expose the generated `DriverModule` struct as `pub(crate)` so that
driver implementations can reference it via `super::DriverModule`
for the `ThisModule` associated type.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 rust/kernel/driver.rs | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/rust/kernel/driver.rs b/rust/kernel/driver.rs
index 36de8098754d0..9c7c69c4d2af0 100644
--- a/rust/kernel/driver.rs
+++ b/rust/kernel/driver.rs
@@ -253,7 +253,7 @@ macro_rules! module_driver {
         type Ops<$gen_type> = $driver_ops;
 
         #[$crate::prelude::pin_data]
-        struct DriverModule {
+        pub(crate) struct DriverModule {
             #[pin]
             _driver: $crate::driver::Registration<Ops<$type>>,
         }

-- 
2.43.0

