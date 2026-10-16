From: Markus Probst <markus.probst@posteo.de>
Date: Fri, 16 Oct 2026 20:08:05 +0200
Subject: [PATCH v27 4/4] MAINTAINERS: rust: leds: Add rust abstraction
 entry
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-rust_leds-v27-4-2c296d8a8e5b@posteo.de>
References: <20261016-rust_leds-v27-0-2c296d8a8e5b@posteo.de>
In-Reply-To: <20261016-rust_leds-v27-0-2c296d8a8e5b@posteo.de>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=693;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=EpcesJjKwltPtTZ2UkOnZtNgz9x6Hd9kGf/UOr4TELI=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBq0mgFR727Lu8WhqMbhYv/5f8/8lNzjnIt5J+K0
 OLlm1Rjg/iJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCatJoBRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9L+0w/7B/fGeJhW8JnpFBXcTbiNdLobMzP5oEu
 1Z48MyvnqOEyoVDY1UEOEzOMVlgjQbjdqlU9h0Lqnp3kTiuFqRD7VxA9EDIdWtbtFxjL/TPxCga
 +DslbK7JlakdWCdSsOpEqbJ3B4HcUTyxlfQ21HAVOl/3ixDsnOtSHwSptUX995xMQc+Tj+Dl+6f
 Zr570hm1/jERB1vWltaJN/xQ+c47yhY/AR/QjCEg5EEHsI6jkis6nMESY7J3T3MfUvkVz1dbYKP
 qS4/TL1fgqTe/Pt3LxKWwV9rtGn7YyZJB9z9dzm+Zmo6Yx9BTreH4hfpRsHZoT6QmWP7sTnYBcd
 KZRrtuS9j6eRmRkxTTj6ioXte66QFbcBubf1SRvBYYNgfabuIHf6MM+AcQwtCF4OrVE1ZAR075l
 c1/R7/qL7gLuHFA9lHG/3BJVbFwPzbkONfn3tsdH4ib1ST41AygS/G+uxBU6R6TUAVHEh19Ggud
 14nritk+Z8DqqIv5OsyOWwVJlIatHatuV8sljD5HyUi9sG+w37dnh48la+M9Cxb45KsTwXjr/lT
 6RybeEaLIporSn1UXrxI0HBZdJXDFWyWuINhAfxYZqyQyESNnW1d4ax8bjTbyF8ZHB0BOyILs85
 gGWVHDyQSq2skJa0TpFBCXYGJu9yI9L+oNWRNt93Xt/nKyHwBeZI=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add self as maintainer.

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
 MAINTAINERS | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index f53047aa8d3c..3ae821614cd8 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -14791,6 +14791,15 @@ F:	drivers/leds/
 F:	include/dt-bindings/leds/
 F:	include/linux/leds.h
 
+LED SUBSYSTEM [RUST]
+M:	Markus Probst <markus.probst@posteo.de>
+L:	linux-leds@vger.kernel.org
+L:	rust-for-linux@vger.kernel.org
+S:	Maintained
+F:	drivers/leds/*.rs
+F:	rust/kernel/led.rs
+F:	rust/kernel/led/
+
 LEGO MINDSTORMS EV3
 R:	David Lechner <david@lechnology.com>
 S:	Maintained

-- 
2.55.0

