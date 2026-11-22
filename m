From: Nick Dowsett <nick42d@gmail.com>
Subject: [PATCH 0/4] rust: wmi: add MVP of WMI abstractions
Date: Sun, 22 Nov 2026 12:28:13 +0800
Message-Id: <20261122-rust-wmi-v1-0-63111d9e824c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMywqAIBCF4VeJWSdoC6NeJVqUjTVBFk43EN89q
 +UH/zkBGD0hQ50F8HgS0+oSVJ6BmTo3oqAhGQpZaKVUJfzBu7gWEkb3EqXFquxKSPnm0dL9XTX
 tbz76Gc3+7iHGB1gJyq5sAAAA
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
Cc: =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 platform-driver-x86@vger.kernel.org, Nick Dowsett <nick42d@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795321700; l=1620;
 i=nick42d@gmail.com; h=from:subject:message-id;
 bh=LRMshCFfcJPtFSPE/6v1bGuREgTWrrb4IAOq+iyX/Wc=;
 b=DLa0YILKrbgNriQJag537mI/mDpfQWW8SXl8SpcnVXH6tnkBsyBCjMPtp1+BlmtTjqOBVkWFR
 033bHYyzf1WC3ZaoD5IQn+66GiZgZ4j27BG9yh4hVXKrOR9SVQ0k4UK
X-Developer-Key: i=nick42d@gmail.com; a=ed25519;
 pk=1uIkNexEofzEXNN3Y3QW5z8IrgjWaP0yH6Es51jxWOg=
X-Endpoint-Received: by B4 Relay for nick42d@gmail.com/default with auth_id=1596
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi there; new to the LKML here, long time Rustacean and Linux user.

I have implemented this series to add an MVP of Rust abstractions for the
WMI subsystem with the bare-minimum implemented to support an in-tree
user, a Clevo laptop keyboard backlight driver
(`https://github.com/nick42d/linux/pull/4`).

Patches to follow for the driver. Note it has two other dependencies:
Markus Probst's LED classdev abstractions (v28) and basic DMI matching
abstractions.

This was not directly influenced by Ilya Gladyshev's previous attempt as
I was not aware of it, upon review, the key difference is that I have
used the newer buffer-based interface (no `acpi_object`), and implemented
less functionality/callbacks.

What's covered is driver probe, registration and unregistration, device
id table, and a safe implementation of `wmidev_invoke_method` that
returns an owned RAII buffer.

Signed-off-by: Nick Dowsett <nick42d@gmail.com>
---
Nick Dowsett (4):
      rust: wmi: add basic WMI device abstraction
      rust: wmi: add DeviceId and wmi_device_table! macro
      rust: wmi: add Driver trait, Adapter and implement RegistrationOps
      rust: wmi: add Buffer and Device::invoke_method()

 MAINTAINERS                     |   1 +
 rust/bindings/bindings_helper.h |   1 +
 rust/kernel/lib.rs              |   2 +
 rust/kernel/wmi.rs              | 361 ++++++++++++++++++++++++++++++++++++++++
 4 files changed, 365 insertions(+)
---
base-commit: 4843f6873f7c4835e62f2c73ba0fd538e57a2f22
change-id: 20261119-rust-wmi-c6b0e0fe97a7

Best regards,
--  
Nick Dowsett <nick42d@gmail.com>

