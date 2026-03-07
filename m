From: Jesung Yang <y.j3ms.n@gmail.com>
Subject: [PATCH v3 0/2] rust: take advantage of newer rust-analyzer
 features
Date: Sun, 08 Mar 2026 08:30:33 +0900
Message-Id: <20260308-ra-fix-primitive-v3-0-598017bcefd8@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABm1rGkC/33NzQ6CMAzA8VchO1uzjiHDk+9hPEzooIl8ZCOLh
 vDuDk4cjMd/0/66iECeKYhrtghPkQOPQ4r8lIm6s0NLwE1qoaS6SJQI3oLjN0yee545EpQGC+3
 IYJk7kc4mT2lhJ++P1B2HefSf/UPEbfoHiwgIDTkjq7won5pubW/5da7HXmxYVEeg+gEokKB0Z
 QplNerCHoF1Xb8HkisL8QAAAA==
X-Change-ID: 20260101-ra-fix-primitive-78154fe8173f
To: Miguel Ojeda <ojeda@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Tamir Duberstein <tamird@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Tamir Duberstein <tamird@kernel.org>
Cc: Eliot Courtney <ecourtney@nvidia.com>, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jesung Yang <y.j3ms.n@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2997; i=y.j3ms.n@gmail.com;
 h=from:subject:message-id; bh=UV8zez8ig/vGnucKtXs4DltLQ0Zavh58ziddpLy7mzg=;
 b=owJ4nAFtApL9kA0DAAoBhnBYoOPQ2LoByyZiAGmstR0PMbBpYJpXr5B10kyH7WlszJHiv2UBF
 c7y6GltYBBizokCMwQAAQoAHRYhBNJuBqTTLsbEgOaQ0IZwWKDj0Ni6BQJprLUdAAoJEIZwWKDj
 0Ni6Gb4QALZJDFivdw4OuukJTR7kgvFfMKAVKJRhqpfDD3eVPUwtkiW2K2TwKVt2JppQpSMRuXs
 BCPfRTlUj0hvKyPO2l5i8eRQD7lPdpLEjOQTM6uyFNwG9ZDQ7hhcJvVaPGVrCVhpmYhHtMdBU/Q
 LhSH3SOZNFeQdDuosQVvr9EwIlND0i3QS4m8uNEI7QLtTPHcLjyQxnv7twjI74VGfZD6KId21bO
 AzFddI4mHaWw68riueut5moRyrBhTEsQrOdXzyc46nbfQ4AwvIIJ1rghKo6EtsOzUJOAzbGTJ6c
 ksL56EblPwfZ7ngNwjFADi/UlC9afzD6hRaxpHV1Fbzg27yINyS3eA6FalzIv2CBPdDsYBHIS6/
 kdUABxO6Yjg7ubTrPH/PIQTsm5iR73D+pOnBMF3i1O0KI9i+YTP+6wSKo5LFh7/5M+owrM5WS5O
 lmgfGftd8egnqxuJTCKe04SPEkvr1P2Y4GffFI07DMXNznV8GH1+RTNoJd7HpUQK6cJ7QpQorI1
 89aLaD9ym18rCPf4GpdVrpF4QlZdrXbpfKQYpA0bkaQBy8S553Bxr093bT/HxdfipU7ZoX6lcjY
 qpmqbVYpO9keA6vfl+Prr9sff9BDdXRnOBMc7CI+Y2vb+ZZjl7+3HlZSJdNpJbyeyiix0gwBxB4
 WHheFwB+BhMUzip7izccrmg==
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

 scripts/generate_rust_analyzer.py | 221 +++++++++++++++++++++++++++++++++-----
 1 file changed, 196 insertions(+), 25 deletions(-)
---
base-commit: 6c02871d2585bca9d43cea239f908c05ef55a89d
change-id: 20260101-ra-fix-primitive-78154fe8173f

Best regards,
-- 
Jesung Yang <y.j3ms.n@gmail.com>

