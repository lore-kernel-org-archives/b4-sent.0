From: SeungJong Ha <engineer.jjhama@gmail.com>
Date: Sun, 28 Jun 2026 17:10:17 +0000
Subject: [PATCH RFC 4/4] gpu: nova-core: gsp: convert GspMem to zerocopy
 via the transmute bridge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260628-dma-zerocopy-bridge-v1-4-9a2895ebe30d@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782666615; l=3247;
 i=engineer.jjhama@gmail.com; s=20260103; h=from:subject:message-id;
 bh=d48cCKivvnRDQm68ktq/uR1zz28Xdd0SmnJqbZoZy8s=;
 b=cbZUKUyzt14pXOSdfcV/Qr/zy05EzjhD6ozy2Be8nSFBJTeQdzYIN/uROEzeTl6S0D9Uj3Xh0
 LscCwKdgDkoD8EZCt4wGkOdBVvWJ8k51VxlaEYKAoUsoTH00crVDMue
X-Developer-Key: i=engineer.jjhama@gmail.com; a=ed25519;
 pk=G5nmjm+RTiWBpyCvc5xjR1b3li/2zipLSMyz+T4fj5E=
X-Endpoint-Received: by B4 Relay for engineer.jjhama@gmail.com/20260103 with auth_id=590
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

`GspMem` (shared with the GSP over a DMA `Coherent`) carried a
hand-audited `unsafe impl transmute::{AsBytes, FromBytes}` that did not
actually meet the no-padding requirement: `Msgq` embeds a page-aligned
`MsgqData` after two small headers.

Make that padding explicit (`_pad`), derive the `zerocopy` traits on the
`MsgqData`/`Msgq`/`GspMem` chain, and bridge to `transmute` via
`impl_transmute_via_zerocopy!`. The `unsafe` is now machine-checked.

Unions (e.g. `GspFwWprMeta`) are left on their hand-audited impls, since
`zerocopy::IntoBytes` cannot derive for unions.

Assisted-by: Claude-Code:claude-opus-4-8
Signed-off-by: SeungJong Ha <engineer.jjhama@gmail.com>
---
 drivers/gpu/nova-core/gsp/cmdq.rs | 15 +++++++--------
 1 file changed, 7 insertions(+), 8 deletions(-)

diff --git a/drivers/gpu/nova-core/gsp/cmdq.rs b/drivers/gpu/nova-core/gsp/cmdq.rs
index 070de0731e95..d9929d24d316 100644
--- a/drivers/gpu/nova-core/gsp/cmdq.rs
+++ b/drivers/gpu/nova-core/gsp/cmdq.rs
@@ -152,7 +152,7 @@ fn read(
 /// This area of memory is to be shared between the driver and the GSP to exchange commands or
 /// messages.
 #[repr(C, align(0x1000))]
-#[derive(Debug)]
+#[derive(Debug, FromBytes, IntoBytes, Immutable)]
 struct MsgqData {
     data: [[u8; GSP_PAGE_SIZE]; num::u32_as_usize(MSGQ_NUM_PAGES)],
 }
@@ -169,6 +169,7 @@ struct MsgqData {
 /// read pointer of `rx` actually refers to the `Msgq` owned by the other side.
 /// This design ensures that only the driver or GSP ever writes to a given instance of this struct.
 #[repr(C)]
+#[derive(FromBytes, IntoBytes, Immutable)]
 // There is no struct defined for this in the open-gpu-kernel-source headers.
 // Instead it is defined by code in `GspMsgQueuesInit()`.
 // TODO: Revert to private once `IoView` projections replace the `gsp_mem` module.
@@ -177,12 +178,16 @@ pub(super) struct Msgq {
     pub(super) tx: MsgqTxHeader,
     /// Header for receiving messages, including the read pointer.
     pub(super) rx: MsgqRxHeader,
+    _pad: [u8; GSP_PAGE_SIZE - size_of::<MsgqTxHeader>() - size_of::<MsgqRxHeader>()],
     /// The message queue proper.
     msgq: MsgqData,
 }
 
+static_assert!(size_of::<MsgqTxHeader>() + size_of::<MsgqRxHeader>() <= GSP_PAGE_SIZE);
+
 /// Structure shared between the driver and the GSP and containing the command and message queues.
 #[repr(C)]
+#[derive(FromBytes, IntoBytes, Immutable)]
 // TODO: Revert to private once `IoView` projections replace the `gsp_mem` module.
 pub(super) struct GspMem {
     /// Self-mapping page table entries.
@@ -205,13 +210,7 @@ impl GspMem {
     const PTE_ARRAY_SIZE: usize = GSP_PAGE_SIZE / size_of::<u64>();
 }
 
-// SAFETY: These structs don't meet the no-padding requirements of AsBytes but
-// that is not a problem because they are not used outside the kernel.
-unsafe impl AsBytes for GspMem {}
-
-// SAFETY: These structs don't meet the no-padding requirements of FromBytes but
-// that is not a problem because they are not used outside the kernel.
-unsafe impl FromBytes for GspMem {}
+kernel::impl_transmute_via_zerocopy!(GspMem);
 
 /// Wrapper around [`GspMem`] to share it with the GPU using a [`Coherent`].
 ///

-- 
2.54.0

