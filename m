From: Markus Probst <markus.probst@posteo.de>
Date: Sat, 30 May 2026 03:13:49 +0200
Subject: [PATCH v8 1/5] rust: devres: return reference in
 `devres::register`
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260530-rust_serdev-v8-1-2a95f1da22a7@posteo.de>
References: <20260530-rust_serdev-v8-0-2a95f1da22a7@posteo.de>
In-Reply-To: <20260530-rust_serdev-v8-0-2a95f1da22a7@posteo.de>
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
 bh=040JEx0DJs+3yI1YzAd4eTxo71xnuIqutPJWJv523rI=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBqGjnPYjXoxu4XSUVvUyFrUA22UYYXUt1sBEHJy
 boxVAJjcqWJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCaho5zxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9I2Yw//XSEvApDXiC0aI/+tyQQXaC2WtluKDYJ
 q4pL6a7XX4I7V/C+yXIbvDd5fiPpzcHx8uBpkpbV5/7NA/vwAFU2El46OuNEOW9vM20K+XgKkOg
 XTBRmGFuI4wZKjridroUTHVMOaKGh2EPcLtnN8TPPBZ+PemcFluAH5r0fj6PyZHVRYiJcbfW+U0
 YTFyvzsL2oySHl43EElJUh7NdxPGhfBW+hPhDy8Gi8Car43qYTmbKTOf9t0mJhrAYuuVjNOenfP
 8gsSgDfcV8VQbaU7qbElj5mgCZ7eGGpkLIlwvK5k7q/kptLtlJNq5zVWNxPTLoHM3uZcKkNOVwi
 XssxOIHr62UU1Y4Pf0obE36CJYCFbMEkogte6SY2YOmIJjn7OKv9+qCGY233bgxbn5Jsrwnd0mr
 RuNzx53K60TXoMApp8NhOiCxc7JjeA7XI0bWU3Y21u5Ys2X8KCKtiVoN73WYwnyuyGsqhKr/q6O
 3DzN1n4ykSc53TzCYh/euLX7+1up/XS4UNaJ+JkNlMM1TgJ3RNYNXNbnpsmuhGLN3d1hcUzjl2a
 3OCeliEpqf6n6fCViEYxTvSE6qKmYY5nM5rU8XDxwnCs3CyGKuLQ0Ps2ne09H3wmXHhatXdkWMu
 pVD/Mg2jgx86QoJrcwLhv8KI1iEHPuv5YNPRySqtmZEdCNR8C2Bc=
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
index d94c6cdbc45a..bbbd4f54218a 100644
--- a/rust/kernel/cpufreq.rs
+++ b/rust/kernel/cpufreq.rs
@@ -1053,7 +1053,8 @@ pub fn new_foreign_owned(dev: &Device<Bound>) -> Result
     where
         T: 'static,
     {
-        devres::register(dev, Self::new()?, GFP_KERNEL)
+        devres::register(dev, Self::new()?, GFP_KERNEL)?;
+        Ok(())
     }
 }
 
diff --git a/rust/kernel/devres.rs b/rust/kernel/devres.rs
index 82cbd8b969fb..e3e954478caa 100644
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

