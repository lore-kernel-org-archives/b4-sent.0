From: Markus Probst <markus.probst@posteo.de>
Subject: [PATCH v14 0/2] Introduce Synology Microp driver
Date: Sun, 31 May 2026 00:57:02 +0200
Message-Id: <20260531-synology_microp_initial-v14-0-1377d425b24b@posteo.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD9rG2oC/43U246bMBAG4FeJuK6Rx+fJ1b5HVUXGHmfRJiELL
 Gq0yrvXEKmlsKS9Qrb0fzbjsT+LjtqaumK/+yxaGuqubi55AOrbrgiv/nIkVsc8UQguDJfcsO5
 2aU7N8XY416Ftrof6Uve1PzGebPTBVlahKXL62lKqf0709x+PcUvvH3mF/jFZnKnr/LTAfjfxm
 mvQQnFeSswDNAxY9G/tyxu1FzqVTXsc5XVO6PxFASUIZdD9b0xykMJKU0qBTiv8Ove7DFNMgwD
 L2o+uP+TSRRoYkVYOCLnTYT8AfJUBUI/MiWLHPGpMNohkE+aEGxOV74iF5nyu+/1usCWwNuhiL
 Nxr3fVNe5uOaICpcv88jAEYZymkRJGMUi68XJuup6aMNJmDmDtu2xHZQekQjUwSgl46cuaA3HZ
 kdnw0PigjveCwdNTMEXzbUdnhSsgYKyeDV0tHzx3cdnR2hA2V41VMGlf7MX8cxfW2Y8b9uBRJW
 VWZgEvHzhyAbceOdfbSc1Rkc4mWjps5z+rjsmNRGY/5Kqj1f+HceXJemB3lnZYyOUvcLh3gc0g
 9acRcH0ZOiyiSpMqvdgQwl+wTaexpDFBF7U224koSc+nJ4cPY1Yr7/MZIGYzgK2nW1vmVeCJNf
 e1FVWHQhtJf9+x+v/8Cw9cX1GAFAAA=
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=12249;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=yTSBo+LGsTtt/6BEuTctYLQ8/lWTaVaRpL15DXNnvP4=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBqG2tC0/F22r6SW6naID2gqoL45gHQ4Op/OjcJc
 Hi2pZr2csiJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCahtrQhsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9LzIQ/9Ew2xmmguoDhHWxEBYfmBe4ezSWowEwN
 k3zAi4npeohyCBvmQ0Xmq2yaWF2X+RktfKsAOKovUe2trrPxfqvN1iutK2/RJMyoS6FgWx0KQc7
 hgLcaffIFvIN7DB6x1gVV5U8yyel7nrryGei8xUQ7n+JUt2N8BlaPQqYf8OMHGvQB3+bASc5q4P
 zkbWY37a2qamUQY5IpZPyWuQlIfUhRFLWIvaMF6cZlP43eeakbG/V22OtT0YQgNDK4RO6UBY1OU
 D+k9FWiq0JY+YIaWnBmju2sqjuJPFhtI2yTtR0Mp7ldo1jxKx+1fUWGUluJdVxZnoeLaZHP0tyH
 z0URnWtO3azt0JVg8zVO0KIyaZtsEenfVZJUgLW1NvuWCFGuqe3UHDXIdrTmmwRFE5vxQPvOTNo
 KYr+yz8PRNrDqNWrfU18ySAdyfjwu6fgQnMJLKxQqbQJW4CZWvOG/TCJdxD2hZdhkL5etJU5rvY
 xnR/mCAHX3m5D+ieXu/+TzG5O8N/u9vb/fQlwmHEH89Xi3PEhA9aUu/e2TX2sTVsvIn/M5wDPNp
 W84fIknI3MuJWaYAiBZWpZ7hooY3r4zTlPWS7ZJfFOcgbtiAQA9XSqrITP0Eqb8n8dwAYsjO9wl
 XqFMbqpJFqaS800zfo/VsgvQYvcK3/gku0bqtJ9ScmhVu6u6eNZE=
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

[1] https://lore.kernel.org/rust-for-linux/20260530-rust_leds-v17-0-c0698c4368e2@posteo.de/
[2] https://lore.kernel.org/rust-for-linux/20260530-rust_serdev-v8-0-2a95f1da22a7@posteo.de/

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
Changes in v14:
- adapt to led abstraction v18 and serdev abstraction v11
- Link to v13: https://patch.msgid.link/20260530-synology_microp_initial-v13-0-aa2bb9c56efc@posteo.de

Changes in v13:
- adapted to driver-lifetime v5 patch series.
- set blink = false as initial power led state, as set_blink hasn't been
  called yet (even though the led is blinking at startup)
- Link to v12: https://patch.msgid.link/20260429-synology_microp_initial-v12-0-40a05033c620@posteo.de

Changes in v12:
- adapted to driver-lifetime patch series. The driver can't take
  advantage of it, until class devices like led also make use of it.
- Link to v11: https://patch.msgid.link/20260427-synology_microp_initial-v11-0-9c1bd5a6f3ed@posteo.de

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
 drivers/platform/synology_microp/led.rs            | 297 +++++++++++++++++++++
 drivers/platform/synology_microp/model.rs          |  49 ++++
 .../platform/synology_microp/synology_microp.rs    |  91 +++++++
 10 files changed, 617 insertions(+)
---
base-commit: 9e171fc1d7d7ab847a750c03571c87ac3c17bd84
change-id: 20260306-synology_microp_initial-0f7dac7b7496
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
prerequisite-message-id: 20260530132736.3298549-1-dakr@kernel.org
prerequisite-patch-id: 310c6bee038ca3909a8e5e58ec12b74f7189b869
prerequisite-patch-id: 92812c3d42b29504838e6dc66c307ff5c035bb5e
prerequisite-change-id: 20251217-rust_serdev-ee5481e9085c:v11
prerequisite-patch-id: 45128665162dd9f51a0764deb3815a338948b291
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
prerequisite-patch-id: 310c6bee038ca3909a8e5e58ec12b74f7189b869
prerequisite-patch-id: 92812c3d42b29504838e6dc66c307ff5c035bb5e
prerequisite-patch-id: 26cf819caf22fa5bb25b70a855d9f3d852ffea32
prerequisite-patch-id: 19eb53ce0c653c1406f8f192f6ad158fb4bd8d8f
prerequisite-patch-id: 55d6a70baf3be7f4da36b82cf02a5a7d59457520
prerequisite-change-id: 20251114-rust_leds-a959f7c2f7f9:v18
prerequisite-patch-id: 45128665162dd9f51a0764deb3815a338948b291
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
prerequisite-patch-id: 4d3ac33ad5f5b6358ad5d72b57fb692a70ff03bf
prerequisite-patch-id: 50bfe4b15f07d3733d4fc4b4520ce74cbac2cf4f
prerequisite-patch-id: 19f2c7abf0b0ca888bff7097a2e039d3676eb1dc

