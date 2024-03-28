From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 28 Mar 2024 17:22:05 +0100
Subject: [PATCH v4 5/6] iio: backend: make use dev_errp_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240328-ltc2983-misc-improv-v4-5-0cc428c07cd5@analog.com>
References: <20240328-ltc2983-misc-improv-v4-0-0cc428c07cd5@analog.com>
In-Reply-To: <20240328-ltc2983-misc-improv-v4-0-0cc428c07cd5@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Jyoti Bhayana <jbhayana@google.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711642925; l=964;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=UI9LYwYsbzsvYImq/LHr54gyhLBEwgpl2jvt1KqrE14=;
 b=l04hnyfmitT+Wc9CJrsYi+vxjlfokLbKdPEhFV9RWHo3uTK/Oc+B5oE8Zqin/iltsRFq3jV4X
 Z/YjBSEYriIDM+VyTSF3MM88ds1JoMh0zkeVGDvS+BqmmGPR5T9C6YM
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Using dev_errp_probe() to simplify the code.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/industrialio-backend.c | 8 +++-----
 1 file changed, 3 insertions(+), 5 deletions(-)

diff --git a/drivers/iio/industrialio-backend.c b/drivers/iio/industrialio-backend.c
index 2fea2bbbe47f..e0b08283d667 100644
--- a/drivers/iio/industrialio-backend.c
+++ b/drivers/iio/industrialio-backend.c
@@ -296,11 +296,9 @@ struct iio_backend *devm_iio_backend_get(struct device *dev, const char *name)
 	}
 
 	fwnode = fwnode_find_reference(dev_fwnode(dev), "io-backends", index);
-	if (IS_ERR(fwnode)) {
-		dev_err_probe(dev, PTR_ERR(fwnode),
-			      "Cannot get Firmware reference\n");
-		return ERR_CAST(fwnode);
-	}
+	if (IS_ERR(fwnode))
+		return dev_errp_probe(dev, PTR_ERR(fwnode),
+				      "Cannot get Firmware reference\n");
 
 	guard(mutex)(&iio_back_lock);
 	list_for_each_entry(back, &iio_back_list, entry) {

-- 
2.44.0

