From: Fabio Forni <development@redaril.me>
Date: Thu, 08 Oct 2026 22:06:53 +0200
Subject: [PATCH v4 1/3] mux: Avoid use-after-free of args.np in mux_get()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261008-mux_fwnode-v4-1-ba3330e44b2a@redaril.me>
References: <20261008-mux_fwnode-v4-0-ba3330e44b2a@redaril.me>
In-Reply-To: <20261008-mux_fwnode-v4-0-ba3330e44b2a@redaril.me>
To: Peter Rosin <peda@lysator.liu.se>, Linus Walleij <linusw@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jonathan Cameron <jic23@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 xu.yang_2@nxp.com, 
 =?utf-8?q?Alvin_=C5=A0ipraga?= <alvin.sipraga@analog.com>, 
 Fabio Forni <development@redaril.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2845;
 i=development@redaril.me; h=from:subject:message-id;
 bh=fIPItUiYGeYkaxLTf5X0TCO2yANOT29/guKj77fHMww=;
 b=owGbwMvMwCXWeKho1tqFWemMp9WSGLKOf7+TWP5VJPuR6tcGv+yuX7vtubvNr8xibMlmT73+u
 6/iK8/pjlIWBjEuBlkxRZb/Tkabus1MjG71S9TCzGFlAhnCwMUpABNR/svIMOew7fJjs/QcX5zL
 W/9t5h9zQ7HqTas4tI9zNjrMe37qmgPDP5NFj3boS79tqe5zjnyW+3pT7pt/Bw4/+/nhhZ7hXVX
 lZ6wA
X-Developer-Key: i=development@redaril.me; a=openpgp;
 fpr=FF4232B28B363432DA8F187D81C2729AADA16A67
X-Endpoint-Received: by B4 Relay for development@redaril.me/default with auth_id=1033
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

of_node_put(args.np) was called right after
of_find_mux_chip_by_node(), but it was too early because the error
handling code below would pass args.np to dev_err().
Let's move all freeing functions to the bottom of mux_get() to avoid
use-after-free bugs.

Signed-off-by: Fabio Forni <development@redaril.me>
Suggested-by: Alvin Šipraga <alvin.sipraga@analog.com>
Fixes: a3b02a9c6591 ("mux: minimal mux subsystem")
---
 drivers/mux/core.c | 30 +++++++++++++++++++++---------
 1 file changed, 21 insertions(+), 9 deletions(-)

diff --git a/drivers/mux/core.c b/drivers/mux/core.c
index 5083e3d19606..6ca40d73ea0e 100644
--- a/drivers/mux/core.c
+++ b/drivers/mux/core.c
@@ -535,6 +535,9 @@ static struct mux_chip *of_find_mux_chip_by_node(struct device_node *np)
  * @optional: Whether to return NULL and silence errors when mux doesn't exist.
  * @node: the device nodes, use dev->of_node if it is NULL.
  *
+ * When a mux-control is found, it is the caller's responsibility to call
+ * mux_control_put() on it when it is no longer needed.
+ *
  * Return: Pointer to the mux-control on success, an ERR_PTR with a negative
  * errno on error, or NULL if optional is true and mux doesn't exist.
  */
@@ -584,9 +587,10 @@ static struct mux_control *mux_get(struct device *dev, const char *mux_name,
 	}
 
 	mux_chip = of_find_mux_chip_by_node(args.np);
-	of_node_put(args.np);
-	if (!mux_chip)
-		return ERR_PTR(-EPROBE_DEFER);
+	if (!mux_chip) {
+		ret = -EPROBE_DEFER;
+		goto end;
+	}
 
 	controller = 0;
 	if (state) {
@@ -594,8 +598,8 @@ static struct mux_control *mux_get(struct device *dev, const char *mux_name,
 		    (args.args_count < 2 && mux_chip->controllers > 1)) {
 			dev_err(dev, "%pOF: wrong #mux-state-cells for %pOF\n",
 				np, args.np);
-			put_device(&mux_chip->dev);
-			return ERR_PTR(-EINVAL);
+			ret = -EINVAL;
+			goto end;
 		}
 
 		if (args.args_count == 2) {
@@ -610,8 +614,8 @@ static struct mux_control *mux_get(struct device *dev, const char *mux_name,
 		    (!args.args_count && mux_chip->controllers > 1)) {
 			dev_err(dev, "%pOF: wrong #mux-control-cells for %pOF\n",
 				np, args.np);
-			put_device(&mux_chip->dev);
-			return ERR_PTR(-EINVAL);
+			ret = -EINVAL;
+			goto end;
 		}
 
 		if (args.args_count)
@@ -621,8 +625,16 @@ static struct mux_control *mux_get(struct device *dev, const char *mux_name,
 	if (controller >= mux_chip->controllers) {
 		dev_err(dev, "%pOF: bad mux controller %u specified in %pOF\n",
 			np, controller, args.np);
-		put_device(&mux_chip->dev);
-		return ERR_PTR(-EINVAL);
+		ret = -EINVAL;
+		goto end;
+	}
+
+end:
+	of_node_put(args.np);
+	if (ret < 0) {
+		if (mux_chip)
+			put_device(&mux_chip->dev);
+		return ERR_PTR(ret);
 	}
 
 	return &mux_chip->mux[controller];

-- 
2.56.0

