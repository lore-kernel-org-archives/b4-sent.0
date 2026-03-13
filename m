From: Markus Probst <markus.probst@posteo.de>
Subject: [PATCH v3 0/7] Introduce Synology Microp driver
Date: Fri, 13 Mar 2026 20:03:04 +0100
Message-Id: <20260313-synology_microp_initial-v3-0-ad6ac463a201@posteo.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGhftGkC/4WPzYqDMBSFX0WynpT8qDGu5j2GIja5aQNqbJKGS
 vHdJ9WBcTPM8lz4vnvOCwXwFgJqixfykGywbsqBfxRI3frpCtjqnBEjrCac1DgskxvcdelGq7y
 bOzvZaPsBEyN0r8RFlLJGmZ49GPvczF/nPXu4P/KDuB9//W2R7RVlVGD/CLHLlTQkDFCVDQVJm
 kq1iaNjpR+E0nJHBtAB97KSRihmhJFtouxNXPoAWLlxtLEtkjgR7BVH70I3G6Lzy7Y80a3RvyM
 TxQQbZQxoqMuyUZ+zCxHcScPmTOzoaf72sOyRvJGy5oZTVR0967p+A3mvwYWXAQAA
X-Change-ID: 20260306-synology_microp_initial-0f7dac7b7496
To: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, "Rafael J. Wysocki" <rafael@kernel.org>, 
 Igor Korotin <igor.korotin.linux@gmail.com>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Len Brown <lenb@kernel.org>, 
 Robert Moore <robert.moore@intel.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, driver-core@lists.linux.dev, 
 linux-pci@vger.kernel.org, linux-leds@vger.kernel.org, 
 linux-acpi@vger.kernel.org, acpica-devel@lists.linux.dev, 
 Markus Probst <markus.probst@posteo.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=4556;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=IrWyWb2kxV5OzeytoBcovDqq1Y5EzHRPfMuaRrJQiho=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBptF9s60d+pfHXse4ikbSkzVo5yY/0L5v1i+qBg
 TKkCKvUvGyJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCabRfbBsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMSwyLDIACgkQNHYf+OetQ9JAbRAAr25iOrm9PmSuwLH7/Y66yv/KUAEuYdW
 exSVg+xJgFhAPn58kruRMn4VglsHwSVAHbkfdBdCS6yCxpZ5WGYGnzOCQHkMQ/BlRWvHl08eDM6
 uSlLgexXZ+xT7ZoF/jhqf5Zc+vmnXUX2vnkFlYxNRSxbJEsAs0eGNLBV1cNOCXfuYnb6usMKf2+
 RWAWNVyPpBkrY3uDl5enzgzCD5haN7sf8QUfBc0q5FOBt5kJuuO3mDhK+uTV9nYSd7IhYv+cUf6
 KpOuxyaumzvP+2rn4KLoewNgnjQOzDeH91ySfAR8LamR4MGksKzrVzqoJ0u4Z0yF7SA62OmHZY/
 o6Wm4VIYa9y9O+FaqSFWi3xBW00XRJbGMtSopeIS6opVoagfs+igz8rVpA+JnIUd3VhJbfiF/t+
 J0cBzpK6GVnk5rCWogmqyBkYnFiOVnNs/inp+rDBX2OffaEm5DYNtT5zwj62/8bS6unyDqxJMFL
 6suoClqKFH08xiMq1XDjORs3m9WoW3aSpIxsXWCKcLLyPY82WEQSqdnnLMXB9LcNFPchOTgEwMw
 NEMpXvLtM7qoWQ3Hir6QoUMwB9o+4YuiSQZcJCqHq1fLVJOvOAcGz6SKDS7SE6bsHBarqIfFD/C
 QO3aGQVaztrrHVoW5bBNVmND0iyTD5xZBLOAoLheJFvdClt9SCag=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Apparently my email provider refused to send the whole patch series,
because of a 100 receiver per hour limit to protect against spam
(according to the error message). Please ignore the previous submission.

Synology uses a microcontroller in their NAS devices connected to a
serial port to control certain LEDs, fan speeds, a beeper, to handle
proper shutdown and restart, buttons and fan failures.

This patch series depends on the rust led abstraction [1] and the rust
serdev abstraction [2].

