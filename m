From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Thu, 17 Jul 2025 15:51:34 +0100
Subject: [PATCH] mfd: adp5585: Drop useless return statement
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250717-adp5585-drop-ret-v1-1-2ae65bd780aa@analog.com>
X-B4-Tracking: v=1; b=H4sIAPUNeWgC/x3MQQqAIBBA0avErBvQwKyuEi0sp5qNyRgRiHdPW
 r7F/xkSCVOCqckg9HDiK1TotoHtdOEgZF8NneqMstqi89GYwaCXK6LQjf2qtRqtdcp5qFkU2vn
 9l/NSygfVjARQYgAAAA==
X-Change-ID: 20250717-adp5585-drop-ret-6b110977a0ad
To: linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org
Cc: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Lee Jones <lee@kernel.org>, Dan Carpenter <dan.carpenter@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752763896; l=1199;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=fa2lU4nXFqoCVVCIfit96zG313AYsYjHUMW+fLWBw3E=;
 b=GiPWHTiCOaER8fe0hS7yssIfg0FKiPLqsOJf5qw/KWPP/gHcS0Kfr3Z8XPeTl0hrOj1aeyVKq
 k91h25x/INrBz+yG0MNRoZFWCp/XSIsuCDZfZmlNahBrcY3zchJ9HwH
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In adp5585_reset_ev_parse(), when parsing the
adi,reset-pulse-width-us property, we were returning in case it was
found and valid. No point in doing that as we'll be returning anyways
after the exiting the property scope. And it could actually lead to bugs
if new properties happen to added after this one.

Reported-by: Dan Carpenter <dan.carpenter@linaro.org>
Closes: https://lore.kernel.org/linux-gpio/c85604d9e077511b8aa6ee0786579594cc0103d4.camel@gmail.com/T/#ma25557bd06ccd2531dc9c85ba6be74af781b81aa
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/mfd/adp5585.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/mfd/adp5585.c b/drivers/mfd/adp5585.c
index 58f7cebe2ea4f2c68f64370449f5fbce8a2f14ed..46b3ce3d7bae8981824a957f6b4ee471d803c981 100644
--- a/drivers/mfd/adp5585.c
+++ b/drivers/mfd/adp5585.c
@@ -432,7 +432,6 @@ static int adp5585_reset_ev_parse(struct adp5585_dev *adp5585)
 					     "Invalid value(%u) for adi,reset-pulse-width-us\n",
 					     prop_val);
 		}
-		return ret;
 	}
 
 	return 0;

---
base-commit: 8f3ef4da96dd3f3e12f6313cbe8cd16a39e9abae
change-id: 20250717-adp5585-drop-ret-6b110977a0ad
--

Thanks!
- Nuno Sá

