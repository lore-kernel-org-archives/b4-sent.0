From: Satish Kharat <satishkh@cisco.com>
Subject: [PATCH v2 0/2] net:ethernet:enic: add VIC ids and link modes
Date: Mon, 23 Feb 2026 02:27:19 -0800
Message-Id: <20260223-enic-cscwi36355-v2-0-63488194a974@cisco.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIcrnGkC/2WNQQ7CIBBFr9LMWsxABaMr72G6qMNgZyEYMFXTc
 HexiSuX7yX//QUKZ+ECx26BzLMUSbGB2XRA0xivrMQ3BoPGoTGoOAopKvSU3vXWqn3wiBd7CKw
 R2uqeOchrLZ6HxpOUR8rv9WDWX/tr6b/WrBUqO6IeHe6ct3wiKZS2lG4w1Fo/nOGj164AAAA=
To: netdev@vger.kernel.org
Cc: Satish Kharat <satishkh@cisco.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771842484; l=917;
 i=satishkh@cisco.com; h=from:subject:message-id;
 bh=N2bM5Up2XL0atqGOG2enGUu9vC/fkdKMG9llDdkFOoo=;
 b=ePtJYNXa95b+fVzS5ILEB9gq+wC/V8iZ3E6DkIITTTW8Y+O5+8iFmUb5ABMrKO4bk6/M/NKvI
 eonYPGwVkUfCQ+giMuvYaKAwxku8hyVWLwabh5BYZcPeRdgjlKuEVaA
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=4BxbLoCGvHeIMH/PbpiNVx8/2IcTjFvqcr0AD8K6WLY=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/default with auth_id=639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add VIC subsystem ids and their supported/advertised media types so ethtool
reflects the hardware capabilities for the VIC variants.

Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
Changes in v2:
Addressed comments from Andrew Lunn
- Removed the advertising of the link speed as we don't support autoneg.
- Link to v1: https://lore.kernel.org/r/20260221-enic-cscwi36355-v1-0-5a01a6046d5e@cisco.com

---
Satish Kharat (2):
      net:ethernet:enic: add VIC subsystem ids
      net:ethernet:enic: map ethtool link modes by VIC type

 drivers/net/ethernet/cisco/enic/enic.h         |  39 +++++++
 drivers/net/ethernet/cisco/enic/enic_ethtool.c | 155 +++++++++++++++++++++++--
 2 files changed, 187 insertions(+), 7 deletions(-)
---
base-commit: 8bf22c33e7a172fbc72464f4cc484d23a6b412ba
change-id: 20260220-enic-cscwi36355-7fd00b59fe10

Best regards,
-- 
Satish Kharat <satishkh@cisco.com>

