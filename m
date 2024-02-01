From: Yang Xiwen <forbidden405@outlook.com>
Date: Thu, 01 Feb 2024 21:16:09 +0800
Subject: [PATCH 2/3] test: phy: test generic_setup(shutdown)_phy_bulk()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240201-ehci-v1-2-bb506cb0f64d@outlook.com>
References: <20240201-ehci-v1-0-bb506cb0f64d@outlook.com>
In-Reply-To: <20240201-ehci-v1-0-bb506cb0f64d@outlook.com>
To: Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Marek Vasut <marex@denx.de>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706793368; l=1136;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=OKbYdfeAfoB1ENsDPSA3px1Y5YCpK81TWIY83hgQ/SQ=;
 b=7xmLBh+dObuVnzZ+BfM67XzkHrIpjUGmngcKMvmtWmCsyPRrwdw+RSaZaBvuPrGSqeytwiNWE
 sd9mCFmrQwsA5PaRYsmRTXhZmtigKJLdXlAoHtxzLYCFM12JiO52U9f
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

add unittests for the newly introduced helper functions.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 test/dm/phy.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/test/dm/phy.c b/test/dm/phy.c
index 0cf3689fde..cb16844a0a 100644
--- a/test/dm/phy.c
+++ b/test/dm/phy.c
@@ -159,6 +159,8 @@ static int dm_test_phy_bulk(struct unit_test_state *uts)
 	ut_asserteq(0, generic_phy_power_on_bulk(&phys));
 	ut_asserteq(0, generic_phy_power_off_bulk(&phys));
 	ut_asserteq(0, generic_phy_exit_bulk(&phys));
+	ut_asserteq(0, generic_setup_phy_bulk(parent, &phys));
+	ut_asserteq(0, generic_shutdown_phy_bulk(&phys));
 
 	/* has a known problem phy */
 	ut_assertok(uclass_get_device_by_name(UCLASS_SIMPLE_BUS,
@@ -171,6 +173,8 @@ static int dm_test_phy_bulk(struct unit_test_state *uts)
 	ut_asserteq(-EIO, generic_phy_power_on_bulk(&phys));
 	ut_asserteq(-EIO, generic_phy_power_off_bulk(&phys));
 	ut_asserteq(0, generic_phy_exit_bulk(&phys));
+	ut_asserteq(-EIO, generic_setup_phy_bulk(parent, &phys));
+	ut_asserteq(-EIO, generic_shutdown_phy_bulk(&phys));
 
 	return 0;
 }

-- 
2.43.0

