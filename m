From: Markus Probst <markus.probst@posteo.de>
Subject: [PATCH v11 0/2] Introduce Synology Microp driver
Date: Mon, 27 Apr 2026 20:12:38 +0200
Message-Id: <20260427-synology_microp_initial-v11-0-9c1bd5a6f3ed@posteo.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABan72kC/4XSzW7jIBAH8FeJfC4VA8OXT32PahVhGFqkJE6Na
 21U5d2XOId6XTk9MtL8+M/AV1NoyFSadvfVDDTlkvtTPQA87Zrw7k9vxHKshUZwobnkmpXLqT/
 0b5f9MYehP+/zKY/ZHxhPJvpgOoNON7X7PFDKf2f69c/9PNDHZ71hvBe//XZXdQUCDBs+y7ivm
 SJNjEihBXLcqtBOM7puAcB7y4FiYd4pl0wQySTXToC3js4XYqE/HvPY7ibzDGwI0NwCvecy9sN
 lHn2COdGvQ07AOEshJYqkEW14OfdlpP450mxOYunYbUdUx0nrnJZJQlBrRy4ckNuOrI6P2gfU0
 gsOawcXjuDbDlaHo5AxdlYGj2tHLR237ajqCBM6y7uYlPuRR387yNW2o295bIqEBjsd3NoxCwd
 g2zG3PXvpuUMydUVrxy6cR/ux1TEOtXcgEH/O5ZbOg/dy1UFvlZTJGuJm7QBfQvjgI9b9MLJKR
 JEkdf6/RNfr9R9hfXWV2gMAAA==
X-Change-ID: 20260306-synology_microp_initial-0f7dac7b7496
To: Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Miguel Ojeda <ojeda@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: platform-driver-x86@vger.kernel.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, Markus Probst <markus.probst@posteo.de>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6107;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=UdG0Y3AzgBhVD5fbYvF/r1RlsPIe/pDq4iIEOXkt55Q=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBp76cZY43+JXV0zU7jUWnPpJio9bHcx8O4/zp7G
 ba+iHsCSauJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCae+nGRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9I0qA//cxHSwP79AllLalTIKQT+fRxW+mC8kfa
 YTcpwzsByTqn/zKWXJt6lIja1AeVEIZNTSPt72CmneOisWSKMXP8gmpkbPS0xrNzZpWgV33Za8b
 2oRjrH/vky4Emi61hwO6kt3p6iUnh9sCm7RoU9A615sIg3niF8bY1G6gdxubUkTsv9IHngl9qIy
 Qy32ei5AUZ/lrU/Pi8KOY3QkbezaHgS90aZk/ncJTy0TrJS2T4iXAoKuuwkpF5jNN58B5d+19uw
 EkpDz4D4/sdfb9+hrZdNcI/c3zcPkB4jh5gRuWouvOMz2eySZtD44x3niSgbIqy8JEpmxZHsoIn
 k+aORsUnJTSG66HKf7ygGBVN/jgvlZW/LAKrgki4pw7jqNzJWUVOVpdothtMPadD6Cs3S7dCreq
 8tMFJW3KvhEKfYJG9tu9frqelVKjMZ2zy6er/HkIXsLNwLD+r5l7G2sN69X1Ttv2qtfMojUWZps
 mrYEMy+eS9zeGRvSXVCIC8WYIrqIE+/T0y4A81dbUAf7oMJ10R39ymSnpPK6yVdg4feFgbJG8wE
 l4Q2dlIyjs06cxil3gv7n4ufvizupHmsLyO522mVLQPZ0g9xMZcXCxml/g7EfLe19N63LsfpBPM
 og6wgmExmiykbW6ljAfAwMAmD844Dp4XFFsWTxckNn7+7H4GMUNo=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Synology uses a microcontroller in their NAS devices connected to a
serial port to control certain LEDs, fan speeds, a beeper, to handle
proper shutdown and restart, buttons and fan failures.

This patch series depends on the rust led abstraction [1] and the rust
serdev abstraction [2].

This is only a initial version of the driver able to control LEDs.
The following rust abstractions would be required, to implement the
remaining features:
- hwmon (include/linux/hwmon.h)
- input (include/linux/input.h)
- sysoff handler (include/linux/reboot.h)

[1] https://lore.kernel.org/rust-for-linux/20260427-rust_leds-v14-0-4f4b17e5d516@posteo.de/
[2] https://lore.kernel.org/rust-for-linux/20260427-rust_serdev-v6-0-173798d5e1a3@posteo.de/

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
Changes in v11:
- rebased on top of 7.1-rc1
- add "synology" as devicename to led, like it is done in existing dts
  files in the kernel
