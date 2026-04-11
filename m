From: Markus Probst <markus.probst@posteo.de>
Subject: [PATCH v4 0/4] rust: add basic serial device bus abstractions
Date: Sat, 11 Apr 2026 17:10:34 +0200
Message-Id: <20260411-rust_serdev-v4-0-845e960c6627@posteo.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGpk2mkC/13MSwrCMBSF4a2UjI0kN6/WkfsQkT5ubCamJDUop
 Xs3LQqtw3Pg+ycSMTiM5FRMJGBy0flHHvJQkLavH3ekrsubAAPFgRsannG8ZdRhoohKlhwrVqq
 WZDEEtO611i7XvHsXRx/eazzx5f12gO06iVNGUUotldFGAz8PPo7ojx2SpZPgZzUTTO8tLLZqQ
 DQSGlDq34qN5WJvRbZtVYvaApfW2K2d5/kD2EMq1R4BAAA=
X-Change-ID: 20251217-rust_serdev-ee5481e9085c
To: Rob Herring <robh@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Miguel Ojeda <ojeda@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Kari Argillander <kari.argillander@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, Boqun Feng <boqun@kernel.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Boqun Feng <boqun@kernel.org>
Cc: linux-serial@vger.kernel.org, linux-kernel@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, linux-pm@vger.kernel.org, 
 driver-core@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 Markus Probst <markus.probst@posteo.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3097;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=JuZcZzdMcRrLzA+RbPD3qbxn3xkXQ/wDeielE4KC3Ew=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBp2mR0PkwCPw9xoffILIbYfqj8mDwwWNu+k8sFd
 tf+efCo2XGJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCadpkdBsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9IeKA/+PtS/C6x7TV+jdU/RUp9xomoT7Tzb+Lu
 enLDgE3sPSHFPZytWBoWHBgg5yepoQpa+32lVAwKfJ7mZ8CtwrellE1dMiRxPnEAVFdsdoNSzmK
 erLjqrUmzn8046X47U9/6qLalHmb3QjsedlaslSMc/8mJFVd32Lqcj2VRAh2+1AI1dWJ4auOOaQ
 yYjBn18G0XApHHzZ5VObp9PE1L4gzXTXIqX1CeMd8pIG+DkdYrG+FjpCAte6mKP/to9R6PRfk1A
 7eUyQtvz260ntEYDBm/gCyZrDqN0Wkk9/GfchNci4mAFnDIPf/Tv8Zro3WxReb7UEJjSOHM17KW
 xj3CAXdF9I2K9NNqjoFs4MyaLfwEe/KulOkpSqzXO6q8u+wq/PgCtsisvy5X3vJeTy9bIX3xh09
 0xF0hPSSZoHBrb1XTw1wvA9wfPqBII3SaWi56SlSiD81e9tFgxeW6UBlesdjGLyot+F0DW0a4nP
 vzQwY9tfjLKv8YaylUJBDXpV+CV2MB1KipRu5e3qCPQO/6IXZodtlQA46e/dWT2cxzhg7j89lj2
 39G+GkedvFBuSGjDqn9eZjVXdyDEZB4L1JzsU4gye4S60KPgcekD95cUw90slAPY2H0NNpXLz3Q
 /V+GPmeu+GDWCsDsXbNXj1h/CTmnH0IddLoGjKl/eaVulfMTgU9U=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds the serdev device bus rust abstraction into the
kernel.

This abstraction will be used by a driver,
which targets the MCU devices in Synology devices.

Kari Argillander also messaged me, stating that he wants to write a
watchdog driver with this abstraction (needing initial device data).

@Rob: Are you willing to maintain these rust abstractions yourself,
as you are the expert on this subsystem, otherwise I would take care of
it with a "SERIAL DEVICE BUS [RUST]" section in the MAINTAINERS file. In
the second case, I assume you are going to pick those patches as-is into
your tree, after they have been reviewed?

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
Changes in v4:
- fixed not selecting rust serdev abstraction in sample
- Link to v3: https://lore.kernel.org/r/20260313-rust_serdev-v3-0-c9a3af214f7f@posteo.de

Changes in v3:
- fix vertical import style
- add Kconfig entry for the rust abstraction
- fix documentation in include/linux/serdev.h
- rename private_data to rust_private_data
- fix `complete_all` <-> `wait_for_completion` typo
- move drvdata_borrow call after the completion
- Link to v2: https://lore.kernel.org/r/20260306-rust_serdev-v2-0-e9b23b42b255@posteo.de

Changes in v2:
- fix documentation in `serdev::Driver::write` and
  `serdev::Driver::write_all`
- remove use of `dev_info` in probe from the sample
- remove `properties_parse` from the sample
- add optional `baudrate` property to the sample
- remove 1. patch
- remove `TryFrom<&device::Device<Ctx>> for &serdev::Device<Ctx>`
  implementation
- fix import style
- add patch to return reference in `devres::register` to fix safety
  issue
- add patch to add private data to serdev_device, to fix
  `Device.drvdata()` from failing
- simplify abstraction by removing ability to receive the initial
  transmission. It may be added later in a separate patch series if
  needed.
- Link to v1: https://lore.kernel.org/r/20251220-rust_serdev-v1-0-e44645767621@posteo.de

---
Markus Probst (4):
      rust: devres: return reference in `devres::register`
      serdev: add rust private data to serdev_device
      rust: add basic serial device bus abstractions
      samples: rust: add Rust serial device bus sample device driver

 drivers/tty/serdev/Kconfig         |   7 +
 include/linux/serdev.h             |  15 +-
 rust/bindings/bindings_helper.h    |   1 +
 rust/helpers/helpers.c             |   1 +
 rust/helpers/serdev.c              |  22 ++
 rust/kernel/cpufreq.rs             |   3 +-
 rust/kernel/devres.rs              |  15 +-
 rust/kernel/drm/driver.rs          |   3 +-
 rust/kernel/lib.rs                 |   2 +
 rust/kernel/serdev.rs              | 536 +++++++++++++++++++++++++++++++++++++
 samples/rust/Kconfig               |  11 +
 samples/rust/Makefile              |   1 +
 samples/rust/rust_driver_serdev.rs |  86 ++++++
 13 files changed, 693 insertions(+), 10 deletions(-)
---
base-commit: c369299895a591d96745d6492d4888259b004a9e
change-id: 20251217-rust_serdev-ee5481e9085c

