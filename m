From: Markus Probst <markus.probst@posteo.de>
Date: Sat, 30 May 2026 03:13:50 +0200
Subject: [PATCH v8 2/5] serdev: add rust private data to serdev_device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260530-rust_serdev-v8-2-2a95f1da22a7@posteo.de>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1683;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=Lci9sJZ/Hd89WrWg8pDQ/wKU3djKPRT47wh61HUUHxo=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBqGjnPHOTEhfqnhbwmmGCBFLn1wOiKsWKQOa3Sj
 kHB2JgOI4WJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCaho5zxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9LvBw/8DEH1sCnx1FyuswKn4avKv4ZzqA70FFn
 n9D2QN0m7Fm+3amdoXrUwEGTD+TARN3zMV+52cl1/OXK5qOHuxhPaZKvR7TmriwGkhNyYzkAcZ5
 Rbds3vnyFKF0mT78MgmeL8HKkSYawt/s+u+HOu4IiaVmO38uv1nrzZuSH3TkHdALy8cdiXMczdj
 TmWYE4s2pG30yijY+GF08s68ncu3+uWIsaBJyV2MgHKuYKhEtvtSWpgILfgUe35GtCKQw/zrc7a
 qHdzbgpn2/vgahiufKVawAP6GavvtVT/kN5LxFjEAJ7Yxui5vlmuMM7JxqZUcyvToQpHHER4u8h
 7g++96xJrtGBggPkwjAXTyuVxscke2sLpjOBwWYxvqMOUrdxMBT/DARM6rakngR3xrvbNP4UV3U
 CHQp2q3RrOaJs1ObUBGT6G/TJPO9TNy98sCgCjP/qQcXnH/73vg8OzfMEALQYI+HClQys0IztLO
 mZVmF2YQfMCX0GtklLIikareIim2XCs4v/RePtI/MOBQgAc3+DIN9nCFnuv9DneBCQTmPStZyC0
 qo7mxgLjvmLhMwYtMsBsgzxzlaK7s8kavOkWnD+/EdB3qo/YPjT5TIQX5U97SH1CZSl7vcq23ra
 Yl4bf2qGOUs4zILBtrQzKgq6pv2x807b8NVTqCraNNSiKc3ToMJs=
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

