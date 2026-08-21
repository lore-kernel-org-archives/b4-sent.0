From: Sven Peter <sven@kernel.org>
Date: Fri, 21 Aug 2026 15:50:27 +0200
Subject: [PATCH 1/3] phy: apple: atc: Support DUMMY PIPEHANDLER state in
 configure_pipehandler
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-b4-atcphy-usb4-v1-1-45c0b741e0c0@kernel.org>
References: <20260821-b4-atcphy-usb4-v1-0-45c0b741e0c0@kernel.org>
In-Reply-To: <20260821-b4-atcphy-usb4-v1-0-45c0b741e0c0@kernel.org>
To: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-phy@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Sven Peter <sven@kernel.org>, Paul Cristian <p4ulcristian@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1735; i=sven@kernel.org;
 h=from:subject:message-id; bh=+OdNmU3kQtFUJCrPPsP1ZLOdt+4zemG/iTRVI9Yczzo=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ1ZH+NJX+Zztsv9Sudi8M7cUh0vmGn48crrmz45Vb74x1
 2s2LZ3YUcrCIMbFICumyLJ9v73pk4dvBJduuvQeZg4rE8gQBi5OAZhIlR4jQ6+hnNtj3jKviK/b
 //jsTK7o5/oRb75/7nr+U3kp6utEvBgZrmluCP1l8O6V5tWoT/J/Zh7xTiipWt2SGP/9k//kgs6
 9bAA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For both Thunderbolt and DisplayPort atcphy_configure_pipehandler is
reached with a request to switch to the DUMMY state (i.e. usb2 only).
With the current code this breaks USB2 when all four SS lanes are used
for DisplayPort AltMode because the -EINVAL is passed all the way back
to the phy_set_mode() call which results in tearing down xhci and dwc3
again.
Let's actually handle that case correctly and also drop the default from
the switch such that we get a compiler warning if another pipehandler
state is ever added and forgotten here.

Reported-by: Paul Cristian <p4ulcristian@gmail.com>
Closes: https://github.com/AsahiLinux/linux/pull/515
Fixes: 8e98ca1e74db ("phy: apple: Add Apple Type-C PHY")
Cc: stable@vger.kernel.org
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/phy/apple/atc.c | 8 +++++---
 1 file changed, 5 insertions(+), 3 deletions(-)

diff --git a/drivers/phy/apple/atc.c b/drivers/phy/apple/atc.c
index 4156fabad742..a3162f25e6cd 100644
--- a/drivers/phy/apple/atc.c
+++ b/drivers/phy/apple/atc.c
@@ -1121,7 +1121,7 @@ static int atcphy_configure_pipehandler_dummy(struct apple_atcphy *atcphy)
 
 static int atcphy_configure_pipehandler(struct apple_atcphy *atcphy, bool host)
 {
-	int ret;
+	int ret = -EINVAL;
 
 	lockdep_assert_held(&atcphy->lock);
 
@@ -1136,8 +1136,10 @@ static int atcphy_configure_pipehandler(struct apple_atcphy *atcphy, bool host)
 		ret = atcphy_configure_pipehandler_dummy(atcphy);
 		atcphy->pipehandler_up = false;
 		break;
-	default:
-		ret = -EINVAL;
+	case ATCPHY_PIPEHANDLER_STATE_DUMMY:
+		ret = atcphy_configure_pipehandler_dummy(atcphy);
+		atcphy->pipehandler_up = false;
+		break;
 	}
 
 	return ret;

-- 
2.55.0

