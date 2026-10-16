From: Markus Probst <markus.probst@posteo.de>
Subject: [PATCH v27 0/4] rust: leds: Add led classdev abstractions
Date: Fri, 16 Oct 2026 20:08:01 +0200
Message-Id: <20261016-rust_leds-v27-0-2c296d8a8e5b@posteo.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XU227cIBAG4FdZ+bqOZgYGmFz1Paqq4thYauLE3
 qxaRXn34o2ihaLeWAL5G/Dwm7dpz9uS9+n+9DZt+bLsy/pUB2S/nKb44J9+5nlJdWIiIEZEPW+
 v+/nHr5z22QtLsZGKLTLV95+3XJbf12Lfvtfxw7Kf1+3PtfbFHbOfVbipcnEzzEm8xqKYWbmvz
 +t+zutdytNR5SKtlFZKlc5E5ORRwKh/JcInNYBgWopQbQaPbLRzushg8Wbro7NYLTtOGF3IBHG
 w1FrbWaq2pMDoNNpgebDqZhV1n4uqWkLPIpEDJRysvllN/bq6Wl10QJs5MZrBcmv7dblasVlsI
 JtDGPdsbpYBO2sOW+qXlJRTTGOfbWMVdNZWG8GIi1oZl2mwrrX9utdUgUWg4BktDFZutna6s0e
 uyFdbzzj7POSKmlyZvld05KpoUT7ULQVdBov/t3g9IygobCWNfaYmVxa7TNKRK2AOoFk82KHPp
 Frb/Qt05CoLFg4GXOAhG9TkSvpe0ZErlyTrCDoFM67b5Eqwt0eu0CMoi8m6OPa5yZX02aAjV04
 5ZZWqZwy5te8fl9GWX17rhXb+uJGm4Pc8x/XxcTnfny72ru4l2vry+1+USKDPBQUAAA==
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
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=6213;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=+Eil9Qvx4QyLTcqSTsshreQVBspccOrmKgKSUDaLxYk=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBq0mgEKjbP0eKyKEEwYSNIC7uTqdb3b/nvWRexz
 TwlOeMMdJqJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCatJoBBsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9J3Eg//bah4Mv18PgA/2BRMfQ2092KYlcQvIk8
 ZPTvdtsjHb5LK/Ew4bVbhNd5x++4nqVMloOtgg5ehKD706hZdKXGl1U8bw+mAg99gnoEPDei+8d
 cpsCvz8Y2WlzQ2ySMvmUclsGQdagxEvQNakOPjWido9LOuPtzZuH8/4UDvndhg1HirLd6dmOnp1
 hjIgdhUsauxczjm7dbUVp5Y/Fb0NWJF2jPLABq12s/ARa9CyEn1l1g1HWnENKjTbrCQOAkOiXJ3
 Dsm97eMBoLagBS4g36VEkIQt50nY2Ri0fnR7NpEI1BWk9dy/IjUQecChqvMY7azK1wfw5g//z3p
 IZIW/wUYfeKO7i9gxBCB7z4GroQCiSjkPFv/2QhHy2d8gQZfTfAtapolH9LQZH1dcA6arfPnm01
 5EN+v/zOTVn9S28mMoqT80f6MboPskHBqzJzJJ1opfhATdg87Wu5T2qWAXCo377ZryAolN/fxxw
 GOcVxAjiGhYdUEPWchGEH9G5xIKcAFXUQwaD2iENsglYghWbh68XoXg18bTlwUnSHN2DWSUF/xM
 Y86rZSfgSHxK8JVQrtkq/4EO0lWihFqUsK1UwT9LfitntLSVpkokre86LJsadhr9k7aKvtbu6J0
 Njy5dLdlkJQq4cid0uUVjAnq2HEGXrLvI6DWnhM+m82OlNydWgAU=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The abstraction is used by
https://lore.kernel.org/rust-for-linux/20260724-synology_microp_initial-v18-0-fb2f49f10e77@posteo.de/
.

The following changes were made:
* add basic led classdev abstractions to register and unregister leds

* add basic led classdev abstractions to register and unregister
  multicolor leds

Changes since v26:
* use Atomic (Boqun)

Changes since v25:
* fix issues reported by Sashiko:
  * fix vertical import
* add drivers/leds/*.rs to MAINTAINERS file (Kari)
* s/add/Add/ in commit message

Changes since v24:
* remove `LedOps::Bus` (Gary)
* support type-erased `Device` and `MultiColorDevice` types (Gary)
* use `Device` and `MultiColorDevice` as arbitrary self types in
  callbacks. Remove separate `classdev` argument (Gary)
* remove unnecessary imports in doc example

Changes since v23:
* add separate patch for MAINTAINERS file update

Changes since v22:
* readded CStrExt import, because it is imported with `as _` in prelude.
  A `# CONFIG_RUST is not set` sneaked into my .config while
  development, so the compile error was unnoticed.

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
Markus Probst (4):
      rust: leds: Add basic led classdev abstractions
      rust: leds: Add Mode trait
      rust: leds: Add multicolor classdev abstractions
      MAINTAINERS: rust: leds: Add rust abstraction entry

 MAINTAINERS                     |   9 +
 rust/bindings/bindings_helper.h |   1 +
 rust/kernel/led.rs              | 317 ++++++++++++++++++++++++++++
 rust/kernel/led/multicolor.rs   | 442 ++++++++++++++++++++++++++++++++++++++++
 rust/kernel/led/normal.rs       | 230 +++++++++++++++++++++
 rust/kernel/lib.rs              |   1 +
 6 files changed, 1000 insertions(+)
---
base-commit: ec8bf8280261294a9b9b4520414b42704c7f9f6b
change-id: 20251114-rust_leds-a959f7c2f7f9

