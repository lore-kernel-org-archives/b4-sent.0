From: Tim Kovalenko <tim.kovalenko@proton.me>
Subject: [PATCH v4 0/4] Fixes the stack overflow
Date: Mon, 09 Mar 2026 12:34:17 -0400
Message-Id: <20260309-drm-rust-next-v4-0-4ef485b19a4c@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XMsQ6DIBSF4VcxzKWBi0rp1PdoOqBcK4NogBIb4
 7sXnYxJx3OS719IQG8xkHuxEI/JBju6PMpLQdpeuzdSa/ImwKBmwIEaP1D/CZE6nCNtsFGgEZW
 RFclm8tjZee89X3n3NsTRf/d84tv7r5Q45bRkSqhbwwFr/pj8GEd3HZBspQRHLc4astaaqbKTN
 wlcn7U4annWImuFElXVVkqa9qjXdf0BSCj97iYBAAA=
X-Change-ID: 20260212-drm-rust-next-beb92aee9d75
To: Alexandre Courbot <acourbot@nvidia.com>, 
 Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Miguel Ojeda <ojeda@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Trevor Gross <tmgross@umich.edu>, Boqun Feng <boqun@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nsc@kernel.org>, 
 Abdiel Janulgue <abdiel.janulgue@gmail.com>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Robin Murphy <robin.murphy@arm.com>, Boqun Feng <boqun@kernel.org>
Cc: nouveau@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, driver-core@lists.linux.dev, 
 Tim Kovalenko <tim.kovalenko@proton.me>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773074117; l=1907;
 i=tim.kovalenko@proton.me; s=20260212; h=from:subject:message-id;
 bh=ur3mma4izM+B5GojZDmfk652EPp1d2EJADISR8mbwE0=;
 b=H3g4pztXItI93AFUT5bJEqqHh4yK27wA5nyBvGNWYTZ5xmzc0yEOXNpfRQ0CgA/5ymjpVGqFG
 fbcO1cz35oUA5sAonNIeYEaK47bnSFhPuWvMK5hzWiftvd8WbwGMrlU
X-Developer-Key: i=tim.kovalenko@proton.me; a=ed25519;
 pk=/+OiulEpgeZifgP4mDE4e5YlV6nMeY+frze/lY/xiHI=
X-Endpoint-Received: by B4 Relay for tim.kovalenko@proton.me/20260212 with auth_id=635
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>


---
Changes in v4:
- Rebase on top of projection changes
- Use index projection when writing PTEs
- Keep PteArray, as discussed in V2, and move entry calculation there
- Avoid stack allocation by writing PTEs directly to DMA memory

- Link to v3: https://lore.kernel.org/r/20260217-drm-rust-next-v3-1-9e7e95c597dc@proton.me

Changes in v3:
- Addressed the comments and re-instated the PteArray type.
- PteArray now uses `init` instead of `new` where it writes to `self`
  page by page.
- PteArray just needs a pte pointer obtained from the `gsp_mem.as_slice_mut`.

I hope I understood everything in the V2 email chain and implemented it correctly :)

- Link to v2: https://lore.kernel.org/r/20260213-drm-rust-next-v2-1-aa094f78721a@proton.me

Changes in v2:
- Missed a code formatting issue.
- Link to v1: https://lore.kernel.org/r/20260212-drm-rust-next-v1-1-409398b12e61@proton.me

---
Gary Guo (3):
      rust: ptr: add `KnownSize` trait to support DST size info extraction
      rust: ptr: add projection infrastructure
      rust: dma: use pointer projection infra for `dma_{read,write}` macro

Tim Kovalenko (1):
      gpu: nova-core: fix stack overflow in GSP memory allocation

 drivers/gpu/nova-core/gsp.rs      |  48 ++++---
 drivers/gpu/nova-core/gsp/boot.rs |   2 +-
 drivers/gpu/nova-core/gsp/cmdq.rs |  23 ++-
 rust/kernel/dma.rs                | 114 +++++++--------
 rust/kernel/lib.rs                |   4 +
 rust/kernel/ptr.rs                |  30 +++-
 rust/kernel/ptr/projection.rs     | 294 ++++++++++++++++++++++++++++++++++++++
 samples/rust/rust_dma.rs          |  30 ++--
 scripts/Makefile.build            |   4 +-
 9 files changed, 443 insertions(+), 106 deletions(-)
---
base-commit: dd8a93dafe6ef50b49d2a7b44862264d74a7aafa
change-id: 20260212-drm-rust-next-beb92aee9d75

Best regards,
-- 
Tim Kovalenko <tim.kovalenko@proton.me>

