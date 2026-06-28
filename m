From: SeungJong Ha <engineer.jjhama@gmail.com>
Date: Sun, 28 Jun 2026 17:10:15 +0000
Subject: [PATCH RFC 2/4] rust: prelude: re-export `zerocopy::Immutable`
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260628-dma-zerocopy-bridge-v1-2-9a2895ebe30d@gmail.com>
References: <20260628-dma-zerocopy-bridge-v1-0-9a2895ebe30d@gmail.com>
In-Reply-To: <20260628-dma-zerocopy-bridge-v1-0-9a2895ebe30d@gmail.com>
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
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 nova-gpu@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 SeungJong Ha <engineer.jjhama@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782666615; l=753;
 i=engineer.jjhama@gmail.com; s=20260103; h=from:subject:message-id;
 bh=0Joli7btSCpMuF0CGmnSjjLbowNlizxBxdLc5J1Eq4M=;
 b=f2bwTmIStE9+jdLSuE6+34IUR9IVAiS5LuzvRuZ9oslpEwm8G7tsJ9qs1YBkr1SYlJqDirm90
 +PqvX+Dh3/CBx0rJrm0SCj7Sa/l0b9LoCNuwdntS95Box1o9sZz6ntZ
X-Developer-Key: i=engineer.jjhama@gmail.com; a=ed25519;
 pk=G5nmjm+RTiWBpyCvc5xjR1b3li/2zipLSMyz+T4fj5E=
X-Endpoint-Received: by B4 Relay for engineer.jjhama@gmail.com/20260103 with auth_id=590
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

`impl_transmute_via_zerocopy!` requires `Immutable` (no interior
mutability) alongside `FromBytes`/`IntoBytes`. Re-export it from the
prelude like the other two.

Assisted-by: Claude-Code:claude-opus-4-8
Signed-off-by: SeungJong Ha <engineer.jjhama@gmail.com>
---
 rust/kernel/prelude.rs | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/rust/kernel/prelude.rs b/rust/kernel/prelude.rs
index ca396f1f78a6..3db51c972bde 100644
--- a/rust/kernel/prelude.rs
+++ b/rust/kernel/prelude.rs
@@ -63,12 +63,14 @@
 #[doc(no_inline)]
 pub use zerocopy::{
     FromBytes,
+    Immutable,
     IntoBytes, //
 };
 
 #[doc(no_inline)]
 pub use zerocopy_derive::{
     FromBytes,
+    Immutable,
     IntoBytes, //
 };
 

-- 
2.54.0

