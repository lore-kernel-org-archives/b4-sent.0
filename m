From: Josef Ippisch <josef.ippisch.dev@mailbox.org>
Subject: [PATCH v2 0/2] rust: debugfs: migrate debugfs traits requirements
 to zerocopy
Date: Tue, 28 Jul 2026 19:31:18 +0200
Message-Id: <20260728-migrate-binarywriter-to-zerocopy-intobytes-v2-0-0a4ec1d3ead4@mailbox.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/52Oyw6CMBBFf8V07Zh2lIeu/A/josCAY5SSaUWR8
 O8CbnSpy5PcnHN75UmYvNoteiXUsmdXj4DLhcpPtq4IuBhZocZYJ2YLV67EBoKMayvdXTiQQHD
 wJHG5azrgOrisC+TBUFpuqNyubazVKGyESn7MscPxzf6WnSkPU2FanNgHJ938pjXT7q9wa0ADJ
 lSsdWSQkmh/tXzJ3GPlpFJTusUPOUY/yXGUUxqhLdK4KE3yLR+G4QVc3HFvVQEAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785259881; l=2544;
 i=josef.ippisch.dev@mailbox.org; s=20260719; h=from:subject:message-id;
 bh=pVoLdUiYaCoewq3P1L24bf598pl03VPwHjg0JPQe1so=;
 b=rvyOi85ebZ1AZVTJ2p5GAH/yDrtUfYVs1PVPi43lRceIk0YaBtm8PeHbmtNZG5BiiA+2Sa5y8
 OxNWPMDl0MyBHXceV/1NDVun0v7ymi1vgE27dkH1oILbTExuXv3hS6V
X-Developer-Key: i=josef.ippisch.dev@mailbox.org; a=ed25519;
 pk=M4DnWHhz9yT9BkhXKzsmw6wTVrK2U1WBK0QiEjHoo1U=
X-Endpoint-Received: by B4 Relay for josef.ippisch.dev@mailbox.org/20260719 with auth_id=884
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Migrate `BinaryWriter` and `BinaryReaderMut`'s default implementation's
requirements on T from `kernel::transmute` traits to `zerocopy` traits.

This is part of a bigger migration from rust/kernel/transmute.rs to the
zerocopy crate, see also [1] and [2]

[1] https://github.com/Rust-for-Linux/linux/issues/975
[2] https://github.com/Rust-for-Linux/linux/issues/1241

The crate zerocopy was introduced with

c37398010a05 rust: zerocopy: import crate

This introduced among other things the `FromBytes` and `IntoBytes` traits
that, when derived, do better checks on the actual requirements of the
types they are implemented on than the existing
`kernel::transmute::FromBytes` and `kernel::transmute::AsBytes` traits,
respectively.

This is my first kernel patch so please let me know if I do anything wrong
process wise or regarding some other aspect!

I noticed that we could probably get rid of the `BinaryWriter` and
`BinaryReaderMut` implementations for `Vec` altogether if we implemented
`FromBytes`, `Immutable` and `IntoBytes` for `Vec`.  These are already
implemented for [T] after all. What do you think?

Suggested-by: Joshua Liebow-Feeser <joshlf@google.com>
Suggested-by: Miguel Ojeda <ojeda@kernel.org>
Link: https://github.com/Rust-for-Linux/linux/issues/975
Link: https://github.com/Rust-for-Linux/linux/issues/1241
Signed-off-by: Josef Ippisch <josef.ippisch.dev@mailbox.org>
---
Changes in v2:
- Addresses Sashiko AI review's comment about also migrating
  `BinaryReaderMut` to zerocopy to not bifurcate the API requirements of
  debugfs/traits.rs.
- Do not `use zerocopy::{FromBytes, IntoBytes}` as they are part of
  `use kernel::prelude::*`.
- For some reason sending v2 via SMTP server did not reach the mailing
  list.  I apologize if some of you receive this twice now.  I did not
  mark this RESEND because of the email never reaching the mailing list.
- Link to v1: https://patch.msgid.link/20260719-migrate-binarywriter-to-zerocopy-intobytes-v1-0-27ed30512e75@mailbox.org

---
Josef Ippisch (2):
      rust: debugfs: migrate debugfs traits requirements to zerocopy
      rust: debugfs: remove unsafe blocks from traits impl for Vec

 rust/kernel/debugfs/traits.rs | 41 +++++++++++------------------------------
 1 file changed, 11 insertions(+), 30 deletions(-)
---
base-commit: 7059bdf4f04a3e14f4fafb3ac35fdca913e3e21a
change-id: 20260719-migrate-binarywriter-to-zerocopy-intobytes-1e8f4ef93a60

Best regards,
--  
Josef Ippisch <josef.ippisch.dev@mailbox.org>

