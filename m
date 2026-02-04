From: Ben Zong-You Xie <ben717@andestech.com>
Date: Wed, 04 Feb 2026 19:30:43 +0800
Subject: [PATCH v4 3/3] MAINTAINERS: add an entry for Andes PWM driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260204-andes-pwm-v4-3-67016bb13555@andestech.com>
References: <20260204-andes-pwm-v4-0-67016bb13555@andestech.com>
In-Reply-To: <20260204-andes-pwm-v4-0-67016bb13555@andestech.com>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ben Zong-You Xie <ben717@andestech.com>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770204641; l=718;
 i=ben717@andestech.com; s=20260120; h=from:subject:message-id;
 bh=L+fNVfc7JYf3+aGNasKyAhP0+tchIMKM44EzBGRUsVE=;
 b=dMDOp2I9fAG+kHI2pDIJDcSRPnnewYchBKmOPeVja702WL++cO63RH3O+uQ63cWrKSthH/Za+
 10Jr2KmL5TqCu/gY8CQDrRGwEpSsON5ZGJOhHwI64d8NGvdUhhihXBc
X-Developer-Key: i=ben717@andestech.com; a=ed25519;
 pk=nb8L7zQKGJpYk0yvrYKjViOZ34A36g1ZIsCmCsP518s=
X-Endpoint-Received: by B4 Relay for ben717@andestech.com/20260120 with auth_id=610
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an entry for the Andes PWM driver to the MAINTAINERS file.

Signed-off-by: Ben Zong-You Xie <ben717@andestech.com>
---
 MAINTAINERS | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 75ebe5750242..536d692c0fb8 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1817,6 +1817,12 @@ S:	Supported
 F:	drivers/clk/analogbits/*
 F:	include/linux/clk/analogbits*
 
+ANDES PWM DRIVER
+M:	Ben Zong-You Xie <ben717@andestech.com>
+S:	Supported
+F:	Documentation/devicetree/bindings/pwm/andestech,ae350-pwm.yaml
+F:	drivers/pwm/pwm-andes.c
+
 ANDROID DRIVERS
 M:	Greg Kroah-Hartman <gregkh@linuxfoundation.org>
 M:	Arve Hjønnevåg <arve@android.com>

-- 
2.34.1

