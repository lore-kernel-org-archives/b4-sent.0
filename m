From: Markus Probst <markus.probst@posteo.de>
Subject: [PATCH v22 0/3] rust: leds: add led classdev abstractions
Date: Sun, 12 Jul 2026 19:26:42 +0200
Message-Id: <20260712-rust_leds-v22-0-055b0459a079@posteo.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XT22reMAwA4Ff5yfVSLMXyoVd9jzKGD/IaWJs2S
 cNG6btX+UtJXLMbg40/2Zalt27heeSlu728dTNv4zJOTzJB/HHp0kN4+s39mGWhQ4UEALqfX5f
 11x/OSx88+WITFlt8J/ufZy7j32uw+58yfxiXdZr/XWNvbl/9ikKnKJvrVZ990FAGIhrc3fO0r
 DzdZO72KJs/S3+WXqQzCSgH8MoM3yWoL2oUKHOmoMSyCkBGO6eLbywcVobKglhylCG5yKhSY/F
 sbWVRbMmRwGmw0VJjh8MOWD0XBrEIgbxPFDFDY/VhNdbnarG66AiWKROYxtLZ1ueSWG/Z24iWY
 2zvbA5LCiprdlvkJSVzTrnNsz3ZQVXWik3KeJf0YBxjY93Z1udeq0pZUBgDgVWN9YeVTFd2rys
 MYuWPOXBTV3iqK1PnCve6KtoPIcqVoi6Nhf9buP6RKuDJ+lzn+f2zwWZ+eZUmXT+7rIth4T5Nj
 4/jenvZ7I3UaULZ/P4By77dX9kDAAA=
X-Change-ID: 20251114-rust_leds-a959f7c2f7f9
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Dave Ertman <david.m.ertman@intel.com>, Leon Romanovsky <leon@kernel.org>, 
 Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, "Rafael J. Wysocki" <rafael@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Ira Weiny <iweiny@kernel.org>, Boqun Feng <boqun@kernel.org>
Cc: rust-for-linux@vger.kernel.org, linux-leds@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pci@vger.kernel.org, 
 Markus Probst <markus.probst@posteo.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5754;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=H6a2W0Q838mvGLsWs1R0GK9HOt4+L45t/evmt7nYJHc=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBqU85U2Yew5IVXo1E6CN1DmFV/ynLbj3mlINvCq
 vzeF94TfjiJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCalPOVBsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9JHNg//doLF2R7rK/qNJtR6JQ2jIBV973yvMmE
 G7a1mX1Vnzokm4QjQ+BvS+TI3e50VaZJcMGqBaymGhh/OpnVFBlJnvIpaNBdLS5EH+kj0nRtqQ+
 y1AiiSv3pOF34ib3Bi1LNEvk2gxJ3I+IZTxCFRhhQ9uyilhjlN/qnvDbSkn7lFOpUcWbArn9TGa
 N/Fljx13rn+aARFAFlxJTmMLK/q7QBG7x+wtGUm38fb0Gea7BfguM3/8x8+HI2dUB7LF1ppl8kd
 e2GR6F5rpN/tj3oOrrmRIC2r1Ge/a5wjC58KOrdt7Y+O3DBD4IhJOWpSmG0Hyla98ByV6MT2N8B
 XJhqWFD4W8IJZ6kCIKa5cuy0ZNYeK2ayYwle1PaPy5atbuZGBUF54OJgNsCr/wvL0n6W8JNUvPA
 H5hEwRDoDkFpYEgg3IAiPn/1EKef9FgZQA+QSJh4f3aqh+B6tPRGUSCcB/PpeSPGyChq8UpEybs
 ucNu/+EcQtZIFGIBKi1FYY05DMq3ctpmJKG9dPBSGzkBWpC1NFfjdhoVu7zszt2NK+QkWWhnR5Q
 ZR00dqffVMxixeszFftqR/a1fkGnC8ESscIVwgZ9HL9gCM/teYuaisxUZPcCQY8LOqWl42KglZX
 BCktK+UpDdXesgWNLv1BegUHPST264dQEWlGq785yGkzKafflqeM=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series has previously been contained in
https://lore.kernel.org/rust-for-linux/20251008181027.662616-1-markus.probst@posteo.de/T/#t
which added a rust written led driver for a microcontroller via i2c.

As the reading and writing to the i2c client via the register!
macro has not been implemented yet [1], the patch series will only
contain the additional abstractions required.

This series depends on [1].

[1] https://lore.kernel.org/rust-for-linux/20260525202921.124698-1-dakr@kernel.org/

The following changes were made:
* add basic led classdev abstractions to register and unregister leds

* add basic led classdev abstractions to register and unregister
  multicolor leds

Changes since v21:
* use 'init for lifetime that is only alive during initialization
* remove unnecessary CStrExt import

