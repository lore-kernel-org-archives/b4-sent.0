From: Nick Dowsett <nick42d@gmail.com>
Subject: [PATCH 0/4] platform/x86: clevo-laptop: add initial Rust driver
 for keyboard backlight
Date: Sun, 22 Nov 2026 12:35:37 +0800
Message-Id: <20261122-clevo-laptop-v1-0-881debf4d4b0@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqAIBBA0avErBNUyKSrRIvSqSYkRSuC6O5ZL
 d/i/wsSRsIETXFBxIMS+TVDlAWYuV8nZGSzQXKphJCcGYeHZ64Pmw9M1NyqShurag05CRFHOr9
 d2/1O+7Cg2d4H3PcD8Wxb43AAAAA=
X-Change-ID: 20261120-clevo-laptop-170d658cd678
To: Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: Armin Wolf <W_Armin@gmx.de>, Werner Sembach <wse@tuxedocomputers.com>, 
 linux-kernel@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, Nick Dowsett <nick42d@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795322140; l=1960;
 i=nick42d@gmail.com; h=from:subject:message-id;
 bh=p78MTrTYwQzdn9dfkJDldtBDVtC1Y5FQDIFCazyzkhc=;
 b=1LfJha8InVu8PtbAMRzAgT44KCMkucZ+h4g8DHDeSIe8mBmk4tAmSA6rBrrrMhHVJczjmHvfs
 T3z8LUxxnoZBx5vDonouDhQs6oABs4w5yQ+l3UbUu+56foRJTsD3+/v
X-Developer-Key: i=nick42d@gmail.com; a=ed25519;
 pk=1uIkNexEofzEXNN3Y3QW5z8IrgjWaP0yH6Es51jxWOg=
X-Endpoint-Received: by B4 Relay for nick42d@gmail.com/default with auth_id=1596
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a new Rust platform driver MVP (`clevo-laptop`) for
Clevo barebones and rebranded laptops (Metabox, Tuxedo, Sager, XMG,
etc.), starting with 5-step white keyboard backlight control.

It is intended as the first in-tree user of the Rust WMI abstractions,
and a starting point to be extended to additional Clevo models and EC
features.

What's included:
- Minimal driver skeleton, Kconfig/Makefile plumbing, and MAINTAINERS
  entry.
- Type-safe EC WMI query interface.
- Driver registration and backlight type detection following
  tuxedo-drivers business rules.

Dependencies (not yet merged):
- Markus Probst's Rust LED classdev abstractions (v28):
  https://lore.kernel.org/all/20261113-rust_leds-v28-0-b8cf2f74fa57@posteo.de/
- Rust WMI abstractions (change-id: 20261119-rust-wmi-c6b0e0fe97a7)
  https://lore.kernel.org/all/20261122-rust-wmi-v1-0-63111d9e824c@gmail.com/
- Rust DMI abstractions (change-id: 20261121-rust-dmi-c49d2041d7e2)
  https://lore.kernel.org/all/20261122-rust-dmi-v1-1-4ace9449f872@gmail.com/

Tested on a Clevo/Metabox NL57AU laptop.

Signed-off-by: Nick Dowsett <nick42d@gmail.com>
---
Nick Dowsett (4):
      platform/x86: clevo-laptop: add minimal WMI driver skeleton and Kbuild plumbing
      platform/x86: clevo-laptop: add EC WMI query interface and BIOS feature check
      platform/x86: clevo-laptop: probe keyboard backlight type and detect 5-step white backlight
      platform/x86: clevo-laptop: register 5-step white keyboard backlight LED device

 MAINTAINERS                          |   6 +
 drivers/platform/x86/Kconfig         |  17 ++
 drivers/platform/x86/Makefile        |   3 +
 drivers/platform/x86/clevo-laptop.rs | 387 +++++++++++++++++++++++++++++++++++
 4 files changed, 413 insertions(+)
---
base-commit: 4843f6873f7c4835e62f2c73ba0fd538e57a2f22
change-id: 20261120-clevo-laptop-170d658cd678

Best regards,
--  
Nick Dowsett <nick42d@gmail.com>

