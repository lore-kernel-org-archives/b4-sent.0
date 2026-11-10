From: Long Zhao <longzhao@ambarella.com>
Date: Tue, 10 Nov 2026 12:32:37 +0800
Subject: [PATCH v14 12/14] gpio: pl061: tidy up IRQ trigger logging
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-cv75-gpio-v14-12-e586aad0467a@ambarella.com>
References: <20261110-cv75-gpio-v14-0-e586aad0467a@ambarella.com>
In-Reply-To: <20261110-cv75-gpio-v14-0-e586aad0467a@ambarella.com>
To: Bartosz Golaszewski <brgl@kernel.org>, linux-gpio@vger.kernel.org
Cc: Linus Walleij <linusw@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Conor Dooley <conor+dt@kernel.org>, Mika Westerberg <westeri@kernel.org>, 
 devicetree@vger.kernel.org, Long Zhao <longzhao@ambarella.com>, 
 Long Zhao <zl020895@163.com>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794285162; l=970;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=NH6oHUs4Wq4OKHpVbaA3cH3G5q6ygkmHpl5qjy7ZpOc=;
 b=7l3FQdyf0Imyw5EhO+e9op6POfCTzVptpLZE11bVQyfd7EaL8Xz3zLP9MXhleKZm0EDwGoseK
 zbRqTaiDG2nDGDc6sFRfrlsqr870iGLQMz7E+I6M+XCsCwILym3an5R
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Join the level-and-edge dev_err() into one string literal so a grep
for "edge detection" finds it.

Suggested-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Reviewed-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 drivers/gpio/gpio-pl061.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/gpio/gpio-pl061.c b/drivers/gpio/gpio-pl061.c
index ff9215447bbb..63ec5363dd5f 100644
--- a/drivers/gpio/gpio-pl061.c
+++ b/drivers/gpio/gpio-pl061.c
@@ -170,8 +170,7 @@ static int pl061_irq_type(struct irq_data *d, unsigned trigger)
 
 	if ((trigger & IRQ_TYPE_LEVEL_MASK) && (trigger & IRQ_TYPE_EDGE_BOTH)) {
 		dev_err(parent,
-			"trying to configure line %d for both level and edge "
-			"detection, choose one!\n",
+			"trying to configure line %d for both level and edge detection, choose one!\n",
 			offset);
 		return -EINVAL;
 	}

-- 
2.34.1

