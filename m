From: Markus Probst <markus.probst@posteo.de>
Date: Mon, 27 Apr 2026 20:05:41 +0200
Subject: [PATCH v6 1/4] rust: devres: return reference in
 `devres::register`
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260427-rust_serdev-v6-1-173798d5e1a3@posteo.de>
References: <20260427-rust_serdev-v6-0-173798d5e1a3@posteo.de>
In-Reply-To: <20260427-rust_serdev-v6-0-173798d5e1a3@posteo.de>
To: Rob Herring <robh@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Miguel Ojeda <ojeda@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Kari Argillander <kari.argillander@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, Boqun Feng <boqun@kernel.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Boqun Feng <boqun@kernel.org>
Cc: linux-serial@vger.kernel.org, linux-kernel@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, linux-pm@vger.kernel.org, 
 driver-core@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 Markus Probst <markus.probst@posteo.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2621;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=oQKYQhuICX5DBtHaowGZbnJGuwpyDpM+GsZaRCaIX4M=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBp76V9jveQ0d8UFFWCXH/ZYKXYbx1j5Z3L5kn+E
 Syf+XW02bKJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCae+lfRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9KVHhAAjJc7tGq49faeum6CZGHoCRQI0UaRoRu
 6SmBsvh1p2l28DUKaEn/dvKXyexu///bZNXPbFw/is3zD6RUn6CHPOmGQ/RHKq7Dhr9/yMCPKvb
 RwkRt/jgEL8fdG0R6doRrnQWtYVmu4CSv4H/mPq1LkoVbNv/6SSYrbhReWEpQyfzMk5ORou8Xhv
 0rEhZmD7zmItkdBdgSh/T08HvqEGCwQavXjQjGOetef8e8lrNYTZY/6GZwQWlsKycoJkmgsIuWV
 gX89cUjDlTCdkkAAWOolNHgJ7ejQOu2fo/vZ2KcDpyofLKla2fBZOw6i3T66sYb9IfnJ2m5aawQ
 ZjTq0BAbX1Lgs6BAQh3bq2UQ1aPzAzjm4usmDfXYzcbed0W5NIj9g/55sdRTJpOifmXmpHun++8
 kqKuTOjxGWpqtK1Vz+bFbjldF8iBvpo9n+D6C3uT/K1Pek7c4uqbZH2HMogF1WUCKX0RdVBa9j0
 VcTAh+543GRxWWoYH3cPkRWH4ya5bKfC4ZtvV4cQLhO8oePehDW6Ttj3P4FUK+fqAq0zjcdmIsa
 hfFR6O7+3AXDXYWISRlFV1O2z0PpctoL7fOBK/0qC4DO0ZXHUVhXCQWDR5KEXHfYBnMzkD2vnYk
 GyvJAqtOI42mCna/Hr9ypH/8EsZz9urdeQ7I21Po3E0TZHc0bhKU=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Return the reference to the initialized data in the `devres::register`
function.

This is needed in a following commit (rust: add basic serial device bus
abstractions).

Acked-by: Viresh Kumar <viresh.kumar@linaro.org>
Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
 rust/kernel/cpufreq.rs    |  3 ++-
 rust/kernel/devres.rs     | 15 +++++++++++++--
 rust/kernel/drm/driver.rs |  3 ++-
 3 files changed, 17 insertions(+), 4 deletions(-)

diff --git a/rust/kernel/cpufreq.rs b/rust/kernel/cpufreq.rs
index d8d26870bea2..e1228530598f 100644
--- a/rust/kernel/cpufreq.rs
+++ b/rust/kernel/cpufreq.rs
@@ -1052,7 +1052,8 @@ pub fn new_foreign_owned(dev: &Device<Bound>) -> Result
     where
         T: 'static,
     {
-        devres::register(dev, Self::new()?, GFP_KERNEL)
+        devres::register(dev, Self::new()?, GFP_KERNEL)?;
+        Ok(())
     }
 }
 
diff --git a/rust/kernel/devres.rs b/rust/kernel/devres.rs
index 9e5f93aed20c..d3c9c376693d 100644
--- a/rust/kernel/devres.rs
+++ b/rust/kernel/devres.rs
@@ -419,15 +419,26 @@ fn register_foreign<P>(dev: &Device<Bound>, data: P) -> Result
 /// }
 ///
 /// fn from_bound_context(dev: &Device<Bound>) -> Result {
-///     devres::register(dev, Registration::new(), GFP_KERNEL)
+///     devres::register(dev, Registration::new(), GFP_KERNEL)?;
+///     Ok(())
 /// }
 /// ```
-pub fn register<T, E>(dev: &Device<Bound>, data: impl PinInit<T, E>, flags: Flags) -> Result
+pub fn register<'a, T, E>(
+    dev: &'a Device<Bound>,
+    data: impl PinInit<T, E>,
+    flags: Flags,
+) -> Result<&'a T>
 where
     T: Send + 'static,
     Error: From<E>,
 {
     let data = KBox::pin_init(data, flags)?;
 
+    let data_ptr = &raw const *data;
+
     register_foreign(dev, data)
+        // SAFETY: `dev` is valid for the lifetime of 'a. As long as there is a reference to
+        // `Device<Bound>`, it is guaranteed that the device is not unbound and data has not been
+        // dropped. Thus `data_ptr` is also valid for the lifetime of 'a.
+        .map(|()| unsafe { &*data_ptr })
 }
diff --git a/rust/kernel/drm/driver.rs b/rust/kernel/drm/driver.rs
index 5233bdebc9fc..1edfd7bacddb 100644
--- a/rust/kernel/drm/driver.rs
+++ b/rust/kernel/drm/driver.rs
@@ -147,7 +147,8 @@ pub fn new_foreign_owned(
 
         let reg = Registration::<T>::new(drm, flags)?;
 
-        devres::register(dev, reg, GFP_KERNEL)
+        devres::register(dev, reg, GFP_KERNEL)?;
+        Ok(())
     }
 
     /// Returns a reference to the `Device` instance for this registration.

-- 
2.53.0

