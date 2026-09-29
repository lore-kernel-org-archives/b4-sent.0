From: Ke Sun <sunke@kylinos.cn>
Date: Tue, 29 Sep 2026 10:15:59 +0800
Subject: [PATCH v3 09/11] rust: device: expose dma_coherent()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260929-tyr-ioctls-v3-9-26955fb111d5@kylinos.cn>
References: <20260929-tyr-ioctls-v3-0-26955fb111d5@kylinos.cn>
In-Reply-To: <20260929-tyr-ioctls-v3-0-26955fb111d5@kylinos.cn>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Lorenzo Stoakes <ljs@kernel.org>, "Liam R. Howlett" <liam@infradead.org>, 
 Lyude Paul <lyude@redhat.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>
Cc: Sami Tolvanen <samitolvanen@google.com>, rust-for-linux@vger.kernel.org, 
 linux-mm@kvack.org, dri-devel@lists.freedesktop.org, 
 driver-core@lists.linux.dev, Ke Sun <sunke@kylinos.cn>, 
 Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790648153; l=1677;
 i=sunke@kylinos.cn; s=20260317; h=from:subject:message-id;
 bh=XfO2LPkTwSiEqM7hoqHCFQ6seVfT+uG3TPffKXpZyws=;
 b=dlpNSCMDn8r/2tfOALYXZiv/AaY/jqC+xKDE9iLPr5YqZoce/oETuwi7HSo5W03jtXpN3XtbH
 Km/IKZIqgLWBW2YiTLEF/VwGN4M6hFlGcgepPAdJlqvcXNJoV3Hp+Hu
X-Developer-Key: i=sunke@kylinos.cn; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for sunke@kylinos.cn/20260317 with auth_id=950
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sami Tolvanen <samitolvanen@google.com>

A driver may need to know whether its device is DMA-coherent, but
rust/kernel exposes no accessor for the attribute today.

Add a thin accessor on Device<Bound> that wraps device_get_dma_attr()
and returns true only for DEV_DMA_COHERENT. The other attribute values
(unset, non-coherent) are treated as non-coherent.

Signed-off-by: Sami Tolvanen <samitolvanen@google.com>
Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 rust/kernel/device.rs | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/rust/kernel/device.rs b/rust/kernel/device.rs
index 2291d85b6849e..57950aa71f33e 100644
--- a/rust/kernel/device.rs
+++ b/rust/kernel/device.rs
@@ -260,6 +260,22 @@ pub unsafe fn drvdata_borrow<T>(&self) -> Pin<&T> {
     }
 }
 
+impl Device<Bound> {
+    /// Returns `true` if the device is reported as DMA-coherent by firmware.
+    ///
+    /// This wraps `device_get_dma_attr()` and only returns `true` for the
+    /// `DEV_DMA_COHERENT` attribute. Devices for which no DMA attribute is
+    /// reported (`DEV_DMA_NOT_SUPPORTED`) or which are explicitly flagged as
+    /// non-coherent (`DEV_DMA_NON_COHERENT`) are treated as non-coherent.
+    #[inline]
+    pub fn dma_coherent(&self) -> bool {
+        // SAFETY: By the type invariants, `self.as_raw()` is a valid pointer
+        // to a `struct device`.
+        let attr = unsafe { bindings::device_get_dma_attr(self.as_raw()) };
+        attr == bindings::dev_dma_attr_DEV_DMA_COHERENT
+    }
+}
+
 impl<Ctx: DeviceContext> Device<Ctx> {
     /// Obtain the raw `struct device *`.
     pub(crate) fn as_raw(&self) -> *mut bindings::device {

-- 
2.43.0

