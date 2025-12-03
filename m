From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Wed, 03 Dec 2025 15:53:37 +0000
Subject: [PATCH 2/2] iio: dac: adi-axi-dac: Turn dev_info() into dev_dbg()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251203-iio-axi-dac-minor-changes-v1-2-b54650cbeb33@analog.com>
References: <20251203-iio-axi-dac-minor-changes-v1-0-b54650cbeb33@analog.com>
In-Reply-To: <20251203-iio-axi-dac-minor-changes-v1-0-b54650cbeb33@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764777217; l=1060;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=1mI9GzMK+TpvyOBmx5lCXv0qeg/FjUA9vszGxDZhgKY=;
 b=9tDz+tZ9RJa0R8s70CoAHiXLhVcI7X6TDG5p3DQYZG3bJerInFLz9b/0HNsvp9tHAaPnwsuDc
 jXNn1iSza1hBrMJ+29drVFyFlq8Ir60hiuSQwkPNyyBhzXA7xxwFtTv
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We should not abuse logging and logging a successful probe is clearly
abuse. Turn it into dev_dbg().

If it turns out the IP version is that relevant we can make it easy to
get through a new debugfs interface later on.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/dac/adi-axi-dac.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/dac/adi-axi-dac.c b/drivers/iio/dac/adi-axi-dac.c
index 0c7b62f5357d..f536158beb4c 100644
--- a/drivers/iio/dac/adi-axi-dac.c
+++ b/drivers/iio/dac/adi-axi-dac.c
@@ -1000,10 +1000,10 @@ static int axi_dac_probe(struct platform_device *pdev)
 						"cannot create device.");
 	}
 
-	dev_info(&pdev->dev, "AXI DAC IP core (%d.%.2d.%c) probed\n",
-		 ADI_AXI_PCORE_VER_MAJOR(ver),
-		 ADI_AXI_PCORE_VER_MINOR(ver),
-		 ADI_AXI_PCORE_VER_PATCH(ver));
+	dev_dbg(&pdev->dev, "AXI DAC IP core (%d.%.2d.%c) probed\n",
+		ADI_AXI_PCORE_VER_MAJOR(ver),
+		ADI_AXI_PCORE_VER_MINOR(ver),
+		ADI_AXI_PCORE_VER_PATCH(ver));
 
 	return 0;
 }

-- 
2.52.0

