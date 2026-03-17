From: Jesung Yang <y.j3ms.n@gmail.com>
Subject: [PATCH v4 0/2] rust: take advantage of newer rust-analyzer
 features
Date: Tue, 17 Mar 2026 18:29:53 +0900
Message-Id: <20260317-ra-fix-primitive-v4-0-bc06709c8243@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABEfuWkC/33NzQ6CMAzA8VcxO1uz7kOGJ9/DeBjQaRMRM8yiI
 by7g4vEEI//pv11ED1Fpl4cNoOIlLjn7p7DbDeivvr7hYCb3EJJtZcoEaKHwC94RG75yYmgcGh
 NIIeFDiKfPSLlhZk8nXNfuX928T1/SDhN/2AJAaGh4GSpbVEZOl5az7dd3bViwpJaAuUKoECCM
 qWzyhs01v8C+gto6VYAnQFbOolFVVNo3BIYx/ED5DkSMTIBAAA=
X-Change-ID: 20260101-ra-fix-primitive-78154fe8173f
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Tamir Duberstein <tamird@kernel.org>
Cc: Eliot Courtney <ecourtney@nvidia.com>, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jesung Yang <y.j3ms.n@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3594; i=y.j3ms.n@gmail.com;
 h=from:subject:message-id; bh=BSzupbVqv6kXAp+fL5Nu51YEhZXplRkaOmwLAhivaZQ=;
 b=owJ4nAFtApL9kA0DAAoBhnBYoOPQ2LoByyZiAGm5HxYED5CvzR6hZpHzcXfGcanFwU+8fyraT
 evHtPaLSzV/xokCMwQAAQoAHRYhBNJuBqTTLsbEgOaQ0IZwWKDj0Ni6BQJpuR8WAAoJEIZwWKDj
 0Ni6l4UP/2oqL/vWm7NmO+x1kXtMrsTE9qP3yZfopeMT3Z5VW3yU49dY3ZD21CJNzkBEPDlBe87
 Ho03S9vy5Zz24KKCJ5RzB6uj22f0mVPvRetRYQDjOe8QfnCueWG66NkkToXZpLxe773lzXcBwUV
 aqowPQ7RAn7uyHMB2vsYKRbkSQc880ZqfUnzu9Krj440pFLkMoIPc0f9VbZGrCyYDmCirJyZqra
 0HxLOHaBTULHGqe4xSvS/iPXPBtQaD615e4JbxT/aqT7IuS85AI8wPuT/hT85L7cLXmOc4/6T0O
 qPSpBrSX10XShmFS4fdiOtTFtp5WIgtFcGW3dcI3LzlxqHRJBkFp1xDippEvkD4ZjeXlNEsJbVT
 s8gf+XpZpXBU+BC8V9T1fGyQ7ic+QMHjOjNdKRavKwk4MmZj3aYtQbbWqnh3GfTZzp6lAvXOyIc
 UHxGYyUIC8l5LPBbbK+BA7p7OvJJZE4HSR46V53jKUtai7Kw6ep36c9ywuJ7Q0jLVz4K0gpHhMU
 s7FVPn+LmFAzIFamtWiaZtGCkAPR1BH0795q9BvtV1Y+VcIZDxFqS+qCF3+pRjZlKA1PCEt0m98
 vFs/xwdLuSpP7Co7uTYn2lUv10FIPp5DxWmP0S0P4D6aL4V8phXcyWB0B9p7t4Y0exN1p1fzZKF
 nSB7D9L+04/7CeHK0PTw2SQ==
X-Developer-Key: i=y.j3ms.n@gmail.com; a=openpgp;
 fpr=D26E06A4D32EC6C480E690D0867058A0E3D0D8BA
X-Endpoint-Received: by B4 Relay for y.j3ms.n@gmail.com/default with auth_id=602
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As discussed in [1], we need to support multiple versions of
rust-analyzer to take advantage of newer features without breaking
compatibility for users on older toolchains.

In this specific patch series addressing IDE support for inherent methods
of primitive types, the main compatibility issue arises from using
`sysroot_src`, which brings `std` as a dependency for crates in
`drivers/` and `samples/` (please see PATCH [2/2] for more details). This
causes rust-analyzer to incorrectly resolve symbols from `std` in those
crates.

It turns out that rust-analyzer v0.3.1877 (2024-03-11), which
corresponds to our current MSRV of 1.78, has the same `std` resolution
issue regardless of whether `sysroot_src` is used. However, as far as I
know, we're likely to bump the MSRV to 1.85, where the corresponding
rust-analyzer release indeed needs the versioning infrastructure to fix
the `std` issue.

Hence, this series revises the approach taken in [2] by first adding
multi-version support for rust-analyzer. Specifically, it enables
support for the v0.3.2727 (2025-12-22) release and newer, which is
required to resolve inherent method resolution issues for primitive
types found in recent versions of rust-analyzer.

As Eliot mentioned in [3], we might also want to do the `include_dirs`
trick on top of this series to support rust-analyzer releases older than
v0.3.2727, but it should be handled in a dedicated patch series.

[1] https://lore.kernel.org/rust-for-linux/20260101-rust-project-reduce-size-v1-1-4cd66e9e02d9@gmail.com/
[2] https://lore.kernel.org/r/20260101-ra-fix-primitive-v1-1-def809357b4e@gmail.com/
[3] https://lore.kernel.org/rust-for-linux/DFVQBFD54CJO.2D3VQ091URH2B@nvidia.com/

Signed-off-by: Jesung Yang <y.j3ms.n@gmail.com>
---
Changes in v4:
- Use `dataclass` for internal data structures.
- Change `RaVersionInfo` to an enum.
- Move `RaVersionInfo` closer to its point of use.
- Statically check if all `RaVersionInfo` variants are properly handled
  (using mypy).
- Relocate `ctx.manual_sysroot_crates` check in `append_sysroot_crate`.
- Move `crate_attrs=["no_std"]` addition to `scripts:
  generate_rust_analyzer.py: fix IDE support for primitive types`.
- Move `typing.NotRequired` closer to the relevant field.
- Link to v3: https://lore.kernel.org/r/20260308-ra-fix-primitive-v3-0-598017bcefd8@gmail.com

Changes in v3:
- Remove extra `crate_attrs=["no_std"]` for crates that specify
  `#![no_std]` by themselves.
- Fix rust-analyzer version for Rust 1.78.
- Tweak `map_ra_version_baseline` to distinguish between Rust version
  and rust-analyzer version.
- Simplify overall structure.
- Rebase on 6c02871d258 ("scripts: generate_rust_analyzer.py: reduce cfg
  plumbing")
- Link to v2: https://lore.kernel.org/r/20260109-ra-fix-primitive-v2-0-249852a4145a@gmail.com

Changes in v2:
- Implement multiple rust-analyzer version support.
- Rebase on 9ace4753a520 (Linux 6.19-rc4).
- Remove an unnecessary new line between tags.
- Link to v1: https://lore.kernel.org/r/20260101-ra-fix-primitive-v1-1-def809357b4e@gmail.com

---
Jesung Yang (2):
      scripts: generate_rust_analyzer.py: add versioning infrastructure
      scripts: generate_rust_analyzer.py: fix IDE support for primitive types

 scripts/generate_rust_analyzer.py | 220 ++++++++++++++++++++++++++++++++++----
 1 file changed, 198 insertions(+), 22 deletions(-)
---
base-commit: 6c02871d2585bca9d43cea239f908c05ef55a89d
change-id: 20260101-ra-fix-primitive-78154fe8173f

Best regards,
-- 
Jesung Yang <y.j3ms.n@gmail.com>

