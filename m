From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Date: Sun, 24 Nov 2024 17:21:36 +0100
Subject: [PATCH v3 2/3] w1: ds2482: Fix datasheet URL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241124-ds2482-add-reg-v3-2-806df39c9454@gmail.com>
References: <20241124-ds2482-add-reg-v3-0-806df39c9454@gmail.com>
In-Reply-To: <20241124-ds2482-add-reg-v3-0-806df39c9454@gmail.com>
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Stefan Wahren <stefan.wahren@chargebyte.com>
Cc: Ben Gardner <bgardner@wabtec.com>, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732465298; l=803;
 i=cleverline1mc@gmail.com; s=20241112; h=from:subject:message-id;
 bh=KgZawicUQ6ba1iLjAlE5ZV15q7h9O+Q2qa06o+itHSU=;
 b=sSTCVKcz+HPkfsDfkPtL1wfea+5GF16lRiRZASuC82+zIuFG5qwHfT7ceOSpcPzIO5S8qX9w/
 ylO11GL9XUMAkoE1i8XaYj4mnO1L9h7yeEuLXT2xQqd/BAW3iamnVi0
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=EJoEbw03UiRORQuCiEyNA8gH1Q6fIpEWnn/MyaWOWX0=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20241112 with auth_id=275
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Current link does redirect to wrong place.

Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
 drivers/w1/masters/ds2482.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/w1/masters/ds2482.c b/drivers/w1/masters/ds2482.c
index 4cb05d00cb6743abc5699583f591ef9b5339b44e..48b4eb7299cb9ba0fc7df6ee7908f1e1709cf303 100644
--- a/drivers/w1/masters/ds2482.c
+++ b/drivers/w1/masters/ds2482.c
@@ -7,7 +7,7 @@
  * It is a I2C to 1-wire bridge.
  * There are two variations: -100 and -800, which have 1 or 8 1-wire ports.
  * The complete datasheet can be obtained from MAXIM's website at:
- *   http://www.maxim-ic.com/quick_view2.cfm/qv_pk/4382
+ *   https://www.analog.com/en/products/ds2482-100.html
  */
 
 #include <linux/module.h>

-- 
2.39.5

