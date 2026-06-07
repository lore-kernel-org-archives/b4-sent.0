From: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
Date: Sun, 07 Jun 2026 18:45:32 +0300
Subject: [PATCH v2 2/5] ufs: Add flags according
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260607-ufs_tool2-v2-2-f79ff26ab18c@mobileye.com>
References: <20260607-ufs_tool2-v2-0-f79ff26ab18c@mobileye.com>
In-Reply-To: <20260607-ufs_tool2-v2-0-f79ff26ab18c@mobileye.com>
To: u-boot@lists.denx.de
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, Tom Rini <trini@konsulko.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Padmarao Begari <padmarao.begari@amd.com>, 
 Michal Simek <michal.simek@amd.com>, Julien Stephan <jstephan@baylibre.com>, 
 Udit Kumar <u-kumar1@ti.com>, 
 Kunihiko Hayashi <hayashi.kunihiko@socionext.com>, 
 Venkatesh Yadav Abbarapu <venkatesh.abbarapu@amd.com>, 
 Shawn Lin <shawn.lin@rock-chips.com>, Jared McArthur <j-mcarthur@ti.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Peter Robinson <pbrobinson@gmail.com>, 
 Dinesh Maniyam <dinesh.maniyam@altera.com>, 
 Heiko Schocher <hs@nabladev.com>, Simon Glass <sjg@chromium.org>, 
 briansune <briansune@gmail.com>, Yao Zi <me@ziyao.cc>, 
 Peng Fan <peng.fan@nxp.com>, Kory Maincent <kory.maincent@bootlin.com>, 
 Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, 
 Stefan Roese <stefan.roese@mailbox.org>, 
 Philip Molloy <philip.molloy@analog.com>, 
 Raz Ben Yehuda <raz.benyehuda@mobileye.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=726;
 i=raz.benyehuda@mobileye.com; h=from:subject:message-id;
 bh=/w2PkHnQPmuBGriJVqFAGn8l0ypJLuh/dA3UCYxJEc8=;
 b=owEBbQKS/ZANAwAKAZ+a6ZSW6I45AcsmYgBqJZI5FkRjyCQ2OHShZtkAcrYn9HMfjQPb8fFHY
 BSPJHRCltOJAjMEAAEKAB0WIQSC7lz5E3UmOrJvRDqfmumUluiOOQUCaiWSOQAKCRCfmumUluiO
 OWXxEACnmnOR49tI4jIMPW2ChS/EbULRE5fafqLTfrqWdFyLts32A0NOydesVmSq17h4EW/pa75
 WxLS+AYHnQ9K+PpjOZ95trVGfs5sXSjn18FqNg4xuCxBLMw1qi2CguwAnAQsru+0jjuJ2u+fcRr
 F/Gp9LiPotn1EimGWDb+zLWpRUF7mT5Nw0/CJV3W67Tt48cs+B4YFVoBk6CfTFHRdfci7i1DKJ6
 L3ErsXgSH6WQ+QsbYdtJktalv9grXTAq4P8xQpJBAOIsSyiBnqgdUGh3lBFh040CcNHgCeR00KF
 2BkEGsNk4BuoRgyyBKYrBIezuI/V9toF7nDS5cn20Rzq875Q/eZ4Pgo/T1TRHU31JF1ZWqrGsdC
 uikNkFEA3VP4tHBDRltHboTievRNLhU2WePC/bPWGD48SR0gdtP6s4W81LVvloMfeYYYCetjB5s
 AV/tDZuHWLoXPQ28BNV5dQOSinjBYdql68VsQ8E0sQTkcl5kjrvTUSxR33DeYdecWmixYh54o3O
 hLHJQ04ZtYLRz4oPmy8hgiZsv7WtkA1BuvQvoThBzBhyDc6buhUnT74cNSXGQnCC3BR5wKsiowe
 Kks4eCToWJ1Gek9zl2ZqL03s7GvxzvIbpkTM7aGXinsHhonijrWCpu99vAsIiT+o4/hwhSW4Gs9
 lNAAn5qj07lF1RQ==
X-Developer-Key: i=raz.benyehuda@mobileye.com; a=openpgp;
 fpr=82EE5CF91375263AB26F443A9F9AE99496E88E39
X-Endpoint-Received: by B4 Relay for raz.benyehuda@mobileye.com/default with auth_id=808
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some flags are missing according to UFS 3.1

Signed-off-by: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
---
 drivers/ufs/ufs.h | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/ufs/ufs.h b/drivers/ufs/ufs.h
index 213b489e5e4..75b7ff83155 100644
--- a/drivers/ufs/ufs.h
+++ b/drivers/ufs/ufs.h
@@ -218,6 +218,9 @@ enum flag_idn {
 	QUERY_FLAG_IDN_BUSY_RTC				= 0x09,
 	QUERY_FLAG_IDN_RESERVED3			= 0x0A,
 	QUERY_FLAG_IDN_PERMANENTLY_DISABLE_FW_UPDATE	= 0x0B,
+	QUERY_FLAG_IDN_F_WRITE_BOOSTER_EN               = 0x0E,
+	QUERY_FLAG_IDN_F_WB_BUF_FLUSH_EN                = 0x0F,
+	QUERY_FLAG_IDN_F_WB_BUF_FLUSH_HIBERN8           = 0x10
 };
 
 /* Attribute idn for Query requests */

-- 
2.43.0

