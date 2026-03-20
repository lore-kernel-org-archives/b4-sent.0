From: Markus Probst <markus.probst@posteo.de>
Subject: [PATCH v4 0/2] Introduce Synology Microp driver
Date: Fri, 20 Mar 2026 23:09:52 +0100
Message-Id: <20260320-synology_microp_initial-v4-0-0423ddb83ca4@posteo.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALHFvWkC/4XP32rDIBgF8FcJXs/iv2jM1d5jjGL1sxXamGoqK
 yXvPpsMFgZll0c4P8/3QBlSgIz65oESlJBDHGoQbw2yJzMcAQdXM2KEScKJxPk+xHM83veXYFM
 c92EIUzBnTLxyxqqDElqi2h4T+PC1yB+fa05wvdUPpvXx1++bqreUUYXTLU/7OslBwQCt6Cho0
 rW2LxxtJ/1UKBVr5QwuY6Nb7ZVlXnndF8qejYPJgG28XMLUN0XtCE5WoOegU8hTTPfl8kKXRf8
 eWSgm2FvvwYEUorPvY8wTxJ2DxSxs63SvHVYdzTutJfec2vavwzcO5a8dXh3jpLFCcsMI3TrzP
 H8DhvMD3d8BAAA=
X-Change-ID: 20260306-synology_microp_initial-0f7dac7b7496
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Miguel Ojeda <ojeda@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, Markus Probst <markus.probst@posteo.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3729;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=LC5mjspC1p41SMU+/gd1k5LdVQSaR5oU7FQTL3cog7M=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBpvcXcnfQYGMaIEfEGVHsnjJVhAf6oxpw3VdwXO
 HSS1TWcOX+JAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCab3F3BsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMSwyLDIACgkQNHYf+OetQ9IfOQ//XhipXoZ9itNPbViGGCLRMr33AbsI+H+
 vuU+wNsQkUTXhJV9xlsEnvQuZwORw4M5Srz/nKCtrQ+3H56UHB87YrGQQNJYVLArba5c9Tv2GHE
 da5XZHhMHETcJlKrSzrsZaJksuZMYKkmraqNgHUR+MxVbuJZxzZ1PZhQ+Y5XdA8AUw0x6WMd1bh
 0ziCQj0mCYz/GYNwyta+s2ZWFOEQHmLsLDrEh5tu81/JcidlBh7anKjeXcB30XtcCk5CDpJ8F0I
 NeioWyiW5CaIXN7E/m012kqeSSOn9ux4b99wBCKCDuM0+GZK+kAa4DMHEKs7fNM6NcVebUnPtUv
 Kb7JZy4yeIFVhc/zwJc6X1Qh3eCLGP96w3ekTMCTWwEF/WiCjgp3G+vFcT21AGemTZZNKmt4zis
 uPE0t6ziTNORC00O6RT5QDcEHhQiBYrjSEjl4a1WwCrMrsogRwKhwj08uFA7xk8+O59l1clrU+5
 uqx45h2hmIN/zX23ayksq/789MbXmXSCvWUGW93A44F/oTATeGy3WxjHu1TaJqS8QyOLvWDsld9
 b5cMQs48j8EFDXV9trgT3RCf4E/8jwa2Ib+bO21sUjHDJODQa5O5F9rMEmqNIi4RTwC+9dZoLQS
 6u+R32Ls+C2nS8D80m7nhPKsrY6yj04nrKDEPYLAiYQsOEP2hlis=
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

[1] https://lore.kernel.org/rust-for-linux/20260207-rust_leds-v12-0-fdb518417b75@posteo.de/
[2] https://lore.kernel.org/rust-for-linux/20260313-rust_serdev-v3-0-c9a3af214f7f@posteo.de/

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
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
      dt-bindings: embedded-controller: Add synology,microp device
      platform: Add initial synology microp driver

 .../embedded-controller/synology,microp.yaml       |  52 +++++
 MAINTAINERS                                        |   6 +
 drivers/platform/Kconfig                           |   2 +
 drivers/platform/Makefile                          |   1 +
 drivers/platform/synology_microp/Kconfig           |  13 ++
 drivers/platform/synology_microp/Makefile          |   3 +
 drivers/platform/synology_microp/TODO              |   7 +
 drivers/platform/synology_microp/command.rs        |  50 ++++
 drivers/platform/synology_microp/led.rs            | 254 +++++++++++++++++++++
 .../platform/synology_microp/synology_microp.rs    |  58 +++++
 10 files changed, 446 insertions(+)
---
base-commit: 34cb4f916af10153c87fabaf6c34e4cafa170427
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

