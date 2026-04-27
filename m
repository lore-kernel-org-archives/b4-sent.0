From: Markus Probst <markus.probst@posteo.de>
Date: Mon, 27 Apr 2026 20:05:42 +0200
Subject: [PATCH v6 2/4] serdev: add rust private data to serdev_device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260427-rust_serdev-v6-2-173798d5e1a3@posteo.de>
References: <20260427-rust_serdev-v6-0-173798d5e1a3@posteo.de>
In-Reply-To: <20260427-rust_serdev-v6-0-173798d5e1a3@posteo.de>
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
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBp76V9RbMszIgYWJvSWd0DQQvpRFArS72LDlcV3
 7DTy3b7pj+JAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCae+lfRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9JuqA/+KWXf7SvsT8sOhGfeNvEPjyBdh3Zb7Su
 QYx71x8wz5G4X2BfWc1y3I4E6K+R9FeOjMzKGGZxSsgbKk95TumVive0o4+rG4hyNk7WD1RbeAp
 cQ+uOCUbhWlwSR+Iwnd+5AEADEBWxzOWn+QzvHa6RxMKhhMUwNd5QNumBtMy6JSyjrrpeG4v3v/
 7BWxPOHhooqtdbhhxSgSl+dub5IQCubhPEySPAhwQ3BdeD1iEXW2leQHDErHk/L6GoNn2fyf4aj
 4tUqsX0qKBTnj8NbBHJ+txkl0BxRdEAWnoHqc8Bfx2F8JW7tjw/hahr10t+efWWTwg84ePqumlz
 RiBXatCl8m4Ju2QZGKhKl4VKOoi6KDrGxI6IoadKSDoWyWYBveZmqcN/TCe2MfgX/lx3K1nAv+2
 0VbxqgLssAVYp+B1cbXp8XdwMvYyBSrPkdiVHRrqwT1/j5dKjY2RFrpYCGZ6gnpPD04n/OejVTv
 QRPyF4vx5fznUKHxFofDtbjrB6AevRJ7CwgS1rKq6O+ZaNiTk7l+CGg22EYwaqwXgIs2JJdov11
 Jb+t1kQs1cmmcLu6qI8l6WUmcx2ai+z1+6I+UqhNiIespcshLjw1fBW3FzVAESd0zFt7ek5a/+S
 DKUZ1Qp6Fm5MT1NeJ8dQn7y2P2mHr2eh8IZJl2zZ0KmusC9UngJk=
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

