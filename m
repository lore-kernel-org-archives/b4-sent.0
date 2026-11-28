From: Fabio Forni <development@redaril.me>
Date: Sat, 28 Nov 2026 11:43:12 +0100
Subject: [PATCH v5 3/3] mux: Document mux_chip_find_by_fwnode()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-mux_fwnode-v5-3-6689b52f3800@redaril.me>
References: <20261128-mux_fwnode-v5-0-6689b52f3800@redaril.me>
In-Reply-To: <20261128-mux_fwnode-v5-0-6689b52f3800@redaril.me>
To: Peter Rosin <peda@lysator.liu.se>, Linus Walleij <linusw@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jonathan Cameron <jic23@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 xu.yang_2@nxp.com, 
 =?utf-8?q?Alvin_=C5=A0ipraga?= <alvin.sipraga@analog.com>, 
 Fabio Forni <development@redaril.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1190;
 i=development@redaril.me; h=from:subject:message-id;
 bh=WsfKOTl/y0DS2QwMlaBJvQeQ9+YnIj+MD9uZdj7LBrA=;
 b=owGbwMvMwCXWeKho1tqFWemMp9WSGLK5NjjW/dzuccDozMd+8evcHl4aLhuk1x62OsT2qWtZ3
 +W4Y14CHaUsDGJcDLJiiiz/nYw2dZuZGN3ql6iFmcPKBDKEgYtTACZS+JKR4ca2/9Jik2p26fpm
 fXG8yzX9YXZVcKqKeeKLvglXr5p+ymJk6C488S57tXHfXwauthleVUe/d0rIL5XZ0OSau++LxkZ
 DLgA=
X-Developer-Key: i=development@redaril.me; a=openpgp;
 fpr=FF4232B28B363432DA8F187D81C2729AADA16A67
X-Endpoint-Received: by B4 Relay for development@redaril.me/default with auth_id=1033
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

What mux_chip_find_by_fwnode() does it pretty obvious. What's
not-so-obvious is that the reference count of mux_chip->dev must be
decreased when done working with it. This commit clarifies the
requirement.

Signed-off-by: Fabio Forni <development@redaril.me>
---
 drivers/mux/core.c | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/drivers/mux/core.c b/drivers/mux/core.c
index d5095905b02e..6289cc98f49e 100644
--- a/drivers/mux/core.c
+++ b/drivers/mux/core.c
@@ -517,7 +517,16 @@ int mux_state_deselect(struct mux_state *mstate)
 }
 EXPORT_SYMBOL_GPL(mux_state_deselect);
 
-/* Note this function returns a reference to the mux_chip dev. */
+/**
+ * mux_chip_find_by_fwnode() - Find a mux-chip by its fwnode.
+ * @fwnode: The fwnode representing the mux-chip.
+ *
+ * When a mux-chip is found, the mux-chip increases the reference count of
+ * the underlying &struct device. The caller is responsible for calling
+ * put_device() on it.
+ *
+ * Return: Pointer to the mux-chip, or NULL if not found.
+ */
 static struct mux_chip *mux_chip_find_by_fwnode(struct fwnode_handle *fwnode)
 {
 	struct device *dev;

-- 
2.56.1

