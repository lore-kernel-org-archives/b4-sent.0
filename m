From: Peder Bergan <peder.bergan@gmail.com>
Date: Thu, 19 Nov 2026 20:33:07 +0100
Subject: [PATCH] rust: bindgen: Preserve sched_statistics alignment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-fix-schedstats-bindgen-layout-v1-1-0599dd230ffd@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPJO/2oC/yWMQQ6CMBBFr0Jm7UQKCMGrEBdtGaFGC+lMDYZwd
 1tdvp//3g5MwRHDtdgh0NuxW3wCdSrAztpPhG5MDFVZtUqpHu9uQ7YzjSxaGI3z40Qen/qzRMG
 yry+mbeqmKztIjTVQEn794fZnjuZBVnI0P4xmQhO0t3Oe4soSSL/OIbKgp03gOL7Z1CCbpgAAA
 A==
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
 Carlos Llamas <cmllamas@google.com>, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795116790; l=2061;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=enj6BUb4oRB8IE5yaVUAOv95G/2SRaL0ZVC/+tCgiiM=;
 b=rQs8CAyFUbEYInVCLSgBlAGhq9GORNTkDMbyOCPP/Y82UJOutZ4Y4O+RHHUn0zap6mInfzx3F
 mgGOYtrg3ocBebFeSG9AqC66FX9RCOAL1h+Uq3/fJkAHzUUVQtnKBAD
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With CONFIG_SCHEDSTATS disabled, struct sched_statistics is empty but
still cache-line aligned. Bindgen emits the empty definition without
that alignment. On affected builds this misplaces fields following
stats in the generated task_struct. In the reported arm64 build, Rust
Binder reads the wrong pointer via CurrentTask::mm() and rejects mmap()
with -EINVAL.

Make sched_statistics opaque so bindgen uses the C size and alignment.
Rust has no callers that access the fields of this type.

Fixes: 313c4281bc9d ("rust: add basic `Task`")
Closes: https://github.com/Rust-for-Linux/linux/issues/1269
Cc: stable@vger.kernel.org
Signed-off-by: Peder Bergan <peder.bergan@gmail.com>
---
Jules Mercier reported the layout mismatch on arm64.

On arm64 with bindgen 0.73.2 and CONFIG_SCHEDSTATS=n, the generated Rust
binding placed task_struct.mm at offset 1168 while the C layout placed
it at 1208. After the change both report 1208. The layouts also agree
with CONFIG_SCHEDSTATS=y, and the Rust kernel crate and Binder driver
build with Clippy in both configurations.

OpenAI Codex assisted with the bindgen change, validation and drafting.
---
 rust/bindgen_parameters | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/rust/bindgen_parameters b/rust/bindgen_parameters
index 5bab3cf063360..2686687555af3 100644
--- a/rust/bindgen_parameters
+++ b/rust/bindgen_parameters
@@ -26,6 +26,10 @@
 # warning. We don't need to peek into it anyway.
 --opaque-type spinlock
 
+# Bindgen drops the alignment of empty structs. Keep the cache-line alignment
+# of sched_statistics when CONFIG_SCHEDSTATS is disabled.
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

