From: Markus Probst <markus.probst@posteo.de>
Date: Wed, 29 Apr 2026 20:21:31 +0200
Subject: [PATCH v7 1/4] rust: devres: return reference in
 `devres::register`
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260429-rust_serdev-v7-1-0d89c791b5c8@posteo.de>
References: <20260429-rust_serdev-v7-0-0d89c791b5c8@posteo.de>
In-Reply-To: <20260429-rust_serdev-v7-0-0d89c791b5c8@posteo.de>
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
 bh=WeIHxGLl3ben5nPlGYSTDPnhSZ6gkaZU6qjHxa9zoas=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBp8kxHXcl87KQk/FOhBiSjoo0VnprhQggdANO36
 AgYdOfD6RmJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCafJMRxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9IY/A/+IyGPbtmOLFRgwtj/GlQ7g8tzolicOJn
 wubWvJ6t/9CVrOTh8mIfj7IW1IG+JFLEVxYNUlZAorXK5CB9t5p6sSF2GfOT+SVOsiOoKqmNodu
 CYeKrdqkbMt13b2C5Kc6qWsBp4oq2V+FEWe4/gRWwjnzN8BKFd/LaCc7aIt9TJwrljS5Bca36ot
 fzDPTzowuXS2Gfl0ZD8zawzhhnGFG+w+MMA/2dxvJcChbNDKKsVqeKD4hMaIK0JUJ3UDN9CTFtl
 XESAmGbH6DOc2gSng7f39nxmyD2EYc/HCdUZacK8phRXvGyBLNbAoFwzxNUQRGOw6tbnfXnebIu
 0apiXQJ3DAxwS55/f34KRaIkzcnQPtmH2KctGAJqxPYTlxvk7DyD1RyIUF6jxergi42+EMnKiEA
 Cl5PlP4nJmmbDR/5iVVLyWYhQDWXlx+IH/BPa+KW6pg9RLkmFwTWcLlQUFwd++rMG3/9Oxbka0/
 HtfI9FEKw9pGDZYHH+Bu6cRyfJvWa8uDZEBMQ9nFtDPmX6ovRgFXhIAzclxPLKSE83x2ykYtzl5
 iVc6sUZa7QJ0cbMe0hC1P9RiPPMIrsXLKTggV2uMWOuEgdsxJDAy4EZaS5cbPlx2gEW8/9KRZ39
 HcHPwhPCq3qTnSH3Ha32MX18UsEvw5h9O/wTzEnrLfqeebXcO9h8=
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
index ac59cdfd633c..1da80dc266dd 100644
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
index 6f3c58355d10..d01e186be381 100644
--- a/rust/kernel/devres.rs
+++ b/rust/kernel/devres.rs
@@ -438,15 +438,26 @@ fn register_foreign<P>(dev: &Device<Bound>, data: P) -> Result
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

