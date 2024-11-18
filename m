From: Manas <manas18244@iiitd.ac.in>
Date: Mon, 18 Nov 2024 18:39:34 +0530
Subject: [PATCH net-next] net: phy: qt2025: simplify Result<()> in probe
 return
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241118-simplify-result-qt2025-v1-1-f2d9cef17fca@iiitd.ac.in>
X-B4-Tracking: v=1; b=H4sIAI48O2cC/x2MSwqDQBAFryK9tsH2A+pVgouoz6RBRzM9EUW8e
 4Ysi6LqIoNXGLXJRR67mq4ugqQJDe+ne4F1jEx5lpciUrPpss06nexh3znwJ0RVsfR904w1qgI
 DxXjzmPT4jx/kENjhCNTd9w9rgZsTcgAAAA==
X-Change-ID: 20241118-simplify-result-qt2025-1bb99d8e53ec
To: FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Trevor Gross <tmgross@umich.edu>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: Shuah Khan <skhan@linuxfoundation.org>, 
 Anup Sharma <anupnewsmail@gmail.com>, netdev@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Manas <manas18244@iiitd.ac.in>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731935374; l=1232;
 i=manas18244@iiitd.ac.in; s=20240813; h=from:subject:message-id;
 bh=b+u/enFxPC2OQb24qeuinsUzhoPbbFPNjp30yv8A78E=;
 b=VVCd959mHl3fdAs00yFofntkbHvAfCQ2XltcauKLxVDNZfmtVWdVj1Nm4rF9y767uXY4UvSAY
 qf/QRFW7KT3CjzzeOo61XIcbXoEmUYDUqLjvqyWWmeNhZuE4CwcHlJT
X-Developer-Key: i=manas18244@iiitd.ac.in; a=ed25519;
 pk=pXNEDKd3qTkQe9vsJtBGT9hrfOR7Dph1rfX5ig2AAoM=
X-Endpoint-Received: by B4 Relay for manas18244@iiitd.ac.in/20240813 with auth_id=196
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

probe returns a `Result<()>` type, which can be simplified as `Result`,
due to default type parameters being unit `()` and `Error` types. This
maintains a consistent usage of `Result` throughout codebase.

Signed-off-by: Manas <manas18244@iiitd.ac.in>
---
 drivers/net/phy/qt2025.rs | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/phy/qt2025.rs b/drivers/net/phy/qt2025.rs
index 1ab065798175b4f54c5f2fd6c871ba2942c48bf1..25c12a02baa255d3d5952e729a890b3ccfe78606 100644
--- a/drivers/net/phy/qt2025.rs
+++ b/drivers/net/phy/qt2025.rs
@@ -39,7 +39,7 @@ impl Driver for PhyQT2025 {
     const NAME: &'static CStr = c_str!("QT2025 10Gpbs SFP+");
     const PHY_DEVICE_ID: phy::DeviceId = phy::DeviceId::new_with_exact_mask(0x0043a400);
 
-    fn probe(dev: &mut phy::Device) -> Result<()> {
+    fn probe(dev: &mut phy::Device) -> Result {
         // Check the hardware revision code.
         // Only 0x3b works with this driver and firmware.
         let hw_rev = dev.read(C45::new(Mmd::PMAPMD, 0xd001))?;

---
base-commit: 8cf0b93919e13d1e8d4466eb4080a4c4d9d66d7b
change-id: 20241118-simplify-result-qt2025-1bb99d8e53ec

Best regards,
-- 
Manas <manas18244@iiitd.ac.in>