- fix color for led being orange instead of amber. I personally can't
  clearly tell them apart, but apparently its amber.
- replaced MCU with EC in Kconfig help
- Link to v10: https://patch.msgid.link/20260424-synology_microp_initial-v10-0-e852d2f3eba1@posteo.de

Changes in v10:
- resolved issues reported by Sashiko Bot:
  - removed unneeded include from device tree
  - fix typo in of device table
  - fix blink not set to false, if delay_off or delay_on is 0
- Link to v9: https://patch.msgid.link/20260423-synology_microp_initial-v9-0-4a8533f87e07@posteo.de

Changes in v9:
- separate fallback and front compatibles in dt schema
- remove front compatibles from of id table, if all functionality is
  by covered by the fallback
- remove TODO file
- add platform-driver-x86@vger.kernel.org to Maintainers file entry
- use `Delta` type in `BLINK_DELAY` const
- Link to v8: https://patch.msgid.link/20260420-synology_microp_initial-v8-0-7946a9124491@posteo.de

Changes in v8:
- removed unnecessary Copy and Clone derive
- added `BLINK_DELAY` constant
- added compatible id fallbacks
- moved dt schema patch before the driver
- added ds411p
- Link to v7: https://lore.kernel.org/r/20260411-synology_microp_initial-v7-0-9a3a094e763a@posteo.de

Changes in v7:
- remove list of compatible ids from commit msg
- explain what makes the different models not compatible in the commit msg
- remove unnecessary examples
- Link to v6: https://lore.kernel.org/r/20260405-synology_microp_initial-v6-0-08fde474b6c9@posteo.de

Changes in v6:
- moved devicetree bindings patch at the end of the set
- remove several patches
- move of id table from model.rs to synology_microp.rs
- remove the model! macro
- use if blocks in devicetree schema to narrow down the
  fan-failure-gpios property
- add multiple devicetree examples to test if blocks
- Link to v5: https://lore.kernel.org/r/20260329-synology_microp_initial-v5-0-27cb80bdf591@posteo.de

Changes in v5:
- add esata led support
- use different compatible for each model
- add visibility modifier to of_device_table macro
- fix match data missing when using PRP0001
- Link to v4: https://lore.kernel.org/r/20260320-synology_microp_initial-v4-0-0423ddb83ca4@posteo.de

Changes in v4:
- convert to monolithic driver and moved it into drivers/platform
- removed mfd rust abstraction
- moved dt-bindings to embedded-controller
- Link to v3: https://lore.kernel.org/r/20260313-synology_microp_initial-v3-0-ad6ac463a201@posteo.de

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
Markus Probst (2):
      dt-bindings: embedded-controller: Add synology microp devices
      platform: Add initial synology microp driver

 .../synology,ds918p-microp.yaml                    | 100 +++++++
 MAINTAINERS                                        |   7 +
 drivers/platform/Kconfig                           |   2 +
 drivers/platform/Makefile                          |   1 +
 drivers/platform/synology_microp/Kconfig           |  13 +
 drivers/platform/synology_microp/Makefile          |   3 +
 drivers/platform/synology_microp/command.rs        |  54 ++++
 drivers/platform/synology_microp/led.rs            | 287 +++++++++++++++++++++
 drivers/platform/synology_microp/model.rs          |  49 ++++
 .../platform/synology_microp/synology_microp.rs    |  90 +++++++
 10 files changed, 606 insertions(+)
---
base-commit: 5e9b7d093f3f77cb0af4409559e3d139babfb443
change-id: 20260306-synology_microp_initial-0f7dac7b7496
prerequisite-change-id: 20251217-rust_serdev-ee5481e9085c:v6
prerequisite-patch-id: 52b17274481cc770c257d8f95335293eca32a2c5
prerequisite-patch-id: 6ab09768759461c6bea5d4a0833d50e3e41067f1
prerequisite-patch-id: 8df2fcbdf925250fd8b768c48d4d4224a431c987
prerequisite-patch-id: d0686cf451ef899a06d468adfba51ccd84e6ff98
prerequisite-change-id: 20251114-rust_leds-a959f7c2f7f9:v14
prerequisite-patch-id: bffdc634baa213e70eacc27b52033b16bd7451c4
prerequisite-patch-id: b15ffa7d95d9260151bfb116b259c4473f721c82
prerequisite-patch-id: 144f13648788a554a03be98ee572e00bd985fa0f

