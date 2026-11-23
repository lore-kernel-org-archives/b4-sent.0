From: Peder Bergan <peder.bergan@gmail.com>
Date: Mon, 23 Nov 2026 17:43:32 +0100
Subject: [PATCH v3] rust: bindgen: Preserve sched_statistics alignment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-fix-schedstats-bindgen-layout-v3-1-ef7e83c32b42@gmail.com>
X-B4-Tracking: v=1; b=H4sIADNtBGsC/43OQW7CMBAF0KsgrzvFdkKQu+o9qi7G9iRxRRzkc
 SIQyt1rw4YdLP/oz9O/CaYUiMXX7iYSrYHDHEtoPnbCjRgHguBLFlrqTilloA8XYDeS54yZwYb
 oB4pwwuu8ZJCmOdiubdqjPIpinBOVh7v/8/vIvNg/crmitWGRCWzC6MZ6Ws6cE+G0TwtniHTJt
 TQGznO63leuqmLvDloVKJAHY7zXjex7/z1MGE6fbp5EHbTqJ03LV5oumnKtphaN6ZCetW3b/gG
 FBdU5TwEAAA==
X-Change-ID: 20261119-fix-schedstats-bindgen-layout-0935b6434707
To: Miguel Ojeda <ojeda@kernel.org>
Cc: Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Carlos Llamas <cmllamas@google.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 =?utf-8?q?Arve_Hj=C3=B8nnev=C3=A5g?= <arve@android.com>, 
 Todd Kjos <tkjos@android.com>, Christian Brauner <brauner@kernel.org>, 
 Jules Mercier <jules@les-mercier.fr>, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795452214; l=2194;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=BRNvzNrAOE8SCJYrQje8ClEabdCLlvZJpmkzsmH/zvc=;
 b=hvkGi2TTDZ5rlFhFS9Sj0TO7Yv3elJsXxiwEWUuUy1v46bGKVG2U1hni9P6f4iGj54YI5wpcU
 02BmMXJGqIiBrB9Eps8k5D56uMKDNX3AMpRzcykH7ZknPalLBFaALjG
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With CONFIG_SCHEDSTATS disabled, struct sched_statistics is empty but
still cache-line aligned. Bindgen omits the alignment of the empty
type. Bindgen 0.73.2 also stopped forcing padding before over-aligned
fields, so fields following stats can be misplaced in the generated
task_struct. On the reported arm64 build, Rust Binder reads the wrong
pointer via CurrentTask::mm() and rejects mmap() with -EINVAL.

Make sched_statistics opaque so bindgen uses the C size and alignment.
Rust has no callers that access the fields of this type.

Reported-by: Jules Mercier <jules@les-mercier.fr>
Closes: https://github.com/Rust-for-Linux/linux/issues/1269
Link: https://github.com/rust-lang/rust-bindgen/issues/3549
Tested-by: Jules Mercier <jules@les-mercier.fr>
Cc: stable@vger.kernel.org # 6.12.x
Signed-off-by: Peder Bergan <peder.bergan@gmail.com>
---
Changes in v3:

- I generalized the comment to cover any types listed below it.
- Link to v2: https://lore.kernel.org/rust-for-linux/20261120-fix-schedstats-bindgen-layout-v2-1-1c42e4a996ae@gmail.com/

OpenAI Codex assisted with the bindgen change, validation and drafting.
---
 rust/bindgen_parameters | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/rust/bindgen_parameters b/rust/bindgen_parameters
index 5bab3cf063360..ef9379312fce9 100644
--- a/rust/bindgen_parameters
+++ b/rust/bindgen_parameters
@@ -26,6 +26,12 @@
 # warning. We don't need to peek into it anyway.
 --opaque-type spinlock
 
+# Bindgen omits the alignment of empty structs. Bindgen 0.73.2 also stopped
+# forcing padding before over-aligned fields, so following fields can be
+# misplaced. Making the types below opaque preserves their C alignment.
+# https://github.com/rust-lang/rust-bindgen/issues/3549
+--opaque-type sched_statistics
+
 # enums that appear in indirect function calls should specify a cfi type
 --newtype-enum fwctl_rpc_scope
 --with-attribute-custom-enum=fwctl_rpc_scope='#[cfi_encoding="15fwctl_rpc_scope"]'

---
base-commit: aebb7274476403040d582c61478df8f4a7bf9cd3
change-id: 20261119-fix-schedstats-bindgen-layout-0935b6434707

Best regards,
--  
Peder Bergan <peder.bergan@gmail.com>

