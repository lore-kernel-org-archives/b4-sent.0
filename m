From: Markus Probst <markus.probst@posteo.de>
Subject: [PATCH v7 0/2] Introduce Synology Microp driver
Date: Sat, 11 Apr 2026 17:27:33 +0200
Message-Id: <20260411-synology_microp_initial-v7-0-9a3a094e763a@posteo.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGVo2mkC/4XP3WrCMBgG4FspPV4k/z892n2MIWnyRQPauKaGi
 Xjvi3VgcZQdvoH3yftd2wxjhNx2zbUdocQc01CDemtat7fDDlD0NbcUU4kZlihfhnRIu8v2GN2
 YTts4xCnaA8JBeetUr7iRbW2fRgjxe5Y/Ph95hK9z/WB6PD79rqm6IJQoNJ7ztK2TPBQEILgmY
 LAWriu8XU76rRDCH5UD+IysESYoR4MKpiuE3Ru9zYBcOh7j1DVFbTAanWrvg/YxT2m8zJcXMi/
 698hCEEbBhQAeJOfavZ9SniBtPMxmoUtHrzu0OoZpYyQLjDjx6rCFQ9i6w6pjvbSOS2YpJq8OX
 zgUrzu8OphT5n2vmbP81RFLx6w7ojpUuV7j3gdh/uyRT4djse7I+x4dPHDFe+nM0rndbj8gfKo
 /twIAAA==
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
 rust-for-linux@vger.kernel.org, Markus Probst <markus.probst@posteo.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=4786;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=A8CCeIhnd3vhy/1oIiAFXzrtseCwEOCPaMseinTRet0=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBp2mhqGT6q5DTwnqjwppI2xNehM5aei3zePYotJ
 puO6kPuGgSJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCadpoahsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9I3MA//XXO76LbZ0+bsX3Vj1jo5NyvOLcLnIuc
 yOAgL20xNCn02F+wDWXVX91ePWhSfAq2IH5nuEZTcPkZKONuFg1Zk7oy+8VZhutYaxJxEJXihan
 1PtJkbD7rougMs9gRjPw6i1PQM8vmx/fbuBuHkAYpeGCQI4YssQssgN+V8AMADAHGpzSiQFCRSJ
 wWCjIC2+EgNeXOU7fbbqAM8JBXWGS3iiWHOn1vVO79hVzkPF9H5spmWjTHW3COYMl8YEjYwmgkw
 hT8JT0qq3nconaC1dMYd5gBFSEIa02WkmLzHD4YUenovGOMlBBeBBP22s9Xjq3acaAVzB7rMDL/
 vpslXNJzgO3LzbcoMX7f3tfU/V9DJAM4J+3gf1xSWbtVeNR5Z/5vlH7dmks+e4tg0z8/eUgFMnC
 +rA4i1sALtT6SZpBSIlLoajXlVZwcrDYdAHfF0320ewCEZaK4SId/Ejf5BJXFDn/crVkR0bPQQu
 UikIsmSP2jaNFo4I6Vf90OkVUQyNRGIRdsr/YDnPoposOLgO9u1+gNNUZDGa2tH1bjJdT88ei15
 T/PPvncS08VcSoMVXW7o4HMOlO4+kXbr3e+RU+iO16XFhZean5mDOgmcnt0WznOe6C+477SltOc
 bGDtrL8oYOrLQiprxaqufz5wF7NSYkjdlHOLUFL2xfLC4KOx714c=
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
- sysoff handler + hardware protection shutdown (include/linux/reboot.h)

[1] https://lore.kernel.org/rust-for-linux/20260329-rust_leds-v13-0-21a599c5b2d1@posteo.de/
[2] https://lore.kernel.org/rust-for-linux/20260411-rust_serdev-v4-0-845e960c6627@posteo.de/

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
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
      platform: Add initial synology microp driver
      dt-bindings: embedded-controller: Add synology microp devices

 .../synology,ds923p-microp.yaml                    |  92 +++++++
 MAINTAINERS                                        |   6 +
 drivers/platform/Kconfig                           |   2 +
 drivers/platform/Makefile                          |   1 +
 drivers/platform/synology_microp/Kconfig           |  13 +
 drivers/platform/synology_microp/Makefile          |   3 +
 drivers/platform/synology_microp/TODO              |   7 +
 drivers/platform/synology_microp/command.rs        |  55 ++++
 drivers/platform/synology_microp/led.rs            | 276 +++++++++++++++++++++
 drivers/platform/synology_microp/model.rs          |  49 ++++
 .../platform/synology_microp/synology_microp.rs    | 109 ++++++++
 11 files changed, 613 insertions(+)
---
base-commit: 0e5d0a0b5ca6ea4e391d6786266405c5871e0151
change-id: 20260306-synology_microp_initial-0f7dac7b7496
prerequisite-change-id: 20251217-rust_serdev-ee5481e9085c:v4
prerequisite-patch-id: 52b17274481cc770c257d8f95335293eca32a2c5
prerequisite-patch-id: eec47e5051640d08bcd34a9670b98804449cad52
prerequisite-patch-id: f24b68c71c3f69371e8ac0251efca0a023b31cc4
prerequisite-patch-id: d0686cf451ef899a06d468adfba51ccd84e6ff98
prerequisite-change-id: 20251114-rust_leds-a959f7c2f7f9:v13
prerequisite-patch-id: 818700f22dcb9676157c985f82762d7c607b861e
prerequisite-patch-id: b15ffa7d95d9260151bfb116b259c4473f721c82
prerequisite-patch-id: 8c47e0d107530f577a1be0b79f8ee791f95d3cbe

