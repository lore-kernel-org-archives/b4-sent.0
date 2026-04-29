From: Markus Probst <markus.probst@posteo.de>
Subject: [PATCH v7 0/4] rust: add basic serial device bus abstractions
Date: Wed, 29 Apr 2026 20:21:30 +0200
Message-Id: <20260429-rust_serdev-v7-0-0d89c791b5c8@posteo.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACpM8mkC/3XRTW7CMBAF4KtEXteRZ/wbVtyjqionmUBEIWAHq
 xXi7nWgqCRql2Ppe/LMu7BIoafIVsWFBUp97IdDHuxLwZqtP2yI922eGQrUgGB5OMfxPaOWEif
 SygFVwumGZXEM1PWft7TXtzxv+zgO4esWnmB6/clBMctJwAUnpYzS1liDsD4OcaShbIlNOQkf1
 ggpzNziZKsaZa2wRq2XVj5ZkHMrs20qL32HoDrbLa36tQpgblW2TmmqjGiMQbu0+sku99XZaku
 u9kJD1cmlNc92fvNksgUrbeVaTeBn9novIdDpnJsc702wPcXob02uikcmIgiBZV5bOgMceOt3Y
 b2jcKCPcgibqc5/HGg9OeWU+9vVPhJvhv2+H1dFsmU+XAP5c9dvhJxzN24CAAA=
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
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5457;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=oK5pms9uVEMP/3te4JTH9eo/pbWJdjojqvXsoKHPuoc=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBp8kxHBzqHPk16mBaErmeqnqv5EIEd9OpEUXPlr
 30+9hosimWJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCafJMRxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9JoYg//ZbQae5uhbRVIAsl7El1cMu6wwgX2d4X
 W7FKaoZlupCzASxnyCrznyMLmV37wBQ3wg9Gq7OautEqryG7bjoGzR3skJ4IZY6gt0FdRH9LOsj
 j6IVr9vKAkvWk9uXobkTyul2MfL3nxtKCCFAhFUznf11aaiEtsjXT1yvKdgcfJmR/qFH3nzXFe/
 HlRBumC8oETC0G6Nl/d7UFpGhXnYELWc+ZCFPLfS/KRPF4eGs7jLPsa3HWL2wzvm/97goZJa6KN
 twadXdACFiQNu1Lw/GVJl50QoN6hwZmIwC+GF7Pl9naTS0kQ+ULgeC31KpVtiE7dDIFd4JyHOok
 TwI4GowcCdMUzNXxoPr1aX2eHWlhx3+cjhvK7+4UBP0OjXJXw6b36iIA2H0RmruAPtaszMnFswB
 rOxh02YYC68z7JTiqA/dQkBz5dTuL8TWy1vWh+0wlvbBAbgtynL3PTRazMxwmAflOFLg9Vssd+o
 N1wfrtTCJCjg9D6KhNrjYRM7oyCTNfuekkGTo10VJ0bwuFEyoVDLmbwKTJEGTXnRB3G0Ob9rRMn
 zDoeiQHwX8MLbWnZg+F7SR9vTqu/Y8zHCpMTALdSv5xb8mrVwdy/f6uMLcAJt/xfDZMVGCpbUmc
 AIsolueDT7n4ZPRRZfK0DSumycpDD8wenJm3+xAm5iAzTHzz8Tds=
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

This series depends on [1].

[1]
https://lore.kernel.org/driver-core/20260427221155.2144848-1-dakr@kernel.org/

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
Changes in v7:
- adapted to driver-lifetime patch series
- Link to v6: https://patch.msgid.link/20260427-rust_serdev-v6-0-173798d5e1a3@posteo.de

Changes in v6:
- rebased onto v7.1-rc1
- Link to v5: https://patch.msgid.link/20260420-rust_serdev-v5-0-57e8ba0519f3@posteo.de

Changes in v5:
- fix typo in documentation
- Link to v4: https://lore.kernel.org/r/20260411-rust_serdev-v4-0-845e960c6627@posteo.de

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
 rust/kernel/serdev.rs              | 571 +++++++++++++++++++++++++++++++++++++
 samples/rust/Kconfig               |  11 +
 samples/rust/Makefile              |   1 +
 samples/rust/rust_driver_serdev.rs |  86 ++++++
 13 files changed, 728 insertions(+), 10 deletions(-)
---
base-commit: 5e9b7d093f3f77cb0af4409559e3d139babfb443
change-id: 20251217-rust_serdev-ee5481e9085c
prerequisite-message-id: 20260427221002.2143861-1-dakr@kernel.org
prerequisite-patch-id: 925690ac15ddd64777b2da34b343d2547bbf79e8
prerequisite-patch-id: 67318671a5eed5fb4ad23a450f1cf0e442bf8ca2
prerequisite-message-id: 20260427221155.2144848-1-dakr@kernel.org
prerequisite-patch-id: 87127047dbf7d948ae98f1ff0f4a782214a516e2
prerequisite-patch-id: 7664165039fb510368a721edfe60f5b67449b7b6
prerequisite-patch-id: 1e8c97720bab512d8646409c129edd6047164c4c
prerequisite-patch-id: f0fdd1e9912f31a3945f1c0f227dcb64cf71885d
prerequisite-patch-id: be515f7e13f7800eaadb3ed85dec6a9ddb733828
prerequisite-patch-id: 3a3c7749e017d9335f58497404d1350e96caf471
prerequisite-patch-id: 3526c9154f581497a11465b936d83ef61a875454
prerequisite-patch-id: 65d8c757b52475c2acc7d22ddc92cd3f0152b55d
prerequisite-patch-id: 4bd31f1414d5248dc080884caadf5f21684a8427
prerequisite-patch-id: 7beadbb0da3e589ed86d12f512d1c83427dd82b4
prerequisite-patch-id: f04f5427c592cb078c08ee071b965ef6fd4a9a48
prerequisite-patch-id: 64c0098c3d2420f82c89f44fccd3eed459557bfc
prerequisite-patch-id: 3294340ecd964b8e3e87e5a787ff1ffa28e0b698
prerequisite-patch-id: b2c14d06f068dc6a52814fc55d1188737dc29861
prerequisite-patch-id: c7fd96983b606bc42cc5b003022b8fa2bb1c0c34
prerequisite-patch-id: 8e9f4c2d5521fb6cdc5bed2d6661f4bbed5eb63d
prerequisite-patch-id: d868f7925ee9dfe44c5ddf50f4deb50263ff203f
prerequisite-patch-id: 5677248690560ec45e512a8cdbbf8aecfad62d77
prerequisite-patch-id: 5d9674da330ee9d0f4c91edb8acc20727ba1cd9c
prerequisite-patch-id: d5f29453bfd2e3354fb96b57d7a55521bedb2b0b
prerequisite-patch-id: 9d6f96e26fe651304e950766d6bc2006dd33e86a
prerequisite-patch-id: c7a73c58c6d4ca8556d29ce651ad78cc647f6f31
prerequisite-patch-id: c5f35030637e78ab6f5fa489172f1506493fbae1
prerequisite-patch-id: aad19e48d4fa45734050bba927a5b72d6def9673

