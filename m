From: Markus Probst <markus.probst@posteo.de>
Date: Fri, 13 Mar 2026 20:03:05 +0100
Subject: [PATCH v3 1/7] rust: Add `parent_unchecked` function to `Device`
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260313-synology_microp_initial-v3-1-ad6ac463a201@posteo.de>
References: <20260313-synology_microp_initial-v3-0-ad6ac463a201@posteo.de>
In-Reply-To: <20260313-synology_microp_initial-v3-0-ad6ac463a201@posteo.de>
To: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, "Rafael J. Wysocki" <rafael@kernel.org>, 
 Igor Korotin <igor.korotin.linux@gmail.com>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Len Brown <lenb@kernel.org>, 
 Robert Moore <robert.moore@intel.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, driver-core@lists.linux.dev, 
 linux-pci@vger.kernel.org, linux-leds@vger.kernel.org, 
 linux-acpi@vger.kernel.org, acpica-devel@lists.linux.dev, 
 Markus Probst <markus.probst@posteo.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2195;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=HETHM3CRJWMhkQNDAYTp+649XpdPAf3ubTc2qfzj0Cs=;
 b=owEBiAJ3/ZANAwAIATR2H/jnrUPSAcsmYgBptF9xtg7fm3QCPAN84bfAyXYLoytkYJX0Zk1Hy
 ocxzpV75O+JAk4EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCabRfcRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMSwyLDIACgkQNHYf+OetQ9KYOw/3QgAiL7JIEEzv95AJctnhTBiyqFlBvmt
 2rYNF7VZNwNIed5G49vPESuPgVmNr8Z/SKmK0QDdCrgbdBcGQ232hAi3TZA5+z50m5hZF9MzUfX
 FJsJIqKyynUuiiViozr4rBz1j/OfxU+le1/EvUc3IByZmJyPKfBWlQPBo4UKNZXTVeP7bVP1OQC
 c7UW5Ws0APSe807FqjLTv2H2KyaKod6o/PwtK8xHp3NpCF/3dLcUlL2GNAvk28tw8Sy5dqOTbay
 7OAEZsnYWgVyx9IPv4psnSXNA1naehGefhF/YGSd2eptg9XBYex2+rSPWvkdDy9tn4OM0YDX/3b
 eQFXWugSsZ7H5D32NOVC3b+S6TVFpfiyozUnPWVT5XGnDiY92+FUn5d8flLyF5OfOqXXtVyi7t2
 zhfHnz4w5VUybSv914BmvPsDhGFJgBp9UiZKXQYY+xLPonzOiWNlGq5daufj3u7tvBI5nGUJCLl
 2KAAlo59pXQt3yYBomdV0cGNXb9gWP8T8Aeiu1NC/7KsTImCU+1g88pcyEGCRwRDvDQ1CodcFEy
 xlt0+ejIXt4gMnZVcdRma/+ybL6zuVQZ6NnTm1OpOsswdHLVU7osmsE8C/XgCoGp1lRd61kzgVm
 BWSIIESxX4PNUz1zTxKUwcSLLBF/tZtanQoc/8+gnPqAzJOcm7A==
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This allows mfd sub-devices to access the bus device of their parent.

The existing safe `parent` function has been made public for
consistency.

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
 rust/kernel/device.rs | 25 +++++++++++++++++++++++--
 1 file changed, 23 insertions(+), 2 deletions(-)

diff --git a/rust/kernel/device.rs b/rust/kernel/device.rs
index 94e0548e7687..a53fb8a388e8 100644
--- a/rust/kernel/device.rs
+++ b/rust/kernel/device.rs
@@ -340,8 +340,7 @@ pub(crate) fn as_raw(&self) -> *mut bindings::device {
     }
 
     /// Returns a reference to the parent device, if any.
-    #[cfg_attr(not(CONFIG_AUXILIARY_BUS), expect(dead_code))]
-    pub(crate) fn parent(&self) -> Option<&Device> {
+    pub fn parent(&self) -> Option<&Device> {
         // SAFETY:
         // - By the type invariant `self.as_raw()` is always valid.
         // - The parent device is only ever set at device creation.
@@ -358,6 +357,28 @@ pub(crate) fn parent(&self) -> Option<&Device> {
         }
     }
 
+    /// Returns a reference to the parent device as bus device.
+    ///
+    /// # Safety
+    ///
+    /// Callers must ensure that the device has a parent, that is contained in `T`.
+    pub unsafe fn parent_unchecked<T: AsBusDevice<Ctx>>(&self) -> &T {
+        // SAFETY:
+        // - By the type invariant `self.as_raw()` is always valid.
+        // - The parent device is only ever set at device creation.
+        let parent_raw = unsafe { (*self.as_raw()).parent };
+
+        // SAFETY:
+        // - The safety requirements guarantee that the device has a parent, thus `parent_raw`
+        //   must be a pointer to a valid `struct device`.
+        // - `parent_raw` is valid for the lifetime of `self`, since a `struct device` holds a
+        //   reference count of its parent.
+        let parent = unsafe { Device::from_raw(parent_raw) };
+
+        // SAFETY: The safety requirements guarantee that the parent device is contained in `T`.
+        unsafe { T::from_device(parent) }
+    }
+
     /// Convert a raw C `struct device` pointer to a `&'a Device`.
     ///
     /// # Safety

-- 
2.52.0

