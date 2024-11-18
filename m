From: Manas <manas18244@iiitd.ac.in>
Date: Mon, 18 Nov 2024 20:00:36 +0530
Subject: [PATCH net-next v2] net: phy: qt2025: simplify Result<()> in probe
 return
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241118-simplify-result-qt2025-v2-1-af1bcff5d101@iiitd.ac.in>
X-B4-Tracking: v=1; b=H4sIAItPO2cC/4WNQQ6CMBBFr0Jm7RCnSgRX3sOwgHYqk2DBthII6
 d1tuIDLl5f//g6BvXCAe7GD50WCTC6DOhWgh869GMVkBnVWVyKqMch7HsVu6Dl8x4ifmFWF1Pd
 NY2quLqwhj2fPVtYj/ATHER2vEdpsBglx8tvxuNDh/8UXQkKrTKPZ0s3q7iEi0ZSdLsVBm1L6A
 TNXe4bIAAAA
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
 Miguel Ojeda <ojeda@kernel.org>, Manas <manas18244@iiitd.ac.in>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731940236; l=1498;
 i=manas18244@iiitd.ac.in; s=20240813; h=from:subject:message-id;
 bh=aNU3+RJ8lBcv7tT/MtgstLYhDl/ERX/hXonU5AJGIRw=;
 b=aKxqt8ceYzbm2O7JpvqJGoSp1qYHMsTzRsrMTB8+OS1LGL00Tyy6twRxjXiO4RBEuY8TARKEm
 YjN5JzMkyPvDkEbaNYjUkvGjmzeQLN61vIPio3EC07kOSA6oeNMAxDO
X-Developer-Key: i=manas18244@iiitd.ac.in; a=ed25519;
 pk=pXNEDKd3qTkQe9vsJtBGT9hrfOR7Dph1rfX5ig2AAoM=
X-Endpoint-Received: by B4 Relay for manas18244@iiitd.ac.in/20240813 with auth_id=196
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

probe returns a `Result<()>` type, which can be simplified as `Result`,
due to default type parameters being unit `()` and `Error` types. This
maintains a consistent usage of `Result` throughout codebase.

Suggested-by: Miguel Ojeda <ojeda@kernel.org>
Link: https://github.com/Rust-for-Linux/linux/issues/1128
Signed-off-by: Manas <manas18244@iiitd.ac.in>
---
Changes in v2:
- Add Link: and Suggested-by: tags
- Link to v1: https://lore.kernel.org/r/20241118-simplify-result-qt2025-v1-1-f2d9cef17fca@iiitd.ac.in
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

