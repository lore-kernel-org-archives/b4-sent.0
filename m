From: Markus Probst <markus.probst@posteo.de>
Date: Sat, 11 Apr 2026 17:10:36 +0200
Subject: [PATCH v4 2/4] serdev: add rust private data to serdev_device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260411-rust_serdev-v4-2-845e960c6627@posteo.de>
References: <20260411-rust_serdev-v4-0-845e960c6627@posteo.de>
In-Reply-To: <20260411-rust_serdev-v4-0-845e960c6627@posteo.de>
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
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1717;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=ECl35l4KVjDGQ1987vPeXlJAH328JZDbp6x8p1+V+Tw=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBp2mR1/rC3QYG4lv8x7+e0BHsEaO6Kzftuyrn4x
 i7TZYRqvjOJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCadpkdRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9KcAg/9EvXGx8GdJdStcMtxvrNEM5CZHOVl3Lc
 NstwET4wP7IwuaA+tFIH3/sr9iA4nbjloefAA7PWihsomU9kmYOK5mz+WvIZugAjYt/85U/A7oy
 JqaVjNd/atsJTbMEK5yGQazTzSkBf4y3khdcSodR/HbLOa4T9rcDHez4xwViN6fNuStr+lxiCAK
 By/90NqzIuioqG9IcAjDdT5K9FQh+gm29QJErC3yJCvOiP0s2c5dnrRkz5iXfjQX11BiRz+I+q8
 PHWUHOTRMRYxnaPRYp4+KRKu6u39l/OBO7KyvtMOkXIV626+6Zck4rgJ6SVNwNOUYIIgatgPJ0F
 QMFElDMw8YKkV4Z7u7yTJoLyQsC2CtDW+8EjjzoAWUT9kV6CVaYIhXLOEDHxp3+da8depLa3YHL
 7koqy2eZforhueezp0fjEijmTft53BVzAdupQ+loZGyfM1sNwnuEuu0ce9ljpZPmT+AzkxlCQRn
 RFg15B3sOTaN14kTbOJyqFoAkKlGyloJ/2l4te7VeicuzLVoOw3bpXanGN3LL3eXBF3IVn10fpK
 7ZSQFGDv/L+JZSN8CrzUGCIbOjh7KdQSXG/tPLE47NjUhfkVskOScyvZIUvUm9g+B5XZwMS2U45
 eZBXC6NOVornad+0dwaHvgAph5a4E7xspX4Ez/jbomhXPDfmw3tU=
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
index 5654c58eb73c..c74c345d60ae 100644
--- a/include/linux/serdev.h
+++ b/include/linux/serdev.h
@@ -33,12 +33,14 @@ struct serdev_device_ops {
 
 /**
  * struct serdev_device - Basic representation of an serdev device
- * @dev:	Driver model representation of the device.
- * @nr:		Device number on serdev bus.
- * @ctrl:	serdev controller managing this device.
- * @ops:	Device operations.
- * @write_comp	Completion used by serdev_device_write() internally
- * @write_lock	Lock to serialize access when writing data
+ * @dev:	       Driver model representation of the device.
+ * @nr:		       Device number on serdev bus.
+ * @ctrl:	       serdev controller managing this device.
+ * @ops:	       Device operations.
+ * @write_comp:	       Completion used by serdev_device_write() internally
+ * @write_lock:	       Lock to serialize access when writing data
+ * @rust_private_data: Private data for the rust abstraction. This should
+ *		       not be used by the C drivers.
  */
 struct serdev_device {
 	struct device dev;
@@ -47,6 +49,7 @@ struct serdev_device {
 	const struct serdev_device_ops *ops;
 	struct completion write_comp;
 	struct mutex write_lock;
+	void *rust_private_data;
 };
 
 static inline struct serdev_device *to_serdev_device(struct device *d)

-- 
2.52.0

