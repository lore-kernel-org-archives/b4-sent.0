From: Fabio Forni <development@redaril.me>
Date: Tue, 29 Sep 2026 22:51:47 +0200
Subject: [PATCH v3 2/3] mux: Document mux_chip_find_by_fwnode()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260929-mux_fwnode-v3-2-9b3b9ae1334e@redaril.me>
References: <20260929-mux_fwnode-v3-0-9b3b9ae1334e@redaril.me>
In-Reply-To: <20260929-mux_fwnode-v3-0-9b3b9ae1334e@redaril.me>
To: Peter Rosin <peda@lysator.liu.se>, Linus Walleij <linusw@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 xu.yang_2@nxp.com, 
 =?utf-8?q?Alvin_=C5=A0ipraga?= <alvin.sipraga@analog.com>, 
 Fabio Forni <development@redaril.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1190;
 i=development@redaril.me; h=from:subject:message-id;
 bh=y3Gesa2naAHXthme8UJGKW3y5p3aniZmhazSrn2+quI=;
 b=owGbwMvMwCXWeKho1tqFWemMp9WSGLL2qLzpnLi+lO1bi+DzuZbFfya2HN9S8OHSiZPcPzqmV
 GytW7PCsKOUhUGMi0FWTJHlv5PRpm4zE6Nb/RK1MHNYmUCGMHBxCsBEnMsYGa5dct2ssCJ1Spha
 2b4NbGEyrDfCl553rsu+79ReqnjJ+xwjw7a4O7l3l3ZsnfNLgrf/xy5NkxcyjS03FvoUcf+6EG2
 UzQoA
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
index 56096a9139bd..d5121772c483 100644
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
2.55.0

