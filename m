From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 08 Dec 2023 16:14:10 +0100
Subject: [PATCH v2 3/8] driver: core: allow modifying device_links flags
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231208-dev-iio-backend-v2-3-5450951895e1@analog.com>
References: <20231208-dev-iio-backend-v2-0-5450951895e1@analog.com>
In-Reply-To: <20231208-dev-iio-backend-v2-0-5450951895e1@analog.com>
To: devicetree@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Frank Rowand <frowand.list@gmail.com>, Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702048448; l=1762;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=NLZHAx7QEa2fUUjKTtfo6RESv2OQO0JG++qc/yxWC4M=;
 b=ASOBUH495cPlwGqGxHPodgKqYv81aF+nGrtg6/d7TDTSOn8lqsHouzKLnCX2reyPDdZDNQmx3
 ULN8adbHoSnBbiPSXjX8hhFAs8zfLET+ys5pqnP/tXGBAS/0dI+u50s
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If a device_link is previously created (eg: via
fw_devlink_create_devlink()) before the supplier + consumer are both
present and bound to their respective drivers, there's no way to set
DL_FLAG_AUTOREMOVE_CONSUMER anymore while one can still set
DL_FLAG_AUTOREMOVE_SUPPLIER. Hence, rework the flags checks to allow
for DL_FLAG_AUTOREMOVE_CONSUMER in the same way
DL_FLAG_AUTOREMOVE_SUPPLIER is done.

While at it, make sure that we are never left with
DL_FLAG_AUTOPROBE_CONSUMER set together with one of
DL_FLAG_AUTOREMOVE_CONSUMER or DL_FLAG_AUTOREMOVE_SUPPLIER.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/base/core.c | 14 +++++++++-----
 1 file changed, 9 insertions(+), 5 deletions(-)

diff --git a/drivers/base/core.c b/drivers/base/core.c
index 67ba592afc77..fdbb5abc75d5 100644
--- a/drivers/base/core.c
+++ b/drivers/base/core.c
@@ -807,11 +807,15 @@ struct device_link *device_link_add(struct device *consumer,
 		 * update the existing link to stay around longer.
 		 */
 		if (flags & DL_FLAG_AUTOREMOVE_SUPPLIER) {
-			if (link->flags & DL_FLAG_AUTOREMOVE_CONSUMER) {
-				link->flags &= ~DL_FLAG_AUTOREMOVE_CONSUMER;
-				link->flags |= DL_FLAG_AUTOREMOVE_SUPPLIER;
-			}
-		} else if (!(flags & DL_FLAG_AUTOREMOVE_CONSUMER)) {
+			link->flags &= ~DL_FLAG_AUTOREMOVE_CONSUMER;
+			link->flags &= ~DL_FLAG_AUTOPROBE_CONSUMER;
+			link->flags |= DL_FLAG_AUTOREMOVE_SUPPLIER;
+
+		} else if (flags & DL_FLAG_AUTOREMOVE_CONSUMER) {
+			link->flags &= ~DL_FLAG_AUTOREMOVE_SUPPLIER;
+			link->flags &= ~DL_FLAG_AUTOPROBE_CONSUMER;
+			link->flags |= DL_FLAG_AUTOREMOVE_CONSUMER;
+		} else {
 			link->flags &= ~(DL_FLAG_AUTOREMOVE_CONSUMER |
 					 DL_FLAG_AUTOREMOVE_SUPPLIER);
 		}

-- 
2.43.0

