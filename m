From: Jesung Yang <y.j3ms.n@gmail.com>
Subject: [PATCH v5 0/2] rust: take advantage of newer rust-analyzer
 features
Date: Thu, 30 Apr 2026 21:15:47 +0900
Message-Id: <20260430-ra-fix-primitive-v5-0-6364d2258e14@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPNH82kC/33NS47CMAyA4augrAmy8yDJrOYeIxZp6oAlSlGKo
 kGod5/AZipUsfwt+/NDTFSYJvG1eYhClSceLy3sdiPSKV6OJLlvLRSoPSCgLFFm/pXXwgPfuJJ
 0Hq3J5NHpLNrZtVBbeJE/h9Ynnm5jub8+VHxOP2AVJcqesoegresMfR+HyOddGgfxxKpaAmEFU
 BKkMsFbFQ0aG98B/Q9o8CuAboANHtB1iXLv3wGzANCtAKYBXYK9g5C8MnoJzPP8B5VywglzAQA
 A
X-Change-ID: 20260101-ra-fix-primitive-78154fe8173f
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Tamir Duberstein <tamird@kernel.org>
Cc: Eliot Courtney <ecourtney@nvidia.com>, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jesung Yang <y.j3ms.n@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777551349; l=5317;
 i=y.j3ms.n@gmail.com; s=kernel; h=from:subject:message-id;
 bh=zKw0oaBr+Wg3YuJsjBzOcpYqmgj50s3i0S8gwq9BgQo=;
 b=gekZ1FEDjjv/n1fbBy0WEurj1jkUrDcWsU4KgZ/Vo+kcqDyfoetbgP7X764e/TRBeuXVMa5jZ
 fbgHB6b1ag3CpGBlbxRxN4v0q1sSul5VjpxnnNxUeIoJ/JyEnQmhFxd
X-Developer-Key: i=y.j3ms.n@gmail.com; a=ed25519;
 pk=4nSlncQuTIIYLyLXkNxS0ssInM3uK0snxLSeQ2tdG/o=
X-Endpoint-Received: by B4 Relay for y.j3ms.n@gmail.com/kernel with auth_id=755
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

Hence, this series revises the approach taken in [2] by first adding
multi-version support for rust-analyzer. Specifically, it enables
support for the v0.3.2727 (2025-12-22) release and newer, which is
required to resolve inherent method resolution issues for primitive
types found in recent versions of rust-analyzer.

As Eliot mentioned in [3], we might also want to do the `include_dirs`
trick on top of this series to support rust-analyzer releases older than
v0.3.2727, but it should be handled in a dedicated patch series.

----- [QUICK TEST INSTRUCTIONS] -----

[Example 1]
1) Apply this patch series.
2) Run `mypy --strict scripts/generate_rust_analyzer.py` against
   different Python versions (e.g., `--python-version 3.9`,
   `--python-version 3.11`)
3) Verify that there is no type errors.

[Example 2]
1) Make rust-analyzer>=v0.3.2727 (2025-12-22) available in `$PATH`.
2) Compile one of the crates under `driver/` or `samples/rust`.
3) Run `make LLVM=1 rust-analyzer`.
4) Check that autocompletion for inherent methods does not work for
   primitive types (e.g., `0i32.rotate_left()`).
5) Apply this patch series.
6) Re-run `make LLVM=1 rust-analyzer`.
7) Verify that autocompletion works properly now.
8) Verify that no autocompletion is provided for `std`.

[Example 3]
1) Make rust-analyzer<v0.3.2727 (2025-12-22) available in `$PATH`.
2) Compile one of the crates under `driver/` or `samples/rust`.
3) Run `make LLVM=1 rust-analyzer`.
4) Run `mv rust-project.json rust-project.json.old`.
5) Apply this patch series.
6) Re-run `make LLVM=1 rust-analyzer`.
7) Run `diff -s rust-project.json rust-project.json.old` to verify that
   they are identical.

[Example 4]
1) Apply this patch series.
2) Ensure `rust-analyzer` is not available in `$PATH`.
3) Run `make V=1 LLVM=1 rust-analyzer`.
4) Verify that the fallback warning message appears.

[1] https://lore.kernel.org/rust-for-linux/20260101-rust-project-reduce-size-v1-1-4cd66e9e02d9@gmail.com/
[2] https://lore.kernel.org/r/20260101-ra-fix-primitive-v1-1-def809357b4e@gmail.com/
[3] https://lore.kernel.org/rust-for-linux/DFVQBFD54CJO.2D3VQ091URH2B@nvidia.com/

Signed-off-by: Jesung Yang <y.j3ms.n@gmail.com>
---
Changes in v5:
- Document how to retrieve rust-analyzer version information.
- Rename `RaVersionInfo.DEFAULT` to `RaVersionInfo.MSRV`.
- Move the introduction of `RaVersionCtx` to the second patch.
- Embed `RaVersionCtx` into `RaVersionInfo`.
- Conditionally add `sysroot_src` field depending on
  `manual_sysroot_crates`.
- Conditionally add `crate_attrs` field depending on `use_crate_attrs`.
- Conditionally define `RustProject` and `Crate` for stricter type
  checking in newer Python versions.
- Move the dependency filtering logic to `build_crate`.
- Move `RustProject` closer to its point of use.
- Fix grammar.
- Link to v4: https://lore.kernel.org/r/20260317-ra-fix-primitive-v4-0-bc06709c8243@gmail.com

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

 scripts/generate_rust_analyzer.py | 268 +++++++++++++++++++++++++++++++++++---
 1 file changed, 248 insertions(+), 20 deletions(-)
---
base-commit: b4e07588e743c989499ca24d49e752c074924a9a
change-id: 20260101-ra-fix-primitive-78154fe8173f

Best regards,
--  
Jesung Yang <y.j3ms.n@gmail.com>

