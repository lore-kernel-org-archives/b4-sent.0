From: Long Zhao <longzhao@ambarella.com>
Date: Wed, 18 Nov 2026 15:42:29 +0800
Subject: [PATCH v15 12/14] gpio: pl061: tidy up IRQ trigger logging
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-cv75-gpio-v15-12-e3c563673fe1@ambarella.com>
References: <20261118-cv75-gpio-v15-0-e3c563673fe1@ambarella.com>
In-Reply-To: <20261118-cv75-gpio-v15-0-e3c563673fe1@ambarella.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794987752; l=970;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=p7Z9u3ngOc5syILLflVzIV7nyZ9es9xNruSYn8Vifgo=;
 b=JW8SztEkB04l0RIgtqVTn3y8xilwHRd0c6dolhWdf+M29eWt7TJ5UmZ8Ku9/SnC9gaauOAJ/x
 zNEnLHUOX5JDgNPYtXMB1N09JtziDKvr5OCeCU4uHczvuq01AgpfC+6
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
index c0a3a8b5c2c1..332fa51f8ccf 100644
--- a/drivers/gpio/gpio-pl061.c
+++ b/drivers/gpio/gpio-pl061.c
@@ -172,8 +172,7 @@ static int pl061_irq_type(struct irq_data *d, unsigned trigger)
 
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

