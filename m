From: Markus Probst <markus.probst@posteo.de>
Subject: [PATCH v8 0/5] rust: add basic serial device bus abstractions
Date: Sat, 30 May 2026 03:13:48 +0200
Message-Id: <20260530-rust_serdev-v8-0-2a95f1da22a7@posteo.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAM05GmoC/23S227DIAwG4FepuB4RBsyhV32PaZpI4rTR1qaDN
 NpU9d1H0k1L0l0hI32/wPaVJYotJbbdXFmkoU1td8qFe9qw6hBOe+JtnWsmhUSQYHm8pP41o5o
 GToTaAXnhsGJZnCM17eeU9vyS60Ob+i5+TeEDjLc/OVIscgbggpPWRqM11kjYnbvUU1fUxMacQ
 f5aI5QwSytH60upSi1Libi2amZBLa3KtvJBhUaCbmyztvrPaoCl1dk6jeSNqIyRdm1xZtf/xWz
 RkiuDQPCNWlszt8ueDyZbsMp6VyNBeLB2bv3S2mxF7XxlPZRYubm93QcY6eOSt6C/T5EdKaUwb
 cF2M2VifjFKLUShfC684cDr8BZ3bxRP9F50cT+uwqOTmE8voQCpjXf/szIk4lV3PLb9djPYIve
 8wvy22zefPfmyqQIAAA==
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=5465;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=Eq5xsqcn55u0Ff87cFqRGAjzzecSn1a5prQhi/eFhS8=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBqGjnOU8wGXkRMtzMSZNOKQGnidFid2NrtiMOVT
 y1Gc4nZjzmJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCaho5zhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9KVTw//WE+ZArGGFvVHz8oNLVGejz+CKNCAEfB
 bTVVd7w+3ETjYK5VfisxskjRukKxBeZh87y6tweGxcIdTPq/23DyrYL+FoxanZRlUf9iV+NeX4Z
 KrPY6Rsvjxw5cNGKwJ7SRryRFcJJCnNCVCBGyO+Odmk2n3ln3XYE6RfWv8V0RqpheLK3T8bpAy1
 SU9Q8NGz0mHH2xQmZ9+jGk6nagxWtoEziz+JjjP9psX5SIZmkmawtNOmoHlqbv1mRKs7UBLWGxM
 N8Aj7k4mAqHloHWEpMYyZd3uHbEBRByZNM1cobzpuvFILYIpImB/YsFu602Dak+vWUPbU13Df9W
 i16wqpxig6kmDFkDV/wJtFIyE4kgSAGgI5SpE/GYA9yLtRWa8Buvdpo5AwkmNfCnhcfWsZSLFp2
 UYJaz/YFVybWH/YhtXwvDdC8zwuOnDRpj19/uluKMSaGjIlBrEZM0MAc3lqomrhYqck8vygv/3q
 R+/iHPdECBi4C89koF2jlFblYE3pHT7ei2fLtqWB/9IjP6tlsjLfI+IxBpwvEbr+YjKnZmzWEco
 fd0hF9mO3LVHqbqyCrmzQw0oCrUmJ14fx71LlPyVRGbr4q+YSkQR4bsSNl5XOls9HtMFJFqGZR6
 I3thtfu+CexK61oQLfAgJ9U4OuEo5VmeAWZOE2h+vdjH6oNaMrFw=
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

This series depends on [1].

