From: Markus Probst <markus.probst@posteo.de>
Date: Sun, 31 May 2026 00:51:04 +0200
Subject: [PATCH v11 3/3] MAINTAINERS: serdev: Add self for serdev
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260531-rust_serdev-v11-3-dee8e0d830f1@posteo.de>
References: <20260531-rust_serdev-v11-0-dee8e0d830f1@posteo.de>
In-Reply-To: <20260531-rust_serdev-v11-0-dee8e0d830f1@posteo.de>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=838;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=P+qqzzRwhI8B2ZhOfr+PVqRWtfVtS9KesBahL8YX4uk=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBqG2nbZIg0nXhOycM/1qybSufuCsXWEmdoGQwRe
 cG7GjM6MOWJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCahtp2xsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9Jy6hAAiPX7RzBxIe3kQ7rF3al/RzJ7ngkNM28
 6zXck0BQMCPs8ApVlkbY/dqKBKelAdDIS5r96upET5eyQy9r8vuQQ3IfProVEJIkbrAoBB/mX+N
 DPL24f5PEBGFj1zu99egO+BKwOGaqv++BJKBpLci0U/nIaOe+zLBX//YodFKB5IeZ4kNekSMWed
 lGlOvGis5lpy10jZt0RdGxijScEt2HrEZiYzXvygwCni3gQBaMdebiUoIHhSLVfBPoiEKDkdRJw
 Usm9GSTDkg4uf5NJ8SWHc5bvGshbLcvwBe17UqXV4MC08uxgwHFPw0WkgpkOF68DSEFk8H40N63
 k7KOt7CrvCIAspifnCzyWz8bTp5ekTdrZxlcxoebQnnw+S2ne5jLTfT7IuxRVyrO3kGL5ToNla0
 qY2BoivjUoj1UG3ajU+klgwpGqn5kKutwgC1xufuX3FZMO7NYPbL0hBwCRkHXld6At/mK+7L1fj
 X8iWAriY+JwXr1+4wntj2CEbppcmCJ0oHoVLGtEDYbXEdo/3qCAOXoiGwoHwCMLsQGIkRBCzFjh
 kaHVX/gawwiTBqYN7Tr5cLGk4CZpvViq4sfHnnsle4kPSxKFLmQeJzT0gRozrOzbJ+9NFf6XtrM
 87s9s70UVl5vWUhK/gDW7iT2o8qK59s4SKm2Ek11qomPYj5Xgr60=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Rob mentioned he needs to find someone else to maintain serdev.

Link: https://lore.kernel.org/rust-for-linux/20260430195858.GA1650658-robh@kernel.org/
Link: https://lore.kernel.org/rust-for-linux/da85ceb81f51079d4a8248a1ffde6a27d2ef24ad.camel@posteo.de/
Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
 MAINTAINERS | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index fa3f20f0cc4f..58db6aedf45a 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -24270,7 +24270,7 @@ F:	drivers/iio/chemical/sps30_i2c.c
 F:	drivers/iio/chemical/sps30_serial.c
 
 SERIAL DEVICE BUS
-M:	Rob Herring <robh@kernel.org>
+M:	Markus Probst <markus.probst@posteo.de>
 L:	linux-serial@vger.kernel.org
 S:	Maintained
 F:	Documentation/devicetree/bindings/serial/serial.yaml

-- 
2.53.0