This only adds the core driver and led driver.
The following rust abstractions would be required, to implement the
remaining features:
- hwmon (include/linux/hwmon.h)
- input (include/linux/input.h)
- sysoff handler + hardware protection shutdown (include/linux/reboot.h)

[1] https://lore.kernel.org/rust-for-linux/20260207-rust_leds-v12-0-fdb518417b75@posteo.de/
[2] https://lore.kernel.org/rust-for-linux/20260313-rust_serdev-v3-0-c9a3af214f7f@posteo.de/

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
Changes in v3:
- remove `default n` from Kconfig entry, as n is the default already.
- select RUST_SERIAL_DEV_BUS_ABSTRACTIONS in Kconfig
- add mfd rust abstraction
- split core and led parts into their own driver. It should now be considered a
  MFD device.
- split led part of dt binding into its own file
- Link to v2: https://lore.kernel.org/r/20260308-synology_microp_initial-v2-0-9389963f31c5@posteo.de

Changes in v2:
- fix missing tabs in MAINTAINERS file
- remove word binding from patch subject
- add missing signed-off-by
- add missing help entry in Kconfig
- add missing spdx license headers
- remove no-check{,-cpu}-fan properties from the dt-bindings and replace
  them with the check_fan module parameter
- use patternProperties for leds in dt-bindings
- license dt-binding as GPL-2.0-only OR BSD-2-Clause
- move driver from staging tree into mfd tree and mark it as work in
  progress inside Kconfig
- only register alert and usb led if fwnode is present
- Link to v1: https://lore.kernel.org/r/20260306-synology_microp_initial-v1-0-fcffede6448c@posteo.de

---
Markus Probst (7):
      rust: Add `parent_unchecked` function to `Device`
      rust: add basic mfd abstractions
      acpi: add acpi_of_match_device_ids
      mfd: match acpi devices against PRP0001
      dt-bindings: mfd: Add synology,microp device
      mfd: Add synology microp core driver
      leds: add synology microp led driver

 .../devicetree/bindings/leds/synology,microp.yaml  |  40 +++
 .../devicetree/bindings/mfd/synology,microp.yaml   |  51 ++++
 MAINTAINERS                                        |  14 +
 drivers/acpi/bus.c                                 |   7 +
 drivers/leds/Kconfig                               |  11 +
 drivers/leds/Makefile                              |   1 +
 drivers/leds/leds_synology_microp.rs               | 303 +++++++++++++++++++++
 drivers/mfd/Kconfig                                |  11 +
 drivers/mfd/Makefile                               |   2 +
 drivers/mfd/mfd-core.c                             |  27 ++
 drivers/mfd/synology_microp.rs                     |  46 ++++
 include/acpi/acpi_bus.h                            |   2 +
 rust/bindings/bindings_helper.h                    |   1 +
 rust/kernel/device.rs                              |  25 +-
 rust/kernel/i2c.rs                                 |   7 +
 rust/kernel/lib.rs                                 |   1 +
 rust/kernel/mfd.rs                                 | 114 ++++++++
 rust/kernel/pci.rs                                 |   7 +
 rust/kernel/platform.rs                            |   7 +
 rust/kernel/serdev.rs                              |   6 +
 rust/kernel/usb.rs                                 |   7 +
 21 files changed, 688 insertions(+), 2 deletions(-)
---
base-commit: 3daa4f5dc6cc1ac1ab2f95b5b4c16bc5fb87f48f
change-id: 20260306-synology_microp_initial-0f7dac7b7496
prerequisite-change-id: 20251217-rust_serdev-ee5481e9085c:v3
prerequisite-patch-id: 52b17274481cc770c257d8f95335293eca32a2c5
prerequisite-patch-id: eec47e5051640d08bcd34a9670b98804449cad52
prerequisite-patch-id: f24b68c71c3f69371e8ac0251efca0a023b31cc4
prerequisite-patch-id: 3dfc1f7e5ecd3e0dd65d676aeb16f55260847b25
prerequisite-change-id: 20251114-rust_leds-a959f7c2f7f9:v12
prerequisite-patch-id: 42c445ef6981e3a3740dbaaf307f4b810042e46f
prerequisite-patch-id: 90c7b200cca722a592353885e21af069101c4e09
prerequisite-patch-id: c664a52faa3d47000d252eb7603c9c08382e868a