Changes since v20:
* resolve Sashiko regressions:
  * fix typo
  * fix fwnode refcount decremented too early

Changes since v19:
* rebase on v7.2-rc1:
  * Add `max_intensity` to `MultiColorSubLed`
* use safer `KBox::pin_slice` instead of `KVec`
  (len might not equal capacity)
* explicitly call `FwNode::dec_ref` instead of dropping a reconstructed
  `ARef<FwNode>`.
* remove direct access to `intensity` and `brightness` fields,
  which may get mutated concurrently by the C side
* fix safety comments pointing to functions from previous revisions

Changes since v18:
* add inlines
* fix invalid documentation
* improve led color duplicate checking

Changes since v17:
* use lifetimes instead of Devres

Changes since v16:
* use for loops for duplicate checking

Changes since v15:
* fix issues reported by Sashiko bot:
  * fix returning error not possible on `brightness_get` callback

Changes since v14:
* fix issues reported by Sashiko bot:
  * add missing inlines
  * add missing Sync trait bound
  * fix vertical import layout for public export of private types
  * fix potential memory leak, if a multicolor led device with over
    `u32::MAX` subleds is registered
* remove default_trigger option
* fix missing CAST doc

Changes since v13:
* rebased onto v7.1-rc1

Changes since v12:
* add `led::DeviceBuilder::name()` and `DeviceBuilderState'
* add `led::Color::as_c_str`

Changes since v11:
* use `led::DeviceBuilder` instead of `led::InitData`
* use static_assert instead of const { assert!(...) }
* restructured patches to avoid moving `led::Device` from
  rust/kernel/led.rs to rust/kernel/led/normal.rs in the 2. patch

Changes since v10:
* allow in-place initialization of `LedOps`
* run rustfmt for code inside `try_pin_init!`

Changes since v9:
* add missing periods in documentation
* duplicate `led::Device` and `led::Adapter` instead of using a complex
  trait
* fix imports not using prelude
* adapt to CStr change
* documented `led::Color::Multi` and `led::Color::Rgb`

Changes since v8:
* accept `Option<ARef<Fwnode>>` in `led::InitData::fwnode()`
* make functions in `MultiColorSubLed` const
* drop the "rust: Add trait to convert a device reference to a bus
  device reference" patch, as it has been picked into driver-core

Changes since v7:
* adjusted import style
* added classdev parameter to callback functions in `LedOps`
* implement `led::Color`
* extend `led::InitData` with
  - initial_brightness
  - default_trigger
  - default_color
* split generic and normal led classdev abstractions up (see patch 3/4)
* add multicolor led class device abstractions (see patch 4/4)
* added MAINTAINERS entry

Changes since v6:
* fixed typos
* improved documentation

Changes since v5:
* rename `IntoBusDevice` trait into `AsBusDevice`
* fix documentation about `LedOps::BLOCKING`
* removed dependency on i2c bindings
* added `AsBusDevice` implementation for `platform::Device`
* removed `device::Device` fallback implementation
* document that `AsBusDevice` must not be used by drivers and is
  intended for bus and class device abstractions only.

Changes since v4:
* add abstraction to convert a device reference to a bus device
  reference
* require the bus device as parent device and provide it in class device
  callbacks
* remove Pin<Vec<_>> abstraction (as not relevant for the led
  abstractions)
* fixed formatting in `led::Device::new`
* fixed `LedOps::BLOCKING` did the inverse effect

Changes since v3:
* fixed kunit tests failing because of example in documentation

Changes since v2:
* return `Devres` on `led::Device` creation
* replace KBox<T> with T in struct definition
* increment and decrement reference-count of fwnode
* make a device parent mandatory for led classdev creation
* rename `led::Handler` to `led::LedOps`
* add optional `brightness_get` function to `led::LedOps`
* use `#[vtable]` instead of `const BLINK: bool`
* use `Opaque::cast_from` instead of casting a pointer
* improve documentation
* improve support for older rust versions
* use `&Device<Bound>` for parent

Changes since v1:
* fixed typos noticed by Onur Özkan

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
Markus Probst (3):
      rust: leds: add basic led classdev abstractions
      rust: leds: add Mode trait
      rust: leds: add multicolor classdev abstractions

 MAINTAINERS                     |   8 +
 rust/bindings/bindings_helper.h |   1 +
 rust/kernel/led.rs              | 338 +++++++++++++++++++++++++++++
 rust/kernel/led/multicolor.rs   | 460 ++++++++++++++++++++++++++++++++++++++++
 rust/kernel/led/normal.rs       | 238 +++++++++++++++++++++
 rust/kernel/lib.rs              |   1 +
 6 files changed, 1046 insertions(+)
---
base-commit: 4c45e14df2f4e77982ad70d6d8e3fe750edd4c37
change-id: 20251114-rust_leds-a959f7c2f7f9

