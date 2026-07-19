From: Josef Ippisch <josef.ippisch.dev@mailbox.org>
Subject: [PATCH 0/2] rust: debugfs: migrate BinaryWriter requirements to
 zerocopy
Date: Sun, 19 Jul 2026 10:28:47 +0200
Message-Id: <20260719-migrate-binarywriter-to-zerocopy-intobytes-v1-0-27ed30512e75@mailbox.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXNSw7CMAwA0atUXmOpKahQroK6SIJTjERSOeYTq
 t6dAMu3mVkgkzBlODYLCD04c4oVZtOAv9g4EfK5Grq269u9GfDGk1gldBytlKewkqAmfJMkn+a
 CHDW5opTR0CHsKAxb27dQg7NQ4Ndvdhr/znd3Ja/fA6zrByIjqcWOAAAA
X-Change-ID: 20260719-migrate-binarywriter-to-zerocopy-intobytes-1e8f4ef93a60
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: driver-core@lists.linux.dev, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joshua Liebow-Feeser <joshlf@google.com>, 
 Miguel Ojeda <ojeda@kernel.org>, 
 Josef Ippisch <josef.ippisch.dev@mailbox.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784449742; l=2110;
 i=josef.ippisch.dev@mailbox.org; s=20260719; h=from:subject:message-id;
 bh=+Y+dMqSu30++/HeilifSoYXXCl2DeneoUS6AA6C233s=;
 b=4LzJukWpHx3BW3yuSqUZo97oUWqt3RybmSx+UHgmW9fomCT64PQcc9bLa7inTXeC0hIHwZBuH
 TtdHCTFY0OPCoYiP/lFsAq2slW10wNg35UZi7EBHboiqDL8J/jSYWFx
X-Developer-Key: i=josef.ippisch.dev@mailbox.org; a=ed25519;
 pk=M4DnWHhz9yT9BkhXKzsmw6wTVrK2U1WBK0QiEjHoo1U=
X-Endpoint-Received: by B4 Relay for josef.ippisch.dev@mailbox.org/20260719 with auth_id=884
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Migrates the `BinaryWriter` default implementation requirements from
`kernel::transmute::IntoBytes` to `zerocopy::Immutable` +
`zerocopy::IntoBytes`.

This is part of a bigger migration from rust/kernel/transmute.rs to the
zerocopy crate, see also [1] and [2]

[1] https://github.com/Rust-for-Linux/linux/issues/975
[2] https://github.com/Rust-for-Linux/linux/issues/1241

The crate zerocopy was introduced with

c37398010a05 rust: zerocopy: import crate

This introduced among other things the `IntoBytes` trait that, when
derived, does better checks on the actual requirements of the types than
the existing `kernel::transmute::AsBytes`.

This is my first kernel patch so please let me know if I do anything wrong
process wise or regarding some other aspect!

There are some other points that I came across when investigating this

- rust/kernel/debugfs/traits.rs still depends on
  `kernel::transmute::AsBytes` for `BinaryReaderMut`.  Should I directly
  migrate this also in this patch series? This would require migrating also
  to `zerocopy::FromBytes` as the implemention for T depends on both
  `AsBytes + FromBytes` currently.
- I noticed that we could probably get rid of the `BinaryWriter`
  implementation for `Vec` altogether if we implemented `Immutable` and
  `IntoBytes` for `Vec`.  These are already implemented for [T] after
  all. What do you think?

Suggested-by: Joshua Liebow-Feeser <joshlf@google.com>
Suggested-by: Miguel Ojeda <ojeda@kernel.org>
Link: https://github.com/Rust-for-Linux/linux/issues/975
Signed-off-by: Josef Ippisch <josef.ippisch.dev@mailbox.org>
---
Josef Ippisch (2):
      rust: debugfs: migrate BinaryWriter requirements to zerocopy
      rust: debugfs: remove unsafe block from BinaryWriter impl for Vec

 rust/kernel/debugfs/traits.rs | 20 +++++++++-----------
 1 file changed, 9 insertions(+), 11 deletions(-)
---
base-commit: 7059bdf4f04a3e14f4fafb3ac35fdca913e3e21a
change-id: 20260719-migrate-binarywriter-to-zerocopy-intobytes-1e8f4ef93a60

Best regards,
--  
Josef Ippisch <josef.ippisch.dev@mailbox.org>

