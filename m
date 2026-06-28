From: SeungJong Ha <engineer.jjhama@gmail.com>
Subject: [PATCH RFC 0/4] rust: dma: bridge zerocopy-derived types into the
 transmute byte-safety bound
Date: Sun, 28 Jun 2026 17:10:13 +0000
Message-Id: <20260628-dma-zerocopy-bridge-v1-0-9a2895ebe30d@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHVVQWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDMyML3ZTcRN2q1KL85PyCSt2koswUoJKUZMNkS7MkM0OD5DQloM6CotS
 0zAqwqdFKQW7OSrEQweLSpKzU5BKQeUq1tQCn5ynvfAAAAA==
X-Change-ID: 20260628-dma-zerocopy-bridge-dc1c96b610cf
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782666615; l=2202;
 i=engineer.jjhama@gmail.com; s=20260103; h=from:subject:message-id;
 bh=PwlNzx3K3F56o2BD0ftoa1LBSTs0jszR297NCpWnCn8=;
 b=q7/VLPO9r7B4lnh9Bj4NW2kqXARN2Q6xgsnTBNKtxvVcYdLqm34c8NDzA9nV/lZBN23maujdg
 xt7Eb5HhZbqB8cxIrCIRuanFyZSLI/OySSfbWlBPbWgOB3L4sD+opGK
X-Developer-Key: i=engineer.jjhama@gmail.com; a=ed25519;
 pk=G5nmjm+RTiWBpyCvc5xjR1b3li/2zipLSMyz+T4fj5E=
X-Endpoint-Received: by B4 Relay for engineer.jjhama@gmail.com/20260103 with auth_id=590
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DMA-coherent allocations (CoherentAllocation/Coherent/dma::Pool) bound
their element type on kernel::transmute::{AsBytes, FromBytes}. This RFC
lets a type satisfy that bound by deriving zerocopy's byte-safety traits
instead of a hand-written unsafe impl.

The bound cannot be switched to zerocopy wholesale (some DMA structs are
unions that IntoBytes cannot derive), and a blanket bridge impl is
rejected by coherence. So the series bridges the two per type:

  1. add the bridge macro impl_transmute_via_zerocopy!, which emits the
     transmute impls only for a zerocopy-derived type.
  2. re-export zerocopy::Immutable from the prelude.
  3-4. worked example: convert nova-core's GspMem and msgq POD types.

This series was prepared with the Claude Code AI assistant (model
claude-opus-4-8): it drafted the macro, the nova-core conversion and the
changelogs, which the submitter reviewed and takes responsibility for. It
was verified by building nova-core on rust-next and a negative test
confirming IntoBytes rejects mis-sized padding. See
Documentation/process/coding-assistants.rst.

Assisted-by: Claude-Code:claude-opus-4-8
Signed-off-by: SeungJong Ha <engineer.jjhama@gmail.com>
---
SeungJong Ha (4):
      rust: transmute: add `impl_transmute_via_zerocopy!` macro
      rust: prelude: re-export `zerocopy::Immutable`
      gpu: nova-core: gsp: derive zerocopy traits for the msgq POD types
      gpu: nova-core: gsp: convert GspMem to zerocopy via the transmute bridge

 drivers/gpu/nova-core/gsp.rs                      | 13 ++-------
 drivers/gpu/nova-core/gsp/cmdq.rs                 | 15 +++++-----
 drivers/gpu/nova-core/gsp/fw.rs                   |  8 +++---
 drivers/gpu/nova-core/gsp/fw/r570_144.rs          |  2 ++
 drivers/gpu/nova-core/gsp/fw/r570_144/bindings.rs |  4 +--
 rust/kernel/prelude.rs                            |  2 ++
 rust/kernel/transmute.rs                          | 35 +++++++++++++++++++++++
 7 files changed, 54 insertions(+), 25 deletions(-)
---
base-commit: 780d569e6c4b422290f5cba319eb904b355d64be
change-id: 20260628-dma-zerocopy-bridge-dc1c96b610cf

Best regards,
--  
SeungJong Ha <engineer.jjhama@gmail.com>