[1]
https://lore.kernel.org/rust-for-linux/20260525202921.124698-1-dakr@kernel.org/

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
Changes in v8:
- adapted to driver-lifetime v5 patch series
- add MAINTAINERS file patch
- Link to v7: https://patch.msgid.link/20260429-rust_serdev-v7-0-0d89c791b5c8@posteo.de

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
Markus Probst (5):
      rust: devres: return reference in `devres::register`
      serdev: add rust private data to serdev_device
      rust: add basic serial device bus abstractions
      samples: rust: add Rust serial device bus sample device driver
      MAINTAINERS: serdev: Add self for serdev

 MAINTAINERS                        |   5 +-
 drivers/tty/serdev/Kconfig         |   7 +
 include/linux/serdev.h             |  15 +-
 rust/bindings/bindings_helper.h    |   1 +
 rust/helpers/helpers.c             |   1 +
 rust/helpers/serdev.c              |  22 ++
 rust/kernel/cpufreq.rs             |   3 +-
 rust/kernel/devres.rs              |  15 +-
 rust/kernel/drm/driver.rs          |   3 +-
 rust/kernel/lib.rs                 |   2 +
 rust/kernel/serdev.rs              | 548 +++++++++++++++++++++++++++++++++++++
 samples/rust/Kconfig               |  11 +
 samples/rust/Makefile              |   1 +
 samples/rust/rust_driver_serdev.rs |  91 ++++++
 14 files changed, 714 insertions(+), 11 deletions(-)
---
base-commit: 9e171fc1d7d7ab847a750c03571c87ac3c17bd84
change-id: 20251217-rust_serdev-ee5481e9085c
prerequisite-message-id: 20260505152400.3905096-1-dakr@kernel.org
prerequisite-patch-id: d2aebf69b153c039bbed1d0ed26906708fd22534
prerequisite-patch-id: 84b28da2f5de20fc1785095c647b2ffc35d969a5
prerequisite-patch-id: 67318671a5eed5fb4ad23a450f1cf0e442bf8ca2
prerequisite-message-id: 20260525202921.124698-1-dakr@kernel.org
prerequisite-patch-id: b84db329d4372a175cb8d49e4e88c3eecf7eb228
prerequisite-patch-id: 2c30303f409cc8288cc87e241920219f5ddd8390
prerequisite-patch-id: 4e4f0ad370d763ad00b0f75b91fa216f2cc95953
prerequisite-patch-id: 5bcd6b37f3498feebda275dfef78136eba34004e
prerequisite-patch-id: 872b0982f3e5e7d1698d9df3b325e4cd27b27789
prerequisite-patch-id: 3a3c7749e017d9335f58497404d1350e96caf471
prerequisite-patch-id: 3526c9154f581497a11465b936d83ef61a875454
prerequisite-patch-id: 65d8c757b52475c2acc7d22ddc92cd3f0152b55d
prerequisite-patch-id: 4bd31f1414d5248dc080884caadf5f21684a8427
prerequisite-patch-id: 7beadbb0da3e589ed86d12f512d1c83427dd82b4
prerequisite-patch-id: 12cd0f67ffd27347f90c065db491945908206b7f
prerequisite-patch-id: 4642e31f66331f6c3b579377111ea733dbb3a11c
prerequisite-patch-id: 52d67b40b4396c741e2222d6a5bc7927abcb77aa
prerequisite-patch-id: 74ca82ff26cf9c7a993757c87db8be62006e820f
prerequisite-patch-id: 466fb9fa7febbffd8ef51b311c7d9893c11fc0f0
prerequisite-patch-id: e515cd98b06e26721cbbe6a4fbacd251d0073b63
prerequisite-patch-id: 8dc8e75d9f6499a554ef7e474bbacdbf3660a9f2
prerequisite-patch-id: 5fdb9f71dca2f44dd293760a60db125b770f1f55
prerequisite-patch-id: c766a24c2d5064f5ec09daada0b8e8fba862d3aa
prerequisite-patch-id: b768f6456d35fa7a80c015e34bbdba6082dbd593
prerequisite-patch-id: 6a8b17234f12f7084e6e2ce843a7031b0a891ce4
prerequisite-patch-id: 98b2deb9e60c1f28f90c5ee34fd608aaa9fd9420
prerequisite-patch-id: 774b29be66e641ee50cedb4704cf49d8b9fabf50
prerequisite-patch-id: cf95dc936cfc4b3a7a363435a51a48d9009645b3

