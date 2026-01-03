From: SeungJong Ha <engineer.jjhama@gmail.com>
Date: Sat, 03 Jan 2026 14:38:50 +0000
Subject: [PATCH] rust: pci: add HeaderType enum and header_type() helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260103-add-rust-pci-header-type-v1-1-879b4d74b227@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPkpWWkC/x3MQQrDIBBG4avIrDugRgLJVUoXon+S2SQypqUle
 PdKlt/ivYsqVFBpNhcpPlLl2Dvcw1Da4r6CJXeTt360zg4cc2Z915NLEt4QM5TPXwEPYfRhSg7
 JBep5USzyvdfPV2t/4WGVIGoAAAA=
To: Danilo Krummrich <dakr@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>
Cc: linux-kernel@vger.kernel.org, linux-pci@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, SeungJong Ha <engineer.jjhama@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767451130; l=3232;
 i=engineer.jjhama@gmail.com; s=20260103; h=from:subject:message-id;
 bh=e2E4FhBSLeClmn+jWVL0WZmHkENN+PUZbPDhQoNtkk4=;
 b=XWFzV0h3yE2SOPThqJB98GlI0lv2RzQLCSus9cLyUDIbfpwW6sbnzuUnfVt3hJPcFVtwd3Qoi
 ggPUYgYQ0g6B8vzD2SeROuxPwThziziy+4DSpr9CTbgbN4MspyHoxec
X-Developer-Key: i=engineer.jjhama@gmail.com; a=ed25519;
 pk=G5nmjm+RTiWBpyCvc5xjR1b3li/2zipLSMyz+T4fj5E=
X-Endpoint-Received: by B4 Relay for engineer.jjhama@gmail.com/20260103 with auth_id=590
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the HeaderType enum to represent PCI configuration space header
types (Normal and Bridge). Also implement the header_type() method in
the Device struct to allow Rust PCI drivers to identify the device
type safely.

This is required for drivers to handle type-specific configuration
registers correctly.

Signed-off-by: SeungJong Ha <engineer.jjhama@gmail.com>
---
Hello,

This is my first patch to the Linux kernel, specifically targeting the 
Rust PCI subsystem. 

This patch introduces the HeaderType enum to represent PCI configuration 
space header types (Normal and Bridge) and implements the header_type() 
method in the Device struct.

I have followed the patch submission checklist, but as this is my first 
contribution, please let me know if I have missed any conventions or 
if there are areas for improvement.

Thank you for your time and review!

Best regards,
SeungJong Ha
---
 rust/kernel/pci.rs        | 10 ++++++++++
 rust/kernel/pci/header.rs | 31 +++++++++++++++++++++++++++++++
 2 files changed, 41 insertions(+)

diff --git a/rust/kernel/pci.rs b/rust/kernel/pci.rs
index 82e128431..90a0eb54f 100644
--- a/rust/kernel/pci.rs
+++ b/rust/kernel/pci.rs
@@ -31,10 +31,12 @@
     },
 };
 
+mod header;
 mod id;
 mod io;
 mod irq;
 
+pub use self::header::HeaderType;
 pub use self::id::{
     Class,
     ClassMask,
@@ -373,6 +375,14 @@ pub fn revision_id(&self) -> u8 {
         unsafe { (*self.as_raw()).revision }
     }
 
+    /// Returns the PCI header type.
+    #[inline]
+    pub fn header_type(&self) -> HeaderType {
+        // SAFETY: By its type invariant `self.as_raw` is always a valid pointer to a
+        // `struct pci_dev`.
+        HeaderType::from(unsafe { (*self.as_raw()).hdr_type })
+    }
+
     /// Returns the PCI bus device/function.
     #[inline]
     pub fn dev_id(&self) -> u16 {
diff --git a/rust/kernel/pci/header.rs b/rust/kernel/pci/header.rs
new file mode 100644
index 000000000..032efeb16
--- /dev/null
+++ b/rust/kernel/pci/header.rs
@@ -0,0 +1,31 @@
+// SPDX-License-Identifier: GPL-2.0
+
+//! PCI device header type definitions.
+//!
+//! This module contains PCI header type definitions
+
+use kernel::bindings;
+
+/// PCI device header types.
+#[derive(Debug, Clone, Copy, PartialEq, Eq)]
+pub enum HeaderType {
+    /// Normal PCI device header (Type 0)
+    NormalDevice,
+    /// PCI-to-PCI bridge header (Type 1)
+    PciToPciBridge,
+    /// CardBus bridge header (Type 2)
+    CardBusBridge,
+    /// Unknown or unsupported header type
+    Unknown,
+}
+
+impl From<u8> for HeaderType {
+    fn from(value: u8) -> Self {
+        match u32::from(value) & bindings::PCI_HEADER_TYPE_MASK {
+            bindings::PCI_HEADER_TYPE_NORMAL => HeaderType::NormalDevice,
+            bindings::PCI_HEADER_TYPE_BRIDGE => HeaderType::PciToPciBridge,
+            bindings::PCI_HEADER_TYPE_CARDBUS => HeaderType::CardBusBridge,
+            _ => HeaderType::Unknown,
+        }
+    }
+}

---
base-commit: f8f9c1f4d0c7a64600e2ca312dec824a0bc2f1da
change-id: 20260103-add-rust-pci-header-type-346249c1ec14

Best regards,
-- 
SeungJong Ha <engineer.jjhama@gmail.com>

