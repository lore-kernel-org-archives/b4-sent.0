From: Sophon Zhang <aiqubits@hotmail.com>
Date: Tue, 01 Sep 2026 01:09:53 +0800
Subject: [PATCH v4] rust: pci: reject IRQ vector indices that do not fit in
 u32
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260901-fix-pci-irq-vector-index-truncation-v4-1-f94aa6932fd9@hotmail.com>
X-B4-Tracking: v=1; b=H4sIAGC1lWoC/53OPQ7CMAwF4KugzBjlpySUiXsghpAYagQtJCUCo
 d4dFybEBOOT/L7nh8iYCLNYTh4iYaFMXcuhmk5EaHy7R6DIWWiprVwYBTu6wTkQULpAwdB3Cai
 NeIM+Xdvge+6DdXO9M26uvIyCpXNCrr1W1pt3ztftgdsjPV40lFm6v94oarz7bbEoUBCt0crFu
 t5at2q6/uTpOAvdSYybRf+halYraSR65yrr62/V/KEaVr1W7C6qqCV+qsMwPAH8zWrBlgEAAA=
 =
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
 linux-kernel@vger.kernel.org, Sophon Zhang <aiqubits@hotmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788196549; l=2550;
 i=aiqubits@hotmail.com; s=20260831; h=from:subject:message-id;
 bh=aDpWwnCHJqNDAl+iMV/Pt6CcKak8JY7tJ57zkb1ld5w=;
 b=NHZdgqGpnU8lETGIZIzu3ZLXvJ5MUb7qp3HPbYOF5EZ6zD3TUOvdD19e2lx9OaKdyoL8P9bx0
 oXZbGHZhaj/BBqC18cpsZ4tDH2lJz928e3nN1ux9aBvnlhVV2c3sNI9
X-Developer-Key: i=aiqubits@hotmail.com; a=ed25519;
 pk=+mrkwQAyCCkZdVPpu+CBQr1VZQlkXa7/1WizfeSF/yg=
X-Endpoint-Received: by B4 Relay for aiqubits@hotmail.com/20260831 with auth_id=992
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IrqVectorRegistration::index() accepts a usize, but pci_irq_vector()
takes an unsigned int. On 64-bit architectures, casting an index larger
than u32::MAX wraps it before the PCI core can validate it. In
particular, u32::MAX + 1 becomes zero and can resolve to the first
allocated vector.

Use a checked conversion and return EINVAL when the index cannot be
represented by the C API.

Fixes: 2fb7755b0a7e ("rust: pci: resolve IRQ in index() and embed IrqRequest in IrqVector")
Signed-off-by: Sophon Zhang <aiqubits@hotmail.com>
---
Prevent 64-bit Rust IRQ vector indices from wrapping when they cross the
PCI C API boundary.
---
Changes in v4:
- Drop the explicit length check in favor of PCI core range validation.
- Use the existing TryFromIntError-to-Error conversion directly.
- Keep commit trailers adjacent and narrow the description to truncation.
- Link to v3: https://patch.msgid.link/20260831-fix-pci-irq-vector-index-truncation-v3-1-a2103084d20e@hotmail.com

Changes in v3:
- Check the index against the allocated vector count before entering the C API.
- Keep the checked usize-to-u32 conversion and document the C-side warning.
- Link to v2: https://patch.msgid.link/20260831-fix-pci-irq-vector-index-truncation-v2-1-4030ea7746a9@hotmail.com

Changes in v2:
- No code changes.
- Link to v1: https://patch.msgid.link/20260831-fix-pci-irq-vector-index-truncation-v1-1-d63217d99b67@hotmail.com

Testing:
- make rustfmtcheck
- Not build- or hardware-tested; bindgen is unavailable in the test environment.
---
 rust/kernel/pci/irq.rs | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/rust/kernel/pci/irq.rs b/rust/kernel/pci/irq.rs
index 6741046ec1c0..22e2cdf82a21 100644
--- a/rust/kernel/pci/irq.rs
+++ b/rust/kernel/pci/irq.rs
@@ -151,8 +151,10 @@ pub fn irq_type(&self) -> IrqType {
     /// [`Self::len()`].
     #[inline]
     pub fn index(&self, index: usize) -> Result<IrqVector<'_>> {
+        let index = u32::try_from(index)?;
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
Sophon Zhang <aiqubits@hotmail.com>

