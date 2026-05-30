From: Markus Probst <markus.probst@posteo.de>
Date: Sat, 30 May 2026 03:13:53 +0200
Subject: [PATCH v8 5/5] MAINTAINERS: serdev: Add self for serdev
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260530-rust_serdev-v8-5-2a95f1da22a7@posteo.de>
References: <20260530-rust_serdev-v8-0-2a95f1da22a7@posteo.de>
In-Reply-To: <20260530-rust_serdev-v8-0-2a95f1da22a7@posteo.de>
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
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBqGjnPhljelHIuzdbOLC3zhJwHUwihLpJ+X/2k8
 18CITrGo5+JAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCaho5zxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9JNdQ/+IR2iPGEy8sqtRVurCujsY1VhZ/t7tm+
 6bWZdXnedNebKNUT6bpdRAAxnB0/Kf7Iu/bWpGDcSZ/esml58O+dBLKANgmpDEn3Hb/kFG/8LmB
 cmAGhf2LSuYuN3IpSJax6GiRzWxb5NaDMhUHM81xmnNSWYnBnQ26L+kUw8x0A4rIkfF5SSu5FAG
 xfnu+x6oVlgHGj4SBPi9IrW5awYtoRMgLuGd97RaA9PSYUS54Zmih3fKnbnoqwUAolRi2iOM7SP
 6lNBjb7sEhpDMsG7SiwfYC4RKp4bjI77UtZA7cFsNDNoV2FJvZAQePzkthoFFbd1i+kFgDiHdg4
 G24/p9FN9pUJ2PbuwfSXpJIZmkPi3W8Hw0hqgh6J64Jd0AtU9gU6x6FX+DBPgdjrax3/YV8PW7F
 UNrktM48Or5Vao7WkN39D2fD7+38l5CS/eWj5kJzeQQP/hn3E/TKPv+7FSSpFUX+8UMjJSpByik
 xqok0SyWTgVdW0JlXHGxsG5d10++pOpV+qXV+qbGjpeFs2aZ9KLLM0BhN1AZv5uMYA6qTU4BCad
 3qCvEJMtgW1uR+gpWCO/uxlJdVexI7D79yFEu6Rj5eLADedrgkRuna6hkubYrkC7fYkqK3+kpZl
 I4h7OJ7fIeJGnn/h65/wr4XgfwNeMWAikFFjuM89/Lbmb0aBvlo0=
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

