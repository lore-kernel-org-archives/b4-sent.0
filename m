From: Jesung Yang <y.j3ms.n@gmail.com>
Subject: [PATCH v4 0/4] rust: add `TryFrom` and `Into` derive macros
Date: Thu, 25 Dec 2025 08:37:46 +0000
Message-Id: <20251225-try-from-into-macro-v4-0-4a563d597836@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANr3TGkC/x3MQQqAIBBA0avIrBsoyYiuEi3ExppFGqNEId09a
 fkW/xdIJEwJJlVA6OLEMVT0jQK327AR8loNutWm09pglge9xAM55IiHdRKxGwazttY770ao5Sn
 k+f6v8/K+H1wD4FVlAAAA
X-Change-ID: 20251225-try-from-into-macro-1665d0afcfc8
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Alexandre Courbot <acourbot@nvidia.com>
Cc: linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 nouveau@lists.freedesktop.org, Jesung Yang <y.j3ms.n@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766651873; l=2575;
 i=y.j3ms.n@gmail.com; s=20251225; h=from:subject:message-id;
 bh=gtGFPnrT1tGUALhUzT4VmeMkygUixFFu28cqcGEINdg=;
 b=oigpxcVK0qRw2hfEHNznCMSACcO+TLwNfRoj4zhgyPnUAXGPdYnQkaUM5e5vnt+cUVr6z3VEu
 VFUC8d3eOCQBpAxbPgueUtNdXE75ng8xK66QUGb1+caZvSXQNDDO6JB
X-Developer-Key: i=y.j3ms.n@gmail.com; a=ed25519;
 pk=2yVgO1I+y7kkFSF2Dc/Dckj4L2FgRnvmERHFt4bspbI=
X-Endpoint-Received: by B4 Relay for y.j3ms.n@gmail.com/20251225 with auth_id=586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I am resending the full series (with minor typo fixes) as Gmail
consistently dropped several patches in v3.

This patch series introduces derive macros for the `TryFrom` and `Into`
traits.

Primary updates in v3:
- Adopt `syn` for improved macro parsing.
- Allow `kernel::num::Bounded` to be specified in helper attributes,
  enabling the generation of `TryFrom` and `Into` implementations for
  types with restricted bit ranges as required by the nova-core [1].
- Add compile-time overflow assertion to ensure that enum discriminants
  fit within the types being converted to or from, preventing silent
  overflows.

Note: 1015+ insertions are purely from doctests. Most of them are kept
private to keep the public API documentation clean and simple for
users. This might not be the usual way of doing things, but for now I
don't think I have a better option. Feedback and suggestions are always
appreciated.

[1] https://lore.kernel.org/rust-for-linux/DDHU4LL4GGIY.16OJMIL7ZK58P@nvidia.com/

Signed-off-by: Jesung Yang <y.j3ms.n@gmail.com>
---
Changes in v4:
- Fix typos.
- Link to (broken) v3: https://lore.kernel.org/rust-for-linux/cover.1766544407.git.y.j3ms.n@gmail.com/

Changes in v3:
- Use the vendored `syn` and `quote` crates.
- Support `kernel::num::Bounded`.
- Add compile-time overflow assertion.
- Add a comment about `#[repr(C)]` enums.
- Drop Tested-by and Reviewed-by tags, as the code structure has
  changed substantially. (Thanks for the previous reviews and testing!)
- Link to v2: https://lore.kernel.org/rust-for-linux/cover.1755235180.git.y.j3ms.n@gmail.com/

Changes in v2 (no functional changes):
- Split the patch "rust: macros: extend custom `quote!()` macro"
  into two separate patches.
- Remove unnecessary spaces between tags.
- Use a consistent commit subject prefix: "rust: macros:".
- Add Tested-by tags.
- Link to v1: https://lore.kernel.org/rust-for-linux/cover.1754228164.git.y.j3ms.n@gmail.com/

---
Jesung Yang (4):
      rust: macros: add derive macro for `Into`
      rust: macros: add derive macro for `TryFrom`
      rust: macros: add private doctests for `Into` derive macro
      rust: macros: add private doctests for `TryFrom` derive macro

 rust/macros/convert.rs | 1546 ++++++++++++++++++++++++++++++++++++++++++++++++
 rust/macros/lib.rs     |  319 ++++++++++
 2 files changed, 1865 insertions(+)
---
base-commit: 9448598b22c50c8a5bb77a9103e2d49f134c9578
change-id: 20251225-try-from-into-macro-1665d0afcfc8

Best regards,
-- 
Jesung Yang <y.j3ms.n@gmail.com>

