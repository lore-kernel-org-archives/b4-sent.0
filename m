From: Sophon Z <aiqubits@hotmail.com>
Date: Mon, 31 Aug 2026 15:17:23 +0800
Subject: [PATCH v3] rust: pci: reject out-of-bounds IRQ vector indices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260831-fix-pci-irq-vector-index-truncation-v3-1-a2103084d20e@hotmail.com>
X-B4-Tracking: v=1; b=H4sIAIIqlWoC/52Oyw6CMBREf4V07TV9QCuu/A/jorRFrlHAFhoM4
 d8tuHKpy0nmnJmZBOfRBXLMZuJdxIBdm4LYZcQ0ur06QJsy4ZRLehAMapygNwjonxCdGToP2Fo
 3weDH1ugh8SBVwWuhCqapJcnUe5ewbeV8+eQwVrdEr+q10WBIptd2I7K199tiZMDASsGZsmVZS
 XVquuGh8b433YOsm5H/YeXJmlNBnVYql7r8ti7L8gYq84LHQAEAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788160663; l=2325;
 i=aiqubits@hotmail.com; s=20260831; h=from:subject:message-id;
 bh=q7Zm+tHJ83aYtHwXNQYwQQlGYVanZgLxBbtlE0DIgk0=;
 b=Jv+3UActeQjNzoPkK5JF3kjtz1JTxK/LXce9OMyQqfs63ERYV8JaPSh4DIJjyl4r5om9z5q+v
 qzZnXc6F/+VCSmHXOylWgFzNM7Hox6LLi1zpe3WpSOp1sHW+BG05/XS
X-Developer-Key: i=aiqubits@hotmail.com; a=ed25519;
 pk=+mrkwQAyCCkZdVPpu+CBQr1VZQlkXa7/1WizfeSF/yg=
X-Endpoint-Received: by B4 Relay for aiqubits@hotmail.com/20260831 with auth_id=992
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IrqVectorRegistration::index() accepts a usize and documents that
out-of-bounds indices return EINVAL, while pci_irq_vector() takes an
unsigned int.

Casting an index larger than u32::MAX wraps it before the PCI core can
validate it. In particular, u32::MAX + 1 becomes zero and can resolve to
the first allocated vector. Values that fit in u32 but exceed
MSI_MAX_INDEX can also reach msi_domain_get_virq() and trigger
WARN_ON_ONCE.

Check the index against the registration length before entering the C
API, and keep the usize-to-u32 conversion checked so the ABI boundary
does not rely on an unchecked cast.

Fixes: 2fb7755b0a7e ("rust: pci: resolve IRQ in index() and embed IrqRequest in IrqVector")

Signed-off-by: Sophon Z <aiqubits@hotmail.com>
---
Changes in v3:
- Check the index against the allocated vector count before entering the C API.
- Keep the checked usize-to-u32 conversion and document the C-side warning.
- Link to v2: https://patch.msgid.link/20260831-fix-pci-irq-vector-index-truncation-v2-1-4030ea7746a9@hotmail.com

Changes in v2:
- No code changes.
- Link to v1: https://patch.msgid.link/20260831-fix-pci-irq-vector-index-truncation-v1-1-d63217d99b67@hotmail.com
---
 rust/kernel/pci/irq.rs | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/rust/kernel/pci/irq.rs b/rust/kernel/pci/irq.rs
index 6741046ec1c0..dfab323f26f7 100644
--- a/rust/kernel/pci/irq.rs
+++ b/rust/kernel/pci/irq.rs
@@ -151,8 +151,14 @@ pub fn irq_type(&self) -> IrqType {
     /// [`Self::len()`].
     #[inline]
     pub fn index(&self, index: usize) -> Result<IrqVector<'_>> {
+        if index >= self.len.get() {
+            return Err(EINVAL);
+        }
+
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

