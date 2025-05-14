From: Alejandro Enrique <alejandroe1@geotab.com>
Date: Wed, 14 May 2025 13:55:55 +0200
Subject: [PATCH 2/2] gnss: ubx: add u-blox,neo-m9 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250514-ubx-m9-v1-2-193973a4f3ca@geotab.com>
References: <20250514-ubx-m9-v1-0-193973a4f3ca@geotab.com>
In-Reply-To: <20250514-ubx-m9-v1-0-193973a4f3ca@geotab.com>
To: Johan Hovold <johan@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Alejandro Enrique <alejandroe1@geotab.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747223768; l=669;
 i=alejandroe1@geotab.com; s=20250514; h=from:subject:message-id;
 bh=KiIso4vtHVKYcUMsG8FY0qTIhtRbhyM34Q0yiSQ9xCA=;
 b=PVY1f03vSetltMmpL6CZOcSbhbOJeLAjcXwD3qOa/O+SeFRxWYYQPjs9ks9rI3FF22RvzVEoP
 r6s80h3JsfXACZ3chq1WuLW3T0+JMU4Ift0hcTZ40hMlq8wT9QIkaJF
X-Developer-Key: i=alejandroe1@geotab.com; a=ed25519;
 pk=xzHMPbqczL/tMsjXr26iLoHwIzLveHVnT+GIU4p1k38=
X-Endpoint-Received: by B4 Relay for alejandroe1@geotab.com/20250514 with auth_id=404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible for u-blox NEO-M9 GPS module.

Signed-off-by: Alejandro Enrique <alejandroe1@geotab.com>
---
 drivers/gnss/ubx.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gnss/ubx.c b/drivers/gnss/ubx.c
index 92402f6082c415c7b9051338eef5406b09e09455..2d69f1b4a5979f96d3d4ce72b122f3bd05892b55 100644
--- a/drivers/gnss/ubx.c
+++ b/drivers/gnss/ubx.c
@@ -124,6 +124,7 @@ static const struct of_device_id ubx_of_match[] = {
 	{ .compatible = "u-blox,neo-6m" },
 	{ .compatible = "u-blox,neo-8" },
 	{ .compatible = "u-blox,neo-m8" },
+	{ .compatible = "u-blox,neo-m9" },
 	{},
 };
 MODULE_DEVICE_TABLE(of, ubx_of_match);

-- 
2.34.1

