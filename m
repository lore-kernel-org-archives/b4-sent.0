From: Nick Dowsett <nick42d@gmail.com>
Subject: [PATCH v2 0/4] rust: wmi: add ACPI WMI bus abstractions
Date: Fri, 27 Nov 2026 19:02:48 +0800
Message-Id: <20261127-rust-wmi-v2-0-5bfafabd6a6e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/0WNQQ6CMBBFr0Jm7Zi2miKuvIdhAWWAMUJNC1VDe
 ncLmrh8yfvvL+DJMXk4Zws4CuzZjgnULgPTV2NHyE1iUEJpKWWBbvYTPgdGo2tBoqUir3JI+sN
 Ry68tdS2/7Of6RmZa96vRs5+se29fQa7eL6vUPxskCtSH9NUUdFJHc+mGiu97YwcoY4wfTeZ9x
 LIAAAA=
X-Change-ID: 20261119-rust-wmi-c6b0e0fe97a7
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
 Armin Wolf <W_Armin@gmx.de>
Cc: linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 platform-driver-x86@vger.kernel.org, Nick Dowsett <nick42d@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795777382; l=1961;
 i=nick42d@gmail.com; s=20261127; h=from:subject:message-id;
 bh=2hHid/ofHgHaK/BRgZmTbjHrJRvc3ibg8IsjVO6o5mU=;
 b=we5Lhv6/SyTPqkxY8A/SFnFWWN39viazN8AGD7NdJHpuSB9asmpVsgDK1Fn6I6nSVw274UQPC
 KXtoUgJ5TXvCbWJAW6YP0g+ALk/Siodj3BHofe9zbEdZJxgU1D53IIs
X-Developer-Key: i=nick42d@gmail.com; a=ed25519;
 pk=rewGRrQm8GTjt8ii+wLiI2tUWP5gtTF4pntVEMNXrj8=
X-Endpoint-Received: by B4 Relay for nick42d@gmail.com/20261127 with auth_id=1660
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi there; new to the LKML here, long time Rustacean and Linux user.

I have implemented this series to add an MVP of Rust abstractions for the
WMI subsystem (`include/linux/wmi.h`) with the bare-minimum
implemented to support an in-tree user, a Clevo laptop keyboard
backlight driver [1].

Note the driver has two other dependencies: Markus Probst's LED
classdev abstractions and basic DMI matching abstractions.

[1] https://lore.kernel.org/all/20261122-clevo-laptop-v1-0-881debf4d4b0@gmail.com/

This was not directly influenced by Ilya Gladyshev's previous attempt as
I was not aware of it, the key difference here is that I have used the
newer buffer-based interface (no `acpi_object`), and implemented less of
the callbacks initially.

What's covered is driver probe, registration and unregistration, device
id table, and a safe implementation of `wmidev_invoke_method` that
returns an owned RAII buffer.

---
Changes in v2:
- Add inline annotations (Sashiko)
- Add / standardise `// INVARIANT:` documentation (Sashiko).
- Additional comments documenting device construction state, expand
  abbreviation in module documentation, and fix typos.
- Rebased onto v7.4-rc4.
- Link to v1: https://patch.msgid.link/20261122-rust-wmi-v1-0-63111d9e824c@gmail.com

---
Nick Dowsett (4):
      rust: wmi: add basic WMI device abstraction
      rust: wmi: add DeviceId and wmi_device_table! macro
      rust: wmi: add Driver trait, Adapter and implement RegistrationOps
      rust: wmi: add Buffer and Device::invoke_method()

 MAINTAINERS                     |   1 +
 rust/bindings/bindings_helper.h |   1 +
 rust/kernel/lib.rs              |   2 +
 rust/kernel/wmi.rs              | 375 ++++++++++++++++++++++++++++++++++++++++
 4 files changed, 379 insertions(+)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261119-rust-wmi-c6b0e0fe97a7

Best regards,
--  
Nick Dowsett <nick42d@gmail.com>

