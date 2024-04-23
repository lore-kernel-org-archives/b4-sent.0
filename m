From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 23 Apr 2024 17:20:32 +0200
Subject: [PATCH v2 3/4] iio: backend: make use of dev_err_cast_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240423-dev-add_dev_errp_probe-v2-3-12f43c5d8b0d@analog.com>
References: <20240423-dev-add_dev_errp_probe-v2-0-12f43c5d8b0d@analog.com>
In-Reply-To: <20240423-dev-add_dev_errp_probe-v2-0-12f43c5d8b0d@analog.com>
To: Petr Mladek <pmladek@suse.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Chris Down <chris@chrisdown.name>, John Ogness <john.ogness@linutronix.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Andi Shyti <andi.shyti@kernel.org>, Jyoti Bhayana <jbhayana@google.com>
Cc: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713885641; l=960;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=O5sBK3dByRpiEz66h+ITvQMqPVPMlwbEa+A9Df4FqVo=;
 b=nei54/x6Mkn2Mx6Ct0Ltt/13H9JOLlF+w9Cmz3PJ7G5HAH92QrzgZNUmxoV52ZTd+mEIhRNDC
 IDXKUJpboqtCwYu3EzhkpajOLYz7lcxIbO1y+uix05hyT/x0KzVn13h
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Using dev_err_cast_probe() to simplify the code.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/industrialio-backend.c | 8 +++-----
 1 file changed, 3 insertions(+), 5 deletions(-)

diff --git a/drivers/iio/industrialio-backend.c b/drivers/iio/industrialio-backend.c
index f08ed6d70ae5..2cc6459246ce 100644
--- a/drivers/iio/industrialio-backend.c
+++ b/drivers/iio/industrialio-backend.c
@@ -475,11 +475,9 @@ struct iio_backend *devm_iio_backend_get(struct device *dev, const char *name)
 	}
 
 	fwnode = fwnode_find_reference(dev_fwnode(dev), "io-backends", index);
-	if (IS_ERR(fwnode)) {
-		dev_err_probe(dev, PTR_ERR(fwnode),
-			      "Cannot get Firmware reference\n");
-		return ERR_CAST(fwnode);
-	}
+	if (IS_ERR(fwnode))
+		return dev_err_cast_probe(dev, fwnode,
+					  "Cannot get Firmware reference\n");
 
 	guard(mutex)(&iio_back_lock);
 	list_for_each_entry(back, &iio_back_list, entry) {

-- 
2.44.0

