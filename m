From: Jesung Yang <y.j3ms.n@gmail.com>
Subject: [PATCH v5 0/4] rust: add `TryFrom` and `Into` derive macros
Date: Thu, 29 Jan 2026 23:32:44 +0900
Message-Id: <20260129-try-from-into-macro-v5-0-dd011008118c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIxve2kC/32NQQqDMBBFryKz7hSNSWq76j2KixATHWiMTEQqk
 rs39QBdvgf//QOSY3IJHtUB7DZKFOcC6lKBncw8OqShMIhaqEYIhSvv6DkGpHmNGIzliI3Waqi
 Nt952UJYLO0+fs/rqC0+U1sj7ebLJn/3f2yTWKI3S7aDut67VzzEYel9tDNDnnL9JtcWwtgAAA
 A==
X-Change-ID: 20251225-try-from-into-macro-1665d0afcfc8
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Alexandre Courbot <acourbot@nvidia.com>
Cc: linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 nouveau@lists.freedesktop.org, Jesung Yang <y.j3ms.n@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=5049; i=y.j3ms.n@gmail.com;
 h=from:subject:message-id; bh=W/lQNM+k2nJyyhsWP+iX2X75QmPDfFgQGv2yUuk2t+c=;
 b=owJ4nAFtApL9kA0DAAoBhnBYoOPQ2LoByyZiAGl7b47aya1K7Gld9Pr15f5ILWyBdh7l0GBPa
 6HOxnu/aM43uYkCMwQAAQoAHRYhBNJuBqTTLsbEgOaQ0IZwWKDj0Ni6BQJpe2+OAAoJEIZwWKDj
 0Ni6aioQALMVekoonpoiaF5wtL63jMIje/TKyxuKccuJJgghAmjDvYFM4Ij7lhMP9rjvb4NJ0rE
 BQw56rPhtTrad1s2AeJkx8Aie2GJd0fyrjwdSFUG3OrlAdZgqrVAP3irlL5ZJ+FK3FHr6nbgE18
 JEyiO4/UF21wCOi1YaF9nWSjj2uLisRsPUdlDaAqHzgSHGVbahFctM0006DjSIZ8d3Mzv3ualFl
 KJubhQGMISfbbqAlc1iU/WTInrVhSpUuHDvk40aQhwdVyfBmsEK0UxybwYgsW6Z/FooynBug22r
 QXXSpKORx8PldH4mlr7smdXgfAdqOBs5oa0hUs+yrbfqozj7gw9RsNes+KdiSYRxVbrQhmwYtcm
 7PFwGpYnazCtS1IwFYP3f2nuXgFlDGbNapgxI5qGObbnoe5DvWhMZA6owKOfC9KJ07+7mulQwts
 aCXS6J2y5yTIVLb4pSfUgrD9+MEWu8rvh8oW873hdc5Lq8qGOYe7KP+zXsXhEemm6BTkLxaKE9T
 VZI3lE85DzjmFW+sbbeo/Edf8/6yCl/iHgJS7j+P1Omf4bB6Rw9HdB+1J0ngAxBZQN8n3DiABQh
 1cveTR6Nm29OnkogajCL53/BC+89P9xNdlOnBuEXCZAbokQ/yF/IRRzShLHx9UdViEPSpUYRe4q
 O1VgLCpp6xCsEOkH5dbAwfw==
X-Developer-Key: i=y.j3ms.n@gmail.com; a=openpgp;
 fpr=D26E06A4D32EC6C480E690D0867058A0E3D0D8BA
X-Endpoint-Received: by B4 Relay for y.j3ms.n@gmail.com/default with auth_id=602
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series introduces derive macros for the `TryFrom` and `Into`
traits.

I dropped support for `#[repr(C)]` fieldless enums (i.e., disallow
deriving `TryFrom` and `Into` on those enums), since the actual
representation of discriminants is defined by rustc internally, and
documentation around it is not yet settled [1][2].

I would like to highlight some feedback from the previous series where I
have decided to retain the original behavior in this series. In part, I
feel more community feedback is needed to reach the right design; I've
also elaborated on my personal reasoning for each point below:

1) Require explicit `#[repr(..)]` for enums using the macros.

Given the drop of `#[repr(C)]` support, I believe defaulting to `isize`
when no `#[repr(..)]` is specified is safe, as it follows the
compiler's (documented) default behavior [3]. By "safe", I mean I see no
potential regressions or hidden issues; we even have a compile-time
overflow assertion which ensure all enum discriminants fit within the
types involved in the conversion.

2) Generate trait implementation for a type in `#[repr(..)]` even when
   the helper attribute is present. For example:

     #[derive(TryFrom)]
     #[try_from(bool)]
     #[repr(u8)]
     enum E {
         A = 0,
         B = 1,
     }

   make the above snippet generate both `TryFrom<u8>` and
   `TryFrom<bool>` implementations.

However, sometimes users might want to prevent generating trait
implementations for the type in `#[repr(..)]`, especially when the enum
encodes types like `bool` or `Bounded<u8, 4>` that cannot be used in
`#[repr(..)]`, like the above snippet. If we were to follow the feedback
directly, users would end up with an unnecessary `TryFrom<u8>`
implementation. Therefore, I think it is reasonable to treat the helper
attribute as an override that ignores the type in `#[repr(..)]` when
present.

One last point: the current `Into` implementation relies on
`Bounded::from_expr()`, which utilizes `build_assert!()`. So the
expanded result looks roughly like this:

  impl From<Enum> for Bounded<u8, 4> {
      fn from(value: Enum) -> Bounded<u8, 4> {
          // Compile-time assertions to guarantee `value` fits within
          // `u8` (Omitted)

          Bounded::<u8, 4>::from_expr(value as u8)
      }
  }

After some experimentation, it appears that the compiler correctly
optimizes out the assertion if (and only if) the `Bounded` type covers
all enum discriminants, though I'm not 100% certain of this behavior in
all cases. Can we approach this better?

Appreciate any feedback or suggestions.

[1] https://github.com/rust-lang/rust/issues/124403
[2] https://github.com/rust-lang/rust/pull/147017
[3] https://doc.rust-lang.org/reference/items/enumerations.html#r-items.enum.discriminant.repr-rust

Signed-off-by: Jesung Yang <y.j3ms.n@gmail.com>
---
Changes in v5:
- Drop support for `#[repr(C)]` enums. (Benno Lossin)
- Allow `#[repr(C, {primitive_int_type})]` for future-proofing.
  (Benno Lossin)
- Parse types in helper attributes into `syn::Type` prior to validation.
  (Benno Lossin)
- Replace doctests for `TryFrom` with correct examples. (Benno Lossin)
- Reorganize error reporting structure.
- Add documentation about `#[repr(C)]` fieldless enums.
- Rebase on commit a7c013f77953 ("Merge patch series "refactor Rust proc
  macros with `syn`"")
- Link to v4: https://lore.kernel.org/r/20251225-try-from-into-macro-v4-0-4a563d597836@gmail.com

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

 rust/macros/convert.rs | 1599 ++++++++++++++++++++++++++++++++++++++++++++++++
 rust/macros/lib.rs     |  349 ++++++++++-
 2 files changed, 1947 insertions(+), 1 deletion(-)
---
base-commit: a7c013f779530190d0c1e1aa5e7c8a61f0bd479e
change-id: 20251225-try-from-into-macro-1665d0afcfc8

Best regards,
-- 
Jesung Yang <y.j3ms.n@gmail.com>

