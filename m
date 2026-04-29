From: Markus Probst <markus.probst@posteo.de>
Date: Wed, 29 Apr 2026 20:21:32 +0200
Subject: [PATCH v7 2/4] serdev: add rust private data to serdev_device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260429-rust_serdev-v7-2-0d89c791b5c8@posteo.de>
References: <20260429-rust_serdev-v7-0-0d89c791b5c8@posteo.de>
In-Reply-To: <20260429-rust_serdev-v7-0-0d89c791b5c8@posteo.de>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1683;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=Lci9sJZ/Hd89WrWg8pDQ/wKU3djKPRT47wh61HUUHxo=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBp8kxH3Vrn90sS/n5Qu4cj02orPT5HfO7Dy3xpo
 9gsC6MwL0+JAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCafJMRxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9IANg/9FrfFJ8eqmUTfCfj3Qv8jpO0a+RhHW9u
 n1W5SbXV2KFb+0ZuFLOzrhJzqmv6dJ4iwiGiraJmTgTd/ro1WZKT39S6YySn1VFQpftWA4TyiMJ
 iMFBYYLThyUWvDOPIRwRzHg6IruXcNxjnfTIwYDedhPV/54i//bCbzYuwsSv0cuGOq6BVNbfM8G
 Ewy1pCFMeCfv+c32mSkyfNoqeqaSSlklGxxzRhqas6IwGcORl4/yDlxQuZbtz0W78lP5moewBAZ
 nyL5PQ/E6TztdbOVbCMDJQ+VeV4IA1svT83oPRtVEN0GVhF1750RI1vvR+TdmaOh3OlyMO7FEi2
 6lcCdxwuEQuLFBDAmRkyuvKbF+W9lvakQoGDMfnGGzf7xW0qtAOvCHxUO3CoYeHWRq6HC6cySAv
 a/P9plJJNdNdDqdHne8Upo90rxCwotiJM0I51H8MrcyEasud/trEUx/+qa8SnDHAKeRRVRTYw71
 667BlVLuqXetYwgGQwksFj+OUUNRfvflmg9luC8NH5ZJJood1j2VYRCKa/y4yuBMSBDaP4V7S5Q
 PB/JvUjzdEuRW0v7Y0tyXe4aK+zdeyDcQx9t+kkmdLmH7tJ8TJXjjmaozLFf47R83D79FwjKAbS
 A0nPGSjtSSY/d7t1fpanUBl3SfO0Z5dF6GLTVdZa96Ky2LH5Ajvk=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add rust private data to `struct serdev_device`, as it is required by the
rust abstraction added in the following commit
(rust: add basic serial device bus abstractions).

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
 include/linux/serdev.h | 15 +++++++++------
 1 file changed, 9 insertions(+), 6 deletions(-)

diff --git a/include/linux/serdev.h b/include/linux/serdev.h
index b6c3d957ec15..048ef5857786 100644
--- a/include/linux/serdev.h
+++ b/include/linux/serdev.h
@@ -33,12 +33,14 @@ struct serdev_device_ops {
 
 /**
  * struct serdev_device - Basic representation of an serdev device
- * @dev:	Driver model representation of the device.
- * @nr:		Device number on serdev bus.
- * @ctrl:	serdev controller managing this device.
- * @ops:	Device operations.
- * @write_comp:	Completion used by serdev_device_write() internally
- * @write_lock:	Lock to serialize access when writing data
+ * @dev:		Driver model representation of the device.
+ * @nr:			Device number on serdev bus.
+ * @ctrl:		serdev controller managing this device.
+ * @ops:		Device operations.
+ * @write_comp:		Completion used by serdev_device_write() internally
+ * @write_lock:		Lock to serialize access when writing data
+ * @rust_private_data:	Private data for the rust abstraction. This should
+ *			not be used by the C drivers.
  */
 struct serdev_device {
 	struct device dev;
@@ -47,6 +49,7 @@ struct serdev_device {
 	const struct serdev_device_ops *ops;
 	struct completion write_comp;
 	struct mutex write_lock;
+	void *rust_private_data;
 };
 
 #define to_serdev_device(d) container_of_const(d, struct serdev_device, dev)

-- 
2.53.0

