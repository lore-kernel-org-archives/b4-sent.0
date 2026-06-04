From: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
Date: Thu, 04 Jun 2026 14:25:49 +0300
Subject: [PATCH PATCHSET 1/6] MAINTAINERS: Add myself to the list of UFS
 maintainers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260604-ufs_tool-v1-1-741ed00232c0@mobileye.com>
References: <20260604-ufs_tool-v1-0-741ed00232c0@mobileye.com>
In-Reply-To: <20260604-ufs_tool-v1-0-741ed00232c0@mobileye.com>
To: u-boot@lists.denx.de
Cc: Tom Rini <trini@konsulko.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Simon Glass <sjg@chromium.org>, 
 Peng Fan <peng.fan@nxp.com>, Kory Maincent <kory.maincent@bootlin.com>, 
 Yao Zi <me@ziyao.cc>, Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Stefan Roese <stefan.roese@mailbox.org>, 
 Philip Molloy <philip.molloy@analog.com>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Macpaul Lin <macpaul.lin@mediatek.com>, Michal Simek <michal.simek@amd.com>, 
 Julien Stephan <jstephan@baylibre.com>, 
 Padmarao Begari <padmarao.begari@amd.com>, 
 Kunihiko Hayashi <hayashi.kunihiko@socionext.com>, 
 Venkatesh Yadav Abbarapu <venkatesh.abbarapu@amd.com>, 
 Jared McArthur <j-mcarthur@ti.com>, Shawn Lin <shawn.lin@rock-chips.com>, 
 Igor Belwon <igor.belwon@mentallysanemainliners.org>, 
 Tuyen Dang <tuyen.dang.xa@renesas.com>, Alexey Charkov <alchark@gmail.com>, 
 Raz Ben Yehuda <raz.benyehuda@mobileye.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=668;
 i=raz.benyehuda@mobileye.com; h=from:subject:message-id;
 bh=Ocf5B/AMvqRO/bsWWzBAN9GEVg25q68LSul7v418mCs=;
 b=owEBbQKS/ZANAwAKAZ+a6ZSW6I45AcsmYgBqIWC+AyXrL+ZyJ8ag+7GnEq4cGzbkiN+715ojC
 +jb5YBkg8+JAjMEAAEKAB0WIQSC7lz5E3UmOrJvRDqfmumUluiOOQUCaiFgvgAKCRCfmumUluiO
 OWiWD/4gii+hV7dDiuKRz7ez3tUfMBfFMBrxJ3LxX7Uo7OXU4mv1vPYrDCVWUlXi/JFD/4cSTZv
 JPb/P7vW+t4lDlDohTZf5TQjXTGjulJZ1OHZhCl8DBLOJWyOn2qcqOE+JTZ/xOmeIlgOHrSAqsg
 Mhz6JtVKM5otfja7PrBma9tguhPtFwmDI1+NrA3lI5flixCJE/VSkcvJrB5yLlknrDfu/NviKLF
 OZGynGUelNtZ4F2VsNBO4BuLPib8CLygvL8DG+SFmV8is6totjxOwQuPbN/g/R2LNQuPk8mGIhK
 78qCRG+TG0lK3TqouhpRPCBw5qlRuaZqDpR8c081pBbR/yqQdL2kPMLo2xkQuAAdPsbteqfaOqK
 nBdRyODMrglnMA+5SFzPxYETWbYdZ+cDGoP3R/uTirVfS0GAkmocADjCe+Az1MchA4pAdMiDfpx
 pvkIs7csalaL82CIoXmZ27Bd7qcoPosTOBglAKKfZWAqa7xeXjqU22ZCyD9Yf63rcUxWrWJ6w9r
 zHEh+ZLDgEucyD89jmP05uzZe0c3BT0G7JQ+XZ8SZynTM65F0HbQWS1ikGwKPD2F0xGvlfi52qO
 YTiDO9R5PFEkWK/l9ScocIq5pxR/cY3TucXcOCCzAY519Lbfg0021kb3psfef98Gk3bYOqi+QVD
 LD1ZCCuVJ6bz5jQ==
X-Developer-Key: i=raz.benyehuda@mobileye.com; a=openpgp;
 fpr=82EE5CF91375263AB26F443A9F9AE99496E88E39
X-Endpoint-Received: by B4 Relay for raz.benyehuda@mobileye.com/default with auth_id=808
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

    Adding myself to ufs.

Signed-off-by: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
---
 MAINTAINERS | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 571af196465..0cb8c3e144b 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1920,8 +1920,13 @@ UFS
 M:	Neil Armstrong <neil.armstrong@linaro.org>
 M:	Bhupesh Sharma <bhupesh.linux@gmail.com>
 M:	Neha Malcom Francis <n-francis@ti.com>
+M:	Raz Ben Yehuda <raz.benyehuda@mobileye.com>
 S:	Maintained
+F:	cmd/ufs.c
 F:	common/spl/spl_ufs.c
+F:	doc/usage/cmd/ufs.rst
+F:	drivers/ufs/ufs_tool.c
+F:	drivers/ufs/ufs_tool.h
 F:	drivers/ufs/
 
 UPL

-- 
2.43.0

