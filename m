From: Sophon Z <aiqubits@hotmail.com>
Date: Mon, 31 Aug 2026 14:04:37 +0800
Subject: [PATCH] rust: pci: Reject IRQ vector indices that do not fit in
 u32
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260831-fix-pci-irq-vector-index-truncation-v1-1-d63217d99b67@hotmail.com>
X-B4-Tracking: v=1; b=H4sIAHQZlWoC/yWNMQ6DMAwAv4I811ISBFT9CuqQJgbcIYATEBLi7
 3Xb8Ya7OyGTMGV4VCcI7Zx5Tgr2VkGYfBoJOSqDM64199riwAcugZFlxZ1CmQU5RTqwyJaCL+p
 j2zVuqLvGehNBS4uQar9L//xz3l5vtb9puK4PLIBAx4cAAAA=
X-Change-ID: 20260831-fix-pci-irq-vector-index-truncation-6752f3751a0d
To: Danilo Krummrich <dakr@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: linux-pci@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sophon Z <aiqubits@hotmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788156278; l=1555;
 i=aiqubits@hotmail.com; s=20260831; h=from:subject:message-id;
 bh=rcVDRPrSPnO1Ee98t164DOTONn63WizVtKhr1VeOh7E=;
 b=LgZKS9pMGXvpbAQyZ5Hry/cE3R8kl1Bl5vL+AIH8R4F7C5szyNioSICnCSc6RthNm2KJeSkLx
 CsOlwGpNTz9CfotyhIy50EhtQoOy0oJodwRebOr2/Sz9bYyplCx6cES
X-Developer-Key: i=aiqubits@hotmail.com; a=ed25519;
 pk=+mrkwQAyCCkZdVPpu+CBQr1VZQlkXa7/1WizfeSF/yg=
X-Endpoint-Received: by B4 Relay for aiqubits@hotmail.com/20260831 with auth_id=992
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IrqVectorRegistration::index() accepts a usize, but pci_irq_vector()
takes an unsigned int. On 64-bit architectures, casting an index
larger than u32::MAX wraps it before the PCI core can validate it.
In particular, u32::MAX + 1 becomes zero and can resolve to the first
allocated vector.

Use a checked conversion and return EINVAL when the index cannot be
represented by the C API.

Fixes: 2fb7755b0a7e ("rust: pci: resolve IRQ in index() and embed IrqRequest in IrqVector")

Signed-off-by: Sophon Z <aiqubits@hotmail.com>
---
 rust/kernel/pci/irq.rs | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/rust/kernel/pci/irq.rs b/rust/kernel/pci/irq.rs
index 6741046ec1c0..1bf91973cb1f 100644
--- a/rust/kernel/pci/irq.rs
+++ b/rust/kernel/pci/irq.rs
@@ -151,8 +151,10 @@ pub fn irq_type(&self) -> IrqType {
     /// [`Self::len()`].
     #[inline]
     pub fn index(&self, index: usize) -> Result<IrqVector<'_>> {
+        let index = u32::try_from(index).map_err(|_| EINVAL)?;
+
         // SAFETY: `self.dev.as_raw()` is a valid pointer to a `struct pci_dev`.
-        let irq = unsafe { bindings::pci_irq_vector(self.dev.as_raw(), index as u32) };
+        let irq = unsafe { bindings::pci_irq_vector(self.dev.as_raw(), index) };
         if irq < 0 {
             return Err(Error::from_errno(irq));
         }

---
base-commit: cee9395acd8043be0644b25c34bfa86623f2b935
change-id: 20260831-fix-pci-irq-vector-index-truncation-6752f3751a0d

Best regards,
--  
Sophon Z <aiqubits@hotmail.com>

