From: Ethan Plant <plant.ethan@gmail.com>
Date: Tue, 04 Aug 2026 16:24:25 -0700
Subject: [PATCH] rust: pci: Mark Device refcount methods inline
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-inline-wrappers-v1-1-16916db867e5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMywqDMBBG4VeRWRuIIkF9ldKFl992RGKYsVUQ3
 92oy29xzk4KYSjVyU6CPyvPPiJLE+q+jf/AcB9Nuc2dLW1h2E/sYVZpQoCoGUpXtQ6FsxkoVkE
 w8HYfX+/H+mtHdMu1oeM4Ad+QKANzAAAA
X-Change-ID: 20260804-inline-wrappers-f869b6e4601e
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
 linux-kernel@vger.kernel.org, Ethan Plant <plant.ethan@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1692; i=plant.ethan@gmail.com;
 h=from:subject:message-id; bh=9Vpgdz4Y5wf49bgzEW37pW0bIiE7fP8d5f85n0neKYk=;
 b=owGbwMvMwCXmcODvRtktquaMp9WSGLKKSlY/ZivYJxtf+nl+7uG8UHEdiXvKPfsnWOqbzctv0
 SlI2PWso5SFQYyLQVZMkSX0y9T9W5PPeCx5K8UEM4eVCWQIAxenAEyEl5vhn+2S+wL1TXnHUkM/
 RM3KL0oODvaSCGhQjXsjWvHm4+xbuQz/kw58DxY7eDOn9/jptdcab4fKh0859+bgVLXpcs99lYy
 bmQE=
X-Developer-Key: i=plant.ethan@gmail.com; a=openpgp;
 fpr=55F495BFB563CC48A4ED1A0240C0FDB11DB42537
X-Endpoint-Received: by B4 Relay for plant.ethan@gmail.com/default with auth_id=917
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When building the kernel, the following Rust symbols are generated:
$ nm vmlinux | grep ' _R' | rustfilt | grep -E 'pci::Device.*(inc_ref|dec_ref)'
... T <kernel::pci::Device as kernel::sync::aref::AlwaysRefCounted>::dec_ref
... T <kernel::pci::Device as kernel::sync::aref::AlwaysRefCounted>::inc_ref

These Rust symbols are trivial wrappers around pci_dev_put() and
pci_dev_get(), respectively. It doesn't make sense to go through a
trivial wrapper for these functions, so mark them inline.

Suggested-by: Alice Ryhl <aliceryhl@google.com>
Link: https://github.com/Rust-for-Linux/linux/issues/1145
Signed-off-by: Ethan Plant <plant.ethan@gmail.com>
---
 rust/kernel/pci.rs | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/rust/kernel/pci.rs b/rust/kernel/pci.rs
index 5071cae6543f..3e80ec1160b3 100644
--- a/rust/kernel/pci.rs
+++ b/rust/kernel/pci.rs
@@ -482,11 +482,13 @@ impl<'a> crate::dma::Device<'a> for Device<device::Core<'a>> {}
 
 // SAFETY: Instances of `Device` are always reference-counted.
 unsafe impl crate::sync::aref::AlwaysRefCounted for Device {
+    #[inline]
     fn inc_ref(&self) {
         // SAFETY: The existence of a shared reference guarantees that the refcount is non-zero.
         unsafe { bindings::pci_dev_get(self.as_raw()) };
     }
 
+    #[inline]
     unsafe fn dec_ref(obj: NonNull<Self>) {
         // SAFETY: The safety requirements guarantee that the refcount is non-zero.
         unsafe { bindings::pci_dev_put(obj.cast().as_ptr()) }

---
base-commit: dc01dfb37b34beeefcfe1c3055364d41a4070c7e
change-id: 20260804-inline-wrappers-f869b6e4601e

Best regards,
--  
Ethan Plant <plant.ethan@gmail.com>

